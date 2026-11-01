// Parcours 7, paiement dans l'application (decision du directeur du
// 01/11/2026 : « le paiement doit se faire sur l'app, pas de sortir
// ailleurs »). Le formulaire de Stripe doit se monter DANS la page de
// resultat de l'application, sans quitter son adresse.
//
// Banc : pile locale ; Stripe en MODE TEST seulement. La session Checkout
// (embedded_page) est creee a l'avance en mode test ; dans la copie
// /tmp/e2e-pile (jamais dans le depot), recharge-payer rend son secret client
// au lieu d'appeler Stripe (pas de cle secrete de test sur ce banc). Le
// webhook et le credit ne sont PAS joues ici.
//
// Usage : E2E_PROXY=... E2E_STRIPE_PK=pk_test_... node tool/e2e/paiement_integre.mjs <succes|refus|etats>
//   succes : carte 4242 4242 4242 4242 ; refus : carte 4000 0000 0000 9995 ;
//   etats  : erreur (Stripe.js bloque) puis hors ligne.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecterParLien, trouver, trouverTexte, libelles, activerSemantique,
  amenerEnVue, APP, TRAVAIL } from './commun.mjs';

const scenario = process.argv[2] ?? 'succes';
if (!['succes', 'refus', 'etats'].includes(scenario)) throw new Error(`scenario inconnu : ${scenario}`);
const pk = process.env.E2E_STRIPE_PK ?? '';
if (scenario !== 'etats' && !pk.startsWith('pk_test_')) throw new Error('refus : E2E_STRIPE_PK doit etre une cle publiable de TEST');

const STRIPE = /(^|\.)(stripe\.com|stripe\.network|stripecdn\.com)$/;
const { FAMILLE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
const p = await parcours(`Paiement dans l'application : ${scenario}`, `paiement-dans-app/${scenario}`);
const echecs = [];
let code = 1;

async function jusquAuPaiement(f) {
  await connecterParLien(f.page, FAMILLE.courriel);
  await f.page.waitForTimeout(3000);
  await f.page.evaluate(() => { location.hash = '#/tuteur/foyer/recharge'; });
  await f.page.waitForTimeout(4000); await activerSemantique(f.page);
  const cocher = f.page.getByRole('checkbox');
  if (await cocher.count() && (await cocher.first().getAttribute('aria-checked')) !== 'true') await cocher.first().click();
  const plus = await trouver(f.page, /^(Augmenter|Ajouter|Plus)/, { delai: 2000, role: 'button' });
  if (plus) await plus.click(); else await f.page.mouse.click(329, 279);
  await f.page.waitForTimeout(2000); await activerSemantique(f.page);
  await p.capture(f, 'recharge');
  const payer = await trouver(f.page, /^Payer/, { delai: 8000, role: 'button' });
  if (!payer) throw new Error('« Payer » absent');
  await amenerEnVue(f.page, payer);
  await payer.click({ timeout: 5000 });
  await f.page.waitForTimeout(5000); await activerSemantique(f.page);
}

try {
  const f = await p.contexte('tuteur', { telephone: true });
  // Stripe (mode test) passe ; tout le reste suit la regle du banc.
  await f.ctx.route('**/*', (route) => {
    const h = new URL(route.request().url()).hostname;
    if (scenario === 'etats' && STRIPE.test(h)) return route.abort();
    if (STRIPE.test(h)) return route.continue();
    return route.fallback();
  });
  await jusquAuPaiement(f);
  const adresse = f.page.url();
  p.dire(`Apres « Payer » : ${adresse}`);
  if (!adresse.startsWith(APP)) echecs.push(`l'application a ete quittee : ${adresse}`);
  const titre = await trouverTexte(f.page, /Payez ici, sans quitter l.application/, 8000);
  p.dire(`Titre : ${titre ?? '-'}`);
  if (!titre) echecs.push('titre « Payez ici, sans quitter l\'application » absent');

  if (scenario === 'etats') {
    const erreur = await trouverTexte(f.page, /Le formulaire de paiement ne s.est pas affiché/, 30000);
    await p.capture(f, 'erreur_stripe_injoignable');
    p.dire(`Erreur : ${erreur ?? '-'}`);
    if (!erreur) echecs.push('etat d\'erreur absent quand Stripe.js est injoignable');
    await f.ctx.setOffline(true);
    await f.page.waitForTimeout(6000); await activerSemantique(f.page);
    await p.capture(f, 'hors_ligne');
    p.dire(`Hors ligne : ${(await libelles(f.page)).slice(0, 8).join(' | ').slice(0, 400)}`);
    await f.ctx.setOffline(false);
  } else {
    const cadre = f.page.frameLocator('iframe[src*="stripe.com"]').first();
    const carte = cadre.locator('input[name="cardNumber"], #cardNumber').first();
    await carte.waitFor({ timeout: 60000 });
    await f.page.waitForTimeout(2000);
    await p.capture(f, 'formulaire_monte');
    p.dire(`Formulaire Stripe monte dans ${f.page.url()}`);
    const remplir = async (sel, v) => { const e = cadre.locator(sel).first(); if (await e.count()) await e.fill(v); };
    await remplir('input[name="email"], #email', 'e2e-famille@example.com');
    await carte.fill(scenario === 'succes' ? '4242424242424242' : '4000000000009995');
    await remplir('input[name="cardExpiry"], #cardExpiry', '12 / 34');
    await remplir('input[name="cardCvc"], #cardCvc', '123');
    await remplir('input[name="billingName"], #billingName', 'E2E Famille');
    await remplir('input[name="billingPostalCode"], #billingPostalCode', '10001');
    await p.capture(f, 'formulaire_rempli');
    await cadre.locator('button[type="submit"], .SubmitButton').first().click();
    await f.page.waitForTimeout(12000); await activerSemantique(f.page);
    await p.capture(f, scenario === 'succes' ? 'apres_paiement' : 'carte_refusee');
    const apres = f.page.url();
    p.dire(`Apres validation : ${apres}`);
    if (!apres.startsWith(APP)) echecs.push(`l'application a ete quittee : ${apres}`);
    if (scenario === 'succes') {
      const etat = await trouverTexte(f.page, /Paiement (en cours de confirmation|confirmé)[^|]*/, 20000);
      p.dire(`Etat relu : ${etat ?? '-'} (webhook non joue sur ce banc : « en cours de confirmation » attendu)`);
      if (!etat) echecs.push('apres le paiement, l\'etat de la commande ne s\'affiche pas');
    } else {
      const refus = await cadre.locator('text=/refus|declined/i').first().textContent({ timeout: 15000 }).catch(() => null);
      p.dire(`Refus affiche par Stripe : ${refus ?? '-'}`);
      if (!refus) echecs.push('aucun message de refus dans le formulaire');
    }
  }
  code = await p.fin(echecs.length ? 'rouge' : 'vert', echecs.join(' ; '));
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
