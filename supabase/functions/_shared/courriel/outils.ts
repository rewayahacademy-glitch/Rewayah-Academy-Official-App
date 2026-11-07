// Les petits outils communs aux textes de chaque langue (COURRIELS-1/2).
//
// Chaque langue ecrite a la main (`modeles_<code>.ts`) reutilise les memes
// outils : salutation, lien vers l'application, date en toutes lettres,
// message court « avis » et message libre de la direction. Le francais est la
// reference : ses parametres par defaut redonnent exactement ses textes.

import { APP, type Bloc, type Contenu, paragraphes } from './gabarit.ts'
import { villeDuFuseau } from './villes_fuseau.ts'

export type Donnees = Record<string, unknown>
export type Fabrique = (d: Donnees) => Omit<Contenu, 'raison'>

export interface Ligne {
  modele: string
  categorie: string
  donnees: Donnees
  essentielle: boolean
}

/// Une langue ecrite a la main : ses modeles, ses raisons, son libelle de
/// desinscription. Le francais est la reference ; les autres langues
/// s'enregistrent dans `LANGUES` (fichier `modeles.ts`). Une langue
/// absente, ou un modele absent d'une langue, est traduit du francais a
/// l'envoi (COURRIELS-2).
export interface LangueEcrite {
  modeles: Record<string, Fabrique>
  raisons: Record<string, string>
  desinscription: string
  droiteAGauche?: boolean
}

/// Les mots fixes d'une langue autour d'un message court.
export interface Parole {
  /// « Bonjour » ; suivi du prenom s'il existe.
  salut: string
  /// Ponctuation apres le salut (« , » ; « ، » en arabe).
  fin: string
  /// Salut sans prenom (l'invitation, ecrite a quelqu'un qui n'a pas de compte).
  salutSeul: string
  /// Note au pied de chaque avis.
  note: string
  /// Sujet d'un message libre sans sujet.
  sujetLibre: string
  /// Locale Intl pour les dates en toutes lettres.
  locale: string
}

export const PAROLE_FR: Parole = {
  salut: 'Bonjour',
  fin: ',',
  salutSeul: 'Bonjour,',
  note: 'Le détail se trouve dans l’application, une fois connecté.',
  sujetLibre: 'Un message de Rewayah Academy',
  locale: 'fr-FR',
}

export function bonjour(d: Donnees, p: Parole = PAROLE_FR): string {
  const prenom = typeof d.prenom === 'string' && d.prenom.trim() ? ` ${d.prenom.trim()}` : ''
  return `${p.salut}${prenom}${p.fin}`
}

export function lienApp(d: Donnees, repli: string): string {
  const dest = typeof d.destination === 'string' && /^\/[a-z][a-z0-9/_-]*$/.test(d.destination) ? d.destination : repli
  // L'application route sur le fragment : /#/chemin (CAND-04, 06/11/2026).
  return `${APP}/#${dest}`
}

export function dateLongue(v: unknown, locale = 'fr-FR'): string | null {
  if (typeof v !== 'string') return null
  const t = new Date(v)
  if (Number.isNaN(t.getTime())) return null
  return new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' })
    .format(t)
}

/// « 165,00 $US » : le montant d'une commande (`montant_mineur`, en centimes,
/// et `devise` ISO), ecrit dans la langue du destinataire. Nul quand les
/// donnees manquent ou sont illisibles : le modele ecrit alors sans montant.
export function montantLisible(d: Donnees, locale = 'fr-FR'): string | null {
  const m = d.montant_mineur
  const devise = d.devise
  if (typeof m !== 'number' || !Number.isFinite(m)) return null
  if (typeof devise !== 'string' || !/^[A-Za-z]{3}$/.test(devise)) return null
  try {
    return new Intl.NumberFormat(locale, { style: 'currency', currency: devise.toUpperCase() }).format(m / 100)
  } catch {
    return null
  }
}

/// COURRIELS-UX (UX-026, UX-030, 03/11/2026) : « heure de Paris » : la ville du
/// fuseau `fuseau`, la meme que dans l'application (`villes_fuseau.ts`), dans
/// la langue de `locale` ; nul quand le fuseau manque ou est illisible.
const HEURE_DE: Record<string, (ville: string) => string> = {
  fr: (v) => `heure de ${v}`,
  en: (v) => `${v} time`,
  ar: (v) => `بتوقيت ${v}`,
  es: (v) => `hora de ${v}`,
  pt: (v) => `hora de ${v}`,
}

