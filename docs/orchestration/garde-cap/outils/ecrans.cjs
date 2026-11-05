const { chromium } = require('playwright');
(async () => {
const b = await chromium.launch();
for (const [w,h] of [[1280,800],[390,844]]) {
  const ctx = await b.newContext({ viewport: { width: w, height: h } });
  const p = await ctx.newPage();
  for (const [nom, chemin] of [['creer','/#/connexion?mode=creer'],['commencer','/#/commencer'],['acces','/#/commencer?etape=acces']]) {
    await p.goto('https://app.rewayahacademy.com' + chemin);
    await p.waitForFunction(() => !document.getElementById('ouverture') || getComputedStyle(document.getElementById('ouverture')).display === 'none', null, { timeout: 60000 }).catch(()=>{});
    await p.waitForTimeout(3500);
    await p.screenshot({ path: `../prod567/${nom}_${w}.png` });
  }
  await ctx.close();
}
await b.close();
})();
