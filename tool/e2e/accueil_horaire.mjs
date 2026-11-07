// ACCUEIL-HORAIRE (PLAN-LOTS rang 22 g, constat du directeur du 05/11/2026) :
// a l'Accueil du tuteur, une seule carte pour l'enfant sans classe dont
// l'horaire reste a choisir. Banc local seulement (G5), jamais un apercu.
//
// Pour chaque passage (390 et 1440, francais et arabe), une famille neuve,
// amorcee comme NIV1 (inscrire_titulaire, puis accepter_admission par la
// direction ; l'Accueil cree et lie le profil de l'enfant). Aucun horaire
// n'est publie sur le banc :
//   1. avant la demande : « Aucun horaire ouvert ne correspond encore », une
//      seule carte (plus de « Aucune classe pour ... »), et « Me prevenir si de
//      nouveaux horaires ouvrent » sur la carte ;
//   2. apres la demande : « Demande enregistree », sans bouton ; une seule
//      demande en base ;
//   3. retour a l'Accueil (une autre page, puis l'Accueil rouvert) : toujours
//      « Demande enregistree ».
// Captures R3 : docs/current/captures/E2E/accueil-horaire/.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, trouver, taper, attendreTexte, activerSemantique, amenerEnVue,
  sql, MDP, COMPTES, DEPOT } from './commun.mjs';

const lire = (fichier) => {
  const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n', fichier), 'utf8'));
  return (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
};
const LANGUES = { fr: lire('fr.i18n.json'), ar: lire('ar.i18n.json') };
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
/// Un texte des fichiers de langue en motif : espaces (insecables comprises)
/// souples ; les parametres `{x}` et les isolants bidirectionnels valent tout.
const souple = (s) => echapper(s.replace(/[⁨⁩]/g, ''))
  .replace(/\\\{[^}]*\\\}/g, '.*').replace(/[\s  ]+/g, '\\s*');
const motif = (s) => new RegExp(souple(s));
const exact = (s) => new RegExp(`^\\s*${souple(s)}\\s*$`);

const p = await parcours('ACCUEIL-HORAIRE : une seule carte « Horaire à choisir »', 'accueil-horaire');
const verdicts = {};
const un = (requete) => sql(requete).split('\n')[0].trim();

function noter(cle, nom, ok, detail = '') {
  verdicts[cle] ??= {};
  verdicts[cle][nom] = ok;
  p.dire(`  ${ok ? 'OK' : 'ROUGE'} ${cle} : ${nom}${detail ? ` (${detail})` : ''}`);
}

