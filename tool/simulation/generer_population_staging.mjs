// Génère la population de test du projet STAGING (xldmmlrnxyabdtvxqbyy) à
// partir du même tirage que le modèle économique : 100 élèves, leurs familles,
// leurs classes, leurs enseignants et l'équipe d'administration.
//
//   node tool/simulation/generer_population_staging.mjs
//
// Écrit :
//   supabase/seed/staging_population_test/NN.sql         (à appliquer dans l'ordre, sur STAGING uniquement)
//   supabase/seed/staging_population_test_nettoyage.sql  (retire tout ce qui précède)
//   tool/simulation/population_staging.json              (personas : paiement, disponibilité, plaintes)
//
// Comptes sans mot de passe, adresses en @sim.rewayah.invalid, identifiants
// préfixés e51 (élèves), e52 (enseignants), e53 (administration), e54
// (familles), e55 (classes) : tout se retrouve et se retire par ces marques.

import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { PARAMETRES_DEFAUT, genererPopulation, generateur } from './modele_academie.mjs';

const DOMAINE = 'sim.rewayah.invalid';
const uuid = (prefixe, n) => `${prefixe}00000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const sql = (v) => (v === null || v === undefined ? 'null' : `'${String(v).replace(/'/g, "''")}'`);

const PRENOMS = {
  F: ['Aïcha', 'Fatima', 'Khadija', 'Maryam', 'Sarah', 'Inès', 'Yasmine', 'Salma', 'Hawa', 'Mariama', 'Aminata',
    'Kadiatou', 'Safiya', 'Zaynab', 'Hafsa', 'Imane', 'Nour', 'Lina', 'Amina', 'Leila', 'Asma', 'Rokia', 'Oumou',
    'Hanane', 'Sofia', 'Malika', 'Djeneba', 'Ramatoulaye', 'Hind', 'Samira'],
  M: ['Ibrahim', 'Moussa', 'Youssef', 'Omar', 'Bilal', 'Amadou', 'Mamadou', 'Ousmane', 'Souleymane', 'Adam', 'Ismaël',
    'Hamza', 'Idriss', 'Karim', 'Mehdi', 'Ayoub', 'Ilyes', 'Abdoulaye', 'Thierno', 'Alpha', 'Yacine', 'Anas', 'Zakaria',
    'Elias', 'Noah', 'Rayan', 'Sami', 'Moctar', 'Lamine', 'Seydou'],
};
const NOMS = ['Diallo', 'Bah', 'Barry', 'Sow', 'Camara', 'Traoré', 'Koné', 'Benali', 'El Amrani', 'Haddad', 'Cissé',
  'Touré', 'Keïta', 'Sylla', 'Kaba', 'Mansour', 'Benkirane', 'Ndiaye', 'Fofana', 'Sangaré', 'Bouzid', 'Chraïbi',
  'Diakité', 'Kouyaté', 'Ali', 'Hassan', 'Rahman', 'Siddiqui', 'Yilmaz', 'Mahmoud'];

const COHORTE = { '6-9': 'enfant_6_9', '10-13': 'enfant_10_13', '14-17': 'ado_14_17', '18+': 'adulte_18_plus' };
const REGION = {
  eee: { libelle: 'Europe', fuseau: 'Europe/Paris', langue: 'francais' },
  royaumeUni: { libelle: 'Royaume-Uni', fuseau: 'Europe/London', langue: 'english' },
  international: { libelle: 'Amérique du Nord', fuseau: 'America/Toronto', langue: 'english' },
};
// Accès payé jusqu'à, relatif au début du mois courant : une famille en retard
// lourd ou défaillante apparaît en « compte échu » côté administration.
const ACCES = {
  avance: "date_trunc('month', now()) + interval '3 months' - interval '1 second'",
  ponctuel: "date_trunc('month', now()) + interval '2 months' - interval '1 second'",
  retardLeger: "date_trunc('month', now()) + interval '1 month' - interval '1 second'",
  retardLourd: "date_trunc('month', now()) + interval '9 days'",
  defaillant: "date_trunc('month', now()) - interval '20 days'",
};
const NIVEAUX = ['debut_lettres', 'lettres_avec_aide', 'lecture_lente', 'lecture_courante', 'memorisation_partielle'];
const OBJECTIFS = ['apprendre_a_lire', 'devenir_fluide', 'memoriser', 'indecis'];

