// Banc de la salle : MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026, defaut SEC-1).
//
// La regle : tant que l'enseignant n'est pas dans la salle, le SERVEUR refuse
// le micro d'un eleve ; a l'entree de l'enseignant, il le lui rend.
//
// Ce script le prouve sur la pile LOCALE, par les vraies fonctions Edge et le
// vrai serveur LiveKit, avec des participants legers (une page nue et la
// bibliotheque web de LiveKit, comme `robots.mjs`) :
//
//   1. un eleve entre seul : `create-room-token` dit `publication_differee`,
//      LiveKit lui donne `canPublish = false`, et ouvrir le micro echoue ;
//   2. le filet demande trop tot (sans enseignant) est refuse par le serveur ;
//   3. un second eleve prend son jeton (differe) mais n'entre pas encore ;
//   4. l'enseignant entre (jamais differe) : le webhook rend son droit au
//      premier eleve, qui ouvre alors son micro, et l'enseignant recoit sa voix ;
//   5. le second eleve entre avec son jeton differe, APRES l'enseignant : sa
//      propre entree le retablit (sinon il resterait muet devant l'enseignant) ;
//   6. un eleve qui prend son jeton apres l'enseignant a ses droits ordinaires.
//
// Prerequis : `tool/e2e/pile.sh` lancee AVEC les fonctions de cette branche
// (create-room-token, livekit-webhook, _shared/). Rien n'ecrit hors de la
// machine. Usage :
//
//   node tool/salle/micro_avant_enseignant.mjs
//
// Limite : le filet qui RETABLIT (etape « webhook perdu ») ne se prouve qu'en
// coupant le webhook de LiveKit (retirer le bloc `webhook:` de son fichier de
// configuration, relancer le conteneur), puis `SANS_WEBHOOK=1 node ...` : le
// script appelle alors lui-meme le filet la ou l'application le ferait.
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { APP, API, MDP, TRAVAIL, COMPTES } from '../e2e/commun.mjs';
import { amorcerClasse } from './amorce.mjs';

const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');
const LIVEKIT_WEB = '/opt/node-tools/node_modules/livekit-client/dist/livekit-client.umd.js';
const CLE = fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8').match(/^PUBLISHABLE_KEY="?([^"\n]+)/m)[1];
const SANS_WEBHOOK = process.env.SANS_WEBHOOK === '1';

let echecs = 0;
function verifier(nom, ok, detail) {
  console.log(`${ok ? 'OK   ' : 'ECHEC'} ${nom}${detail === undefined ? '' : ` : ${JSON.stringify(detail)}`}`);
  if (!ok) echecs++;
}
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));

