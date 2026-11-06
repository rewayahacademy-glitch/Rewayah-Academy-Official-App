// CAHIER-C1 (06/11/2026) : la position de reprise automatique, de bout en bout,
// sur la pile LOCALE (rien n'ecrit en production).
// Pour chaque variante (1440 et 390, francais et arabe) :
//   1. une Classe neuve de l'enseignant de test, deux seances : s1 tenue par
//      lui maintenant, s2 juste apres, remplacee par un second enseignant ;
//   2. l'enseignant rejoint la salle de s1, presente une page du Coran ; la
//      base retient la page pour la Classe (verifie en SQL) ; il quitte ;
//   3. la fiche de la Classe (« A preparer ») affiche « On reprend page N » ;
//   4. le remplacant, sur un autre navigateur, rejoint la salle de s2 et lit
//      « On reprend page N » dans la Bibliotheque.
// Usage : node tool/e2e/cahier_c1.mjs   (apres pile.sh, amorcer.sh, construire, servir)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, trouverTexte, libelles, amenerEnVue,
  activerSemantique, sql, COMPTES, DEPOT, MDP } from './commun.mjs';

const REMPLACANT = 'e2e-remplacant-c1@example.com';
const VARIANTES = [
  { nom: '1440_fr', vue: { width: 1440, height: 900 }, langue: 'fr-FR', code: 'fr' },
  { nom: '390_fr', vue: { width: 390, height: 844 }, langue: 'fr-FR', code: 'fr' },
  { nom: '1440_ar', vue: { width: 1440, height: 900 }, langue: 'ar-SA', code: 'ar' },
  { nom: '390_ar', vue: { width: 390, height: 844 }, langue: 'ar-SA', code: 'ar' },
].filter((v) => !process.env.E2E_C1_VARIANTE || v.nom === process.env.E2E_C1_VARIANTE);

// Les libelles viennent des fichiers de traduction : le robot verifie le texte
// que l'ecran doit afficher, dans chaque langue.
const I18N = Object.fromEntries(['fr', 'ar'].map((c) => [c,
  JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${c}.i18n.json`), 'utf8'))]));
const cle = (code, chemin) => chemin.split('.').reduce((o, k) => o[k], I18N[code]);
const nettoyer = (s) => s.replace(/[⁨⁩]/g, '').replace(/ /g, ' ');
const echapper = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const motif = (code, chemin, vars = {}, { debut = true, fin = false } = {}) => {
  let s = nettoyer(cle(code, chemin));
  const morceaux = s.split(/\{(\w+)\}/);
  // Les valeurs sont entourees d'isolants bidirectionnels en arabe (U+2068,
  // U+2069), parfois rendus en espace : on les tolere.
  const iso = '[\\u2068\\u2069\\s]*';
  const re = morceaux.map((m, i) => (i % 2 ? `${iso}${echapper(String(vars[m] ?? ''))}${iso}` : echapper(m))).join('');
  return new RegExp(`${debut ? '^' : ''}${re.replace(/ /g, '[\\s\\u00a0]')}${fin ? '$' : ''}`);
};

const p = await parcours('CAHIER-C1 : la position de reprise automatique (salle, preparation, remplacant)', 'cahier-c1');
const verifier = (condition, libelle) => {
  if (!condition) throw new Error(`ROUGE : ${libelle}`);
  p.dire(`  OK ${libelle}`);
};
const vers = async (page, chemin) => {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(4000);
  await activerSemantique(page);
};

/// Le second enseignant (le remplacant), cree en SQL LOCAL comme l'amorce.
function amorcerRemplacant() {
  sql(`with existant as (select id from auth.users where email = '${REMPLACANT}'),
    nouveau as (
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
        email_change_token_new, email_change)
      select '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
        '${REMPLACANT}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
        '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
      where not exists (select 1 from existant) returning id),
    ident as (
      insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at, last_sign_in_at)
      select gen_random_uuid(), n.id, n.id::text,
        jsonb_build_object('sub', n.id::text, 'email', '${REMPLACANT}', 'email_verified', true), 'email', now(), now(), now()
      from nouveau n returning user_id)
    select 1`);
  const id = sql(`select id from auth.users where email = '${REMPLACANT}'`);
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${id}', 'E2E-PROF-C1', 'teacher', 'E2E Remplacant', 'C1', 'provisional_active', 'male')
       on conflict (id) do nothing;
     insert into public.teacher_profiles (profile_id, country, languages, kyc_status)
       values ('${id}', 'FR', '{fr}', 'approved') on conflict (profile_id) do update set kyc_status = 'approved'`);
  sql(`DO $$
    DECLARE v_nda text; v_notice text;
    BEGIN
      IF (SELECT account_status FROM public.profiles WHERE id = '${id}') = 'active' THEN RETURN; END IF;
      SELECT version INTO v_nda FROM public.contract_texts WHERE contract_kind='teacher_nda' AND locale='fr' AND is_current;
      SELECT version INTO v_notice FROM public.contract_required_versions WHERE contract_kind='recording_and_control_notice';
      PERFORM set_config('request.jwt.claim.sub', '${id}', true);
      PERFORM set_config('request.jwt.claims', '{"sub":"${id}","role":"authenticated","app_metadata":{"role":"teacher"}}', true);
      PERFORM public.signer_contrat(v_nda, 'E2E Remplacant C1');
      INSERT INTO public.contract_acceptances(profile_id, contract_kind, version)
        VALUES ('${id}', 'recording_and_control_notice', v_notice) ON CONFLICT DO NOTHING;
      INSERT INTO public.contract_acceptances(profile_id, contract_kind, version)
        VALUES ('${id}', 'teacher_conduct_code', public.code_conduite_version_requise()) ON CONFLICT DO NOTHING;
      UPDATE public.profiles SET account_status = 'active' WHERE id = '${id}';
    END $$`);
  return id;
}

