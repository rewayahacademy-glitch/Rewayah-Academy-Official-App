// LINK-CHOIX (06/11/2026), banc LOCAL seulement, contre le FAUX Stripe de
// banc (`tool/e2e/faux_stripe.mjs`, port 12111) : aucune cle Stripe, meme de
// test, aucune carte saisie.
//
// Stripe.js est remplace dans le navigateur par un FAUX qui imite
// `initCheckoutElementsSdk` (element de paiement) : des boutons « Link »,
// « Google Pay » et un champ de carte peints a la main, marques « faux ». Il
// ne prouve PAS le rendu ni le comportement du vrai Stripe (en particulier :
// qu'aucun code Link ne part avant un clic). Il prouve ce que NOTRE page fait :
//   * le serveur ouvre la session en `ui_mode: elements` (journal du faux) ;
//   * Stripe.js n'est initialise avec aucune adresse ni valeur par defaut ;
//     l'adresse ne part qu'a la confirmation (toucher « Payer ») ;
//   * la sortie est en haut, visible, et Echap ferme la page ;
//   * a 1440, deux colonnes (texte a gauche, formulaire a droite) ;
//   * un refus montre une phrase et rend « Payer » ;
//   * le temps du toucher de « Payer » au champ de carte pret (Stripe.js servi
//     avec un delai simule, E2E_DELAI_STRIPE_JS, 800 ms par defaut).
// Captures 390 et 1440, francais et arabe.
//
// Usage : node tool/e2e/link_choix.mjs [--dossier link-choix]
import { parcours, ouvrir, taper, trouver, libelles, activerSemantique, amenerEnVue, sql, MDP } from './commun.mjs';

