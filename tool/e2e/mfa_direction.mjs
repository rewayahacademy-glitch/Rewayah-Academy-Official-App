// MFA-DIRECTION (03/11/2026) : sur la pile LOCALE seulement (jamais un aperçu
// Vercel, jamais la production).
//
//   1. une direction neuve (aucun facteur) ouvre Compte > Sécurité, scanne la
//      clé (lue à l'écran, sinon dans la base locale, et c'est dit), saisit le
//      premier code : « La double vérification est activée » ;
//   2. une nouvelle connexion (aal1) invite un comptable : le serveur refuse
//      (aal2), la feuille « Code de vérification » s'ouvre, le code est
//      accepté, le geste est rejoué et l'invitation est créée ;
//   3. au téléphone, en sombre : Compte > Sécurité dit « activée ».
//
// Usage : node tool/e2e/mfa_direction.mjs
import crypto from 'node:crypto';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, MDP } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
const p = await parcours('MFA-DIRECTION : activer la double vérification, code demandé au geste',
  `mfa-direction/${date}`);
const lus = async (page, n = 80) => (await libelles(page)).slice(0, n).join(' | ');
const un = (q) => sql(q).split('\n')[0].trim();
const manque = [];
const tampon = String(Date.now()).slice(-6);

function totp(cle, decalage = 0) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const c of cle.replace(/[\s=]/g, '').toUpperCase()) bits += alphabet.indexOf(c).toString(2).padStart(5, '0');
  const octets = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
  const compteur = Buffer.alloc(8);
  compteur.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000) + decalage));
  const h = crypto.createHmac('sha1', octets).update(compteur).digest();
  const o = h[h.length - 1] & 0xf;
  return String((h.readUInt32BE(o) & 0x7fffffff) % 1000000).padStart(6, '0');
}

/// Attend le debut d'une nouvelle fenetre de 30 s : un code deja servi n'est
/// pas rejoue par le serveur d'authentification.
async function fenetreSuivante(page) {
  const reste = 30000 - (Date.now() % 30000);
  await page.waitForTimeout(reste + 1500);
}

