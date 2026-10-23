// Le gabarit unique des e-mails Rewayah Academy (COURRIELS-1).
//
// Leger par construction : une table, des styles en ligne, aucune police web,
// deux images (logo en tete, ornement au pied, PNG de quelques Ko), aucun
// script. Gmail coupe un message au-dela de 102 Ko ; un message de ce gabarit
// en fait moins de 10. Les couleurs sont celles de `lib/core/theme/app_palette.dart`
// (fond neutre, carte blanche, encre, violet de marque) ; jamais de creme
// (identite perimee, competence `marque-rewayah`).
//
// Regle de marque (BRAND-ORN-1 §7) : l'ornement est centre au pied, en PNG
// exporte du SVG violet, jamais a cote du logo.

export const SITE = 'https://rewayahacademy.com'
export const APP = 'https://app.rewayahacademy.com'
const IMAGES = `${SITE}/fr/assets`

const C = {
  fond: '#F1EFF4',
  carte: '#FFFFFF',
  encre: '#110E20',
  attenue: '#655E70',
  filet: '#E3DEE9',
  violet: '#8652E6',
  lien: '#6538E4',
}
const POLICE = "'Plus Jakarta Sans','Segoe UI',Roboto,Helvetica,Arial,sans-serif"
const POLICE_TITRE = "'DM Sans','Segoe UI',Roboto,Helvetica,Arial,sans-serif"

export type Bloc =
  | { type: 'texte'; texte: string }
  | { type: 'bouton'; libelle: string; href: string }
  | { type: 'code'; code: string }
  | { type: 'note'; texte: string }

export interface Contenu {
  sujet: string
  /// Le texte d'apercu que la boite de reception montre sous le sujet.
  apercu: string
  titre: string
  blocs: Bloc[]
  /// Lien de desinscription (categories non essentielles seulement).
  desinscription?: string
  /// Pourquoi la personne recoit ce message (une ligne au pied).
  raison: string
}

/// Typographie francaise : espace insecable avant « : ; ? ! » et apres « ».
function insecables(html: string): string {
  return html.replace(/ ([:;?!»])/g, '&nbsp;$1').replace(/« /g, '«&nbsp;')
    .replace(/\b(e-mails?)\b/g, '<span style="white-space:nowrap">$1</span>')
}

export function echapper(v: string): string {
  return v.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;')
}

/// Un paragraphe saisi a la main (message de la direction) : lignes vides =
/// paragraphes, retours simples = <br>. Aucun HTML accepte.
export function paragraphes(texte: string): string[] {
  return texte.replace(/\r\n?/g, '\n').split(/\n{2,}/).map((p) => p.trim()).filter(Boolean)
}

function blocHtml(b: Bloc): string {
  switch (b.type) {
    case 'texte':
      return `<p style="margin:0 0 16px;font:400 15px/1.6 ${POLICE};color:${C.encre}">${
        insecables(echapper(b.texte)).replace(/\n/g, '<br>')}</p>`
    case 'note':
      return `<p style="margin:0 0 16px;font:400 13px/1.5 ${POLICE};color:${C.attenue}">${
        insecables(echapper(b.texte)).replace(/\n/g, '<br>')}</p>`
    case 'code':
      return `<p style="margin:0 0 20px;font:600 28px/1.2 ${POLICE};letter-spacing:6px;color:${C.encre}">${
        echapper(b.code)}</p>`
    case 'bouton':
      return `<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:4px 0 24px"><tr>` +
        `<td style="border-radius:12px;background:${C.violet}">` +
        `<a href="${echapper(b.href)}" style="display:inline-block;padding:13px 24px;font:600 15px/1 ${POLICE};` +
        `color:#FFFFFF;text-decoration:none;border-radius:12px">${echapper(b.libelle)}</a></td></tr></table>`
  }
}

function blocTexte(b: Bloc): string {
  switch (b.type) {
    case 'texte':
    case 'note':
      return b.texte
    case 'code':
      return b.code
    case 'bouton':
      return `${b.libelle} : ${b.href}`
  }
}

export function composer(c: Contenu): { html: string; texte: string } {
  const pied = [
    echapper(c.raison),
    c.desinscription
      ? `<a href="${echapper(c.desinscription)}" style="color:${C.attenue}">Ne plus recevoir ces e-mails</a>`
      : '',
  ].filter(Boolean).join('<br>')

  const html = `<!doctype html><html lang="fr"><head><meta charset="utf-8">` +
    `<meta name="viewport" content="width=device-width,initial-scale=1">` +
    `<meta name="color-scheme" content="light"><meta name="supported-color-schemes" content="light">` +
    `<title>${echapper(c.sujet)}</title></head>` +
    `<body style="margin:0;padding:0;background:${C.fond}">` +
    `<div style="display:none;max-height:0;overflow:hidden;opacity:0">${echapper(c.apercu)}</div>` +
    `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:${C.fond}"><tr>` +
    `<td align="center" style="padding:24px 12px">` +
    `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px">` +
    `<tr><td style="padding:0 8px 16px"><a href="${SITE}/fr/"><img src="${IMAGES}/courriel-logo-violet.png" width="150" height="43" ` +
    `alt="Rewayah Academy" style="display:block;border:0;width:150px;height:auto;font:600 18px ${POLICE_TITRE};color:${C.violet}"></a></td></tr>` +
    `<tr><td style="background:${C.carte};border:1px solid ${C.filet};border-radius:16px;padding:32px 28px">` +
    `<h1 style="margin:0 0 16px;font:600 22px/1.3 ${POLICE_TITRE};color:${C.encre}">${echapper(c.titre)}</h1>` +
    c.blocs.map(blocHtml).join('') +
    `</td></tr>` +
    `<tr><td align="center" style="padding:24px 16px 8px">` +
    `<img src="${IMAGES}/courriel-ornement-violet.png" width="24" height="40" alt="" style="display:block;border:0;width:24px;height:auto"></td></tr>` +
    `<tr><td align="center" style="padding:0 16px 8px;font:400 12px/1.6 ${POLICE};color:${C.attenue}">` +
    `Rewayah Academy · <a href="${SITE}/fr/" style="color:${C.attenue}">rewayahacademy.com</a><br>${pied}</td></tr>` +
    `</table></td></tr></table></body></html>`

  const texte = [
    c.titre,
    '',
    ...c.blocs.map(blocTexte).flatMap((t) => [t, '']),
    '--',
    'Rewayah Academy · rewayahacademy.com',
    c.raison,
    c.desinscription ? `Ne plus recevoir ces e-mails : ${c.desinscription}` : '',
  ].filter((l, i, t) => !(l === '' && t[i - 1] === '')).join('\n').trim()

  return { html, texte }
}