/// La connexion de `commun.mjs`, avec le libelle arabe de « J'ai deja un compte ».
async function connecter(page, courriel) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    const e = await trouver(page, /^(J'ai déjà un compte|لدي حساب بالفعل)$/, { delai: 8000 });
    if (e) { await e.click(); await page.waitForTimeout(1200); }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await activerSemantique(page);
}

const args = process.argv.slice(2);
const dossier = args.includes('--dossier') ? args[args.indexOf('--dossier') + 1] : 'link-choix';
const FAUX = 'http://127.0.0.1:12111';
const DELAI = Number(process.env.E2E_DELAI_STRIPE_JS ?? 800);
const tampon = new Date().toISOString().slice(5, 19).replace(/[-T:]/g, '');
const p = await parcours('LINK-CHOIX : la carte, Link et les portefeuilles au choix', dossier);
function verifier(ok, quoi) {
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}`);
  if (!ok) throw new Error(quoi);
}
const journal = async () => (await (await fetch(`${FAUX}/__journal`)).json());

const FAUX_STRIPE_JS = `(function () {
  function bouton(texte, fond, encre) {
    var b = document.createElement('button');
    b.type = 'button';
    b.textContent = texte;
    b.style.cssText = 'flex:1;min-height:44px;border:0;border-radius:6px;font:600 15px system-ui;cursor:pointer;background:' + fond + ';color:' + encre + ';';
    return b;
  }
  window.Stripe = function (cle, options) {
    window.__fauxStripeOptions = options || null;
    return {
      initCheckoutElementsSdk: function (o) {
        window.__fauxInit = JSON.parse(JSON.stringify(o));
        window.__fauxConfirmations = [];
        return {
          createExpressCheckoutElement: function () {
            var h = {};
            return {
              on: function (ev, cb) { h[ev] = cb; },
              mount: function (el) {
                var d = document.createElement('div');
                d.id = 'faux-boutons-stripe';
                d.style.cssText = 'display:flex;gap:8px;';
                var link = bouton('Link (faux)', '#00d66f', '#011e0f');
                link.id = 'faux-link';
                link.onclick = function () { window.__fauxLinkClic = true; h.confirm && h.confirm({ expressPaymentType: 'link' }); };
                d.appendChild(link);
                d.appendChild(bouton('Google Pay (faux)', '#000000', '#ffffff'));
                el.appendChild(d);
                setTimeout(function () { h.ready && h.ready({ availablePaymentMethods: { link: true, googlePay: true, applePay: false } }); }, 0);
              },
            };
          },
          createPaymentElement: function () {
            var h = {};
            return {
              on: function (ev, cb) { h[ev] = cb; },
              mount: function (el) {
                var d = document.createElement('div');
                d.id = 'faux-carte-stripe';
                d.style.cssText = 'font:14px system-ui;color:#30313d;';
                d.innerHTML = '<div style="opacity:.7;margin-bottom:8px">Faux champ de carte de banc (le vrai est celui de Stripe)</div>'
                  + '<div style="height:44px;border:1px solid #e6e6e6;border-radius:12px;margin-bottom:12px"></div>'
                  + '<div style="display:flex;gap:12px"><div style="flex:1;height:44px;border:1px solid #e6e6e6;border-radius:12px"></div>'
                  + '<div style="flex:1;height:44px;border:1px solid #e6e6e6;border-radius:12px"></div></div>';
                el.appendChild(d);
                setTimeout(function () { window.__fauxStripeMonte = performance.now(); h.ready && h.ready({}); }, 0);
              },
            };
          },
          loadActions: function () {
            return Promise.resolve({ type: 'success', actions: {
              confirm: function (opts) {
                window.__fauxConfirmations.push({ email: opts.email || null, redirect: opts.redirect || null,
                  express: !!opts.expressCheckoutConfirmEvent });
                return Promise.resolve({ type: 'error', error: { message: '' } });
              },
            } });
          },
        };
      },
    };
  };
})();`;

async function avecFauxStripeJs(acteur) {
  await acteur.ctx.route('https://js.stripe.com/**', async (route) => {
    await new Promise((r) => setTimeout(r, DELAI));
    await route.fulfill({ status: 200, contentType: 'text/javascript', body: FAUX_STRIPE_JS });
  });
}

/// La premiere ligne d'une requete (psql ajoute « INSERT 0 1 » apres un RETURNING).
const un = (requete) => sql(requete).split('\n')[0].trim();

// Une seule classe par passage (le meme enseignant ne peut pas avoir deux
// classes au meme horaire) : un creneau libre, essaye au hasard.
let classe = null;
function classeDuPassage() {
  if (classe) return classe;
  const prof = un(`select id from public.profiles where role = 'teacher' and account_status = 'active' order by created_at limit 1`);
  for (let essai = 0; essai < 20 && !classe; essai++) {
    const jour = 1 + Math.floor(Math.random() * 7);
    const heure = 6 + Math.floor(Math.random() * 15);
    try {
      classe = un(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
         values ('${prof}', 'enfant', 5, 'E2E LinkChoix ${tampon}', ${jour}, ${heure}, 'Europe/Paris') returning id`);
    } catch { /* creneau pris : un autre */ }
  }
  if (!classe) throw new Error('aucun creneau libre pour la classe de test');
  return classe;
}

// Une famille de test (base LOCALE) : un titulaire, un enfant dans une classe.
function amorcerFamille(suffixe) {
  const courriel = `e2e-linkchoix-${tampon}-${suffixe}@example.com`;
  const id = un(`with u as (
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
        email_change_token_new, email_change)
      values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
        '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
        '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
      returning id),
    i as (insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
      select gen_random_uuid(), u.id, u.id::text, jsonb_build_object('sub', u.id::text, 'email', '${courriel}', 'email_verified', true),
             'email', now(), now(), now() from u returning user_id)
    select id from u`);
  const foyer = un(`insert into public.households (timezone) values ('Europe/Paris') returning id`);
  const enfant = un(`select gen_random_uuid()`);
  sql(`insert into auth.users (id, email) values ('${enfant}', 'e2e-linkchoix-enfant-${tampon}-${suffixe}@example.com')`);
  sql(`insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
       ('${id}', 'E2E-LINKC-T-${tampon}${suffixe}', 'guardian', '${foyer}', 'E2E Parent', 'LinkChoix', 'active', 'female'),
       ('${enfant}', 'E2E-LINKC-E-${tampon}${suffixe}', 'student', '${foyer}', 'H', 'LinkChoix', 'active', 'male')`);
  sql(`update public.households set primary_guardian_id = '${id}' where id = '${foyer}'`);
  sql(`insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${enfant}', 'minor', 'standard')`);
  sql(`insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${classeDuPassage()}', '${enfant}', now() - interval '20 days')`);
  return { courriel, id };
}

