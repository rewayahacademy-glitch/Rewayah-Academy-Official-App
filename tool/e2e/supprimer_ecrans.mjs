// SUPPRIMER écrans (03/11/2026, PLAN-LOTS §12) : sur la pile LOCALE
// seulement (jamais un aperçu Vercel, jamais la production).
//
//   1. la direction choisit deux comptes dans Comptes, confirme avec leur
//      nombre, lit le résultat ;
//   2. dans Personnes > Suppressions, « Comptes supprimés » : elle restaure
//      l'un d'eux ;
//   3. un tuteur supprime le profil d'un enfant depuis sa fiche ; la
//      direction voit ce retrait, « Un tuteur ».
//
// A 1440 x 900 (clair) et 390 x 844 (sombre). Les RPC de la direction
// exigent la double vérification (aal2), que l'application ne propose pas à
// la direction (blocage signalé le 03/11) : le robot enrôle un facteur TOTP
// par l'API d'authentification LOCALE, vérifie le code, et pose cette
// session dans le navigateur avant le démarrage de l'application. C'est dit
// dans le journal ; rien d'autre n'est contourné.
//
// Usage : node tool/e2e/supprimer_ecrans.mjs
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  amenerEnVue, sql, COMPTES, API, MDP, TRAVAIL } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
const p = await parcours('SUPPRIMER écrans : supprimer, restaurer, profil d\'un enfant',
  `supprimer-ecrans/${date}`);
const statut = Object.fromEntries(fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => {
    const i = l.indexOf('=');
    return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')];
  }));
const CLE = statut.PUBLISHABLE_KEY;
const lus = async (page, n = 80) => (await libelles(page)).slice(0, n).join(' | ');
const un = (q) => sql(q).split('\n')[0].trim();
const manque = [];
const tampon = String(Date.now()).slice(-6);

/// Code TOTP (RFC 6238, SHA-1, 30 s, 6 chiffres) d'une clé en base32.
function totp(cle) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const c of cle.replace(/[\s=]/g, '').toUpperCase()) bits += alphabet.indexOf(c).toString(2).padStart(5, '0');
  const octets = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
  const compteur = Buffer.alloc(8);
  compteur.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30000)));
  const h = crypto.createHmac('sha1', octets).update(compteur).digest();
  const o = h[h.length - 1] & 0xf;
  return String((h.readUInt32BE(o) & 0x7fffffff) % 1000000).padStart(6, '0');
}

async function auth(chemin, corps, jeton) {
  const r = await fetch(`${API}/auth/v1${chemin}`, {
    method: 'POST',
    headers: { apikey: CLE, 'Content-Type': 'application/json', ...(jeton ? { Authorization: `Bearer ${jeton}` } : {}) },
    body: JSON.stringify(corps ?? {}),
  });
  const j = await r.json();
  if (!r.ok) throw new Error(`auth ${chemin} : ${r.status} ${JSON.stringify(j).slice(0, 200)}`);
  return j;
}

/// Une session aal2 de la direction, par l'API locale (enrôlement TOTP).
async function sessionDirectionAal2() {
  const s1 = await auth('/token?grant_type=password', { email: COMPTES.direction, password: MDP });
  const f = await auth('/factors', { factor_type: 'totp', friendly_name: `e2e-${tampon}-${Math.random()}` }, s1.access_token);
  const ch = await auth(`/factors/${f.id}/challenge`, {}, s1.access_token);
  return auth(`/factors/${f.id}/verify`, { challenge_id: ch.id, code: totp(f.totp.secret) }, s1.access_token);
}

