// FN-102 (lot 13 FN-DIVERS, 06/11/2026) : le piege 1.13 (« signature au nom
// d'un autre », 31/10) rejoue sur l'ecran actuel. Le parcours candidat de
// pieges_1.mjs ne suit plus l'ecran d'inscription (lot 1) : la candidate est
// amorcee en SQL LOCAL (enseignante pending_kyc, nom « E2E Amina Benali »),
// connectee par mot de passe, puis menee a « Nos conditions ».
// Attendu : le nom du compte en lecture seule ; une saisie d'un autre nom
// n'y entre pas ; la signature enregistree en base porte le nom du compte.
// Usage : node tool/e2e/fn102_signature.mjs   (pile locale)
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { parcours, connecter, ouvrir, cliquer, trouverTexte, libelles, sql, DEPOT, TRAVAIL } from './commun.mjs';

const p = await parcours('FN-102 : signature au nom du compte', 'fn-divers/robot-fn102');
const courriel = `e2e-fn102-${Date.now().toString(36)}@example.com`;
// Le meme utilisateur qu'amorcer.sh, en SQL local (aucune cle de service).
execFileSync('bash', ['-c', `
  set -euo pipefail
  DB_URL=$(grep '^DB_URL=' "${TRAVAIL}/statut.env" | cut -d'"' -f2)
  case "$DB_URL" in postgresql://*@127.0.0.1:*) ;; *) echo "refus : base non locale"; exit 1 ;; esac
  psql "$DB_URL" -v ON_ERROR_STOP=1 -q -v c="${courriel}" <<'SQL'
with u as (
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
    email_change_token_new, email_change)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated', :'c',
    extensions.crypt('E2E-motdepasse-2026', extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
  returning id
), i as (
  insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
  select gen_random_uuid(), u.id, u.id::text, jsonb_build_object('sub', u.id::text, 'email', :'c', 'email_verified', true),
    'email', now(), now(), now() from u returning user_id
), pr as (
  insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  select user_id, 'E2E-FN102-' || substr(user_id::text, 1, 8), 'teacher', 'E2E Amina', 'Benali', 'pending_kyc', 'female' from i
  returning id
)
insert into public.teacher_profiles (profile_id, country, languages, kyc_status)
select id, 'FR', '{fr}', 'pending' from pr;
SQL
`], { stdio: 'inherit' });
void path; void DEPOT;

const r = [];
// 1440 d'abord, sans signer ; puis 390, qui signe.
for (const vue of [{ nom: '1440', vue: { width: 1440, height: 900 } }, { nom: '390', telephone: true }]) {
  const c = await p.contexte(`candidate-${vue.nom}`, vue);
  await connecter(c.page, courriel);
  await ouvrir(c.page, '/#/attente/accords');
  const champ = c.page.locator('input[aria-label^="Nom du signataire"], textarea[aria-label^="Nom du signataire"]').first();
  if (!(await champ.count())) {
    p.dire(`  ${vue.nom} : champ introuvable ; ${(await libelles(c.page)).slice(0, 25).join(' | ')}`);
    r.push('ROUGE champ introuvable'); await c.ctx.close(); continue;
  }
  // Le nom du compte arrive par une lecture : on l'attend (10 s au plus).
  let avant = '';
  for (let k = 0; k < 20 && !avant; k++) { avant = await champ.inputValue(); if (!avant) await c.page.waitForTimeout(500); }
  await champ.click({ force: true });
  await c.page.keyboard.press('Control+A');
  await c.page.keyboard.type("Quelqu'un d'autre");
  const apres = await champ.inputValue();
  await p.capture(c, `fn102_${vue.nom}_conditions`);
  p.dire(`  ${vue.nom} : champ avant « ${avant} », apres saisie « ${apres} »`);
  if (vue.nom === '390') {
    const cases = c.page.getByRole('checkbox');
    for (let i = 0; i < await cases.count(); i++) {
      if ((await cases.nth(i).getAttribute('aria-checked')) !== 'true') { await cases.nth(i).click(); await c.page.waitForTimeout(300); }
    }
    await cliquer(c.page, /^Suivant$/, { pause: 4000 });
    await p.capture(c, `fn102_${vue.nom}_apres_suivant`);
    const erreur = await trouverTexte(c.page, /(n'a pas encore de nom|ne s'affiche pas|n'a pas été)[^|]*/, 1500);
    if (erreur) p.dire(`  message : ${erreur}`);
  }
  // Flutter Web ne cree le vrai champ de saisie qu'au focus : la valeur se
  // lit apres le clic. Le nom du compte y est, et la frappe n'y est pas entree.
  r.push(`${vue.nom} : ${apres === 'E2E Amina Benali' ? 'lecture seule, nom du compte' : 'ROUGE'} (apres saisie de « Quelqu'un d'autre » : « ${apres} »)`);
  await c.ctx.close();
}
const signe = sql(`select ca.signer_name from public.contract_acceptances ca join auth.users u on u.id = ca.profile_id
  where u.email = '${courriel}' and ca.contract_kind = 'teacher_nda' order by ca.accepted_at desc limit 1`);
r.push(`signature en base : « ${signe || 'aucune'} »`);
if (signe !== 'E2E Amina Benali') r.push('ROUGE');
process.exit(await p.fin(r.some((x) => /ROUGE/.test(x)) ? 'rouge' : 'vert', r.join(' ; ')));