/// Une Classe neuve, ses deux seances et le remplacement de s2 (SQL LOCAL).
function preparerClasse(nomVariante, profId, rempId) {
  const libelle = `E2E C1 ${nomVariante} ${Date.now().toString(36)}`;
  // Un decalage propre a ce passage : deux passages ne se recouvrent jamais.
  const decalage = `interval '${1000 + (Math.floor(Date.now() / 60000) % 50000)} days'`;
  // Une presence restee ouverte d'un passage precedent ramenerait la salle
  // sur l'ancienne seance : elle est fermee (banc local).
  sql(`insert into public.session_events (session_id, profile_id, event_type, server_ts, source)
       select j.session_id, j.profile_id, 'left', now(), 'livekit_webhook'
         from public.session_events j join public.sessions s on s.id = j.session_id
         join public.groupes g on g.id = s.groupe_id
        where g.libelle like 'E2E C1 %' and j.event_type = 'joined'
          and not exists (select 1 from public.session_events l where l.session_id = j.session_id
                            and l.profile_id = j.profile_id and l.event_type = 'left' and l.server_ts >= j.server_ts)`);
  // Une seance d'un passage precedent restee « en cours » rouvrirait la salle
  // sur elle : elle est close (banc local).
  sql(`update public.sessions s set finance_started_at = s.started_at, finance_ended_at = s.ended_at, status = 'ended'
       from public.groupes g where g.id = s.groupe_id and g.libelle like 'E2E C1 %' and s.status = 'in_progress'`);
  // Les seances des passages precedents de ce robot sont decalees dans le
  // passe (banc local seulement) : la Journee ne propose que celles du
  // passage en cours.
  sql(`update public.sessions s set started_at = s.started_at - ${decalage}, ended_at = s.ended_at - ${decalage}
       from public.groupes g where g.id = s.groupe_id and g.libelle like 'E2E C1 %' and s.ended_at > now() - interval '2 hours'`);
  // Les Classes des passages precedents sont closes (banc local) : leur
  // creneau du jour ne doit plus s'afficher dans la Journee.
  sql(`update public.groupes set ended_at = now(), ended_by = '${profId}', end_reason = 'Banc E2E CAHIER-C1'
       where libelle like 'E2E C1 %' and ended_at is null`);
  // La creation d'une Classe materialise ses seances hebdomadaires : un autre
  // jour que celui-ci, et une heure libre pour l'enseignant de test.
  let groupe = null;
  for (let essai = 0; essai < 48 && !groupe; essai++) {
    const heure = Math.floor(Math.random() * 24);
    try {
      groupe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
         values ('${profId}', 'adulte', 6, '${libelle}', ((extract(isodow from now())::int + 2) % 7) + 1, ${heure}, 'Europe/Paris')
         returning id`).split('\n')[0];
    } catch (_) { /* heure prise : une autre */ }
  }
  if (!groupe) throw new Error('aucune heure libre pour la Classe d\'essai');
  // Seules s1 et s2 comptent : les seances materialisees partent dans le passe.
  sql(`update public.sessions set started_at = started_at - ${decalage} - interval '200 days', ended_at = ended_at - ${decalage} - interval '200 days'
       where groupe_id = '${groupe}'`);
  const s1 = sql(`insert into public.sessions (teacher_id, started_at, ended_at, status, groupe_id)
     values ('${profId}', now() - interval '25 minutes', now() + interval '8 minutes', 'planned', '${groupe}') returning id`).split('\n')[0];
  const s2 = sql(`insert into public.sessions (teacher_id, started_at, ended_at, status, groupe_id)
     values ('${profId}', now() + interval '9 minutes', now() + interval '69 minutes', 'planned', '${groupe}') returning id`).split('\n')[0];
  sql(`insert into public.remplacements_seance (session_id, evenement, enseignant_titulaire_id, enseignant_remplacant_id, acteur_id, cle_idempotence, cree_le)
     values ('${s2}', 'absence_declaree', '${profId}', null, '${profId}', gen_random_uuid(), clock_timestamp()),
            ('${s2}', 'remplacement_pris', '${profId}', '${rempId}', '${rempId}', gen_random_uuid(), clock_timestamp() + interval '1 millisecond')`);
  return { libelle, groupe, s1, s2 };
}

/// Ouvre la Bibliotheque du Coran, au telephone par le tiroir des commandes.
async function ouvrirBibliotheque(acteur, code) {
  const coran = motif(code, 'salle.supports.coran');
  if (await trouver(acteur.page, coran, { delai: 4000 })) return true;
  const commandes = await trouver(acteur.page, motif(code, 'salle.seance.commandes.declencheurSemantique'), { delai: 4000 })
    ?? await trouver(acteur.page, motif(code, 'salle.seance.commandes.declencheur'), { delai: 2000 });
  if (commandes) { await commandes.click(); await acteur.page.waitForTimeout(1500); }
  const onglet = await trouver(acteur.page, motif(code, 'salle.seance.commandes.ongletSupport'), { delai: 3000 });
  if (onglet) { await onglet.click(); await acteur.page.waitForTimeout(1500); }
  return !!(await trouver(acteur.page, coran, { delai: 6000 }));
}

/// Rejoint la salle depuis la Journee (premier bouton « Rejoindre la salle »).
async function rejoindre(acteur, code, classe) {
  const precis = motif(code, 'enseignant.journee.rejoindreSalleLecteur', { classe });
  const bouton = await trouver(acteur.page, precis, { delai: 30000 })
    ?? await trouver(acteur.page, motif(code, 'enseignant.journee.rejoindreSalle'), { delai: 5000 });
  if (!bouton) {
    await p.capture(acteur, 'echec_rejoindre');
    throw new Error(`${acteur.role} : aucun « Rejoindre la salle » ; ecran : ${(await libelles(acteur.page)).slice(0, 40).join(' | ')}`);
  }
  await amenerEnVue(acteur.page, bouton);
  await bouton.click();
  await acteur.page.waitForTimeout(8000);
  await activerSemantique(acteur.page);
  if (!acteur.page.url().includes('/salle')) {
    await p.capture(acteur, 'echec_rejoindre');
    p.dire(`  url ${acteur.page.url()} ; ecran : ${(await libelles(acteur.page)).slice(0, 40).join(' | ')}`);
  }
  verifier(acteur.page.url().includes('/salle'), `${acteur.role} : « Rejoindre la salle » ouvre la salle`);
}

let code = 1;
try {
  const profId = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  if (!profId) throw new Error('enseignant de test absent : lancer tool/e2e/amorcer.sh');
  const rempId = amorcerRemplacant();
  for (const v of VARIANTES) {
    p.dire(`-- variante ${v.nom}`);
    const c = preparerClasse(v.nom, profId, rempId);
    p.dire(`  Classe « ${c.libelle} » ${c.groupe} ; s1 ${c.s1} ; s2 ${c.s2} (remplacee)`);

    // 2. L'enseignant presente une page pendant s1.
    const e = await p.contexte(`enseignant_${v.nom}`, { vue: v.vue, langue: v.langue });
    await connecter(e.page, COMPTES.enseignant);
    await rejoindre(e, v.code, c.libelle);
    await p.capture(e, '1_salle');
    const ouvrir = await trouver(e.page, motif(v.code, 'salle.ouvrirCoran', {}, { fin: true }), { delai: 3000 });
    if (ouvrir) { await ouvrir.click(); await e.page.waitForTimeout(2000); }
    else verifier(await ouvrirBibliotheque(e, v.code), 'enseignant : le Coran dans la Bibliotheque');
    const coran = await trouver(e.page, motif(v.code, 'salle.supports.coran'), { delai: 3000 });
    if (coran) { await amenerEnVue(e.page, coran); await coran.click(); await e.page.waitForTimeout(3000); }
    const presenter = await trouver(e.page, motif(v.code, 'enseignant.salle.presenterSourate', { deSourate: '' }), { delai: 8000, role: 'button' })
      ?? await trouver(e.page, motif(v.code, 'salle.seance.bibliotheque.presenter'), { delai: 3000, role: 'button' });
    if (!presenter) throw new Error(`enseignant : aucun « Présenter » ; ecran : ${(await libelles(e.page)).slice(0, 30).join(' | ')}`);
    p.dire(`  geste : ${(await presenter.getAttribute('aria-label')) ?? ''}`);
    await presenter.click();
    await e.page.waitForTimeout(4000);
    const premiere = sql(`select page from public.classe_position_reprise where groupe_id = '${c.groupe}'`);
    p.dire(`  base apres « Présenter » : page ${premiere}`);
    // Un changement de page part aussi au serveur : « page precedente ».
    const precedente = await trouver(e.page, motif(v.code, 'salle.seance.pagePrecedente'), { delai: 4000 })
      ?? await trouver(e.page, motif(v.code, 'enseignant.salle.precedente'), { delai: 2000 });
    if (precedente) { await precedente.click(); await e.page.waitForTimeout(4000); }
    await p.capture(e, '2_page_presentee');
    const page = sql(`select page from public.classe_position_reprise where groupe_id = '${c.groupe}'`);
    verifier(/^\d+$/.test(page), `base : la page presentee est retenue pour la Classe (page ${page})`);
    if (precedente) verifier(Number(page) === Number(premiere) - 1, `base : la page precedente remplace la premiere (${premiere} puis ${page})`);
    verifier(sql(`select session_id from public.classe_position_reprise where groupe_id = '${c.groupe}'`) === c.s1,
      'base : la page est rattachee a la seance de l\'enseignant');

    // L'enseignant quitte la salle.
    const quitter = await trouver(e.page, motif(v.code, 'salle.quitter', {}, { fin: true }), { delai: 4000 })
      ?? await trouver(e.page, motif(v.code, 'salle.seance.sortir'), { delai: 3000 });
    if (quitter) {
      await quitter.click();
      await e.page.waitForTimeout(1500);
      const confirmer = await trouver(e.page, motif(v.code, 'salle.seance.quitterCahier'), { delai: 3000 })
        ?? await trouver(e.page, motif(v.code, 'salle.seance.sortir', {}, { fin: true }), { delai: 2000, role: 'button' })
        ?? await trouver(e.page, motif(v.code, 'salle.quitterLeCours', {}, { fin: true }), { delai: 2000, role: 'button' });
      await p.capture(e, '2b_quitter_question');
      p.dire(`  sortie : confirmation ${confirmer ? `« ${(await confirmer.getAttribute('aria-label')) ?? (await confirmer.textContent())} »` : 'introuvable'} ; ecran : ${(await libelles(e.page)).filter((x) => /uitter|ester/.test(x)).join(' | ')}`);
      if (confirmer) { await confirmer.click(); await e.page.waitForTimeout(6000); }
      await activerSemantique(e.page);
      await p.capture(e, '2c_apres_quitter');
      p.dire(`  apres la confirmation : ${(await libelles(e.page)).slice(0, 12).join(' | ')}`);
    }
    p.dire(`  apres « Quitter » : ${e.page.url().replace(/^.*#/, '#')}`);
    // L'ecran de fin s'affiche sur la meme adresse : on verifie que les
    // commandes de l'appel ont disparu.
    verifier(!(await trouver(e.page, motif(v.code, 'salle.quitter', {}, { fin: true }), { delai: 2000, role: 'button' })),
      'enseignant : il a quitte la salle (plus de « Quitter »)');

    // 3. La preparation de la seance suivante, dans la fiche de la Classe.
    await vers(e.page, `/enseignant/groupe/${c.groupe}`);
    const attendu = motif(v.code, 'cahierC1.onReprendPage', { page }, { debut: false });
    const lu = await trouverTexte(e.page, attendu, 20000);
    if (lu) {
      const n = await trouver(e.page, attendu, { delai: 3000 });
      if (n) await amenerEnVue(e.page, n);
    }
    await p.capture(e, '3_preparation_on_reprend');
    verifier(!!lu, `fiche de la Classe : « ${nettoyer(cle(v.code, 'cahierC1.onReprendPage')).replace('{page}', page)} » (${lu ?? 'absent'})`);
    await e.ctx.close();

    // 4. Le remplacant, sur un autre navigateur, entre dans la salle de s2.
    const r = await p.contexte(`remplacant_${v.nom}`, { vue: v.vue, langue: v.langue });
    await connecter(r.page, REMPLACANT);
    await p.capture(r, '4_journee');
    await rejoindre(r, v.code, c.libelle);
    const biblio = await ouvrirBibliotheque(r, v.code);
    p.dire(`  remplacant : Bibliotheque ${biblio ? 'ouverte' : 'introuvable'}`);
    const vuParR = await trouverTexte(r.page, attendu, 20000);
    if (vuParR) {
      const n = await trouver(r.page, attendu, { delai: 3000 });
      if (n) await amenerEnVue(r.page, n);
    }
    await p.capture(r, '5_salle_on_reprend');
    verifier(!!vuParR, `remplacant : « On reprend page ${page} » dans la salle de la seance remplacee (${vuParR ?? 'absent'})`);
    const reprendre = await trouver(r.page, motif(v.code, 'salle.seance.bibliotheque.reprendrePage', { page }), { delai: 4000 });
    p.dire(`  remplacant : action « Reprendre page ${page} » ${reprendre ? 'presente' : 'absente'}`);
    await r.ctx.close();
  }
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
