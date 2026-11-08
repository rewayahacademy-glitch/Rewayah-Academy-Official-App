// REVENUS (pilote, 07/11/2026, file du garde-cap) sur la pile LOCALE.
//
// Donnees (SQL local seulement, idempotent) : pour l'enseignant amorce
// (amorcer.sh), une Classe d'enfants « An-Nasr E2E » et deux seances tenues
// ce mois-ci, l'enseignant connecte 60 minutes a chacune :
//   * seance payee : Yasmine presente toute la seance, Lina 9 minutes sur 60
//     (presente en partie, sous le seuil de 50 %), Nour absente ; cahier
//     depose ;
//   * seance non payee : Nour seule inscrite, absente.
// Le serveur ecrit la paie a la cloture (private.pai_due_seance) : 2 eleves
// payes (Yasmine et Lina) x taux enfant x 1 h ; la seance sans present, rien.
//
// Ce que le parcours prouve, a 390 et 1440, en francais et en arabe :
//   * le resume dit « A recevoir ce mois-ci » (montants des seances sans
//     attentes) ;
//   * une ligne par Classe, repliee : son nom et son montant, aucun detail ;
//   * toucher la ligne deplie la Classe : Yasmine « Presente », Lina
//     « Presente en partie » avec sa part, Nour « Absente » sans montant, la
//     phrase sur la presence en partie ; la seance sans present dit « seance
//     non payee », sans montant ;
//   * « Comment c'est calcule » est replie, puis deplie au toucher, avec
//     l'etape de la presence en partie ;
//   * aucun texte de l'ancien modele (garantie, plafond, eligible,
//     occupation).
// Usage : node tool/e2e/revenus.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, activerSemantique, trouver, trouverTexte, taper, sql, DEPOT, COMPTES, MDP } from './commun.mjs';

const p = await parcours('REVENUS : une ligne par Classe, detail au toucher, presence partielle, seance non payee', 'revenus');
let code = 1;
const LANGUES = {
  fr: JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8')),
  ar: JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/ar.i18n.json'), 'utf8')),
};
const sansIsolats = (s) => s.replace(/[\u2066-\u2069]/g, '').replace(/\u00a0/g, ' ');
const motif = (s) => new RegExp(sansIsolats(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/ /g, '[\\s\\u00a0]'), 'i');

// Meme connexion que revenus_verite.mjs : en arabe, le bouton dans sa langue.
async function entrer(page, courriel, T) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    for (const libelle of [T.inscription.questionnaire.dejaUnCompte, T.connexion.modeConnexion]) {
      const e = await trouver(page, sansIsolats(libelle), { delai: 6000, exact: true });
      if (e) { await e.click(); await page.waitForTimeout(1200); break; }
    }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', MDP);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await activerSemantique(page);
}

const P = 'ae400000-0000-4000-8000-0000000000';
const PAYEE = 'ae400000-0000-4000-8000-000000000501';
const NON_PAYEE = 'ae400000-0000-4000-8000-000000000502';
const CLASSE = 'ae400000-0000-4000-8000-000000000c01';

