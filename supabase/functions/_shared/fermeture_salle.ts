// FERMETURE-SALLE (decision du directeur du 11/11/2026, seconde moitie du
// defaut SEC-1 de `docs/current/salle/CONSTAT.md`, journal D-018).
//
// Des enfants ne se parlent pas, micro ouvert, sans adulte : ni avant
// l'entree de l'enseignant (`publication_differee.ts`), ni **apres son
// depart**, ni **apres la fin de la seance**. Ce fichier porte ces deux
// derniers cas.
//
// **La regle la plus importante de la salle passe avant** : pendant le cours,
// l'eleve et l'enseignant s'entendent. Rien ici ne coupe une classe par
// erreur. Chaque choix en decoule :
//
//   * **l'enseignant sort** : rien n'est retire sur le moment. LiveKit annonce
//     le depart puis le retour d'un enseignant qui se reconnecte ; fermer au
//     premier message couperait toute la classe a chaque coupure de son
//     reseau. Le serveur note seulement l'instant (`sans_enseignant`, dans les
//     metadonnees de la salle, qu'aucun participant ne peut ecrire) ;
//   * **il n'est pas revenu apres le delai de grace** : le serveur retire aux
//     eleves le droit de publier (micro et camera). La salle reste ouverte :
//     ils attendent, ils ne se parlent pas ;
//   * **il revient** : la marque est levee, et le droit est rendu par le
//     mecanisme qui existe deja (`retablirPublication`, comme a une entree) ;
//   * **la seance est finie** (fin prevue + depassement autorise
//     `grace_after_end_minutes`, ou seance close en base) **et l'enseignant
//     n'est plus la** : la salle est fermee pour tous (`deleteRoom`) ;
//   * **l'enseignant est encore la apres la fin** : la salle n'est PAS fermee.
//     Aucune regle ecrite ne dit de couper un cours qui se tient encore
//     (D-003 borne le chrono et ferme la porte d'entree, pas le cours). La
//     question est posee au directeur (D-018) ; l'interrupteur est
//     `FERMER_A_LA_CLOTURE_MEME_AVEC_ENSEIGNANT` ;
//   * **dans le doute, rien n'est ferme** : seance illisible en base, LiveKit
//     muet, metadonnees illisibles : la salle reste comme elle est.
//
// Le delai ne vit pas dans le webhook (LiveKit livre ses webhooks un par un :
// attendre dedans retarderait le retour de l'enseignant). L'echeance est une
// date ecrite dans la salle ; elle est appliquee par le prochain appel qui
// lit la salle : la tache planifiee `observation-coupure` (en production, au
// 11/11/2026, seulement quand un tuteur observe une seance : voir l'en-tete
// de cette fonction), l'application d'un eleve qui demande au serveur de
// verifier
// (`create-room-token`, action `verifier_salle`), ou un evenement de la
// salle. La decision lit toujours l'etat de la salle chez LiveKit, jamais
// l'ordre des messages ni la parole d'un client.
//
// Ce fichier ne porte que les decisions, en fonctions pures, sans reseau ni
// SDK (`fermeture_salle_test.ts`). Les appels a LiveKit vivent dans
// `livekit.ts`.

import {
  enseignantPresent,
  lireMetadonnees,
  type ParticipantVu,
  ROLE_QUI_ATTEND,
} from './publication_differee.ts'

/// Le delai de grace apres le depart de l'enseignant, en secondes.
///
/// Deux minutes. Pourquoi pas moins : apres une coupure de reseau,
/// l'application de l'enseignant reprend seule l'appel pendant environ
/// 75 secondes (une dizaine d'essais du SDK, environ 45 s, puis les essais du
/// moteur : 0, 2, 4, 8, 16 s ; `lib/core/video/livekit_session_provider.dart`),
/// et LiveKit n'annonce son depart qu'apres ses propres essais. Fermer avant
/// couperait les micros d'une classe dont l'enseignant est en train de
/// revenir, et chaque eleve devrait rouvrir le sien. Pourquoi pas plus : c'est
/// le temps pendant lequel des enfants peuvent se parler sans adulte.
export const DELAI_SANS_ENSEIGNANT_S = 120

