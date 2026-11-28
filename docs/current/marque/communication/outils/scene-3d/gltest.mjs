import { createRequire } from 'module';
const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');
const combos = [
 {name:'pw-chromium default', opts:{}},
 {name:'pw-chromium swiftshader', opts:{args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--use-gl=angle']}},
 {name:'google-chrome swiftshader', opts:{executablePath:'/usr/bin/google-chrome',args:['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--use-gl=angle']}},
];
for (const c of combos){ try{
 const b = await chromium.launch(c.opts); const p = await b.newPage();
 const r = await p.evaluate(()=>{const g=document.createElement('canvas').getContext('webgl2'); if(!g) return 'NO WEBGL2'; const e=g.getExtension('WEBGL_debug_renderer_info'); return g.getParameter(e.UNMASKED_RENDERER_WEBGL)+' | max tex '+g.getParameter(g.MAX_TEXTURE_SIZE)+' | floatRT '+!!g.getExtension('EXT_color_buffer_float');});
 console.log(c.name,'=>',r,'|',b.version()); await b.close(); }catch(e){console.log(c.name,'ERR',String(e).slice(0,200));}}