/// Une famille admise, par le vrai chemin (inscrire_titulaire puis
/// accepter_admission), avec un mot de passe pour se connecter.
function famille(prenom, enfants) {
  const courriel = `e2e.suppr.${prenom.toLowerCase()}.${tampon}@example.com`;
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
  const nom = `Suppr${tampon}`;
  const apprenants = JSON.stringify(enfants.map((e) => ({ prenom: e, age: 9, genre: 'female',
    niveau: 'lecture_lente', objectif: 'devenir_fluide', moments: ['soir'], langue: 'francais' })));
  sql(`begin;
    select set_config('request.jwt.claim.sub', '${id}', true);
    select set_config('request.jwt.claims', '{"sub":"${id}","role":"authenticated"}', true);
    set local role authenticated;
    select (public.inscrire_titulaire('famille', '${prenom}', '${nom}', 'female', 'Europe/Paris', false,
      '${apprenants}'::jsonb)).id;
    commit;`);
  const direction = un(`select id from auth.users where email = '${COMPTES.direction}'`);
  const [candId, version] = un(`select c.id || '|' || c.version from public.candidatures c where c.profile_id = '${id}'`).split('|');
  sql(`begin;
    select set_config('request.jwt.claim.sub', '${direction}', true);
    select set_config('request.jwt.claims', '{"sub":"${direction}","role":"authenticated","app_metadata":{"role":"admin"}}', true);
    set local role authenticated;
    select public.accepter_admission('${candId}', ${version}, 'e2e-suppr-${tampon}');
    commit;`);
  const enfantsIds = Object.fromEntries(sql(`select e.first_name || '|' || e.id from public.profiles e
      join public.profiles t on t.household_id = e.household_id
     where t.id = '${id}' and e.role = 'student' and e.deleted_at is null`)
    .split('\n').filter(Boolean).map((l) => l.trim().split('|')));
  p.dire(`Amorce : famille ${prenom} ${nom} (${courriel}), enfants ${JSON.stringify(enfantsIds)}`);
  return { id, courriel, nom, enfants: enfantsIds };
}

async function directionAal2(options) {
  const session = await sessionDirectionAal2();
  const a = await p.contexte('direction', options);
  // Le client Supabase du web garde sa session dans le localStorage
  // (shared_preferences : préfixe « flutter. », valeur encodée en JSON).
  await a.ctx.addInitScript((s) => {
    window.localStorage.setItem('flutter.sb-127-auth-token', JSON.stringify(JSON.stringify(s)));
  }, session);
  p.dire(`[direction] session aal2 posée par l'API locale (facteur TOTP enrôlé par le robot)`);
  return a;
}

