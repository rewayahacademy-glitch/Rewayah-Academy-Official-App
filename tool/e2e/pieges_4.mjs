// Parcours 4 : pieges du placement d'un eleve (captures/E2E/parcours-4/pieges.md).
// Une classe de pieges (garcons, enfants, seuil d'un eleve, mercredi 6 h) est
// creee par l'interface puis close a la fin.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, sql, COMPTES, DEPOT, TRAVAIL } from './commun.mjs';
import { ouvrirClasses, creerClasse } from './classes.mjs';

const p = await parcours('Parcours 4 : pieges', 'parcours-4/pieges');
const R = {};
const noter = (id, resultat, detail) => { R[id] = { resultat, detail }; p.dire(`[${id}] ${resultat} : ${detail}`); };
async function piege(id, f) { try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 200)}`); } }
const membres = (classe) => sql(`select count(*) from public.groupe_membres gm join public.groupes g on g.id = gm.groupe_id where g.libelle = '${classe}' and gm.left_at is null`);

/// Ouvre « Ajouter un élève » de la classe, choisit l'eleve (si propose) et le motif, « Ajouter ».
async function tenter(d, classe, eleve, { motif = 'Demande de la famille', dbl = false, capture }) {
  const f = await trouver(d.page, /^Actives, /, { delai: 1500 }); if (f) { await f.click(); await d.page.waitForTimeout(1200); }
  await cliquer(d.page, new RegExp(`^Actions : ${classe}`));
  await cliquer(d.page, /^Ajouter un élève$/, { role: 'menuitem', pause: 1500 });
  const proposes = (await libelles(d.page)).filter((x) => x.startsWith('radio:')).map((x) => x.slice(6, 70));
  const choix = eleve ? await trouver(d.page, new RegExp(`^${eleve}`), { role: 'radio', delai: 4000 }) : null;
  if (eleve && !choix) { await p.capture(d, capture); await d.page.keyboard.press('Escape'); await d.page.waitForTimeout(800); return { absent: true, proposes }; }
  if (choix) { await choix.click(); await d.page.waitForTimeout(400); }
  if (motif) await cliquer(d.page, new RegExp(`^${motif}$`), { pause: 400 });
  const b = await trouver(d.page, /^Ajouter$/, { role: 'button' });
  if (dbl) await b.dblclick(); else await b.click();
  await d.page.waitForTimeout(3000);
  await p.capture(d, capture);
  const msg = await trouverTexte(d.page, /(L'ajout n'a pas abouti[^|]*|Un motif est requis[^|]*|motif[^|]*obligatoire|complète[^|]*|seuil[^|]*)/i, 2000);
  await d.page.keyboard.press('Escape'); await d.page.waitForTimeout(800);
  return { msg, proposes };
}

const d = await p.contexte('direction');
await connecter(d.page, COMPTES.direction);
await ouvrirClasses(d.page);
const classe = `E2E Piege placement ${Date.now() % 100000}`;
await creerClasse(p, d, { public: 'Enfants', genre: 'Garçons', enseignant: 'E2E Enseignant Valide', creneaux: [{ jour: 'Mercredi', heure: 6 }], nom: classe });
// Seuil d'un eleve : reglage « Modifier le seuil » (sinon, le piege 4.5 n'est pas joue).
let seuil1 = false;
await piege('seuil', async () => {
  await cliquer(d.page, new RegExp(`^Actions : ${classe}`));
  await cliquer(d.page, /^Modifier le seuil$/, { role: 'menuitem', pause: 1500 });
  await cliquer(d.page, /^1 élève$/, { pause: 500 });
  const ok = await trouver(d.page, /^(Enregistrer|Valider|Modifier)/, { role: 'button', delai: 2000 });
  if (ok) { await ok.click(); await d.page.waitForTimeout(2000); }
  seuil1 = sql(`select seuil_max from public.groupes where libelle = '${classe}'`) === '1';
  await d.page.keyboard.press('Escape'); await d.page.waitForTimeout(600);
  delete R.seuil;
});
const comptes = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
const fille = sql(`select first_name || ' ' || last_name from public.profiles p join public.student_profiles sp on sp.profile_id = p.id
  where p.first_name like 'E2E Amina%' and sp.student_type = 'minor' and p.gender = 'female' order by p.created_at desc limit 1`);
const adulte = sql(`select first_name || ' ' || last_name from public.profiles p join public.student_profiles sp on sp.profile_id = p.id
  where p.first_name = 'E2E Adulte' and sp.student_type = 'autonomous' and not exists (select 1 from public.groupe_membres gm join public.groupes g on g.id = gm.groupe_id where gm.student_id = p.id and gm.left_at is null and g.ended_at is null)
  order by p.created_at limit 1`);

await piege('4.2', async () => {
  const r = await tenter(d, classe, comptes.FAMILLE.enfant, { motif: null, capture: 'p4-2_sans_motif' });
  noter('4.2', r.msg && membres(classe) === '0' ? 'vert' : 'rouge', `sans motif : « ${r.msg ?? 'aucun message'} » ; membres ${membres(classe)}`);
});
await piege('4.1', async () => {
  const r = await tenter(d, classe, comptes.FAMILLE.enfant, { capture: 'p4-1_deja_en_classe' });
  noter('4.1', r.msg && !/code: P0001|hint|details/.test(r.msg) ? 'vert' : 'rouge', `eleve deja en classe : « ${r.msg ?? 'aucun message'} » → UX-019`);
});
await piege('4.3', async () => {
  if (!adulte) return noter('4.3', 'non joué', 'aucun eleve adulte libre');
  const r = await tenter(d, classe, adulte, { capture: 'p4-3_adulte_classe_enfants' });
  if (r.absent) return noter('4.3', 'vert', `l'eleve adulte n'est pas propose dans une classe d'enfants (proposes : ${r.proposes.join(', ') || 'aucun'})`);
  noter('4.3', r.msg ? 'vert' : 'rouge', `adulte dans une classe d'enfants : « ${r.msg ?? 'accepte sans un mot'} »`);
});
await piege('4.4', async () => {
  if (!fille) return noter('4.4', 'non joué', 'aucune eleve fille');
  const r = await tenter(d, classe, fille, { capture: 'p4-4_fille_classe_garcons' });
  if (r.absent) return noter('4.4', 'vert', `la fille n'est pas proposee dans une classe de garcons`);
  noter('4.4', r.msg ? 'vert' : 'rouge', `fille dans une classe de garcons : « ${r.msg ?? 'acceptee sans un mot'} »`);
});
noter('4.5', 'non joué', seuil1 ? 'seuil a 1 pose, mais aucun second garcon libre pour le depasser' : '« Modifier le seuil » non abouti par le script');
noter('4.6', 'non joué', 'aucun eleve libre a ajouter deux fois (le seul garcon est deja en classe)');
await piege('4.7', async () => {
  const f = await trouver(d.page, /^Actives, /, { delai: 1500 }); if (f) { await f.click(); await d.page.waitForTimeout(1200); }
  await cliquer(d.page, new RegExp(`^Classe : ${classe}`), { pause: 2000 });
  await p.capture(d, 'p4-7_fiche_classe');
  const a = await trouver(d.page, /Ajouter un élève/, { delai: 1500 });
  noter('4.7', a ? 'vert' : 'rouge', a ? 'la fiche propose « Ajouter un élève »' : 'la fiche de la classe montre « Membres » et « Aucun élève dans cette classe pour l\'instant » sans « Ajouter un élève » (l\'action est dans le menu de la ligne) → UX-008');
  await d.page.keyboard.press('Escape');
});

const f = path.join(DEPOT, 'docs/current/captures/E2E/parcours-4/pieges.md');
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').split('\n').map((l) => {
  const m = l.match(/^\| (4\.\d+) \|/);
  if (!m || !R[m[1]]) return l;
  const c = l.split('|');
  c[5] = ` ${R[m[1]].resultat === 'non joué' ? 'non' : 'oui'} `;
  c[6] = ` ${R[m[1]].resultat} : ${R[m[1]].detail.replace(/\|/g, '/').replace(/\s+/g, ' ')} `;
  return c.join('|');
}).join('\n'));
const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
sql(`update public.groupe_membres set left_at = now(), left_by = '${admin}', left_reason = 'E2E : pieges' where left_at is null and groupe_id = (select id from public.groupes where libelle = '${classe}')`);
sql(`update public.groupes set ended_at = now(), ended_by = '${admin}', end_reason = 'E2E : pieges' where libelle = '${classe}' and ended_at is null`);
await p.fin('joué');
