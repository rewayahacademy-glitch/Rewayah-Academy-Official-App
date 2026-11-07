// FN-101, option B (06/11/2026, branche claude/fn101-barriere) : une piece
// d'identite n'entre dans kyc_documents que si son CONTENU est confirme par la
// fonction Edge kyc-confirme (migration 20261110800000).
//
// 1. Par l'API, avec le jeton de la candidate (on contourne l'application, comme
//    le ferait quelqu'un de mal intentionne) :
//    a. un texte nomme .pdf est depose dans le seau kyc ; kyc-confirme rend 422 ;
//       l'insertion directe de la ligne est refusee ;
//    b. une vraie image PNG : kyc-confirme rend 200, la ligne entre.
// 2. Dans le navigateur, une autre candidate depose une vraie photo par
//    l'application : le dossier passe « en cours de vérification ».
// Usage : node tool/e2e/fn101_contenu.mjs   (pile locale, application construite
// depuis claude/fn101-barriere)
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, ouvrir, cliquer, trouverTexte, libelles, activerSemantique,
  sql, API, DEPOT, TRAVAIL } from './commun.mjs';

const p = await parcours('FN-101 : contenu de la piece confirme par le serveur', 'fn-divers/robot-fn101');
const statut = Object.fromEntries(fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8').split('\n')
  .filter((l) => l.includes('=')).map((l) => { const i = l.indexOf('='); return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')]; }));
const CLE = statut.ANON_KEY;
const PIECE = path.join(DEPOT, 'tool/e2e/piece_factice.png');

function candidate(etiquette) {
  const courriel = `e2e-fn101-${etiquette}-${Date.now().toString(36)}@example.com`;
  execFileSync('bash', ['-c', `
    set -euo pipefail
    DB_URL=$(grep '^DB_URL=' "${TRAVAIL}/statut.env" | cut -d'"' -f2)
    case "$DB_URL" in postgresql://*@127.0.0.1:*) ;; *) echo "refus : base non locale"; exit 1 ;; esac
    psql "$DB_URL" -v ON_ERROR_STOP=1 -q -v c="${courriel}" -v n="${etiquette}" <<'SQL'
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
  select user_id, 'E2E-FN101-' || substr(user_id::text, 1, 8), 'teacher', 'E2E Piece', :'n', 'pending_kyc', 'female' from i
  returning id
)
insert into public.teacher_profiles (profile_id, country, languages, kyc_status)
select id, 'FR', '{fr}', 'pending' from pr;
SQL
  `], { stdio: 'inherit' });
  return courriel;
}

async function jeton(courriel) {
  const r = await fetch(`${API}/auth/v1/token?grant_type=password`, {
    method: 'POST', headers: { apikey: CLE, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: 'E2E-motdepasse-2026' }),
  });
  const j = await r.json();
  if (!j.access_token) throw new Error(`connexion API impossible : ${JSON.stringify(j).slice(0, 200)}`);
  return { jwt: j.access_token, uid: j.user.id };
}

const r = [];
// ---------- 1. API ----------
const a = await jeton(candidate('Api'));
const H = (type) => ({ apikey: CLE, Authorization: `Bearer ${a.jwt}`, ...(type ? { 'Content-Type': type } : {}) });
async function deposer(nom, octets, type) {
  const cle = `${a.uid}/${nom}`;
  const up = await fetch(`${API}/storage/v1/object/kyc/${cle}`, { method: 'POST', headers: H(type), body: octets });
  const conf = await fetch(`${API}/functions/v1/kyc-confirme`, { method: 'POST', headers: H('application/json'), body: JSON.stringify({ object_key: cle }) });
  const confCorps = await conf.text();
  const ins = await fetch(`${API}/rest/v1/kyc_documents`, { method: 'POST', headers: { ...H('application/json'), Prefer: 'return=minimal' },
    body: JSON.stringify({ profile_id: a.uid, doc_type: 'id_card', object_key: cle }) });
  const insCorps = await ins.text();
  return { depot: up.status, confirme: conf.status, confCorps, insertion: ins.status, insCorps };
}
const faux = await deposer('faux.pdf', new TextEncoder().encode('ceci est un texte, pas un PDF'), 'application/pdf');
p.dire(`  API, texte nomme .pdf : depot ${faux.depot} ; kyc-confirme ${faux.confirme} ${faux.confCorps} ; insertion ${faux.insertion} ${faux.insCorps.slice(0, 120)}`);
r.push(`API faux PDF : ${faux.confirme === 422 && faux.insertion >= 400 ? 'refuse' : 'ROUGE'} (confirme ${faux.confirme}, insertion ${faux.insertion})`);
const vrai = await deposer('vrai.png', fs.readFileSync(PIECE), 'image/png');
p.dire(`  API, vraie image : depot ${vrai.depot} ; kyc-confirme ${vrai.confirme} ${vrai.confCorps} ; insertion ${vrai.insertion} ${vrai.insCorps.slice(0, 120)}`);
r.push(`API vraie image : ${vrai.confirme === 200 && vrai.insertion === 201 ? 'acceptee' : 'ROUGE'} (confirme ${vrai.confirme}, insertion ${vrai.insertion})`);

// ---------- 2. Navigateur ----------
const courriel = candidate('Navigateur');
const c = await p.contexte('candidate', { telephone: true });
await connecter(c.page, courriel);
await ouvrir(c.page, '/#/attente/accords');
await c.page.waitForTimeout(3000);
const cases = c.page.getByRole('checkbox');
for (let i = 0; i < await cases.count(); i++) {
  if ((await cases.nth(i).getAttribute('aria-checked')) !== 'true') { await cases.nth(i).click(); await c.page.waitForTimeout(300); }
}
await cliquer(c.page, /^Suivant$/, { pause: 4000 });
await activerSemantique(c.page);
await cliquer(c.page, /^Carte d'identité\./, { role: 'radio' });
c.page.once('filechooser', (fc) => fc.setFiles(PIECE));
await cliquer(c.page, /^Choisir la photo$/, { pause: 3000 });
await p.capture(c, 'piece_choisie');
await cliquer(c.page, /^Envoyer ma pièce$/, { pause: 6000 });
await activerSemantique(c.page);
await p.capture(c, 'apres_envoi');
const attente = await trouverTexte(c.page, /Votre dossier est en cours de vérification/, 15000);
const ligne = sql(`select count(*) from public.kyc_documents k join auth.users u on u.id = k.profile_id where u.email = '${courriel}'`);
p.dire(`  navigateur : ${attente ?? (await libelles(c.page)).slice(0, 12).join(' | ')} ; lignes kyc_documents : ${ligne}`);
r.push(`navigateur vraie photo : ${attente && ligne === '1' ? 'deposee, en verification' : 'ROUGE'}`);
await c.ctx.close();
process.exit(await p.fin(r.some((x) => /ROUGE/.test(x)) ? 'rouge' : 'vert', r.join(' ; ')));