async function aller(a, chemin, attente = 5000) {
  await ouvrir(a.page, `/#${chemin}`);
  await a.page.waitForTimeout(attente);
  await activerSemantique(a.page);
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

let code = 1;
try {
  const f1 = famille('Karima', ['Adam', 'Sara']);
  const f2 = famille('Samira', ['Lina']);
  const adam = `Adam ${f1.nom}`;
  const sara = `Sara ${f1.nom}`;

  // 1. La direction supprime Adam et Sara, par sélection (1440, clair).
  const d = await directionAal2({ vue: { width: 1440, height: 900 } });
  await aller(d, '/admin/personnes/comptes?vue=eleves');
  await p.capture(d, '1440_comptes_cases');
  await toucher(d, new RegExp(`^Cocher ${adam}`), `case de ${adam}`, { role: 'checkbox', pause: 1200 });
  await toucher(d, new RegExp(`^Cocher ${sara}`), `case de ${sara}`, { role: 'checkbox', pause: 1200 });
  await voir(d, /2 comptes choisis/, 'barre « 2 comptes choisis »');
  await p.capture(d, '1440_comptes_deux_choisis');
  await toucher(d, /^Supprimer 2 comptes$/, '« Supprimer 2 comptes »', { role: 'button' });
  await voir(d, /Supprimer ces 2 comptes/, 'confirmation avec le nombre');
  await p.capture(d, '1440_confirmation');
  // Le bouton destructif de la feuille (le dernier du même nom).
  const boutons = d.page.getByRole('button', { name: /^Supprimer 2 comptes$/ });
  await boutons.last().click();
  await d.page.waitForTimeout(5000); await activerSemantique(d.page);
  await voir(d, /2 comptes sont supprimés/, 'résultat « 2 comptes sont supprimés »');
  await p.capture(d, '1440_resultat');
  const retires = un(`select count(*) from private.retraits_comptes where profile_id in ('${f1.enfants.Adam}', '${f1.enfants.Sara}') and restaure_le is null`);
  p.dire(`Base locale : ${retires} retrait(s) en cours pour Adam et Sara`);
  if (retires !== '2') manque.push(`base : ${retires} retraits au lieu de 2`);

  // 2. Personnes > Suppressions, « Comptes supprimés », restaurer Adam.
  await aller(d, '/admin/personnes/suppressions');
  await toucher(d, /^Comptes supprimés$/, 'section « Comptes supprimés »', { pause: 4000 });
  await voir(d, /sans remettre l.élève dans ses classes/, 'phrase « sans remettre l\'élève dans ses classes »');
  await p.capture(d, '1440_comptes_supprimes');
  await toucher(d, new RegExp(`^Restaurer le compte de ${adam}`), `« Restaurer le compte de ${adam} »`, { role: 'button', pause: 5000 });
  await voir(d, new RegExp(`Le compte de ${adam} est restauré`), 'résultat de la restauration');
  await p.capture(d, '1440_restaure');
  const etat = un(`select account_status || '|' || (deleted_at is null) from public.profiles where id = '${f1.enfants.Adam}'`);
  p.dire(`Base locale : Adam ${etat}`);
  if (!etat.endsWith('|t')) manque.push(`base : Adam pas restauré (${etat})`);
  await d.ctx.close();

  // 3. Le tuteur supprime le profil de Lina (390, sombre), puis à 1440.
  const t = await p.contexte('tuteur', { vue: { width: 390, height: 844 }, sombre: true });
  await connecter(t.page, f2.courriel);
  if (await t.page.locator('input[type=password]').count()) await connecter(t.page, f2.courriel);
  await aller(t, `/tuteur/foyer/${f2.enfants.Lina}`);
  await toucher(t, /^Supprimer le profil de Lina/, '« Supprimer le profil de Lina »', { pause: 2500 });
  await voir(t, /Supprimer le profil de Lina\s*\?/, 'confirmation du tuteur');
  await p.capture(t, '390_sombre_confirmation_tuteur');
  await t.page.getByRole('button', { name: /^Supprimer le profil$/ }).last().click();
  await t.page.waitForTimeout(6000); await activerSemantique(t.page);
  await p.capture(t, '390_sombre_foyer_apres');
  const lina = un(`select (deleted_at is not null) from public.profiles where id = '${f2.enfants.Lina}'`);
  p.dire(`Base locale : Lina supprimée = ${lina}`);
  if (lina !== 't') manque.push('base : Lina pas supprimée');
  await t.ctx.close();

  // 4. La direction, au téléphone en sombre : la sélection et le retrait du tuteur.
  const d2 = await directionAal2({ vue: { width: 390, height: 844 }, sombre: true });
  await aller(d2, '/admin/personnes/comptes?vue=eleves');
  await toucher(d2, new RegExp(`^Cocher ${adam}`), `case de ${adam} (390)`, { role: 'checkbox', pause: 1500 });
  await voir(d2, /1 compte choisi/, 'barre « 1 compte choisi » (390)');
  await p.capture(d2, '390_sombre_comptes_un_choisi');
  await aller(d2, '/admin/personnes/suppressions');
  await toucher(d2, /^Comptes supprimés$/, 'section « Comptes supprimés » (390)', { pause: 4000 });
  await voir(d2, /Un tuteur/, 'retrait de Lina « Un tuteur »');
  await p.capture(d2, '390_sombre_comptes_supprimes');
  await d2.ctx.close();

  code = await p.fin(manque.length === 0 ? 'vert' : 'rouge', manque.join(' ; '));
} catch (e) {
  p.dire(`ERREUR : ${e.stack ?? e}`);
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
