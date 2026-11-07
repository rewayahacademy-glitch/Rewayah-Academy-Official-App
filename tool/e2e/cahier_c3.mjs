// CAHIER-C3 (07/11/2026) : le cahier de confirmation, de bout en bout, sur la
// pile LOCALE (rien n'ecrit en production).
// Pour chaque variante (1440 et 390, francais et arabe) :
//   1. SQL LOCAL : une Classe neuve de l'enseignant de test sur une etape
//      publiee, un eleve de 6 a 9 ans place a l'etape 2, une seance tenue
//      il y a une heure, et la page 42 du Mushaf presentee dans la salle
//      (la salle elle-meme est prouvee par le robot de CAHIER-C1) ;
//   2. l'enseignant ouvre le cahier : « La Classe s'est arretee page 42 du
//      Mushaf. » ; il ouvre la feuille de l'eleve, touche un objectif de
//      l'etape et « Pret pour le petit bilan », puis valide le cahier ;
//   3. la base : le cahier porte la page 42, et les lignes d'observation
//      existent (un objectif a renforcer, un pret pour le bilan).
// Usage : node tool/e2e/cahier_c3.mjs   (apres pile.sh, amorcer.sh, cahier_c2.mjs)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, trouverTexte, libelles, amenerEnVue,
  activerSemantique, sql, COMPTES, DEPOT } from './commun.mjs';

const VARIANTES = [
  { nom: '1440_fr', vue: { width: 1440, height: 900 }, langue: 'fr-FR', code: 'fr' },
  { nom: '390_fr', vue: { width: 390, height: 844 }, langue: 'fr-FR', code: 'fr' },
  { nom: '1440_ar', vue: { width: 1440, height: 900 }, langue: 'ar-SA', code: 'ar' },
  { nom: '390_ar', vue: { width: 390, height: 844 }, langue: 'ar-SA', code: 'ar' },
].filter((v) => !process.env.E2E_C3_VARIANTE || v.nom === process.env.E2E_C3_VARIANTE);

const I18N = Object.fromEntries(['fr', 'ar'].map((c) => [c,
  JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${c}.i18n.json`), 'utf8'))]));
const cle = (code, chemin) => chemin.split('.').reduce((o, k) => o[k], I18N[code]);
const nettoyer = (s) => s.replace(/[⁨⁩]/g, '').replace(/ /g, ' ');
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const motif = (code, chemin, vars = {}, { debut = true, fin = false } = {}) => {
  const morceaux = nettoyer(cle(code, chemin)).split(/\{(\w+)\}/);
  const iso = '[\\u2068\\u2069\\s]*';
  const re = morceaux.map((m, i) => (i % 2 ? `${iso}${echapper(String(vars[m] ?? ''))}${iso}` : echapper(m))).join('');
  return new RegExp(`${debut ? '^' : ''}${re.replace(/ /g, '[\\s\\u00a0]')}${fin ? '$' : ''}`);
};

const p = await parcours('CAHIER-C3 : le cahier de confirmation (position proposee, points a renforcer)', 'cahier-c3');
const verifier = (condition, libelle) => {
  if (!condition) throw new Error(`ROUGE : ${libelle}`);
  p.dire(`  OK ${libelle}`);
};
const vers = async (page, chemin) => {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(5000);
  await activerSemantique(page);
};
const appuyer = async (acteur, cible, libelle, options = {}) => {
  const e = await trouver(acteur.page, cible, { delai: 15000, ...options });
  if (!e) {
    await p.capture(acteur, `echec_${libelle.replace(/\W+/g, '_')}`);
    throw new Error(`${libelle} introuvable ; ecran : ${(await libelles(acteur.page)).slice(0, 40).join(' | ')}`);
  }
  await amenerEnVue(acteur.page, e);
  await e.click();
  await acteur.page.waitForTimeout(2500);
  await activerSemantique(acteur.page);
};

function preparer(nomVariante, profId, adminId) {
  const versionId = sql(`select id from public.programme_versions where statut = 'publiee' order by numero_version desc limit 1`);
  if (!versionId) throw new Error('aucune version publiee : lancer cahier_c2.mjs');
  const n1 = sql(`select id from public.programme_niveaux where version_id = '${versionId}' and ordre = 1`);
  const n2 = sql(`select id from public.programme_niveaux where version_id = '${versionId}' and ordre = 2`);
  const suffixe = `${nomVariante}-${Date.now().toString(36)}`;
  const libelle = `E2E C3 ${suffixe}`;
  sql(`update public.groupes set ended_at = now(), ended_by = '${profId}', end_reason = 'Banc E2E CAHIER-C3'
       where libelle like 'E2E C3 %' and ended_at is null`);
  let groupe = null;
  for (let essai = 0; essai < 48 && !groupe; essai++) {
    const heure = Math.floor(Math.random() * 24);
    try {
      groupe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, programme_niveau_id)
         values ('${profId}', 'enfant', 5, '${libelle}', ((extract(isodow from now())::int + 4) % 7) + 1, ${heure}, 'Europe/Paris', '${n1}')
         returning id`).split('\n')[0];
    } catch (_) { /* heure prise : une autre */ }
  }
  if (!groupe) throw new Error('aucune heure libre pour la Classe d\'essai');
  sql(`update public.sessions set started_at = started_at - interval '400 days', ended_at = ended_at - interval '400 days' where groupe_id = '${groupe}'`);
  const eleve = sql(`with u as (
      insert into auth.users (instance_id, id, aud, role, email, created_at, updated_at)
      values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
              'e2e-eleve-c3-${suffixe}@example.com', now(), now()) returning id),
    f as (insert into public.households (id, timezone) values (gen_random_uuid(), 'Europe/Paris') returning id)
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    select u.id, 'E2E-C3-' || upper(substr(md5(u.id::text), 1, 6)), 'student', f.id, 'Yasmine', 'C3', 'active', 'female'
      from u, f returning id`).split('\n')[0];
  sql(`insert into public.student_profiles (profile_id, student_type, interface_mode, cohorte)
       values ('${eleve}', 'minor', 'child', 'enfant_6_9');
     insert into public.groupe_membres (groupe_id, student_id) values ('${groupe}', '${eleve}');
     insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
       values ('${eleve}', '${n2}', 'diagnostic_initial', '${adminId}', 'Banc E2E CAHIER-C3')`);
  // Banc local : les seances de l'enseignant de test qui chevauchent la
  // fenetre de l'essai partent loin dans le passe.
  const decalage = `interval '${2000 + (Math.floor(Date.now() / 60000) % 50000)} days'`;
  sql(`update public.sessions set started_at = started_at - ${decalage}, ended_at = ended_at - ${decalage}
       where teacher_id = '${profId}' and started_at < now() + interval '5 minutes' and ended_at > now() - interval '80 minutes'`);
  const seance = sql(`insert into public.sessions (teacher_id, started_at, ended_at, status, groupe_id)
     values ('${profId}', now() - interval '70 minutes', now() - interval '10 minutes', 'planned', '${groupe}') returning id`).split('\n')[0];
  sql(`insert into public.session_participants (session_id, profile_id, role) values ('${seance}', '${eleve}', 'student')
       on conflict do nothing;
     insert into public.session_events (session_id, profile_id, event_type, server_ts, source) values
       ('${seance}', '${profId}', 'joined', now() - interval '69 minutes', 'livekit_webhook'),
       ('${seance}', '${eleve}', 'joined', now() - interval '68 minutes', 'livekit_webhook'),
       ('${seance}', '${eleve}', 'left', now() - interval '11 minutes', 'livekit_webhook'),
       ('${seance}', '${profId}', 'left', now() - interval '10 minutes', 'livekit_webhook');
     update public.sessions set status = 'preflight' where id = '${seance}';
     update public.sessions set status = 'in_progress' where id = '${seance}';
     update public.sessions set finance_started_at = started_at, finance_ended_at = ended_at, status = 'ended' where id = '${seance}';
     insert into public.classe_position_reprise (groupe_id, page, session_id, presentee_par)
       values ('${groupe}', 42, '${seance}', '${profId}')
       on conflict (groupe_id) do update set page = 42, session_id = excluded.session_id`);
  return { libelle, groupe, eleve, seance };
}

