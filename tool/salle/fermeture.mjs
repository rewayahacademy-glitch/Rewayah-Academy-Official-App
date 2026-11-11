// Banc de la salle : FERMETURE-SALLE (directeur, 11/11/2026, seconde moitie du
// defaut SEC-1, journal D-018).
//
// La regle : des enfants ne se parlent pas, micro ouvert, sans adulte. Apres
// le depart de l'enseignant et un delai de grace, le SERVEUR retire aux eleves
// le droit de publier ; a son retour, il le rend. Quand la seance est finie et
// que l'enseignant n'est plus la, le serveur ferme la salle pour tous. Un
// cours qui se tient encore n'est jamais coupe.
//
// Ce script le prouve sur la pile LOCALE, par les vraies fonctions Edge et le
// vrai serveur LiveKit, avec des participants legers (une page nue et la
// bibliotheque web de LiveKit, comme `micro_avant_enseignant.mjs`) :
//
//   Seance 1 (deux eleves A et B, puis C)
//   1. l'enseignant, A et B entrent ; A ouvre son micro ;
//   2. coupure courte : l'enseignant sort et revient avant le delai. Rien
//      n'est retire, le serveur a seulement note l'instant, puis l'efface ;
//   3. il sort pour de bon. Pendant le delai : micros intacts. Le delai
//      passe : B demande la verification (`create-room-token`, action
//      `verifier_salle`) ; le serveur ferme A ET B (un seul client honnete
//      suffit), depublie le micro de A, refuse de le rouvrir ; C, qui prend
//      son jeton a ce moment, est differe ;
//   4. l'enseignant revient : le droit est rendu (webhook), A rouvre son micro ;
//   5. il ressort ; AUCUN client ne demande rien. Le delai passe, puis le
//      passage de la tache planifiee (`fermeture_passage.ts`, le code de
//      `observation-coupure`) ferme les micros ;
//   6. la fin prevue et le depassement sont passes (heures de la seance
//      reculees en base), l'enseignant toujours absent : le passage ferme la
//      salle ; A et B sont deconnectes avec la raison « salle supprimee ».
//
//   Seance 2 (un eleve D) : un cours qui deborde n'est pas coupe
//   7. l'enseignant et D sont en salle, le depassement est passe : la
//      verification ne ferme rien ;
//   8. la seance est close en base par la cloture automatique : la
//      verification ne ferme toujours rien tant que l'enseignant est la ;
//   9. l'enseignant sort : le webhook ferme la salle, D est deconnecte.
//
// Prerequis : `tool/e2e/pile.sh` lancee AVEC les fonctions de cette branche
// (create-room-token, livekit-webhook, _shared/). Rien n'ecrit hors de la
// machine. Le script attend deux fois le vrai delai du serveur (deux minutes
// chacune) : compter cinq a six minutes. Usage :
//
//   node tool/salle/fermeture.mjs
//
// `DENO=<chemin>` : le binaire Deno pour les etapes 5 et 6 (defaut : `deno`).
// Sans Deno, ces deux etapes passent par la demande d'un eleve, et le script
// dit que le passage planifie n'a pas ete essaye.
// Comme les autres bancs de la salle, l'amorce retire d'abord les anciennes
// classes E2E (deux classes du meme enseignant a la meme heure se refusent) :
// ne pas le lancer pendant qu'un autre banc tourne sur la meme pile.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { APP, API, MDP, TRAVAIL, COMPTES, DEPOT, sql } from '../e2e/commun.mjs';
import { amorcerClasse } from './amorce.mjs';

const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');
const LIVEKIT_WEB = '/opt/node-tools/node_modules/livekit-client/dist/livekit-client.umd.js';
const lireEnv = (fichier, nom) =>
  fs.readFileSync(path.join(TRAVAIL, fichier), 'utf8').match(new RegExp(`^${nom}="?([^"\\n]+)`, 'm'))?.[1];
const CLE = lireEnv('statut.env', 'PUBLISHABLE_KEY');

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
    window.__deconnexion = null;
    salle.on(lk.RoomEvent.TrackSubscribed, (piste, _pub, qui) => {
      if (piste.kind === 'audio') window.__voixRecues.push(qui.identity);
    });
    salle.on(lk.RoomEvent.Disconnected, (raison) => {
      window.__deconnexion = { raison: raison ?? null, nom: lk.DisconnectReason[raison] ?? null };
    });
    await salle.connect(a.ws_url, a.token);
  }, acces);
  return page;
}

