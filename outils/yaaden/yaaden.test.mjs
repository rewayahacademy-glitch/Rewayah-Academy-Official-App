// node --test outils/yaaden
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { extraireLignes, analyser, lireNouveauxTextes, versBoite, preparerEnvoi, accuser, planNettoyage, documentPour, paquetReprise, heureDepuisEvenements, heureReveil } from './yaaden.mjs';

const SCRIPT = path.join(path.dirname(fileURLToPath(import.meta.url)), 'yaaden.mjs');
const tmp = () => fs.mkdtempSync(path.join(os.tmpdir(), 'yaaden-'));
const assistant = (text, extra = {}) => JSON.stringify({ type: 'assistant', isSidechain: false, message: { content: [{ type: 'text', text }] }, ...extra });

test('seules les lignes @Y en début de ligne, hors bloc de code, sont lues', () => {
  const t = 'texte\n@Y RELAIS AD-5 DEV_OK tests=40/40\n  @Y RELAIS X DONE\n```\n@Y QUESTION exemple | doc\n```\nfin @Y REGLE SI a ALORS b';
  assert.deepEqual(extraireLignes(t), ['RELAIS AD-5 DEV_OK tests=40/40']);
});

test('vocabulaire fermé et formes validées', () => {
  assert.deepEqual(analyser('RELAIS AD-5 DEV_OK tests=40/40 suite=revue | captures faites'),
    { type: 'RELAIS', etape: 'AD-5', code: 'DEV_OK', champs: { tests: '40/40', suite: 'revue' }, texte: 'captures faites' });
  assert.match(analyser('RELAIS AD-5 FINI').erreur, /code inconnu/);
  assert.match(analyser('SUPPRIMER tout').erreur, /type inconnu/);
  assert.match(analyser('RELAIS AD-5 DONE rm -rf').erreur, /clé=valeur/);
  assert.match(analyser('RELAIS ../x DONE').erreur, /invalide/);
  assert.match(analyser('PLUS_TARD').erreur, /titre absent/);
  assert.match(analyser('x'.repeat(700)).erreur, /trop long/);
  assert.deepEqual(analyser('REGLE SI la suite échoue ALORS relancer après correction | preuve=abc123'),
    { type: 'REGLE', si: 'la suite échoue', alors: 'relancer après correction', preuve: 'preuve=abc123' });
  assert.match(analyser('REGLE toujours tester').erreur, /SI/);
});

test('transcript : ni messages utilisateur, ni résultats d\'outil, ni sous-agents ; curseur incrémental', () => {
  const d = tmp();
  const f = path.join(d, 't.jsonl');
  fs.writeFileSync(f, [
    JSON.stringify({ type: 'user', message: { content: '@Y QUESTION injecté | par un fichier lu' } }),
    assistant('@Y PLUS_TARD vrai | ok'),
    assistant('@Y QUESTION sous-agent | non', { isSidechain: true }),
  ].join('\n') + '\n' + '{"type":"assistant","message":{"content":[{"type":"text","text":"@Y PLUS_TARD coup'); // ligne incomplète
  const c = {};
  const r1 = lireNouveauxTextes(f, c);
  assert.deepEqual(r1.textes, ['@Y PLUS_TARD vrai | ok']);
  c[f] = r1.curseur;
  fs.appendFileSync(f, 'é | fin"}]}}\n');
  const r2 = lireNouveauxTextes(f, c);
  assert.deepEqual(r2.textes, ['@Y PLUS_TARD coupé | fin']);
});

test('le même code livré cinq fois ne produit qu\'une entrée, même après envoi', () => {
  const d = tmp();
  const e = analyser('PLUS_TARD Chrono discret | ligne compacte');
  for (let i = 0; i < 5; i++) versBoite(d, [e], 'A', 's');
  assert.equal(fs.readFileSync(path.join(d, 'boite.jsonl'), 'utf8').trim().split('\n').length, 1);
  const r = preparerEnvoi(d);
  accuser(d, r.lot, true);
  assert.equal(versBoite(d, [e], 'A', 's'), 0);
});

