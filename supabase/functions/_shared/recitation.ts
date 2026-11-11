// GESTES-POINTEUR (directeur, 11/11/2026, cahier de la salle §8) : « Faire
// reciter ne marche pas, et personne ne sait a quoi il sert. Donne-lui une
// vraie strategie. »
//
// La strategie, en une phrase : **pendant qu'un eleve recite, le serveur ferme
// le micro de ses camarades, pour qu'on n'entende que lui.**
//
//   * celui qui conduit la seance choisit un eleve present : le serveur retire
//     aux AUTRES eleves le droit de publier leur MICRO, et le leur rend a la
//     fin. Ce n'est jamais seulement a l'ecran : un client modifie n'y gagne
//     rien, LiveKit refuse sa piste ;
//   * **RECITATION-MICRO-SEUL (directeur, 11/11/2026) : leur camera reste.**
//     Le premier jet retirait le droit de publier d'un bloc (micro ET camera).
//     Depuis cette decision, un camarade garde le droit de publier sa camera
//     si son propre jeton le lui donne (`pub.camera`, signe par le serveur) et
//     perd seulement le micro. Un eleve dont la camera est interdite par son
//     profil n'en gagne jamais une par ce biais : pendant la recitation il n'a
//     ni micro ni camera. A la fin, chacun retrouve exactement les droits de
//     son propre jeton ;
//   * le micro du recitant n'est jamais ouvert de force : il l'ouvre lui-meme ;
//   * **la recitation ne tient que tant que l'enseignant ET le recitant sont
//     dans la salle.** Des que l'un des deux n'y est plus, elle se termine
//     d'elle-meme et tous les droits reviennent. Une classe ne reste jamais
//     bloquee muette : c'est la regle la plus importante de ce fichier.
//
// Ou vit l'etat : dans les **metadonnees de la salle LiveKit**, ecrites par le
// serveur seul (un participant ne peut pas les changer). Aucune table, aucune
// migration ; l'etat disparait avec la salle, donc avec la seance.
//
// Ce fichier ne porte que les decisions, en fonctions pures, sans reseau ni
// SDK : elles se testent seules (`recitation_test.ts`). Les appels a LiveKit
// vivent dans `livekit.ts`.

import {
  type DroitsPublication,
  droitsEnVigueur,
  type EleveARetablir,
  enseignantPresent,
  lireMetadonnees,
  type ParticipantVu,
  ROLE_QUI_ATTEND,
} from './publication_differee.ts'

/// La recitation en cours, telle que le serveur l'a ecrite dans la salle.
export interface Recitation {
  /// L'identite LiveKit de l'eleve qui recite (son profil).
  recitant: string
  /// Le moment ou elle a commence (millisecondes), pour le journal.
  depuis: number
}

/// La cle des metadonnees de la salle qui porte la recitation.
const CLE = 'recitation'

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

/// Lit la recitation dans les metadonnees de la salle. Absente ou illisible :
/// `null`, donc aucune recitation (dans le doute, la classe parle).
export function lireRecitation(metadonneesSalle: string | null | undefined): Recitation | null {
  const r = objetDe(metadonneesSalle)[CLE]
  if (typeof r !== 'object' || r === null || Array.isArray(r)) return null
  const objet = r as Record<string, unknown>
  const recitant = typeof objet.recitant === 'string' ? objet.recitant.trim() : ''
  if (!recitant) return null
  return { recitant, depuis: typeof objet.depuis === 'number' ? objet.depuis : 0 }
}

/// Les metadonnees de la salle avec la recitation posee ([recitation]) ou
/// retiree (`null`). Les autres cles sont gardees telles quelles.
export function ecrireRecitation(
  metadonneesSalle: string | null | undefined,
  recitation: Recitation | null,
): string {
  const objet = objetDe(metadonneesSalle)
  if (recitation === null) {
    delete objet[CLE]
  } else {
    objet[CLE] = { recitant: recitation.recitant, depuis: recitation.depuis }
  }
  return JSON.stringify(objet)
}

function estEleve(p: ParticipantVu): boolean {
  return p.deconnecte !== true && lireMetadonnees(p.metadata).role === ROLE_QUI_ATTEND
}

