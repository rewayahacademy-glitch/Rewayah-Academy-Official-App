// La convention de cles d'objets, et le seul endroit qui a le droit d'en
// fabriquer une.
//
// Deux regles, et elles se tiennent l'une l'autre :
//
//   1. **Une cle est fabriquee par le serveur, jamais recue du client.** Un
//      `object_key` qui arrive dans un corps de requete est une demande, pas une
//      designation -- exactement comme un `profile_id` recu du client est une
//      demande et non une identite (doctrine de `create-room-token`). Les points
//      d'entree parlent donc en identifiants metier (`document_id`,
//      `recording_id`) et cette couche en deduit la cle.
//   2. **Une cle ne porte aucune donnee lisible.** Pas de nom, pas de courriel,
//      pas de numero de piece, pas de genre. Rien que des UUID opaques. Une cle
//      voyage dans des journaux, des URL et des tableaux de bord Cloudflare : ce
//      qu'elle porte est, en pratique, publie a l'interieur de l'organisation.
//
// Le genre merite sa propre phrase, parce que c'est le piege specifique de ce
// projet : dans `kyc_documents`, le genre du dossier decide QUI peut l'ouvrir
// (migration `0004`). L'ecrire dans un chemin de fichier exposerait une donnee
// de cloisonnement sous une forme que ni la RLS ni le journal d'audit ne
// gouvernent.
//
// `verifierCle()` existe pour le chemin inverse : quand une cle nous revient de
// l'exterieur -- typiquement le `filepath` qu'un Egress LiveKit annonce apres
// coup -- elle est confrontee a la convention avant d'entrer en base. On ne fait
// pas confiance a ce qu'un fournisseur renvoie, meme signe.

import type { DomaineStockage } from './domaines.ts'

/// Le prefixe de premier niveau de chaque domaine.
const PREFIXE_CLE: Record<DomaineStockage, string> = {
  pieceIdentite: 'identity',
  archiveSeance: 'recordings',
  pieceJointeMessage: 'messages',
  priveApplicatif: 'private',
}

/// La forme canonique d'un UUID, en minuscules. La casse est imposee : deux
/// cles qui ne different que par la casse designent deux objets distincts chez
/// R2, et une convention qui tolere les deux finit par en creer deux.
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

/// L'echec de construction ou de validation d'une cle.
export class ErreurCleObjet extends Error {
  readonly motif: string

  constructor(motif: string) {
    super(`cle d objet invalide : ${motif}`)
    this.name = 'ErreurCleObjet'
    this.motif = motif
  }
}

function exigerUuid(valeur: string, role: string): string {
  const normalise = valeur.trim().toLowerCase()
  if (!UUID.test(normalise)) {
    // Le role suffit a situer la faute ; la valeur refusee n'est pas reprise,
    // un identifiant recu d'un client n'ayant aucune raison d'entrer dans un
    // journal avant d'avoir ete reconnu.
    throw new ErreurCleObjet(`${role} n est pas un UUID`)
  }
  return normalise
}

