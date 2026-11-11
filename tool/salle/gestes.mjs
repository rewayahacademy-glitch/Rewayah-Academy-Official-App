// Banc de la salle : GESTES-POINTEUR, « Faire reciter » (directeur, 11/11/2026,
// cahier de la salle §8, journal D-014), et RECITATION-MICRO-SEUL (directeur,
// 11/11/2026, journal D-022).
//
// La regle : pendant qu'un eleve recite, le SERVEUR ferme le MICRO de ses
// camarades (droit retire chez LiveKit), et le leur rend a la fin. **Leur
// camera reste** (D-022), si leur propre jeton la leur donne ; un eleve dont
// le profil interdit la camera n'en gagne jamais une. La recitation ne tient
// que tant que l'enseignant ET le recitant sont dans la salle : jamais une
// classe bloquee muette.
//
// Ce script le prouve sur la pile LOCALE, par les vraies fonctions Edge
// (`salle-gestes`, `create-room-token`, `livekit-webhook`) et le vrai serveur
// LiveKit, avec des participants legers (une page nue et la bibliotheque web
// de LiveKit, comme `micro_avant_enseignant.mjs`) :
//
//   1. l'enseignant et trois eleves entrent, micros ouverts : A (le
//      recitant), B (camera permise, allumee) et D (camera interdite par son
//      profil) ;
//   2. un eleve ne peut pas lancer une recitation (la base refuse) ;
//   3. « Faire reciter A » :
//        - B : le serveur depublie son micro et le lui interdit ; sa camera
//          reste publiee (la MEME piste, jamais coupee) ; un micro force par
//          un client modifie est refuse par le SERVEUR ; une camera neuve est
//          acceptee ;
//        - D : ni micro ni camera, meme forces ;
//        - A et l'enseignant ne perdent rien ;
//   4. le filet demande par B (comme le ferait un client modifie) ne lui rend
//      rien ;
//   5. C entre pendant la recitation : son micro est ferme a son tour, sa
//      camera s'ouvre ;
//   6. « Terminer la recitation » : B, C et D retrouvent exactement les droits
//      de leur jeton (D : le micro, toujours sans camera), micros fermes (rien
//      n'est rouvert a leur place), et B rouvre le sien ;
//   7. le recitant quitte la salle : la recitation se termine d'elle-meme ;
//   8. l'enseignant quitte la salle : la recitation se termine d'elle-meme ;
//   9. « Terminer » sans recitation en cours ne fait rien.
//
// « Refuse par le SERVEUR » : la bibliotheque web de LiveKit refuse d'elle-meme
// de publier sans le droit. Pour prouver que la regle ne tient pas a l'ecran,
// le script retire ce controle local (`hasPermissionsToPublish`), comme le
// ferait un client modifie, et regarde ce que l'ENSEIGNANT recoit : c'est le
// serveur qui decide de ce qui est relaye.
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
import { APP, API, MDP, TRAVAIL, COMPTES, sql } from '../e2e/commun.mjs';
import { amorcerClasse } from './amorce.mjs';

const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');
const LIVEKIT_WEB = '/opt/node-tools/node_modules/livekit-client/dist/livekit-client.umd.js';
const CLE = fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8').match(/^PUBLISHABLE_KEY="?([^"\n]+)/m)[1];
const SANS_WEBHOOK = process.env.SANS_WEBHOOK === '1';