/// Vrai quand [identite] est un eleve present dans la salle.
export function elevePresent(participants: readonly ParticipantVu[], identite: string): boolean {
  return participants.some((p) => p.identity === identite && estEleve(p))
}

/// La recitation tient-elle encore ?
///
/// Seulement si celui qui conduit la seance ET le recitant sont dans la
/// salle. Sinon elle est finie, quoi que disent les metadonnees : la fonction
/// lit l'etat de la salle, jamais l'ordre des evenements.
export function recitationTenue(
  recitation: Recitation | null,
  participants: readonly ParticipantVu[],
): boolean {
  return recitation !== null &&
    enseignantPresent(participants) &&
    elevePresent(participants, recitation.recitant)
}

/// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : ce qu'un camarade a le
/// droit de publier pendant la recitation d'un autre. **Jamais le micro.** La
/// camera, seulement si son propre jeton la lui donne ([pub], signe par le
/// serveur : `camera_policy` du profil y est deja appliquee). Sans droits
/// lisibles dans son jeton, rien : on ne donne jamais ce qui n'est pas promis.
export function droitsPendantRecitation(pub: DroitsPublication | null): DroitsPublication {
  return { micro: false, camera: pub !== null && pub.camera === true }
}

/// Les camarades dont le serveur doit regler les droits pendant la
/// recitation : tout eleve present, sauf le recitant, dont les droits en
/// vigueur ne sont pas deja ceux de [droitsPendantRecitation]. Pour chacun,
/// les droits a poser.
///
/// Le cas ordinaire : micro et camera ouverts, il garde la camera seule.
/// Camera interdite par le profil : il perd tout. Deja regle : il n'est pas
/// retouche (un appel rejoue ne change rien). Ferme tout entier par une autre
/// regle alors que l'enseignant est la (droit pas encore rendu apres son
/// retour) : il retrouve sa camera, pas son micro.
///
/// A n'appeler que pour une recitation qui tient ([recitationTenue]), donc
/// avec l'enseignant dans la salle : c'est ce qui permet de laisser une
/// camera. L'enseignant, le tuteur, le controleur et l'administration ne sont
/// jamais touches.
export function camaradesARegler(
  participants: readonly ParticipantVu[],
  recitant: string,
): EleveARetablir[] {
  const liste: EleveARetablir[] = []
  for (const p of participants) {
    if (!estEleve(p) || p.identity === recitant) continue
    const voulus = droitsPendantRecitation(lireMetadonnees(p.metadata).pub)
    const actuels = droitsEnVigueur(p)
    if (actuels.micro === voulus.micro && actuels.camera === voulus.camera) continue
    liste.push({ identity: p.identity, droits: voulus })
  }
  return liste
}

/// Les eleves a qui rendre leurs droits quand la recitation se termine : tout
/// eleve present dont le micro est ferme alors que son jeton lui en
/// promettait un (`pub`, signe par le serveur). Chacun retrouve exactement
/// les droits de son propre jeton : le micro, et la camera seulement s'il
/// l'avait.
///
/// **Que l'enseignant soit la ou non** : si c'est lui qui est parti, les
/// camarades retrouvent ce qu'ils avaient avant la recitation. Jamais une
/// classe bloquee muette.
export function elevesARendre(participants: readonly ParticipantVu[]): EleveARetablir[] {
  const liste: EleveARetablir[] = []
  for (const p of participants) {
    if (!estEleve(p) || droitsEnVigueur(p).micro) continue
    const { pub } = lireMetadonnees(p.metadata)
    if (pub === null || !pub.micro) continue
    liste.push({ identity: p.identity, droits: pub })
  }
  return liste
}

/// Pendant une recitation qui tient, parmi les eleves que la regle ordinaire
/// voudrait retablir ([candidats]), seul le recitant l'est : les autres
/// restent fermes jusqu'a la fin.
export function retablisPendantRecitation(
  candidats: readonly EleveARetablir[],
  recitant: string,
): EleveARetablir[] {
  return candidats.filter((c) => c.identity === recitant)
}
