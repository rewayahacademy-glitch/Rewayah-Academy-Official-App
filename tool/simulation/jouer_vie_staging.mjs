// Fait vivre la population de test du STAGING pendant 8 semaines passées
// (22 août → 17 octobre 2026) : séances tenues ou annulées, présences et
// absences selon la disponibilité de chaque élève, départs, suspension des
// familles défaillantes, changements de classe, signalements des enseignants
// et demandes de créneau. Écrit des étapes SQL de quelques kilo-octets dans
// tool/simulation/vie_staging/, à appliquer dans l'ordre sur le STAGING
// seulement (jamais la production).
//
//   node tool/simulation/jouer_vie_staging.mjs

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const DOSSIER = new URL('./vie_staging/', import.meta.url);
const pop = JSON.parse(readFileSync(new URL('./population_staging.json', import.meta.url)));
const famille = new Map(pop.familles.map((f) => [f.id, f]));
const num = (uuid) => Number(uuid.slice(-12));
const ADMIN = 'e5300000-0000-4000-8000-000000000001';
const DEBUT = '2026-08-20';
const sql = (s) => `'${String(s).replace(/'/g, "''")}'`;

const eleves = pop.eleves.map((e) => ({ ...e, paiement: e.paiementFamille ?? famille.get(e.famille)?.paiement }));
const enClasse = eleves.filter((e) => e.classe);

// 1. Familles défaillantes : suspendues le 1er octobre après deux mensualités impayées.
const suspendus = enClasse.filter((e) => e.paiement === 'defaillant');
const famillesSuspendues = [...new Set(suspendus.map((e) => e.famille))];

// 2. Départs : élèves qui se plaignent souvent ou très occupés, un par semaine.
const DATES_DEPART = ['2026-09-05', '2026-09-12', '2026-09-19', '2026-09-26', '2026-10-03', '2026-10-10'];
const MOTIFS = ['depart : trop de travail cette annee', 'depart : horaires incompatibles', 'depart : insatisfaction du rythme',
  'depart : demenagement', 'depart : raisons familiales', 'depart : pas de progres ressenti'];
const departs = enClasse
  .filter((e) => e.paiement !== 'defaillant' && (e.plaintes === 'souvent' || (e.disponibilite === 'occupe' && e.plaintes === 'parfois')))
  .slice(0, DATES_DEPART.length)
  .map((e, i) => ({ ...e, date: DATES_DEPART[i], motif: MOTIFS[i] }));
const partis = new Set([...suspendus, ...departs].map((e) => e.id));

// 3. Changements de classe le 5 octobre, après les suspensions : un adulte qui
//    se plaint parfois rejoint une classe de même public (même sexe) où une
//    place s'est libérée.
const taille = new Map();
for (const e of enClasse) if (!partis.has(e.id)) taille.set(e.classe, (taille.get(e.classe) ?? 0) + 1);
const classe = new Map(pop.classes.map((c) => [c.id, c]));
const publicDe = (c) => `${c.type}|${c.genre}|${c.tranche}`;
const transferts = [];
for (const e of enClasse.filter((x) => !partis.has(x.id) && x.type === 'adulte' && x.plaintes === 'parfois')) {
  if (transferts.length === 3) break;
  const source = classe.get(e.classe);
  const cible = pop.classes.find((c) => c.id !== source.id && publicDe(c) === publicDe(source) &&
    (taille.get(c.id) ?? 0) < (c.type === 'adulte' ? 6 : 5));
  if (!cible) continue;
  taille.set(cible.id, (taille.get(cible.id) ?? 0) + 1);
  taille.set(source.id, taille.get(source.id) - 1);
  transferts.push({ ...e, cible: cible.id, date: '2026-10-05' });
}
const transferes = new Set(transferts.map((e) => e.id));

