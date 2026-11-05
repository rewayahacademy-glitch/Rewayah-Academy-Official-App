const { chromium } = require('playwright');
(async () => {
const b = await chromium.launch();
for (const [nom, ancien] of [['lent_premiere', null], ['lent_nouvelle', '"ancienne"']]) {
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
  const p = await ctx.newPage();
  const cdp = await ctx.newCDPSession(p);
  await cdp.send('Network.enable');
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 150, downloadThroughput: 4e6/8, uploadThroughput: 1e6/8 });
  if (ancien) await p.addInitScript((v) => { try { localStorage.setItem('rewayah.ouverture.version', v); } catch(e){} }, ancien);
  const t0 = Date.now(); const vus = [];
  p.goto('https://app.rewayahacademy.com/').catch(()=>{});
  while (Date.now() - t0 < 90000) {
    await p.waitForTimeout(400);
    const r = await p.evaluate(() => { const o = document.getElementById('ouverture'); const ph = document.getElementById('ouverture-phrase'); const bar = document.querySelector('.ouverture-barre span'); return { la: !!o && o.isConnected && getComputedStyle(o).display !== 'none', t: ph && ph.textContent, w: bar && bar.style.width }; }).catch(() => null);
    if (!r) continue;
    const s = ((Date.now()-t0)/1000).toFixed(1);
    if (!r.la) { vus.push(`${s}s FIN`); break; }
    if (!vus.length || !vus[vus.length-1].includes(r.t)) vus.push(`${s}s ${r.t} [${r.w}]`);
    if (Math.abs((Date.now()-t0) % 10000) < 400) await p.screenshot({ path: `../prod567/${nom}_${s}.png` });
  }
  console.log(nom, JSON.stringify(vus));
  await ctx.close();
}
await b.close();
})();
