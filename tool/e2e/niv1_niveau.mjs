// NIV1 (03/11/2026, migration 20261106800000) : le niveau demande une seule
// fois. Banc local seulement (pile tool/e2e), jamais un apercu Vercel.
//
//   A. Un enfant venu de la demande : la famille s'inscrit (inscrire_titulaire,
//      avec le niveau de l'enfant), la direction l'accepte (accepter_admission),
//      l'Accueil cree et lie le profil de l'enfant (creer-profil-enfant, puis
//      lier_apprenant_profil). Son Parcours s'ouvre sur les horaires, sans
//      reposer les questions.
//   B. Un enfant ajoute depuis le Foyer : « Creer le profil » ouvre son
//      Parcours, qui pose les questions SANS l'age, puis montre les horaires.
//
// Captures R3 : docs/current/captures/E2E/niv1-niveau/ (390 et 1440).
import { parcours, ouvrir, connecter, trouver, trouverTexte, activerSemantique, amenerEnVue,
  libelles, sql, MDP, COMPTES } from './commun.mjs';

const p = await parcours('NIV1 : le niveau demande une seule fois', 'niv1-niveau');
const tampon = new Date().toISOString().slice(5, 19).replace(/[-T:]/g, '');
const manque = [];
const un = (requete) => sql(requete).split('\n')[0].trim();
const LARGE = { width: 1440, height: 900 };

// --- Amorce : un compte d'authentification, puis les vraies fonctions -------
const courriel = `e2e-niv1-${tampon}@example.com`;
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
const NOM = `Niv${tampon.slice(-6)}`;
sql(`begin;
  select set_config('request.jwt.claim.sub', '${titulaire}', true);
  select set_config('request.jwt.claims', '{"sub":"${titulaire}","role":"authenticated"}', true);
  set local role authenticated;
  select (public.inscrire_titulaire('famille', 'Samira', '${NOM}', 'female', 'Europe/Paris', false,
    '[{"prenom": "Lina", "age": 9, "genre": "female", "niveau": "lecture_lente",
       "objectif": "devenir_fluide", "moments": ["soir"], "langue": "francais"}]'::jsonb)).id;
  commit;`);
const direction = un(`select id from auth.users where email = '${COMPTES.direction}'`);
const candidature = un(`select c.id || '|' || c.version from public.candidatures c where c.profile_id = '${titulaire}'`);
const [candId, version] = candidature.split('|');
sql(`begin;
  select set_config('request.jwt.claim.sub', '${direction}', true);
  select set_config('request.jwt.claims', '{"sub":"${direction}","role":"authenticated","app_metadata":{"role":"admin"}}', true);
  set local role authenticated;
  select public.accepter_admission('${candId}', ${version}, 'e2e-niv1-${tampon}');
  commit;`);
const etape = un(`select etape from public.candidatures where id = '${candId}'`);
p.dire(`Amorce : famille ${courriel} (Samira ${NOM}, enfant Lina 9 ans), demande ${etape}`);
if (etape !== 'confirmee') manque.push(`amorce : demande ${etape}, pas confirmee`);

async function acteur(role, options) {
  const a = await p.contexte(role, options);
  await connecter(a.page, courriel);
  if (await a.page.locator('input[type=password]').count()) await connecter(a.page, courriel);
  return a;
}
async function aller(a, chemin) {
  await ouvrir(a.page, `/#${chemin}`);
  await a.page.waitForTimeout(4000);
  await activerSemantique(a.page);
}
async function voir(a, motif, quoi, delai = 15000) {
  const t = await trouverTexte(a.page, motif, delai);
  p.dire(`[${a.role}] ${quoi} : ${t ?? 'ABSENT'}`);
  if (!t) manque.push(`${a.role} : ${quoi}`);
  return t;
}
async function toucher(a, motif, role = undefined, delai = 10000) {
  const e = await trouver(a.page, motif, { delai, role });
  if (!e) return false;
  await amenerEnVue(a.page, e);
  const b = await e.boundingBox();
  if (b) await a.page.mouse.click(b.x + b.width / 2, b.y + Math.min(b.height, 48) / 2);
  else await e.click();
  await a.page.waitForTimeout(1800);
  await activerSemantique(a.page);
  return true;
}
const HORAIRES = /Voici les horaires ouverts pour|Aucun horaire/;

