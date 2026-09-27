#!/usr/bin/env node
// YAADEN : logistique du tableau de suivi sans IA.
// Le script range, déduplique, prépare les envois et compacte. Il n'exécute
// jamais une commande tirée d'un texte, n'utilise ni réseau ni git, et
// n'écrit que dans son dossier de cache. Claude n'appuie que sur « envoyer ».
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const ICI = path.dirname(fileURLToPath(import.meta.url));
// <racine>/pilotage-git/outils/yaaden -> <racine>/yaaden-cache
export const CACHE_DEFAUT = path.resolve(ICI, '..', '..', '..', 'yaaden-cache');
const TABLEAU = 'https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU';

export const CODES = ['READY', 'RUN', 'DEV_OK', 'REVIEW_REQ', 'REVIEW_OK', 'REVIEW_FAIL',
  'CROSS_REQ', 'BLOCK', 'DONE', 'ACK', 'NACK'];
const TYPES = ['RELAIS', 'PLUS_TARD', 'QUESTION', 'REGLE'];
const MAX_LIGNE = 600;
const MAX_ECRITURES = 50; // plafond d'un batch ArtifactData
const FRAICHEUR_MS = 15 * 60 * 1000;

// ---------- utilitaires ----------
const lireJson = (f, defaut) => { try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return defaut; } };
const ecrireJson = (f, v) => { fs.mkdirSync(path.dirname(f), { recursive: true }); const t = f + '.tmp'; fs.writeFileSync(t, JSON.stringify(v, null, 2)); fs.renameSync(t, f); };
const hash = (s, n = 8) => crypto.createHash('sha256').update(s).digest('hex').slice(0, n);
const nettoyer = (s) => s.replace(/[\u0000-\u0008\u000b-\u001f\u007f​-‏‪-‮⁦-⁩]/g, '').trim();
const jour = (d = new Date()) => d.toISOString().slice(0, 10);

function charger(cache) {
  const conf = lireJson(path.join(cache, 'config.json'), null);
  return { cache, conf };
}

function journaliserErreur(cache, e) {
  try { fs.mkdirSync(cache, { recursive: true }); fs.appendFileSync(path.join(cache, 'erreurs.log'), `${new Date().toISOString()} ${e?.stack || e}\n`); } catch {}
}

// ---------- 1. lecture des codes @Y ----------
// Une ligne compte seulement si elle commence par « @Y » dans un texte écrit
// par Claude (jamais un résultat d'outil ni un message utilisateur), hors bloc
// de code. Le contenu reste une donnée : il n'est jamais exécuté.
export function extraireLignes(texte) {
  const sortie = [];
  let dansCode = false;
  for (const brute of texte.split(/\r?\n/)) {
    if (/^\s*```/.test(brute)) { dansCode = !dansCode; continue; }
    if (dansCode || !brute.startsWith('@Y ')) continue;
    sortie.push(nettoyer(brute.slice(3)));
  }
  return sortie;
}

// Transforme une ligne en entrée validée, ou { erreur }.
export function analyser(ligne) {
  if (ligne.length > MAX_LIGNE) return { erreur: `trop long (${ligne.length} > ${MAX_LIGNE})` };
  const [tete, ...reste] = ligne.split(' | ');
  const texte = reste.join(' | ').trim();
  const mots = tete.trim().split(/\s+/);
  const type = mots.shift();
  if (!TYPES.includes(type)) return { erreur: `type inconnu : ${type}` };
  if (type === 'RELAIS') {
    const [etape, code, ...kv] = mots;
    if (!etape || !/^[A-Za-z0-9_.-]{1,40}$/.test(etape)) return { erreur: 'RELAIS : étape absente ou invalide' };
    if (!CODES.includes(code)) return { erreur: `RELAIS : code inconnu ${code}` };
    const champs = {};
    for (const m of kv) {
      const i = m.indexOf('=');
      if (i < 1) return { erreur: `RELAIS : « ${m} » n'est pas clé=valeur` };
      champs[m.slice(0, i)] = m.slice(i + 1);
    }
    return { type, etape, code, champs, texte };
  }
  if (type === 'REGLE') {
    const corps = [mots.join(' '), texte].filter(Boolean).join(' | ');
    const m = /^SI (.+?) ALORS (.+?)(?: \| (.*))?$/.exec(corps);
    if (!m) return { erreur: 'REGLE : forme attendue « SI … ALORS … | preuve=… »' };
    return { type, si: m[1].trim(), alors: m[2].trim(), preuve: (m[3] || '').trim() };
  }
  const titre = mots.join(' ').trim();
  if (!titre) return { erreur: `${type} : titre absent` };
  return { type, titre, texte };
}

