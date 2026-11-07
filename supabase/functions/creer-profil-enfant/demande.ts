// La lecture de la demande de creer-profil-enfant, sans reseau ni cle : ce
// qui se decide avant de creer quoi que ce soit, isole pour etre teste
// (index_test.ts).
//
// MINEUR-FANTOME (directeur, 07/11/2026 ; correctif du garde-cap le meme jour) :
//   * 18 ans ou plus : refus, mot pour mot celui de public.creer_profil_enfant
//     (20261110340000), que le client reconnait par « age adulte » ;
//   * le genre : male ou female (enum public.gender en production, releve du
//     pilote le 07/11/2026 a 07:50 UTC). ABSENT, il est TOLERE, comme dans la
//     RPC (regle B6) : le chemin d'admission (profils_demande.dart) n'a pas
//     toujours le genre de l'enfant et ne doit jamais etre bloque. Une valeur
//     presente hors de la liste est refusee (« genre_requis »).
//   * le genre voyage dans app_metadata seulement, jamais user_metadata (que
//     l'utilisateur peut ecrire) : la RPC le lit la.

/// Le refus des 18 ans et plus.
export const REFUS_ADULTE =
  'age adulte : un profil eleve de 18 ans ou plus ne se cree pas ici ; pour soi-meme, creer mon profil eleve'

/// Les valeurs de public.gender.
export const GENRES = ['male', 'female'] as const

/// Un genre de public.gender.
export type Genre = (typeof GENRES)[number]

/// Une demande lisible, ou la raison du refus.
export type Demande =
  | { ok: true; prenom: string; nom: string; age: number; niveau: string | null; genre: Genre | null }
  | { ok: false; erreur: string }

/// Lit le corps JSON de la requete.
export function lireDemande(corps: Record<string, unknown>): Demande {
  const prenom = String(corps.first_name ?? '').trim()
  const nom = String(corps.last_name ?? '').trim()
  const age = Number(corps.age)
  const niveau = corps.level == null ? null : String(corps.level)

  if (!prenom || !nom || !Number.isInteger(age)) {
    return { ok: false, erreur: 'prenom, nom et age sont requis' }
  }
  if (age >= 18) {
    return { ok: false, erreur: REFUS_ADULTE }
  }

  let genre: Genre | null = null
  if (corps.gender != null) {
    const valeur = String(corps.gender)
    if (!(GENRES as readonly string[]).includes(valeur)) {
      return { ok: false, erreur: 'genre_requis' }
    }
    genre = valeur as Genre
  }
  return { ok: true, prenom, nom, age, niveau, genre }
}

/// L'app_metadata du compte cree : le tuteur, et le genre s'il est connu.
export function metadonneesApp(tuteurId: string, genre: Genre | null): Record<string, string> {
  return genre == null ? { child_of: tuteurId } : { child_of: tuteurId, gender: genre }
}
