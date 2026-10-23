// Le registre des langues des e-mails et le choix du texte a envoyer
// (COURRIELS-1 et 2). Les textes vivent un par langue : `modeles_fr.ts`
// (reference), `modeles_en.ts`, `modeles_ar.ts`, `modeles_es.ts`,
// `modeles_pt.ts`. Les outils communs sont dans `outils.ts`. Une langue non
// ecrite part traduite du francais a l'envoi (traduction.ts).

import { type Contenu, SITE } from './gabarit.ts'
import { FRANCAIS, MODELES, RAISON } from './modeles_fr.ts'
import { ANGLAIS } from './modeles_en.ts'
import { ARABE } from './modeles_ar.ts'
import { ESPAGNOL } from './modeles_es.ts'
import { PORTUGAIS } from './modeles_pt.ts'
import type { Fabrique, LangueEcrite, Ligne } from './outils.ts'

export type { LangueEcrite, Ligne }
export { FRANCAIS }

export const LANGUES: Record<string, LangueEcrite> = {
  fr: FRANCAIS,
  en: ANGLAIS,
  ar: ARABE,
  es: ESPAGNOL,
  pt: PORTUGAIS,
}

/// Ce que le travailleur doit faire pour une ligne de la file : le contenu,
/// et la langue d'ou le traduire si la langue demandee n'est pas ecrite.
export interface Rendu {
  contenu: Contenu
  /// Langue source a traduire vers `langue` ; absente quand rien n'est a traduire.
  traduireDepuis?: string
}

export function contenuPour(l: Ligne, langue = 'fr'): Contenu {
  return rendre(l, langue).contenu
}

export function rendre(l: Ligne, langue = 'fr'): Rendu {
  const d = l.donnees ?? {}
  // Un message ecrit par la direction est dans sa langue d'ecriture.
  const libre = l.modele === 'message_libre' || l.modele === 'nouvelles'
  const source = libre && typeof d.langue_source === 'string' ? d.langue_source : 'fr'
  const ecrite: LangueEcrite | undefined = libre ? LANGUES[source] ?? FRANCAIS : LANGUES[langue]
  const fabrique: Fabrique | undefined = ecrite?.modeles[l.modele]
  const base: LangueEcrite = fabrique !== undefined && ecrite !== undefined ? ecrite : FRANCAIS
  const m = fabrique ?? FRANCAIS.modeles[l.modele]
  if (!m) throw new Error(`modele inconnu : ${l.modele}`)
  const langueDuTexte = libre ? source : (fabrique !== undefined ? langue : 'fr')
  const c = m(d)
  const jeton = typeof d.jeton_desinscription === 'string' ? d.jeton_desinscription : null
  // Les chrome (raison, desinscription) suivent la langue du texte rendu.
  const chrome = libre ? (LANGUES[source] ?? FRANCAIS) : base
  const contenu: Contenu = {
    ...c,
    raison: chrome.raisons[l.categorie] ?? chrome.raisons.direction ?? RAISON.direction,
    libelleDesinscription: chrome.desinscription,
    langue: langueDuTexte,
    droiteAGauche: (LANGUES[langueDuTexte]?.droiteAGauche) ?? false,
    desinscription: !l.essentielle && jeton
      ? `${SITE}/fr/courriels/desinscription?jeton=${encodeURIComponent(jeton)}`
      : undefined,
  }
  return langueDuTexte === langue ? { contenu } : { contenu, traduireDepuis: langueDuTexte }
}

export const modelesConnus = Object.keys(MODELES)