// ---------- 2. hook Stop : transcript -> boîte d'envoi ----------
export function lireNouveauxTextes(fichier, curseurs) {
  const taille = fs.statSync(fichier).size;
  // première lecture d'une longue session : seulement la fin (la ligne
  // coupée au début est ignorée par JSON.parse)
  let debut = curseurs[fichier] ?? Math.max(0, taille - 2_000_000);
  if (debut > taille) debut = 0; // fichier recréé ou compacté
  const fd = fs.openSync(fichier, 'r');
  const buf = Buffer.alloc(taille - debut);
  fs.readSync(fd, buf, 0, buf.length, debut);
  fs.closeSync(fd);
  const brut = buf.toString('utf8');
  const fin = brut.lastIndexOf('\n'); // ne consommer que des lignes complètes
  if (fin < 0) return { textes: [], curseur: debut };
  const textes = [];
  for (const l of brut.slice(0, fin).split('\n')) {
    let o; try { o = JSON.parse(l); } catch { continue; }
    if (o.type !== 'assistant' || o.isSidechain) continue;
    for (const c of o.message?.content || []) if (c.type === 'text') textes.push(c.text);
  }
  return { textes, curseur: debut + Buffer.byteLength(brut.slice(0, fin + 1), 'utf8') };
}

export function versBoite(cache, entrees, poste, session) {
  const boite = path.join(cache, 'boite.jsonl');
  const vus = new Set(lireLignes(boite).map((e) => e.cle));
  for (const j of lireJournal(cache)) vus.add(j.cle);
  let ajoutes = 0;
  for (const e of entrees) {
    const cle = hash(`${poste}|${JSON.stringify(e)}`, 16);
    if (vus.has(cle)) continue;
    vus.add(cle);
    fs.mkdirSync(cache, { recursive: true });
    fs.appendFileSync(boite, JSON.stringify({ cle, poste, session, date: new Date().toISOString(), e }) + '\n');
    ajoutes++;
  }
  return ajoutes;
}

const lireLignes = (f) => { try { return fs.readFileSync(f, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l)); } catch { return []; } };
function lireJournal(cache) {
  const d = path.join(cache, 'journal');
  if (!fs.existsSync(d)) return [];
  return fs.readdirSync(d).filter((f) => f.endsWith('.jsonl')).flatMap((f) => lireLignes(path.join(d, f)));
}

function hookStop(cache, entree) {
  const { conf } = charger(cache);
  if (!conf || !dansPerimetre(conf, entree.cwd)) return;
  const fichier = entree.transcript_path;
  if (!fichier || !fs.existsSync(fichier)) return;
  const curseurs = lireJson(path.join(cache, 'curseurs.json'), {});
  const { textes, curseur } = lireNouveauxTextes(fichier, curseurs);
  const valides = [];
  for (const t of textes) for (const l of extraireLignes(t)) {
    const a = analyser(l);
    if (a.erreur) fs.appendFileSync(path.join(cache, 'refus.log'), `${new Date().toISOString()} ${a.erreur} :: ${l.slice(0, 200)}\n`);
    else valides.push(a);
  }
  versBoite(cache, valides, conf.poste, entree.session_id || '');
  curseurs[fichier] = curseur;
  ecrireJson(path.join(cache, 'curseurs.json'), curseurs);
}

function dansPerimetre(conf, cwd) {
  if (!cwd) return false;
  const c = path.resolve(cwd).toLowerCase();
  return (conf.racines || []).some((r) => c === path.resolve(r).toLowerCase() || c.startsWith(path.resolve(r).toLowerCase() + path.sep));
}

