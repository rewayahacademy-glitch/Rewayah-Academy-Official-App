// Banc de la salle : GESTES-POINTEUR, « Faire reciter » (directeur, 11/11/2026,
// cahier de la salle §8, journal D-014).
//
// La regle : pendant qu'un eleve recite, le SERVEUR ferme le micro de ses
// camarades (droit de publier retire chez LiveKit), et le leur rend a la fin.
// La recitation ne tient que tant que l'enseignant ET le recitant sont dans la
// salle : jamais une classe bloquee muette.
//
// Ce script le prouve sur la pile LOCALE, par les vraies fonctions Edge
// (`salle-gestes`, `create-room-token`, `livekit-webhook`) et le vrai serveur
// LiveKit, avec des participants legers (une page nue et la bibliotheque web
// de LiveKit, comme `micro_avant_enseignant.mjs`) :
//
//   1. l'enseignant et deux eleves entrent, micros ouverts ;
//   2. un eleve ne peut pas lancer une recitation (la base refuse) ;
//   3. « Faire reciter A » : le serveur depublie le micro de B et lui retire
//      le droit de publier ; A garde le sien ; rouvrir le micro de B ECHOUE ;
//   4. le filet demande par B (comme le ferait un client modifie) ne lui rend
//      rien ;
//   5. C entre pendant la recitation : le serveur le ferme a son tour ;
//   6. « Terminer la recitation » : B et C retrouvent leur droit, micros
//      fermes (rien n'est rouvert a leur place), et B rouvre le sien ;
//   7. le recitant quitte la salle : la recitation se termine d'elle-meme ;
//   8. l'enseignant quitte la salle : la recitation se termine d'elle-meme ;
//   9. « Terminer » sans recitation en cours ne fait rien.
//
// Prerequis : `tool/e2e/pile.sh` lancee AVEC les fonctions de cette branche
// (salle-gestes, livekit-webhook, _shared/). Rien n'ecrit hors de la machine.
//
//   node tool/salle/gestes.mjs
//
// `SANS_WEBHOOK=1` : le webhook de LiveKit est coupe ; les etapes 5, 7 et 8
// passent alors par le filet (l'appel que l'application de l'eleve refait
// seule toutes les quinze secondes au plus), que le script declenche lui-meme.
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

const jetons = new Map();
async function jetonSupabase(courriel) {
  if (jetons.has(courriel)) return jetons.get(courriel);
  const session = await (await fetch(`${API}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: CLE, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP }),
  })).json();
  if (!session.access_token) throw new Error(`connexion refusee pour ${courriel}`);
  jetons.set(courriel, session.access_token);
  return session.access_token;
}

/// Appelle la fonction Edge [fonction] avec le compte [courriel], comme l'application.
async function appeler(fonction, courriel, corps) {
  const r = await fetch(`${API}/functions/v1/${fonction}`, {
    method: 'POST',
    headers: { apikey: CLE, Authorization: `Bearer ${await jetonSupabase(courriel)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(corps),
  });
  let lu = null;
  try { lu = await r.json(); } catch { /* corps vide */ }
  return { statut: r.status, corps: lu };
}
const jeton = (courriel, seance) => appeler('create-room-token', courriel, { session_id: seance });
const filet = (courriel, seance) => appeler('create-room-token', courriel, { session_id: seance, action: 'retablir_publication' });
const geste = (courriel, seance, nom, eleve) =>
  appeler('salle-gestes', courriel, { session_id: seance, geste: nom, ...(eleve ? { eleve_id: eleve } : {}) });

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
    await salle.connect(a.ws_url, a.token);
  }, acces);
  return page;
}

const droits = (page) => page.evaluate(() => {
  const p = window.__salle.localParticipant.permissions;
  return { canPublish: p?.canPublish ?? null, sources: p?.canPublishSources ?? [] };
});
const microPublie = (page) => page.evaluate(() =>
  [...window.__salle.localParticipant.trackPublications.values()].filter((p) => p.kind === 'audio' && p.trackSid).length > 0);
const metadonneesSalle = (page) => page.evaluate(() => window.__salle.metadata ?? '');

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

/// Attend que le droit de publier de [page] vaille [voulu] (au plus [ms]).
async function attendreDroit(page, voulu, ms = 8000) {
  const debut = Date.now();
  while (Date.now() - debut < ms) {
    if ((await droits(page)).canPublish === voulu) return Date.now() - debut;
    await attendre(200);
  }
  return null;
}

const classe = amorcerClasse({ n: 3, etiquette: 'gestes-recitation' });
const [a, b, c] = classe.eleves;
const seance = classe.seance;
const navigateur = await chromium.launch({
  args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream', '--autoplay-policy=no-user-gesture-required'],
});

