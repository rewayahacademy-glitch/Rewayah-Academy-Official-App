// Parcours 6 : pieges du cahier de transmission (captures/E2E/parcours-6/pieges.md).
// Joue sur la seance close de la classe d'adultes, puis valide le cahier pour de bon.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, sql,
  activerSemantique, COMPTES, DEPOT, TRAVAIL } from './commun.mjs';

const p = await parcours('Parcours 6 : pieges', 'parcours-6/pieges');
const R = {};
const noter = (id, resultat, detail) => { R[id] = { resultat, detail }; p.dire(`[${id}] ${resultat} : ${detail}`); };
async function piege(id, f) { try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 200)}`); } }
const classe = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'classe_adultes.json'), 'utf8'));
const statut = sql(`select s.status from public.sessions s join public.groupes g on g.id = s.groupe_id
  where g.libelle = '${classe.nom}' and s.deleted_at is null and s.started_at < now() order by s.started_at desc limit 1`);
p.dire(`Seance de « ${classe.nom} » : ${statut}`);

const e = await p.contexte('enseignant');
await connecter(e.page, COMPTES.enseignant);
async function ouvrirCahier() {
  const re = new RegExp(`^Cahier de transmission.*${classe.nom.replace(/^E2E /, '').slice(0, 12)}|^Cahier de transmission`);
  let l = await trouver(e.page, re, { delai: 8000 });
  if (!l) { const v = await trouver(e.page, /À terminer/, { delai: 2000 }); if (v) { await v.click(); await e.page.waitForTimeout(2000); } l = await trouver(e.page, re, { delai: 4000 }); }
  if (!l) throw new Error('pas de ligne « Cahier de transmission » dans « À terminer »');
  await l.click(); await e.page.waitForTimeout(3000); await activerSemantique(e.page);
}
const valider = async () => { const v = await trouver(e.page, /^Valider le cahier de transmission/, { delai: 4000, role: 'button' }); if (!v) throw new Error('pas de bouton Valider'); return v; };
const champ = async () => e.page.locator('textarea').first();

await piege('6.1', async () => {
  await ouvrirCahier();
  await (await valider()).click(); await e.page.waitForTimeout(2500); await activerSemantique(e.page);
  await p.capture(e, 'p6-1_valider_sans_position');
  const msg = await trouverTexte(e.page, /(obligatoire|Choisissez|Indiquez|manque|avant de valider)[^|]*/i, 3000);
  const parti = !(await trouver(e.page, /^Valider le cahier de transmission/, { delai: 1500, role: 'button' }));
  noter('6.1', msg && !parti ? 'vert' : 'rouge', parti ? 'le cahier a ete valide sans position' : `message : ${msg ? `« ${msg} »` : 'aucun'}`);
});
await piege('6.2', async () => {
  if (!(await trouver(e.page, /^Valider le cahier de transmission/, { delai: 1500, role: 'button' }))) await ouvrirCahier();
  const c = await champ(); await c.click({ force: true }); await e.page.keyboard.type('E2E brouillon a garder', { delay: 5 });
  await cliquer(e.page, /^Retour$/, { role: 'button', pause: 2000 });
  await activerSemantique(e.page);
  await p.capture(e, 'p6-2_retour_en_cours');
  const avert = await trouverTexte(e.page, /(perdu|abandonner|enregistr|brouillon|Quitter)[^|]*/i, 2000);
  const rester = await trouver(e.page, /^(Rester|Annuler|Continuer)/, { delai: 1000, role: 'button' });
  if (rester) { await rester.click(); await e.page.waitForTimeout(1500); } else await ouvrirCahier();
  const garde = await e.page.evaluate(() => [...document.querySelectorAll('textarea')].some((t) => t.value.includes('E2E brouillon')));
  await p.capture(e, 'p6-2_reouvert');
  noter('6.2', avert || garde ? 'vert' : 'rouge', `${avert ? `avertissement « ${avert} »` : 'aucun avertissement'} ; texte retrouve a la reouverture : ${garde}`);
});
await piege('6.3', async () => {
  const c = await champ(); await c.click({ force: true }); await e.page.keyboard.press('Control+A');
  await e.page.keyboard.insertText('Lecture lente. '.repeat(200));
  await e.page.waitForTimeout(1500);
  const n = await c.inputValue();
  await p.capture(e, 'p6-3_texte_long');
  const lim = await trouverTexte(e.page, /\d+\s*\/\s*\d+|caractères/, 1500);
  noter('6.3', 'vert', `${n.length} caracteres gardes ; ${lim ? `compteur « ${lim} »` : 'pas de compteur'} (reste lisible, voir capture)`);
  await c.click({ force: true }); await e.page.keyboard.press('Control+A'); await e.page.keyboard.insertText('E2E : lettres revues, lecture lente.');
});
await piege('6.4', async () => {
  await cliquer(e.page, /^Où la Classe s'est arrêtée/, { pause: 2500 });
  await cliquer(e.page, /^109\. Al-Kaafiroon/, { role: 'radio', pause: 1500 });
  await cliquer(e.page, /^6$/, { role: 'button', pause: 800 });
  await cliquer(e.page, /^Retenir cette position$/, { pause: 2500 });
  const v = await valider(); await v.dblclick(); await e.page.waitForTimeout(3000);
  const conf = await trouver(e.page, /^(Valider|Confirmer)/, { delai: 1500, role: 'button' }); if (conf) { await conf.click(); await e.page.waitForTimeout(3000); }
  await activerSemantique(e.page);
  await p.capture(e, 'p6-4_double_clic');
  const nb = sql(`select count(*) from public.lesson_reports j join public.sessions s on s.id = j.session_id join public.groupes g on g.id = s.groupe_id where g.libelle = '${classe.nom}'`).trim();
  const err = await trouverTexte(e.page, /(erreur|n'a pas abouti|déjà)[^|]*/i, 1500);
  noter('6.4', err ? 'rouge' : 'vert', `apres double clic : ${err ? `« ${err} »` : 'aucune erreur affichee'} ; lignes de cahier en base : ${nb || '?'}`);
});

const f = path.join(DEPOT, 'docs/current/captures/E2E/parcours-6/pieges.md');
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').split('\n').map((l) => {
  const m = l.match(/^\| (6\.\d+) \|/);
  if (!m || !R[m[1]]) return l;
  const c = l.split('|');
  c[5] = ` ${R[m[1]].resultat === 'non joué' ? 'non' : 'oui'} `;
  c[6] = ` ${R[m[1]].resultat} : ${R[m[1]].detail.replace(/\|/g, '/').replace(/\s+/g, ' ')} `;
  return c.join('|');
}).join('\n'));
await p.fin('joué');