export function heureDeLaVille(d: Donnees, locale = 'fr-FR'): string | null {
  const langue = locale.slice(0, 2).toLowerCase()
  const ville = villeDuFuseau(d.fuseau, langue)
  if (!ville) return null
  return (HEURE_DE[langue] ?? HEURE_DE.fr)(ville)
}

/// Le nom de la classe (`classe`, pose par le serveur), ou nul.
export function nomClasse(d: Donnees): string | null {
  return typeof d.classe === 'string' && d.classe.trim() ? d.classe.trim() : null
}

/// Les prenoms des eleves du foyer concernes (`eleves`, portee `foyer`
/// seulement), joints dans la langue (« Lina et Yanis ») ; nul sans prenom.
export function prenomsEleves(d: Donnees, locale = 'fr-FR'): { texte: string; plusieurs: boolean } | null {
  const v = Array.isArray(d.eleves) ? d.eleves.filter((x): x is string => typeof x === 'string' && x.trim() !== '') : []
  if (v.length === 0) return null
  const noms = v.map((x) => x.trim())
  let texte = noms.join(', ')
  try {
    texte = new Intl.ListFormat(locale, { style: 'long', type: 'conjunction' }).format(noms)
  } catch { /* liste simple */ }
  return { texte, plusieurs: noms.length > 1 }
}

/// Les mots, dans une langue, des precisions ajoutees a un avis de classe.
export interface Precisions {
  locale: string
  /// Mot entre la date et l'heure (« à », « at », « الساعة »).
  a: string
  classe: (nom: string) => string
  eleves: (noms: string, plusieurs: boolean) => string
  premiere: (quand: string) => string
}

/// La date et l'heure locales d'une cle (`debut_local` ou `prochaine_local`,
/// « AAAA-MM-JJTHH:MM:SS », deja dans le fuseau du destinataire), suivies de
/// la ville de ce fuseau entre parentheses quand le serveur le donne (UX-026,
/// UX-030) : « 6 novembre 2026 à 18:00 (heure de Paris) ». Nul sans date.
export function quandLocal(d: Donnees, cle: string, locale = 'fr-FR', a = 'à'): string | null {
  const v = d[cle]
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/.test(v)) return null
  const jour = dateLongue(v.slice(0, 10), locale)
  if (!jour) return null
  const zone = heureDeLaVille(d, locale)
  return `${jour} ${a} ${v.slice(11, 16)}${zone ? ` (${zone})` : ''}`
}

/// Les precisions d'un avis de classe, en phrases courtes : la classe, les
/// eleves du foyer, la prochaine seance. Chaine vide quand rien n'est connu.
export function precisions(
  d: Donnees, p: Precisions, quoi: { eleves?: boolean; premiere?: boolean } = {},
): string {
  const parts: string[] = []
  const c = nomClasse(d)
  if (c) parts.push(p.classe(c))
  const e = quoi.eleves === false ? null : prenomsEleves(d, p.locale)
  if (e) parts.push(p.eleves(e.texte, e.plusieurs))
  const q = quoi.premiere ? quandLocal(d, 'prochaine_local', p.locale, p.a) : null
  if (q) parts.push(p.premiere(q))
  return parts.join(' ')
}

/// Une phrase suivie de ses precisions, separees d'une espace.
export function avec(phrase: string, suite: string): string {
  return suite ? `${phrase} ${suite}` : phrase
}

/// Un message court qui renvoie vers l'application, dans la langue de `p`.
export function avisDans(p: Parole) {
  return (
    d: Donnees, sujet: string, titre: string, phrase: string, bouton: string, repli: string,
  ): Omit<Contenu, 'raison'> => ({
    sujet,
    apercu: phrase,
    titre,
    blocs: [
      { type: 'texte', texte: bonjour(d, p) },
      { type: 'texte', texte: phrase },
      { type: 'bouton', libelle: bouton, href: lienApp(d, repli) },
      { type: 'note', texte: p.note },
    ],
  })
}

/// Un message ecrit par la direction : sujet et corps tels quels.
export function libre(d: Donnees, sujetParDefaut = PAROLE_FR.sujetLibre): Omit<Contenu, 'raison'> {
  const sujet = typeof d.sujet === 'string' ? d.sujet : sujetParDefaut
  const corps = typeof d.corps === 'string' ? d.corps : ''
  const blocs: Bloc[] = paragraphes(corps).map((texte) => ({ type: 'texte', texte }))
  return { sujet, apercu: blocs[0]?.type === 'texte' ? blocs[0].texte.slice(0, 120) : sujet, titre: sujet, blocs }
}
