// NOTIFS-L6 (pilote, 02/11/2026 ; demande du directeur du 02/11 : « pour
// qu'il tombe sur la priorite ») : la page Notifications, sur la pile LOCALE,
// lue par le robot.
//
// Ce que le parcours prouve, a 1440 x 900 et 390 x 844, en francais et en
// arabe, pour une famille (30 notifications) et la direction (50) :
//   * trois sections, dans l'ordre : « A faire », « Nouvelles », « Plus
//     anciennes » (repliees sous les priorites) ;
//   * ouvrir la page ne marque rien comme lu (compte en base, avant et apres) ;
//   * trois relances de paiement du meme jour tiennent en une ligne
//     (« 3 fois ») ;
//   * « Voir plus » demande au serveur la page suivante des lues
//     (`cree_le=lt.` et `limit=20`), jamais une lecture sans fin ;
//   * « Ecarter » (menu « ... ») pose ecartee_le en base et retire la ligne ;
//   * « Tout marquer comme lu » vide « Nouvelles » ; « A faire » reste, lue.
//
// Prerequis : la migration 20261104500000_notifications_a_faire.sql appliquee
// sur la pile LOCALE. Donnees de test : deux comptes neufs a chaque passage
// (une famille, une direction) ; rien n'est efface. Aucune migration ici.
// Usage : node tool/e2e/notifs_l6.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, trouver, libelles, ouvrir, activerSemantique, amenerEnVue,
  taper, sql, DEPOT, MDP } from './commun.mjs';

const p = await parcours('NOTIFS-L6 : la page Notifications, priorite d abord', 'notifs-l6');
let code = 1;
const n = Date.now() % 1000000;
const I = Object.fromEntries(['fr', 'ar'].map((l) => [l,
  JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${l}.i18n.json`), 'utf8'))]));
const sans = (s) => s.replace(/[⁨⁩]/g, '');
const fois = (l, k) => sans(l === 'fr' ? I.fr.notifications.repetitions.other
  : I.ar.notifications.repetitions.few).replace('{n}', String(k));

function creerCompte(courriel) {
  return sql(`with nouveau as (
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
      'authenticated', '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
    returning id),
  ident as (insert into auth.identities (id, user_id, provider_id, identity_data, provider,
      created_at, updated_at, last_sign_in_at)
    select gen_random_uuid(), id, id::text,
      jsonb_build_object('sub', id::text, 'email', '${courriel}', 'email_verified', true),
      'email', now(), now(), now() from nouveau returning user_id)
  select id from nouveau`).split('\n')[0];
}

const COMPTE = { famille: `e2e-l6-famille-${n}@example.com`, direction: `e2e-l6-direction-${n}@example.com` };
const ID = {};

/// Les notifications de test, inserees comme le serveur les ecrit : le
/// declencheur de la migration pose geste_requis.
function amorcer() {
  ID.famille = creerCompte(COMPTE.famille);
  ID.direction = creerCompte(COMPTE.direction);
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.famille}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name,
                                 account_status, gender)
    values ('${ID.famille}', 'E2E-L6-T-${n}', 'guardian', '${ID.famille}', 'Amina', 'FamilleL6',
            'active', 'female'),
           ('${ID.direction}', 'E2E-L6-A-${n}', 'admin', null, 'Direction', 'L6', 'active', 'female');
    update public.households set primary_guardian_id = '${ID.famille}' where id = '${ID.famille}';
    commit;`);
  const F = ID.famille; const A = ID.direction;
  sql(`begin;
    -- Famille, 30 : 3 relances (A faire, un seul jour), 4 nouvelles, 23 lues.
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    select '${F}', 'paiement_relance', '{"portee": "foyer"}', '/tuteur/foyer/recharge',
           now() - make_interval(mins => 5 + 20 * g) from generate_series(0, 2) g;
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    values ('${F}', 'classe_validee', '{}', '/tuteur/demandes', now() - interval '2 hours'),
           ('${F}', 'seance_deplacee', '{"portee": "foyer"}', '/tuteur', now() - interval '1 day'),
           ('${F}', 'enseignant_affecte', '{"portee": "foyer"}', '/tuteur', now() - interval '2 days'),
           ('${F}', 'classe_creee', '{"portee": "foyer"}', '/tuteur', now() - interval '3 days');
    insert into public.notifications (destinataire, evenement, params, destination, cree_le, lu_le)
    select '${F}', (array['classe_creee', 'seance_deplacee', 'classe_validee', 'eleve_inscrit'])[1 + g % 4],
           '{"portee": "foyer"}', '/tuteur', now() - make_interval(days => 4 + g),
           now() - make_interval(days => 4 + g) + interval '1 hour' from generate_series(0, 22) g;
    -- Direction, 50 : 2 contestations (A faire), 8 nouvelles dont 3 demandes
    -- du meme jour, 40 lues.
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    values ('${A}', 'litige_ouvert', '{"portee": "direction", "commande_id": "l6-a-${n}"}', '/admin/finance', now() - interval '15 minutes'),
           ('${A}', 'litige_ouvert', '{"portee": "direction", "commande_id": "l6-b-${n}"}', '/admin/finance', now() - interval '1 day');
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    select '${A}', 'demande_recue', '{}', '/admin/operations/planning', now() - make_interval(mins => 30 + 10 * g)
      from generate_series(0, 2) g;
    insert into public.notifications (destinataire, evenement, params, destination, cree_le)
    select '${A}', (array['remboursement_effectue', 'titulaire_en_retard', 'classe_validee'])[1 + g % 3],
           '{"portee": "direction"}', '/admin/operations/planning', now() - make_interval(days => 1 + g) from generate_series(0, 4) g;
    insert into public.notifications (destinataire, evenement, params, destination, cree_le, lu_le)
    select '${A}', (array['demande_recue', 'classe_validee', 'remboursement_effectue', 'titulaire_en_retard'])[1 + g % 4],
           '{"portee": "direction"}', '/admin/operations/planning', now() - make_interval(days => 6 + g),
           now() - make_interval(days => 6 + g) + interval '1 hour' from generate_series(0, 39) g;
    commit;`);
}

const compter = (qui, ou = 'true') =>
  Number(sql(`select count(*) from public.notifications where destinataire = '${ID[qui]}' and (${ou})`));
const nonLues = (qui) => compter(qui, 'lu_le is null');
const aFaire = (qui) => compter(qui, 'geste_requis and ecartee_le is null and geste_fait_le is null');

async function connecterEn(page, courriel, langue) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    const e = await trouver(page, langue === 'fr' ? "J'ai déjà un compte" : I.ar.connexion.modeConnexion, { delai: 8000 });
    if (e) { await e.click(); await page.waitForTimeout(1200); }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await activerSemantique(page);
}