// 4. Signalements des enseignants : absences répétées des élèves occupés,
//    demandes de changement des élèves qui se plaignent souvent.
const enseignantDe = (e) => classe.get(e.classe).enseignant;
const signalements = [
  ...enClasse.filter((e) => e.disponibilite === 'occupe' && !partis.has(e.id)).slice(0, 5).map((e, i) => ({
    e, categorie: 'presence', date: `2026-09-${String(15 + i * 3).padStart(2, '0')}`,
    interne: 'Absent a plusieurs seances ces dernieres semaines.', famille: i % 2 ? 'Nous avons remarque plusieurs absences. Tout va bien ?' : null })),
  ...enClasse.filter((e) => e.plaintes === 'souvent' && !partis.has(e.id)).slice(0, 3).map((e, i) => ({
    e, categorie: 'changement', date: `2026-10-0${2 + i * 2}`,
    interne: 'Se plaint du creneau et demande une autre classe.', famille: null })),
];

// 5. Demandes de créneau envoyées par des adultes qui se plaignent, encore en attente.
const demandes = enClasse.filter((e) => e.type === 'adulte' && e.plaintes !== 'jamais' && !partis.has(e.id) && !transferes.has(e.id))
  .slice(0, 3).map((e, i) => ({ e, jours: [[6, 7], [1, 3, 5], [2, 4]][i], heure: [10, 20, 19][i] }));

// --- Étapes SQL -------------------------------------------------------------

const valeurs = (lignes) => lignes.map((l) => `  (${l.join(', ')})`).join(',\n');
const ID = (prefixe, n) => `('${prefixe}00000-0000-4000-8000-' || lpad((${n})::text, 12, '0'))::uuid`;
const etapes = [];

etapes.push(['anciennete', [
  `-- Les élèves sont inscrits depuis le ${DEBUT}, avant les 8 semaines rejouées.`,
  `update public.groupe_membres set joined_at = '${DEBUT}T08:00:00Z'`,
  `where student_id::text like 'e51%' and groupe_id::text like 'e55%' and left_at is null;`,
]]);

etapes.push(['departs', [
  '-- Départs, un par semaine.',
  'update public.groupe_membres m set left_at = (d.jour || \'T18:00:00Z\')::timestamptz, left_by = ' + sql(ADMIN) + '::uuid, left_reason = d.motif',
  'from (values', valeurs(departs.map((e) => [num(e.id), sql(e.date), sql(e.motif)])), ') d(n, jour, motif)',
  `where m.student_id = ${ID('e51', 'd.n')} and m.left_at is null;`,
  '-- Familles défaillantes : suspendues le 1er octobre, leurs élèves quittent leur classe.',
  'update public.households set status = \'suspended\' where id in (' + famillesSuspendues.map((f) => `${sql(f)}::uuid`).join(', ') + ');',
  `update public.groupe_membres set left_at = '2026-10-01T08:00:00Z', left_by = ${sql(ADMIN)}::uuid,`,
  "  left_reason = 'suspension : deux mensualites impayees'",
  'where left_at is null and student_id in (' + suspendus.map((e) => `${sql(e.id)}::uuid`).join(', ') + ');',
  '-- Comme retirer_eleve_groupe : plus de place dans les séances à venir.',
  'update public.session_participants sp set deleted_at = now()',
  'from public.sessions s, public.groupe_membres m',
  `where s.id = sp.session_id and s.started_at > now() and sp.deleted_at is null and sp.role = 'student'`,
  '  and m.student_id = sp.profile_id and m.groupe_id = s.groupe_id and m.left_at is not null;',
]]);

