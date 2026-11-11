// Banc de la salle : de vraies seances sur la pile LOCALE (tool/e2e/pile.sh puis
// tool/salle/banc.sh), avec la VRAIE application, des reseaux abimes par le
// relais (tool/salle/reseau_degrade.mjs) et la mesure de ce que chacun entend.
//
// Chaque participant a son propre navigateur Chromium : son micro factice lit
// un fichier (une recitation), sa camera factice est celle de Chromium.
// Un crochet pose avant le chargement de la page garde les RTCPeerConnection :
// on y lit les statistiques WebRTC et on y enregistre le son RECU, apres le
// tampon de gigue et la dissimulation des pertes, donc ce que la personne entend.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { APP, API, TRAVAIL, MDP, activerSemantique, libelles, trouver, ouvrir, taper } from '../e2e/commun.mjs';

const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');
const WEB = path.join(TRAVAIL, 'web');
const TYPES = { '.js': 'text/javascript', '.wasm': 'application/wasm', '.mjs': 'text/javascript' };
export const RELAIS = 'http://127.0.0.1:7890';

// Pose dans la page, avant tout script de l'application.
const CROCHET = () => {
  const Origine = window.RTCPeerConnection;
  window.__pcs = [];
  window.__audios = [];
  function Espion(...a) {
    const pc = new Origine(...a);
    window.__pcs.push(pc);
    pc.addEventListener('track', (e) => { if (e.track.kind === 'audio') window.__audios.push(e.track); });
    return pc;
  }
  Espion.prototype = Origine.prototype;
  Object.setPrototypeOf(Espion, Origine);
  window.RTCPeerConnection = Espion;

  window.__stats = async () => {
    const sortie = { a: performance.now(), recu: [], emis: [], paires: [], distant: [] };
    for (const pc of window.__pcs) {
      if (pc.connectionState === 'closed') continue;
      const r = await pc.getStats();
      const parId = new Map(); r.forEach((s) => parId.set(s.id, s));
      r.forEach((s) => {
        const codec = s.codecId ? parId.get(s.codecId) : null;
        if (s.type === 'inbound-rtp') {
          sortie.recu.push({ genre: s.kind, codec: codec?.mimeType, nack: s.nackCount, retransmisRecus: s.retransmittedPacketsReceived, fmtp: codec?.sdpFmtpLine, ssrc: s.ssrc,
            paquets: s.packetsReceived, perdus: s.packetsLost, gigue: s.jitter, octets: s.bytesReceived,
            echantillons: s.totalSamplesReceived, dissimules: s.concealedSamples, dissimulesMuets: s.silentConcealedSamples,
            evenementsDissimulation: s.concealmentEvents, fecRecus: s.fecPacketsReceived, fecJetes: s.fecPacketsDiscarded,
            tamponDelai: s.jitterBufferDelay, tamponEmis: s.jitterBufferEmittedCount,
            acceleres: s.removedSamplesForAcceleration, ralentis: s.insertedSamplesForDeceleration,
            images: s.framesDecoded, largeur: s.frameWidth, hauteur: s.frameHeight, ips: s.framesPerSecond, gels: s.freezeCount });
        } else if (s.type === 'outbound-rtp') {
          sortie.emis.push({ genre: s.kind, codec: codec?.mimeType, fmtp: codec?.sdpFmtpLine, rid: s.rid, octets: s.bytesSent,
            paquets: s.packetsSent, cible: s.targetBitrate, largeur: s.frameWidth, hauteur: s.frameHeight, ips: s.framesPerSecond,
            limite: s.qualityLimitationReason, retransmis: s.retransmittedPacketsSent });
        } else if (s.type === 'remote-inbound-rtp') {
          sortie.distant.push({ genre: s.kind, fractionPerdue: s.fractionLost, allerRetour: s.roundTripTime, gigue: s.jitter });
        } else if (s.type === 'candidate-pair' && s.nominated && s.state === 'succeeded') {
          const l = parId.get(s.localCandidateId); const d = parId.get(s.remoteCandidateId);
          sortie.paires.push({ port: l?.port, protocole: l?.protocol, type: l?.candidateType, distant: `${d?.address}:${d?.port}`,
            allerRetour: s.currentRoundTripTime, debitSortant: s.availableOutgoingBitrate });
        }
      });
    }
    return sortie;
  };

  // Regle le tampon de gigue vise par les recepteurs audio (W3C
  // RTCRtpReceiver.jitterBufferTarget, en ms) : plus de retard, mais le temps
  // de recevoir une seconde fois un paquet perdu. Rend le nombre de recepteurs.
  window.__tampon = (ms) => {
    let n = 0;
    for (const pc of window.__pcs) {
      if (pc.connectionState === 'closed') continue;
      for (const r of pc.getReceivers()) {
        if (r.track?.kind === 'audio') { r.jitterBufferTarget = ms; n += 1; }
      }
    }
    return n;
  };

  // Ce que la negociation dit de l'audio recu : codecs et retours (nack).
  window.__sdpAudio = () => {
    const lignes = new Set();
    for (const pc of window.__pcs) {
      const sdp = pc.remoteDescription?.sdp ?? '';
      for (const section of sdp.split(/\r?\nm=/).filter((x) => x.startsWith('audio') || x.includes('\nm=audio'))) {
        for (const l of section.split(/\r?\n/)) {
          if (/^a=(rtpmap|rtcp-fb|fmtp):\d+ .*(opus|red|nack)/i.test(l) || /^a=rtcp-fb:\d+ nack/.test(l)) lignes.add(l.trim());
        }
      }
    }
    return [...lignes];
  };

  // Enregistre toutes les pistes audio recues, melangees comme a l'ecoute.
  window.__enregistrer = () => {
    const pistes = window.__audios.filter((t) => t.readyState === 'live');
    if (!pistes.length) return 0;
    const ctx = new AudioContext({ sampleRate: 48000 });
    const dest = ctx.createMediaStreamDestination();
    for (const t of pistes) ctx.createMediaStreamSource(new MediaStream([t])).connect(dest);
    const morceaux = [];
    const enr = new MediaRecorder(dest.stream, { mimeType: 'audio/webm;codecs=opus', audioBitsPerSecond: 256000 });
    enr.ondataavailable = (e) => { if (e.data.size) morceaux.push(e.data); };
    enr.start(1000);
    window.__enr = { enr, morceaux, ctx };
    return pistes.length;
  };
  window.__arreter = () => new Promise((fini) => {
    const { enr, morceaux, ctx } = window.__enr;
    enr.onstop = async () => {
      const tampon = new Uint8Array(await new Blob(morceaux).arrayBuffer());
      let s = ''; for (let i = 0; i < tampon.length; i += 0x8000) s += String.fromCharCode(...tampon.subarray(i, i + 0x8000));
      ctx.close(); fini(btoa(s));
    };
    enr.stop();
  });
};

