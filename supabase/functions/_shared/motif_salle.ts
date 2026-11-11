// FN-025 (lot « Fin de seance », etape 2) : la raison d'un refus de salle,
// telle que la base la rend a qui y a droit (`public.motif_refus_salle`).
//
// La base decide seule qui apprend le motif : un appelant qui n'est ni
// participant, ni enseignant effectif, ni tuteur d'un eleve inscrit recoit
// NULL, et le refus reste le 403 generique. Ici, on ne fait que verifier la
// forme de la reponse : une valeur inattendue vaut « aucun motif ».

/// Les motifs que la base peut rendre.
// `acces_perdu` (PR 124, 01/11/2026) : le titulaire ecarte par l'absence
// automatique (A3). Sans lui dans cette liste, la base le rendait mais l'ecran
// retombait sur le refus generique (capture R3 du banc local).
// `titulaire_entre`, `remplacant_entre` (A3-bis, 03/11/2026) : apres une prise
// de remplacement, le premier des deux enseignants entre ferme la porte a
// l'autre, qui lit qui est entre (decision du directeur du 03/11).
// `seance_reportee` (SNT, 03/11/2026) : personne n'est entre a T+30, la seance
// est reportee ; quiconque y avait droit lit pourquoi la salle ne s'ouvre plus.
// SITUATIONS-GRAVES (directeur, 11/11/2026, defaut n° 8 du releve) : les
// refus qui ne dependent que de l'appelant lui-meme (compte, acces suspendu,
// sortie par l'enseignant, temps d'observation epuise) et le refus d'une
// seance qui n'est pas la sienne (`non_inscrit`). Ils sont lus dans la raison
// de `autoriser_jeton_video` ([motifPersonnel], [motifHorsSeance]), jamais
// recus du client.
export const MOTIFS_SALLE = [
  'pas_encore_ouverte', 'terminee', 'annulee', 'acces_perdu', 'titulaire_entre', 'remplacant_entre',
  'seance_reportee', 'non_inscrit', 'acces_suspendu', 'sorti', 'observation_terminee',
  'compte_invalide',
] as const
export type MotifSalle = (typeof MOTIFS_SALLE)[number]

/// Ce qui accompagne le 403 quand la base donne un motif.
export interface DetailRefusSalle {
  motif: MotifSalle
  fin_utc: string | null
  ouverture_utc: string | null
  grace_minutes: number | null
}

function horodatage(v: unknown): string | null {
  return typeof v === 'string' && !Number.isNaN(Date.parse(v)) ? v : null
}

/// Lit la reponse de `motif_refus_salle`, ou `null` si elle ne porte aucun
/// motif connu (NULL, forme inattendue).
export function lireMotifSalle(valeur: unknown): DetailRefusSalle | null {
  if (valeur === null || typeof valeur !== 'object' || Array.isArray(valeur)) return null
  const v = valeur as Record<string, unknown>
  const motif = v.motif
  if (typeof motif !== 'string' || !(MOTIFS_SALLE as readonly string[]).includes(motif)) return null
  const grace = v.grace_minutes
  return {
    motif: motif as MotifSalle,
    fin_utc: horodatage(v.fin_utc),
    ouverture_utc: horodatage(v.ouverture_utc),
    grace_minutes: typeof grace === 'number' && Number.isInteger(grace) && grace >= 0 ? grace : null,
  }
}

/// Un detail sans heures, pour un motif lu dans la raison du refus.
function sansHeures(motif: MotifSalle): DetailRefusSalle {
  return { motif, fin_utc: null, ouverture_utc: null, grace_minutes: null }
}

/// SITUATIONS-GRAVES : le refus qui ne depend que de l'appelant, lu dans la
/// raison levee par `autoriser_jeton_video` (ou sa variante tuteur). Chacune
/// n'est levee qu'APRES que la base a reconnu l'appelant comme eleve, enseignant
/// ou observateur de CETTE seance (ou, pour le compte, ne parle que de lui) :
/// la dire ne revele rien d'une seance qui n'est pas la sienne. Aucun montant,
/// aucune regle d'argent : « acces suspendu » seulement.
export function motifPersonnel(raison: string | null | undefined): DetailRefusSalle | null {
  const r = String(raison ?? '')
  if (r.startsWith('compte non valide') || r.startsWith('tuteur non valide')) return sansHeures('compte_invalide')
  if (r.startsWith('acces suspendu pour paiement')) return sansHeures('acces_suspendu')
  if (r.startsWith("sorti de la seance par l'enseignant")) return sansHeures('sorti')
  if (r.startsWith("quota d'observation atteint")) return sansHeures('observation_terminee')
  return null
}

/// SITUATIONS-GRAVES : la seance n'est pas celle de l'appelant. A n'employer
/// qu'apres `motif_refus_salle` rendu NULL (l'appelant n'y a pas droit) :
/// seance inconnue, close ou sans lui donnent alors la MEME reponse, et rien
/// n'apprend si elle existe.
export function motifHorsSeance(raison: string | null | undefined): DetailRefusSalle | null {
  const r = String(raison ?? '')
  return [
    'non inscrit a cette seance',
    'seance introuvable',
    'seance close',
    'eleve hors du foyer',
    'role refuse par ce chemin',
  ].some((m) => r.startsWith(m))
    ? sansHeures('non_inscrit')
    : null
}

/// SITUATIONS-GRAVES : une panne (base injoignable, erreur inattendue) n'est
/// pas un refus. Les refus de `autoriser_jeton_video` sont tous leves avec un
/// code SQL connu ; toute autre forme est une panne, dite comme telle.
export function estPanne(erreur: { code?: string | null } | null | undefined): boolean {
  if (!erreur) return true
  return !['42501', '23514', 'P0002', 'P0001', '02000'].includes(String(erreur.code ?? ''))
}
