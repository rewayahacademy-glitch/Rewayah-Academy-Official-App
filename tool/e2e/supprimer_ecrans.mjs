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
  // Un facteur deja verifie (passage precedent, base LOCALE) sert de nouveau :
  // en enroler un second demanderait deja aal2.
  const deja = un(`select f.id || '|' || f.secret from auth.mfa_factors f join auth.users u on u.id = f.user_id
    where u.email = '${COMPTES.direction}' and f.factor_type = 'totp' and f.status = 'verified'
    order by f.created_at limit 1`);
  let id; let secret;
  if (deja) {
    [id, secret] = deja.split('|');
  } else {
    const f = await auth('/factors', { factor_type: 'totp', friendly_name: `e2e-${tampon}` }, s1.access_token);
    id = f.id; secret = f.totp.secret;
  }
  const ch = await auth(`/factors/${id}/challenge`, {}, s1.access_token);
  return auth(`/factors/${id}/verify`, { challenge_id: ch.id, code: totp(secret) }, s1.access_token);
}

/// Une famille en SQL local (comme fn115c_rembourser.mjs) : un tuteur qui se
/// connecte par mot de passe, ses enfants mineurs, actifs.
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
  const ids = {};
  let lignes = `insert into public.households (id, timezone) values ('${id}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${id}', 'E2E-SUP-${prenom.slice(0, 3).toUpperCase()}-${tampon}', 'guardian', '${id}', '${prenom}', '${nom}', 'active', 'female');
    update public.households set primary_guardian_id = '${id}' where id = '${id}';`;
  for (const e of enfants) {
    const eid = un('select gen_random_uuid()');
    ids[e] = eid;
    lignes += `insert into auth.users (id, email) values ('${eid}', 'e2e.suppr.${e.toLowerCase()}.${tampon}@example.com');
      insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
      values ('${eid}', 'E2E-SUP-${e.slice(0, 3).toUpperCase()}-${tampon}', 'student', '${id}', '${e}', '${nom}', 'active', 'female');
      insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${eid}', 'minor', 'standard');`;
  }
  sql(`begin; ${lignes} commit;`);
  p.dire(`Amorce : famille ${prenom} ${nom} (${courriel}), enfants ${JSON.stringify(ids)}`);
  return { id, courriel, nom, enfants: ids };
}

async function directionAal2(options) {
  const session = await sessionDirectionAal2();
  const a = await p.contexte('direction', options);
  // Le client Supabase du web garde sa session dans le localStorage, sous
  // « sb-<hote>-auth-token » (relevé sur la pile locale le 03/11).
  await a.ctx.addInitScript((s) => {
    window.localStorage.setItem('sb-127-auth-token', JSON.stringify(s));
  }, session);
  p.dire(`[direction] session aal2 posée par l'API locale (facteur TOTP enrôlé ou réutilisé par le robot, base locale)`);
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

/// Coche la case d'un compte : un toucher sur la case elle-meme (au debut de
/// la ligne), comme un doigt ; le noeud d'accessibilite de la case peut
/// couvrir toute la ligne dense du telephone (journal ecrit).
async function cocher(a, nom) {
  const e = await trouver(a.page, new RegExp(`^Cocher ${nom}`), { delai: 12000, role: 'checkbox' });
  if (!e) { manque.push(`${a.role} : case de ${nom} absente`); return; }
  await amenerEnVue(a.page, e);
  const b = await e.boundingBox();
  p.dire(`[${a.role}] case de ${nom} : noeud ${Math.round(b.width)} x ${Math.round(b.height)}`);
  await a.page.mouse.click(b.x + Math.min(24, b.width / 2), b.y + b.height / 2);
  await a.page.waitForTimeout(1500);
  await activerSemantique(a.page);
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
  await cocher(d, adam);
  await cocher(d, sara);
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
  // Le relevé des libellés coupe un noeud à 160 signes : le début de la phrase.
  await voir(d, /Les comptes supprimés par la direction ou par un tuteur/, 'phrase de contexte de la section');
  await p.capture(d, '1440_comptes_supprimes');
  await toucher(d, new RegExp(`^Restaurer le compte de ${adam}`), `« Restaurer le compte de ${adam} »`, { role: 'button', pause: 5000 });
  await voir(d, new RegExp(`Le compte de ${adam} est restauré`), 'résultat de la restauration');
  await p.capture(d, '1440_restaure');
  const etat = un(`select account_status || '|' || (deleted_at is null) from public.profiles where id = '${f1.enfants.Adam}'`);
  p.dire(`Base locale : Adam ${etat}`);
  if (!/\|(t|true)$/.test(etat)) manque.push(`base : Adam pas restauré (${etat})`);
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
  if (!/^(t|true)$/.test(lina)) manque.push('base : Lina pas supprimée');
  await t.ctx.close();

  // 4. La direction, au téléphone en sombre : la sélection et le retrait du tuteur.
  const d2 = await directionAal2({ vue: { width: 390, height: 844 }, sombre: true });
  await aller(d2, '/admin/personnes/comptes?vue=eleves');
  await cocher(d2, adam);
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