/// Un participant : son navigateur, son micro factice (`audio` : fichier WAV lu
/// en boucle ; absent : le bip de Chromium), sa taille d'ecran.
export async function participant(nom, { audio = null, vue = { width: 1440, height: 900 }, telephone = false,
  sombre = false, langue = 'fr-FR', echelleTexte = null } = {}) {
  const navigateur = await chromium.launch({
    args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream',
      '--autoplay-policy=no-user-gesture-required',
      ...(audio ? [`--use-file-for-fake-audio-capture=${audio}`] : [])],
  });
  const ctx = await navigateur.newContext({
    viewport: telephone ? { width: 390, height: 780 } : vue,
    // Ecran tactile de telephone, mais agent de navigateur d'ordinateur : avec un
    // agent mobile, Flutter n'allume l'arbre d'accessibilite que par un vrai
    // toucher, et le banc ne lirait plus l'ecran.
    ...(telephone ? { hasTouch: true } : {}),
    colorScheme: sombre ? 'dark' : 'light', deviceScaleFactor: 1, locale: langue, timezoneId: 'Europe/Paris',
    permissions: ['camera', 'microphone'], ignoreHTTPSErrors: true,
  });
  await ctx.addInitScript(CROCHET);
  await ctx.route('**/*', (route) => {
    const u = new URL(route.request().url());
    if (u.host === 'www.gstatic.com' && u.pathname.startsWith('/flutter-canvaskit/')) {
      const f = path.join(WEB, 'canvaskit', u.pathname.split('/').slice(3).join('/'));
      if (fs.existsSync(f)) return route.fulfill({ path: f, contentType: TYPES[path.extname(f)] });
      return route.abort();
    }
    if (u.hostname === 'kong') return route.continue({ url: u.href.replace(`${u.protocol}//${u.host}`, API) });
    if (u.hostname === '127.0.0.1' || u.hostname === 'localhost' || /^172\.\d+\.\d+\.\d+$/.test(u.hostname)) return route.continue();
    if (u.host === 'fonts.gstatic.com' || u.host === 'fonts.googleapis.com') return route.continue();
    if (u.protocol === 'data:' || u.protocol === 'blob:') return route.continue();
    return route.abort();
  });
  const page = await ctx.newPage();
  const journal = [];
  page.on('pageerror', (e) => journal.push(`erreur de page : ${String(e).slice(0, 300)}`));
  page.on('console', (m) => { if (m.type() === 'error' && !m.text().startsWith('Failed to load resource')) journal.push(`console : ${m.text().slice(0, 300)}`); });
  const moi = { nom, navigateur, ctx, page, journal };
  moi.lus = async (k = 60) => (await libelles(page)).slice(0, k).join(' | ');
  moi.stats = () => page.evaluate(() => window.__stats());
  moi.ports = async () => [...new Set((await moi.stats()).paires.map((x) => x.port).filter(Boolean))];
  moi.fermer = () => navigateur.close();
  return moi;
}

