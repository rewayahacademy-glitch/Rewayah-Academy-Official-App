// PAY-UX (02/11/2026), banc LOCAL seulement (G5, B7), contre le FAUX Stripe
// de banc (`tool/e2e/faux_stripe.mjs`, port 12111) : aucune cle Stripe, meme
// de test, aucune carte, aucun numero de carte saisi ni affiche.
//
// Stripe.js (js.stripe.com) est remplace dans le navigateur par un FAUX
// formulaire : il relit sa session au faux Stripe et peint le fond et les noms
// de lignes que le serveur a demandes. Il ne prouve donc pas le rendu du vrai
// formulaire de Stripe, seulement ce que notre serveur lui demande et ce que
// notre page fait autour.
//
// Ce que le parcours prouve :
//   * nom des lignes sans prenom (« Mensualite de ... »), nom de l'academie, et
//     fond du formulaire = fond de notre page (journal du faux Stripe) ;
//   * la page du formulaire : fond clair dans les deux themes, ligne
//     rassurante sous le formulaire ;
//   * nouveau depart : « Revenir sans payer », puis le retour sur le resultat
//     montre « Reprendre le paiement » ; un formulaire NEUF (ancienne session
//     expiree, nouvelle creee avec sa propre cle) ; une seule session par
//     commande en base ;
//   * session deja payee au nouveau depart : ni expiration ni nouvelle session ;
//   * expiration refusee par Stripe : aucune nouvelle session, phrase claire.
// Le double credit par webhook rejoue est prouve par
// supabase/tests/scenarios_pay_ux_session_neuve.sql.
//
// Mesure (« --mesure N ») : temps entre le toucher de « Payer » et le
// formulaire monte, Stripe.js servi avec un delai simule (E2E_DELAI_STRIPE_JS,
// 800 ms par defaut) ; rien n'est paye.
//
// Usage : node tool/e2e/pay_ux.mjs [--mesure N] [--dossier pay-ux]
import { parcours, ouvrir, connecter, trouver, trouverTexte, libelles, activerSemantique,
  amenerEnVue, sql, MDP, DB } from './commun.mjs';

const args = process.argv.slice(2);
const mesure = args.includes('--mesure') ? Number(args[args.indexOf('--mesure') + 1] || 3) : 0;
const dossier = args.includes('--dossier') ? args[args.indexOf('--dossier') + 1] : 'pay-ux';
const FAUX = 'http://127.0.0.1:12111';
const DELAI = Number(process.env.E2E_DELAI_STRIPE_JS ?? 800);
const tampon = new Date().toISOString().slice(5, 19).replace(/[-T:]/g, '');
const p = await parcours(`PAY-UX : la page de paiement des familles${mesure ? ` (mesure x${mesure})` : ''}`, dossier);
const verifs = [];
function verifier(ok, quoi) {
  verifs.push({ ok, quoi });
  p.dire(`${ok ? 'OK   ' : 'ROUGE'} ${quoi}`);
  if (!ok) throw new Error(quoi);
}
const journal = async () => (await (await fetch(`${FAUX}/__journal`)).json());
const sessionsCreees = (j) => j.filter((e) => e.methode === 'POST' && e.chemin === '/v1/checkout/sessions');

