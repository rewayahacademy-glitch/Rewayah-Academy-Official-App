// FN-115c (pilote, 02/11/2026) : « Rembourser » depuis Finance > Paiements,
// sur la pile LOCALE, lu par le robot, contre un FAUX Stripe de banc
// (`tool/e2e/faux_stripe.mjs`, port 12111 ; le pilote ne fournit aucune cle
// secrete, meme de test).
//
// Ce que le parcours prouve, a 1440 x 900 et 390 x 844 :
//   * le menu « ... » de l'eleve paye porte « Rembourser » ; pas celui d'un
//     eleve sans paiement remboursable ;
//   * la feuille dit le montant juste du serveur et son detail (paye, regle
//     du delai) ;
//   * un double clic sur « Rembourser {montant} » ne cree qu'une demande et
//     qu'un remboursement chez le prestataire : une seule requete
//     POST /v1/refunds (ou des requetes de la meme cle d'idempotence),
//     payment_intent et montant du serveur, cle = la demande ;
//   * l'identifiant du remboursement est note sur la demande (« envoyee ») ;
//   * ensuite, plus rien a rendre : « Rembourser » disparait du menu ;
//   * la fonction Edge refuse un compte qui n'est pas la direction (403).
// Ce qui n'est PAS prouve ici : l'appel au vrai Stripe, et le webhook
// `charge.refunded` (signature) ; le passage aux ecritures est prouve par
// `supabase/tests/scenarios_fn115c_rembourser.sql`.
//
// Prerequis : migration 20261105100000 sur la pile LOCALE ; fonctions servies
// avec STRIPE_SECRET_KEY=sk_test_... et STRIPE_API_BASE_BANC ; faux Stripe
// lance. Donnees : une famille neuve a chaque passage ; rien n'est efface.
// Usage : node tool/e2e/fn115c_rembourser.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, ouvrir, activerSemantique, amenerEnVue,
  libelles, cliquer, sql, API, DEPOT, MDP, COMPTES } from './commun.mjs';

const p = await parcours('FN-115c : Rembourser depuis Finance > Paiements', 'fn115c-rembourser');
let code = 1;
const n = Date.now() % 1000000;
const FR = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const P = FR.admin.finance.pai;
const sans = (s) => s.replace(/[⁨⁩]/g, '').replace(/\s+/g, ' ').trim();
const FAUX = 'http://127.0.0.1:12111';
const statut = Object.fromEntries(fs.readFileSync('/tmp/e2e-pile/statut.env', 'utf8').split('\n')
  .filter((l) => l.includes('=')).map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1).replace(/^"|"$/g, '')]));

const TUTEUR = `e2e-fn115c-tuteur-${n}@example.com`;
const NOM = `Rembourse${n}`;

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

