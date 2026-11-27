import * as THREE from 'three';
import { SVGLoader } from 'three/addons/loaders/SVGLoader.js';

const P = Object.assign({ w:1080, h:1920, yaw:-0.52, haze:1, steps:40, frontal:false, msaa:4 }, window.__PARAMS||{});
const U = 0.01;                 // 1 unité SVG = 1 cm
const GAP_X = 261.06;           // centre de l'entrebâillement (220.509..301.62), lu dans le tracé
const FLOOR_Y = 700;            // niveau du sol en unités SVG (l'ornement est coupé sur un cercle : bas non plat)
const DEPTH = 0.55;             // épaisseur de l'arche (m)

const canvas = document.getElementById('c');
canvas.width = P.w; canvas.height = P.h;
const renderer = new THREE.WebGLRenderer({ canvas, antialias:false, preserveDrawingBuffer:true });
renderer.setPixelRatio(1); renderer.setSize(P.w, P.h, false);
renderer.shadowMap.enabled = true; renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.outputColorSpace = THREE.LinearSRGBColorSpace; // on fait le tonemap + sRGB nous-mêmes

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0b0914);
scene.fog = new THREE.FogExp2(0x0b0914, 0.012);

// ---------- caméra unique ----------
const camera = P.frontal ? new THREE.OrthographicCamera(-P.w/4*U, P.w/4*U, P.h/4*U, -P.h/4*U, 0.1, 120) : new THREE.PerspectiveCamera(44, P.w/P.h, 0.1, 120);

// ---------- arche : tracé officiel extrudé, AUCUN point redessiné ----------
const svg = new SVGLoader().parse(window.__SVG);
const shapes = svg.paths.flatMap(p => SVGLoader.createShapes(p));
const archGeo = new THREE.ExtrudeGeometry(shapes, { depth: DEPTH/U, bevelEnabled:false, curveSegments:48 });
// repère : x centré sur l'entrebâillement, y vers le haut (seul Y est inversé), sol à FLOOR_Y
archGeo.translate(-GAP_X, -FLOOR_Y, 0); archGeo.scale(U, -U, U);
// l'inversion de Y retourne les triangles : on rétablit l'ordre pour garder des normales sortantes
{ const idx = archGeo.index; if (idx){ const a=idx.array; for(let i=0;i<a.length;i+=3){const t=a[i+1];a[i+1]=a[i+2];a[i+2]=t;} }
  else { const pos=archGeo.attributes.position, uv=archGeo.attributes.uv; for(let i=0;i<pos.count;i+=3){ for(const at of [pos,uv]){ if(!at) continue; const n=at.itemSize; const b=at.array.slice((i+1)*n,(i+2)*n); at.array.copyWithin((i+1)*n,(i+2)*n,(i+3)*n); at.array.set(b,(i+2)*n);} } }
  archGeo.computeVertexNormals(); }
const archMat = new THREE.MeshStandardMaterial({ color:0xf4f1fa, roughness:0.62, metalness:0.0, side:THREE.DoubleSide, shadowSide:THREE.DoubleSide });
const arch = new THREE.Mesh(archGeo, archMat); arch.castShadow = true; arch.receiveShadow = true;

const door = new THREE.Group();            // tout ce qui tourne avec la porte : arche, lumière, cache
door.add(arch);
door.position.set(P.frontal?0:1.15, 0, 0);
door.rotation.y = P.frontal?0:P.yaw;
scene.add(door);

// cache invisible : ne laisse passer la lumière que par les vides du tracé (ouverture x 30..300, y>185 en unités SVG)
{ const s = new THREE.Shape(); s.moveTo(-30,-3); s.lineTo(30,-3); s.lineTo(30,30); s.lineTo(-30,30); s.closePath();
  const h = new THREE.Path(); const x0=(30-GAP_X)*U, x1=(300-GAP_X)*U, y1=(FLOOR_Y-185)*U;
  h.moveTo(x0,-3); h.lineTo(x1,-3); h.lineTo(x1,y1); h.lineTo(x0,y1); h.closePath(); s.holes.push(h);
  const m = new THREE.Mesh(new THREE.ShapeGeometry(s), new THREE.MeshBasicMaterial({ colorWrite:false, depthWrite:false, side:THREE.DoubleSide }));
  m.position.z = -0.02; m.castShadow = true; m.userData.blocker = true; door.add(m);
  { const b = new THREE.Mesh(new THREE.PlaneGeometry(60,30), m.material); b.rotation.x=-Math.PI/2; b.position.set(0,0.012,-15.02); b.castShadow=true; door.add(b); }
  // intérieur lumineux visible à travers les vides (ne projette pas d'ombre)
  const g = new THREE.Mesh(new THREE.PlaneGeometry(x1-x0+0.02, y1+3), new THREE.MeshBasicMaterial({ color:new THREE.Color(4.6,4.3,5.6), fog:false }));
  g.position.set((x0+x1)/2, (y1-3)/2, -0.06); g.userData.noLight = true; g.visible = !P.frontal; door.add(g);
}