/// Faut-il fermer la salle a la cloture de la seance en base (statut final)
/// alors que l'enseignant y est encore ? **Non tant que le directeur ne l'a
/// pas ecrit** (question posee dans D-018). A vrai, une seance close en base
/// ferme la salle pour tous, enseignant compris.
export const FERMER_A_LA_CLOTURE_MEME_AVEC_ENSEIGNANT = false

/// Les statuts d'une seance qui ne reprendra pas : la base refuse alors tout
/// jeton (`autoriser_jeton_video`) ou a deja clos la seance.
export const STATUTS_FINAUX = [
  'ended',
  'canceled',
  'canceled_late',
  'teacher_absent',
  'tech_failure',
] as const

/// Le depassement autorise par defaut, le meme que celui de la base
/// (`app_config_int('grace_after_end_minutes', 15)`), quand le reglage ne se
/// lit pas.
export const DEPASSEMENT_PAR_DEFAUT_MIN = 15

/// Les seances que la regle concerne : les cours d'une classe. Un entretien
/// de recrutement ou une reunion (`session_type` `entretien`, `reunion`)
/// passent par les memes tables et les memes salles, sans aucun role
/// `teacher` : leur appliquer la regle fermerait un entretien en cours.
export const TYPES_DE_COURS = ['standard', 'child'] as const

/// Ce que la base sait de la seance d'une salle.
export interface SeanceVue {
  /// Vrai pour le cours d'une classe (`session_type` `standard` ou `child`).
  /// Faux : entretien, reunion, ou type inconnu ; la regle ne s'applique pas.
  cours: boolean
  /// `sessions.status`.
  statut: string
  /// `sessions.ended_at` : la fin prevue, en millisecondes.
  finPrevueMs: number
  /// `grace_after_end_minutes` : le depassement autorise, en minutes.
  depassementMin: number
}

/// La marque posee dans la salle quand elle se retrouve sans enseignant.
export interface SansEnseignant {
  /// L'instant ou le serveur a vu la salle sans enseignant (millisecondes).
  depuis: number
}

/// La cle des metadonnees de la salle qui porte la marque.
const CLE = 'sans_enseignant'

function objetDe(brut: string | null | undefined): Record<string, unknown> {
  if (!brut) return {}
  try {
    const decode: unknown = JSON.parse(brut)
    if (typeof decode === 'object' && decode !== null && !Array.isArray(decode)) {
      return decode as Record<string, unknown>
    }
  } catch {
    // Illisible : rien n'est suppose.
  }
  return {}
}

/// Lit la marque dans les metadonnees de la salle. Absente ou illisible :
/// `null` (le delai repartira de zero : dans le doute, rien n'est ferme).
export function lireSansEnseignant(
  metadonneesSalle: string | null | undefined,
): SansEnseignant | null {
  const r = objetDe(metadonneesSalle)[CLE]
  if (typeof r !== 'object' || r === null || Array.isArray(r)) return null
  const depuis = (r as Record<string, unknown>).depuis
  if (typeof depuis !== 'number' || !Number.isFinite(depuis) || depuis <= 0) return null
  return { depuis }
}

/// Les metadonnees de la salle avec la marque posee ([marque]) ou levee
/// (`null`). Les autres cles (la recitation) sont gardees telles quelles.
export function ecrireSansEnseignant(
  metadonneesSalle: string | null | undefined,
  marque: SansEnseignant | null,
): string {
  const objet = objetDe(metadonneesSalle)
  if (marque === null) {
    delete objet[CLE]
  } else {
    objet[CLE] = { depuis: marque.depuis }
  }
  return JSON.stringify(objet)
}

