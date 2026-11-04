// Parcours 3 : pieges de l'inscription d'une famille (captures/E2E/parcours-3/pieges.md).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, cliquer, trouver, trouverTexte, libelles, taper, dernierLien,
  activerSemantique, sql, DEPOT } from './commun.mjs';
import { questionnaire } from './inscription.mjs';

const p = await parcours('Parcours 3 : pieges', 'parcours-3/pieges');
const R = {};
const noter = (id, resultat, detail) => { R[id] = { resultat, detail }; p.dire(`[${id}] ${resultat} : ${detail}`); };
const t = Date.now().toString(36);
async function piege(id, f) { try { await f(); } catch (e) { noter(id, 'non joué', `le script a echoue : ${String(e.message).slice(0, 200)}`); } }
const REPONSES = (age = /^9 ans$/) => [
  { q: /Comment s'appelle votre enfant/, saisie: `E2E Piege${t}` },
  { q: /Quel âge a/, choix: age },
  { q: / est…/, choix: /^Un garçon$/ },
  { q: /Où en est .* aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
  { q: /Suivez-vous aussi des cours/, choix: /^Non$/ },
  { q: /Dans quelle langue/, choix: /^Français$/ },
  { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
  { q: /Quels moments/, choix: /^Le soir$/ },
];
async function debut(a, age) {
  await ouvrir(a.page, '/');
  await cliquer(a.page, /^Créer un compte$/);
  await cliquer(a.page, /^J'inscris mon enfant/);
  await cliquer(a.page, /^Continuer$/);
  return questionnaire(p, a, REPONSES(age), 'q');
}

await piege('3.2', async () => {
  const a = await p.contexte('famille-5ans', { telephone: true });
  const arret = await debut(a, /^5 ans$/);
  const msg = await trouverTexte(a.page, /(6 ans|âge minimum|trop jeune)[^|]*/i, 1500);
  await p.capture(a, 'p3-2_5_ans');
  noter('3.2', arret || msg ? 'vert' : 'rouge', arret ? `arret sur « ${arret} »` : (msg ? `message « ${msg} »` : '« 5 ans » accepte sans un mot au questionnaire, alors que l\'ajout de profil exige 6 ans au minimum'));
  await a.ctx.close();
});

await piege('3.6', async () => {
  const a = await p.contexte('famille-reprise', { telephone: true });
  await ouvrir(a.page, '/');
  await cliquer(a.page, /^Créer un compte$/);
  await cliquer(a.page, /^J'inscris mon enfant/);
  await cliquer(a.page, /^Continuer$/);
  await questionnaire(p, a, REPONSES().slice(0, 3), 'q_avant');
  const url = a.page.url();
  await a.page.reload(); await a.page.waitForTimeout(6000); await activerSemantique(a.page);
  await p.capture(a, 'p3-6_apres_rechargement');
  const l = (await libelles(a.page)).filter((x) => x.startsWith('flt-semantics:')).slice(0, 3).join(' / ');
  noter('3.6', /Où en est|Étape [4-9]/.test(l) ? 'vert' : 'rouge', `avant : ${url} ; apres rechargement : ${a.page.url()} ; « ${l} »`);
  await a.ctx.close();
});

const C1 = `E2E-Piege-${t}@Example.COM`;
await piege('3.3', async () => {
  const a = await p.contexte('famille-majuscules', { telephone: true });
  await debut(a);
  const depuis = Date.now();
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', `  ${C1}  `);
  await cliquer(a.page, /^Recevoir le lien d'inscription$/, { pause: 2500 });
  await p.capture(a, 'p3-3_adresse_majuscules');
  const recu = await dernierLien(C1.toLowerCase(), depuis, 30000);
  const err = await trouverTexte(a.page, /(n'a pas|invalide|forme)[^|]*/i, 1000);
  noter('3.3', recu?.lien ? 'vert' : 'rouge', recu?.lien ? 'adresse avec majuscules et espaces : lien recu (adresse normalisee)' : `aucun lien recu ; ${err ?? 'aucun message'}`);
  R.lienC1 = recu?.lien; R.ctxC1 = a;
});

await piege('3.1', async () => {
  if (!R.lienC1) return noter('3.1', 'non joué', 'pas de lien (3.3)');
  const b = await p.contexte('autre-appareil', { telephone: true });
  await b.page.goto(R.lienC1); await b.page.waitForTimeout(6000); await activerSemantique(b.page);
  await p.capture(b, 'p3-1_lien_autre_appareil');
  const l = (await libelles(b.page)).filter((x) => /^(flt-semantics|radio|button):/.test(x)).slice(0, 6).join(' | ');
  p.dire(`  autre appareil : ${b.page.url()} ; ${l}`);
  // On continue sur cet appareil : identite puis recapitulatif.
  for (let k = 0; k < 6; k++) {
    for (const c of await b.page.locator('input').all()) {
      const n = `${await c.getAttribute('aria-label') ?? ''}`;
      const v = /prénom/i.test(n) ? 'E2E Parent' : (/nom/i.test(n) ? `Piege${t}` : null);
      if (v) { await c.click({ force: true }); await b.page.keyboard.press('Control+A'); await b.page.keyboard.type(v); }
    }
    const g = await trouver(b.page, /^Un homme/, { delai: 800, role: 'radio' }); if (g) await g.click();
    const env = await trouver(b.page, /^Envoyer ma demande$/, { delai: 1000 });
    if (env) break;
    const c = await trouver(b.page, /^Continuer$/, { delai: 1500 }); if (!c) break;
    await c.click(); await b.page.waitForTimeout(1500); await activerSemantique(b.page);
  }
  await p.capture(b, 'p3-1_recapitulatif_autre_appareil');
  const recap = (await libelles(b.page)).filter((x) => /^button:(Type de compte|Vos propres|E2E Piege|Langue|Nom|Genre)/.test(x)).join(' | ');
  const pourQui = await trouverTexte(b.page, /Pour qui créez-vous ce compte/, 800);
  const enfantPerdu = !/E2E Piege/.test(recap);
  noter('3.1', !enfantPerdu ? 'vert' : 'rouge', enfantPerdu
    ? `lien ouvert sur un autre appareil : les reponses du questionnaire (enfant, age, niveau) ne suivent pas ; ${pourQui ? 'retour a « Pour qui créez-vous ce compte ? »' : `recapitulatif : ${recap || 'vide'}`}, sans un mot pour l'expliquer`
    : `les reponses suivent : ${recap}`);
  R.ctxB = b;
});

await piege('3.4', async () => {
  const b = R.ctxB; if (!b) return noter('3.4', 'non joué', 'pas de contexte');
  const env = await trouver(b.page, /^Envoyer ma demande$/, { delai: 3000 });
  if (!env) return noter('3.4', 'non joué', 'pas de « Envoyer ma demande » sur cet appareil (voir 3.1)');
  await env.dblclick(); await b.page.waitForTimeout(4000);
  const n = sql(`select count(*) from public.candidatures c join public.profiles p on p.id = c.responsable_id join auth.users u on u.id = p.id where lower(u.email) = lower('${C1}')`);
  await p.capture(b, 'p3-4_double_clic_envoyer');
  noter('3.4', n === '1' ? 'vert' : 'rouge', `${n} demande(s) en base apres un double clic`);
});

await piege('3.5', async () => {
  const b = R.ctxB; if (!b) return noter('3.5', 'non joué', 'pas de contexte');
  await b.page.goBack(); await b.page.waitForTimeout(3000); await activerSemantique(b.page);
  await p.capture(b, 'p3-5_retour_arriere');
  const l = (await libelles(b.page)).filter((x) => x.startsWith('flt-semantics:')).slice(0, 3).join(' / ');
  const env = await trouver(b.page, /^Envoyer ma demande$/, { delai: 1500 });
  noter('3.5', env ? 'rouge' : 'vert', env ? `retour arriere apres l'envoi : le recapitulatif revient avec « Envoyer ma demande » (${l})` : `retour arriere : ${b.page.url()} ; « ${l} »`);
});
noter('3.7', 'non joué', 'lecture faite sur les captures, voir le bilan');

const f = path.join(DEPOT, 'docs/current/captures/E2E/parcours-3/pieges.md');
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').split('\n').map((l) => {
  const m = l.match(/^\| (3\.\d+) \|/);
  if (!m || !R[m[1]]) return l;
  const c = l.split('|');
  c[5] = ` ${R[m[1]].resultat === 'non joué' ? 'non' : 'oui'} `;
  c[6] = ` ${R[m[1]].resultat} : ${R[m[1]].detail.replace(/\|/g, '/').replace(/\s+/g, ' ')} `;
  return c.join('|');
}).join('\n'));
await p.fin('joué');