const p = PARAMETRES_DEFAUT;
const pop = genererPopulation(p);
const hasard = generateur(p.graine + 1);
const choisir = (liste) => liste[Math.floor(hasard() * liste.length)];

const familles = pop.foyers.map((f) => ({ ...f, uuid: uuid('e54', f.id + 1), nom: choisir(NOMS), region: REGION[f.origineCarte] }));
const eleves = pop.eleves.map((e) => {
  const famille = familles[e.foyer];
  return {
    ...e, uuid: uuid('e51', e.id + 1), email: `eleve-${String(e.id + 1).padStart(3, '0')}@${DOMAINE}`,
    prenom: choisir(PRENOMS[e.sexe]), nom: famille.nom, famille,
    niveau: choisir(NIVEAUX), objectif: choisir(OBJECTIFS),
  };
});
const enseignants = pop.enseignants.map((x) => ({
  ...x, uuid: uuid('e52', x.id + 1), email: `enseignant-${String(x.id + 1).padStart(2, '0')}@${DOMAINE}`,
  prenom: choisir(PRENOMS[x.sexe]), nom: choisir(NOMS), titre: x.sexe === 'F' ? 'sayyida' : 'sayyid',
  pays: choisir(['GN', 'SN', 'ML', 'MA']),
}));
const ADMINISTRATION = [
  { role: 'admin', sexe: 'M' }, { role: 'admin', sexe: 'F' }, { role: 'accountant', sexe: 'F' }, { role: 'controller', sexe: 'M' },
].map((x, i) => ({
  ...x, uuid: uuid('e53', i + 1), email: `${x.role}-${String(i + 1).padStart(2, '0')}@${DOMAINE}`, prenom: choisir(PRENOMS[x.sexe]), nom: choisir(NOMS),
}));

// Deux classes par enseignant, mêmes jours, heures décalées (enfants 60 min,
// adultes 90 min) : lundi-mercredi-vendredi ou mardi-jeudi-samedi.
const classes = pop.groupes.map((g) => {
  const enseignant = enseignants[g.enseignant];
  const rang = enseignant.groupes.indexOf(g.id);
  const jours = enseignant.id % 2 === 0 ? [1, 3, 5] : [2, 4, 6];
  const heure = g.type === 'enfant' ? 17 + rang * 2 : 19 + rang * 2;
  const genre = g.public === 'F' ? 'femmes' : g.public === 'M' ? 'hommes' : 'indetermine';
  const libellePublic = g.type === 'enfant' ? `Enfants ${g.tranche} ans` : `Adultes ${g.public === 'F' ? 'femmes' : 'hommes'}`;
  return {
    ...g, uuid: uuid('e55', g.id + 1), jours, heure, genre, enseignantUuid: enseignant.uuid,
    libelle: `${libellePublic} · classe ${g.id + 1}`, seuil: g.type === 'enfant' ? p.groupes.maxEnfants : p.groupes.maxAdultes,
  };
});

// --- SQL ----------------------------------------------------------------------
// L'outil MCP d'application refuse au-delà de quelques kilo-octets (délai de
// 60 s dépassé sans que la requête n'atteigne la base) : la population part en
// étapes courtes, chacune transactionnelle, à appliquer dans l'ordre.

const v = (rangees) => rangees.map((r) => `  (${r.join(', ')})`).join(',\n');
const ID = (prefixe, n) => `('${prefixe}00000-0000-4000-8000-' || lpad((${n})::text, 12, '0'))::uuid`;
const entete = (titre) => [
  `-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), ${titre}.`,
  '-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.',
  '',
];
const lots = (liste, taille) => Array.from({ length: Math.ceil(liste.length / taille) }, (_, i) => liste.slice(i * taille, (i + 1) * taille));
const etapes = [];