// Le faux Stripe.js : il remplace js.stripe.com dans le navigateur.
const FAUX_STRIPE_JS = `(function () {
  window.Stripe = function () {
    return {
      createEmbeddedCheckoutPage: function (o) {
        return Promise.resolve(o.fetchClientSecret()).then(function (secret) {
          var id = String(secret).split('_secret')[0];
          return {
            mount: function (el) {
              var d = document.createElement('div');
              d.id = 'faux-formulaire-stripe';
              d.setAttribute('data-session', id);
              d.style.cssText = 'min-height:360px;border-radius:12px;padding:24px;box-sizing:border-box;font:15px system-ui;color:#1a1a1a;';
              el.appendChild(d);
              window.__fauxStripeMonte = performance.now();
              fetch('${FAUX}/v1/checkout/sessions/' + id).then(function (r) { return r.json(); }).then(function (s) {
                d.style.background = (s.branding_settings && s.branding_settings.background_color) || '#ffffff';
                d.innerHTML = '<div style="font-weight:600;margin-bottom:8px">' + ((s.branding_settings && s.branding_settings.display_name) || '?') + '</div>'
                  + '<div style="opacity:.75;margin-bottom:4px">Faux formulaire de banc (le vrai est celui de Stripe)</div>'
                  + (s.noms || []).map(function (n) { return '<div class="ligne-stripe">' + n + '</div>'; }).join('')
                  + '<div style="margin-top:16px;height:44px;border:1px solid #c9c9d1;border-radius:6px"></div>'
                  + '<div style="margin-top:12px;height:44px;border:1px solid #c9c9d1;border-radius:6px"></div>'
                  + '<div style="margin-top:16px;height:44px;border-radius:6px;background:#5b3fd6"></div>';
              });
            },
            destroy: function () { var x = document.getElementById('faux-formulaire-stripe'); if (x) x.remove(); },
          };
        });
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

// Une famille de test (base LOCALE) : un titulaire, un enfant dans une classe.
function amorcerFamille(suffixe) {
  const courriel = `e2e-payux-${tampon}-${suffixe}@example.com`;
  const id = sql(`with u as (
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
  const foyer = sql(`insert into public.households (timezone) values ('Europe/Paris') returning id`);
  const enfant = sql(`select gen_random_uuid()`);
  sql(`insert into auth.users (id, email) values ('${enfant}', 'e2e-payux-enfant-${tampon}-${suffixe}@example.com')`);
  sql(`insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
       ('${id}', 'E2E-PAYUX-T-${tampon}${suffixe}', 'guardian', '${foyer}', 'E2E Parent', 'PayUx', 'active', 'female'),
       ('${enfant}', 'E2E-PAYUX-E-${tampon}${suffixe}', 'student', '${foyer}', 'H', 'PayUx', 'active', 'male')`);
  sql(`update public.households set primary_guardian_id = '${id}' where id = '${foyer}'`);
  sql(`insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${enfant}', 'minor', 'standard')`);
  const prof = sql(`select id from public.profiles where role = 'teacher' and account_status = 'active' order by created_at limit 1`);
  const groupe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
       values ('${prof}', 'enfant', 5, 'E2E PayUx ${tampon}${suffixe}', 2, 17, 'Europe/Paris') returning id`);
  sql(`insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${groupe}', '${enfant}', now() - interval '20 days')`);
  return { courriel, id };
}

async function jusquAuFormulaire(acteur) {
  await acteur.page.evaluate(() => { location.hash = '#/tuteur/foyer/recharge'; });
  await acteur.page.waitForTimeout(4000);
  await activerSemantique(acteur.page);
  const cocher = acteur.page.getByRole('checkbox');
  if (await cocher.count() && (await cocher.first().getAttribute('aria-checked')) !== 'true') await cocher.first().click();
  const plus = await trouver(acteur.page, /^(Augmenter|Ajouter|Plus)/, { delai: 3000, role: 'button' });
  if (plus) { await plus.click(); await acteur.page.waitForTimeout(1500); }
  await activerSemantique(acteur.page);
  const payer = await trouver(acteur.page, /^Payer/, { delai: 10000, role: 'button' });
  if (!payer) throw new Error(`« Payer » absent ; ecran : ${(await libelles(acteur.page)).slice(0, 14).join(' | ')}`);
  await amenerEnVue(acteur.page, payer);
  // On attend que Stripe.js precharge ait eu le temps d'arriver (la famille
  // choisit ses montants pendant ce temps).
  await acteur.page.waitForTimeout(DELAI + 500);
  await acteur.page.evaluate(() => { window.__fauxStripeMonte = undefined; });
  const t0 = await acteur.page.evaluate(() => performance.now());
  await payer.click({ timeout: 5000 });
  await acteur.page.waitForFunction(() => window.__fauxStripeMonte !== undefined, null, { timeout: 30000 });
  const t1 = await acteur.page.evaluate(() => window.__fauxStripeMonte);
  await acteur.page.waitForTimeout(1200);
  return Math.round(t1 - t0);
}

const commandeDe = (titulaire) => sql(`select id || '|' || session_prestataire || '|' || etat from public.commandes_recharge
  where titulaire = '${titulaire}' order by cree_le desc limit 1`).split('|');

async function revenirSansPayer(acteur) {
  await acteur.page.getByRole('button', { name: /Revenir aux soldes sans payer/ }).first().click({ timeout: 5000 });
  await acteur.page.waitForTimeout(2500);
}

async function ouvrirResultat(acteur, commande) {
  await acteur.page.evaluate((c) => { location.hash = `#/tuteur/foyer/recharge/result?commande=${c}`; }, commande);
  await acteur.page.waitForTimeout(4000);
  await activerSemantique(acteur.page);
}

