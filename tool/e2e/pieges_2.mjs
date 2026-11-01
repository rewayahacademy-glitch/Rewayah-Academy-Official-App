// Parcours 2 : pieges de la direction sur « Nouvelle classe »
// (docs/current/captures/E2E/parcours-2/pieges.md). Seconde enseignante,
// creneaux du mercredi matin : la chaine des parcours n'est pas genee.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, taper, sql, COMPTES, DEPOT } from './commun.mjs';
import { ouvrirClasses } from './classes.mjs';

const p = await parcours('Parcours 2 : pieges', 'parcours-2/pieges');
const R = {};
const noter = (id, resultat, detail) => { R[id] = { resultat, detail }; p.dire(`[${id}] ${resultat} : ${detail}`); };
const prof = sql(`select p.first_name || ' ' || p.last_name from public.profiles p where p.role = 'teacher' and p.account_status = 'active' and p.first_name = 'E2E Candidate' order by p.created_at desc limit 1`);
const nbClasses = (nom) => sql(`select count(*) from public.groupes where libelle = '${nom.replace(/'/g, "''")}'`);
const erreur = (page) => trouverTexte(page, /(La classe n'est pas créée[^|]*|Choisissez[^|]*|nécessaire[^|]*|obligatoire[^|]*|déjà[^|]*)/i, 2500);

async function formulaire(a, { genre = 'Filles', enseignant = true, creneaux = [['Mercredi', 6]], nom }) {
  await cliquer(a.page, 'Nouvelle classe');
  await cliquer(a.page, /^Enfants\./, { role: 'radio' });
  await cliquer(a.page, new RegExp(`^${genre}\\.`), { role: 'radio' });
  if (enseignant) await cliquer(a.page, new RegExp(`^${prof.split(' ').slice(0, 2).join(' ')}`), { role: 'radio' });
  const nb = await a.page.getByRole('button', { name: /^Heure/ }).count();
  for (let i = 0; i < creneaux.length; i++) {
    await a.page.getByRole('button', { name: new RegExp(`^${creneaux[i][0]}$`) }).nth(i).click();
    await a.page.waitForTimeout(400);
    await a.page.getByRole('button', { name: /^Heure/ }).nth(i).click();
    await a.page.waitForTimeout(600);
    await cliquer(a.page, new RegExp(`^${creneaux[i][1]} h$`), { role: 'menuitem' });
  }
  for (let i = nb; i > creneaux.length; i--) await cliquer(a.page, `Retirer le créneau ${i}`);
  if (nom !== undefined) {
    const champ = a.page.locator('input[aria-label^="Nom de la classe"]');
    await champ.click({ force: true }); await a.page.keyboard.press('Control+A');
    if (nom === '') await a.page.keyboard.press('Delete'); else await a.page.keyboard.type(nom, { delay: 5 });
  }
}
async function fermer(a) { await a.page.keyboard.press('Escape'); await a.page.waitForTimeout(800); const f = await trouver(a.page, /^(Fermer|Annuler)$/, { delai: 800, role: 'button' }); if (f) await f.click(); await a.page.waitForTimeout(600); }
async function piege(id, f) { try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 200)}`); } }

const d = await p.contexte('direction');
await connecter(d.page, COMPTES.direction);
await ouvrirClasses(d.page);

await piege('2.1', async () => {
  const nom = `E2E Piege sans enseignant ${Date.now() % 100000}`;
  await formulaire(d, { enseignant: false, nom });
  await cliquer(d.page, /^Créer la classe$/, { role: 'button', pause: 2500 });
  await p.capture(d, 'p2-1_sans_enseignant');
  const m = await erreur(d.page); const n = nbClasses(nom);
  const etat = sql(`select coalesce(max(etat), '-') from public.groupes where libelle = '${nom}'`);
  noter('2.1', n === '0' && m ? 'vert' : (etat === 'en_attente_enseignant' ? 'vert' : 'rouge'),
    `${n} classe creee (etat ${etat}) ; message « ${m ?? 'aucun'} »`);
  await fermer(d);
});
await piege('2.2', async () => {
  await formulaire(d, { nom: '' });
  await cliquer(d.page, /^Créer la classe$/, { role: 'button', pause: 2500 });
  await p.capture(d, 'p2-2_nom_vide');
  const m = await erreur(d.page);
  const cree = await trouverTexte(d.page, /^(?!.*Nouvelle classe)/, 1);
  noter('2.2', m ? 'vert' : 'rouge', `nom vide : « ${m ?? 'aucun message'} »`);
  await fermer(d);
});
await piege('2.3', async () => {
  const nom = `E2E Piege doublon creneau ${Date.now() % 100000}`;
  await formulaire(d, { creneaux: [['Mercredi', 7], ['Mercredi', 7]], nom });
  await cliquer(d.page, /^Créer la classe$/, { role: 'button', pause: 2500 });
  await p.capture(d, 'p2-3_creneaux_identiques');
  const m = await erreur(d.page); const n = nbClasses(nom);
  noter('2.3', n === '0' && m ? 'vert' : 'rouge', `${n} classe creee ; message « ${m ?? 'aucun'} »`);
  await fermer(d);
});
await piege('2.4', async () => {
  const nom = `E2E Piege double clic ${Date.now() % 100000}`;
  await formulaire(d, { creneaux: [['Mercredi', 8]], nom });
  const b = await trouver(d.page, /^Créer la classe$/, { role: 'button' });
  await b.dblclick(); await d.page.waitForTimeout(3500);
  await p.capture(d, 'p2-4_double_clic');
  const n = nbClasses(nom);
  noter('2.4', n === '1' ? 'vert' : 'rouge', `${n} classe(s) creee(s) par un double clic`);
  await fermer(d);
});
await piege('2.5', async () => {
  const nom = `E2E ${'صف تحفيظ القرآن '.repeat(6)}${'x'.repeat(20)}`.slice(0, 120);
  await formulaire(d, { creneaux: [['Mercredi', 9]], nom });
  await cliquer(d.page, /^Créer la classe$/, { role: 'button', pause: 3000 });
  await p.capture(d, 'p2-5_nom_long_arabe');
  const n = nbClasses(nom); const m = await erreur(d.page);
  noter('2.5', n === '1' || m ? 'vert' : 'rouge', `nom de ${nom.length} caracteres en arabe : ${n === '1' ? 'accepte' : `refuse (« ${m ?? 'sans message'} »)`}`);
  await fermer(d);
});
await piege('2.6', async () => {
  await formulaire(d, { creneaux: [['Mercredi', 10]], nom: 'E2E Saisie a garder' });
  await d.page.keyboard.press('Escape'); await d.page.waitForTimeout(1200);
  const avert = await trouverTexte(d.page, /(perdre|abandonner|quitter sans|modifications)[^|]*/i, 1500);
  const encore = await trouverTexte(d.page, /^h2:Nouvelle classe$/, 800);
  await p.capture(d, 'p2-6_echap');
  if (encore) { noter('2.6', 'vert', 'Échap ne ferme pas la boite (saisie gardee)'); await fermer(d); return; }
  await cliquer(d.page, 'Nouvelle classe');
  const garde = await d.page.locator('input[aria-label^="Nom de la classe"]').inputValue().catch(() => '');
  await p.capture(d, 'p2-6_reouverture');
  noter('2.6', avert || /garder/.test(garde) ? 'vert' : 'rouge', `Échap en pleine saisie : ${avert ? `avertissement « ${avert} »` : 'fermee sans un mot'} ; a la reouverture, nom « ${garde || 'vide'} »`);
  await fermer(d);
});
await piege('2.7', async () => {
  await cliquer(d.page, 'Nouvelle classe');
  await cliquer(d.page, /^Garçons\./, { role: 'radio' });
  const avant = (await libelles(d.page)).filter((x) => /^radio:E2E/.test(x));
  await cliquer(d.page, /^E2E Enseignant Valide/, { role: 'radio' });
  await cliquer(d.page, /^Filles\./, { role: 'radio' });
  await d.page.waitForTimeout(800);
  const apres = (await libelles(d.page)).filter((x) => /^radio:E2E/.test(x));
  const msg = await trouverTexte(d.page, /(enseignant[^|]*(retiré|ne peut|plus disponible)|choisissez un autre)[^|]*/i, 1500);
  await p.capture(d, 'p2-7_genre_change');
  const garde = apres.some((x) => /E2E Enseignant Valide/.test(x));
  noter('2.7', !garde || msg ? 'vert' : 'rouge', `Garçons → enseignant homme → Filles : liste avant ${avant.length}, apres ${apres.length} ; l'enseignant homme ${garde ? 'reste propose' : 'disparait'} ; ${msg ? `message « ${msg} »` : 'aucun message'}`);
  await fermer(d);
});
await piege('2.8', async () => {
  const t = await p.contexte('direction-telephone', { telephone: true });
  await connecter(t.page, COMPTES.direction);
  await p.capture(t, 'p2-8_accueil_telephone');
  await cliquer(t.page, 'Opérations', { pause: 2000 }).catch(async () => { await t.page.evaluate(() => { location.hash = '#/admin/operations'; }); await t.page.waitForTimeout(2000); });
  await cliquer(t.page, /^Classes$/, { pause: 2000 }).catch(() => {});
  const nouvelle = await trouver(t.page, 'Nouvelle classe', { delai: 5000 });
  if (!nouvelle) { await p.capture(t, 'p2-8_classes_telephone'); return noter('2.8', 'rouge', `au telephone, « Nouvelle classe » introuvable (${t.page.url()})`); }
  await nouvelle.click(); await t.page.waitForTimeout(1500);
  await p.capture(t, 'p2-8_formulaire_telephone');
  const creer = await trouver(t.page, /^Créer la classe$/, { delai: 3000, role: 'button' });
  noter('2.8', creer ? 'vert' : 'rouge', `au telephone (390 px) : formulaire ouvert, « Créer la classe » ${creer ? 'atteignable' : 'introuvable'}`);
  await t.ctx.close();
});
noter('2.9', 'non joué', 'lecture faite sur les captures, voir le bilan');

const f = path.join(DEPOT, 'docs/current/captures/E2E/parcours-2/pieges.md');
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').split('\n').map((l) => {
  const m = l.match(/^\| (2\.\d+) \|/);
  if (!m || !R[m[1]]) return l;
  const c = l.split('|');
  c[5] = ` ${R[m[1]].resultat === 'non joué' ? 'non' : 'oui'} `;
  c[6] = ` ${R[m[1]].resultat} : ${R[m[1]].detail.replace(/\|/g, '/').replace(/\s+/g, ' ')} `;
  return c.join('|');
}).join('\n'));
// Les classes de pieges ne doivent pas rester actives.
sql(`update public.groupes set ended_at = now(), ended_by = (select id from auth.users where email = '${COMPTES.direction}'), end_reason = 'E2E : pieges'
  where libelle like 'E2E Piege%' or libelle like 'E2E صف%' and ended_at is null`);
await p.fin('joué');