function amorcer() {
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  if (!prof) throw new Error('comptes amorces absents : lancer tool/e2e/amorcer.sh');
  if (sql(`select status from public.sessions where id = '${PAYEE}'`) === 'ended') return prof;
  sql(`
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;
INSERT INTO auth.users(id, email) VALUES ('${P}e1', 'e2e-rp-e1@example.com'), ('${P}e2', 'e2e-rp-e2@example.com'),
  ('${P}e3', 'e2e-rp-e3@example.com') ON CONFLICT DO NOTHING;
INSERT INTO public.households(id, timezone) VALUES ('${P}f1', 'Europe/Paris') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('${P}e1', 'E2E-RP-ELV-1', 'student', '${P}f1', 'Yasmine', 'E2E', 'active', 'female'),
  ('${P}e2', 'E2E-RP-ELV-2', 'student', '${P}f1', 'Lina', 'E2E', 'active', 'female'),
  ('${P}e3', 'E2E-RP-ELV-3', 'student', '${P}f1', 'Nour', 'E2E', 'active', 'female')
  ON CONFLICT DO NOTHING;
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
  ('${P}e1', 'minor', 'standard'), ('${P}e2', 'minor', 'standard'), ('${P}e3', 'minor', 'standard')
  ON CONFLICT DO NOTHING;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
  VALUES ('${CLASSE}', '${prof}', 'enfant', 5, 'An-Nasr E2E', 2, 10, 'Europe/Paris') ON CONFLICT DO NOTHING;
-- Deux seances passees du mois : la payee la veille, la non payee deux jours avant.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
  SELECT x.id::uuid, '${prof}', d - x.j * interval '1 day', d - x.j * interval '1 day' + interval '60 minutes', 'planned', '${CLASSE}'
    FROM (SELECT greatest(date_trunc('month', now()) + interval '2 days 10 hours',
                          date_trunc('hour', now()) - interval '1 day') AS d) b,
         (VALUES ('${PAYEE}', 0), ('${NON_PAYEE}', 1)) AS x(id, j)
  ON CONFLICT DO NOTHING;
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
  ('${PAYEE}', '${P}e1', 'student'), ('${PAYEE}', '${P}e2', 'student'), ('${PAYEE}', '${P}e3', 'student'),
  ('${NON_PAYEE}', '${P}e3', 'student') ON CONFLICT DO NOTHING;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
  SELECT x.s::uuid, x.p::uuid, x.t::public.session_event_type, s.started_at + x.m * interval '1 minute', 'livekit_webhook'
    FROM (VALUES ('${PAYEE}', '${prof}', 'joined', 0), ('${PAYEE}', '${prof}', 'left', 60),
                 ('${PAYEE}', '${P}e1', 'joined', 1),
                 ('${PAYEE}', '${P}e2', 'joined', 1), ('${PAYEE}', '${P}e2', 'left', 10),
                 ('${NON_PAYEE}', '${prof}', 'joined', 0), ('${NON_PAYEE}', '${prof}', 'left', 60)) AS x(s, p, t, m)
    JOIN public.sessions s ON s.id = x.s::uuid;
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
  VALUES ('${PAYEE}', 'e2e-rp-cahier', jsonb_build_object('version', 1, 'session_id', '${PAYEE}', 'eleves',
    jsonb_build_array(jsonb_build_object('student_id', '${P}e1', 'confirme', true),
                      jsonb_build_object('student_id', '${P}e2', 'confirme', true),
                      jsonb_build_object('student_id', '${P}e3', 'confirme', true))), '${prof}')
  ON CONFLICT DO NOTHING;
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id IN ('${PAYEE}', '${NON_PAYEE}');
UPDATE public.sessions SET status = 'in_progress' WHERE id IN ('${PAYEE}', '${NON_PAYEE}');
UPDATE public.sessions SET finance_started_at = started_at, finance_ended_at = started_at + interval '60 minutes',
  status = 'ended' WHERE id IN ('${PAYEE}', '${NON_PAYEE}');
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;
COMMIT;`);
  return prof;
}