/// Sort de la salle comme l'application (deconnexion voulue), puis ferme la page.
async function sortir(page) {
  await page.evaluate(() => window.__salle.disconnect());
  await page.context().close();
}

const droits = (page) => page.evaluate(() => {
  const p = window.__salle.localParticipant.permissions;
  return { canPublish: p?.canPublish ?? null, sources: p?.canPublishSources ?? [] };
});

const microPublie = (page) => page.evaluate(() =>
  [...window.__salle.localParticipant.trackPublications.values()].some((p) => p.kind === 'audio' && p.trackSid));

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
async function attendreDroit(page, voulu, ms) {
  const debut = Date.now();
  while (Date.now() - debut < ms) {
    if ((await droits(page)).canPublish === voulu) return Date.now() - debut;
    await attendre(200);
  }
  return null;
}

/// Attend que [page] soit deconnectee par le serveur (au plus [ms]).
async function attendreDeconnexion(page, ms) {
  const debut = Date.now();
  while (Date.now() - debut < ms) {
    const d = await page.evaluate(() => window.__deconnexion);
    if (d) return d;
    await attendre(200);
  }
  return null;
}

/// Le passage de la tache planifiee sur [salle], par le code de la fonction
/// `observation-coupure` (voir `fermeture_passage.ts`). `null` sans Deno.
function passagePlanifie(salle) {
  const deno = process.env.DENO ?? 'deno';
  const r = spawnSync(deno, ['run', '-A', path.join(DEPOT, 'tool/salle/fermeture_passage.ts'), salle], {
    encoding: 'utf8',
    env: {
      ...process.env,
      SUPABASE_URL: API,
      SUPABASE_SERVICE_ROLE_KEY: lireEnv('statut.env', 'SERVICE_ROLE_KEY'),
      LIVEKIT_CLOUD_API_KEY: lireEnv('fonctions.env', 'LIVEKIT_CLOUD_API_KEY'),
      LIVEKIT_CLOUD_API_SECRET: lireEnv('fonctions.env', 'LIVEKIT_CLOUD_API_SECRET'),
    },
  });
  if (r.error || r.status !== 0) {
    console.log(`     (passage planifie non lance : ${r.error?.message ?? r.stderr?.trim().split('\n').pop()})`);
    return null;
  }
  return JSON.parse(r.stdout.trim().split('\n').pop());
}

/// Recule les heures de la seance : sa fin prevue est passee de [minutes].
function finirDepuis(seance, minutes) {
  sql(`update public.sessions
          set started_at = now() - interval '${minutes + 60} minutes',
              ended_at = now() - interval '${minutes} minutes'
        where id = '${seance}'`);
}

const navigateur = await chromium.launch({
  args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream', '--autoplay-policy=no-user-gesture-required'],
});