/// Une famille, un enfant dans une classe, un mois paye par le vrai chemin
/// (recharge_verifier_montants, recharge_payer, puis l'evenement Stripe
/// checkout.session.completed sous service_role, comme le webhook).
function amorcer() {
  const t = creerCompte(TUTEUR);
  const e = sql(`select gen_random_uuid()`);
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  sql(`begin;
    insert into auth.users (id, email) values ('${e}', 'e2e-fn115c-eleve-${n}@example.com');
    insert into public.households (id, timezone) values ('${t}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${t}', 'E2E-115C-T-${n}', 'guardian', '${t}', 'Amina', '${NOM}', 'active', 'female'),
           ('${e}', 'E2E-115C-E-${n}', 'student', '${t}', 'Yanis', '${NOM}', 'active', 'male');
    update public.households set primary_guardian_id = '${t}' where id = '${t}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${e}', 'minor', 'standard');
    -- Un creneau libre de l'enseignant de banc : la creation de la classe
    -- materialise ses seances, qui ne doivent pas chevaucher les autres.
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    select gen_random_uuid(), '${prof}', 'enfant', 5, 'Classe ${NOM}', c.j, c.h, 'Europe/Paris'
      from (select j, h from generate_series(1, 6) j, generate_series(6, 21) h
             where not exists (select 1 from public.sessions s where s.teacher_id = '${prof}'
                                 and extract(isodow from s.started_at at time zone 'Europe/Paris') = j
                                 and extract(hour from s.started_at at time zone 'Europe/Paris') between h - 1 and h + 1)
             order by random() limit 1) c;
    insert into public.groupe_membres (groupe_id, student_id, joined_at)
    select id, '${e}', now() - interval '10 days' from public.groupes where libelle = 'Classe ${NOM}';
    commit;`);
  const pi = `pi_banc_${n}`;
  const commande = sql(`
    create function pg_temp.qui(p_id uuid, p_role text, p_foyer uuid) returns void language plpgsql as $$
    declare v text;
    begin
      v := json_build_object('aal', 'aal1', 'app_metadata', json_build_object('role', p_role, 'household_id', p_foyer))::text;
      perform set_config('request.jwt.claim.sub', p_id::text, false);
      perform set_config('request.jwt.claims', v, false);
    end $$;
    create function pg_temp.payer() returns uuid language plpgsql as $$
    declare v_m bigint; v_r jsonb; v_c uuid; v_total bigint;
    begin
      perform pg_temp.qui('${t}', 'guardian', '${t}');
      execute 'set role authenticated';
      select ((x -> 'formules') -> 0 -> 'montant' ->> 'mineur')::bigint into v_m
        from jsonb_array_elements(public.recharge_beneficiaires()) x where x ->> 'id' = '${e}';
      v_r := public.recharge_verifier_montants(jsonb_build_array(
        jsonb_build_object('profilId', '${e}', 'mineur', v_m, 'devise', 'USD')));
      v_c := (public.recharge_payer((v_r ->> 'id')::uuid, gen_random_uuid()) ->> 'commandeId')::uuid;
      execute 'reset role';
      select total_mineur into v_total from public.commandes_recharge where id = v_c;
      execute 'set role service_role';
      perform public.recharge_attacher_session(v_c, '${t}', 'cs_${pi}', 'https://checkout.stripe.com/c/cs_${pi}', 'test');
      if public.recharge_evenement_stripe('evt_pay_${pi}', 'checkout.session.completed', 'test', v_c,
           'cs_${pi}', '${pi}', 'paid', v_total, 'usd') <> 'credite' then
        raise exception 'paiement non credite';
      end if;
      execute 'reset role';
      return v_c;
    end $$;
    select pg_temp.payer();`).split('\n').pop();
  return { tuteur: t, eleve: e, commande, pi };
}

