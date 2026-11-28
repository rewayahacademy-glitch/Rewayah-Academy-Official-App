import { createRequire } from 'module'; import fs from 'fs'; import path from 'path'; import { spawn } from 'child_process'; import { fileURLToPath } from 'url';
const require = createRequire('/opt/node-tools/node_modules/'); const { chromium } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url)); const out = path.resolve(here,'..');
const args = Object.fromEntries(process.argv.slice(2).map(a=>{const [k,v]=a.replace(/^--/,'').split('=');return [k,v??'1'];}));
const svg = fs.readFileSync(args.svg || '/home/user/Rewayah-Academy-Official-App/assets/brand/logo/blanc/ornement-plein.svg','utf8');
const params = JSON.parse(args.params||'{}');
const browser = await chromium.launch(); const page = await browser.newPage({ viewport:{width:params.w||1080,height:params.h||1920} });
page.on('console', m=>{ if(m.type()==='error'||m.type()==='warning') console.log('[page]',m.text().slice(0,400)); }); page.on('pageerror', e=>console.log('[pageerror]',String(e).slice(0,600)));
await page.addInitScript(([s,p])=>{ window.__SVG=s; window.__PARAMS=p; }, [svg, params]);
const tl = Date.now(); await page.goto('file://'+path.join(here,'index.html')); await page.waitForFunction('window.__READY===true'); console.log('chargement scène ms', Date.now()-tl);
const fps = 30, dur = 3;
if (args.stills){ for (const s of args.stills.split(',')){ const t=parseFloat(s); const ms = await page.evaluate(([t,d])=>window.renderFrame(t,d),[t,dur]); const ms2 = await page.evaluate(([t,d])=>window.renderFrame(t,d),[t,dur]);
    const b64 = await page.evaluate(()=>window.grab('image/png')); const f = path.join(out,'frames',`${args.name||'frame'}_t${s}.png`); fs.writeFileSync(f, Buffer.from(b64,'base64')); console.log(f,'rendu ms (1er / 2e):',ms.toFixed(0),ms2.toFixed(0)); } }
if (args.compare){ console.log('fidélité de face', JSON.stringify(await page.evaluate(()=>window.compareSvg()))); }
if (args.video){ const N = fps*dur; const f = path.join(out, args.video);
  const ff = spawn('ffmpeg',['-y','-loglevel','error','-f','image2pipe','-framerate',String(fps),'-c:v','mjpeg','-i','-','-c:v','libx264','-preset','medium','-crf','17','-pix_fmt','yuv420p','-movflags','+faststart',f],{stdio:['pipe','inherit','inherit']});
  let tr=0,tg=0; const T0=Date.now(); const rs=[];
  for(let i=0;i<N;i++){ const ms = await page.evaluate(([t,d])=>window.renderFrame(t,d),[i/fps,dur]); tr+=ms; rs.push(ms); const g0=Date.now(); const b64 = await page.evaluate(()=>window.grab('image/jpeg',0.95)); const buf=Buffer.from(b64,'base64'); tg+=Date.now()-g0; if(!ff.stdin.write(buf)) await new Promise(r=>ff.stdin.once('drain',r)); }
  ff.stdin.end(); await new Promise(r=>ff.on('close',r)); rs.sort((a,b)=>a-b);
  console.log(JSON.stringify({video:f,frames:N,rendu_ms_moy:+(tr/N).toFixed(1),rendu_ms_median:+rs[N>>1].toFixed(1),rendu_ms_max:+rs[N-1].toFixed(1),capture_jpeg_ms_moy:+(tg/N).toFixed(1),total_s:+((Date.now()-T0)/1000).toFixed(1)})); }
await browser.close();