// ---------- source unique, dans l'embrasure ----------
const LIGHT_LOCAL = new THREE.Vector3(0.0, 2.35, -2.6);
const spot = new THREE.SpotLight(0xF2EBFF, 900, 60, 1.05, 0.35, 2);
spot.position.copy(LIGHT_LOCAL); spot.target.position.set(0, 1.6, 4); door.add(spot); door.add(spot.target);
spot.castShadow = true; spot.shadow.mapSize.set(2048,2048); spot.shadow.camera.near = 1.0; spot.shadow.camera.far = 50; spot.shadow.bias = -0.0006; spot.shadow.radius = 3;

// lumières d'ambiance très faibles (lisibilité de la face avant ; déclarées comme "fill", pas comme source)
scene.add(new THREE.HemisphereLight(0x6a4fd0, 0x120e22, P.frontal?2.5:0.38));
const fill = new THREE.DirectionalLight(0x8652E6, P.frontal?0:0.22); fill.position.set(-4,6,10); scene.add(fill);
// rebond du sol éclairé vers l'arche (approximation d'illumination indirecte : 1 lumière ponctuelle au centre de la nappe)
const bounce = new THREE.PointLight(0xDCCAFD, P.frontal?0:5.5, 9, 2); bounce.position.set(0, 0.25, 1.6); door.add(bounce);

// ---------- sol ----------
const floor = new THREE.Mesh(new THREE.PlaneGeometry(200,200), new THREE.MeshStandardMaterial({ color:0x3d3360, roughness:0.86, metalness:0.0 }));
floor.rotation.x = -Math.PI/2; floor.receiveShadow = true; scene.add(floor);

// ---------- route de dalles : sort selon la normale de la porte, puis tourne à gauche ----------
door.updateMatrixWorld(true);
const n = new THREE.Vector3(0,0,1).transformDirection(door.matrixWorld);
const D = new THREE.Vector3(0,0,DEPTH*0.5).applyMatrix4(door.matrixWorld); D.y = 0;
const pts = [ D.clone().addScaledVector(n,-0.6), D.clone(), D.clone().addScaledVector(n,2.2), D.clone().addScaledVector(n,4.2),
  new THREE.Vector3(-1.75,0,6.3), new THREE.Vector3(-3.3,0,8.4), new THREE.Vector3(-6.2,0,9.9), new THREE.Vector3(-11,0,10.6), new THREE.Vector3(-17,0,10.6) ];
const curve = new THREE.CatmullRomCurve3(pts, false, 'centripetal', 0.5);
const L = curve.getLength();
const ROAD_W = 1.5, NX = 3, ROW = 0.52, JOINT = 0.035;
const rows = Math.floor(L/ROW);
const tileGeo = new THREE.BoxGeometry(1,0.05,1);
const tiles = new THREE.InstancedMesh(tileGeo, new THREE.MeshStandardMaterial({ color:0x8f86ad, roughness:0.72 }), rows*(NX+1));
tiles.castShadow = true; tiles.receiveShadow = true;
{ const m = new THREE.Matrix4(), q = new THREE.Quaternion(), sc = new THREE.Vector3(), pos = new THREE.Vector3(); let k=0; const col = new THREE.Color();
  for (let r=0;r<rows;r++){ const u=(r+0.5)*ROW/L; const p=curve.getPointAt(u), t=curve.getTangentAt(u); const side=new THREE.Vector3(t.z,0,-t.x);
    q.setFromUnitVectors(new THREE.Vector3(0,0,1), t.clone().setY(0).normalize());
    const odd = r%2; const cells = odd? NX+1 : NX; const cw = ROAD_W/NX;
    for (let c=0;c<cells;c++){ let x0 = odd ? (c-0.5)*cw : c*cw, x1 = x0+cw; x0=Math.max(0,x0); x1=Math.min(ROAD_W,x1);
      const w = x1-x0-JOINT; pos.copy(p).addScaledVector(side,(x0+x1)/2-ROAD_W/2); pos.y=0.025;
      sc.set(w,1,ROW-JOINT); m.compose(pos,q,sc); tiles.setMatrixAt(k,m);
      const v = 0.86+0.14*Math.abs(Math.sin(r*12.9898+c*78.233)*43758.5453%1); col.setRGB(v*0.56,v*0.52,v*0.70); tiles.setColorAt(k,col); k++; } }
  tiles.count = k; }