etapes.push(['comptes', [
  ...entete('comptes de connexion sans mot de passe'),
  'do $garde$ begin',
  `  if exists (select 1 from auth.users where email like '%@${DOMAINE}') then`,
  "    raise exception 'population de test deja presente : appliquer d''abord le nettoyage';",
  '  end if;',
  'end $garde$;',
  '',
  'insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,',
  '  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,',
  '  email_change_token_new, email_change, email_change_token_current, phone_change, phone_change_token,',
  '  reauthentication_token, is_sso_user, is_anonymous)',
  `select '00000000-0000-0000-0000-000000000000', (c.prefixe || '00000-0000-4000-8000-' || lpad(c.n::text, 12, '0'))::uuid,`,
  "  'authenticated', 'authenticated', c.email, null, now(),",
  `  '{"provider":"email","providers":["email"],"population_test":true}'::jsonb, '{}'::jsonb, now(), now(),`,
  "  '', '', '', '', '', '', '', '', false, false",
  'from (',
  `  select 'e51' prefixe, n, 'eleve-' || lpad(n::text, 3, '0') || '@${DOMAINE}' email from generate_series(1, ${eleves.length}) n`,
  '  union all',
  `  select 'e52', n, 'enseignant-' || lpad(n::text, 2, '0') || '@${DOMAINE}' from generate_series(1, ${enseignants.length}) n`,
  '  union all',
  `  select 'e53', n, (array[${ADMINISTRATION.map((a) => sql(a.role)).join(', ')}])[n] || '-' || lpad(n::text, 2, '0') || '@${DOMAINE}' from generate_series(1, ${ADMINISTRATION.length}) n`,
  ') c;',
  '',
]]);

etapes.push(['familles', [
  ...entete('familles, sans compte tuteur'),
  'insert into public.households (id, primary_guardian_id, timezone, status)',
  `select ${ID('e54', 'f.n')}, null, f.fuseau, 'active' from (values`,
  v(familles.map((x) => [x.id + 1, sql(x.region.fuseau)])),
  ') f(n, fuseau);',
  '',
]]);

etapes.push(['personnel', [
  ...entete('enseignants (provisoirement actifs) et administration'),
  'insert into public.profiles (id, role, household_id, first_name, last_name, account_status, gender)',
  `select (p.prefixe || '00000-0000-4000-8000-' || lpad(p.n::text, 12, '0'))::uuid, p.role::public.app_role, null, p.prenom, p.nom,`,
  "  (case when p.role = 'teacher' then 'provisional_active' else 'active' end)::public.account_status,",
  "  (case p.sexe when 'F' then 'female' else 'male' end)::public.gender",
  'from (values',
  v([
    ...enseignants.map((e) => [`'e52'`, e.id + 1, `'teacher'`, sql(e.sexe), sql(e.prenom), sql(e.nom)]),
    ...ADMINISTRATION.map((a, i) => [`'e53'`, i + 1, sql(a.role), sql(a.sexe), sql(a.prenom), sql(a.nom)]),
  ]),
  ') p(prefixe, n, role, sexe, prenom, nom);',
  '',
  'insert into public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, titre)',
  `select ${ID('e52', 't.n')}, t.pays, array['fr', 'ar'], 12, 'approved', 'Africa/Conakry', t.titre from (values`,
  v(enseignants.map((e) => [e.id + 1, sql(e.pays), sql(e.titre)])),
  ') t(n, pays, titre);',
  '',
]]);

// Accès payé jusqu'à une date qui suit le profil de paiement de la famille.
const ACCES_SQL = ['  case e.paiement', ...Object.entries(ACCES).map(([k, x]) => `    when '${k}' then ${x}`), '  end'];
for (const lot of lots(eleves, 25)) {
  const premier = lot[0].id + 1;
  etapes.push([`eleves_${premier}`, [
    ...entete(`élèves ${premier} à ${premier + lot.length - 1}`),
    'create temp table sim_lot (n int, sexe text, prenom text, nom text, famille int, cohorte text, niveau text, objectif text, langue text, paiement text);',
    'insert into sim_lot values',
    v(lot.map((e) => [e.id + 1, sql(e.sexe), sql(e.prenom), sql(e.nom), e.foyer + 1, sql(COHORTE[e.tranche]),
      sql(e.niveau), sql(e.objectif), sql(e.famille.region.langue), sql(e.famille.paiement)])) + ';',
    '',
    'insert into public.profiles (id, role, household_id, first_name, last_name, account_status, access_until, gender)',
    `select ${ID('e51', 'e.n')}, 'student', ${ID('e54', 'e.famille')}, e.prenom, e.nom, 'active',`,
    ...ACCES_SQL.map((x) => x + (x === '  end' ? ',' : '')),
    "  (case e.sexe when 'F' then 'female' else 'male' end)::public.gender",
    'from sim_lot e;',
    '',
    'insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,',
    '  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)',
    `select ${ID('e51', 'e.n')}, c.student_type, c.interface_mode, 'hafs',`,
    "  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,",
    "  e.langue, c.code, e.niveau, e.objectif, 'fait', now()",
    'from sim_lot e join public.cohortes_age c on c.code = e.cohorte;',
    '',
    'drop table sim_lot;',
    '',
  ]]);
}

