// SUIVI-ELEVE (07/11/2026) : le suivi de l'eleve et du tuteur, de bout en
// bout, sur la pile LOCALE (rien n'ecrit en production).
// Donnees (SQL LOCAL, comme cahier_c2.mjs) : une version des bases publiee ;
// une Classe de l'enseignant de test sur l'etape 1 ; un eleve adulte (compte a
// mot de passe) decide a l'etape 1 il y a 1 semaine ; un tuteur et son enfant
// de 6 a 9 ans, decide a l'etape 2 il y a 16 semaines ; la page 42 presentee
// dans la Classe ; une seance finie de l'adulte dont le dernier evenement de
// salle est une coupure (etat en direct « deconnectee » : le cas du « Lien
// coupé »).
// Pour chaque variante (1440 et 390, francais et arabe) :
//   1. l'eleve adulte ouvre /eleve/suivi : « Où j'en suis », son etape, la
//      page 42, sa date limite, « Dans la durée prévue », et jamais « Lien
//      coupé » sur la seance finie ;
//   2. le tuteur ouvre l'Historique : « Où en est Yasmine », etape 2, page 42,
//      « Au-delà de la durée prévue » ;
//   3. l'eleve en Interface guidee : etape, objectifs, page 42 ; ni rythme ni
//      date limite.
// Les valeurs attendues sont lues dans la base par la RPC elle-meme, sous le
// jeton de la personne (aucun calcul ici).
// Usage : node tool/e2e/suivi_eleve.mjs   (apres pile.sh, amorcer.sh)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, ouvrir, taper, trouver, trouverTexte, libelles, amenerEnVue,
  activerSemantique, sql, COMPTES, DEPOT, MDP } from './commun.mjs';

const VARIANTES = [
  { nom: '1440_fr', vue: { width: 1440, height: 900 }, langue: 'fr-FR', code: 'fr' },
  { nom: '390_fr', vue: { width: 390, height: 844 }, langue: 'fr-FR', code: 'fr' },
  { nom: '1440_ar', vue: { width: 1440, height: 900 }, langue: 'ar-SA', code: 'ar' },
  { nom: '390_ar', vue: { width: 390, height: 844 }, langue: 'ar-SA', code: 'ar' },
].filter((v) => !process.env.E2E_SE_VARIANTE || v.nom === process.env.E2E_SE_VARIANTE);