/// Une famille neuve, acceptee par la direction, avec un enfant (Lina).
function amorcer(cle) {
  const tampon = `${Date.now() % 100000000}`;
  const courriel = `e2e-ah-${cle}-${tampon}@example.com`;
  const titulaire = un(`with u as (
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
  sql(`begin;
    select set_config('request.jwt.claim.sub', '${titulaire}', true);
    select set_config('request.jwt.claims', '{"sub":"${titulaire}","role":"authenticated"}', true);
    set local role authenticated;
    select (public.inscrire_titulaire('famille', 'Samira', 'Ah${tampon.slice(-6)}', 'female', 'Europe/Paris', false,
      '[{"prenom": "Lina", "age": 9, "genre": "female", "niveau": "lecture_lente",
         "objectif": "devenir_fluide", "moments": ["soir"], "langue": "francais"}]'::jsonb)).id;
    commit;`);
  const direction = un(`select id from auth.users where email = '${COMPTES.direction}'`);
  const [candId, version] = un(`select c.id || '|' || c.version from public.candidatures c
    where c.profile_id = '${titulaire}'`).split('|');
  sql(`begin;
    select set_config('request.jwt.claim.sub', '${direction}', true);
    select set_config('request.jwt.claims', '{"sub":"${direction}","role":"authenticated","app_metadata":{"role":"admin"}}', true);
    set local role authenticated;
    select public.accepter_admission('${candId}', ${version}, 'e2e-ah-${tampon}');
    commit;`);
  return { courriel, titulaire };
}

async function connecter(c, courriel, T) {
  await ouvrir(c.page, '/');
  const deja = await trouver(c.page, exact(T('inscription.questionnaire.dejaUnCompte')), { delai: 10000 });
  if (deja) { await deja.click(); await c.page.waitForTimeout(1500); }
  await taper(c.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(c.page, 'input[type=password]', MDP);
  await c.page.keyboard.press('Enter');
  await c.page.waitForTimeout(7000);
  await activerSemantique(c.page);
}

async function accueil(c) {
  await ouvrir(c.page, '/#/tuteur/accueil');
  await c.page.waitForTimeout(4000);
  await activerSemantique(c.page);
}

/// Amene la carte dans la fenetre, pour que la capture la montre (L2).
async function montrer(c, texte) {
  const e = await trouver(c.page, motif(texte), { delai: 4000 });
  if (e) { await amenerEnVue(c.page, e); await c.page.waitForTimeout(400); }
  await c.page.mouse.move(2, 2);
}

async function passage(langue, largeur, hauteur) {
  const T = LANGUES[langue];
  const cle = `${largeur}_${langue}`;
  const { courriel, titulaire } = amorcer(cle);
  const c = await p.contexte('tuteur', { vue: { width: largeur, height: hauteur },
    langue: langue === 'ar' ? 'ar-SA' : 'fr-FR' });
  await connecter(c, courriel, T);
  await accueil(c);
  // L'Accueil cree et lie le profil de l'enfant ; on rouvre une fois lie.
  let lina = '';
  for (let k = 0; k < 20 && !lina; k++) {
    lina = un(`select p.id from public.profiles p join public.profiles t on t.household_id = p.household_id
                where t.id = '${titulaire}' and p.role = 'student' and p.first_name = 'Lina'`);
    if (!lina) await c.page.waitForTimeout(1500);
  }
  noter(cle, 'le profil de l\'enfant existe', Boolean(lina));
  await accueil(c);

  // 1. Avant la demande.
  noter(cle, 'avant : « Aucun horaire ouvert ne correspond encore »',
    await attendreTexte(c.page, motif(T('parcours.aucuneOffre')), 20000));
  noter(cle, 'avant : plus de seconde carte « Aucune classe pour Lina »',
    !(await attendreTexte(c.page, motif(T('tuteur.accueil.sansClasseTitre')), 1500)));
  noter(cle, 'avant : jamais « Voir les horaires » vers une impasse',
    !(await trouver(c.page, exact(T('parcours.voirHoraires')), { delai: 1500 })));
  const prevenir = await trouver(c.page, exact(T('parcours.refusPrevenir')), { delai: 8000 });
  noter(cle, 'avant : « Me prévenir » sur la carte', prevenir !== null);
  await montrer(c, T('parcours.aucuneOffre'));
  await p.capture(c, `${cle}_1_avant_la_demande`);
  if (!prevenir) { await c.ctx.close(); return; }

  // 2. Apres la demande.
  await amenerEnVue(c.page, prevenir); await prevenir.click();
  await c.page.waitForTimeout(2500); await activerSemantique(c.page);
  noter(cle, 'apres : « Demande enregistrée »',
    await attendreTexte(c.page, motif(T('accueilHoraire.demandeTitre')), 15000));
  noter(cle, 'apres : plus de bouton « Me prévenir »',
    !(await trouver(c.page, exact(T('parcours.refusPrevenir')), { delai: 1500 })));
  const n = un(`select count(*) from public.matching_requests
    where kind = 'horaire_insatisfait' and subject_profile_id = '${lina}'`);
  noter(cle, 'apres : une seule demande en base', n === '1', `en base : ${n}`);
  await montrer(c, T('accueilHoraire.demandeTitre'));
  await p.capture(c, `${cle}_2_apres_la_demande`);

  // 3. Retour a l'Accueil, apres une autre page.
  await ouvrir(c.page, '/#/tuteur/foyer');
  await c.page.waitForTimeout(3000);
  await accueil(c);
  noter(cle, 'retour : toujours « Demande enregistrée »',
    await attendreTexte(c.page, motif(T('accueilHoraire.demandeTitre')), 20000));
  noter(cle, 'retour : une seule carte, sans « Aucune classe pour Lina »',
    !(await attendreTexte(c.page, motif(T('tuteur.accueil.sansClasseTitre')), 1500)));
  await montrer(c, T('accueilHoraire.demandeTitre'));
  await p.capture(c, `${cle}_3_retour_a_l_accueil`);
  await c.ctx.close();
}

let code = 1;
try {
  for (const langue of ['fr', 'ar']) {
    for (const [largeur, hauteur] of [[390, 844], [1440, 900]]) {
      if (process.env.E2E_SEUL && process.env.E2E_SEUL !== `${largeur}_${langue}`) continue;
      await passage(langue, largeur, hauteur);
    }
  }
  const rouges = Object.entries(verdicts).flatMap(([k, v]) =>
    Object.entries(v).filter(([, ok]) => !ok).map(([nom]) => `${k} : ${nom}`));
  code = await p.fin(rouges.length ? 'rouge' : 'vert', rouges.join(' ; '));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