let code = 1;
try {
  if (mesure) {
    const f = amorcerFamille('m');
    const t = await p.contexte('tuteur', { vue: { width: 1440, height: 900 } });
    await avecFauxStripeJs(t);
    await connecter(t.page, f.courriel);
    const temps = [];
    for (let i = 0; i < mesure; i++) {
      temps.push(await jusquAuFormulaire(t));
      p.dire(`mesure ${i + 1} : ${temps.at(-1)} ms du toucher de « Payer » au formulaire monte`);
      await revenirSansPayer(t);
    }
    const tries = [...temps].sort((a, b) => a - b);
    p.dire(`MESURE : mediane ${tries[Math.floor(tries.length / 2)]} ms (${temps.join(', ')}) ; Stripe.js servi en ${DELAI} ms`);
    code = await p.fin('vert', `mesure : mediane ${tries[Math.floor(tries.length / 2)]} ms`);
  } else {
    const jAvant = (await journal()).length;
    // 1. Le formulaire, 1440, theme clair.
    const f1 = amorcerFamille('a');
    const t = await p.contexte('tuteur', { vue: { width: 1440, height: 900 } });
    await avecFauxStripeJs(t);
    await connecter(t.page, f1.courriel);
    const ms = await jusquAuFormulaire(t);
    p.dire(`formulaire monte en ${ms} ms apres « Payer » (Stripe.js precharge, servi en ${DELAI} ms)`);
    await p.capture(t, '1440_clair_formulaire');
    const [commande, sessionA] = commandeDe(f1.id);
    const creees = sessionsCreees((await journal()).slice(jAvant));
    const premiere = creees.at(-1);
    p.dire(`faux Stripe : creation ${premiere?.cle} ; fond ${premiere?.corps['branding_settings[background_color]']} ; nom ${premiere?.corps['branding_settings[display_name]']} ; ligne « ${premiere?.corps['line_items[0][price_data][product_data][name]']} »`);
    verifier(/^Mensualité d/.test(premiere?.corps['line_items[0][price_data][product_data][name]'] ?? '')
      && !(premiere?.corps['line_items[0][price_data][product_data][name]'] ?? '').includes('· H'),
      'la ligne dit ce qu on paie (« Mensualite de ... »), sans prenom');
    verifier(premiere?.corps['branding_settings[display_name]'] === 'Rewayah Academy', 'nom affiche par Stripe : Rewayah Academy');
    const fondPage = await t.page.evaluate(() => {
      const d = document.querySelector('[role=dialog][aria-modal=true]');
      return d ? getComputedStyle(d).backgroundColor : null;
    });
    const hex = premiere?.corps['branding_settings[background_color]'] ?? '';
    const rgb = hex.length === 7 ? `rgb(${parseInt(hex.slice(1, 3), 16)}, ${parseInt(hex.slice(3, 5), 16)}, ${parseInt(hex.slice(5, 7), 16)})` : '?';
    verifier(fondPage === rgb, `fond du formulaire demande a Stripe (${hex}) = fond de la page (${fondPage}) : aucun cadre`);
    const rassurance = await t.page.evaluate(() => document.getElementById('paiement-rassurance')?.textContent ?? null);
    verifier(Boolean(rassurance) && /Stripe/.test(rassurance) && /ne les voit pas et ne les garde pas/.test(rassurance),
      `ligne rassurante sous le formulaire : « ${rassurance} »`);

    // 2. Nouveau depart : revenir sans payer, puis reprendre.
    await revenirSansPayer(t);
    await ouvrirResultat(t, commande);
    await p.capture(t, '1440_clair_retour_reprendre');
    const reprendre = await trouver(t.page, /^Reprendre le paiement/, { delai: 8000, role: 'button' });
    verifier(Boolean(reprendre), 'au retour : « Reprendre le paiement », et aucun ancien formulaire remonte');
    const jAvantReprise = (await journal()).length;
    await reprendre.click();
    await t.page.waitForFunction(() => window.__fauxStripeMonte !== undefined && document.getElementById('faux-formulaire-stripe'), null, { timeout: 20000 });
    await t.page.waitForTimeout(1500);
    await p.capture(t, '1440_clair_formulaire_neuf');
    const jReprise = (await journal()).slice(jAvantReprise);
    const [, sessionB] = commandeDe(f1.id);
    const neuf = await t.page.evaluate(() => document.getElementById('faux-formulaire-stripe')?.getAttribute('data-session'));
    p.dire(`reprise : ${jReprise.map((e) => `${e.methode} ${e.chemin}${e.cle ? ` [${e.cle}]` : ''}`).join(' ; ')}`);
    verifier(jReprise.some((e) => e.chemin === `/v1/checkout/sessions/${sessionA}/expire`)
      && sessionsCreees(jReprise).length === 1 && sessionsCreees(jReprise)[0].cle.endsWith(`-apres-${sessionA}`),
      'nouveau depart : ancienne session expiree, puis une seule nouvelle, avec sa propre cle');
    verifier(sessionB !== sessionA && neuf === sessionB, `la commande porte la nouvelle session (${sessionB}), celle du formulaire monte`);
    verifier(sql(`select count(*) from public.commandes_recharge where titulaire = '${f1.id}'`) === '1', 'une seule commande');

    // 3. Session deja payee au nouveau depart : rien n'est expire ni cree.
    await fetch(`${FAUX}/__payer/${sessionB}`, { method: 'POST' });
    await revenirSansPayer(t);
    await ouvrirResultat(t, commande);
    const jAvantPayee = (await journal()).length;
    await (await trouver(t.page, /^Reprendre le paiement/, { delai: 8000, role: 'button' })).click();
    await t.page.waitForTimeout(4000);
    await activerSemantique(t.page);
    await p.capture(t, '1440_clair_deja_payee');
    const jPayee = (await journal()).slice(jAvantPayee);
    p.dire(`session payee : ${jPayee.map((e) => `${e.methode} ${e.chemin}`).join(' ; ')}`);
    verifier(!jPayee.some((e) => /\/expire$/.test(e.chemin)) && sessionsCreees(jPayee).length === 0
      && commandeDe(f1.id)[1] === sessionB && !(await t.page.evaluate(() => document.getElementById('faux-formulaire-stripe'))),
      'session payee : ni expiration, ni nouvelle session, aucun formulaire ; la page relit l etat');

    // 4. Expiration refusee : aucune nouvelle session, une phrase claire.
    const f2 = amorcerFamille('b');
    const t2 = await p.contexte('tuteur', { vue: { width: 1440, height: 900 } });
    await avecFauxStripeJs(t2);
    await connecter(t2.page, f2.courriel);
    await jusquAuFormulaire(t2);
    const [commande2, sessionC] = commandeDe(f2.id);
    await revenirSansPayer(t2);
    await fetch(`${FAUX}/__refuser_expiration?oui=1`, { method: 'POST' });
    await ouvrirResultat(t2, commande2);
    const jAvantRefus = (await journal()).length;
    await (await trouver(t2.page, /^Reprendre le paiement/, { delai: 8000, role: 'button' })).click();
    await t2.page.waitForTimeout(4000);
    await activerSemantique(t2.page);
    const phrase = await trouverTexte(t2.page, /n'a pas pu être fermé[^|]*/, 8000);
    await p.capture(t2, '1440_clair_expiration_refusee');
    await fetch(`${FAUX}/__refuser_expiration?oui=0`, { method: 'POST' });
    const jRefus = (await journal()).slice(jAvantRefus);
    verifier(Boolean(phrase) && sessionsCreees(jRefus).length === 0 && commandeDe(f2.id)[1] === sessionC,
      `expiration refusee : aucune nouvelle session, la commande garde la sienne, phrase « ${phrase ?? '-'} »`);

    // 5. 390 et theme sombre : la page du formulaire reste claire, sans cadre.
    const f3 = amorcerFamille('c');
    const t3 = await p.contexte('tuteur', { telephone: true, sombre: true });
    await avecFauxStripeJs(t3);
    await connecter(t3.page, f3.courriel);
    await jusquAuFormulaire(t3);
    await p.capture(t3, '390_sombre_formulaire');
    await t3.page.evaluate(() => document.getElementById('paiement-rassurance')?.scrollIntoView({ block: 'center' }));
    await t3.page.waitForTimeout(500);
    await p.capture(t3, '390_sombre_formulaire_rassurance');
    const fond3 = await t3.page.evaluate(() => getComputedStyle(document.querySelector('[role=dialog][aria-modal=true]')).backgroundColor);
    verifier(fond3 === fondPage, `theme sombre : meme fond clair que le formulaire (${fond3})`);
    const [commande3] = commandeDe(f3.id);
    await revenirSansPayer(t3);
    await ouvrirResultat(t3, commande3);
    await p.capture(t3, '390_sombre_retour_reprendre');
    const f4 = amorcerFamille('d');
    const t4 = await p.contexte('tuteur', { telephone: true });
    await avecFauxStripeJs(t4);
    await connecter(t4.page, f4.courriel);
    await jusquAuFormulaire(t4);
    await p.capture(t4, '390_clair_formulaire');
    const t5 = await p.contexte('tuteur', { vue: { width: 1440, height: 900 }, sombre: true });
    const f5 = amorcerFamille('e');
    await avecFauxStripeJs(t5);
    await connecter(t5.page, f5.courriel);
    await jusquAuFormulaire(t5);
    await p.capture(t5, '1440_sombre_formulaire');

    code = await p.fin('vert', `${verifs.length} verifications vertes ; formulaire monte en ${ms} ms`);
  }
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