try {
  const prof = amorcer();
  const paie = sql(`select montant_minor from public.tresorerie_mouvements where source_id = '${PAYEE}'
    and regle = 'remuneration_due' and coffre = 'paie_a_decaisser' and sens = 'entree'`);
  if (!paie) throw new Error('aucune paie ecrite pour la seance payee');
  // Ce que rend le serveur a l'enseignant, lu en son nom (la lecture que fait l'ecran).
  const lu = sql(`select set_config('request.jwt.claim.sub', '${prof}', true),
      set_config('request.jwt.claims', json_build_object('sub', '${prof}', 'role', 'authenticated',
        'app_metadata', json_build_object('role', 'teacher'))::text, true);
    set local role authenticated;
    select jsonb_pretty(jsonb_path_query_array(public.mes_revenus_enseignant(NULL),
      '$.seances[*] ? (@.classe == "An-Nasr E2E")'))`);
  fs.writeFileSync(path.join(p.sortie, 'serveur_seances.json'), lu ?? '');
  p.dire(`Enseignant ${prof} ; paie ecrite ${paie} (mineur) pour la seance payee`);
  const part = (Number(paie) / 2 / 100).toFixed(2);
  const verdicts = {};
  for (const langue of ['fr', 'ar']) {
    const T = LANGUES[langue];
    const R = T.enseignant.revenus;
    const locale = langue === 'ar' ? 'ar-SA' : 'fr-FR';
    for (const [largeur, hauteur] of [[390, 2600], [1440, 1800]]) {
      const cle = `${largeur}_${langue}`;
      const v = {};
      const ens = await p.contexte('enseignant', { vue: { width: largeur, height: hauteur }, langue: locale });
      await entrer(ens.page, COMPTES.enseignant, T);
      await ouvrir(ens.page, '/#/enseignant/revenus');
      await activerSemantique(ens.page);
      v.titre = Boolean(await trouverTexte(ens.page, motif(R.titre), 20000));
      v.aRecevoir = Boolean(await trouverTexte(ens.page, motif(R.aRecevoir), 10000));
      v.liste = Boolean(await trouverTexte(ens.page, motif(R.classesSection), 10000));
      v.classe = Boolean(await trouverTexte(ens.page, /An-Nasr E2E/, 10000));
      // Repliee : aucun detail tant que la ligne n'est pas touchee.
      v.repliee = !(await trouverTexte(ens.page, motif(R.presentPartiel), 2000));
      v.calculReplie = !(await trouverTexte(ens.page, motif(R.partielleDetail), 2000));
      await p.capture(ens, `${cle}_1_liste`);
      const ligne = await trouver(ens.page, /An-Nasr E2E/, { delai: 8000 });
      if (ligne) { await ligne.click(); await ens.page.waitForTimeout(1500); await activerSemantique(ens.page); }
      v.partiel = Boolean(await trouverTexte(ens.page, motif(R.presentPartiel), 10000));
      v.partielleNote = Boolean(await trouverTexte(ens.page, motif(R.partielleNote), 5000));
      v.aucunMontant = Boolean(await trouverTexte(ens.page, motif(R.aucunMontant), 5000));
      v.yasmine = Boolean(await trouverTexte(ens.page, /Yasmine/, 5000));
      v.lina = Boolean(await trouverTexte(ens.page, /Lina/, 5000));
      v.nour = Boolean(await trouverTexte(ens.page, /Nour/, 5000));
      v.part = Boolean(await trouverTexte(ens.page, new RegExp(part.replace('.', '[,.٫]')), 5000));
      v.ancienModele = Boolean(await trouverTexte(ens.page, /garantie|plafond|éligible|occupation/i, 2000));
      await p.capture(ens, `${cle}_2_classe_depliee`);
      await ens.page.mouse.wheel(0, hauteur - 300); await ens.page.waitForTimeout(1200);
      await p.capture(ens, `${cle}_3_classe_suite`);
      const calcul = await trouver(ens.page, motif(R.calculSection), { delai: 8000 });
      if (calcul) { await calcul.click(); await ens.page.waitForTimeout(1500); await activerSemantique(ens.page); }
      v.calculDeplie = Boolean(await trouverTexte(ens.page, motif(R.partielleDetail), 8000));
      await ens.page.mouse.wheel(0, hauteur); await ens.page.waitForTimeout(1200);
      await p.capture(ens, `${cle}_4_calcul_deplie`);
      await ens.ctx.close();
      p.dire(`${cle} : ${JSON.stringify(v)}`);
      verdicts[cle] = v;
    }
  }
  fs.writeFileSync(path.join(p.sortie, 'constats.json'), JSON.stringify(verdicts, null, 2));
  const rouges = Object.entries(verdicts).filter(([, v]) =>
    !v.titre || !v.aRecevoir || !v.liste || !v.classe || !v.repliee || !v.calculReplie || !v.partiel || !v.partielleNote
    || !v.aucunMontant || !v.yasmine || !v.lina || !v.nour || !v.part || v.ancienModele || !v.calculDeplie)
    .map(([k]) => k);
  if (rouges.length) throw new Error(`rouge a ${rouges.join(', ')}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