async function jusquAuFormulaire(acteur) {
  await acteur.page.evaluate(() => { location.hash = '#/tuteur/foyer/recharge'; });
  await acteur.page.waitForTimeout(4000);
  await activerSemantique(acteur.page);
  const cocher = acteur.page.getByRole('checkbox');
  if (await cocher.count() && (await cocher.first().getAttribute('aria-checked')) !== 'true') await cocher.first().click();
  const plus = await trouver(acteur.page, /^(Augmenter|Ajouter|Plus|زيادة|إضافة)/, { delai: 3000, role: 'button' });
  if (plus) { await plus.click(); await acteur.page.waitForTimeout(1500); }
  await activerSemantique(acteur.page);
  const payer = await trouver(acteur.page, /^(Payer|دفع)/, { delai: 10000, role: 'button' });
  if (!payer) throw new Error(`« Payer » absent ; ecran : ${(await libelles(acteur.page)).slice(0, 14).join(' | ')}`);
  await amenerEnVue(acteur.page, payer);
  await acteur.page.waitForTimeout(DELAI + 500);
  await acteur.page.evaluate(() => { window.__fauxStripeMonte = undefined; });
  const t0 = await acteur.page.evaluate(() => performance.now());
  await payer.click({ timeout: 5000 });
  await acteur.page.waitForFunction(() => window.__fauxStripeMonte !== undefined, null, { timeout: 30000 });
  const t1 = await acteur.page.evaluate(() => window.__fauxStripeMonte);
  await acteur.page.waitForTimeout(1200);
  return Math.round(t1 - t0);
}

const DIALOGUE = '[role=dialog][aria-modal=true]';

async function verifierPage(acteur, largeur, langue) {
  const dlg = acteur.page.locator(DIALOGUE);
  verifier(await dlg.count() === 1, `${largeur} ${langue} : la page de paiement est ouverte`);
  const cadre = await dlg.boundingBox();
  p.dire(`${largeur} ${langue} : la page de paiement occupe x=${Math.round(cadre.x)} y=${Math.round(cadre.y)} `
    + `largeur=${Math.round(cadre.width)} hauteur=${Math.round(cadre.height)} (zone de contenu de la route)`);
  // La sortie en haut : le premier bouton de la page, dans le haut de l'ecran.
  const sortie = dlg.locator('button.rwy-paiement-retour');
  const boite = await sortie.boundingBox();
  verifier(boite && boite.y < 80, `${largeur} ${langue} : la sortie est en haut (y = ${boite && Math.round(boite.y)})`);
  // Deux colonnes a 1440, une seule a 390.
  const bt = await dlg.locator('h1').boundingBox();
  const bz = await dlg.locator('.rwy-paiement-zone').boundingBox();
  const br = await dlg.locator('.rwy-paiement-rassurance').boundingBox();
  const cote = Math.abs(bt.y - bz.y) < 8 && Math.abs(bt.x - bz.x) > 200;
  verifier(largeur >= 1200 ? cote : bz.y > bt.y && Math.abs(bz.x - bt.x) < 8,
    `${largeur} ${langue} : ${largeur >= 1200 ? 'deux colonnes' : 'une colonne'}`);
  if (largeur < 1200) verifier(br.y > bz.y + bz.height - 1, `${largeur} ${langue} : la ligne rassurante est sous le formulaire`);
  // Le choix : les boutons Link et portefeuilles, puis la carte, puis « Payer ».
  verifier(await dlg.locator('#faux-link').count() === 1, `${largeur} ${langue} : Link est propose en bouton`);
  verifier(await dlg.locator('#faux-carte-stripe').count() === 1, `${largeur} ${langue} : la carte est proposee`);
  verifier(await dlg.locator('button.rwy-paiement-payer').count() === 1, `${largeur} ${langue} : le bouton de paiement par carte est la`);
  // Aucune adresse ni valeur par defaut donnee a Stripe a l'ouverture.
  const init = await acteur.page.evaluate(() => window.__fauxInit);
  const brut = JSON.stringify(init);
  verifier(!/@|defaultValues|email/i.test(brut), `${largeur} ${langue} : Stripe.js initialise sans adresse (${brut.slice(0, 120)})`);
  verifier((await acteur.page.evaluate(() => window.__fauxConfirmations.length)) === 0,
    `${largeur} ${langue} : aucune confirmation avant un toucher`);
}