etapes.push(['changements', [
  '-- Changements de classe le 5 octobre (même public, une place libre).',
  'update public.groupe_membres m set left_at = (t.jour || \'T18:00:00Z\')::timestamptz, left_by = ' + sql(ADMIN) + "::uuid, left_reason = 'transfert : changement de creneau demande'",
  'from (values', valeurs(transferts.map((e) => [num(e.id), sql(e.cible), sql(e.date)])), ') t(n, cible, jour)',
  `where m.student_id = ${ID('e51', 't.n')} and m.left_at is null;`,
  '-- Libérer les séances à venir de l’ancienne classe avant d’entrer dans la nouvelle',
  '-- (sinon le garde-fou de chevauchement refuse les nouvelles séances).',
  'update public.session_participants sp set deleted_at = now()',
  'from public.sessions s, public.groupe_membres m',
  `where s.id = sp.session_id and s.started_at > now() and sp.deleted_at is null and sp.role = 'student'`,
  '  and m.student_id = sp.profile_id and m.groupe_id = s.groupe_id and m.left_at is not null;',
  'insert into public.groupe_membres (groupe_id, student_id, joined_at)',
  `select t.cible::uuid, ${ID('e51', 't.n')}, (t.jour || 'T18:00:00Z')::timestamptz from (values`,
  valeurs(transferts.map((e) => [num(e.id), sql(e.cible), sql(e.date)])), ') t(n, cible, jour);',
]]);

etapes.push(['seances', [
  '-- 8 semaines de séances passées, copiées des créneaux de la première semaine',
  '-- à venir ; 2 séances sur 100 annulées.',
  'insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id, join_opens_at, prayer_pause_minutes, created_at, updated_at)',
  "select md5('vie-staging' || s.id::text || k)::uuid, s.teacher_id,",
  "  s.started_at - k * interval '7 days', s.ended_at - k * interval '7 days',",
  "  (case when abs(hashtext(s.id::text || k)) % 100 < 2 then 'canceled' else 'ended' end)::public.session_status,",
  "  s.session_type, s.groupe_id, s.join_opens_at - k * interval '7 days', s.prayer_pause_minutes,",
  "  s.started_at - k * interval '7 days' - interval '28 days', s.ended_at - k * interval '7 days'",
  'from public.sessions s cross join generate_series(1, 8) k',
  `where s.groupe_id::text like 'e55%' and s.deleted_at is null and s.status = 'planned'`,
  "  and s.started_at >= now() and s.started_at < now() + interval '7 days'",
  '  -- Une séance du jour déjà commencée garde son original : pas de doublon.',
  '  and not exists (select 1 from public.sessions o where o.groupe_id = s.groupe_id and o.deleted_at is null',
  "    and o.started_at = s.started_at - k * interval '7 days');",
]]);

// Disponibilité de chaque élève : o = occupé (25 % d'absences), d = disponible (8 %).
const dispo = Array.from({ length: 100 }, (_, i) => (eleves.find((e) => num(e.id) === i + 1)?.disponibilite === 'occupe' ? 'o' : 'd')).join('');
const presenceEleve = `abs(hashtext(s.id::text || m.student_id::text)) % 100 >= case substr('${dispo}', right(m.student_id::text, 12)::int, 1) when 'o' then 25 else 8 end`;
// Les séances encore « planned » d'aujourd'hui gardent leurs participants d'origine.
const passees = `s.groupe_id::text like 'e55%' and s.started_at < now() and s.started_at >= '${DEBUT}' and s.deleted_at is null and s.status <> 'planned'`;

etapes.push(['participants', [
  "-- Élèves inscrits à la date de chaque séance passée ; présents selon leur disponibilité.",
  'insert into public.session_participants (session_id, profile_id, role, entered_at, exited_at, created_at)',
  "select s.id, m.student_id, 'student',",
  `  case when s.status = 'ended' and ${presenceEleve} then s.started_at + interval '2 minutes' end,`,
  `  case when s.status = 'ended' and ${presenceEleve} then s.ended_at end, s.created_at`,
  'from public.sessions s join public.groupe_membres m on m.groupe_id = s.groupe_id',
  '  and m.joined_at <= s.started_at and (m.left_at is null or m.left_at > s.started_at)',
  `where ${passees};`,
  "insert into public.session_participants (session_id, profile_id, role, entered_at, exited_at, created_at)",
  "select s.id, s.teacher_id, 'teacher',",
  "  case when s.status = 'ended' then s.started_at - interval '3 minutes' end,",
  "  case when s.status = 'ended' then s.ended_at end, s.created_at",
  `from public.sessions s where ${passees};`,
]]);

