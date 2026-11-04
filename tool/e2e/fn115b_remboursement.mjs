// FN-115b : un paiement est remboursé, puis un autre est contesté et perdu.
// La famille et la direction le lisent dans l'application ; la famille reçoit
// l'e-mail. Usage : node tool/e2e/fn115b_remboursement.mjs
// Prerequis : le parcours 3 a cree la famille (comptes_parcours3.json), son
// enfant est dans une classe ; les fonctions Edge LOCALES tournent avec un
// STRIPE_WEBHOOK_SECRET FACTICE du banc (fonctions_fn115b.env), jamais un
// secret reel. Pile LOCALE seulement : les evenements Stripe sont fabriques et
// signes ici, puis postes au webhook local, comme Stripe le ferait. La commande
// est creee par les memes fonctions que l'application (recapitulatif, commande,
// session), sans passer par Stripe.
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, connecterParLien, ouvrir, trouverTexte, libelles, sql,
  activerSemantique, COMPTES, TRAVAIL, MAILPIT } from './commun.mjs';

const WEBHOOK = 'http://127.0.0.1:54321/functions/v1/stripe-webhook';
const { FAMILLE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
const ligne = fs.readFileSync(path.join(TRAVAIL, 'fonctions_fn115b.env'), 'utf8')
  .split('\n').find((l) => l.startsWith('STRIPE_WEBHOOK_SECRET=whsec_banc_local_'));
if (!ligne) throw new Error('refus : secret factice du banc introuvable');
const SECRET = ligne.slice('STRIPE_WEBHOOK_SECRET='.length);

const p = await parcours('FN-115b : remboursement et contestation, lus par la famille et la direction',
  'fn115b-remboursement');
const manque = [];
const id = Date.now().toString(36);

const tuteur = sql(`select p.id || '|' || p.household_id from public.profiles p join auth.users u on u.id = p.id
  where u.email = '${FAMILLE.courriel}'`);
const [titulaire, foyer] = tuteur.split('|');
const enfant = sql(`select id from public.profiles where household_id = '${foyer}' and role = 'student'
  and first_name = '${FAMILLE.enfant}' limit 1`);
if (!titulaire || !enfant) process.exit(await p.fin('rouge', 'famille du parcours 3 introuvable'));
const commeTuteur = `set local role authenticated;
  select set_config('request.jwt.claim.sub', '${titulaire}', true),
         set_config('request.jwt.claims', json_build_object('sub', '${titulaire}', 'aal', 'aal1', 'role', 'authenticated',
           'app_metadata', json_build_object('role', 'guardian', 'household_id', '${foyer}'))::text, true);`;

/// Une commande payee comme dans l'application : le montant suggere a la
/// famille (le mois, plus une dette eventuelle), recapitulatif et commande par
/// le tuteur, session attachee par le serveur, puis l'evenement Stripe signe.
async function payer(n) {
  const r = sql(`${commeTuteur}
    with m as (select coalesce((x -> 'montantSuggere' ->> 'mineur')::bigint,
        ((x -> 'formules') -> 0 -> 'montant' ->> 'mineur')::bigint) as mineur
      from jsonb_array_elements(public.recharge_beneficiaires()) x where x ->> 'id' = '${enfant}'),
    rec as (select public.recharge_verifier_montants(jsonb_build_array(jsonb_build_object(
      'profilId', '${enfant}', 'mineur', (select mineur from m), 'devise', 'USD'))) as v)
    select public.recharge_payer((v ->> 'id')::uuid, gen_random_uuid()) ->> 'commandeId' from rec`)
    .split('\n').pop();
  const total = sql(`select total_mineur from public.commandes_recharge where id = '${r}'`);
  const session = `cs_test_banc_${id}_${n}`;
  const pi = `pi_banc_${id}_${n}`;
  sql(`set local role service_role; select public.recharge_attacher_session('${r}', '${titulaire}', '${session}',
    'https://checkout.stripe.com/c/pay/${session}', 'test')`);
  const statut = await poster({ type: 'checkout.session.completed', object: {
    id: session, object: 'checkout.session', client_reference_id: r, metadata: { commande: r },
    payment_intent: pi, payment_status: 'paid', amount_total: Number(total), currency: 'usd' } });
  p.dire(`Paiement ${n} : commande ${r}, ${total} centimes, webhook ${statut}`);
  return { commande: r, total: Number(total), pi };
}

/// Un evenement signe comme Stripe le signe (en-tete Stripe-Signature, v1 =
/// HMAC-SHA256 du secret sur « horodatage.corps »).
async function poster({ type, object }) {
  const corps = JSON.stringify({ id: `evt_banc_${id}_${crypto.randomBytes(4).toString('hex')}`, object: 'event',
    type, livemode: false, created: Math.floor(Date.now() / 1000), data: { object } });
  const t = Math.floor(Date.now() / 1000);
  const v1 = crypto.createHmac('sha256', SECRET).update(`${t}.${corps}`).digest('hex');
  const rep = await fetch(WEBHOOK, { method: 'POST', body: corps,
    headers: { 'content-type': 'application/json', 'stripe-signature': `t=${t},v1=${v1}` } });
  return `${rep.status} ${await rep.text()}`;
}

const etat = () => sql(`select coalesce((select statut from public.factures_mensuelles where profile_id = '${enfant}'
  order by mois desc limit 1), 'aucune') || ' ; suspendu : ' || exists(select 1 from public.acces_suspensions_paiement
  where profile_id = '${enfant}' and retabli_le is null)`);

// Point de depart : un mois paye, l'acces ouvert.
const p1 = await payer(1);
p.dire(`Apres paiement 1 : ${etat()}`);
if (!etat().startsWith('financee ; suspendu : false')) manque.push(`paiement 1 non finance (${etat()})`);

// 1. Remboursement complet, fait dans Stripe.
const avantCourriel = Date.now();
const rb = await poster({ type: 'charge.refunded', object: { id: `ch_banc_${id}_1`, object: 'charge',
  payment_intent: p1.pi, amount_refunded: p1.total, currency: 'usd' } });
p.dire(`charge.refunded : ${rb} ; ${etat()}`);
if (!etat().startsWith('a_financer ; suspendu : true')) manque.push(`remboursement : mois non rouvert ou acces ouvert (${etat()})`);
const rejoue = sql(`select count(*) from public.remboursements_paiement where commande_id = '${p1.commande}'`);

// La famille lit la notification ; l'e-mail arrive.
const f = await p.contexte('tuteur', { telephone: true });
await connecterParLien(f.page, FAMILLE.courriel);
await f.page.waitForTimeout(3000);
await ouvrir(f.page, '/#/tuteur/notifications');
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const lu1 = await trouverTexte(f.page, /Un remboursement est fait/, 15000);
const lu2 = await trouverTexte(f.page, /un paiement a été remboursé, le mois n'est plus payé/, 5000);
await p.capture(f, 'famille_notifications_remboursement');
p.dire(`Famille : ${lu1 ?? 'remboursement absent'} | ${lu2 ?? 'suspension absente'} ; lignes de remboursement : ${rejoue}`);
if (!lu1) manque.push('famille : notification « Un remboursement est fait » absente');
if (!lu2) manque.push('famille : notification de suspension pour remboursement absente');

let courriel = null;
for (let i = 0; i < 45 && !courriel; i++) {
  const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${FAMILLE.courriel}`)}`)).json();
  courriel = (r.messages ?? []).find((m) => new Date(m.Created).getTime() >= avantCourriel - 5000
    && /rembours/i.test(m.Subject));
  if (!courriel) await new Promise((ok) => setTimeout(ok, 2000));
}
if (courriel) {
  await f.page.goto(`${MAILPIT}/view/${courriel.ID}.html`);
  await f.page.waitForTimeout(1500);
  await p.capture(f, 'famille_courriel_remboursement');
}
p.dire(`E-mail : ${courriel ? courriel.Subject : 'aucun'}`);
if (!courriel) manque.push('e-mail de remboursement non recu');

