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
export const MOTIFS_SALLE = ['pas_encore_ouverte', 'terminee', 'annulee', 'acces_perdu'] as const
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
