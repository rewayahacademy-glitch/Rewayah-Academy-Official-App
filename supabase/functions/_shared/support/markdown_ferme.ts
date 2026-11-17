// PX-BD-SUPPORT : le Markdown FERME des supports que Praxis redige. Une grammaire courte, ecrite une fois (docs/current/BUREAU-EQUIPE/PRAXIS/
// MARKDOWN-FERME.md), analysee ici cote serveur (refus clair de tout ce qui sort de la liste) et, a l'identique, par le lecteur de
// l'application (lib/core/tc_bibliotheque/markdown_ferme.dart). Les DEUX analyseurs passent les memes vecteurs (vecteurs.json) : un cas qui
// donne un resultat different d'un cote ou de l'autre est rouge.
//
// Ce qui est admis : titres #, ##, ###, paragraphes, listes a puces et numerotees (un seul niveau), gras (**x**), italique (*x*), citation (> ),
// separateur (---). Ce qui est REFUSE, avec son code : toute balise HTML, tout lien, toute image, tout tableau, tout code, le barre, une marque
// non fermee ou imbriquee, une liste a deux niveaux, un caractere de commande ou de surcharge du sens de lecture. Aucune « reparation ».

export type Inline =
  | { t: 'texte'; v: string }
  | { t: 'gras'; v: string }
  | { t: 'italique'; v: string }

export type Bloc =
  | { type: 'titre'; niveau: 1 | 2 | 3; inlines: Inline[] }
  | { type: 'paragraphe'; inlines: Inline[] }
  | { type: 'puces'; items: Inline[][] }
  | { type: 'numerotee'; debut: number; items: Inline[][] }
  | { type: 'citation'; inlines: Inline[] }
  | { type: 'separateur' }

export type CodeRefus =
  | 'vide' | 'trop_long' | 'ligne_trop_longue' | 'trop_de_blocs' | 'caractere_interdit' | 'html' | 'lien' | 'image' | 'tableau'
  | 'code' | 'barre' | 'marque_non_fermee' | 'imbrication' | 'liste_imbriquee' | 'titre_trop_profond'

export type Resultat = { ok: true; blocs: Bloc[] } | { ok: false; code: CodeRefus; ligne: number }

export const OCTETS_MAX = 100_000
export const LIGNE_MAX = 5000
export const BLOCS_MAX = 2000

const RE_TITRE = /^(#{1,3}) (.+)$/
const RE_PUCE = /^[-*] (.+)$/
const RE_NUM = /^(\d{1,3})\. (.+)$/
const RE_IMBRIQUEE = /^ +(?:[-*]|\d{1,3}\.) /
const RE_HTML = /<[A-Za-z/!?]/
const RE_LIEN = /\[[^\]\n]*\]\([^)\n]*\)/

function interdit(c: number): boolean {
  if (c === 0x0a || c === 0x09) return false
  if (c < 0x20 || c === 0x7f) return true
  // Surcharge du sens de lecture : embeddings, overrides et isolats. Les marques LRM, RLM et ALM restent admises (arabe).
  if (c >= 0x202a && c <= 0x202e) return true
  if (c >= 0x2066 && c <= 0x2069) return true
  return false
}

/// Les marques en ligne d'un texte deja joint. Rend les segments, ou le code du refus.
function inlines(texte: string): Inline[] | CodeRefus {
  const sortie: Inline[] = []
  let tampon = ''
  const vider = () => {
    if (tampon !== '') {
      const dernier = sortie[sortie.length - 1]
      if (dernier && dernier.t === 'texte') dernier.v += tampon
      else sortie.push({ t: 'texte', v: tampon })
      tampon = ''
    }
  }
  let i = 0
  while (i < texte.length) {
    const c = texte[i]
    if (c === '\\') {
      const s = texte[i + 1]
      if (s === '*' || s === '\\') {
        tampon += s
        i += 2
      } else {
        tampon += c
        i += 1
      }
      continue
    }
    if (c === '*') {
      const gras = texte[i + 1] === '*'
      const ouvre = gras ? 2 : 1
      let j = i + ouvre
      let contenu = ''
      let ferme = false
      while (j < texte.length) {
        const d = texte[j]
        if (d === '\\' && (texte[j + 1] === '*' || texte[j + 1] === '\\')) {
          contenu += texte[j + 1]
          j += 2
          continue
        }
        if (d === '*') {
          if (gras) {
            if (texte[j + 1] === '*') {
              ferme = true
              j += 2
              break
            }
            return 'imbrication'
          }
          if (texte[j + 1] === '*') return 'imbrication'
          ferme = true
          j += 1
          break
        }
        contenu += d
        j += 1
      }
      if (!ferme || contenu === '') return 'marque_non_fermee'
      vider()
      sortie.push({ t: gras ? 'gras' : 'italique', v: contenu })
      i = j
      continue
    }
    tampon += c
    i += 1
  }
  vider()
  return sortie
}

