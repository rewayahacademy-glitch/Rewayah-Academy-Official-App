// Parcours 5 bis : pieges de l'appareil de l'enfant (captures/E2E/parcours-5bis/pieges.md).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, connecterParLien, cliquer, trouver, trouverTexte, libelles, taper,
  allerOnglet, activerSemantique, DEPOT, TRAVAIL } from './commun.mjs';

const p = await parcours('Parcours 5 bis : pieges', 'parcours-5bis/pieges');
const R = {};
const noter = (id, resultat, detail) => { R[id] = { resultat, detail }; p.dire(`[${id}] ${resultat} : ${detail}`); };
async function piege(id, f) { try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 200)}`); } }
const { FAMILLE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));

// Le tuteur affiche un code (en retirant les appareils deja relies).
const t = await p.contexte('tuteur', { telephone: true });
await connecterParLien(t.page, FAMILLE.courriel);
await allerOnglet(t.page, 'Foyer', '/tuteur/foyer', p.dire);
await cliquer(t.page, /^Appareils du foyer/, { pause: 2000 });
await cliquer(t.page, new RegExp(`^${FAMILLE.enfant}`), { pause: 2000 });
for (let k = 0; k < 4 && await trouver(t.page, /^Navigateur web Connecté/, { delai: 1500, role: 'button' }); k++) {
  await t.page.mouse.click(311, 220); await t.page.waitForTimeout(1500);
  const ok = await trouver(t.page, /^(Retirer|Confirmer|Oui)/, { delai: 2000, role: 'button' }); if (ok) { await ok.click(); await t.page.waitForTimeout(2000); } else break;
}
await cliquer(t.page, /^Connecter un appareil$/, { pause: 4000 });
if (await trouverTexte(t.page, /Un code est déjà valable/, 1500)) { await t.page.mouse.click(195, 422); await t.page.waitForTimeout(3000); const c = await trouver(t.page, /^(Générer|Confirmer|Oui)/, { delai: 1500, role: 'button' }); if (c) { await c.click(); await t.page.waitForTimeout(3000); } }
const lu = await trouverTexte(t.page, /Code à saisir : [A-Z0-9 ]+/, 8000);
const code = lu?.match(/Code à saisir : ([A-Z0-9 ]+)/)?.[1].replace(/\s/g, '');
p.dire(`Code : ${code}`);

await piege('5b.4', async () => {
  await cliquer(t.page, /^Retour$/, { role: 'button', pause: 1500 });
  await cliquer(t.page, /^Connecter un appareil$/, { pause: 3000 });
  await p.capture(t, 'p5b-4_retour_ecran_code');
  const msg = await trouverTexte(t.page, /Un code est déjà valable[^|]*/, 3000);
  noter('5b.4', msg ? 'vert' : 'rouge', msg ? `« ${msg} » avec « Générer un nouveau code » (le bouton n'a pas de noeud propre : UX-021)` : 'rien ne dit qu\'un code est deja valable');
});

const e = await p.contexte('eleve', { telephone: true });
async function ecranCode() {
  await ouvrir(e.page, '/');
  const entree = await trouver(e.page, /^Connecter l'appareil d'un élève$/, { delai: 3000 });
  if (entree) { await entree.click(); await e.page.waitForTimeout(1200); } else { await e.page.evaluate(() => { location.hash = '#/connexion/eleve'; }); await e.page.waitForTimeout(3000); await activerSemantique(e.page); }
  const s = await trouver(e.page, /^Saisir le code$/, { delai: 3000 }); if (s) { await s.click(); await e.page.waitForTimeout(1200); }
}
await piege('5b.1', async () => {
  await ecranCode();
  const faux = code.slice(0, -1) + (code.endsWith('A') ? 'B' : 'A');
  await taper(e.page, 'input, textarea', faux);
  await cliquer(e.page, /^Connecter l'appareil$/, { pause: 4000 });
  await p.capture(e, 'p5b-1_code_faux');
  const msg = await trouverTexte(e.page, /(n'est pas|invalide|expiré|inconnu|incorrect|Vérifie|Vérifiez)[^|]*/i, 3000);
  noter('5b.1', msg ? 'vert' : 'rouge', `code faux : ${msg ? `« ${msg} »` : 'aucun message'}`);
});
await piege('5b.2', async () => {
  await ecranCode();
  await taper(e.page, 'input, textarea', code.toLowerCase());
  await p.capture(e, 'p5b-2_code_minuscules_saisi');
  await cliquer(e.page, /^Connecter l'appareil$/, { pause: 6000 });
  await activerSemantique(e.page);
  await p.capture(e, 'p5b-2_code_minuscules');
  const ok = await trouverTexte(e.page, /Choisis ton code personnel/, 4000);
  const msg = await trouverTexte(e.page, /(n'est pas|invalide|expiré|inconnu|incorrect)[^|]*/i, 1000);
  noter('5b.2', ok ? 'vert' : 'rouge', ok ? 'code en minuscules accepte' : `code en minuscules refuse : ${msg ?? 'aucun message'}`);
});
await piege('5b.3', async () => {
  if (!(await trouverTexte(e.page, /Choisis ton code personnel/, 2000))) return noter('5b.3', 'non joué', 'ecran du code personnel non atteint');
  for (const y of [447, 526, 605, 685]) { await e.page.mouse.click(195, y); await e.page.waitForTimeout(300); }   // 2 5 8 0
  await e.page.waitForTimeout(2000); await activerSemantique(e.page);
  for (const y of [400, 400, 400, 400]) { await e.page.mouse.click(111, y); await e.page.waitForTimeout(300); } // 1 1 1 1
  await e.page.waitForTimeout(2500); await activerSemantique(e.page);
  await p.capture(e, 'p5b-3_confirmation_differente');
  const msg = await trouverTexte(e.page, /(ne correspond|pas les? mêmes?|à nouveau|recommence|différent|Essaie)[^|]*/i, 3000);
  const l = (await libelles(e.page)).filter((x) => x.startsWith('flt-semantics:')).slice(0, 4).join(' / ');
  noter('5b.3', msg ? 'vert' : 'rouge', `confirmation differente : ${msg ? `« ${msg} »` : `aucun message (ecran : ${l})`}`);
});
noter('5b.5', 'oui', 'vert a la lecture : phrases courtes, tutoiement, « Quatre chiffres, rien que pour toi. Il reste sur cet appareil. », consigne lue par un bouton son');

const f = path.join(DEPOT, 'docs/current/captures/E2E/parcours-5bis/pieges.md');
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').split('\n').map((l) => {
  const m = l.match(/^\| (5b\.\d+) \|/);
  if (!m || !R[m[1]]) return l;
  const c = l.split('|');
  c[5] = ` ${R[m[1]].resultat === 'non joué' ? 'non' : 'oui'} `;
  c[6] = ` ${R[m[1]].resultat === 'oui' ? '' : R[m[1]].resultat + ' : '}${R[m[1]].detail.replace(/\|/g, '/').replace(/\s+/g, ' ')} `;
  return c.join('|');
}).join('\n'));
await p.fin('joué');