// ---------- 3. paquet de reprise (≤ 10 lignes + règles) ----------
export function paquetReprise(cache) {
  const { conf } = charger(cache);
  const m = lireJson(path.join(cache, 'tableau', 'etat', 'maintenant.json'), null);
  const boite = lireLignes(path.join(cache, 'boite.jsonl')).filter((x) => !x.lot);
  const enAttente = lireLignes(path.join(cache, 'boite.jsonl')).filter((x) => x.lot);
  const court = (s, n) => (s || '').replace(/\s+/g, ' ').slice(0, n);
  const lignes = [
    `YAADEN poste ${conf?.poste ?? '?'} · tableau ${TABLEAU}`,
    m ? `ÉTAPE ${court(m.etape, 220)}` : 'ÉTAPE inconnue (instantané absent : lancer « yaaden photo »)',
    m ? `ENSUITE ${court(m.ensuite, 220)}` : '',
    m ? `INTERDIT ${court(m.interdit, 200)}` : '',
    `BOÎTE ${boite.length} à envoyer, ${enAttente.length} envoyés sans accusé${boite.length ? ' → node yaaden.mjs envoyer' : ''}`,
    `PHOTO ${ageInstantane(cache)}`,
    'CODES @Y RELAIS|PLUS_TARD|QUESTION|REGLE : voir YAADEN_RULES.md §1',
  ].filter(Boolean);
  const regles = fs.existsSync(path.join(ICI, 'YAADEN_RULES.md')) ? fs.readFileSync(path.join(ICI, 'YAADEN_RULES.md'), 'utf8') : '';
  return `${lignes.join('\n')}\n\n${regles}`.trim();
}

function ageInstantane(cache) {
  const f = path.join(cache, 'tableau', 'etat', 'maintenant.json');
  if (!fs.existsSync(f)) return 'aucune';
  const min = Math.round((Date.now() - fs.statSync(f).mtimeMs) / 60000);
  return `il y a ${min} min${min > 60 ? ' (ancienne : relire le tableau avant d\'agir)' : ''}`;
}

// ---------- 4. envoi : boîte -> fichier de batch prêt ----------
export function documentPour(x) {
  const { e, poste } = x;
  const base = { poste, date: x.date.slice(0, 10), session: x.session, source: 'yaaden' };
  const id = `${poste}-${x.date.slice(0, 10).replaceAll('-', '')}-${x.cle.slice(0, 8)}`;
  switch (e.type) {
    case 'RELAIS':
      return { collection: 'relais', doc_id: id, data: { ...base, etape: e.etape, code: e.code, champs: e.champs, texte: e.texte } };
    case 'PLUS_TARD': // visible au tableau comme une étape reportée
      return { collection: 'etapes', doc_id: `PT-${id}`, data: { ...base, titre: e.titre, note: e.texte, statut: 'a_faire', phase: 'À faire plus tard', vague: 'À faire plus tard', ordre: 900 } };
    case 'QUESTION':
      return { collection: 'depots', doc_id: `${poste}-q-${id.slice(poste.length + 1)}`, data: { ...base, type: 'question', statut: 'nouveau', titre: e.titre, texte: e.texte } };
    case 'REGLE':
      return { collection: 'regles_candidates', doc_id: `R-${id}`, data: { ...base, si: e.si, alors: e.alors, preuve: e.preuve, statut: 'candidate' } };
  }
  throw new Error(`type inconnu ${e.type}`);
}

export function preparerEnvoi(cache) {
  const f = path.join(cache, 'boite.jsonl');
  const tout = lireLignes(f);
  if (tout.some((x) => x.lot)) return { erreur: `un lot attend son accusé (${tout.find((x) => x.lot).lot}) : node yaaden.mjs recu <lot> ou echec <lot>` };
  const choix = tout.slice(0, MAX_ECRITURES);
  if (!choix.length) return { vide: true };
  const lot = `L${Date.now().toString(36)}`;
  const dossier = path.join(cache, 'envoi', lot);
  const ecritures = choix.map((x) => {
    const d = documentPour(x);
    const fichier = path.join(dossier, `${d.collection.replaceAll('/', '_')}__${d.doc_id}.json`);
    ecrireJson(fichier, d.data);
    // doc_id neuf et déterministe : aucun écrasement d'une ligne existante
    return { op: 'set', collection: d.collection, doc_id: d.doc_id, file_path: fichier };
  });
  ecrireJson(path.join(dossier, 'writes.json'), ecritures);
  const marques = new Set(choix.map((x) => x.cle));
  ecrireLignes(f, tout.map((x) => (marques.has(x.cle) ? { ...x, lot } : x)));
  return { lot, ecritures, reste: tout.length - choix.length };
}

