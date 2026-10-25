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
  /// Une phrase discrete suivie d'un lien court : le lien de secours d'un
  /// bouton, sans afficher l'adresse technique en clair.
  | { type: 'lien'; texte: string; libelle: string; href: string }

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
  /// Langue du message (code ISO) ; francais par defaut (COURRIELS-2).
  langue?: string
  /// Ecriture de droite a gauche (arabe) : tout le message se miroite.
  droiteAGauche?: boolean
  /// Libelle du lien de desinscription, dans la langue du message.
  libelleDesinscription?: string
  /// Ligne ajoutee quand le message a ete traduit a l'envoi.
  noteTraduction?: string
  /// Une lettre personnelle (pilote, 25/10/2026 : la copie de test du
  /// courriel d'attente arrivait dans « Promotions » de Gmail) : rendu sobre,
  /// comme un courriel ecrit a la main ; ni image, ni carte, ni titre, police
  /// du systeme, pied en une ligne de texte. L'envoi n'y ajoute aucun en-tete
  /// de liste (`List-Unsubscribe`) : le lien de desinscription est en corps.
  lettre?: boolean
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

function blocHtml(b: Bloc, typo: (h: string) => string, cote: string): string {
  switch (b.type) {
    case 'texte':
      return `<p style="margin:0 0 16px;font:400 15px/1.6 ${POLICE};color:${C.encre}">${
        typo(echapper(b.texte)).replace(/\n/g, '<br>')}</p>`
    case 'note':
      return `<p style="margin:0 0 16px;font:400 13px/1.5 ${POLICE};color:${C.attenue}">${
        typo(echapper(b.texte)).replace(/\n/g, '<br>')}</p>`
    case 'code':
      return `<p style="margin:0 0 20px;font:600 28px/1.2 ${POLICE};letter-spacing:6px;color:${C.encre}">${
        echapper(b.code)}</p>`
    case 'bouton':
      // Le bouton prend toute la largeur de la carte (facile a toucher sur
      // mobile, demande du directeur 23/10) ; jamais une table `align`, qui
      // flotte et faisait remonter le texte suivant a cote du bouton.
      return `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:4px 0 24px"><tr>` +
        `<td align="center" style="border-radius:12px;background:${C.violet}">` +
        `<a href="${echapper(b.href)}" style="display:block;padding:15px 24px;font:600 16px/1.2 ${POLICE};` +
        `color:#FFFFFF;text-decoration:none;text-align:center;border-radius:12px">${echapper(b.libelle)}</a></td></tr></table>`
    case 'lien':
      return `<p style="margin:0 0 16px;font:400 13px/1.5 ${POLICE};color:${C.attenue}">${typo(echapper(b.texte))} ` +
        `<a href="${echapper(b.href)}" style="color:${C.lien}">${typo(echapper(b.libelle))}</a></p>`
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
    case 'lien':
      return `${b.texte} ${b.libelle} : ${b.href}`
  }
}

/// La police du systeme de la lettre : celle d'un courriel ecrit a la main.
const POLICE_LETTRE = 'Arial,Helvetica,sans-serif'