try {
  // ------------------------------------------------------------------ Seance 1
  const classe = amorcerClasse({ n: 3, etiquette: `fermeture-${Date.now() % 100000}` });
  const [a, b, c] = classe.eleves;
  const verifierSalle = (courriel) => demander(courriel, { session_id: classe.seance, action: 'verifier_salle' });

  // 1. L'enseignant, A et B entrent ; A ouvre son micro.
  let jetonEns = await demander(COMPTES.enseignant, { session_id: classe.seance });
  let pageEns = await entrer(navigateur, jetonEns.corps);
  const salle1 = jetonEns.corps.room_name;
  await attendre(1500);
  const jetonA = await demander(a.courriel, { session_id: classe.seance });
  const jetonB = await demander(b.courriel, { session_id: classe.seance });
  verifier('1. enseignant present : les eleves ont leurs droits ordinaires',
    jetonA.corps.publication_differee === false && jetonB.corps.publication_differee === false);
  const pageA = await entrer(navigateur, jetonA.corps);
  const pageB = await entrer(navigateur, jetonB.corps);
  verifier('1. A ouvre son micro', (await ouvrirMicro(pageA)).ouvert === true);

  // 2. Coupure courte de l'enseignant.
  await sortir(pageEns);
  await attendre(3000);
  const court = await verifierSalle(a.courriel);
  verifier('2. l\'enseignant vient de sortir : rien n\'est ferme, le delai court',
    court.statut === 200 && court.corps.salle === 'ouverte' && court.corps.micros_fermes === 0 &&
    court.corps.reste_s > 60, court);
  verifier('2. ... le droit et le micro de A sont intacts',
    (await droits(pageA)).canPublish === true && (await microPublie(pageA)) === true);
  jetonEns = await demander(COMPTES.enseignant, { session_id: classe.seance });
  pageEns = await entrer(navigateur, jetonEns.corps);
  await attendre(3000);
  const revenu = await verifierSalle(a.courriel);
  verifier('2. il revient avant le delai : la marque est levee, rien n\'a ete retire',
    revenu.statut === 200 && revenu.corps.reste_s === null && revenu.corps.micros_fermes === 0 &&
    (await droits(pageA)).canPublish === true && (await microPublie(pageA)) === true, revenu);

  // 3. Il sort pour de bon.
  await sortir(pageEns);
  await attendre(3000);
  const debut = await verifierSalle(a.courriel);
  verifier('3. depart de l\'enseignant : le delai repart de zero', debut.corps.reste_s > 100, debut);
  const delai = debut.corps.reste_s;
  await attendre(Math.max(0, (delai - 20) * 1000));
  const presque = await verifierSalle(a.courriel);
  verifier('3. juste avant l\'echeance : micros toujours ouverts',
    presque.corps.micros_fermes === 0 && presque.corps.reste_s > 0 &&
    (await droits(pageA)).canPublish === true && (await microPublie(pageA)) === true, presque);
  await attendre((presque.corps.reste_s + 1) * 1000);
  const echu = await verifierSalle(b.courriel);
  verifier('3. le delai est passe : a la demande de B, le serveur ferme A ET B',
    echu.statut === 200 && echu.corps.micros_fermes === 2 && echu.corps.salle === 'ouverte', echu);
  verifier('3. LiveKit retire a A le droit de publier', (await attendreDroit(pageA, false, 5000)) !== null);
  verifier('3. ... et a B, qui n\'avait pas de micro ouvert', (await droits(pageB)).canPublish === false);
  await attendre(1500);
  verifier('3. le micro de A est depublie par le serveur', (await microPublie(pageA)) === false);
  const essai = await ouvrirMicro(pageA);
  verifier('3. rouvrir le micro ECHOUE (refuse par le serveur)', essai.ouvert === false, essai);
  const jetonC = await demander(c.courriel, { session_id: classe.seance });
  verifier('3. un eleve qui prend son jeton sans enseignant est differe', jetonC.corps.publication_differee === true);
  const encore = await verifierSalle(a.courriel);
  verifier('3. redemander ne change rien (la decision lit l\'etat)',
    encore.corps.micros_fermes === 0 && (await droits(pageA)).canPublish === false, encore);

  // 4. L'enseignant revient.
  jetonEns = await demander(COMPTES.enseignant, { session_id: classe.seance });
  pageEns = await entrer(navigateur, jetonEns.corps);
  verifier('4. retour de l\'enseignant : le droit est rendu a A', (await attendreDroit(pageA, true, 8000)) !== null);
  verifier('4. ... et a B', (await attendreDroit(pageB, true, 8000)) !== null);
  verifier('4. A rouvre son micro', (await ouvrirMicro(pageA)).ouvert === true);
  await attendre(2500);
  verifier('4. l\'enseignant recoit sa voix',
    (await pageEns.evaluate(() => window.__voixRecues)).includes(a.id));

  // 5. Il ressort ; aucun client ne demande rien ; la tache planifiee passe.
  await sortir(pageEns);
  await attendre(3000);
  const avant = passagePlanifie(salle1);
  const planifie = avant !== null;
  if (planifie) {
    verifier('5. passage planifie pendant le delai : rien n\'est ferme',
      avant.retenues === 1 && avant.examinees === 1 && avant.microsFermes === 0 && avant.sallesFermees === 0 &&
      (await droits(pageA)).canPublish === true, avant);
    await attendre((delai + 2) * 1000);
    const apres = passagePlanifie(salle1);
    verifier('5. passage planifie apres le delai : les micros sont fermes, sans aucune demande d\'un client',
      apres?.microsFermes === 1 && apres?.sallesFermees === 0, apres);
  } else {
    console.log('NON ESSAYE 5. le passage planifie (Deno absent) : la suite passe par la demande d\'un eleve');
    await attendre((delai + 2) * 1000);
    await verifierSalle(b.courriel);
  }
  verifier('5. A et B n\'ont plus le droit de publier',
    (await attendreDroit(pageA, false, 5000)) !== null && (await droits(pageB)).canPublish === false);

  // 6. La seance est finie (fin prevue et depassement passes), enseignant absent.
  finirDepuis(classe.seance, 16);
  if (planifie) {
    const fin = passagePlanifie(salle1);
    verifier('6. seance finie, enseignant absent : le passage planifie ferme la salle', fin?.sallesFermees === 1, fin);
  } else {
    const fin = await verifierSalle(b.courriel);
    verifier('6. seance finie, enseignant absent : la verification ferme la salle',
      fin.statut === 403 && fin.corps.salle === 'fermee', fin);
  }
  const decoA = await attendreDeconnexion(pageA, 8000);
  const decoB = await attendreDeconnexion(pageB, 8000);
  verifier('6. A est deconnecte, raison « salle supprimee »', decoA?.nom === 'ROOM_DELETED', decoA);
  verifier('6. B est deconnecte, raison « salle supprimee »', decoB?.nom === 'ROOM_DELETED', decoB);
  const refuse = await demander(a.courriel, { session_id: classe.seance });
  verifier('6. la base refuse un nouveau jeton : la seance est terminee',
    refuse.statut === 403 && refuse.corps.motif === 'terminee', refuse);

  // ------------------------------------------------------------------ Seance 2
  const classe2 = amorcerClasse({ n: 1, etiquette: `fermeture-fin-${Date.now() % 100000}` });
  const [d] = classe2.eleves;
  const verifierSalle2 = (courriel) => demander(courriel, { session_id: classe2.seance, action: 'verifier_salle' });
  const jetonEns2 = await demander(COMPTES.enseignant, { session_id: classe2.seance });
  const pageEns2 = await entrer(navigateur, jetonEns2.corps);
  await attendre(1500);
  const pageD = await entrer(navigateur, (await demander(d.courriel, { session_id: classe2.seance })).corps);
  verifier('7. D ouvre son micro devant son enseignant', (await ouvrirMicro(pageD)).ouvert === true);

  // 7. Le depassement est passe, le cours se tient encore.
  finirDepuis(classe2.seance, 20);
  const deborde = await verifierSalle2(d.courriel);
  verifier('7. depassement passe, enseignant present : la base ferme la porte, la salle reste ouverte',
    deborde.statut === 403 && deborde.corps.motif === 'terminee' && deborde.corps.salle === 'ouverte', deborde);
  await attendre(2000);
  verifier('7. ... personne n\'est deconnecte, le micro de D reste ouvert',
    (await pageD.evaluate(() => window.__deconnexion)) === null &&
    (await pageEns2.evaluate(() => window.__deconnexion)) === null && (await microPublie(pageD)) === true);

  // 8. La cloture automatique clot la seance en base.
  finirDepuis(classe2.seance, 31);
  sql('select private.ses_cloturer_seances_echues(pg_catalog.clock_timestamp())');
  const statut = sql(`select status from public.sessions where id = '${classe2.seance}'`);
  verifier('8. la cloture automatique a clos la seance en base', statut === 'ended', { statut });
  const close = await verifierSalle2(d.courriel);
  verifier('8. seance close, enseignant present : la salle n\'est pas fermee (question posee au directeur)',
    close.statut === 403 && close.corps.salle === 'ouverte', close);
  await attendre(2000);
  verifier('8. ... personne n\'est deconnecte',
    (await pageD.evaluate(() => window.__deconnexion)) === null &&
    (await pageEns2.evaluate(() => window.__deconnexion)) === null);

  // 9. L'enseignant sort : le webhook ferme la salle.
  await sortir(pageEns2);
  const decoD = await attendreDeconnexion(pageD, 10000);
  verifier('9. l\'enseignant sort d\'une seance close : le serveur ferme la salle, D est deconnecte',
    decoD?.nom === 'ROOM_DELETED', decoD);
} finally {
  await navigateur.close();
}
console.log(echecs === 0 ? '\nFERMETURE-SALLE : la regle tient sur la pile.' : `\n${echecs} ECHEC(S)`);
process.exit(echecs === 0 ? 0 : 1);