export async function connecter(p, courriel) {
  await ouvrir(p.page, '/');
  if (!(await p.page.locator('input[type=password]').count())) {
    const e = await trouver(p.page, /^(J'ai déjà un compte|لدي حساب بالفعل)$/, { delai: 8000 });
    if (e) { await e.click(); await p.page.waitForTimeout(1200); }
  }
  await taper(p.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(p.page, 'input[type=password]', MDP);
  await p.page.keyboard.press('Enter');
  await p.page.waitForTimeout(5000);
  await activerSemantique(p.page);
}

/// Clique le premier bouton dont le nom correspond ; rend son nom, ou null.
export async function appuyer(p, motif, { delai = 8000, pause = 1500, role = 'button' } = {}) {
  const b = await trouver(p.page, motif, { delai, role });
  if (!b) return null;
  const nom = await b.getAttribute('aria-label').catch(() => null);
  await b.click();
  await p.page.waitForTimeout(pause);
  await activerSemantique(p.page);
  return nom ?? String(motif);
}

/// Regle le reseau d'un participant : `montant` (lui vers le serveur) et
/// `descendant` (le serveur vers lui). Sans argument : reseau parfait.
///
/// Le reglage vaut pour TOUS les flux que ce participant a ouverts depuis son
/// entree : sous de fortes pertes la connexion se reconstruit sur un nouveau
/// flux, et l'ancien ne doit pas garder le reglage d'avant. `entretenir`
/// repose le meme reglage (a appeler pendant une mesure, pour les flux nes
/// entre-temps).
export async function reseau(p, { montant = {}, descendant = {} } = {}) {
  p.profilReseau = { montant, descendant };
  return entretenir(p, { exiger: true });
}

export async function entretenir(p, { exiger = false } = {}) {
  if (!p.profilReseau) return [];
  p.portsConnus ??= new Set();
  for (const port of await p.ports().catch(() => [])) p.portsConnus.add(port);
  let regles = 0;
  for (const port of p.portsConnus) {
    const r = await (await fetch(`${RELAIS}/profil`, { method: 'POST', body: JSON.stringify({ port, ...p.profilReseau }) })).json();
    regles += r.regles ?? 0;
  }
  // Un reglage qui ne touche aucun flux fausserait toute la mesure en silence.
  if (exiger && !regles) throw new Error(`${p.nom} : aucun flux du relais ne correspond aux ports ${[...p.portsConnus].join(', ')}`);
  return [...p.portsConnus];
}

/// Enregistre `secondes` de ce que le participant entend ; rend le chemin.
export async function ecouter(p, secondes, fichier) {
  const n = await p.page.evaluate(() => window.__enregistrer());
  if (!n) throw new Error(`${p.nom} : aucune piste audio recue a enregistrer`);
  await p.page.waitForTimeout(secondes * 1000);
  const b64 = await p.page.evaluate(() => window.__arreter());
  fs.mkdirSync(path.dirname(fichier), { recursive: true });
  fs.writeFileSync(fichier, Buffer.from(b64, 'base64'));
  return fichier;
}

/// Resume audio entre deux releves de statistiques (recu).
export function bilanAudio(avant, apres) {
  const cle = (s) => s.ssrc;
  const sortie = [];
  for (const b of apres.recu.filter((s) => s.genre === 'audio')) {
    const a = avant.recu.find((s) => cle(s) === cle(b)) ?? {};
    const d = (k) => (b[k] ?? 0) - (a[k] ?? 0);
    const paquets = d('paquets'); const perdus = d('perdus'); const ech = d('echantillons');
    if (ech <= 0) continue;
    sortie.push({ codec: b.codec, fmtp: b.fmtp,
      pertes: +(perdus / Math.max(1, paquets + perdus)).toFixed(4),
      dissimule: +(d('dissimules') / ech).toFixed(4),
      dissimuleMuet: +(d('dissimulesMuets') / ech).toFixed(4),
      evenements: d('evenementsDissimulation'),
      fecRecus: d('fecRecus'),
      tamponMs: Math.round(1000 * d('tamponDelai') / Math.max(1, d('tamponEmis'))),
      gigueMs: Math.round(1000 * (b.gigue ?? 0)),
      debitKbps: Math.round(d('octets') * 8 / Math.max(1, apres.a - avant.a)) });
  }
  return sortie;
}
export { APP, activerSemantique, libelles, trouver };
