// Reprise de NOTIFS-L6 (pilote, 02/11/2026), en tete de FN-115c, sur la pile
// LOCALE, lue par le robot. La direction, 50 notifications, a 1440 x 900 et
// 390 x 844.
//
// Ce que le parcours prouve :
//   1. « Nouvelles » montre 10 lignes, puis 10 de plus par « Voir plus » (la
//      source en lit jusqu'a 100 : avant, les 16 non lues s'empilaient) ;
//   2. un seul signe par ligne : le badge ne vit que sur « A faire », avec le
//      mot du geste (« Traiter la contestation ») ; aucune ligne ne dit plus
//      « A lire » ; une non lue dit « non lue » seul.
//
// Prerequis : la migration 20261104700000_notifications_a_faire.sql sur la
// pile LOCALE. Donnees : un compte de direction neuf a chaque passage ; rien
// n'est efface. Aucune migration ici.
// Usage : node tool/e2e/notifs_l6_reprise.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, trouver, ouvrir, activerSemantique, amenerEnVue, taper, sql,
  DEPOT, MDP } from './commun.mjs';

const p = await parcours('NOTIFS-L6, reprise : 10 nouvelles et un seul signe', 'notifs-l6-reprise');
let code = 1;
const n = Date.now() % 1000000;
const FR = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const N = FR.notifications;
const sans = (s) => s.replace(/[⁨⁩]/g, '').replace(/\s+/g, ' ').trim();
const COURRIEL = `e2e-l6r-direction-${n}@example.com`;

function amorcer() {
  const id = sql(`with nouveau as (
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
      'authenticated', '${COURRIEL}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
    returning id),
  ident as (insert into auth.identities (id, user_id, provider_id, identity_data, provider,
      created_at, updated_at, last_sign_in_at)
    select gen_random_uuid(), id, id::text,
      jsonb_build_object('sub', id::text, 'email', '${COURRIEL}', 'email_verified', true),
      'email', now(), now(), now() from nouveau returning user_id)
  select id from nouveau`).split('\n')[0];
  sql(`begin;
    insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
    values ('${id}', 'E2E-L6R-A-${n}', 'admin', 'Direction', 'L6R', 'active', 'female');
    -- 50 : 2 contestations (A faire), 3 demandes du jour (une ligne), 15
    -- autres non lues (15 jours), 30 lues.
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    values ('${id}', 'litige_ouvert', '{"portee": "direction", "commande_id": "l6r-a-${n}"}', '/admin/finance', now() - interval '15 minutes'),
           ('${id}', 'litige_ouvert', '{"portee": "direction", "commande_id": "l6r-b-${n}"}', '/admin/finance', now() - interval '1 day');
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    select '${id}', 'demande_recue', '{}', '/admin/operations/planning', now() - make_interval(mins => 30 + 10 * g)
      from generate_series(0, 2) g;
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    select '${id}', (array['remboursement_effectue', 'titulaire_en_retard', 'classe_validee'])[1 + g % 3],
           '{"portee": "direction"}', '/admin/operations/planning', now() - make_interval(days => 1 + g)
      from generate_series(0, 14) g;
    insert into public.notifications (destinataire, evenement, params, destination, cree_le, lu_le)
    select '${id}', (array['demande_recue', 'classe_validee', 'remboursement_effectue'])[1 + g % 3],
           '{"portee": "direction"}', '/admin/operations/planning', now() - make_interval(days => 20 + g),
           now() - make_interval(days => 20 + g) + interval '1 hour' from generate_series(0, 29) g;
    commit;`);
  return id;
}

async function connecter(page) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    const e = await trouver(page, "J'ai déjà un compte", { delai: 8000 });
    if (e) { await e.click(); await page.waitForTimeout(1200); }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', COURRIEL);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await activerSemantique(page);
}

/// Les noms accessibles des lignes de notification (« ..., le ... à ... »),
/// relevés en descendant toute la page a la molette.
async function lignes(page) {
  const vue = page.viewportSize();
  await page.mouse.move(vue.width * 0.6, vue.height / 2);
  for (let i = 0; i < 25; i++) { await page.mouse.wheel(0, -800); await page.waitForTimeout(50); }
  await page.waitForTimeout(500);
  const vus = new Set();
  for (let i = 0; i < 40; i++) {
    // Les boutons de Flutter portent leur nom dans leur texte, pas dans
    // aria-label.
    const noms = await page.evaluate(() => [...document.querySelectorAll('[role=button]')]
      .map((e) => e.getAttribute('aria-label') || e.textContent || ''));
    for (const nom of noms.map(sans)) if (/, le .* à \d{2}:\d{2}/.test(nom)) vus.add(nom);
    await page.mouse.wheel(0, 350);
    await page.waitForTimeout(150);
  }
  return [...vus];
}

try {
  amorcer();
  p.dire(`Direction ${COURRIEL} : 50 notifications (2 a faire, 18 non lues dont 3 du meme jour, 30 lues)`);
  const verdicts = {};
  for (const [largeur, hauteur] of [[1440, 900], [390, 844]]) {
    const v = {};
    const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
    await connecter(c.page);
    await ouvrir(c.page, '/#/admin/notifications');
    await c.page.waitForTimeout(3000); await activerSemantique(c.page);
    await p.capture(c, `${largeur}_1_tete`);
    const nonLue = sans(N.nonLueSemantique);
    const avant = await lignes(c.page);
    const aFaireAvant = avant.filter((l) => l.includes(sans(N.gesteTraiterContestation)));
    const nouvellesAvant = avant.filter((l) => l.includes(nonLue) && !aFaireAvant.includes(l));
    v.dixNouvelles = nouvellesAvant.length === 10;
    v.badgeDitLeGeste = aFaireAvant.length === 2;
    v.jamaisALire = avant.every((l) => !l.includes(sans(FR.com.socle.composants.badge.aLire)));
    await p.capture(c, `${largeur}_2_bas_des_nouvelles`);
    const plus = await trouver(c.page, new RegExp(`^\\s*${N.voirPlus}\\s*$`), { delai: 4000, role: 'button' });
    if (plus) {
      await amenerEnVue(c.page, plus); await plus.click(); await c.page.waitForTimeout(1500);
      await p.capture(c, `${largeur}_3_voir_plus`);
    }
    const apres = await lignes(c.page);
    const nouvellesApres = apres.filter((l) => l.includes(nonLue)
      && !l.includes(sans(N.gesteTraiterContestation)));
    v.voirPlusDixDePlus = nouvellesApres.length === 16;
    p.dire(`  ${largeur} : a faire ${aFaireAvant.length} ; nouvelles ${nouvellesAvant.length} puis ${nouvellesApres.length}`);
    if (aFaireAvant[0]) p.dire(`  ligne A faire : ${aFaireAvant[0]}`);
    if (nouvellesAvant[0]) p.dire(`  ligne nouvelle : ${nouvellesAvant[0]}`);
    verdicts[largeur] = v;
    await c.ctx.close();
  }
  for (const [k, v] of Object.entries(verdicts)) p.dire(`${k} : ${JSON.stringify(v)}`);
  const rouges = Object.entries(verdicts).flatMap(([k, v]) =>
    Object.entries(v).filter(([, ok]) => ok !== true).map(([x]) => `${k}.${x}`));
  if (rouges.length) throw new Error(`rouge : ${rouges.join(', ')}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