const ecrireLignes = (f, l) => { const t = f + '.tmp'; fs.writeFileSync(t, l.map((x) => JSON.stringify(x)).join('\n') + (l.length ? '\n' : '')); fs.renameSync(t, f); };

export function accuser(cache, lot, ok) {
  const f = path.join(cache, 'boite.jsonl');
  const tout = lireLignes(f);
  const du = tout.filter((x) => x.lot === lot);
  if (!du.length) return { erreur: `lot inconnu : ${lot}` };
  if (ok) {
    const j = path.join(cache, 'journal', `${jour()}.jsonl`);
    fs.mkdirSync(path.dirname(j), { recursive: true });
    for (const x of du) fs.appendFileSync(j, JSON.stringify({ ...x, envoye: new Date().toISOString() }) + '\n');
    ecrireLignes(f, tout.filter((x) => x.lot !== lot));
  } else {
    ecrireLignes(f, tout.map((x) => (x.lot === lot ? (({ lot: _, ...r }) => r)(x) : x)));
  }
  return { n: du.length };
}

// ---------- 5. nettoyage du tableau (depuis une photo fraîche) ----------
// N'archive que ce qui est définitivement clos : étape « verifie » (validée
// par une autre session) et dépôt « traite ». La copie d'archive précède
// toujours la suppression dans le même batch, et rien d'autre n'est effacé.
export function planNettoyage(cache, maintenant = Date.now()) {
  const dir = path.join(cache, 'tableau');
  const f = path.join(dir, 'etat', 'maintenant.json');
  const frais = (x) => maintenant - fs.statSync(x).mtimeMs <= FRAICHEUR_MS;
  if (!fs.existsSync(f) || !frais(f)) {
    return { erreur: 'photo absente ou de plus de 15 min : relire etapes, depots et etat/maintenant avec out_dir d\'abord' };
  }
  const ecritures = [];
  const avis = [];
  const lot = `N${maintenant.toString(36)}`;
  const sortie = path.join(cache, 'envoi', lot);
  const regles = [['etapes', 'archive_etapes', (d) => d.statut === 'verifie'], ['depots', 'archive_depots', (d) => d.statut === 'traite']];
  for (const [src, arch, clos] of regles) {
    const d = path.join(dir, src);
    if (!fs.existsSync(d)) continue;
    for (const nom of fs.readdirSync(d).filter((n) => n.endsWith('.json')).sort()) {
      if (ecritures.length + 2 > MAX_ECRITURES) { avis.push(`plafond de ${MAX_ECRITURES} écritures : relancer après envoi`); break; }
      // un fichier ancien = document peut-être déjà archivé ou modifié depuis
      if (!frais(path.join(d, nom))) continue;
      const doc = lireJson(path.join(d, nom), null);
      if (!doc || !clos(doc)) continue;
      const id = nom.slice(0, -5);
      const copie = path.join(sortie, `${arch}__${id}.json`);
      ecrireJson(copie, { ...doc, archive_le: jour(new Date(maintenant)), archive_par: 'yaaden' });
      ecritures.push({ op: 'set', collection: arch, doc_id: id, file_path: copie });
      ecritures.push({ op: 'delete', collection: src, doc_id: id });
    }
  }
  const m = lireJson(f, {});
  for (const [k, max] of [['quoi', 900], ['maj', 400], ['etape', 250], ['ensuite', 400]]) {
    if ((m[k] || '').length > max) avis.push(`etat/maintenant.${k} fait ${(m[k] || '').length} caractères (> ${max}) : à condenser par Claude`);
  }
  if (ecritures.length) ecrireJson(path.join(sortie, 'writes.json'), ecritures);
  return { lot, ecritures, avis };
}