/// L'ordonnee du premier noeud visible qui porte ce texte, ou null.
/// Les titres de section sont des en-tetes (`Semantics(header: true)`) ; le
/// selecteur « Toutes / A faire / Non lues » porte les memes mots, en haut.
async function hauteur(page, texte, role = 'heading') {
  const e = await trouver(page, new RegExp(`^\\s*${texte}\\s*$`), { delai: 3000, role });
  return e ? (await e.boundingBox())?.y ?? null : null;
}

/// Revient en haut de la page (molette, comme un utilisateur).
async function enHaut(page) {
  const vue = page.viewportSize();
  await page.mouse.move(vue.width * 0.6, vue.height / 2);
  for (let i = 0; i < 25; i++) { await page.mouse.wheel(0, -600); await page.waitForTimeout(80); }
  await page.waitForTimeout(600);
}

/// Un passage : un compte, une largeur, une langue.
async function passage(qui, largeur, langue, { ecarter = false, toutLire = false } = {}) {
  const N = I[langue].notifications;
  const etiquette = `${largeur}_${langue}`;
  const c = await p.contexte(qui, {
    vue: { width: largeur, height: largeur > 800 ? 900 : 844 },
    langue: langue === 'fr' ? 'fr-FR' : 'ar-SA',
  });
  const pages = [];
  c.page.on('request', (r) => {
    const u = r.url();
    if (r.method() === 'GET' && u.includes('/rest/v1/notifications') && u.includes('cree_le=lt.')) pages.push(u);
  });
  const v = {};
  await connecterEn(c.page, COMPTE[qui], langue);
  const avant = nonLues(qui);
  await ouvrir(c.page, qui === 'famille' ? '/#/tuteur/notifications' : '/#/admin/notifications');
  await c.page.waitForTimeout(3000); await activerSemantique(c.page);
  const lus = sans((await libelles(c.page)).join(' | '));
  v.ouvertureNeMarqueRien = nonLues(qui) === avant;
  const yA = await hauteur(c.page, N.sectionAFaire);
  const yN = await hauteur(c.page, N.sectionNouvelles);
  const yP = await hauteur(c.page, N.sectionPlusAnciennes, 'button');
  v.ordreDesSections = yA != null && yN != null && yP != null && yA < yN && yN < yP;
  v.regroupe = lus.includes(fois(langue, 3));
  await p.capture(c, `${etiquette}_1_tete`);
  p.dire(`  ${qui} ${etiquette} : non lues ${avant} ; a faire ${aFaire(qui)} ; sections ${yA}/${yN}/${yP}`);

  // « Plus anciennes », repliees : on ouvre.
  const replie = await trouver(c.page, N.sectionPlusAnciennes, { delai: 3000 });
  if (replie) {
    v.replieesParDefaut = (await replie.getAttribute('aria-expanded')) === 'false';
    await amenerEnVue(c.page, replie); await replie.click(); await c.page.waitForTimeout(1200);
    await p.capture(c, `${etiquette}_2_anciennes`);
  }
  // « Voir plus » : la page suivante, au serveur.
  const plus = await trouver(c.page, N.voirPlus, { delai: 4000 });
  if (plus) {
    await amenerEnVue(c.page, plus);
    await plus.click(); await c.page.waitForTimeout(2500);
    v.voirPlusAuServeur = pages.length >= 1 && pages.every((u) => /limit=20\b/.test(u));
    await p.capture(c, `${etiquette}_3_voir_plus`);
  } else {
    v.voirPlusAuServeur = false;
  }

  if (ecarter) {
    const avantEcart = aFaire(qui);
    const titre = sans(qui === 'famille' ? N.evenements.paiementRelance : N.evenements.litigeOuvertDirection);
    const objet = sans(I[langue].commun.listes.actionsDe).replace('{objet}', titre);
    const menu = await trouver(c.page, objet, { delai: 5000 });
    if (menu) {
      await amenerEnVue(c.page, menu); await menu.click(); await c.page.waitForTimeout(900);
      await p.capture(c, `${etiquette}_4_menu`);
      const choix = await trouver(c.page, N.ecarter, { delai: 4000, role: 'menuitem' })
        ?? await trouver(c.page, N.ecarter, { delai: 2000 });
      if (choix) { await choix.click(); await c.page.waitForTimeout(2500); }
    }
    v.ecarterEnBase = aFaire(qui) === avantEcart - 1
      && compter(qui, 'ecartee_le is not null') === 1;
    await p.capture(c, `${etiquette}_5_apres_ecart`);
  }

  if (toutLire) {
    const avantAFaire = aFaire(qui);
    await enHaut(c.page);
    const bouton = await trouver(c.page, N.toutMarquerLu, { delai: 5000 });
    if (bouton) {
      await amenerEnVue(c.page, bouton); await bouton.click(); await c.page.waitForTimeout(2500);
    }
    await enHaut(c.page);
    await activerSemantique(c.page);
    v.toutLu = nonLues(qui) === 0;
    v.aFaireResteApresLecture = aFaire(qui) === avantAFaire && avantAFaire > 0
      && (await hauteur(c.page, N.sectionAFaire)) != null
      && (await hauteur(c.page, N.sectionNouvelles)) == null;
    await p.capture(c, `${etiquette}_6_tout_lu`);
  }
  await c.ctx.close();
  return v;
}

