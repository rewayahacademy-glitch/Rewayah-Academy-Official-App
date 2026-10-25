// Traduction a l'envoi (COURRIELS-2, directeur 23/10/2026 : Google Traduction).
//
// Un seul appel par e-mail : tous les textes visibles partent ensemble a
// l'API Cloud Translation v2 (`GOOGLE_TRADUCTION_CLE`). Les passages en
// ecriture arabe d'un texte qui n'est pas traduit vers l'arabe (versets,
// invocations, noms) sont proteges : jamais traduits automatiquement
// (competence mots-rewayah, §6). Le nom de la marque (« Rewayah Academy »,
// « Rewayah ») est protege de meme, vers toutes les langues : il reste en
// latin et s'ecrit pareil partout (pilote, 25/10/2026, apres une copie de test
// en arabe qui le rendait de trois facons).

import type { Bloc, Contenu } from './gabarit.ts'

const API = 'https://translation.googleapis.com/language/translate/v2'
const ARABE = /[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿][؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿\sً-ٰٟ]*/g

const MARQUE = /Rewayah(?: Academy)?/g
const proteger = (m: string) => `<span translate="no" class="notranslate">${m}</span>`

export function versHtml(t: string, protegerArabe: boolean): string {
  const e = t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g, '<br>')
  const marque = e.replace(MARQUE, proteger)
  return protegerArabe ? marque.replace(ARABE, proteger) : marque
}

export function depuisHtml(h: string): string {
  return h.replace(/<span translate="no" class="notranslate">(.*?)<\/span>/gs, '$1')
    .replace(/<br\s*\/?>/gi, '\n').replace(/&#39;/g, "'").replace(/&quot;/g, '"')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&')
}

export type Traducteur = (textes: string[], source: string, cible: string) => Promise<string[]>

/// Le traducteur Google. Une erreur remonte : l'envoi est rejoue plus tard
/// (5 essais), jamais parti dans une autre langue que celle du destinataire.
export const traducteurGoogle: Traducteur = async (textes, source, cible) => {
  const cle = Deno.env.get('GOOGLE_TRADUCTION_CLE')
  if (!cle) throw new Error('configuration absente : GOOGLE_TRADUCTION_CLE')
  const r = await fetch(`${API}?key=${encodeURIComponent(cle)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ q: textes.map((t) => versHtml(t, cible !== 'ar')), source, target: cible, format: 'html' }),
  })
  if (!r.ok) throw new Error(`traduction ${r.status}`)
  const corps = await r.json()
  const sortie = (corps?.data?.translations ?? []).map((x: { translatedText: string }) => depuisHtml(x.translatedText))
  if (sortie.length !== textes.length) throw new Error('traduction incomplete')
  return sortie
}

/// Traduit tous les textes visibles d'un contenu ; les liens et les codes ne
/// bougent pas.
export async function traduireContenu(
  c: Contenu, source: string, cible: string, traduire: Traducteur = traducteurGoogle,
): Promise<Contenu> {
  const textes: string[] = [c.sujet, c.apercu, c.titre, c.raison, c.libelleDesinscription ?? 'Ne plus recevoir ces e-mails',
    'Ce message a été traduit automatiquement.']
  const places: number[] = []
  c.blocs.forEach((b, i) => {
    if (b.type === 'texte' || b.type === 'note' || b.type === 'bouton') {
      places.push(i)
      textes.push(b.type === 'bouton' ? b.libelle : b.texte)
    }
  })
  const t = await traduire(textes, source, cible)
  const blocs: Bloc[] = c.blocs.map((b) => ({ ...b }))
  places.forEach((i, k) => {
    const b = blocs[i]
    const v = t[6 + k]
    if (b.type === 'bouton') b.libelle = v
    else if (b.type === 'texte' || b.type === 'note') b.texte = v
  })
  return { ...c, sujet: t[0], apercu: t[1], titre: t[2], raison: t[3], libelleDesinscription: t[4], noteTraduction: t[5], blocs, langue: cible }
}
