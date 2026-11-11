// MICRO-AVANT-ENSEIGNANT (decision du directeur du 11/11/2026, defaut SEC-1 de
// `docs/current/salle/CONSTAT.md`).
//
// Les eleves entrent dans la salle jusqu'a vingt minutes avant l'heure. Tant
// que l'enseignant n'y est pas, un eleve ne peut ouvrir ni son micro ni sa
// camera : des enfants ne se parlent pas, micro ouvert, sans adulte.
//
// **La regle est tenue par le serveur LiveKit** (les droits du participant),
// jamais par l'ecran : un client modifie n'y gagne rien.
//
// Ce fichier ne porte que les decisions, en fonctions pures, sans reseau ni
// SDK : elles se testent seules (`publication_differee_test.ts`). Les appels
// a LiveKit vivent dans `livekit.ts`, seul fichier autorise a importer le SDK.
//
// Trois choix, ecrits ici pour qu'ils se relisent :
//
//   * **qui ouvre les micros** : le role `teacher` du jeton, donc l'enseignant
//     effectif de la seance (l'attitre, ou le remplacant designe). C'est la
//     base qui pose ce role, et le serveur qui le signe dans les metadonnees :
//     un participant ne peut pas se le donner ;
//   * **qui attend** : le role `student`, enfant comme adulte. La decision
//     parle des enfants ; l'appliquer a tous les eleves est plus simple et
//     plus sur (point a confirmer par le directeur) ;
//   * **dans le doute, la classe parle** : si LiveKit ne repond pas quand on
//     lui demande qui est la, le jeton part avec ses droits ordinaires. Un
//     eleve reste muet devant son enseignant serait pire que le defaut.

/// Le role qui conduit la seance : sa presence ouvre les micros.
export const ROLE_QUI_CONDUIT = 'teacher'

/// Le role dont la publication attend l'enseignant.
export const ROLE_QUI_ATTEND = 'student'

/// Ce que le serveur sait de la presence de l'enseignant dans la salle.
/// `inconnue` : LiveKit n'a pas repondu (panne, delai).
export type PresenceEnseignant = 'present' | 'absent' | 'inconnue'

/// Les droits de publication decides par la base (`autoriser_jeton_video`).
export interface CapacitesPublication {
  can_publish: boolean
  can_publish_video: boolean
}

/// Les droits qu'un eleve retrouve a l'entree de l'enseignant. Ils voyagent
/// dans les metadonnees du jeton, signees par le serveur.
export interface DroitsPublication {
  micro: boolean
  camera: boolean
}

/// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : une source de publication
/// que les regles lisent. Les autres sources de LiveKit (partage d'ecran)
/// ne sont jamais accordees a un eleve et ne sont pas lues.
export type SourcePublication = 'micro' | 'camera'

/// Un participant de la salle, reduit a ce que la regle lit.
export interface ParticipantVu {
  identity: string
  /// Les metadonnees du jeton (JSON), telles que LiveKit les rend.
  metadata?: string | null
  /// Le droit de publier en vigueur (`permission.canPublish`).
  peutPublier?: boolean
  /// RECITATION-MICRO-SEUL : les sources auxquelles le droit de publier est
  /// borne (`permission.canPublishSources`), reduites au micro et a la
  /// camera. **Absent : aucune borne**, toutes les sources (regle de LiveKit
  /// pour une liste vide). Une liste, meme vide : seulement celles-la.
  sourcesPermises?: readonly SourcePublication[]
  /// LiveKit le dit deja parti.
  deconnecte?: boolean
}

/// Un eleve a qui rendre ses droits.
export interface EleveARetablir {
  identity: string
  droits: DroitsPublication
}

/// Les metadonnees d'un jeton : le role toujours, et pour un eleve les droits
/// de publication que la base lui a donnes (`pub`).
export function metadonneesDuJeton(role: string, capacites: CapacitesPublication): string {
  if (role !== ROLE_QUI_ATTEND) {
    return JSON.stringify({ role })
  }
  return JSON.stringify({
    role,
    pub: {
      micro: capacites.can_publish === true,
      camera: capacites.can_publish === true && capacites.can_publish_video === true,
    },
  })
}

/// Lit les metadonnees d'un participant. Une metadonnee absente ou illisible
/// ne donne ni role ni droit : rien n'est suppose.
export function lireMetadonnees(
  brut: string | null | undefined,
): { role: string; pub: DroitsPublication | null } {
  if (!brut) return { role: '', pub: null }
  let decode: unknown
  try {
    decode = JSON.parse(brut)
  } catch {
    return { role: '', pub: null }
  }
  if (typeof decode !== 'object' || decode === null || Array.isArray(decode)) {
    return { role: '', pub: null }
  }
  const objet = decode as Record<string, unknown>
  const role = typeof objet.role === 'string' ? objet.role : ''
  const pub = objet.pub
  if (typeof pub !== 'object' || pub === null || Array.isArray(pub)) {
    return { role, pub: null }
  }
  const p = pub as Record<string, unknown>
  return { role, pub: { micro: p.micro === true, camera: p.camera === true } }
}

/// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : les droits de publication
/// EN VIGUEUR chez LiveKit pour ce participant, source par source.
///
/// Depuis ce lot, « le droit est ferme » ne se lit plus sur un seul booleen :
/// pendant une recitation, un camarade garde `canPublish` (pour sa camera) et
/// perd le micro par la liste des sources. Chaque regle lit donc ce qu'elle
/// protege :
///
///   * rendre un micro (MICRO-AVANT-ENSEIGNANT, fin de recitation) : le micro
///     est ferme, c'est-a-dire `micro === false` ici ;
///   * fermer apres le depart de l'enseignant (FERMETURE-SALLE) : il reste
///     quelque chose a fermer, c'est-a-dire `peutPublier !== false`.
///
/// Un participant sans permission lue (`peutPublier` absent) est tenu pour
/// ouvert, comme avant ce lot : il sera ferme si une regle le demande, et rien
/// ne lui sera « rendu » sur une lecture incomplete.
export function droitsEnVigueur(p: ParticipantVu): DroitsPublication {
  if (p.peutPublier === false) return { micro: false, camera: false }
  const sources = p.sourcesPermises
  if (sources === undefined) return { micro: true, camera: true }
  return { micro: sources.includes('micro'), camera: sources.includes('camera') }
}

/// RECITATION-MICRO-SEUL : la permission LiveKit qui realise [droits].
///
/// **Jamais `canPublish` avec une liste vide** : LiveKit lit une liste vide
/// comme « toutes les sources ». Sans micro ni camera, le droit de publier
/// est donc retire tout entier.
export function permissionDePublication(
  droits: DroitsPublication,
): { canPublish: boolean; sources: SourcePublication[] } {
  const sources: SourcePublication[] = []
  if (droits.micro) sources.push('micro')
  if (droits.camera) sources.push('camera')
  return { canPublish: sources.length > 0, sources }
}

/// Vrai quand celui qui conduit la seance est dans la salle.
export function enseignantPresent(participants: readonly ParticipantVu[]): boolean {
  return participants.some(
    (p) => p.deconnecte !== true && lireMetadonnees(p.metadata).role === ROLE_QUI_CONDUIT,
  )
}

/// La decision du jeton : faut-il le signer sans droit de publier ?
///
/// Seulement pour un eleve qui aurait le droit de publier, et seulement quand
/// le serveur SAIT que l'enseignant n'est pas la. L'enseignant, le remplacant,
/// l'administration visible ne sont jamais differes ; le tuteur en observation
/// et le controleur ne publient jamais et ne changent pas.
export function doitDifferer(
  role: string,
  capacites: CapacitesPublication,
  presence: PresenceEnseignant,
): boolean {
  return role === ROLE_QUI_ATTEND && capacites.can_publish === true && presence === 'absent'
}

/// Les eleves a qui rendre leurs droits : aucun tant que l'enseignant n'est
/// pas dans la salle ; ensuite, tout eleve present dont le micro est ferme
/// alors que son jeton lui en promettait un.
///
/// RECITATION-MICRO-SEUL (11/11/2026) : « ferme » se lit sur le micro
/// ([droitsEnVigueur]), plus sur `canPublish` seul. Un eleve reste avec sa
/// seule camera apres une recitation dont la fin s'est mal passee (LiveKit
/// muet au moment de rendre) est ainsi retabli par la regle ordinaire, au
/// prochain evenement ou par le filet : il ne reste jamais sans micro devant
/// son enseignant. Un eleve ferme tout entier (avant l'enseignant, apres son
/// depart) se lit comme avant.
///
/// La fonction lit l'etat de la salle, jamais l'ordre des evenements : un
/// webhook rejoue, en retard ou en double donne le meme resultat.
export function elevesARetablir(participants: readonly ParticipantVu[]): EleveARetablir[] {
  if (!enseignantPresent(participants)) return []
  const liste: EleveARetablir[] = []
  for (const p of participants) {
    if (p.deconnecte === true || droitsEnVigueur(p).micro) continue
    const { role, pub } = lireMetadonnees(p.metadata)
    if (role !== ROLE_QUI_ATTEND || pub === null || !pub.micro) continue
    liste.push({ identity: p.identity, droits: pub })
  }
  return liste
}