if(!P.frontal) scene.add(tiles);

// ---------- PLACEHOLDER (ce n'est pas Praxis) ----------
const ph = new THREE.Group();
const sph = new THREE.Mesh(new THREE.SphereGeometry(0.42, 48, 32), new THREE.MeshStandardMaterial({ color:0xb7a4f0, roughness:0.55 }));
sph.castShadow = true; sph.receiveShadow = true; ph.add(sph);
{ const cv = document.createElement('canvas'); cv.width=512; cv.height=96; const g=cv.getContext('2d'); g.fillStyle='rgba(0,0,0,0.55)'; g.fillRect(0,0,512,96); g.fillStyle='#fff'; g.font='bold 40px sans-serif'; g.textAlign='center'; g.fillText('PLACEHOLDER (pas Praxis)',256,62);
  const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map:new THREE.CanvasTexture(cv), fog:false, depthTest:false })); sp.scale.set(1.5,0.28,1); sp.position.y=0.72; sp.userData.noLight=true; ph.add(sp); }
if(!P.frontal) scene.add(ph);

// ---------- cibles de rendu ----------
const depthTex = new THREE.DepthTexture(P.w, P.h); depthTex.type = THREE.UnsignedIntType;
const rtScene = new THREE.WebGLRenderTarget(P.w, P.h, { type:THREE.HalfFloatType, samples:P.msaa, depthTexture:depthTex });
const LS = 1024;
const lightDepth = new THREE.DepthTexture(LS, LS); lightDepth.type = THREE.UnsignedIntType;
const rtLight = new THREE.WebGLRenderTarget(LS, LS, { depthTexture:lightDepth });
const lightCam = new THREE.PerspectiveCamera(THREE.MathUtils.radToDeg(spot.angle)*2, 1, 1.0, 50);
const hw = Math.round(P.w/2), hh = Math.round(P.h/2);
const rtHaze = new THREE.WebGLRenderTarget(hw, hh, { type:THREE.HalfFloatType });
const rtHaze2 = new THREE.WebGLRenderTarget(hw, hh, { type:THREE.HalfFloatType });
const depthOnly = new THREE.MeshBasicMaterial({ side:THREE.DoubleSide });

const fsScene = new THREE.Scene(); const fsCam = new THREE.OrthographicCamera(-1,1,1,-1,0,1);
const quad = new THREE.Mesh(new THREE.PlaneGeometry(2,2)); fsScene.add(quad);
const VS = `varying vec2 vUv; void main(){ vUv=uv; gl_Position=vec4(position.xy,0.,1.); }`;

