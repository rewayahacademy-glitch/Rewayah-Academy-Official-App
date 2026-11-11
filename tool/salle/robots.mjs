// Banc de la salle : des eleves « robots », legers, pour remplir une classe.
//
// Douze fois la vraie application sur une seule machine de test satureraient
// son processeur et l'on mesurerait la machine, pas la salle. Un robot est une
// page nue qui entre dans la salle avec la bibliotheque web de LiveKit :
// meme serveur, meme jeton que la vraie application (il se connecte avec le
// compte de l'eleve et demande son jeton a `create-room-token`), donc memes
// droits ; micro factice, camera factice en petite taille.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { APP, API, MDP, TRAVAIL } from '../e2e/commun.mjs';

const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');
const LIVEKIT_WEB = '/opt/node-tools/node_modules/livekit-client/dist/livekit-client.umd.js';
const CLE = fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8').match(/^PUBLISHABLE_KEY="?([^"\n]+)/m)[1];

/// Le jeton de salle d'un eleve, demande comme le fait l'application.
export async function jetonDe(courriel, seance) {
  const session = await (await fetch(`${API}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: CLE, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP }),
  })).json();
  if (!session.access_token) throw new Error(`connexion refusee pour ${courriel} : ${JSON.stringify(session).slice(0, 200)}`);
  const r = await fetch(`${API}/functions/v1/create-room-token`, {
    method: 'POST', headers: { apikey: CLE, Authorization: `Bearer ${session.access_token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ session_id: seance }),
  });
  const acces = await r.json();
  if (!acces.token) throw new Error(`jeton refuse pour ${courriel} (${r.status}) : ${JSON.stringify(acces).slice(0, 300)}`);
  return acces;
}

/// Fait entrer des robots dans la seance. `eleves` : ceux de `amorcerClasse`.
/// `audio` : fichier WAV du micro factice (sinon le bip de Chromium, coupe).
/// Rend { navigateur, pages, fermer }.
export async function robots(eleves, seance, { camera = true, micro = false, audio = null } = {}) {
  const navigateur = await chromium.launch({
    args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream',
      '--autoplay-policy=no-user-gesture-required',
      ...(audio ? [`--use-file-for-fake-audio-capture=${audio}`] : [])],
  });
  const pages = [];
  for (const eleve of eleves) {
    const acces = await jetonDe(eleve.courriel, seance);
    const ctx = await navigateur.newContext({ permissions: ['camera', 'microphone'], viewport: { width: 320, height: 240 } });
    const page = await ctx.newPage();
    // Une origine sure (127.0.0.1) pour que le navigateur donne micro et camera.
    await page.goto(`${APP}/version.json`);
    await page.addScriptTag({ path: LIVEKIT_WEB });
    const etat = await page.evaluate(async ({ acces, camera, micro }) => {
      const lk = window.LivekitClient;
      const salle = new lk.Room({
        adaptiveStream: false, dynacast: true,
        // Petite image, une seule couche : un robot ne doit pas couter.
        videoCaptureDefaults: { resolution: { width: 320, height: 180, frameRate: 10 } },
        publishDefaults: { simulcast: false, videoEncoding: { maxBitrate: 120000, maxFramerate: 10 } },
      });
      window.__salle = salle;
      await salle.connect(acces.ws_url, acces.token, { autoSubscribe: false });
      const sortie = { identite: salle.localParticipant.identity, droits: salle.localParticipant.permissions };
      if (micro) await salle.localParticipant.setMicrophoneEnabled(true).catch((e) => { sortie.micro = String(e); });
      if (camera) await salle.localParticipant.setCameraEnabled(true).catch((e) => { sortie.camera = String(e); });
      sortie.pistes = [...salle.localParticipant.trackPublications.values()].map((p) => p.source);
      return sortie;
    }, { acces, camera, micro });
    pages.push({ eleve, page, etat });
  }
  return { navigateur, pages, fermer: () => navigateur.close() };
}