/// Appelle `create-room-token` avec le compte [courriel], comme l'application.
async function demander(courriel, corps) {
  const session = await (await fetch(`${API}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: CLE, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP }),
  })).json();
  if (!session.access_token) throw new Error(`connexion refusee pour ${courriel}`);
  const r = await fetch(`${API}/functions/v1/create-room-token`, {
    method: 'POST',
    headers: { apikey: CLE, Authorization: `Bearer ${session.access_token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(corps),
  });
  return { statut: r.status, corps: await r.json() };
}

/// Entre dans la salle avec [acces] ; rend la page, qui garde la salle.
async function entrer(navigateur, acces) {
  const ctx = await navigateur.newContext({ permissions: ['camera', 'microphone'], viewport: { width: 320, height: 240 } });
  const page = await ctx.newPage();
  await page.goto(`${APP}/version.json`);
  await page.addScriptTag({ path: LIVEKIT_WEB });
  await page.evaluate(async (a) => {
    const lk = window.LivekitClient;
    const salle = new lk.Room({ adaptiveStream: false, dynacast: false });
    window.__salle = salle;
    window.__voixRecues = [];
    salle.on(lk.RoomEvent.TrackSubscribed, (piste, _pub, qui) => {
      if (piste.kind === 'audio') window.__voixRecues.push(qui.identity);
    });
    await salle.connect(a.ws_url, a.token);
  }, acces);
  return page;
}

const droits = (page) => page.evaluate(() => {
  const p = window.__salle.localParticipant.permissions;
  return { canPublish: p?.canPublish ?? null, sources: p?.canPublishSources ?? [] };
});

/// Tente d'ouvrir le micro ; rend { ouvert, erreur }.
const ouvrirMicro = (page) => page.evaluate(async () => {
  const local = window.__salle.localParticipant;
  let erreur = null;
  try {
    await Promise.race([
      local.setMicrophoneEnabled(true),
      new Promise((_, ko) => setTimeout(() => ko(new Error('aucune reponse du serveur en 12 s')), 12000)),
    ]);
  } catch (e) { erreur = String(e?.message ?? e); }
  const pistes = [...local.trackPublications.values()].filter((p) => p.kind === 'audio' && p.trackSid);
  return { ouvert: pistes.length > 0, erreur };
});

/// Attend que le serveur ait rendu le droit de publier (au plus [ms]).
async function attendreDroit(page, ms) {
  const debut = Date.now();
  while (Date.now() - debut < ms) {
    if ((await droits(page)).canPublish === true) return Date.now() - debut;
    await attendre(200);
  }
  return null;
}

const classe = amorcerClasse({ n: 3, etiquette: 'micro-avant-enseignant' });
const [a, b, c] = classe.eleves;
const navigateur = await chromium.launch({
  args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream', '--autoplay-policy=no-user-gesture-required'],
});

try {
  // 1. Un eleve entre seul.
  const jetonA = await demander(a.courriel, { session_id: classe.seance });
  verifier('1. eleve seul : le serveur differe sa publication', jetonA.corps.publication_differee === true,
    { statut: jetonA.statut, publication_differee: jetonA.corps.publication_differee });
  verifier('1. la reponse garde les droits qu\'il retrouvera', jetonA.corps.capabilities?.can_publish === true);
  const pageA = await entrer(navigateur, jetonA.corps);
  const droitsA = await droits(pageA);
  verifier('1. LiveKit ne lui accorde pas le droit de publier', droitsA.canPublish === false, droitsA);
  const essaiA = await ouvrirMicro(pageA);
  verifier('1. ouvrir le micro ECHOUE (refuse par le serveur)', essaiA.ouvert === false, essaiA);

  // 2. Le filet, sans enseignant : le serveur refuse.
  const tropTot = await demander(a.courriel, { session_id: classe.seance, action: 'retablir_publication' });
  verifier('2. filet sans enseignant : rien n\'est rendu',
    tropTot.corps.retabli === false && tropTot.corps.publication_differee === true, tropTot);
  verifier('2. ... et le droit reste ferme chez LiveKit', (await droits(pageA)).canPublish === false);

  // 3. Un second eleve prend son jeton, sans entrer.
  const jetonB = await demander(b.courriel, { session_id: classe.seance });
  verifier('3. second eleve : jeton differe', jetonB.corps.publication_differee === true);

  // 4. L'enseignant entre.
  const jetonEns = await demander(COMPTES.enseignant, { session_id: classe.seance });
  verifier('4. l\'enseignant n\'est jamais differe',
    jetonEns.corps.publication_differee === false && jetonEns.corps.capabilities?.can_publish === true,
    { statut: jetonEns.statut, role: jetonEns.corps.role });
  const pageEns = await entrer(navigateur, jetonEns.corps);
  if (SANS_WEBHOOK) {
    await attendre(1000);
    verifier('4. sans webhook : le droit est encore ferme', (await droits(pageA)).canPublish === false);
    const filet = await demander(a.courriel, { session_id: classe.seance, action: 'retablir_publication' });
    verifier('4. le filet rend le droit', filet.corps.retabli === true && filet.corps.publication_differee === false, filet);
  }
  const delaiA = await attendreDroit(pageA, 8000);
  verifier(`4. le droit de publier est rendu au premier eleve (${SANS_WEBHOOK ? 'filet' : 'webhook'})`,
    delaiA !== null, { ms: delaiA });
  const essaiA2 = await ouvrirMicro(pageA);
  verifier('4. il ouvre alors son micro', essaiA2.ouvert === true, essaiA2);
  await attendre(2500);
  const recues = await pageEns.evaluate(() => window.__voixRecues);
  verifier('4. l\'enseignant recoit sa voix', recues.includes(a.id), recues);

  // 5. Le second eleve entre avec son jeton differe, apres l'enseignant.
  const pageB = await entrer(navigateur, jetonB.corps);
  if (SANS_WEBHOOK) {
    await demander(b.courriel, { session_id: classe.seance, action: 'retablir_publication' });
  }
  const delaiB = await attendreDroit(pageB, 8000);
  verifier('5. entre apres l\'enseignant avec un jeton differe : retabli', delaiB !== null, { ms: delaiB });
  verifier('5. ... et son micro s\'ouvre', (await ouvrirMicro(pageB)).ouvert === true);

  // 6. Un eleve qui prend son jeton apres l'enseignant.
  const jetonC = await demander(c.courriel, { session_id: classe.seance });
  verifier('6. jeton pris apres l\'enseignant : droits ordinaires', jetonC.corps.publication_differee === false);
  const pageC = await entrer(navigateur, jetonC.corps);
  verifier('6. ... LiveKit lui accorde le droit de publier', (await droits(pageC)).canPublish === true);
} finally {
  await navigateur.close();
}
console.log(echecs === 0 ? '\nMICRO-AVANT-ENSEIGNANT : la regle tient sur la pile.' : `\n${echecs} ECHEC(S)`);
process.exit(echecs === 0 ? 0 : 1);