/// La lettre personnelle ([Contenu.lettre]) : des paragraphes sur fond
/// blanc, une colonne, aucune image, aucun bouton peint ; le pied en texte.
function composerLettre(c: Contenu): { html: string; texte: string } {
  const langue = c.langue ?? 'fr'
  const rtl = c.droiteAGauche === true
  const dir = rtl ? 'rtl' : 'ltr'
  const cote = rtl ? 'right' : 'left'
  const typo = langue === 'fr' ? insecables : (h: string) => h
  const desinscrire = c.libelleDesinscription ?? 'Ne plus recevoir ces e-mails'
  const paragraphe = (t: string, style: string) =>
    `<p style="margin:0 0 14px;${style}">${typo(echapper(t)).replace(/\n/g, '<br>')}</p>`
  const corps = c.blocs.map((b) => {
    switch (b.type) {
      case 'texte':
        return paragraphe(b.texte, '')
      case 'note':
        return paragraphe(b.texte, 'color:#555555;font-size:13px')
      case 'code':
        return paragraphe(b.code, 'font-weight:bold')
      case 'bouton':
        return `<p style="margin:0 0 14px"><a href="${echapper(b.href)}">${echapper(b.libelle)}</a></p>`
      case 'lien':
        return `<p style="margin:0 0 14px">${typo(echapper(b.texte))} <a href="${echapper(b.href)}">${typo(echapper(b.libelle))}</a></p>`
    }
  }).join('')
  const pied = [
    'Rewayah Academy · rewayahacademy.com',
    c.noteTraduction ? echapper(c.noteTraduction) : '',
    echapper(c.raison),
    c.desinscription ? `<a href="${echapper(c.desinscription)}">${echapper(desinscrire)}</a>` : '',
  ].filter(Boolean).join('<br>')
  const html = `<!doctype html><html lang="${echapper(langue)}" dir="${dir}"><head><meta charset="utf-8">` +
    `<meta name="viewport" content="width=device-width,initial-scale=1">` +
    `<title>${echapper(c.sujet)}</title></head>` +
    `<body style="margin:0;padding:16px;background:#FFFFFF">` +
    `<div dir="${dir}" style="max-width:600px;text-align:${cote};font:14px/1.6 ${POLICE_LETTRE};color:#222222">` +
    corps +
    `<p style="margin:24px 0 0;font-size:12px;color:#777777">${pied}</p>` +
    `</div></body></html>`
  const texte = [
    ...c.blocs.map(blocTexte).flatMap((t) => [t, '']),
    '--',
    'Rewayah Academy · rewayahacademy.com',
    c.noteTraduction ?? '',
    c.raison,
    c.desinscription ? `${desinscrire} : ${c.desinscription}` : '',
  ].filter((l, i, t) => !(l === '' && t[i - 1] === '')).join('\n').trim()
  return { html, texte }
}

export function composer(c: Contenu): { html: string; texte: string } {
  if (c.lettre === true) return composerLettre(c)
  const langue = c.langue ?? 'fr'
  const rtl = c.droiteAGauche === true
  const dir = rtl ? 'rtl' : 'ltr'
  const cote = rtl ? 'right' : 'left'
  const typo = langue === 'fr' ? insecables : (h: string) => h
  const desinscrire = c.libelleDesinscription ?? 'Ne plus recevoir ces e-mails'
  const pied = [
    c.noteTraduction ? echapper(c.noteTraduction) : '',
    echapper(c.raison),
    c.desinscription
      ? `<a href="${echapper(c.desinscription)}" style="color:${C.attenue}">${echapper(desinscrire)}</a>`
      : '',
  ].filter(Boolean).join('<br>')

  const html = `<!doctype html><html lang="${echapper(langue)}" dir="${dir}"><head><meta charset="utf-8">` +
    `<meta name="viewport" content="width=device-width,initial-scale=1">` +
    `<meta name="color-scheme" content="light"><meta name="supported-color-schemes" content="light">` +
    `<title>${echapper(c.sujet)}</title></head>` +
    `<body style="margin:0;padding:0;background:${C.fond}">` +
    `<div style="display:none;max-height:0;overflow:hidden;opacity:0">${echapper(c.apercu)}</div>` +
    `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:${C.fond}"><tr>` +
    `<td align="center" style="padding:24px 12px">` +
    `<table role="presentation" dir="${dir}" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px">` +
    `<tr><td align="${cote}" style="padding:0 8px 16px"><a href="${SITE}/fr/"><img src="${IMAGES}/courriel-logo-violet.png" width="150" height="43" ` +
    `alt="Rewayah Academy" style="display:block;border:0;width:150px;height:auto;font:600 18px ${POLICE_TITRE};color:${C.violet}"></a></td></tr>` +
    `<tr><td dir="${dir}" align="${cote}" style="background:${C.carte};border:1px solid ${C.filet};border-radius:16px;padding:32px 28px;text-align:${cote}">` +
    `<h1 style="margin:0 0 16px;font:600 22px/1.3 ${POLICE_TITRE};color:${C.encre}">${echapper(c.titre)}</h1>` +
    c.blocs.map((b) => blocHtml(b, typo, cote)).join('') +
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
    c.noteTraduction ?? '',
    c.raison,
    c.desinscription ? `${desinscrire} : ${c.desinscription}` : '',
  ].filter((l, i, t) => !(l === '' && t[i - 1] === '')).join('\n').trim()

  return { html, texte }
}
