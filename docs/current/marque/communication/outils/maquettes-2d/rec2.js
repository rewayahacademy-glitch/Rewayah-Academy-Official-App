const { chromium } = require('playwright'); const path=require('path'); const fs=require('fs');
const [page,dir]=process.argv.slice(2);
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1080,height:1920}});
p.on('pageerror',e=>console.log('E',e.message));
await p.goto('file://'+path.join(__dirname,page));await p.evaluate(()=>document.fonts.ready);await p.waitForTimeout(400);
const dur=await p.evaluate(()=>window.tl.duration());fs.rmSync(dir,{recursive:true,force:true});fs.mkdirSync(dir);
for(let i=0;i<Math.round(dur*30);i++){await p.evaluate(t=>{window.tl.seek(t,false)},i/30);await p.locator('#f').screenshot({path:`${dir}/${String(i).padStart(4,'0')}.png`});}
console.log('frames',Math.round(dur*30));await b.close();})();