/// Une direction neuve, sans facteur (SQL local, comme amorcer.sh).
function direction() {
  const courriel = `e2e.mfa.${tampon}@example.com`;
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
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
    values ('${id}', 'E2E-MFA-${tampon}', 'admin', 'Direction', 'Mfa${tampon}', 'active', 'female')`);
  p.dire(`Amorce : direction neuve ${courriel} (${id}), facteurs : ${un(`select count(*) from auth.mfa_factors where user_id = '${id}'`)}`);
  return { id, courriel };
}

async function toucher(a, motif, quoi, options = {}) {
  const e = await trouver(a.page, motif, { delai: 12000, ...options });
  if (!e) { manque.push(`${a.role} : ${quoi} absent`); p.dire(`[${a.role}] ${quoi} ABSENT ; ${await lus(a.page, 60)}`); return false; }
  await amenerEnVue(a.page, e);
  await e.click();
  await a.page.waitForTimeout(options.pause ?? 2500);
  await activerSemantique(a.page);
  return true;
}

async function voir(a, motif, quoi) {
  const tout = (await libelles(a.page)).join(' | ');
  const ok = motif.test(tout);
  p.dire(`[${a.role}] ${quoi} : ${ok ? 'vu' : 'ABSENT'}`);
  if (!ok) { manque.push(`${a.role} : ${quoi}`); p.dire(`   lus : ${tout.slice(0, 1500)}`); }
  return ok;
}

async function saisirCode(a, code) {
  const champ = a.page.locator('input:not([disabled]), textarea:not([disabled])').last();
  await champ.waitFor({ state: 'visible', timeout: 10000 });
  await amenerEnVue(a.page, champ);
  await champ.click(); await a.page.waitForTimeout(500);
  await a.page.keyboard.type(code, { delay: 60 });
}

let code = 1;
try {
  const dir = direction();

  // 1. Activer, au bureau (clair).
  const d = await p.contexte('direction', { vue: { width: 1440, height: 900 } });
  await connecter(d.page, dir.courriel);
  if (await d.page.locator('input[type=password]').count()) await connecter(d.page, dir.courriel);
  await ouvrir(d.page, '/#/compte');
  await d.page.waitForTimeout(3000); await activerSemantique(d.page);
  await voir(d, /Sécurité/, 'rubrique « Sécurité » dans Compte');
  await p.capture(d, '1440_compte_rubrique_securite');
  await toucher(d, /^Sécurité/, '« Sécurité »', { pause: 5000 });
  await voir(d, /Activez la double vérification/, 'enrôlement « Activez la double vérification »');
  await p.capture(d, '1440_enrolement');
  let cle = await d.page.evaluate(() => {
    for (const x of document.querySelectorAll('flt-semantics, [aria-label]')) {
      const t = (x.getAttribute('aria-label') ?? x.textContent ?? '').trim();
      if (/^[A-Z2-7]{16,}$/.test(t)) return t;
    }
    return null;
  });
  if (!cle) {
    cle = un(`select secret from auth.mfa_factors where user_id = '${dir.id}' order by created_at desc limit 1`);
    p.dire('ECART : clé absente de l\'arbre d\'accessibilité ; lue dans la base locale');
  }
  await saisirCode(d, totp(cle));
  await toucher(d, /^Activer la protection$/, '« Activer la protection »', { role: 'button', pause: 5000 });
  await voir(d, /La double vérification est activée/, '« La double vérification est activée »');
  await p.capture(d, '1440_activee');
  const verifie = un(`select count(*) from auth.mfa_factors where user_id = '${dir.id}' and status = 'verified'`);
  p.dire(`Base locale : ${verifie} facteur(s) vérifié(s)`);
  if (verifie !== '1') manque.push(`base : ${verifie} facteurs vérifiés au lieu de 1`);
  await d.ctx.close();

  // 2. Nouvelle connexion (aal1) : inviter un comptable, code demandé au geste.
  const d2 = await p.contexte('direction', { vue: { width: 1440, height: 900 } });
  await connecter(d2.page, dir.courriel);
  if (await d2.page.locator('input[type=password]').count()) await connecter(d2.page, dir.courriel);
  await ouvrir(d2.page, '/#/admin/personnes/invitations');
  await d2.page.waitForTimeout(4000); await activerSemantique(d2.page);
  await toucher(d2, /Un comptable/, 'choix « Un comptable »', { pause: 2000 });
  const courrielCompta = `e2e.compta.${tampon}@example.com`;
  const champ = await trouver(d2.page, /Adresse de courriel du comptable/, { delai: 10000, role: 'textbox' });
  if (!champ) throw new Error(`champ du comptable absent ; ${await lus(d2.page, 60)}`);
  await amenerEnVue(d2.page, champ); await champ.click();
  await d2.page.keyboard.type(courrielCompta, { delay: 20 });
  await toucher(d2, /^Créer l'invitation/, '« Créer l\'invitation »', { role: 'button', pause: 4000 });
  await voir(d2, /Code de vérification/, 'feuille « Code de vérification »');
  await p.capture(d2, '1440_code_demande');
  await fenetreSuivante(d2.page);
  await saisirCode(d2, totp(cle));
  await toucher(d2, /^Confirmer le code et continuer$/, '« Confirmer le code et continuer »', { role: 'button', pause: 6000 });
  await voir(d2, /Invitation créée/, 'invitation créée après le code');
  await p.capture(d2, '1440_geste_accepte');
  const invit = un(`select count(*) from public.invitations_comptable where lower(email) = lower('${courrielCompta}')`);
  p.dire(`Base locale : ${invit} invitation(s) pour ${courrielCompta}`);
  if (invit !== '1') manque.push(`base : ${invit} invitation(s)`);
  await d2.ctx.close();

  // 3. Au téléphone, en sombre : « activée ».
  const t = await p.contexte('direction', { vue: { width: 390, height: 844 }, sombre: true });
  await connecter(t.page, dir.courriel);
  if (await t.page.locator('input[type=password]').count()) await connecter(t.page, dir.courriel);
  await ouvrir(t.page, '/#/compte/securite');
  await t.page.waitForTimeout(4000); await activerSemantique(t.page);
  await voir(t, /La double vérification est activée/, '390 : « activée »');
  await p.capture(t, '390_sombre_activee');
  await t.ctx.close();

  code = await p.fin(manque.length === 0 ? 'vert' : 'rouge', manque.join(' ; '));
} catch (e) {
  p.dire(`ERREUR : ${e.stack ?? e}`);
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
