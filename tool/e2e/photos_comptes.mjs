// Constats du 05/11/2026 (pilote et garde-cap), demande du directeur du 04/11
// (« elle ne s'affiche pas partout, elle ne synchronise pas ») : au
// telephone, l'envoi de la photo d'un enfant echouait apres un ecran du
// tuteur, et la direction ne voyait aucune photo dans Comptes. Pile LOCALE
// seulement (jamais un apercu Vercel, jamais la production).
//
// A 390, dans le meme document :
//   1. le tuteur ouvre son Accueil, puis Suivi, puis la fiche de Yanis
//      (Informations), et envoie sa photo : la base porte la cle ;
//   2. pendant ces ecrans, `mon_horloge` n'est lu qu'une fois (la boucle
//      corrigee saturait le navigateur) ;
//   3. la direction ouvre Comptes, vue Eleves, cherche Yanis : sa carte
//      montre la photo (URL signee du seau avatars servie).
// Captures : docs/current/captures/E2E/PHOTOS-COMPTES/<date>/.
//
// Usage : node tool/e2e/photos_comptes.mjs
import path from 'node:path';
import { parcours, connecter, trouver, libelles, activerSemantique, amenerEnVue,
  sql, COMPTES, MDP, DEPOT } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
const p = await parcours('Photos : envoi au telephone et Comptes de la direction (390)',
  `PHOTOS-COMPTES/${date}`);
const FICHIER = path.join(DEPOT, 'tool/e2e/portrait_factice.png');
const vue = { width: 390, height: 844 };
const n = Date.now() % 1000000;
const verdicts = {};
const lus = async (page, k = 60) => (await libelles(page)).slice(0, k).join(' | ');

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

async function vers(page, chemin, attente = 5000) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(attente);
  await activerSemantique(page);
}

async function toucher(page, motif, quoi, { delai = 10000, role } = {}) {
  const e = await trouver(page, motif, { delai, role });
  if (!e) throw new Error(`${quoi} absent ; ${await lus(page)}`);
  await amenerEnVue(page, e);
  await e.click();
  await page.waitForTimeout(2500);
  await activerSemantique(page);
}

let code = 1;
try {
  const courriel = `e2e-phc-${n}@example.com`;
  const tuteur = creerCompte(courriel);
  const yanis = creerCompte(`e2e-phc-e-${n}@example.com`);
  const nom = `Photo${n}`;
  sql(`begin;
    insert into public.households (id, timezone) values ('${tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${tuteur}', 'E2E-PHC-T-${n}', 'guardian', '${tuteur}', 'Nadia', '${nom}', 'active', 'female'),
      ('${yanis}', 'E2E-PHC-E-${n}', 'student', '${tuteur}', 'Yanis', '${nom}', 'active', 'male');
    insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${yanis}', 'minor', 'child');
    update public.households set primary_guardian_id = '${tuteur}' where id = '${tuteur}';
    commit;`);
  p.dire(`Amorce : tuteur ${courriel}, Yanis ${yanis} (${nom})`);

  // 1-2. Le tuteur, dans un seul document.
  const t = await p.contexte('tuteur', { vue });
  let horloge = 0;
  const envois = [];
  t.page.on('request', (r) => {
    const u = r.url();
    if (u.includes('rpc/mon_horloge')) horloge += 1;
    if (u.includes('/storage/v1/object/avatars/') || u.includes('rpc/poser_photo_eleve')) {
      envois.push(`${r.method()} ${u.replace(/\?.*$/, '').split('/v1/')[1]}`);
    }
  });
  await connecter(t.page, courriel);
  await vers(t.page, '/tuteur', 6000);
  await p.capture(t, '1_accueil');
  await vers(t.page, '/tuteur/suivi', 5000);
  await p.capture(t, '2_suivi');
  await vers(t.page, `/tuteur/foyer/${yanis}/informations`, 5000);
  t.page.once('filechooser', (fc) => fc.setFiles(FICHIER));
  await toucher(t.page, /^Choisir une photo/, '« Choisir une photo » (Yanis)');
  await p.capture(t, '3_apercu');
  await toucher(t.page, /^Envoyer cette photo/, '« Envoyer cette photo »', { role: 'button' });
  await t.page.waitForTimeout(4000); await activerSemantique(t.page);
  const ecran = await lus(t.page, 80);
  const cle = sql(`select coalesce(avatar_storage_key, '') from public.student_profiles where profile_id = '${yanis}'`);
  p.dire(`Envoi : requetes ${JSON.stringify(envois)} ; cle en base « ${cle} »`);
  verdicts.envoiSansEchec = !/pas pu être envoyée/.test(ecran);
  verdicts.cleEnBase = cle.startsWith(`${yanis}/`);
  verdicts.horlogeLueUneFois = horloge <= 2;
  p.dire(`mon_horloge : ${horloge} appel(s) pendant Accueil, Suivi et la fiche`);
  await p.capture(t, '4_photo_envoyee');

  // 3. La direction, Comptes, vue Eleves.
  const d = await p.contexte('direction', { vue });
  const signees = [];
  d.page.on('response', (r) => {
    if (r.status() === 200 && r.url().includes('/storage/v1/object/sign/avatars/')) signees.push(r.url());
  });
  await connecter(d.page, COMPTES.direction);
  await vers(d.page, `/admin/personnes/comptes?vue=eleves&q=${nom}`, 8000);
  const carte = await trouver(d.page, new RegExp(`Yanis ${nom}`), { delai: 10000 });
  if (carte) await amenerEnVue(d.page, carte);
  const fin = Date.now() + 20000;
  while (Date.now() < fin && !signees.some((u) => u.includes(cle.split('/').pop()))) {
    await d.page.waitForTimeout(500);
  }
  verdicts.carteTrouvee = carte !== null;
  verdicts.photoDansComptes = signees.some((u) => u.includes(cle.split('/').pop()));
  p.dire(`Comptes : URL signees ${JSON.stringify(signees.map((u) => u.replace(/\?.*$/, '').split('/sign/')[1]))} ; ecran ${await lus(d.page, 30)}`);
  await p.capture(d, '5_comptes_photo');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