// 2. Un second paiement, conteste aupres de la banque puis perdu.
const p2 = await payer(2);
p.dire(`Apres paiement 2 : ${etat()}`);
const litige = `du_banc_${id}`;
const lo = await poster({ type: 'charge.dispute.created', object: { id: litige, object: 'dispute',
  payment_intent: p2.pi, amount: p2.total, currency: 'usd', status: 'needs_response', balance_transactions: [] } });
p.dire(`charge.dispute.created : ${lo} ; ${etat()}`);
const lc = await poster({ type: 'charge.dispute.closed', object: { id: litige, object: 'dispute',
  payment_intent: p2.pi, amount: p2.total, currency: 'usd', status: 'lost',
  balance_transactions: [{ id: `txn_banc_${id}`, fee: 1500 }] } });
const litigeBase = sql(`select statut || ' ; frais ' || frais_mineur from public.litiges_paiement where id = '${litige}'`);
p.dire(`charge.dispute.closed (perdu, 15 USD de frais) : ${lc} ; litige ${litigeBase} ; ${etat()}`);
if (!litigeBase.startsWith('perdu ; frais 1500')) manque.push(`litige non clos perdu (${litigeBase})`);

await ouvrir(f.page, '/#/tuteur/notifications');
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const lu3 = await trouverTexte(f.page, /Un paiement est contesté auprès de la banque/, 15000);
const lu4 = await trouverTexte(f.page, /les frais vont au solde du foyer/, 5000);
await p.capture(f, 'famille_notifications_contestation');
p.dire(`Famille : ${lu3 ?? 'contestation ouverte absente'} | ${lu4 ?? 'contestation perdue absente'}`);
if (!lu3) manque.push('famille : « Un paiement est contesté » absent');
if (!lu4) manque.push('famille : « les frais vont au solde du foyer » absent');
await f.ctx.close();

// 3. La direction le lit dans l'application.
const d = await p.contexte('direction');
await connecter(d.page, COMPTES.direction);
await d.page.waitForTimeout(3000);
await ouvrir(d.page, '/#/admin/notifications');
await d.page.waitForTimeout(4000); await activerSemantique(d.page);
const ld1 = await trouverTexte(d.page, /Un remboursement a été fait à une famille/, 15000);
const ld2 = await trouverTexte(d.page, /Une famille conteste un paiement auprès de sa banque/, 5000);
const ld3 = await trouverTexte(d.page, /Une contestation de paiement est close/, 5000);
await p.capture(d, 'direction_notifications');
p.dire(`Direction : ${[ld1, ld2, ld3].map((x) => x ?? 'absent').join(' | ')}`);
if (!ld1 || !ld2 || !ld3) manque.push('direction : une notification de remboursement ou de contestation manque');
if (!(ld1 && ld2 && ld3)) p.dire(`Direction, ecran : ${(await libelles(d.page)).slice(0, 15).join(' | ')}`);
await d.ctx.close();

process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'remboursement et contestation perdue : mois rouvert, acces suspendu, famille et direction prevenues, e-mail recu'));
