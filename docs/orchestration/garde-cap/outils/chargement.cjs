const { chromium } = require('playwright');
(async () => {
const URL = 'https://app.rewayahacademy.com/';
const out = process.argv[2];
const b = await chromium.launch();
async function suivre(ctx, nom, avant) {
  const p = await ctx.newPage();
  if (avant) await p.addInitScript(avant);
  const t0 = Date.now(); const vus = [];
  p.goto(URL).catch(()=>{});
  let fin = false;
  while (Date.now() - t0 < 40000) {
    await p.waitForTimeout(400);
    const r = await p.evaluate(() => {
      const o = document.getElementById('ouverture');
      const ph = document.getElementById('ouverture-phrase');
      return { la: !!o && o.isConnected && getComputedStyle(o).display !== 'none' && getComputedStyle(o).opacity !== '0', t: ph ? ph.textContent : null };
    }).catch(() => null);
    if (!r) continue;
    const s = ((Date.now()-t0)/1000).toFixed(1);
    if (!r.la) { vus.push(`${s}s FIN`); fin = true; break; }
    if (!vus.length || !vus[vus.length-1].endsWith(r.t)) vus.push(`${s}s ${r.t}`);
  }
  await p.screenshot({ path: `${out}/${nom}_apres.png` });
  console.log(nom, JSON.stringify(vus));
  await p.close();
}
const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
await suivre(ctx, '1_premiere');
await suivre(ctx, '2_meme');
await suivre(ctx, '3_nouvelle', () => { try { localStorage.setItem('rewayah.ouverture.version', '"ancienne"'); } catch(e){} });
const ctxAr = await b.newContext({ viewport: { width: 390, height: 844 }, locale: 'ar' });
await suivre(ctxAr, '4_ar_premiere');
await b.close();
})();