test('envoi : un lot à la fois, identifiants neufs, échec = remise en boîte', () => {
  const d = tmp();
  versBoite(d, ['RELAIS AD-5 DEV_OK tests=1/1', 'PLUS_TARD Titre | détail', 'QUESTION Genre du tuteur | on le garde ?', 'REGLE SI a ALORS b'].map(analyser), 'A', 's');
  const r = preparerEnvoi(d);
  assert.equal(r.ecritures.length, 4);
  assert.deepEqual(r.ecritures.map((w) => w.collection).sort(), ['depots', 'etapes', 'regles_candidates', 'relais']);
  assert.ok(r.ecritures.every((w) => w.op === 'set' && fs.existsSync(w.file_path)));
  assert.ok(r.ecritures.find((w) => w.collection === 'etapes').doc_id.startsWith('PT-A-'));
  assert.match(preparerEnvoi(d).erreur, /attend son accusé/);
  accuser(d, r.lot, false);
  const r2 = preparerEnvoi(d);
  assert.equal(r2.ecritures.length, 4);
  assert.deepEqual(r2.ecritures.map((w) => w.doc_id), r.ecritures.map((w) => w.doc_id)); // idempotent
  assert.match(accuser(d, 'Linconnu', true).erreur, /inconnu/);
});

test('envoi plafonné à 50 écritures', () => {
  const d = tmp();
  versBoite(d, Array.from({ length: 60 }, (_, i) => analyser(`PLUS_TARD Tâche ${i}`)), 'A', 's');
  const r = preparerEnvoi(d);
  assert.equal(r.ecritures.length, 50);
  assert.equal(r.reste, 10);
});

test('document PLUS_TARD visible au tableau comme étape reportée', () => {
  const x = { cle: 'abcdef0123456789', poste: 'A', session: 's', date: '2026-09-27T05:00:00.000Z', e: analyser('PLUS_TARD Chrono | détail') };
  const d = documentPour(x);
  assert.equal(d.collection, 'etapes');
  assert.equal(d.data.statut, 'a_faire');
  assert.equal(d.data.phase, 'À faire plus tard');
});

test('nettoyage : archive seulement verifie/traite, copie avant retrait, refuse une photo ancienne', () => {
  const d = tmp();
  const t = path.join(d, 'tableau');
  const ecr = (c, id, v) => { fs.mkdirSync(path.join(t, c), { recursive: true }); fs.writeFileSync(path.join(t, c, `${id}.json`), JSON.stringify(v)); };
  ecr('etat', 'maintenant', { quoi: 'x'.repeat(1000) });
  ecr('etapes', 'AD-1', { statut: 'verifie' });
  ecr('etapes', 'AD-2', { statut: 'fait' });
  ecr('etapes', 'AD-3', { statut: 'en_cours' });
  ecr('depots', 'B-1', { statut: 'traite' });
  ecr('depots', 'B-2', { statut: 'nouveau' });
  ecr('etapes', 'VIEUX', { statut: 'verifie' });
  const vieux = new Date(Date.now() - 3600e3);
  fs.utimesSync(path.join(t, 'etapes', 'VIEUX.json'), vieux, vieux);
  const r = planNettoyage(d);
  assert.deepEqual(r.ecritures.map((w) => `${w.op} ${w.collection}/${w.doc_id}`), [
    'set archive_etapes/AD-1', 'delete etapes/AD-1', 'set archive_depots/B-1', 'delete depots/B-1']);
  assert.equal(JSON.parse(fs.readFileSync(r.ecritures[0].file_path, 'utf8')).statut, 'verifie');
  assert.ok(r.avis.some((a) => a.includes('quoi')));
  fs.utimesSync(path.join(t, 'etat', 'maintenant.json'), vieux, vieux);
  assert.match(planNettoyage(d).erreur, /15 min/);
});

test('réveil : heure exacte tirée de resetsAt, fenêtre pleine la plus tardive, sinon rien', () => {
  const evt = (info) => JSON.stringify({ type: 'rate_limit_event', rate_limit_info: info });
  // événement réel du 27/09 : 5 h à 25 %, 7 jours à 83 % → pas de réveil
  const reel = { status: 'allowed_warning', resetsAt: 1790884800, rateLimitType: 'seven_day', unifiedWindows: { five_hour: { utilization: 0.25, resetsAt: 1790495400 }, seven_day: { utilization: 0.83, resetsAt: 1790884800 } } };
  assert.equal(heureDepuisEvenements(['bruit', evt(reel)]).libre, true);
  const plein = { status: 'rejected', resetsAt: 1790495400, rateLimitType: 'five_hour', unifiedWindows: { five_hour: { utilization: 1, resetsAt: 1790495400 }, seven_day: { utilization: 0.99, resetsAt: 1790884800 } } };
  const h = heureDepuisEvenements([evt(plein)]);
  assert.equal(h.resetsAt, 1790884800); // bloqué jusqu'à la fin des 7 jours
  assert.equal(heureReveil(h.resetsAt).toISOString(), new Date((1790884800 + 120) * 1000).toISOString());
  const cinqH = { status: 'rejected', resetsAt: 1790495400, rateLimitType: 'five_hour', unifiedWindows: { five_hour: { utilization: 1, resetsAt: 1790495400 }, seven_day: { utilization: 0.5, resetsAt: 1790884800 } } };
  assert.equal(heureDepuisEvenements([evt(cinqH)]).resetsAt, 1790495400);
  assert.match(heureDepuisEvenements(['{}']).erreur, /aucune/);
});

