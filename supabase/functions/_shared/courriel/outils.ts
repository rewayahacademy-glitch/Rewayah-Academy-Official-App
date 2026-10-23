// Les petits outils communs aux textes de chaque langue (COURRIELS-1/2).
//
// Chaque langue ecrite a la main (`modeles_<code>.ts`) reutilise les memes
// outils : salutation, lien vers l'application, date en toutes lettres,
// message court « avis » et message libre de la direction. Le francais est la
// reference : ses parametres par defaut redonnent exactement ses textes.

import { APP, type Bloc, type Contenu, paragraphes } from './gabarit.ts'

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
  return `${APP}${dest}`
}

export function dateLongue(v: unknown, locale = 'fr-FR'): string | null {
  if (typeof v !== 'string') return null
  const t = new Date(v)
  if (Number.isNaN(t.getTime())) return null
  return new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' })
    .format(t)
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