// --- A. L'enfant venu de la demande --------------------------------------
{
  const tel = await acteur('famille', { telephone: true });
  await aller(tel, '/tuteur/accueil');
  // L'Accueil cree et lie le profil de l'enfant de la demande.
  let lina = '';
  for (let k = 0; k < 20 && !lina; k++) {
    lina = un(`select p.id from public.profiles p join public.profiles t on t.household_id = p.household_id
                where t.id = '${titulaire}' and p.role = 'student' and p.first_name = 'Lina'`);
    if (!lina) await tel.page.waitForTimeout(1500);
  }
  if (!lina) {
    manque.push('A : le profil de Lina n\'est pas cree par l\'Accueil');
  } else {
    const fiche = un(`select coalesce(niveau_declare, '-') || ' ' || coalesce(cohorte, '-') || ' ' ||
                       (onboarding_fait_le is not null) from public.student_profiles where profile_id = '${lina}'`);
    p.dire(`A : fiche de Lina en base : ${fiche}`);
    if (!/^lecture_lente \S+ true$/.test(fiche)) manque.push(`A : fiche de Lina non remplie (${fiche})`);
    await aller(tel, `/tuteur/parcours/${lina}`);
    await voir(tel, HORAIRES, 'A : le Parcours de Lina s\'ouvre sur les horaires');
    if (await trouverTexte(tel.page, /Où en est Lina aujourd'hui|Dans quelle langue/, 1500)) {
      manque.push('A : le Parcours de Lina repose les questions');
    }
    await p.capture(tel, '390_clair_a_parcours_horaires');
  }
  await tel.ctx.close();
  if (lina) {
    const bureau = await acteur('famille', { vue: LARGE, sombre: true });
    await aller(bureau, `/tuteur/parcours/${lina}`);
    await voir(bureau, HORAIRES, 'A : horaires au bureau');
    await p.capture(bureau, '1440_sombre_a_parcours_horaires');
    await bureau.ctx.close();
  }
}

// --- B. L'enfant ajoute depuis le Foyer ----------------------------------
async function ajouter(a, prenom, prefixe) {
  await aller(a, '/tuteur/foyer/ajouter');
  if (!await toucher(a, /^Un enfant ou un mineur/)) { manque.push(`${prefixe} : choix « Un enfant ou un mineur » absent`); return null; }
  await toucher(a, /^Suivant$/, 'button');
  for (const c of await a.page.locator('input').all()) {
    const n = `${await c.getAttribute('aria-label') ?? ''}`;
    const v = /prénom/i.test(n) ? prenom : /nom/i.test(n) ? NOM : null;
    if (v === null) continue;
    await c.click({ force: true }); await a.page.keyboard.press('Control+A');
    await a.page.keyboard.type(v, { delay: 10 }); await a.page.waitForTimeout(200);
  }
  await toucher(a, /^8( ans)?$/);
  await p.capture(a, `${prefixe}_formulaire`);
  if (!await toucher(a, /^Créer le profil/, 'button')) { manque.push(`${prefixe} : « Créer le profil » absent`); return null; }
  await a.page.waitForTimeout(3000);
  await activerSemantique(a.page);
  return a.page.url();
}
async function repondre(a, prenom, prefixe) {
  const vues = [];
  for (let k = 0; k < 10; k++) {
    if (await trouverTexte(a.page, HORAIRES, 1500)) return vues;
    const l = await libelles(a.page);
    const q = l.filter((x) => x.startsWith('flt-semantics:') || x.startsWith('h1:') || x.startsWith('h2:')).slice(0, 2).join(' / ');
    vues.push(q.slice(0, 80));
    if (/Quel âge a/.test(q)) manque.push(`${prefixe} : le Parcours repose l'age`);
    await p.capture(a, `${prefixe}_q${k}`);
    // Une reponse : la premiere carte proposee (aucune n'est preselectionnee).
    const carte = await trouver(a.page, /./, { delai: 2000, role: 'radio' });
    if (carte) {
      await amenerEnVue(a.page, carte);
      const b = await carte.boundingBox();
      if (b) await a.page.mouse.click(b.x + b.width / 2, b.y + Math.min(b.height, 48) / 2);
      await a.page.waitForTimeout(1500);
    }
    await toucher(a, /^(Continuer|Suivant|Voir les horaires|Enregistrer)$/, 'button', 2500);
    await a.page.waitForTimeout(1500);
    await activerSemantique(a.page);
  }
  manque.push(`${prefixe} : les horaires ne viennent pas apres les questions (${vues.join(' | ')})`);
  return vues;
}
{
  const tel = await acteur('famille', { telephone: true });
  const url = await ajouter(tel, 'Yanis', '390_clair_b');
  p.dire(`B : apres « Créer le profil » : ${url}`);
  if (url && !url.includes('/tuteur/parcours/')) manque.push(`B : « Créer le profil » ne mene pas au Parcours (${url})`);
  if (url?.includes('/tuteur/parcours/')) {
    await voir(tel, /Dans quelle langue|Où vous trouvez-vous|Où en est Yanis/, 'B : premiere question du Parcours (sans l\'age)');
    const vues = await repondre(tel, 'Yanis', '390_clair_b');
    p.dire(`B : questions vues : ${vues.join(' | ')}`);
    await voir(tel, HORAIRES, 'B : horaires apres les questions');
    await p.capture(tel, '390_clair_b_horaires');
    const yanis = un(`select (onboarding_fait_le is not null) || ' ' || coalesce(niveau_declare, '-')
                        from public.student_profiles sp join public.profiles p on p.id = sp.profile_id
                       join public.profiles t on t.household_id = p.household_id
                      where t.id = '${titulaire}' and p.first_name = 'Yanis'`);
    p.dire(`B : fiche de Yanis en base : ${yanis}`);
    if (!yanis.startsWith('true')) manque.push(`B : fiche de Yanis non remplie apres les questions (${yanis})`);
  }
  await tel.ctx.close();

  const bureau = await acteur('famille', { vue: LARGE });
  const url2 = await ajouter(bureau, 'Adam', '1440_clair_b');
  p.dire(`B : au bureau, apres « Créer le profil » : ${url2}`);
  if (url2 && !url2.includes('/tuteur/parcours/')) manque.push(`B bureau : pas de Parcours (${url2})`);
  if (url2?.includes('/tuteur/parcours/')) {
    await voir(bureau, /Dans quelle langue|Où vous trouvez-vous|Où en est Adam/, 'B : premiere question au bureau');
    await p.capture(bureau, '1440_clair_b_premiere_question');
    await repondre(bureau, 'Adam', '1440_clair_b');
    await voir(bureau, HORAIRES, 'B : horaires au bureau');
    await p.capture(bureau, '1440_clair_b_horaires');
  }
  await bureau.ctx.close();
}

process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'A : enfant venu de la demande, Parcours sur les horaires ; B : enfant ajoute, questions sans l\'age puis horaires ; 390 et 1440'));