/// Lit une seance rendue par la base. Une ligne incomplete ne donne rien :
/// sans seance lisible, la salle n'est jamais fermee.
export function lireSeance(ligne: unknown, depassementMin: unknown): SeanceVue | null {
  if (typeof ligne !== 'object' || ligne === null || Array.isArray(ligne)) return null
  const l = ligne as Record<string, unknown>
  // Une seance retiree (`deleted_at`) n'est ni en cours ni finie : rien n'en
  // est deduit, la salle n'est pas fermee sur cette seule lecture.
  if (l.deleted_at !== null && l.deleted_at !== undefined) return null
  const statut = typeof l.status === 'string' ? l.status : ''
  const fin = typeof l.ended_at === 'string' ? Date.parse(l.ended_at) : NaN
  if (!statut || Number.isNaN(fin)) return null
  return {
    cours: typeof l.session_type === 'string' &&
      (TYPES_DE_COURS as readonly string[]).includes(l.session_type),
    statut,
    finPrevueMs: fin,
    depassementMin: lireDepassement(depassementMin),
  }
}

/// Le depassement autorise lu dans `app_config` (un nombre, ou un nombre en
/// chaine). Absent ou invalide : la valeur par defaut de la base.
export function lireDepassement(valeur: unknown): number {
  const n = typeof valeur === 'number'
    ? valeur
    : typeof valeur === 'string' && /^[0-9]{1,4}$/.test(valeur.trim())
    ? Number(valeur.trim())
    : NaN
  return Number.isInteger(n) && n >= 0 && n <= 1440 ? n : DEPASSEMENT_PAR_DEFAUT_MIN
}

/// La seance est-elle finie pour la salle ? `cloture` : la base l'a close
/// (statut final). `depassement` : la fin prevue et le depassement autorise
/// sont passes (la porte d'entree est fermee). `non` : elle se tient encore,
/// ou la base n'a rien dit.
export function finDeSeance(
  seance: SeanceVue | null,
  maintenantMs: number,
): 'non' | 'depassement' | 'cloture' {
  if (seance === null) return 'non'
  if ((STATUTS_FINAUX as readonly string[]).includes(seance.statut)) return 'cloture'
  return maintenantMs > seance.finPrevueMs + seance.depassementMin * 60_000
    ? 'depassement'
    : 'non'
}

function estEleve(p: ParticipantVu): boolean {
  return p.deconnecte !== true && lireMetadonnees(p.metadata).role === ROLE_QUI_ATTEND
}

/// Les eleves presents dont le droit de publier n'est pas ferme.
export function elevesQuiPublient(participants: readonly ParticipantVu[]): string[] {
  return participants.filter((p) => estEleve(p) && p.peutPublier !== false).map((p) => p.identity)
}

/// Ce que le serveur doit faire d'une salle, maintenant.
export type DecisionSalle =
  /// Rien a faire.
  | { action: 'rien'; resteMs?: number }
  /// L'enseignant est la : la marque est levee (les droits sont rendus par
  /// `retablirPublication`).
  | { action: 'lever_echeance' }
  /// La salle vient d'etre vue sans enseignant : noter l'instant.
  | { action: 'poser_echeance'; depuis: number; resteMs: number }
  /// Le delai est passe : retirer aux eleves le droit de publier.
  | { action: 'fermer_micros'; eleves: string[] }
  /// La seance est finie et l'enseignant n'est plus la : fermer la salle.
  | { action: 'fermer_salle'; motif: 'depassement' | 'cloture' }