etapes.push(['classes', [
  ...entete('classes actives et leurs trois créneaux par semaine'),
  'create temp table sim_classes (n int, enseignant int, type text, genre text, jours int[], heure int, seuil int, libelle text);',
  'insert into sim_classes values',
  v(classes.map((g) => [g.id + 1, g.enseignant + 1, sql(g.type), sql(g.genre), `'{${g.jours.join(',')}}'`, g.heure, g.seuil, sql(g.libelle)])) + ';',
  '',
  '-- Enseignant du même sexe quand la classe est séparée.',
  'insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, nom_cours, weekday, hour_local,',
  '  timezone_iana, etat, genre_public, langue_code)',
  `select ${ID('e55', 'n')}, ${ID('e52', 'enseignant')}, type, seuil, libelle, 'Lecture du Coran',`,
  "  jours[1], heure, 'Europe/Paris', 'active', genre, 'francais'",
  'from sim_classes;',
  '',
  'insert into public.groupe_creneaux (groupe_id, weekday, hour_local)',
  `select ${ID('e55', 'n')}, j, heure from sim_classes, unnest(jours[2:3]) j;`,
  '',
  'drop table sim_classes;',
  '',
]]);

// Chaque inscription régénère les séances de la classe : quatre classes par étape.
for (const lot of lots(classes, 4)) {
  etapes.push([`membres_${lot[0].id + 1}`, [
    ...entete(`élèves des classes ${lot[0].id + 1} à ${lot.at(-1).id + 1}`),
    'insert into public.groupe_membres (groupe_id, student_id)',
    `select ${ID('e55', 'm.classe')}, ${ID('e51', 'm.eleve')} from (values`,
    v(lot.flatMap((g) => g.membres.map((i) => [g.id + 1, i + 1]))),
    ') m(classe, eleve);',
    '',
  ]]);
}

rmSync('supabase/seed/staging_population_test', { recursive: true, force: true });
mkdirSync('supabase/seed/staging_population_test', { recursive: true });
etapes.forEach(([nom, x], i) => writeFileSync(
  `supabase/seed/staging_population_test/${String(i + 1).padStart(2, '0')}_${nom}.sql`, x.join('\n')));

writeFileSync('supabase/seed/staging_population_test_nettoyage.sql', [
  '-- Retire la population de test du STAGING créée par staging_population_test.sql.',
  "delete from public.session_participants where session_id in (select id from public.sessions where groupe_id::text like 'e5500000-%');",
  "delete from public.sessions where groupe_id::text like 'e5500000-%';",
  "delete from public.groupes where id::text like 'e5500000-%';",
  "delete from auth.users where email like '%@" + DOMAINE + "';",
  "delete from public.households where id::text like 'e5400000-%';",
  '',
].join('\n'));

writeFileSync('tool/simulation/population_staging.json', JSON.stringify({
  graine: p.graine,
  familles: familles.map((f) => ({ id: f.uuid, nom: f.nom, region: f.region.libelle, paiement: f.paiement, membres: f.membres.map((i) => eleves[i].uuid) })),
  eleves: eleves.map((e) => ({
    id: e.uuid, email: e.email, prenom: e.prenom, nom: e.nom, type: e.type, tranche: e.tranche, sexe: e.sexe,
    famille: e.famille.uuid, classe: e.groupe === undefined ? null : classes[e.groupe].uuid,
    disponibilite: e.disponibilite, plaintes: e.plaintes, paiementFamille: e.famille.paiement,
  })),
  enseignants: enseignants.map((e) => ({ id: e.uuid, email: e.email, prenom: e.prenom, nom: e.nom, sexe: e.sexe, classes: e.groupes.map((i) => classes[i].uuid) })),
  administration: ADMINISTRATION.map((a) => ({ id: a.uuid, email: a.email, role: a.role, prenom: a.prenom, nom: a.nom })),
  classes: classes.map((g) => ({ id: g.uuid, libelle: g.libelle, type: g.type, tranche: g.tranche, genre: g.genre, jours: g.jours, heure: g.heure, enseignant: g.enseignantUuid, membres: g.membres.map((i) => eleves[i].uuid) })),
}, null, 2) + '\n');

console.log(`${eleves.length} élèves, ${familles.length} familles, ${classes.length} classes, ${enseignants.length} enseignants, ${ADMINISTRATION.length} administrateurs.`);