let code = 1;
try {
  const profId = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  const adminId = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  if (!profId || !adminId) throw new Error('comptes de test absents : lancer tool/e2e/amorcer.sh');
  for (const v of VARIANTES) {
    p.dire(`-- variante ${v.nom}`);
    const c = preparer(v.nom, profId, adminId);
    p.dire(`  Classe « ${c.libelle} » ; seance ${c.seance} ; page 42 presentee`);
    const e = await p.contexte(`enseignant_${v.nom}`, { vue: v.vue, langue: v.langue });
    await connecter(e.page, COMPTES.enseignant);
    await vers(e.page, `/enseignant/seance/${c.seance}/cahier`);
    // La phrase de cahierC3.arretPage, page 42, en francais ou en arabe.
    const phrase = /42[\s\u00a0\u2068\u2069]*(du Mushaf|من المصحف)/;
    const lue = await trouverTexte(e.page, phrase, 20000);
    const n = await trouver(e.page, phrase, { delai: 3000 });
    if (n) await amenerEnVue(e.page, n);
    await p.capture(e, '1_cahier_page_proposee');
    p.dire(`  libelles 42 : ${JSON.stringify((await libelles(e.page)).filter((x) => /42/.test(x)))}`);
    verifier(!!lue, `cahier : « ${nettoyer(cle(v.code, 'cahierC3.arretPage')).replace('{page}', '42')} » (${lue ?? 'absent'})`);
    await appuyer(e, /Yasmine/, 'ligne de l eleve');
    await appuyer(e, /Lit la chadda/, 'objectif Lit la chadda');
    await appuyer(e, motif(v.code, 'cahierC3.pretBilan'), 'Pret pour le petit bilan');
    await p.capture(e, '2_feuille_points_a_renforcer');
    await appuyer(e, motif(v.code, 'enseignant.cahier.ajusterValider', {}, { fin: true }), 'valider la feuille', { role: 'button' });
    await appuyer(e, motif(v.code, 'enseignant.cahier.valider', {}, { fin: true }), 'Valider le cahier', { role: 'button' });
    await e.page.waitForTimeout(3000);
    await p.capture(e, '3_cahier_valide');
    const pageBase = sql(`select content->>'page_reprise' from public.lesson_reports where session_id = '${c.seance}' and deleted_at is null order by created_at desc limit 1`);
    verifier(pageBase === '42', `base : le cahier porte la page 42 (${pageBase || 'aucun cahier'})`);
    const obs = sql(`select string_agg(nature || ':' || coalesce(objectif, '-'), ',' order by nature) from public.cahier_observations where session_id = '${c.seance}'`);
    verifier(obs === 'a_renforcer:Lit la chadda,pret_bilan:-', `base : observations en lignes (${obs || 'aucune'})`);
    await e.ctx.close();
  }
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