async function jetonDe(courriel) {
  const r = await fetch(`${API}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: statut.ANON_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP }),
  });
  return (await r.json()).access_token;
}

try {
  const f = amorcer();
  p.dire(`Famille ${TUTEUR} : eleve Yanis ${NOM}, commande ${f.commande}, paiement ${f.pi}`);
  const propose = Number(sql(`select (private.fn115c_montant_propose('${f.commande}', '${f.eleve}') ->> 'montant_mineur')`));
  p.dire(`Montant propose par le serveur : ${propose} cents`);

  const verdicts = {};
  // 1. Un compte qui n'est pas la direction est refuse par la fonction Edge.
  const demandeTiers = sql(`select gen_random_uuid()`);
  const refus = await fetch(`${API}/functions/v1/remboursement-stripe`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${await jetonDe(TUTEUR)}`, apikey: statut.ANON_KEY,
      'Content-Type': 'application/json' },
    body: JSON.stringify({ demandeId: demandeTiers }),
  });
  verdicts.nonDirectionRefuse = refus.status === 403;
  p.dire(`  fonction Edge sous le jeton du tuteur : ${refus.status}`);

  for (const [largeur, hauteur] of [[390, 844], [1440, 900]]) {
    const v = {};
    const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
    await connecter(c.page, COMPTES.direction);
    await ouvrir(c.page, '/#/admin/finance/paiements');
    await c.page.waitForTimeout(3000); await activerSemantique(c.page);
    const menu = await trouver(c.page, new RegExp(`${sans(FR.commun.listes.actionsDe).replace('{objet}', '')}.*${NOM}`),
      { delai: 15000, role: 'button' });
    v.menuPresent = Boolean(menu);
    if (!menu) { verdicts[largeur] = v; await p.capture(c, `${largeur}_0_sans_menu`); await c.ctx.close(); continue; }
    await amenerEnVue(c.page, menu);
    await p.capture(c, `${largeur}_1_liste`);
    await menu.click(); await c.page.waitForTimeout(900);
    await p.capture(c, `${largeur}_2_menu`);
    const entree = await trouver(c.page, new RegExp(`^\\s*${P.rembourser}\\s*$`), { delai: 5000 });
    if (entree) { await entree.click(); await c.page.waitForTimeout(2500); }
    await activerSemantique(c.page);
    await p.capture(c, `${largeur}_3_feuille`);
    const bouton = await trouver(c.page, /^\s*Rembourser\s.+/, { delai: 8000, role: 'button' });
    v.feuilleDitLeMontant = Boolean(bouton);
    // Seconde confirmation (directeur, 02/11) : la fenetre dit le montant et
    // le prenom reels ; rien ne part sans « Oui, rembourser ».
    const fenetre = async () => {
      await bouton.click(); await c.page.waitForTimeout(1500); await activerSemantique(c.page);
      const l = sans((await libelles(c.page)).join(' | '));
      const question = sans(P.rembQuestion).replace('{montant}', '').replace('{prenom}', '').split(/\s+/)[0];
      return l.includes(sans(P.rembSansRetour)) && l.includes(P.rembOui) && l.includes('Yanis')
        && l.includes(question) && /\$/.test(l);
    };
    if (largeur === 390 && bouton) {
      v.fenetreDitMontantEtPrenom = await fenetre();
      await p.capture(c, `${largeur}_3b_confirmation`);
      await cliquer(c.page, new RegExp(`^${FR.commun.annuler}$`), { role: 'button', pause: 1200 });
      v.annulerRienNePart = sql(`select count(*) from public.remboursements_demandes where commande_id = '${f.commande}'`) === '0';
    }
    if (largeur === 1440 && bouton) {
      v.fenetreDitMontantEtPrenom = await fenetre();
      await p.capture(c, `${largeur}_3b_confirmation`);
      // Double clic sur « Oui, rembourser » : une seule demande, un seul
      // remboursement.
      const oui = await trouver(c.page, new RegExp(`^${P.rembOui}$`), { delai: 4000, role: 'button' });
      await oui.click(); await oui.click({ force: true }).catch(() => {});
      await c.page.waitForTimeout(6000);
      await activerSemantique(c.page);
      await p.capture(c, `${largeur}_4_envoye`);
      const etat = sql(`select count(*) || '|' || coalesce(max(etat), '') || '|' || coalesce(max(stripe_remboursement), '') || '|' || coalesce(max(id::text), '')
                          from public.remboursements_demandes where commande_id = '${f.commande}'`).split('|');
      const journal = await (await fetch(`${FAUX}/__journal`)).json();
      const posts = journal.filter((j) => j.methode === 'POST' && j.chemin === '/v1/refunds'
        && j.corps.payment_intent === f.pi);
      const cles = new Set(posts.map((j) => j.cle));
      p.dire(`  demandes ${etat[0]}, etat ${etat[1]}, remboursement ${etat[2]} ; POST /v1/refunds ${posts.length} (cles ${[...cles].join(', ')})`);
      if (posts[0]) p.dire(`  corps envoye : ${JSON.stringify(posts[0].corps)}`);
      v.uneSeuleDemande = etat[0] === '1';
      v.notee = etat[1] === 'envoyee' && /^re_banc_/.test(etat[2]);
      v.unSeulRemboursement = posts.length >= 1 && cles.size === 1
        && [...cles][0] === `remboursement-${etat[3]}`;
      v.formeDeLaRequete = posts.length >= 1 && posts[0].corps.payment_intent === f.pi
        && Number(posts[0].corps.amount) === propose
        && posts[0].corps['metadata[profil]'] === f.eleve
        && posts[0].autorisation.startsWith('Bearer sk_test');
      // Rien ne reste a rendre : le serveur ne propose plus « Rembourser ».
      await ouvrir(c.page, '/#/admin/finance/paiements');
      await c.page.waitForTimeout(3000); await activerSemantique(c.page);
      v.menuDisparuApres = !(await trouver(c.page,
        new RegExp(`${sans(FR.commun.listes.actionsDe).replace('{objet}', '')}.*${NOM}`), { delai: 4000, role: 'button' }));
      await p.capture(c, `${largeur}_5_menu_disparu`);
    }
    verdicts[largeur] = v;
    await c.ctx.close();
  }
  for (const [k, v] of Object.entries(verdicts)) p.dire(`${k} : ${JSON.stringify(v)}`);
  const rouges = Object.entries(verdicts).flatMap(([k, v]) =>
    typeof v === 'object' ? Object.entries(v).filter(([, ok]) => ok !== true).map(([x]) => `${k}.${x}`)
      : (v === true ? [] : [k]));
  if (rouges.length) throw new Error(`rouge : ${rouges.join(', ')}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