// brume volumétrique : marche de rayon dans le cône de la lampe, occultée par la carte de profondeur de la lampe
const hazeMat = new THREE.ShaderMaterial({ vertexShader:VS, depthTest:false, depthWrite:false,
  uniforms:{ tDepth:{value:depthTex}, tLight:{value:lightDepth}, invProj:{value:new THREE.Matrix4()}, camWorld:{value:new THREE.Matrix4()},
    lightVP:{value:new THREE.Matrix4()}, lightPos:{value:new THREE.Vector3()}, camPos:{value:new THREE.Vector3()}, lightCol:{value:new THREE.Color(0xC4ACFA)},
    doorP:{value:new THREE.Vector3()}, doorN:{value:new THREE.Vector3()}, uTime:{value:0}, uPower:{value:1}, uDens:{value:P.haze} },
  defines:{ STEPS:P.steps },
  fragmentShader:`precision highp float; varying vec2 vUv; uniform sampler2D tDepth; uniform sampler2D tLight; uniform mat4 invProj, camWorld, lightVP;
  uniform vec3 lightPos, camPos, lightCol, doorP, doorN; uniform float uTime, uPower, uDens;
  float hash(vec3 p){ p=fract(p*0.3183099+.1); p*=17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
  float noise(vec3 x){ vec3 i=floor(x), f=fract(x); f=f*f*(3.-2.*f);
    return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z); }
  void main(){
    float d = texture2D(tDepth, vUv).r;
    vec4 v = invProj * vec4(vUv*2.-1., d*2.-1., 1.); v/=v.w; vec3 wp = (camWorld*v).xyz;
    vec3 rd = wp-camPos; float len = min(length(rd), 45.); rd = normalize(rd);
    float jit = fract(52.9829189*fract(dot(gl_FragCoord.xy, vec2(0.06711056,0.00583715))));
    float stepL = len/float(STEPS); float acc = 0.;
    for(int i=0;i<STEPS;i++){
      vec3 p = camPos + rd*(float(i)+jit)*stepL;
      if(dot(p-doorP,doorN)<0.) continue; vec4 lc = lightVP*vec4(p,1.); if(lc.w<=0.) continue; vec3 nd = lc.xyz/lc.w;
      float rr = length(nd.xy); if(rr>1.||nd.z>1.) continue;
      float sd = texture2D(tLight, nd.xy*.5+.5).r;
      if(nd.z*.5+.5 > sd+0.0004) continue;
      vec3 lv = p-lightPos; float dist2 = dot(lv,lv); lv = normalize(lv);
      float ct = dot(lv,-rd); float g=0.55; float ph = (1.-g*g)/pow(1.+g*g-2.*g*ct,1.5)*0.25;
      float den = 0.55+0.9*noise(p*0.9+vec3(uTime*0.12,-uTime*0.05,uTime*0.08))*noise(p*2.3-vec3(0.,uTime*0.1,0.));
      acc += (1.-smoothstep(0.75,1.,rr)) * ph * den * stepL / (1.+dist2*0.16);
    }
    gl_FragColor = vec4(lightCol*acc*uPower*uDens*0.8, 1.);
  }` });
const blurMat = new THREE.ShaderMaterial({ vertexShader:VS, depthTest:false, depthWrite:false, uniforms:{ t:{value:null}, dir:{value:new THREE.Vector2()} },
  fragmentShader:`precision highp float; varying vec2 vUv; uniform sampler2D t; uniform vec2 dir;
  void main(){ vec3 c=texture2D(t,vUv).rgb*0.227; c+=(texture2D(t,vUv+dir*1.385).rgb+texture2D(t,vUv-dir*1.385).rgb)*0.316; c+=(texture2D(t,vUv+dir*3.231).rgb+texture2D(t,vUv-dir*3.231).rgb)*0.0703; gl_FragColor=vec4(c,1.); }` });
const compMat = new THREE.ShaderMaterial({ vertexShader:VS, depthTest:false, depthWrite:false, uniforms:{ tScene:{value:rtScene.texture}, tHaze:{value:rtHaze.texture}, uHaze:{value:P.frontal?0:1} },
  fragmentShader:`precision highp float; varying vec2 vUv; uniform sampler2D tScene, tHaze; uniform float uHaze;
  vec3 aces(vec3 x){ return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.,1.); }
  void main(){ vec3 c = texture2D(tScene,vUv).rgb + texture2D(tHaze,vUv).rgb*uHaze;
    vec2 q=vUv-.5; c*=1.-0.55*dot(q,q);
    c = aces(c*0.9); c = pow(c, vec3(1./2.2));
    c += (fract(sin(dot(gl_FragCoord.xy,vec2(12.9898,78.233)))*43758.5453)-.5)/255.; // tramage anti-bandes
    gl_FragColor = vec4(c,1.); }` });

const gl = renderer.getContext(); const px = new Uint8Array(4);
const smooth = (a,b,x)=>{ x=Math.min(1,Math.max(0,(x-a)/(b-a))); return x*x*(3-2*x); };