const I18N = Object.fromEntries(['fr', 'ar'].map((c) => [c,
  JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${c}.i18n.json`), 'utf8'))]));
const cle = (code, chemin) => chemin.split('.').reduce((o, k) => o[k], I18N[code]);
/// Un libelle a pluriel (slang « (param=x) ») : la forme du nombre donne.
const pluriel = (code, chemin, n) => {
  const formes = cle(code, chemin);
  return code === 'fr' ? (Number(n) <= 1 ? formes.one : formes.other) : formes.other;
};
const nettoyer = (s) => s.replace(/[⁨⁩]/g, '').replace(/ /g, ' ');
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const motif = (code, chemin, vars = {}, { debut = true, fin = false, nombre } = {}) => {
  const brut = nombre === undefined ? cle(code, chemin) : pluriel(code, chemin, nombre);
  const morceaux = nettoyer(brut).split(/\{(\w+)\}/);
  const iso = '[\\u2068\\u2069\\s]*';
  const re = morceaux.map((m, i) => (i % 2 ? `${iso}${echapper(String(vars[m] ?? ''))}${iso}` : echapper(m))).join('');
  return new RegExp(`${debut ? '^' : ''}${re.replace(/ /g, '[\\s\\u00a0]')}${fin ? '$' : ''}`);
};

const p = await parcours('SUIVI-ELEVE : le suivi pedagogique de l\'eleve et du tuteur', 'suivi-eleve');
const verifier = (condition, libelle) => {
  if (!condition) throw new Error(`ROUGE : ${libelle}`);
  p.dire(`  OK ${libelle}`);
};
const vers = async (page, chemin) => {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(5000);
  await activerSemantique(page);
};
/// Connexion par mot de passe, dans la langue du navigateur : en arabe, le
/// lien « J'ai déjà un compte » porte son libelle arabe (connecter() de
/// commun.mjs ne cherche que le francais).
const seConnecter = async (page, code, courriel) => {
  if (code === 'fr') return connecter(page, courriel);
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    const e = await trouver(page, motif(code, 'inscription.questionnaire.dejaUnCompte', {}, { fin: true }), { delai: 8000 });
    if (e) { await e.click(); await page.waitForTimeout(1200); }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await activerSemantique(page);
};
const voir = async (acteur, cible, etiquette) => {
  const e = await trouver(acteur.page, cible, { delai: 15000 });
  if (e) await amenerEnVue(acteur.page, e);
  await p.capture(acteur, etiquette);
  return e;
};

/// Un compte a mot de passe, confirme (SQL LOCAL, comme amorcer.sh).
function compte(courriel) {
  return sql(`with existant as (select id from auth.users where email = '${courriel}'),
    nouveau as (
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
        email_change_token_new, email_change)
      select '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
        '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
        '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
      where not exists (select 1 from existant) returning id),
    ident as (
      insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
      select gen_random_uuid(), n.id, n.id::text,
        jsonb_build_object('sub', n.id::text, 'email', '${courriel}', 'email_verified', true),
        'email', now(), now(), now() from nouveau n returning user_id)
    select id from nouveau union all select id from existant`).split('\n')[0];
}

/// Appelle une fonction sous le jeton d'une personne (SQL LOCAL).
function sousJeton(id, role, foyer, requete) {
  const jwt = JSON.stringify({ sub: id, role: 'authenticated', app_metadata: { role, household_id: foyer } });
  return sql(`begin;
    select set_config('request.jwt.claim.sub', '${id}', true);
    select set_config('request.jwt.claims', '${jwt}', true);
    set local role authenticated;
    ${requete};
    commit;`).split('\n').filter((l) => l && !/^(set_config|SET|BEGIN|COMMIT)$/.test(l))
    .filter((l) => l !== id && !l.startsWith('{')).join('\n');
}

/// Une version des bases publiee : celle qui existe, sinon une neuve.
function versionPubliee(adminId) {
  const existante = sql(`select v.id from public.programme_versions v where v.statut = 'publiee'
     and (select count(*) from public.programme_niveaux n where n.version_id = v.id
          and cardinality(n.objectifs) between 3 and 5) >= 2 order by v.numero_version desc limit 1`);
  if (existante) return existante;
  const jwt = JSON.stringify({ sub: adminId, role: 'authenticated', app_metadata: { role: 'admin' } });
  return sql(`begin;
    select set_config('request.jwt.claim.sub', '${adminId}', true);
    select set_config('request.jwt.claims', '${jwt}', true);
    do $$ declare v uuid; begin
      v := public.creer_version_programme(null);
      perform public.preremplir_bases_programme(v);
      perform public.publier_version_programme(v, 'Banc E2E SUIVI-ELEVE');
    end $$;
    commit;
    select id from public.programme_versions where statut = 'publiee' order by numero_version desc limit 1;`)
    .split('\n').filter((l) => /^[0-9a-f-]{36}$/.test(l)).pop();
}

function preparer(profId, adminId) {
  const suffixe = Date.now().toString(36);
  const versionId = versionPubliee(adminId);
  const n1 = sql(`select id from public.programme_niveaux where version_id = '${versionId}' and ordre = 1`);
  const n2 = sql(`select id from public.programme_niveaux where version_id = '${versionId}' and ordre = 2`);
  sql(`update public.groupe_membres set left_at = now(), left_by = '${adminId}', left_reason = 'Banc E2E SUIVI-ELEVE'
        where left_at is null and groupe_id in (select id from public.groupes where libelle like 'E2E SE %' and ended_at is null);
       update public.groupes set ended_at = now(), ended_by = '${profId}', end_reason = 'Banc E2E SUIVI-ELEVE'
        where libelle like 'E2E SE %' and ended_at is null`);
  let groupe = null;
  for (let essai = 0; essai < 48 && !groupe; essai++) {
    const heure = Math.floor(Math.random() * 24);
    try {
      groupe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, programme_niveau_id)
         values ('${profId}', 'enfant', 5, 'E2E SE ${suffixe}', ((extract(isodow from now())::int + 3) % 7) + 1, ${heure}, 'Europe/Paris', '${n1}')
         returning id`).split('\n')[0];
    } catch (_) { /* heure prise : une autre */ }
  }
  if (!groupe) throw new Error('aucune heure libre pour la Classe d\'essai');

  // Le foyer, le tuteur, l'enfant ; l'eleve adulte dans son propre foyer.
  const foyerT = sql(`insert into public.households (timezone) values ('Europe/Paris') returning id`).split('\n')[0];
  const foyerA = sql(`insert into public.households (timezone) values ('Europe/Paris') returning id`).split('\n')[0];
  const tuteur = compte('e2e-se-tuteur@example.com');
  const adulte = compte('e2e-se-adulte@example.com');
  sql(`insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
       values ('${tuteur}', 'E2E-SE-TUT', 'guardian', '${foyerT}', 'Nadia', 'SE', 'active', 'female')
       on conflict (id) do update set household_id = excluded.household_id;
     insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
       values ('${adulte}', 'E2E-SE-ADU', 'student', '${foyerA}', 'Karim', 'SE', 'active', 'male')
       on conflict (id) do update set household_id = excluded.household_id;
     insert into public.student_profiles (profile_id, student_type, interface_mode, cohorte)
       values ('${adulte}', 'autonomous', 'standard', 'adulte_18_plus')
       on conflict (profile_id) do update set cohorte = excluded.cohorte`);
  const enfant = compte(`e2e-se-enfant-${suffixe}@example.com`);
  sql(`insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
       values ('${enfant}', 'E2E-SE-' || upper(substr(md5(random()::text), 1, 6)), 'student', '${foyerT}', 'Yasmine', 'SE', 'active', 'female')`);
  sql(`update public.profiles set household_id = '${foyerT}' where id = '${tuteur}';
     insert into public.student_profiles (profile_id, student_type, interface_mode, cohorte)
       values ('${enfant}', 'minor', 'standard', 'enfant_6_9');
     update public.profiles set deleted_at = now()
       where role = 'student' and first_name = 'Yasmine' and last_name = 'SE' and id <> '${enfant}' and deleted_at is null;
     insert into public.groupe_membres (groupe_id, student_id) values ('${groupe}', '${enfant}'), ('${groupe}', '${adulte}');
     insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif, created_at)
       values ('${enfant}', '${n2}', 'diagnostic_initial', '${adminId}', 'Banc E2E SUIVI-ELEVE', now() - interval '16 weeks 1 hour'),
              ('${adulte}', '${n1}', 'diagnostic_initial', '${adminId}', 'Banc E2E SUIVI-ELEVE', now() - interval '1 week 1 hour')`);

  // Une seance finie de l'adulte : entre, puis coupure reseau (« deconnectee »).
  const seance = sql(`insert into public.sessions (teacher_id, started_at, ended_at, status, groupe_id)
       values ('${profId}', now() - interval '1 day 2 hours', now() - interval '1 day 1 hour', 'ended', '${groupe}')
       returning id`).split('\n')[0];
  sql(`insert into public.session_participants (session_id, profile_id, role)
       values ('${seance}', '${adulte}', 'student'), ('${seance}', '${enfant}', 'student');
     insert into public.session_events (session_id, profile_id, event_type, server_ts, source)
       values ('${seance}', '${adulte}', 'joined', now() - interval '1 day 2 hours', 'livekit_webhook'),
              ('${seance}', '${adulte}', 'left', now() - interval '1 day 1 hour 50 minutes', 'network');
     insert into public.classe_position_reprise (groupe_id, page, session_id, presentee_par)
       values ('${groupe}', 42, '${seance}', '${profId}')
       on conflict (groupe_id) do update set page = 42, session_id = excluded.session_id`);
  return { groupe, seance, tuteur, adulte, enfant, foyerT, foyerA };
}