etapes.push(['presences', [
  '-- Ce que LiveKit aurait signalé : arrivée et départ de chaque présent.',
  'insert into public.session_events (session_id, profile_id, event_type, server_ts, source)',
  "select sp.session_id, sp.profile_id, e.type::public.session_event_type, case e.type when 'joined' then sp.entered_at else sp.exited_at end, 'livekit_webhook'",
  "from public.session_participants sp join public.sessions s on s.id = sp.session_id cross join (values ('joined'), ('left')) e(type)",
  `where ${passees} and sp.entered_at is not null;`,
]]);

etapes.push(['signalements', [
  '-- Signalements déposés par les enseignants, transmis ou non à la famille.',
  'insert into public.student_concern (categorie, groupe_id, student_id, teacher_id, internal_details, family_summary, statut, cree_le, transmis_le, transmis_a)',
  "select x.categorie::public.concern_category, x.groupe::uuid, x.eleve::uuid, x.enseignant::uuid, x.interne, x.famille,",
  "  (case when x.famille is null then 'ouvert' else 'transmis' end)::public.concern_status, (x.jour || 'T19:30:00Z')::timestamptz,",
  "  case when x.famille is not null then (x.jour || 'T21:00:00Z')::timestamptz end,",
  "  (case when x.famille is not null then case x.type when 'enfant' then 'tuteur_du_mineur' else 'eleve_adulte' end end)::public.concern_target",
  'from (values', valeurs(signalements.map((s) => [sql(s.categorie), sql(s.e.classe), sql(s.e.id), sql(enseignantDe(s.e)), sql(s.interne),
    s.famille ? sql(s.famille) : 'null::text', sql(s.date), sql(s.e.type)])),
  ') x(categorie, groupe, eleve, enseignant, interne, famille, jour, type);',
  '-- Demandes d’un autre créneau, encore sans réponse.',
  'insert into public.demandes_horaires_famille (eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales, source, etat, created_at, updated_at)',
  "select d.eleve::uuid, 'adulte', 'francais', 'Europe/Paris', d.jours::smallint[], d.heures::smallint[], 'personnalisee', 'envoyee', d.jour::timestamptz, d.jour::timestamptz",
  'from (values', valeurs(demandes.map((d, i) => [sql(d.e.id), sql(`{${d.jours}}`), sql(`{${d.jours.map(() => d.heure)}}`), sql(`2026-10-1${i}T09:00:00Z`)])),
  ') d(eleve, jours, heures, jour);',
]]);

mkdirSync(DOSSIER, { recursive: true });
etapes.forEach(([nom, lignes], i) => {
  writeFileSync(new URL(`${String(i + 1).padStart(2, '0')}_${nom}.sql`, DOSSIER), lignes.join('\n') + '\n');
});
writeFileSync(new URL('scenario.json', DOSSIER), JSON.stringify({
  suspendus: suspendus.map((e) => e.id), famillesSuspendues,
  departs: departs.map(({ id, date, motif }) => ({ id, date, motif })),
  transferts: transferts.map(({ id, classe: source, cible, date }) => ({ id, source, cible, date })),
  signalements: signalements.map((s) => ({ eleve: s.e.id, categorie: s.categorie, date: s.date, transmis: Boolean(s.famille) })),
  demandes: demandes.map((d) => ({ eleve: d.e.id, jours: d.jours, heure: d.heure })),
}, null, 2) + '\n');
console.log(`${etapes.length} étapes ; ${suspendus.length} élèves suspendus (${famillesSuspendues.length} familles), ` +
  `${departs.length} départs, ${transferts.length} changements, ${signalements.length} signalements, ${demandes.length} demandes.`);