// ---------- 6. vue compacte ----------
export function vue(cache) {
  const d = path.join(cache, 'tableau', 'etapes');
  if (!fs.existsSync(d)) return 'pas de photo du tableau';
  const docs = fs.readdirSync(d).filter((n) => n.endsWith('.json')).map((n) => ({ id: n.slice(0, -5), ...lireJson(path.join(d, n), {}) }));
  const par = {};
  for (const x of docs) (par[x.statut] ||= []).push(x.id);
  const pt = docs.filter((x) => x.phase === 'À faire plus tard').map((x) => `${x.id} ${x.titre}`);
  return [
    ...Object.entries(par).map(([s, ids]) => `${s} (${ids.length}) ${s === 'verifie' || s === 'fait' ? '' : ids.join(' ')}`.trim()),
    `plus tard (${pt.length})${pt.length ? ' : ' + pt.slice(0, 5).join(' · ') : ''}`,
  ].join('\n');
}

// ---------- 7. réveil après la remise à zéro des limites ----------
// L'heure vient de l'événement rate_limit_event que Claude Code émet lui-même
// (champ resetsAt, en secondes). Aucune estimation : sans cet horodatage, rien
// n'est programmé.
export function heureDepuisEvenements(lignes, seuil = 0.98) {
  let info;
  for (const l of lignes) {
    let o; try { o = JSON.parse(l); } catch { continue; }
    if (o.type === 'rate_limit_event' && o.rate_limit_info) info = o.rate_limit_info;
  }
  if (!info) return { erreur: 'aucune information de limite reçue' };
  const fenetres = Object.entries(info.unifiedWindows || {}).map(([nom, w]) => ({ nom, ...w }));
  const pleines = fenetres.filter((w) => w.utilization >= seuil && w.resetsAt);
  if (info.status === 'rejected' && info.resetsAt) pleines.push({ nom: info.rateLimitType || 'limite', resetsAt: info.resetsAt });
  if (!pleines.length) return { libre: true, fenetres };
  // la plus tardive des fenêtres pleines décide : avant elle, on serait encore bloqué
  const w = pleines.reduce((a, b) => (b.resetsAt > a.resetsAt ? b : a));
  return { fenetre: w.nom, resetsAt: w.resetsAt, fenetres };
}