try {
  amorcer();
  p.dire(`Famille ${COMPTE.famille} : ${compter('famille')} notifications, ${aFaire('famille')} a faire, ${nonLues('famille')} non lues`);
  p.dire(`Direction ${COMPTE.direction} : ${compter('direction')} notifications, ${aFaire('direction')} a faire, ${nonLues('direction')} non lues`);
  const verdicts = {
    famille_1440_fr: await passage('famille', 1440, 'fr'),
    famille_390_fr: await passage('famille', 390, 'fr'),
    famille_390_ar: await passage('famille', 390, 'ar'),
    famille_1440_ar: await passage('famille', 1440, 'ar', { toutLire: true }),
    direction_1440_fr: await passage('direction', 1440, 'fr'),
    direction_390_fr: await passage('direction', 390, 'fr', { ecarter: true }),
    direction_1440_ar: await passage('direction', 1440, 'ar'),
  };
  for (const [k, v] of Object.entries(verdicts)) p.dire(`${k} : ${JSON.stringify(v)}`);
  const rouges = Object.entries(verdicts).flatMap(([k, v]) =>
    Object.entries(v).filter(([, ok]) => ok !== true).map(([c]) => `${k}.${c}`));
  if (rouges.length) throw new Error(`rouge : ${rouges.join(', ')}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