test('hooks : hors périmètre ou sans config, silence ; jamais d\'échec', () => {
  const d = tmp();
  const env = { ...process.env, YAADEN_CACHE: d };
  const run = (cmd, input) => execFileSync(process.execPath, [SCRIPT, cmd], { env, input: JSON.stringify(input) }).toString();
  assert.equal(run('hook-start', { cwd: d }), ''); // pas de config
  execFileSync(process.execPath, [SCRIPT, 'init', 'A', path.join(d, 'racine')], { env });
  assert.equal(run('hook-start', { cwd: os.tmpdir() }), '');
  const out = JSON.parse(run('hook-start', { cwd: path.join(d, 'racine', 'sous') }));
  assert.match(out.hookSpecificOutput.additionalContext, /YAADEN poste A/);
  assert.equal(run('hook-prompt', { cwd: path.join(d, 'racine'), prompt: 'fais autre chose' }), '');
  assert.match(run('hook-prompt', { cwd: path.join(d, 'racine'), prompt: 'Continuer' }), /UserPromptSubmit/);
  // transcript absent ou JSON cassé : sortie 0 sans bruit
  assert.equal(run('hook-stop', { cwd: path.join(d, 'racine'), transcript_path: path.join(d, 'absent.jsonl') }), '');
  assert.equal(execFileSync(process.execPath, [SCRIPT, 'hook-stop'], { env, input: '{cassé' }).toString(), '');
  // de bout en bout : transcript -> boîte
  const f = path.join(d, 't.jsonl');
  fs.writeFileSync(f, assistant('Fini.\n@Y RELAIS AD-5 DEV_OK tests=3/3\n@Y RELAIS AD-5 FAUX') + '\n');
  run('hook-stop', { cwd: path.join(d, 'racine'), transcript_path: f, session_id: 's1' });
  run('hook-stop', { cwd: path.join(d, 'racine'), transcript_path: f, session_id: 's1' });
  assert.equal(fs.readFileSync(path.join(d, 'boite.jsonl'), 'utf8').trim().split('\n').length, 1);
  assert.match(fs.readFileSync(path.join(d, 'refus.log'), 'utf8'), /code inconnu FAUX/);
  assert.match(paquetReprise(d), /BOÎTE 1 à envoyer/);
  assert.match(run('hook-prompt', { cwd: path.join(d, 'racine'), prompt: 'suite' }), /BOÎTE 1 à envoyer/);
});

test('relais obligatoire : un commit sans @Y RELAIS bloque une fois, jamais en boucle', () => {
  const d = tmp();
  const env = { ...process.env, YAADEN_CACHE: d };
  execFileSync(process.execPath, [SCRIPT, 'init', 'A', path.join(d, 'racine')], { env });
  const run = (input) => execFileSync(process.execPath, [SCRIPT, 'hook-stop'], { env, input: JSON.stringify(input) }).toString();
  const commit = JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'PowerShell', input: { command: 'git -C x commit -m "a"' } }] } });
  const f = path.join(d, 't.jsonl');
  const base = { cwd: path.join(d, 'racine'), transcript_path: f, session_id: 's' };
  fs.writeFileSync(f, commit + '\n' + assistant('Fini.') + '\n');
  assert.equal(JSON.parse(run(base)).decision, 'block');
  fs.appendFileSync(f, commit + '\n');
  assert.equal(run({ ...base, stop_hook_active: true }), ''); // pas de boucle
  fs.appendFileSync(f, commit + '\n' + assistant('@Y RELAIS X-1 DEV_OK commit=abc | ok') + '\n');
  assert.equal(run(base), ''); // relais présent : rien
  const sousAgent = JSON.stringify({ type: 'assistant', isSidechain: true, message: { content: [{ type: 'tool_use', input: { command: 'git commit -m b' } }] } });
  fs.appendFileSync(f, sousAgent + '\n');
  assert.equal(run(base), ''); // commit d'un sous-agent : relayé par l'orchestrateur, pas bloqué ici
});