try {
  // 1. L'enseignant et deux eleves entrent, micros ouverts.
  let pageEns = await entrer(navigateur, (await jeton(COMPTES.enseignant, seance)).corps);
  let pageA = await entrer(navigateur, (await jeton(a.courriel, seance)).corps);
  const pageB = await entrer(navigateur, (await jeton(b.courriel, seance)).corps);
  verifier('1. A et B ont le droit de publier', (await attendreDroit(pageA, true)) !== null && (await attendreDroit(pageB, true)) !== null);
  verifier('1. A et B ouvrent leur micro', (await ouvrirMicro(pageA)).ouvert && (await ouvrirMicro(pageB)).ouvert);

  // 2. Un eleve ne peut pas lancer une recitation.
  const parEleve = await geste(b.courriel, seance, 'faire_reciter', a.id);
  verifier('2. un eleve qui demande « Faire reciter » est refuse par la base', parEleve.statut === 403, parEleve);
  verifier('2. ... et rien n\'a change pour A', (await droits(pageA)).canPublish === true);

  // 3. « Faire reciter A ».
  const ouverture = await geste(COMPTES.enseignant, seance, 'faire_reciter', a.id);
  verifier('3. l\'enseignant fait reciter A : le serveur l\'applique',
    ouverture.statut === 200 && ouverture.corps?.applique === true && ouverture.corps?.fermes === 1, ouverture);
  const delaiB = await attendreDroit(pageB, false);
  verifier('3. LiveKit retire a B le droit de publier', delaiB !== null, { ms: delaiB, droits: await droits(pageB) });
  await attendre(500);
  verifier('3. le micro de B est depublie par le serveur', (await microPublie(pageB)) === false);
  const essaiB = await ouvrirMicro(pageB);
  verifier('3. rouvrir le micro de B ECHOUE (refuse par le serveur)', essaiB.ouvert === false, essaiB);
  verifier('3. A garde son droit et son micro', (await droits(pageA)).canPublish === true && (await microPublie(pageA)) === true);
  verifier('3. l\'enseignant garde son droit', (await droits(pageEns)).canPublish === true);
  const meta = await metadonneesSalle(pageEns);
  verifier('3. la salle porte la recitation (ecrite par le serveur)', meta.includes(a.id), meta);

  // 4. Le filet de B ne lui rend rien.
  const filetB = await filet(b.courriel, seance);
  verifier('4. le filet demande par B ne rend rien pendant la recitation',
    filetB.statut === 200 && filetB.corps?.retabli === false && filetB.corps?.publication_differee === true, filetB);
  verifier('4. ... et son droit reste ferme chez LiveKit', (await droits(pageB)).canPublish === false);

  // 5. C entre pendant la recitation.
  const jetonC = await jeton(c.courriel, seance);
  const pageC = await entrer(navigateur, jetonC.corps);
  if (SANS_WEBHOOK) await filet(b.courriel, seance);
  const delaiC = await attendreDroit(pageC, false);
  verifier(`5. C, entre pendant la recitation, est ferme a son tour (${SANS_WEBHOOK ? 'filet' : 'webhook'})`,
    delaiC !== null, { ms: delaiC });
  verifier('5. ... et son micro ne s\'ouvre pas', (await ouvrirMicro(pageC)).ouvert === false);

  // 6. « Terminer la recitation ».
  const fin = await geste(COMPTES.enseignant, seance, 'terminer_recitation', a.id);
  verifier('6. l\'enseignant termine : le serveur rend les droits',
    fin.statut === 200 && fin.corps?.applique === true && fin.corps?.rendus === 2, fin);
  verifier('6. B et C retrouvent le droit de publier',
    (await attendreDroit(pageB, true)) !== null && (await attendreDroit(pageC, true)) !== null);
  verifier('6. leurs micros restent fermes : rien n\'est rouvert a leur place',
    (await microPublie(pageB)) === false && (await microPublie(pageC)) === false);
  verifier('6. B rouvre son micro lui-meme', (await ouvrirMicro(pageB)).ouvert === true);
  verifier('6. la salle ne porte plus de recitation', !(await metadonneesSalle(pageEns)).includes(a.id));

  // 7. Le recitant quitte la salle.
  const r7 = await geste(COMPTES.enseignant, seance, 'faire_reciter', a.id);
  verifier('7. nouvelle recitation de A', r7.corps?.applique === true && (await attendreDroit(pageB, false)) !== null, r7);
  await pageA.evaluate(() => window.__salle.disconnect());
  if (SANS_WEBHOOK) { await attendre(1500); await filet(b.courriel, seance); }
  const retour7 = await attendreDroit(pageB, true, 15000);
  verifier(`7. A quitte la salle : B retrouve son droit sans geste de l'enseignant (${SANS_WEBHOOK ? 'filet' : 'webhook de sortie'})`,
    retour7 !== null, { ms: retour7 });
  verifier('7. ... C aussi', (await attendreDroit(pageC, true)) !== null);

  // 8. L'enseignant quitte la salle.
  const r8 = await geste(COMPTES.enseignant, seance, 'faire_reciter', b.id);
  verifier('8. recitation de B', r8.corps?.applique === true && (await attendreDroit(pageC, false)) !== null, r8);
  await pageEns.evaluate(() => window.__salle.disconnect());
  if (SANS_WEBHOOK) { await attendre(1500); await filet(c.courriel, seance); }
  const retour8 = await attendreDroit(pageC, true, 15000);
  verifier(`8. l'enseignant quitte la salle : C retrouve son droit (${SANS_WEBHOOK ? 'filet' : 'webhook de sortie'})`,
    retour8 !== null, { ms: retour8 });

  // 9. « Terminer » sans recitation en cours.
  pageEns = await entrer(navigateur, (await jeton(COMPTES.enseignant, seance)).corps);
  const rien = await geste(COMPTES.enseignant, seance, 'terminer_recitation');
  verifier('9. « Terminer » sans recitation en cours ne fait rien',
    rien.statut === 200 && rien.corps?.applique === false, rien);
  const absent = await geste(COMPTES.enseignant, seance, 'faire_reciter', a.id);
  verifier('9. faire reciter un eleve sorti de la salle est refuse, sans rien fermer',
    absent.statut === 200 && absent.corps?.applique === false && absent.corps?.motif === 'recitant_absent', absent);
  verifier('9. ... B et C gardent leur droit', (await droits(pageB)).canPublish === true && (await droits(pageC)).canPublish === true);
} finally {
  await navigateur.close();
}
console.log(echecs === 0 ? '\nGESTES, recitation : la regle tient sur la pile.' : `\n${echecs} ECHEC(S)`);
process.exit(echecs === 0 ? 0 : 1);
