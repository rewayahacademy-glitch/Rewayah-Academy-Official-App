// RECHARGE-CARTE (03/11/2026), banc LOCAL seulement (G5, B7), contre le FAUX
// Stripe de banc (`tool/e2e/faux_stripe.mjs`, port 12111) : aucune cle Stripe,
// meme de test, aucune carte. Stripe.js est remplace dans le navigateur par le
// meme faux formulaire que `pay_ux.mjs`.
//
// Ce que le parcours prouve : pendant une commande engagee (« Payer » touche,
// commande creee, formulaire monte), la carte du profil coche dit toujours le
// montant retenu, le meme que sa ligne au recapitulatif du serveur ; plus de
// « 0 $ » attenue. A 390 et a 1440.
//
// Usage : node tool/e2e/recharge_carte.mjs
import { parcours, trouver, libelles, activerSemantique, amenerEnVue, sql, MDP, connecter }
  from './commun.mjs';

const FAUX = 'http://127.0.0.1:12111';
const tampon = new Date().toISOString().slice(5, 19).replace(/[-T:]/g, '');
const p = await parcours('RECHARGE-CARTE : la carte et le recapitulatif concordent pendant une commande engagee', 'RECHARGE-CARTE');
const manque = [];
const un = (requete) => sql(requete).split('\n')[0].trim();

// Le faux Stripe.js (copie de pay_ux.mjs, sans le delai de mesure).
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
              d.style.cssText = 'min-height:360px;border-radius:12px;padding:24px;box-sizing:border-box;font:15px system-ui;color:#1a1a1a;background:#fff';
              d.textContent = 'Faux formulaire de banc (le vrai est celui de Stripe)';
              el.appendChild(d);
              window.__fauxStripeMonte = performance.now();
            },
            destroy: function () { var x = document.getElementById('faux-formulaire-stripe'); if (x) x.remove(); },
          };
        });
      },
    };
  };
})();`;

// Une famille de test (base LOCALE) : un titulaire, un enfant dans une classe.
let classe = null;
function classeDuPassage() {
  if (classe) return classe;
  const prof = un(`select id from public.profiles where role = 'teacher' and account_status = 'active' order by created_at limit 1`);
  for (let essai = 0; essai < 20 && !classe; essai++) {
    const jour = 1 + Math.floor(Math.random() * 7);
    const heure = 6 + Math.floor(Math.random() * 15);
    try {
      classe = un(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
         values ('${prof}', 'enfant', 5, 'E2E RechargeCarte ${tampon}', ${jour}, ${heure}, 'Europe/Paris') returning id`);
    } catch { /* creneau pris : un autre */ }
  }
  if (!classe) throw new Error('aucun creneau libre pour la classe de test');
  return classe;
}
function amorcerFamille(suffixe) {
  const courriel = `e2e-rcarte-${tampon}-${suffixe}@example.com`;
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
  sql(`insert into auth.users (id, email) values ('${enfant}', 'e2e-rcarte-enfant-${tampon}-${suffixe}@example.com')`);
  sql(`insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
       ('${id}', 'E2E-RCARTE-T-${tampon}${suffixe}', 'guardian', '${foyer}', 'E2E Parent', 'Carte', 'active', 'female'),
       ('${enfant}', 'E2E-RCARTE-E-${tampon}${suffixe}', 'student', '${foyer}', 'Hamza', 'Carte', 'active', 'male')`);
  sql(`update public.households set primary_guardian_id = '${id}' where id = '${foyer}'`);
  sql(`insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${enfant}', 'minor', 'standard')`);
  sql(`insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${classeDuPassage()}', '${enfant}', now() - interval '20 days')`);
  return { courriel, id };
}

/// Le montant lu sur la carte de Hamza (le noeud nomme « Montant pour Hamza »)
/// et sa ligne au recapitulatif.
async function lire(a) {
  const l = await libelles(a.page);
  const carte = l.find((x) => /Montant pour Hamza|Montant de Hamza|Hamza.*\$/.test(x)) ?? null;
  const recap = l.filter((x) => /Hamza/.test(x) && /\$/.test(x));
  return { carte, recap, tout: l.filter((x) => /\$/.test(x)).slice(0, 12) };
}

async function passage(taille, nom) {
  const f = amorcerFamille(nom);
  const a = await p.contexte(nom, taille === 390 ? { telephone: true } : { vue: { width: 1440, height: 900 } });
  await a.ctx.route('https://js.stripe.com/**', (route) =>
    route.fulfill({ status: 200, contentType: 'text/javascript', body: FAUX_STRIPE_JS }));
  await connecter(a.page, f.courriel);
  if (await a.page.locator('input[type=password]').count()) await connecter(a.page, f.courriel);
  await a.page.evaluate(() => { location.hash = '#/tuteur/foyer/recharge'; });
  await a.page.waitForTimeout(4000);
  await activerSemantique(a.page);
  const cocher = a.page.getByRole('checkbox');
  if (await cocher.count() && (await cocher.first().getAttribute('aria-checked')) !== 'true') await cocher.first().click();
  await a.page.waitForTimeout(1500);
  await activerSemantique(a.page);
  const avant = await lire(a);
  p.dire(`[${taille}] avant « Payer » : carte ${avant.carte} ; montants vus : ${avant.tout.join(' | ')}`);
  await p.capture(a, `${taille}_avant_payer`);
  const payer = await trouver(a.page, /^Payer/, { delai: 15000, role: 'button' });
  if (!payer) { manque.push(`${taille} : « Payer » absent`); await a.ctx.close(); return; }
  await amenerEnVue(a.page, payer);
  await payer.click({ timeout: 5000 });
  try {
    await a.page.waitForFunction(() => window.__fauxStripeMonte !== undefined, null, { timeout: 30000 });
  } catch { manque.push(`${taille} : le formulaire (faux Stripe) ne se monte pas`); }
  await a.page.waitForTimeout(2000);
  const commande = un(`select etat from public.commandes_recharge where titulaire = '${f.id}' order by cree_le desc limit 1`);
  p.dire(`[${taille}] commande en base : ${commande || 'aucune'}`);
  if (!commande) manque.push(`${taille} : aucune commande engagee`);
  await activerSemantique(a.page);
  const apres = await lire(a);
  p.dire(`[${taille}] commande engagee : carte ${apres.carte} ; montants vus : ${apres.tout.join(' | ')}`);
  await p.capture(a, `${taille}_commande_engagee`);
  // La carte dit le meme montant qu'avant « Payer », jamais « 0 $ ».
  const montant = (x) => (x?.match(/\d+(?:[.,]\d+)?\s?\$/) ?? [null])[0];
  if (!apres.carte || /\b0\s?\$/.test(apres.carte) || montant(apres.carte) !== montant(avant.carte)) {
    manque.push(`${taille} : carte « ${apres.carte} » pendant la commande (avant : « ${avant.carte} »)`);
  }
  await a.ctx.close();
}

let code = 1;
try {
  await passage(390, 'tel');
  await passage(1440, 'bureau');
  code = manque.length
    ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
    : await p.fin('vert', 'commande engagee : la carte du profil coche garde son montant, comme le recapitulatif ; 390 et 1440');
} catch (e) {
  code = await p.fin('rouge', `erreur : ${e.message}`);
}
process.exit(code);
