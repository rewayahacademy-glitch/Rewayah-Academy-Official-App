import {writeFile, mkdir} from 'node:fs/promises';
const [phase='before', widthArg='1440', route='/fr/'] = process.argv.slice(2);
const width = Number(widthArg);
const tabs = await (await fetch('http://127.0.0.1:9331/json')).json();
const ws = new WebSocket(tabs.find(t=>t.type==='page').webSocketDebuggerUrl);
await new Promise(resolve=>ws.addEventListener('open',resolve,{once:true}));
let id=0; const pending=new Map(); const errors=[];
ws.addEventListener('message', e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);m.error?p.reject(m.error):p.resolve(m.result);}else if(m.method==='Runtime.exceptionThrown') errors.push(m.params.exceptionDetails.text);});
function call(method,params={}){return new Promise((resolve,reject)=>{pending.set(++id,{resolve,reject});ws.send(JSON.stringify({id,method,params}));});}
const evaluate=async expression=>(await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true})).result.value;
await call('Page.enable'); await call('Runtime.enable');
await call('Emulation.setDeviceMetricsOverride',{width,height:width<700?844:1000,deviceScaleFactor:1,mobile:false});
await call('Page.navigate',{url:'http://127.0.0.1:8766'+route});
await new Promise(r=>setTimeout(r,1000));
await evaluate('document.fonts.ready.then(()=>Promise.all([...document.images].filter(i=>i.loading!=="lazy").map(i=>i.decode().catch(()=>{}))))');
const folder='docs/site-public/captures/reprise-finale'; await mkdir(folder,{recursive:true});
const capture=async(name,clip)=>{const shot=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,...(clip?{clip}:{})});await writeFile(`${folder}/${phase}-${width}-${name}.png`,Buffer.from(shot.data,'base64'));};
await capture('hero',{x:0,y:0,width,height:width<700?844:1000,scale:1});
const sections=await evaluate(`Array.from(document.querySelectorAll('.home-section, .site-footer')).map(e=>{const b=e.getBoundingClientRect();return {id:e.id||'pied-de-page',x:0,y:b.y+scrollY,width:innerWidth,height:Math.ceil(b.height),scale:1}})`);
for(const section of sections){
  const current = await evaluate('scrollY');
  await call('Input.dispatchMouseEvent',{type:'mouseWheel',x:width/2,y:400,deltaX:0,deltaY:section.y-current});
  await new Promise(r=>setTimeout(r,400));
  const {id,...clip}=section; await capture(id,clip);
}
const metrics=await evaluate(`({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,background:getComputedStyle(document.body).backgroundColor,fonts:[...document.fonts].filter(f=>f.status==='loaded').map(f=>f.family),brokenImages:[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.src),overflow:[...document.querySelectorAll('main *, footer *')].filter(e=>{const r=e.getBoundingClientRect();return r.width>0&&(r.right>innerWidth+1||r.left< -1)}).map(e=>e.className).slice(0,20)})`);
await writeFile(`${folder}/${phase}-${width}-metrics.json`,JSON.stringify({...metrics,errors},null,2));
console.log(JSON.stringify({...metrics,errors})); ws.close();