/// La cle d'une piece d'identite.
///
///   identity/<profile_id>/<document_id>
///
/// Le premier segment est l'identifiant du profil TITULAIRE de la piece. Ce
/// choix n'est pas esthetique : c'est deja la forme employee par le stockage
/// Supabase actuel (`<auth.uid()>/<horodatage>.<ext>`, pose par
/// `service_dossier.dart`), ou la politique `kyc_depot_self` compare ce premier
/// segment a `auth.uid()`. Garder le profil en tete conserve ce rapprochement
/// et rend un objet orphelin rattachable a son dossier.
///
/// Pas d'extension : le type de piece vit dans `kyc_documents.doc_type`, ou la
/// RLS le gouverne. Le repeter dans un nom de fichier le sortirait de sa garde.
export function cleDe(_domaine: 'pieceIdentite', profilId: string, documentId: string): string
export function cleDe(_domaine: 'archiveSeance', seanceId: string, archiveId: string): string
export function cleDe(_domaine: 'pieceJointeMessage', conversationId: string, pieceId: string): string
export function cleDe(_domaine: 'priveApplicatif', ressource: string, ressourceId: string): string
export function cleDe(domaine: DomaineStockage, parent: string, enfant: string): string {
  const prefixe = PREFIXE_CLE[domaine]

  if (domaine === 'priveApplicatif') {
    // Le seul domaine dont le premier segment n'est pas un UUID : il classe par
    // famille de ressource. La liste reste fermee pour que ce segment ne
    // devienne pas un champ libre ecrit par un appelant.
    const famille = parent.trim().toLowerCase()
    if (!/^[a-z][a-z0-9_]{1,31}$/.test(famille)) {
      throw new ErreurCleObjet('famille de ressource hors convention')
    }
    return `${prefixe}/${famille}/${exigerUuid(enfant, 'identifiant de ressource')}`
  }

  const roles: Record<string, [string, string]> = {
    pieceIdentite: ['identifiant de profil', 'identifiant de document'],
    archiveSeance: ['identifiant de seance', 'identifiant d archive'],
    pieceJointeMessage: ['identifiant de conversation', 'identifiant de piece jointe'],
  }
  const [roleParent, roleEnfant] = roles[domaine]

  const debut = `${prefixe}/${exigerUuid(parent, roleParent)}/${exigerUuid(enfant, roleEnfant)}`

  // L'archive audio est le seul objet dont l'extension est utile : c'est
  // LiveKit Egress qui ecrit le fichier, en `audio_only` (ADR-002), et le
  // conteneur fait partie du contrat passe a Egress. Elle ne revele rien.
  return domaine === 'archiveSeance' ? `${debut}${EXTENSION_ARCHIVE}` : debut
}

/// Le conteneur des archives audio. `audio_only` en OGG/Opus, conformement a
/// l'ADR-002. Centralise ici parce que le chemin d'Egress et le chemin de
/// lecture doivent s'accorder au caractere pres.
export const EXTENSION_ARCHIVE = '.ogg'

/// Confronte une cle venue de l'exterieur a la convention du domaine.
///
/// Rend la cle normalisee, ou leve. Sert pour le `filepath` annonce par un
/// evenement `egress_ended` : LiveKit choisit le nom du fichier a partir du
/// gabarit qu'on lui a donne, mais l'evenement qui l'annonce reste une donnee
/// recue, et une donnee recue se verifie avant d'entrer en base.
export function verifierCle(domaine: DomaineStockage, cle: string): string {
  const normalise = cle.trim().replace(/^\/+/, '')
  if (normalise === '' || normalise.length > 512) {
    throw new ErreurCleObjet('longueur hors bornes')
  }
  // Aucune remontee de chemin, aucun segment vide, aucun caractere de controle.
  if (normalise.includes('..') || normalise.includes('//') || /[\u0000-\u001f]/.test(normalise)) {
    throw new ErreurCleObjet('chemin non canonique')
  }

  const segments = normalise.split('/')
  if (segments[0] !== PREFIXE_CLE[domaine]) {
    throw new ErreurCleObjet(`prefixe etranger au domaine ${domaine}`)
  }
  if (segments.length !== 3) {
    throw new ErreurCleObjet('profondeur hors convention')
  }

  if (domaine === 'priveApplicatif') {
    if (!/^[a-z][a-z0-9_]{1,31}$/.test(segments[1])) {
      throw new ErreurCleObjet('famille de ressource hors convention')
    }
    exigerUuid(segments[2], 'identifiant de ressource')
    return normalise
  }

  exigerUuid(segments[1], 'deuxieme segment')
  const dernier = domaine === 'archiveSeance'
    ? segments[2].slice(0, -EXTENSION_ARCHIVE.length)
    : segments[2]
  if (domaine === 'archiveSeance' && !segments[2].endsWith(EXTENSION_ARCHIVE)) {
    throw new ErreurCleObjet('conteneur audio inattendu')
  }
  exigerUuid(dernier, 'troisieme segment')

  return normalise
}
