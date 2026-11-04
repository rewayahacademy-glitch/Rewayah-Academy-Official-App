// Parcours 5 : pieges de la salle (captures/E2E/parcours-5/pieges.md).
// S'appuie sur la seance en cours de la classe du parcours 2 (chaine).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, cliquer, trouver, trouverTexte, libelles,
  activerSemantique, COMPTES, DEPOT, TRAVAIL } from './commun.mjs';

const p = await parcours('Parcours 5 : pieges', 'parcours-5/pieges');
const R = {};
const noter = (id, resultat, detail) => { R[id] = { resultat, detail }; p.dire(`[${id}] ${resultat} : ${detail}`); };
async function piege(id, f) { try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 200)}`); } }
const { FAMILLE, ADULTE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
const dansSalle = async (page) => page.url().includes('/salle') && !!(await trouver(page, /^Quitter la séance/, { delai: 4000 }));

const e = await p.contexte('enseignant');
await connecter(e.page, COMPTES.enseignant);
await cliquer(e.page, /^Rejoindre la salle/, { pause: 7000 });

await piege('5.1', async () => {
  await cliquer(e.page, /^Quitter la séance/, { pause: 1500 });
  await p.capture(e, 'p5-1_quitter_confirmation');
  const rester = await trouver(e.page, /^Rester$/, { delai: 2000, role: 'button' });
  const quitter = await trouver(e.page, /^Quitter/, { delai: 2000, role: 'button' });
  if (quitter) { await quitter.click(); await e.page.waitForTimeout(4000); await activerSemantique(e.page); }
  await p.capture(e, 'p5-1_apres_quitter');
  const retour = await trouver(e.page, /^Retourner dans la salle/, { delai: 4000 }) ?? await trouver(e.page, /^Rejoindre la salle/, { delai: 2000 });
  if (retour) { await retour.click(); await e.page.waitForTimeout(6000); }
  const ok = await dansSalle(e.page);
  noter('5.1', rester && ok ? 'vert' : 'rouge', `confirmation ${rester ? 'avec « Rester »' : 'absente'} ; apres « Quitter », ${retour ? `« ${(await retour.getAttribute('aria-label')) ?? 'Retourner'} »` : 'aucun retour propose'} ; de nouveau en salle : ${ok}`);
});
await piege('5.2', async () => {
  if (!(await dansSalle(e.page))) { await cliquer(e.page, /^Rejoindre la salle/, { pause: 6000 }).catch(() => {}); }
  await e.page.reload(); await e.page.waitForTimeout(8000); await activerSemantique(e.page);
  await p.capture(e, 'p5-2_apres_rechargement');
  const ok = await dansSalle(e.page);
  const l = (await libelles(e.page)).filter((x) => x.startsWith('flt-semantics:') || x.startsWith('h2:')).slice(0, 3).join(' / ');
  noter('5.2', ok ? 'vert' : (await trouver(e.page, /^(Rejoindre|Retourner)/, { delai: 2000 }) ? 'vert' : 'rouge'), `apres rechargement : ${e.page.url()} ; ${ok ? 'toujours en salle' : `« ${l} »`}`);
  if (!ok) { const r = await trouver(e.page, /^(Rejoindre la salle|Retourner dans la salle)/, { delai: 3000 }); if (r) { await r.click(); await e.page.waitForTimeout(6000); } }
});
await piege('5.3', async () => {
  const deux = await e.ctx.newPage();
  const { ouvrir } = await import('./commun.mjs');
  await ouvrir(deux, '/');
  const r = await trouver(deux, /^Rejoindre la salle/, { delai: 8000 });
  if (r) { await r.click(); await deux.waitForTimeout(7000); }
  await activerSemantique(deux);
  await deux.screenshot({ path: path.join(p.sortie, 'p5-3_second_onglet.png') });
  await e.page.waitForTimeout(3000); await activerSemantique(e.page);
  await p.capture(e, 'p5-3_premier_onglet');
  const msg1 = await trouverTexte(e.page, /(autre onglet|autre appareil|déjà connecté|ailleurs|déconnect)[^|]*/i, 2000);
  const msg2 = await trouverTexte(deux, /(autre onglet|autre appareil|déjà connecté|ailleurs)[^|]*/i, 1500);
  noter('5.3', msg1 || msg2 ? 'vert' : 'rouge', `deux onglets : ${msg1 ?? msg2 ?? 'aucun des deux ne dit que la salle est ouverte ailleurs'}`);
  await deux.close();
});
await piege('5.4', async () => {
  const t = await p.contexte('tuteur-sans-camera', { telephone: true });
  await t.ctx.clearPermissions();
  await connecterParLien(t.page, FAMILLE.courriel);
  const r = await trouver(t.page, /^Rejoindre la salle avec/, { delai: 8000 });
  if (r) { await r.click(); await t.page.waitForTimeout(7000); }
  await activerSemantique(t.page);
  const micro = await trouver(t.page, /^Ouvrir le micro/, { delai: 3000 });
  if (micro) { await micro.click(); await t.page.waitForTimeout(3000); }
  await p.capture(t, 'p5-4_micro_refuse');
  const msg = await trouverTexte(t.page, /(autoris|permission|accès au micro|réglages|bloqué)[^|]*/i, 3000);
  noter('5.4', msg ? 'vert' : 'rouge', `micro refuse par le navigateur puis « Ouvrir le micro » : ${msg ? `« ${msg} »` : 'aucun message (le micro semble simplement ne pas s\'ouvrir)'}`);
  await t.ctx.close();
});
await piege('5.5', async () => {
  const a = await p.contexte('adulte-tot', { telephone: true });
  await connecterParLien(a.page, ADULTE.courriel);
  await p.capture(a, 'p5-5_accueil_avant_ouverture');
  const r = await trouver(a.page, /^Rejoindre/, { delai: 3000, role: 'button' });
  const msg = await trouverTexte(a.page, /(s'ouvre|ouvrira|dans \d+|Cours dans|minutes avant)[^|]*/i, 3000);
  noter('5.5', !r && msg ? 'vert' : (r ? 'rouge' : 'rouge'), r ? '« Rejoindre » propose avant l\'ouverture' : `pas de « Rejoindre » ; ${msg ? `l'ecran dit « ${msg} »` : 'aucune phrase sur l\'ouverture de la salle'}`);
  await a.ctx.close();
});
await piege('5.6', async () => {
  const t = await p.contexte('tuteur', { telephone: true });
  await connecterParLien(t.page, FAMILLE.courriel);
  await cliquer(t.page, /^Rejoindre la salle avec/, { pause: 7000 });
  await cliquer(t.page, /^Quitter la séance/, { pause: 1500 });
  const q = await trouver(t.page, /^Quitter/, { delai: 2000, role: 'button' }); if (q) { await q.click(); await t.page.waitForTimeout(4000); }
  await activerSemantique(t.page);
  await p.capture(t, 'p5-6_tuteur_apres_quitter');
  const r = await trouver(t.page, /^(Rejoindre la salle avec|Retourner dans la salle)/, { delai: 5000 });
  if (r) { await r.click(); await t.page.waitForTimeout(6000); }
  const ok = !!(await trouver(t.page, /^Quitter la séance/, { delai: 4000 }));
  await p.capture(t, 'p5-6_tuteur_revenu');
  noter('5.6', ok ? 'vert' : 'rouge', `le tuteur quitte puis ${r ? 'retrouve un bouton pour revenir' : 'ne trouve rien pour revenir'} ; de nouveau en salle : ${ok}`);
  await t.ctx.close();
});

const f = path.join(DEPOT, 'docs/current/captures/E2E/parcours-5/pieges.md');
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').split('\n').map((l) => {
  const m = l.match(/^\| (5\.\d+) \|/);
  if (!m || !R[m[1]]) return l;
  const c = l.split('|');
  c[5] = ` ${R[m[1]].resultat === 'non joué' ? 'non' : 'oui'} `;
  c[6] = ` ${R[m[1]].resultat} : ${R[m[1]].detail.replace(/\|/g, '/').replace(/\s+/g, ' ')} `;
  return c.join('|');
}).join('\n'));
await p.fin('joué');
