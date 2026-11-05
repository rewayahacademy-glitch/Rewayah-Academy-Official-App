const { chromium } = require('playwright');
// usage: node parcours.cjs prefix "click:x,y;type:texte;key:Enter;wait:ms;shot"
(async () => {
const [pref, actions] = process.argv.slice(2);
const b = await chromium.launch();
const ctx = await b.newContext({ viewport: { width: 390, height: 844 } });
const p = await ctx.newPage();
await p.goto('https://app.rewayahacademy.com/#/commencer');
await p.waitForTimeout(9000);
let n = 0;
for (const a of actions.split(';')) {
  const [k, v] = [a.split(':')[0], a.slice(a.indexOf(':')+1)];
  if (k === 'click') { const [x,y] = v.split(',').map(Number); await p.mouse.click(x,y); await p.waitForTimeout(1200); }
  else if (k === 'type') { await p.keyboard.type(v, { delay: 40 }); await p.waitForTimeout(600); }
  else if (k === 'key') { await p.keyboard.press(v); await p.waitForTimeout(1200); }
  else if (k === 'wheel') { await p.mouse.move(195,400); await p.mouse.wheel(0, Number(v)); await p.waitForTimeout(900); }
  else if (k === 'wait') await p.waitForTimeout(Number(v));
  else if (k === 'shot') { n++; await p.screenshot({ path: `../prod567/${pref}_${String(n).padStart(2,'0')}.png` }); }
}
await b.close();
})();
