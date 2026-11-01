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
// Usage : E2E_PROXY=... E2E_STRIPE_PK=pk_test_... node tool/e2e/paiement_integre.mjs <scenario> [etiquette]
//   succes : paiement accepte (E2E_CARTE, 4242 4242 4242 4242 par defaut) ;
//   3ds    : paiement accepte apres l'authentification de la banque (4000 0025 0000 3155) ;
//   refus  : carte refusee (E2E_CARTE : 9995 fonds insuffisants, 0002 refus, 0069 expiree) ;
//   etats  : erreur (Stripe.js bloque) puis hors ligne.
// [etiquette] nomme le dossier des captures (par defaut, le scenario).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecterParLien, trouver, trouverTexte, libelles, activerSemantique,
  amenerEnVue, APP, TRAVAIL } from './commun.mjs';

const scenario = process.argv[2] ?? 'succes';
const etiquette = process.argv[3] ?? scenario;
if (!['succes', '3ds', 'refus', 'etats'].includes(scenario)) throw new Error(`scenario inconnu : ${scenario}`);
const CARTES = { succes: '4242424242424242', '3ds': '4000002500003155', refus: '4000000000009995' };
const carteChoisie = (process.env.E2E_CARTE || CARTES[scenario] || '').split(',')[0].replace(/\s/g, '');
const reussite = scenario === 'succes' || scenario === '3ds';
const pk = process.env.E2E_STRIPE_PK ?? '';
if (scenario !== 'etats' && !pk.startsWith('pk_test_')) throw new Error('refus : E2E_STRIPE_PK doit etre une cle publiable de TEST');

const STRIPE = /(^|\.)(stripe\.com|stripe\.network|stripecdn\.com)$/;
const { FAMILLE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
const p = await parcours(`Paiement dans l'application : ${etiquette}`, `paiement-dans-app/${etiquette}`);
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
  // La page de paiement est native (role dialog) quand le formulaire se
  // monte ; sinon le titre est celui de la page Flutter (etats).
  const titre = (await f.page.locator('[role=dialog] h1').first().textContent({ timeout: 8000 }).catch(() => null))
    ?? await trouverTexte(f.page, /Payez ici, sans quitter l.application/, 8000);
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
    p.dire(`Carte de test : ${carteChoisie.slice(0, 4)} … ${carteChoisie.slice(-4)}`);
    await carte.fill(carteChoisie);
    await remplir('input[name="cardExpiry"], #cardExpiry', '12 / 34');
    await remplir('input[name="cardCvc"], #cardCvc', '123');
    await remplir('input[name="billingName"], #billingName', 'E2E Famille');
    await remplir('input[name="billingPostalCode"], #billingPostalCode', '10001');
    // « Enregistrer mes informations avec Link » est coche d'office par
    // Stripe et demande alors un telephone : une famille peut le decocher.
    const link = cadre.getByRole('checkbox', { name: /Link/ }).first();
    if (await link.count() && await link.isChecked().catch(() => false)) await link.uncheck().catch(() => {});
    await p.capture(f, 'formulaire_rempli');
    // Le bouton de Stripe est plus bas : c'est la PAGE de paiement qui
    // defile (regle du 01/11), jusqu'au bouton, puis on le presse.
    const bouton = cadre.locator('button[type="submit"], .SubmitButton').first();
    await bouton.scrollIntoViewIfNeeded();
    await f.page.waitForTimeout(800);
    await p.capture(f, 'page_defilee_jusqu_au_bouton');
    await bouton.click();
    if (scenario === '3ds') {
      // La banque demande une confirmation : fenetre de test de Stripe,
      // « Complete » (ou « Terminer »).
      // La fenetre de test de la banque arrive dans un cadre imbrique : on la
      // cherche jusqu'a 40 s, puis on confirme.
      let fait = false;
      for (let essai = 0; essai < 20 && !fait; essai++) {
        await f.page.waitForTimeout(2000);
        for (const fr of f.page.frames()) {
          const b = fr.locator('button, a[role=button]').filter({ hasText: /complete|terminer|autoriser|authorize|confirmer/i });
          if (await b.count().catch(() => 0)) {
            await p.capture(f, 'authentification_banque');
            await b.first().click().catch(() => {});
            fait = true; break;
          }
        }
      }
      p.dire(`Authentification de test : ${fait ? 'confirmee' : 'bouton introuvable'}`);
      if (!fait) echecs.push('authentification 3-D Secure : bouton de confirmation introuvable');
    }
    await f.page.waitForTimeout(12000); await activerSemantique(f.page);
    if (reussite) await p.capture(f, 'apres_paiement');
    const apres = f.page.url();
    p.dire(`Apres validation : ${apres}`);
    if (!apres.startsWith(APP)) echecs.push(`l'application a ete quittee : ${apres}`);
    if (reussite) {
      const etat = await trouverTexte(f.page, /Paiement (en cours de confirmation|confirmé)[^|]*/, 20000);
      p.dire(`Etat relu : ${etat ?? '-'} (webhook non joue sur ce banc : « en cours de confirmation » attendu)`);
      if (!etat) echecs.push('apres le paiement, l\'etat de la commande ne s\'affiche pas');
    } else {
      // E2E_CARTE peut nommer plusieurs cartes refusees (virgules) : chacune
      // est essayee dans le meme formulaire, qui reste ouvert apres un refus.
      const cartes = (process.env.E2E_CARTE || CARTES.refus).split(',').map((c) => c.replace(/\s/g, ''));
      for (let i = 0; i < cartes.length; i++) {
        if (i > 0) {
          await carte.fill(cartes[i]);
          await bouton.scrollIntoViewIfNeeded();
          await bouton.click();
          await f.page.waitForTimeout(10000);
        }
        const message = cadre.locator('text=/refus|declined|insuffisant|insufficient|expir|incorrect/i').first();
        await message.scrollIntoViewIfNeeded().catch(() => {});
        const refus = await message.textContent({ timeout: 15000 }).catch(() => null);
        await p.capture(f, `carte_refusee_${cartes[i].slice(-4)}`);
        p.dire(`Carte ${cartes[i].slice(0, 4)} … ${cartes[i].slice(-4)} : refus affiche par Stripe : ${refus ?? '-'}`);
        if (!refus) echecs.push(`carte ${cartes[i].slice(-4)} : aucun message de refus`);
        if (!f.page.url().startsWith(APP)) echecs.push(`l'application a ete quittee : ${f.page.url()}`);
      }
    }
  }
  code = await p.fin(echecs.length ? 'rouge' : 'vert', echecs.join(' ; '));
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