/// La decision, a partir de l'etat de la salle lu chez LiveKit
/// ([participants], [marque]) et de la seance lue en base ([seance], ou
/// `null` si elle ne se lit pas).
///
/// Elle ne lit que l'etat : un appel rejoue, en double ou en retard donne la
/// meme reponse.
export function deciderSalle(entree: {
  maintenantMs: number
  participants: readonly ParticipantVu[]
  marque: SansEnseignant | null
  seance: SeanceVue | null
  delaiS?: number
  fermerAvecEnseignant?: boolean
  /// L'evenement traite est le depart de l'enseignant lui-meme : le delai
  /// repart de maintenant, meme si une vieille marque trainait dans la salle
  /// (une marque non levee ne doit jamais fermer une classe a la premiere
  /// coupure de son enseignant).
  departEnseignant?: boolean
}): DecisionSalle {
  const { maintenantMs, seance } = entree
  const marque = entree.departEnseignant === true ? null : entree.marque
  // Un entretien, une reunion : la regle ne les concerne pas, rien n'y est
  // note ni ferme.
  if (seance !== null && !seance.cours) return { action: 'rien' }
  const delaiMs = (entree.delaiS ?? DELAI_SANS_ENSEIGNANT_S) * 1000
  const presents = entree.participants.filter((p) => p.deconnecte !== true)
  // Salle vide : LiveKit la ferme lui-meme (`departure_timeout`).
  if (presents.length === 0) return { action: 'rien' }

  const fin = finDeSeance(seance, maintenantMs)

  if (enseignantPresent(presents)) {
    // Un cours qui se tient n'est jamais coupe ici, meme apres la fin prevue
    // et le depassement : voir l'en-tete et D-018.
    if (
      fin === 'cloture' &&
      (entree.fermerAvecEnseignant ?? FERMER_A_LA_CLOTURE_MEME_AVEC_ENSEIGNANT)
    ) {
      return { action: 'fermer_salle', motif: 'cloture' }
    }
    return entree.marque === null ? { action: 'rien' } : { action: 'lever_echeance' }
  }

  // Sans enseignant, seance close en base : personne ne reviendra (la base
  // refuse tout jeton). La salle se ferme sans attendre.
  if (fin === 'cloture') return { action: 'fermer_salle', motif: 'cloture' }

  // Sans enseignant : l'instant est note a la premiere vue. Une marque
  // posee dans le futur (horloge deplacee) est reprise a maintenant.
  if (marque === null || marque.depuis > maintenantMs) {
    return { action: 'poser_echeance', depuis: maintenantMs, resteMs: delaiMs }
  }
  const resteMs = marque.depuis + delaiMs - maintenantMs
  if (resteMs > 0) return { action: 'rien', resteMs }

  // Le delai est passe et l'enseignant n'est pas revenu.
  if (fin === 'depassement') return { action: 'fermer_salle', motif: 'depassement' }
  const eleves = elevesQuiPublient(presents)
  return eleves.length > 0 ? { action: 'fermer_micros', eleves } : { action: 'rien' }
}

/// Une salle a examiner : sa route LiveKit et ce que la base sait de sa
/// seance.
export interface SalleASurveiller {
  provider: 'cloud' | 'self_hosted'
  ws_url: string
  room_name: string
  seance: SeanceVue
}

/// Lit les routes rendues par la base (`session_video_route` et sa seance).
/// Une ligne incomplete est ecartee, jamais devinee.
export function lireSallesASurveiller(
  donnees: unknown,
  depassementMin: unknown,
): SalleASurveiller[] {
  if (!Array.isArray(donnees)) return []
  const salles: SalleASurveiller[] = []
  for (const l of donnees) {
    if (typeof l !== 'object' || l === null) continue
    const r = l as Record<string, unknown>
    const seance = lireSeance(Array.isArray(r.sessions) ? r.sessions[0] : r.sessions, depassementMin)
    if (
      seance !== null &&
      // Seulement les cours : un entretien ou une reunion ne sont pas examines.
      seance.cours &&
      (r.provider === 'cloud' || r.provider === 'self_hosted') &&
      typeof r.ws_url === 'string' && r.ws_url !== '' &&
      typeof r.room_name === 'string' && r.room_name !== ''
    ) {
      salles.push({ provider: r.provider, ws_url: r.ws_url, room_name: r.room_name, seance })
    }
  }
  return salles
}
