// Images des lettres aux organisations, style Silhouette (figurines du design system, pied de page officiel).
const { chromium } = require('playwright');
const fs = require('fs');
const R = process.cwd(); // lancer depuis la racine du depot
const A = R + '/tool/prospection/silhouette/'; // figurines copiees du design system (bibliotheque Silhouette)
const inner = (f) => fs.readFileSync(A + f, 'utf8').replace(/^<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
const f64 = (n) => fs.readFileSync(`${R}/assets/fonts/${n}-Variable.ttf`).toString('base64');
const logo = 'data:image/svg+xml;base64,' + fs.readFileSync(`${R}/assets/brand/logo/blanc/logo-horizontal.svg`).toString('base64');
const ic = (n) => fs.readFileSync(`${R}/tool/prospection/silhouette/${n}.svg`, 'utf8').replace('<svg ', '<svg class="ic" ');
const TAHA = fs.readFileSync(`${R}/assets/fonts/UthmanTahaNaskh-Regular.otf`).toString('base64');
const HADITH = 'الدَّالُّ عَلَى الخَيْرِ كَفَاعِلِهِ';
const T = {
  fr: { a: 'Pour vos élèves qui ne peuvent pas venir', tr: '« Celui qui indique le bien est comme celui qui le fait. »', ref: 'Hadith rapporté par at-Tirmidhî, n° 2670', dir: 'ltr' },
  en: { a: 'For the students who cannot come', tr: '“The one who guides to good is like the one who does it.”', ref: 'Hadith narrated by at-Tirmidhi, no. 2670', dir: 'ltr' },
  ar: { a: 'لطلابكم الذين لا يستطيعون الحضور', tr: '', ref: 'رواه الترمذي (2670)', dir: 'rtl' },
};
// Scene 1200 x 630, sol a y = 520, echelle 0.62 ; en arabe, la scene passe a gauche, en miroir.
function scene(rtl) {
  const s = 0.58, y = 520 - 540 * s;
  const piece = (f, x) => `<svg x="${x}" y="${y}" width="${600 * s}" height="${600 * s}" viewBox="0 0 600 600">${inner(f)}</svg>`;
  const g = piece('mere-enfant-chemin.svg', 590 - 110 * s) + piece('bab-montre.svg', 840 - 180 * s) + piece('place-libre.svg', 1040 - 200 * s);
  return `<svg class="scene" width="1200" height="630" viewBox="0 0 1200 630"><g transform="${rtl ? 'translate(1200,0) scale(-1,1)' : ''}">${g}</g></svg>`;
}
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 });
  for (const [k, t] of Object.entries(T)) {
    const rtl = t.dir === 'rtl', cote = rtl ? 'right' : 'left';
    const html = `<!doctype html><html dir="${t.dir}"><head><meta charset="utf-8"><style>
@font-face{font-family:DM;src:url(data:font/ttf;base64,${f64('DMSans')})}
@font-face{font-family:PJ;src:url(data:font/ttf;base64,${f64('PlusJakartaSans')})}
@font-face{font-family:TN;src:url(data:font/otf;base64,${TAHA})}
@font-face{font-family:NA;src:url(data:font/ttf;base64,${f64('NotoSansArabic')})}
html,body{margin:0;width:1200px;height:630px;overflow:hidden}
.c{position:relative;width:1200px;height:630px;background:#8652E6;overflow:hidden}
.scene{position:absolute;inset:0}
.t{position:absolute;top:74px;${cote}:64px;width:500px}
.a{font:600 ${rtl ? 28 : 22}px/1.3 ${rtl ? 'NA' : 'PJ'};color:#FFFFFF;margin:0 0 6px}
.h{font:400 76px/1.5 TN;color:#FFFFFF;margin:0;direction:rtl;text-align:${cote}}
.tr{font:700 ${rtl ? 26 : 27}px/1.3 DM;color:#110E20;margin:6px 0 0;text-wrap:balance}
.ref{font:500 ${rtl ? 20 : 15}px/1.3 ${rtl ? 'NA' : 'PJ'};color:#FFFFFF;opacity:.8;margin:14px 0 0}
footer{position:absolute;left:40px;right:40px;bottom:22px;color:#FFFFFF}
footer .l{display:flex;align-items:center;gap:22px;direction:ltr}
footer img{height:34px;display:block}
footer .sep{flex:1;height:2px;background:rgba(255,255,255,.3)}
footer .e{font:600 13px/1 PJ;display:flex;align-items:center;gap:6px;white-space:nowrap}
.ic{width:16px;height:16px;position:relative;top:1px;fill:currentColor}
</style></head><body><div class="c">${scene(rtl)}
<div class="t"><p class="a">${t.a}</p><p class="h">«${HADITH}»</p>${t.tr ? `<p class="tr">${t.tr}</p>` : ''}<p class="ref">${t.ref}</p></div>
<footer><div class="l"><img src="${logo}" alt=""><span class="sep"></span>
<span class="e">${ic('globe-simple')}rewayahacademy.com</span><span class="e">${ic('envelope-simple')}contact@rewayahacademy.com</span>
<span class="e">${ic('facebook-logo')}${ic('instagram-logo')}@rewayahacademy</span><span class="e">${ic('x-logo')}@rewayahA48452</span><span class="e">${ic('tiktok-logo')}@rewayah.academy</span></div></footer>
</div></body></html>`;
    await p.setContent(html, { waitUntil: 'load' });
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: `${R}/site-public/assets/courriel-prospection-${k}.png` });
  }
  await b.close();
})();