window.renderFrame = (t, dur=3) => {
  const t0 = performance.now();
  const k = t/dur;
  // animation déterministe, fonction de t seulement
  const power = P.frontal ? 0 : (0.25 + 0.75*smooth(0.0,0.45,k));           // la lumière monte
  spot.intensity = 900*power; bounce.intensity = 5.5*power; hazeMat.uniforms.uPower.value = power;
  if (P.frontal){ camera.position.set(0, (FLOOR_Y-372)*U, 17.5); camera.lookAt(0,(FLOOR_Y-372)*U,0); door.position.x = (GAP_X-228.5)*U; }
  else { camera.position.set(0.7-0.6*k, 2.7+0.15*k, 19.0-1.6*k); camera.lookAt(-0.5, 2.3, 0); }
  const u = 0.20 + 0.06*k; const pp = curve.getPointAt(u); ph.position.set(pp.x, 0.66+0.05*Math.sin(t*6.0), pp.z);
  scene.updateMatrixWorld(true); camera.updateMatrixWorld(true);

  // 1. profondeur vue de la lampe (même géométrie que les ombres : l'arche officielle + le cache)
  lightCam.position.copy(spot.getWorldPosition(new THREE.Vector3())); lightCam.lookAt(spot.target.getWorldPosition(new THREE.Vector3())); lightCam.updateMatrixWorld(true);
  const hidden=[]; scene.traverse(o=>{ if(o.userData.noLight && o.visible){ o.visible=false; hidden.push(o);} });
  const fog = scene.fog, bg = scene.background; scene.fog=null; scene.background=null; scene.overrideMaterial = depthOnly;
  const sm = renderer.shadowMap.autoUpdate; renderer.shadowMap.autoUpdate=false;
  renderer.setRenderTarget(rtLight); renderer.clear(); renderer.render(scene, lightCam);
  renderer.shadowMap.autoUpdate=sm; scene.overrideMaterial=null; scene.fog=fog; scene.background=bg; hidden.forEach(o=>o.visible=true);
  // 2. scène
  renderer.setRenderTarget(rtScene); renderer.render(scene, camera);
  // 3. brume (demi-résolution) + flou séparable
  hazeMat.uniforms.invProj.value.copy(camera.projectionMatrixInverse); hazeMat.uniforms.camWorld.value.copy(camera.matrixWorld);
  hazeMat.uniforms.lightVP.value.multiplyMatrices(lightCam.projectionMatrix, lightCam.matrixWorldInverse);
  hazeMat.uniforms.lightPos.value.copy(lightCam.position); hazeMat.uniforms.camPos.value.copy(camera.position); hazeMat.uniforms.uTime.value = t; hazeMat.uniforms.doorP.value.setFromMatrixPosition(door.matrixWorld); hazeMat.uniforms.doorN.value.set(0,0,1).transformDirection(door.matrixWorld);
  if (!P.frontal && P.haze>0){
    quad.material = hazeMat; renderer.setRenderTarget(rtHaze); renderer.render(fsScene, fsCam);
    blurMat.uniforms.t.value = rtHaze.texture; blurMat.uniforms.dir.value.set(1/hw,0); quad.material = blurMat; renderer.setRenderTarget(rtHaze2); renderer.render(fsScene, fsCam);
    blurMat.uniforms.t.value = rtHaze2.texture; blurMat.uniforms.dir.value.set(0,1/hh); renderer.setRenderTarget(rtHaze); renderer.render(fsScene, fsCam);
  } else { renderer.setRenderTarget(rtHaze); renderer.setClearColor(0,1); renderer.clear(); }
  // 4. composition
  quad.material = compMat; renderer.setRenderTarget(null); renderer.render(fsScene, fsCam);
  gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px); // force la fin du rendu (équivaut à gl.finish)
  return performance.now()-t0;
};
window.grab = async (type, q) => { const b = await new Promise(r=>canvas.toBlob(r,type,q)); const a = new Uint8Array(await b.arrayBuffer()); let s=''; const CH=0x8000; for(let i=0;i<a.length;i+=CH) s+=String.fromCharCode.apply(null,a.subarray(i,i+CH)); return btoa(s); };
window.__READY = true;

// preuve de fidélité : compare la silhouette 3D de face (orthographique, 2 px par unité SVG) au SVG officiel rastérisé par le navigateur
window.compareSvg = async () => { const img = new Image(); img.src = 'data:image/svg+xml;base64,'+btoa(window.__SVG); await img.decode();
  const c2 = document.createElement('canvas'); c2.width=P.w; c2.height=P.h; const g = c2.getContext('2d');
  g.drawImage(img, P.w/2-228.5*2, P.h/2-372*2, 457*2, 744*2); const a = g.getImageData(0,0,P.w,P.h).data;
  const c3 = document.createElement('canvas'); c3.width=P.w; c3.height=P.h; const g3=c3.getContext('2d'); g3.drawImage(canvas,0,0); const b = g3.getImageData(0,0,P.w,P.h).data;
  let inter=0, uni=0, diff=0, na=0; for(let i=0;i<a.length;i+=4){ const A=a[i+3]>127, B=b[i+2]>80; if(A) na++; if(A&&B) inter++; if(A||B) uni++; if(A!==B) diff++; }
  return { pixels_svg:na, iou:inter/uni, pixels_differents:diff }; };
