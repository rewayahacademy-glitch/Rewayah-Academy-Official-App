// PROSPECTION-IMAGE (27/11/2026) : les images des lettres aux organisations (couleurs de app_palette.dart, logo officiel).
const { chromium } = require('playwright');
const fs = require('fs');
// Lancer depuis la racine du depot : node tool/prospection/images_courriel.js (Playwright installe).
// Sortie : site-public/assets/courriel-prospection-{fr,en,ar}.png, 1200x630.
const R = process.cwd();
const logo = fs.readFileSync(R + '/assets/brand/logo/violet/logo-horizontal.svg', 'utf8')
  .replace(/<svg /, '<svg class="logo" ');
const f = (n) => fs.readFileSync(`${R}/assets/fonts/${n}-Variable.ttf`).toString('base64');
const T = {
  fr: { l1: 'Apprendre', l2: 'en attendant.', s: 'Pour les enfants de votre liste d’attente.', dir: 'ltr' },
  en: { l1: 'Learning', l2: 'while they wait.', s: 'For the children on your waiting list.', dir: 'ltr' },
  ar: { l1: 'يتعلّمون', l2: 'وهم ينتظرون.', s: 'لأطفال قائمة الانتظار عندكم.', dir: 'rtl' },
};
// La liste : 6 lignes grises ; un point quitte la liste et entre sous l'arche violette.
function visuel(rtl) {
  let s = '';
  for (let i = 0; i < 6; i++) {
    const y = 120 + i * 62;
    const actif = i === 2;
    s += `<rect x="0" y="${y}" width="250" height="38" rx="19" fill="${actif ? '#DCCAFD' : '#E3DEE9'}"/>`;
    s += `<circle cx="19" cy="${y + 19}" r="11" fill="${actif ? 'none' : '#84798F'}" stroke="${actif ? '#8652E6' : 'none'}" stroke-width="3" stroke-dasharray="${actif ? '3 4' : ''}" opacity="${actif ? 1 : .55}"/>`;
  }
  // trajet en pointillés de la ligne active vers l'arche
  s += `<path d="M262 263 C 320 263, 330 263, 352 263" stroke="#8652E6" stroke-width="4" stroke-dasharray="2 12" stroke-linecap="round" fill="none"/>`;
  // l'arche (une porte ouverte)
  s += `<path d="M370 470 V 230 A 80 80 0 0 1 530 230 V 470 Z" fill="#8652E6"/>`;
  s += `<circle cx="450" cy="300" r="26" fill="#FFFFFF"/>`;
  s += `<rect x="408" y="345" width="84" height="125" rx="42" fill="#FFFFFF" opacity=".9"/>`;
  const g = `<g transform="translate(${rtl ? 560 : 0},0) scale(${rtl ? -1 : 1},1)">${s}</g>`;
  return `<svg class="vis" width="560" height="630" viewBox="0 0 560 630">${g}</svg>`;
}
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 });
  for (const [k, t] of Object.entries(T)) {
    const rtl = t.dir === 'rtl';
    const html = `<!doctype html><html dir="${t.dir}"><head><meta charset="utf-8"><style>
@font-face{font-family:DM;src:url(data:font/ttf;base64,${f('DMSans')})}
@font-face{font-family:PJ;src:url(data:font/ttf;base64,${f('PlusJakartaSans')})}
@font-face{font-family:NA;src:url(data:font/ttf;base64,${f('NotoSansArabic')})}
html,body{margin:0;width:1200px;height:630px;background:#F1EFF4;overflow:hidden}
.t{position:absolute;top:150px;${rtl ? 'right' : 'left'}:84px;width:500px;color:#110E20}
h1{margin:0;font:700 ${rtl ? 84 : 70}px/1.08 ${rtl ? 'NA' : 'DM'};letter-spacing:${rtl ? 0 : -2}px}
h1 span{color:#8652E6}
p{margin:28px 0 0;font:500 ${rtl ? 30 : 28}px/1.4 ${rtl ? 'NA' : 'PJ'};color:#655E70}
.logo{position:absolute;bottom:56px;${rtl ? 'right' : 'left'}:84px;height:40px;width:auto}
.vis{position:absolute;top:0;${rtl ? 'left' : 'right'}:40px}
</style></head><body><div class="t"><h1>${t.l1}<br><span>${t.l2}</span></h1><p>${t.s}</p></div>${logo}${visuel(rtl)}</body></html>`;
    await p.setContent(html, { waitUntil: 'load' });
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: `${R}/site-public/assets/courriel-prospection-${k}.png` });
  }
  await b.close();
})();