let echecs = 0;
let controles = 0;
function verifier(nom, ok, detail) {
  controles++;
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

/// Les sources du protocole LiveKit (`TrackSource`) : CAMERA = 1, MICROPHONE = 2.
const SRC_CAMERA = 1;
const SRC_MICRO = 2;

/// Les droits que LiveKit accorde a [page], tels que le serveur les annonce.
const droits = (page) => page.evaluate(() => {
  const p = window.__salle.localParticipant.permissions;
  return { canPublish: p?.canPublish ?? null, sources: [...(p?.canPublishSources ?? [])] };
});
/// Une liste de sources vide veut dire « toutes » (regle de LiveKit).
const microPermis = (d) => d.canPublish === true && (d.sources.length === 0 || d.sources.includes(SRC_MICRO));
const cameraPermise = (d) => d.canPublish === true && (d.sources.length === 0 || d.sources.includes(SRC_CAMERA));

/// Les pistes que [page] publie : l'identifiant de piste donne par le serveur, ou null.
const pistes = (page) => page.evaluate(() => {
  const pubs = [...window.__salle.localParticipant.trackPublications.values()].filter((p) => p.trackSid);
  return {
    micro: pubs.find((p) => p.source === 'microphone')?.trackSid ?? null,
    camera: pubs.find((p) => p.source === 'camera')?.trackSid ?? null,
  };
});
const microPublie = async (page) => (await pistes(page)).micro !== null;
const metadonneesSalle = (page) => page.evaluate(() => window.__salle.metadata ?? '');

/// Ce que [page] RECOIT du participant [identite] : c'est le serveur qui
/// decide de ce qu'il relaye. null : il n'est pas dans la salle.
const recuDe = (page, identite) => page.evaluate((id) => {
  const p = window.__salle.remoteParticipants.get(id);
  if (!p) return null;
  const pubs = [...p.trackPublications.values()];
  return {
    micro: pubs.filter((x) => x.source === 'microphone').length,
    camera: pubs.filter((x) => x.source === 'camera').length,
  };
}, identite);

/// Tente d'ouvrir le micro ou la camera ; rend { ouvert, erreur }.
/// [force] : le controle local de la bibliotheque est retire, comme dans un
/// client modifie ; seul le serveur peut encore refuser (il ne repond pas a la
/// demande de piste, la bibliotheque abandonne apres dix secondes).
const ouvrir = (page, source, force = false) => page.evaluate(async ({ source, force }) => {
  const local = window.__salle.localParticipant;
  if (force) local.hasPermissionsToPublish = () => true;
  let erreur = null;
  try {
    await Promise.race([
      source === 'camera' ? local.setCameraEnabled(true) : local.setMicrophoneEnabled(true),
      new Promise((_, ko) => setTimeout(() => ko(new Error('aucune reponse du serveur en 20 s')), 20000)),
    ]);
  } catch (e) { erreur = String(e?.message ?? e); }
  const pubs = [...local.trackPublications.values()].filter((p) => p.source === source && p.trackSid);
  return { ouvert: pubs.length > 0, erreur };
}, { source, force });
const ouvrirMicro = (page, force = false) => ouvrir(page, 'microphone', force);
const ouvrirCamera = (page, force = false) => ouvrir(page, 'camera', force);

/// Retire la piste de camera de [page] (depublication complete, pas une simple coupure).
const retirerCamera = (page) => page.evaluate(async () => {
  const local = window.__salle.localParticipant;
  for (const p of [...local.trackPublications.values()]) {
    if (p.source === 'camera' && p.track) await local.unpublishTrack(p.track);
  }
});

/// Attend que le MICRO de [page] soit permis ([voulu] vrai) ou interdit (au plus [ms]).
async function attendreMicro(page, voulu, ms = 8000) {
  const debut = Date.now();
  while (Date.now() - debut < ms) {
    if (microPermis(await droits(page)) === voulu) return Date.now() - debut;
    await attendre(200);
  }
  return null;
}

const classe = amorcerClasse({ n: 4, etiquette: 'gestes-recitation' });
const [a, b, c, d] = classe.eleves;
const seance = classe.seance;
// D : la camera est interdite par son profil (`camera_policy`), base LOCALE.
sql(`update public.student_profiles set camera_policy = 'forbidden' where profile_id = '${d.id}'`);
const navigateur = await chromium.launch({
  args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream', '--autoplay-policy=no-user-gesture-required'],
});

try {
  // 1. L'enseignant et trois eleves entrent, micros ouverts.
  let pageEns = await entrer(navigateur, (await jeton(COMPTES.enseignant, seance)).corps);
  let pageA = await entrer(navigateur, (await jeton(a.courriel, seance)).corps);
  const pageB = await entrer(navigateur, (await jeton(b.courriel, seance)).corps);
  const pageD = await entrer(navigateur, (await jeton(d.courriel, seance)).corps);
  verifier('1. A, B et D ont le droit de publier leur micro',
    (await attendreMicro(pageA, true)) !== null && (await attendreMicro(pageB, true)) !== null &&
    (await attendreMicro(pageD, true)) !== null);
  verifier('1. A, B et D ouvrent leur micro',
    (await ouvrirMicro(pageA)).ouvert && (await ouvrirMicro(pageB)).ouvert && (await ouvrirMicro(pageD)).ouvert);
  const droitsD1 = await droits(pageD);
  verifier('1. D (camera interdite par son profil) : son jeton ne donne que le micro',
    microPermis(droitsD1) && !cameraPermise(droitsD1), droitsD1);
  verifier('1. B allume sa camera', (await ouvrirCamera(pageB)).ouvert === true);
  const cameraB1 = (await pistes(pageB)).camera;
  await attendre(500);
  verifier('1. l\'enseignant recoit le micro et la camera de B',
    JSON.stringify(await recuDe(pageEns, b.id)) === JSON.stringify({ micro: 1, camera: 1 }), await recuDe(pageEns, b.id));

  // 2. Un eleve ne peut pas lancer une recitation.
  const parEleve = await geste(b.courriel, seance, 'faire_reciter', a.id);
  verifier('2. un eleve qui demande « Faire reciter » est refuse par la base', parEleve.statut === 403, parEleve);
  verifier('2. ... et rien n\'a change pour A', microPermis(await droits(pageA)));

  // 3. « Faire reciter A ».
  const ouverture = await geste(COMPTES.enseignant, seance, 'faire_reciter', a.id);
  verifier('3. l\'enseignant fait reciter A : le serveur l\'applique a B et a D',
    ouverture.statut === 200 && ouverture.corps?.applique === true && ouverture.corps?.fermes === 2 &&
    ouverture.corps?.echecs === 0, ouverture);
  const delaiB = await attendreMicro(pageB, false);
  const droitsB3 = await droits(pageB);
  verifier('3. LiveKit retire a B le droit de publier son MICRO', delaiB !== null, { ms: delaiB, droits: droitsB3 });
  verifier('3. ... et lui laisse le droit de publier sa CAMERA, elle seule',
    droitsB3.canPublish === true && JSON.stringify(droitsB3.sources) === JSON.stringify([SRC_CAMERA]), droitsB3);
  await attendre(800);
  const pistesB3 = await pistes(pageB);
  verifier('3. le micro de B est depublie par le serveur', pistesB3.micro === null, pistesB3);
  verifier('3. la camera de B reste publiee : la meme piste, jamais coupee',
    pistesB3.camera !== null && pistesB3.camera === cameraB1, { avant: cameraB1, pendant: pistesB3.camera });
  verifier('3. l\'enseignant ne recoit plus le micro de B, et recoit toujours sa camera',
    JSON.stringify(await recuDe(pageEns, b.id)) === JSON.stringify({ micro: 0, camera: 1 }), await recuDe(pageEns, b.id));
  const essaiB = await ouvrirMicro(pageB);
  verifier('3. rouvrir le micro de B ECHOUE (application ordinaire)', essaiB.ouvert === false, essaiB);
  const forceB = await ouvrirMicro(pageB, true);
  await attendre(500);
  const recuB3 = await recuDe(pageEns, b.id);
  verifier('3. un micro force par un client modifie est refuse par le SERVEUR : l\'enseignant ne recoit rien',
    forceB.ouvert === false && recuB3?.micro === 0, { essai: forceB, recuParEnseignant: recuB3 });
  await retirerCamera(pageB);
  await attendre(500);
  const neuveB = await ouvrirCamera(pageB);
  await attendre(500);
  const recuB3b = await recuDe(pageEns, b.id);
  verifier('3. une camera NEUVE de B est acceptee par le serveur pendant la recitation',
    neuveB.ouvert === true && recuB3b?.camera === 1 && recuB3b?.micro === 0, { essai: neuveB, recuParEnseignant: recuB3b });

  const delaiD = await attendreMicro(pageD, false);
  const droitsD3 = await droits(pageD);
  verifier('3. D (camera interdite) : LiveKit lui retire tout droit de publier',
    delaiD !== null && droitsD3.canPublish === false, droitsD3);
  verifier('3. le micro de D est depublie par le serveur', (await microPublie(pageD)) === false);
  const forceMicroD = await ouvrirMicro(pageD, true);
  const forceCameraD = await ouvrirCamera(pageD, true);
  await attendre(500);
  const recuD3 = await recuDe(pageEns, d.id);
  verifier('3. D ne gagne ni micro ni camera, meme forces par un client modifie',
    forceMicroD.ouvert === false && forceCameraD.ouvert === false && recuD3?.micro === 0 && recuD3?.camera === 0,
    { micro: forceMicroD, camera: forceCameraD, recuParEnseignant: recuD3 });

  verifier('3. A garde son droit et son micro', microPermis(await droits(pageA)) && (await microPublie(pageA)) === true);
  verifier('3. l\'enseignant garde son droit', microPermis(await droits(pageEns)));
  const meta = await metadonneesSalle(pageEns);
  verifier('3. la salle porte la recitation (ecrite par le serveur)', meta.includes(a.id), meta);

  // 4. Le filet de B ne lui rend rien.
  const filetB = await filet(b.courriel, seance);
  verifier('4. le filet demande par B ne rend rien pendant la recitation',
    filetB.statut === 200 && filetB.corps?.retabli === false && filetB.corps?.publication_differee === true, filetB);
  const droitsB4 = await droits(pageB);
  verifier('4. ... son micro reste interdit chez LiveKit, sa camera permise',
    !microPermis(droitsB4) && cameraPermise(droitsB4), droitsB4);

  // B2 (revue du garde-cap) : « Terminer » sans cible, demande par quelqu'un
  // qui ne conduit pas la seance, PENDANT une recitation : refuse avant toute
  // lecture. La meme reponse sera rendue sans recitation (etape 9).
  const intrus4 = await geste(b.courriel, seance, 'terminer_recitation');
  verifier('4. B2 : un eleve demande « Terminer » sans cible pendant la recitation : 403',
    intrus4.statut === 403, intrus4);
  const direction4 = await geste(COMPTES.direction, seance, 'terminer_recitation');
  verifier('4. B2 : un compte hors de la seance aussi : 403', direction4.statut === 403, direction4);
  verifier('4. B2 : ... et la recitation tient toujours : B n\'a pas retrouve son micro',
    !microPermis(await droits(pageB)));

  // 5. C entre pendant la recitation.
  const jetonC = await jeton(c.courriel, seance);
  const pageC = await entrer(navigateur, jetonC.corps);
  if (SANS_WEBHOOK) await filet(b.courriel, seance);
  const delaiC = await attendreMicro(pageC, false);
  const droitsC5 = await droits(pageC);
  verifier(`5. C, entre pendant la recitation, perd son micro a son tour (${SANS_WEBHOOK ? 'filet' : 'webhook'})`,
    delaiC !== null, { ms: delaiC, droits: droitsC5 });
  verifier('5. ... son micro ne s\'ouvre pas, meme force', (await ouvrirMicro(pageC, true)).ouvert === false);
  verifier('5. ... sa camera lui reste permise et s\'ouvre',
    cameraPermise(droitsC5) && (await ouvrirCamera(pageC)).ouvert === true);

  // 6. « Terminer la recitation ».
  const fin = await geste(COMPTES.enseignant, seance, 'terminer_recitation', a.id);
  verifier('6. l\'enseignant termine : le serveur rend les droits a B, C et D',
    fin.statut === 200 && fin.corps?.applique === true && fin.corps?.rendus === 3, fin);
  verifier('6. B, C et D retrouvent le droit de publier leur micro',
    (await attendreMicro(pageB, true)) !== null && (await attendreMicro(pageC, true)) !== null &&
    (await attendreMicro(pageD, true)) !== null);
  const droitsB6 = await droits(pageB);
  const droitsD6 = await droits(pageD);
  verifier('6. B retrouve exactement les droits de son jeton : micro et camera',
    microPermis(droitsB6) && cameraPermise(droitsB6), droitsB6);
  verifier('6. D retrouve exactement les droits de son jeton : le micro, toujours sans camera',
    microPermis(droitsD6) && !cameraPermise(droitsD6), droitsD6);
  await attendre(500);
  verifier('6. leurs micros restent fermes : rien n\'est rouvert a leur place',
    (await microPublie(pageB)) === false && (await microPublie(pageC)) === false && (await microPublie(pageD)) === false);
  verifier('6. la camera de B est toujours publiee', (await pistes(pageB)).camera !== null);
  verifier('6. B rouvre son micro lui-meme', (await ouvrirMicro(pageB)).ouvert === true);
  const forceCameraD6 = await ouvrirCamera(pageD, true);
  verifier('6. la camera de D reste refusee par le serveur apres la recitation', forceCameraD6.ouvert === false, forceCameraD6);
  verifier('6. la salle ne porte plus de recitation', !(await metadonneesSalle(pageEns)).includes(a.id));

  // 7. Le recitant quitte la salle.
  const r7 = await geste(COMPTES.enseignant, seance, 'faire_reciter', a.id);
  verifier('7. nouvelle recitation de A', r7.corps?.applique === true && (await attendreMicro(pageB, false)) !== null, r7);
  await pageA.evaluate(() => window.__salle.disconnect());
  if (SANS_WEBHOOK) { await attendre(1500); await filet(b.courriel, seance); }
  const retour7 = await attendreMicro(pageB, true, 15000);
  verifier(`7. A quitte la salle : B retrouve son micro sans geste de l'enseignant (${SANS_WEBHOOK ? 'filet' : 'webhook de sortie'})`,
    retour7 !== null, { ms: retour7 });
  verifier('7. ... C aussi', (await attendreMicro(pageC, true)) !== null);

  // 8. L'enseignant quitte la salle.
  const r8 = await geste(COMPTES.enseignant, seance, 'faire_reciter', b.id);
  verifier('8. recitation de B', r8.corps?.applique === true && (await attendreMicro(pageC, false)) !== null, r8);
  await pageEns.evaluate(() => window.__salle.disconnect());
  if (SANS_WEBHOOK) { await attendre(1500); await filet(c.courriel, seance); }
  const retour8 = await attendreMicro(pageC, true, 15000);
  verifier(`8. l'enseignant quitte la salle : C retrouve son micro (${SANS_WEBHOOK ? 'filet' : 'webhook de sortie'})`,
    retour8 !== null, { ms: retour8 });

  // 9. « Terminer » sans recitation en cours.
  pageEns = await entrer(navigateur, (await jeton(COMPTES.enseignant, seance)).corps);
  const rien = await geste(COMPTES.enseignant, seance, 'terminer_recitation');
  verifier('9. « Terminer » sans recitation en cours ne fait rien',
    rien.statut === 200 && rien.corps?.applique === false, rien);
  const intrus9 = await geste(b.courriel, seance, 'terminer_recitation');
  const direction9 = await geste(COMPTES.direction, seance, 'terminer_recitation');
  verifier('9. B2 : sans recitation, la meme reponse qu\'avec pour qui ne conduit pas la seance (403, meme corps)',
    intrus9.statut === 403 && direction9.statut === 403 &&
    JSON.stringify(intrus9.corps) === JSON.stringify(intrus4.corps) &&
    JSON.stringify(direction9.corps) === JSON.stringify(direction4.corps), { intrus9, direction9 });
  const absent = await geste(COMPTES.enseignant, seance, 'faire_reciter', a.id);
  verifier('9. faire reciter un eleve sorti de la salle est refuse, sans rien fermer',
    absent.statut === 200 && absent.corps?.applique === false && absent.corps?.motif === 'recitant_absent', absent);
  verifier('9. ... B et C gardent leur micro', microPermis(await droits(pageB)) && microPermis(await droits(pageC)));
} finally {
  await navigateur.close();
}
console.log(echecs === 0
  ? `\nGESTES, recitation : la regle tient sur la pile (${controles} controles sur ${controles}).`
  : `\n${echecs} ECHEC(S) sur ${controles} controles`);
process.exit(echecs === 0 ? 0 : 1);