function motifsInterdits(ligne: string): CodeRefus | null {
  if (ligne.includes('![')) return 'image'
  if (RE_LIEN.test(ligne)) return 'lien'
  if (RE_HTML.test(ligne)) return 'html'
  if (ligne.includes('`')) return 'code'
  if (ligne.includes('~~')) return 'barre'
  return null
}

export function analyser(source: string): Resultat {
  if (new TextEncoder().encode(source).length > OCTETS_MAX) return { ok: false, code: 'trop_long', ligne: 0 }
  // Les fins de ligne Windows et anciennes se ramenent a \n AVANT le controle des caracteres : un retour chariot isole n'est pas refuse.
  const normalise = source.replace(/\r\n?/g, '\n')
  for (let k = 0; k < normalise.length; k++) {
    if (interdit(normalise.charCodeAt(k))) return { ok: false, code: 'caractere_interdit', ligne: 0 }
  }
  const lignes = normalise.replace(/\t/g, ' ').split('\n')
  if (lignes.every((l) => l.trim() === '')) return { ok: false, code: 'vide', ligne: 0 }
  const blocs: Bloc[] = []
  let para: string[] = []
  let citation: string[] = []
  let puces: string[] | null = null
  let nums: { debut: number; items: string[] } | null = null
  let ligneCourante = 0
  const echec = (code: CodeRefus): Resultat => ({ ok: false, code, ligne: ligneCourante })

  const fermer = (): CodeRefus | null => {
    const pousser = (b: (ins: Inline[]) => Bloc, texte: string): CodeRefus | null => {
      const r = inlines(texte)
      if (typeof r === 'string') return r
      blocs.push(b(r))
      return null
    }
    if (para.length > 0) {
      const e = pousser((ins) => ({ type: 'paragraphe', inlines: ins }), para.join(' '))
      para = []
      if (e) return e
    }
    if (citation.length > 0) {
      const e = pousser((ins) => ({ type: 'citation', inlines: ins }), citation.join(' '))
      citation = []
      if (e) return e
    }
    if (puces) {
      const items: Inline[][] = []
      for (const t of puces) {
        const r = inlines(t)
        if (typeof r === 'string') return r
        items.push(r)
      }
      puces = null
      blocs.push({ type: 'puces', items })
    }
    if (nums) {
      const items: Inline[][] = []
      for (const t of nums.items) {
        const r = inlines(t)
        if (typeof r === 'string') return r
        items.push(r)
      }
      blocs.push({ type: 'numerotee', debut: nums.debut, items })
      nums = null
    }
    return null
  }

  for (let n = 0; n < lignes.length; n++) {
    ligneCourante = n + 1
    const brute = lignes[n]
    if (brute.length > LIGNE_MAX) return echec('ligne_trop_longue')
    const l = brute.trimEnd()
    if (l.trim() === '') {
      const e = fermer()
      if (e) return echec(e)
      continue
    }
    if (l.startsWith('|')) return echec('tableau')
    if (l.trim().startsWith('```') || l.trim().startsWith('~~~')) return echec('code')
    const m = motifsInterdits(l)
    if (m) return echec(m)
    if (RE_IMBRIQUEE.test(l)) return echec('liste_imbriquee')
    if (/^#{4,}( |$)/.test(l)) return echec('titre_trop_profond')
    const t = RE_TITRE.exec(l)
    if (t) {
      const e = fermer()
      if (e) return echec(e)
      const r = inlines(t[2].trim())
      if (typeof r === 'string') return echec(r)
      blocs.push({ type: 'titre', niveau: t[1].length as 1 | 2 | 3, inlines: r })
      continue
    }
    if (l.trim() === '---') {
      const e = fermer()
      if (e) return echec(e)
      blocs.push({ type: 'separateur' })
      continue
    }
    if (l.startsWith('>')) {
      if (para.length > 0 || puces || nums) {
        const e = fermer()
        if (e) return echec(e)
      }
      citation.push(l.replace(/^> ?/, '').trim())
      continue
    }
    const p = RE_PUCE.exec(l)
    if (p) {
      if (para.length > 0 || citation.length > 0 || nums) {
        const e = fermer()
        if (e) return echec(e)
      }
      if (!puces) puces = []
      puces.push(p[1].trim())
      continue
    }
    const q = RE_NUM.exec(l)
    if (q) {
      if (para.length > 0 || citation.length > 0 || puces) {
        const e = fermer()
        if (e) return echec(e)
      }
      if (!nums) nums = { debut: Number(q[1]), items: [] }
      nums.items.push(q[2].trim())
      continue
    }
    if (citation.length > 0 || puces || nums) {
      const e = fermer()
      if (e) return echec(e)
    }
    para.push(l.trim())
  }
  ligneCourante = lignes.length
  const e = fermer()
  if (e) return echec(e)
  if (blocs.length > BLOCS_MAX) return { ok: false, code: 'trop_de_blocs', ligne: 0 }
  return { ok: true, blocs }
}