let code = 1;
try {
  const jAvant = (await journal()).length;
  const temps = [];
  for (const [largeur, langue, cle] of [[1440, 'fr-FR', 'fr'], [390, 'fr-FR', 'fr'], [1440, 'ar-SA', 'ar'], [390, 'ar-SA', 'ar']]) {
    const f = amorcerFamille(`${cle}${largeur}`);
    const t = await p.contexte('tuteur', { vue: { width: largeur, height: largeur >= 1200 ? 900 : 780 }, langue });
    await avecFauxStripeJs(t);
    await connecter(t.page, f.courriel);
    const ms = await jusquAuFormulaire(t);
    temps.push(ms);
    p.dire(`${largeur} ${cle} : champ de carte pret ${ms} ms apres « Payer » (Stripe.js servi en ${DELAI} ms)`);
    const pret = await t.page.locator(DIALOGUE).getAttribute('data-pret-ms');
    p.dire(`${largeur} ${cle} : mesure de la page (data-pret-ms) : ${pret} ms depuis l'ouverture de la page`);
    await verifierPage(t, largeur, cle);
    await p.capture(t, `${largeur}_${cle}_choix`);
    if (largeur === 1440 && cle === 'fr') {
      // La page defile : la sortie reste en haut.
      await t.page.locator(DIALOGUE).evaluate((d) => { d.scrollTop = d.scrollHeight; });
      await t.page.waitForTimeout(300);
      const b = await t.page.locator(`${DIALOGUE} button.rwy-paiement-retour`).boundingBox();
      verifier(b && b.y < 80, '1440 fr : apres defilement, la sortie reste en haut');
      await t.page.locator(DIALOGUE).evaluate((d) => { d.scrollTop = 0; });
      // Payer par carte : l'adresse part a la confirmation seulement ; refus.
      await t.page.locator(`${DIALOGUE} button.rwy-paiement-payer`).click();
      await t.page.waitForTimeout(600);
      const conf = await t.page.evaluate(() => window.__fauxConfirmations);
      verifier(conf.length === 1 && conf[0].email === f.courriel && conf[0].redirect === 'if_required',
        `1440 fr : l'adresse ne part qu'au toucher de « Payer » (${JSON.stringify(conf)})`);
      const refus = await t.page.locator(`${DIALOGUE} [role=alert]`).innerText();
      verifier(/n'est pas pass/.test(refus), `1440 fr : le refus se dit (${refus.slice(0, 60)})`);
      await p.capture(t, '1440_fr_refus');
      // Link : seulement sur son bouton.
      await t.page.locator('#faux-link').click();
      await t.page.waitForTimeout(600);
      const conf2 = await t.page.evaluate(() => window.__fauxConfirmations);
      verifier(conf2.length === 2 && conf2[1].express === true, '1440 fr : Link confirme seulement apres son bouton');
      // Echap ferme la page.
      await t.page.keyboard.press('Escape');
      await t.page.waitForTimeout(1500);
      verifier(await t.page.locator(DIALOGUE).count() === 0, '1440 fr : Echap ferme la page de paiement');
      await p.capture(t, '1440_fr_apres_echap');
    }
    await t.ctx.close();
  }
  const j = (await journal()).slice(jAvant).filter((e) => e.methode === 'POST' && e.chemin === '/v1/checkout/sessions');
  verifier(j.length >= 4 && j.every((e) => e.corps.ui_mode === 'elements'), `le serveur ouvre les sessions en ui_mode elements (${j.map((e) => e.corps.ui_mode).join(', ')})`);
  verifier(j.every((e) => !('branding_settings[display_name]' in e.corps) && !('redirect_on_completion' in e.corps)),
    'aucun reglage refuse par Stripe en elements (branding_settings, redirect_on_completion)');
  const tries = [...temps].sort((a, b) => a - b);
  p.dire(`MESURE : mediane ${tries[Math.floor(tries.length / 2)]} ms (${temps.join(', ')}) du toucher de « Payer » au champ de carte pret`);
  code = await p.fin('vert', `mediane ${tries[Math.floor(tries.length / 2)]} ms`);
} catch (e) {
  p.dire(`ERREUR : ${e.stack}`);
  code = await p.fin('rouge', e.message);
}
process.exit(code);