const date = (code, iso, prevue) => {
  const [annee, mois, jour] = iso.split('-').map(Number);
  return motif(code, 'suiviPedagogique.aFinirAvantDate', {
    numero: String(jour), mois: cle(code, 'commun.dates.mois')[mois - 1], annee: String(annee), prevue,
  }, { debut: false });
};

let code = 1;
try {
  const profId = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  const adminId = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  if (!profId || !adminId) throw new Error('comptes de test absents : lancer tool/e2e/amorcer.sh');
  const d = preparer(profId, adminId);
  p.dire(`  Classe ${d.groupe} ; adulte ${d.adulte} ; enfant ${d.enfant} ; seance ${d.seance}`);

  // La base, sous le jeton de chacun : ce que l'ecran doit montrer.
  const etatDirect = sousJeton(d.adulte, 'student', d.foyerA,
    `select public.etat_presence('${d.seance}', '${d.adulte}')::text`);
  verifier(etatDirect.includes('deconnectee'), `base : l'etat en direct de la seance finie est « deconnectee » (${etatDirect})`);
  const lireSuivi = (id, role, foyer, eleve) => sousJeton(id, role, foyer,
    `select etape_ordre || '|' || coalesce(date_limite::text, '') || '|' || coalesce(duree_prevue_semaines::text, '')
       || '|' || coalesce(semaines_ecoulees::text, '') || '|' || rythme || '|' || coalesce(page_reprise::text, '')
       from public.suivi_pedagogique_eleve('${eleve}')`).split('\n').find((l) => l.includes('|'));
  const [oA, dA, pA, sA, rA, gA] = (lireSuivi(d.adulte, 'student', d.foyerA, d.adulte) ?? '').split('|');
  const [oE, dE, pE, sE, rE, gE] = (lireSuivi(d.tuteur, 'guardian', d.foyerT, d.enfant) ?? '').split('|');
  verifier(oA === '1' && rA === 'dans_les_temps' && gA === '42', `base : adulte etape 1, dans_les_temps, page 42 (${oA}|${rA}|${gA})`);
  verifier(oE === '2' && rE === 'au_dela_du_prevu' && gE === '42', `base : enfant etape 2, au_dela_du_prevu, page 42 (${oE}|${rE}|${gE})`);
  const nomA = sql(`select nom_humain from public.programme_niveaux n join public.groupes g on g.programme_niveau_id = n.id where g.id = '${d.groupe}'`);
  const nomE = sql(`select n.nom_humain from public.programme_niveaux n where n.version_id = (select version_id from public.programme_niveaux where id = (select programme_niveau_id from public.groupes where id = '${d.groupe}')) and n.ordre = 2`);

  for (const v of VARIANTES) {
    p.dire(`-- variante ${v.nom}`);
    // 1. L'eleve adulte.
    const a = await p.contexte(`adulte_${v.nom}`, { vue: v.vue, langue: v.langue });
    await seConnecter(a.page, v.code, 'e2e-se-adulte@example.com');
    await vers(a.page, '/eleve/suivi');
    const titre = await voir(a, motif(v.code, 'suiviPedagogique.titreSoi', {}, { fin: true }), '1_eleve_ou_j_en_suis');
    p.dire(`  ecran : ${(await libelles(a.page)).slice(0, 30).join(' | ')}`);
    verifier(!!titre, 'eleve : « Où j\'en suis » en tete du Suivi');
    verifier(!!(await trouverTexte(a.page, new RegExp(echapper(nomA)), 8000)), `eleve : l'etape « ${nomA} »`);
    verifier(!!(await trouverTexte(a.page, motif(v.code, 'suiviPedagogique.reprisePage', { page: '42' }), 8000)),
      'eleve : la Classe s\'est arretee page 42 du Mushaf');
    verifier(!!(await trouverTexte(a.page, date(v.code, dA, pA), 8000)), `eleve : a finir avant le ${dA}, ${pA} semaines prevues`);
    const rythme = await voir(a, motif(v.code, 'suiviPedagogique.dansLesTemps(param=ecoulees)', { ecoulees: sA, prevue: pA }, { debut: false, nombre: sA }), '2_eleve_rythme');
    verifier(!!rythme, `eleve : « Dans la durée prévue : ${sA} sur ${pA} »`);
    const lien = await trouverTexte(a.page, motif(v.code, 'presence.deconnectee', {}, { fin: true }), 3000);
    const seance = await trouver(a.page, motif(v.code, 'eleve.suivi.cours', {}, { debut: false }), { delai: 8000 });
    if (seance) await amenerEnVue(a.page, seance);
    await p.capture(a, '3_eleve_seance_finie');
    verifier(!!seance, 'eleve : la seance finie est dans la liste');
    verifier(!lien, 'eleve : jamais « Lien coupé » sur la seance finie (etat en direct « deconnectee »)');
    // Un cours a venir garde son etat en direct, jamais « Absence » (la mesure
    // du serveur rend « absente » tant que le cours n'a pas eu lieu).
    const aVenir = await trouverTexte(a.page, motif(v.code, 'presence.planifiee', {}, { debut: false }), 8000);
    verifier(!!aVenir, `eleve : les cours a venir disent « ${nettoyer(cle(v.code, 'presence.planifiee'))} »`);
    await a.ctx.close();

    // 2. Le tuteur, pour son enfant.
    const t = await p.contexte(`tuteur_${v.nom}`, { vue: v.vue, langue: v.langue });
    await seConnecter(t.page, v.code, 'e2e-se-tuteur@example.com');
    await vers(t.page, `/tuteur/suivi?eleve=${d.enfant}`);
    const titreT = await voir(t, motif(v.code, 'suiviPedagogique.titre', { prenom: 'Yasmine' }, { fin: true }), '4_tuteur_ou_en_est');
    p.dire(`  ecran : ${(await libelles(t.page)).slice(0, 30).join(' | ')}`);
    verifier(!!titreT, 'tuteur : « Où en est Yasmine » en tete de l\'Historique');
    verifier(!!(await trouverTexte(t.page, new RegExp(echapper(nomE)), 8000)), `tuteur : l'etape « ${nomE} »`);
    verifier(!!(await trouverTexte(t.page, motif(v.code, 'suiviPedagogique.reprisePage', { page: '42' }), 8000)),
      'tuteur : page 42 du Mushaf');
    verifier(!!(await trouverTexte(t.page, date(v.code, dE, pE), 8000)), `tuteur : a finir avant le ${dE}`);
    const rT = await voir(t, motif(v.code, 'suiviPedagogique.auDelaDuPrevu(param=ecoulees)', { ecoulees: sE, prevue: pE }, { debut: false, nombre: sE }), '5_tuteur_rythme');
    verifier(!!rT, `tuteur : « Au-delà de la durée prévue : ${sE} sur ${pE} »`);
    await t.ctx.close();
  }

  // 3. Interface guidee : l'eleve voit son etape, ses objectifs, la page ;
  //    ni le rythme ni la date limite (garde-cap, 07/11/2026).
  sql(`update public.student_profiles set interface_mode = 'child' where profile_id = '${d.adulte}'`);
  try {
    for (const v of VARIANTES) {
      p.dire(`-- Interface guidee ${v.nom}`);
      const g = await p.contexte(`guidee_${v.nom}`, { vue: v.vue, langue: v.langue });
      await seConnecter(g.page, v.code, 'e2e-se-adulte@example.com');
      await vers(g.page, '/eleve/suivi');
      const titreG = await voir(g, motif(v.code, 'suiviPedagogique.titreSoi', {}, { fin: true }), '6_guidee_ou_j_en_suis');
      p.dire(`  ecran : ${(await libelles(g.page)).slice(0, 30).join(' | ')}`);
      verifier(!!titreG, 'Interface guidee : « Où j\'en suis »');
      verifier(!!(await trouverTexte(g.page, new RegExp(echapper(nomA)), 8000)), 'Interface guidee : l\'etape');
      const page42 = await trouver(g.page, motif(v.code, 'suiviPedagogique.reprisePage', { page: '42' }, { debut: false }), { delai: 8000 });
      if (page42) await amenerEnVue(g.page, page42);
      await p.capture(g, '7_guidee_reprise');
      verifier(!!page42, 'Interface guidee : page 42 du Mushaf');
      verifier(!(await trouverTexte(g.page, motif(v.code, 'suiviPedagogique.aFinirAvant', {}, { debut: false }), 3000)),
        'Interface guidee : pas de date limite');
      verifier(!(await trouverTexte(g.page, motif(v.code, 'suiviPedagogique.rythme', {}, { debut: false }), 3000)),
        'Interface guidee : pas de rythme');
      await g.ctx.close();
    }
  } finally {
    sql(`update public.student_profiles set interface_mode = 'standard' where profile_id = '${d.adulte}'`);
  }
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