export function heureReveil(resetsAtSec, margeSec = 120) {
  return new Date((resetsAtSec + margeSec) * 1000);
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function reveil(cache, args) {
  const { spawnSync } = await import('node:child_process');
  const session = args.find((a) => UUID.test(a));
  const force = args.find((a) => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/.test(a));
  let quand;
  if (force) quand = new Date(force);
  else {
    // sonde minimale : Haiku, sans CLAUDE.md ni outils, session non gardée
    const r = spawnSync('claude', ['-p', '--safe-mode', '--model', 'haiku', '--tools', '', '--output-format', 'stream-json', '--verbose', '--no-session-persistence', 'Réponds seulement : ok'], { encoding: 'utf8', shell: process.platform === 'win32', timeout: 120000 });
    const h = heureDepuisEvenements((r.stdout || '').split('\n'));
    if (h.erreur) return `${h.erreur} : rien programmé`;
    if (h.libre) return `pas de limite atteinte (${h.fenetres.map((w) => `${w.nom} ${Math.round(w.utilization * 100)} %`).join(', ')}) : rien programmé`;
    quand = heureReveil(h.resetsAt);
  }
  if (Number.isNaN(quand.getTime()) || quand.getTime() < Date.now()) return 'heure invalide ou passée : rien programmé';
  const conf = charger(cache).conf || {};
  const dossier = (conf.racines || [])[0] || process.cwd();
  // commande fixe ; seules l'heure (Date validée) et l'identifiant (UUID) varient
  const cmdClaude = session ? `claude --resume ${session} continuer` : 'claude continuer';
  const ps = [
    `$a = New-ScheduledTaskAction -Execute 'wt.exe' -Argument '-d "${dossier.replaceAll("'", "''")}" ${cmdClaude}'`,
    `$t = New-ScheduledTaskTrigger -Once -At ([datetime]::Parse('${quand.toISOString()}').ToLocalTime())`,
    `$s = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun`,
    `Register-ScheduledTask -TaskName 'YAADEN-reveil' -Action $a -Trigger $t -Settings $s -Force | Out-Null`,
  ].join('; ');
  const r = spawnSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', ps], { encoding: 'utf8' });
  if (r.status !== 0) return `échec de la programmation : ${(r.stderr || '').slice(0, 300)}`;
  ecrireJson(path.join(cache, 'reveil.json'), { quand: quand.toISOString(), session: session || null });
  return `réveil programmé le ${quand.toLocaleString('fr-FR')} (${cmdClaude}, dossier ${dossier})`;
}

// ---------- CLI ----------
async function lireEntree() {
  if (process.stdin.isTTY) return {};
  let s = '';
  for await (const c of process.stdin) s += c;
  try { return JSON.parse(s.replace(/^﻿/, '') || '{}'); } catch { return {}; } // PowerShell 5.1 ajoute un BOM
}

async function main() {
  const [cmd, ...args] = process.argv.slice(2);
  const cache = process.env.YAADEN_CACHE || CACHE_DEFAUT;
  const aide = 'usage : init <A|B> [racine…] | envoyer | recu <lot> | echec <lot> | nettoyer | reprise | vue | reveil [session-uuid] [heure-ISO] | reveil-annuler | hook-stop | hook-start | hook-prompt';
  try {
    switch (cmd) {
      case 'init': {
        const poste = args[0];
        if (!/^[A-Z]$/.test(poste || '')) { console.log(aide); process.exitCode = 1; return; }
        const racines = args.slice(1).length ? args.slice(1) : [path.resolve(ICI, '..', '..', '..')];
        ecrireJson(path.join(cache, 'config.json'), { poste, racines, tableau: TABLEAU });
        console.log(`poste ${poste}, cache ${cache}, racines ${racines.join(' ; ')}`);
        return;
      }
      case 'hook-stop': hookStop(cache, await lireEntree()); return;
      case 'hook-start':
      case 'hook-prompt': {
        const entree = await lireEntree();
        const { conf } = charger(cache);
        if (!conf || !dansPerimetre(conf, entree.cwd)) return;
        if (cmd === 'hook-prompt' && !/^\s*continuer\s*[.!]?\s*$/i.test(entree.prompt || '')) return;
        const evt = cmd === 'hook-start' ? 'SessionStart' : 'UserPromptSubmit';
        console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: evt, additionalContext: paquetReprise(cache) } }));
        return;
      }
      case 'reprise': console.log(paquetReprise(cache)); return;
      case 'reveil': console.log(await reveil(cache, args)); return;
      case 'reveil-annuler': {
        const { spawnSync } = await import('node:child_process');
        spawnSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', "Unregister-ScheduledTask -TaskName 'YAADEN-reveil' -Confirm:$false -ErrorAction SilentlyContinue"]);
        console.log('réveil annulé');
        return;
      }
      case 'vue': console.log(vue(cache)); return;
      case 'envoyer': {
        const r = preparerEnvoi(cache);
        if (r.erreur) { console.log(r.erreur); process.exitCode = 1; return; }
        if (r.vide) { console.log('boîte vide : rien à envoyer'); return; }
        console.log(`LOT ${r.lot} : ${r.ecritures.length} écritures${r.reste ? `, ${r.reste} restent pour le lot suivant` : ''}.`);
        console.log(`ArtifactData batch url=${TABLEAU} writes=`);
        console.log(JSON.stringify(r.ecritures));
        console.log(`Puis : node yaaden.mjs recu ${r.lot}   (ou echec ${r.lot})`);
        return;
      }
      case 'recu':
      case 'echec': {
        const r = accuser(cache, args[0], cmd === 'recu');
        console.log(r.erreur || `${r.n} entrées ${cmd === 'recu' ? 'archivées au journal' : 'remises dans la boîte'}`);
        if (r.erreur) process.exitCode = 1;
        return;
      }
      case 'nettoyer': {
        const r = planNettoyage(cache);
        if (r.erreur) { console.log(r.erreur); process.exitCode = 1; return; }
        for (const a of r.avis) console.log(`AVIS ${a}`);
        if (!r.ecritures.length) { console.log('rien à archiver'); return; }
        console.log(`LOT ${r.lot} : ${r.ecritures.length / 2} documents à archiver (copie puis retrait).`);
        console.log(`ArtifactData batch url=${TABLEAU} writes=`);
        console.log(JSON.stringify(r.ecritures));
        return;
      }
      default: console.log(aide); if (cmd) process.exitCode = 1;
    }
  } catch (e) {
    journaliserErreur(cache, e);
    // un hook ne doit jamais bloquer la session
    if (!cmd?.startsWith('hook-')) { console.error(String(e)); process.exitCode = 1; }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
