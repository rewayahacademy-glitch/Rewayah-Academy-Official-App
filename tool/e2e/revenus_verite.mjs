// REVENUS-VERITE (pilote, 06/11/2026, points 2, 3, 4 et 6) sur la pile LOCALE.
//
// Donnees (SQL local seulement, idempotent) : pour l'enseignant amorce
// (amorcer.sh), une Classe d'enfants « Al-Nour E2E », deux eleves inscrits a
// une seance tenue ce mois-ci : Yasmine presente (arrivee mesuree), Nour
// absente ; l'enseignant connecte 60 minutes ; le cahier de la seance depose.
// Le serveur ecrit la paie a la cloture (private.pai_due_seance) : 1 eleve
// present x taux enfant x 1 h.
//
// Ce que le parcours prouve, a 390 et 1440, en francais et en arabe :
//   * Profil de l'enseignant : la ligne « Mes revenus » dit les heures
//     assurees du mois, lues au serveur ;
//   * Mes revenus : les heures du mois, le jour de paie (du 1er au 10 du mois
//     suivant, reglage paie.fenetre_versement), la seance, Yasmine presente et
//     son montant, Nour absente a 0 ; aucun « base garantie », « plafond »,
//     « sieges eligibles » ;
//   * Direction > Politique commerciale : la section « Remuneration des
//     enseignants » dit la regle par eleve present (memes textes que
//     l'enseignant), sans « composante d'occupation » ; l'apercu se calcule au
//     serveur (apercu_paie_enseignant), sans erreur ;
//   * Direction > Configuration > Regles : la section « Paie des enseignants »
//     (jour de paie, reglage de la direction) ; a 1440 en francais, le dernier
//     jour passe de 10 a 11 par l'interface et la base le relit.
// Usage : node tool/e2e/revenus_verite.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, activerSemantique, trouver, trouverTexte, taper, sql, DEPOT, COMPTES, MDP } from './commun.mjs';

const p = await parcours('REVENUS-VERITE : revenus de l enseignant et politique commerciale', 'revenus-verite');
let code = 1;
const LANGUES = {
  fr: JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8')),
  ar: JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/ar.i18n.json'), 'utf8')),
};
const sansIsolats = (s) => s.replace(/[\u2066-\u2069]/g, '').replace(/\u00a0/g, ' ');
const motif = (s) => new RegExp(sansIsolats(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/ /g, '[\\s\\u00a0]'), 'i');
// Le plus long morceau litteral d'un texte a parametres : « assurées en ».
const litteral = (s) => motif(sansIsolats(s).split(/\{[^}]*\}/).map((x) => x.trim())
  .sort((a, b) => b.length - a.length)[0]);

// La connexion de commun.mjs cherche « J'ai deja un compte » en francais, et
// rouvre la page : en arabe, on touche le meme bouton dans sa langue, puis on
// saisit sans recharger.
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

const P = 'ae300000-0000-4000-8000-0000000000';
const SEANCE = 'ae300000-0000-4000-8000-000000000501';

function amorcer() {
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  if (!prof || !admin) throw new Error('comptes amorces absents : lancer tool/e2e/amorcer.sh');
  if (sql(`select status from public.sessions where id = '${SEANCE}'`) === 'ended') return prof;
  sql(`
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;
INSERT INTO auth.users(id, email) VALUES ('${P}e1', 'e2e-rv-e1@example.com'), ('${P}e2', 'e2e-rv-e2@example.com')
  ON CONFLICT DO NOTHING;
INSERT INTO public.households(id, timezone) VALUES ('${P}f1', 'Europe/Paris') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('${P}e1', 'E2E-RV-ELV-1', 'student', '${P}f1', 'Yasmine', 'E2E', 'active', 'male'),
  ('${P}e2', 'E2E-RV-ELV-2', 'student', '${P}f1', 'Nour', 'E2E', 'active', 'male')
  ON CONFLICT DO NOTHING;
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode) VALUES
  ('${P}e1', 'minor', 'standard'), ('${P}e2', 'minor', 'standard') ON CONFLICT DO NOTHING;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
  VALUES ('ae300000-0000-4000-8000-000000000c01', '${prof}', 'enfant', 5, 'Al-Nour E2E', 1, 9, 'Europe/Paris')
  ON CONFLICT DO NOTHING;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, status, groupe_id)
  SELECT '${SEANCE}', '${prof}', d, d + interval '60 minutes', 'planned', 'ae300000-0000-4000-8000-000000000c01'
    FROM (SELECT greatest(date_trunc('month', now()) + interval '9 hours',
                          date_trunc('hour', now()) - interval '1 day') AS d) x
  ON CONFLICT DO NOTHING;
INSERT INTO public.session_participants(session_id, profile_id, role) VALUES
  ('${SEANCE}', '${P}e1', 'student'), ('${SEANCE}', '${P}e2', 'student') ON CONFLICT DO NOTHING;
INSERT INTO public.session_events(session_id, profile_id, event_type, server_ts, source)
  SELECT '${SEANCE}', x.p::uuid, x.t::public.session_event_type, s.started_at + x.m * interval '1 minute', 'livekit_webhook'
    FROM (VALUES ('${prof}', 'joined', 0), ('${prof}', 'left', 60), ('${P}e1', 'joined', 1)) AS x(p, t, m)
    JOIN public.sessions s ON s.id = '${SEANCE}';
INSERT INTO public.lesson_reports(session_id, idempotency_key, content, author_profile_id)
  VALUES ('${SEANCE}', 'e2e-rv-cahier', jsonb_build_object('version', 1, 'session_id', '${SEANCE}', 'eleves',
    jsonb_build_array(jsonb_build_object('student_id', '${P}e1', 'confirme', true),
                      jsonb_build_object('student_id', '${P}e2', 'confirme', true))), '${prof}')
  ON CONFLICT DO NOTHING;
ALTER TABLE public.sessions DISABLE TRIGGER sessions_tresorerie_timestamps;
UPDATE public.sessions SET status = 'preflight' WHERE id = '${SEANCE}';
UPDATE public.sessions SET status = 'in_progress' WHERE id = '${SEANCE}';
UPDATE public.sessions SET finance_started_at = started_at, finance_ended_at = started_at + interval '60 minutes',
  status = 'ended' WHERE id = '${SEANCE}';
ALTER TABLE public.sessions ENABLE TRIGGER sessions_tresorerie_timestamps;
COMMIT;`);
  return prof;
}

try {
  const prof = amorcer();
  const paie = sql(`select montant_minor from public.tresorerie_mouvements where source_id = '${SEANCE}'
    and regle = 'remuneration_due' and coffre = 'paie_a_decaisser' and sens = 'entree'`);
  if (!paie) throw new Error('aucune paie ecrite pour la seance de test');
  const fenetre = sql(`select value::text from public.app_config where key = 'paie.fenetre_versement'`);
  p.dire(`Enseignant ${prof} ; paie ecrite ${paie} (mineur) ; fenetre ${fenetre}`);
  const montant = (Number(paie) / 100).toFixed(2).replace('.', ',');
  const verdicts = {};
  for (const langue of ['fr', 'ar']) {
    const T = LANGUES[langue];
    const R = T.enseignant.revenus;
    const pol = T.admin.finance.pol;
    const locale = langue === 'ar' ? 'ar-SA' : 'fr-FR';
    for (const [largeur, hauteur] of [[390, 2600], [1440, 1800]]) {
      const cle = `${largeur}_${langue}`;
      const v = {};
      const ens = await p.contexte('enseignant', { vue: { width: largeur, height: hauteur }, langue: locale });
      await entrer(ens.page, COMPTES.enseignant, T);
      await ouvrir(ens.page, '/#/enseignant/profil');
      await activerSemantique(ens.page);
      v.profilTitre = Boolean(await trouverTexte(ens.page, motif(T.enseignant.profil.revenus), 20000));
      v.profilHeures = Boolean(await trouverTexte(ens.page, litteral(T.enseignant.profil.revenusHeures), 15000));
      await p.capture(ens, `${cle}_1_profil`);
      await ouvrir(ens.page, '/#/enseignant/revenus');
      await activerSemantique(ens.page);
      v.titre = Boolean(await trouverTexte(ens.page, motif(R.titre), 20000));
      v.versement = Boolean(await trouverTexte(ens.page, motif(R.versement), 10000));
      v.seances = Boolean(await trouverTexte(ens.page, motif(R.seancesSection), 10000));
      v.yasmine = Boolean(await trouverTexte(ens.page, /Yasmine/, 10000));
      v.nour = Boolean(await trouverTexte(ens.page, /Nour E2E|^Nour|Nour/, 10000));
      v.present = Boolean(await trouverTexte(ens.page, motif(R.present), 5000));
      v.absent = Boolean(await trouverTexte(ens.page, motif(R.absent), 5000));
      v.montant = Boolean(await trouverTexte(ens.page, new RegExp(montant.replace(',', '[,.٫]')), 5000));
      v.ancienModele = Boolean(await trouverTexte(ens.page, /garantie|plafond|éligible|occupation/i, 2000));
      await p.capture(ens, `${cle}_2_revenus`);
      await ens.page.mouse.wheel(0, 2600); await ens.page.waitForTimeout(1500);
      await p.capture(ens, `${cle}_3_revenus_bas`);
      await ens.ctx.close();

      const dir = await p.contexte('direction', { vue: { width: largeur, height: hauteur }, langue: locale });
      const refus = [];
      dir.page.on('response', (r) => {
        if (r.url().includes('/rpc/apercu_paie_enseignant') && r.status() >= 400) refus.push(r.status());
      });
      let apercus = 0;
      dir.page.on('request', (r) => { if (r.url().includes('/rpc/apercu_paie_enseignant')) apercus += 1; });
      await entrer(dir.page, COMPTES.direction, T);
      await ouvrir(dir.page, '/#/admin/finance/politiques');
      await dir.page.waitForTimeout(3000); await activerSemantique(dir.page);
      v.section = Boolean(await trouverTexte(dir.page, motif(pol.enseignants), 20000));
      v.regleDirection = Boolean(await trouverTexte(dir.page, motif(T.commun.paieEnseignant.absent), 10000));
      v.occupationDirection = Boolean(await trouverTexte(dir.page, motif(LANGUES.fr.admin.finance.pol.occupation), 2000));
      await p.capture(dir, `${cle}_4_politique`);
      for (let i = 1; i <= 3; i++) {
        await dir.page.mouse.wheel(0, hauteur - 200); await dir.page.waitForTimeout(1500);
        await p.capture(dir, `${cle}_${4 + i}_politique_suite`);
      }
      v.apercuHeure = Boolean(await trouverTexte(dir.page, motif(pol.apercuHeure), 10000));
      v.apercus = apercus; v.refusApercu = refus;

      // Exige (4), garde-cap du 06/11 : le jour de paie se regle dans la
      // console de la direction, Configuration > Regles.
      const P2 = T.admin.regles.paie;
      await ouvrir(dir.page, '/#/admin/configuration/regles');
      await dir.page.waitForTimeout(2000); await activerSemantique(dir.page);
      for (let i = 0; i < 6; i++) { await dir.page.mouse.wheel(0, 1500); await dir.page.waitForTimeout(400); }
      v.reglagePaie = Boolean(await trouverTexte(dir.page, motif(P2.section), 15000));
      v.reglageDernier = Boolean(await trouverTexte(dir.page, motif(P2.fin), 5000));
      await p.capture(dir, `${cle}_8_reglage_jour_de_paie`);
      if (cle === '1440_fr') {
        const ligne = await trouver(dir.page, motif(P2.fin), { delai: 8000 });
        if (ligne) {
          await ligne.click(); await dir.page.waitForTimeout(1500);
          const plus = await trouver(dir.page, T.choix.augmenter, { delai: 8000 });
          if (plus) { await plus.click(); await dir.page.waitForTimeout(600); }
          await p.capture(dir, `${cle}_9_reglage_feuille`);
          const envoyer = await trouver(dir.page, T.admin.regles.envoyer, { delai: 8000, exact: true });
          if (envoyer) { await envoyer.click(); await dir.page.waitForTimeout(3000); }
        }
        v.ecrit = sql(`select value::text from public.app_config where key = 'paie.fenetre_versement'`);
        await p.capture(dir, `${cle}_10_reglage_enregistre`);
        // La pile locale revient au defaut pour les passages suivants.
        sql(`update public.app_config set value = '{"jourDebut": 1, "jourFin": 10}' where key = 'paie.fenetre_versement'`);
      }
      await dir.ctx.close();
      p.dire(`${cle} : ${JSON.stringify(v)}`);
      verdicts[cle] = v;
    }
  }
  fs.writeFileSync(path.join(p.sortie, 'constats.json'), JSON.stringify(verdicts, null, 2));
  const rouges = Object.entries(verdicts).filter(([k, v]) =>
    !v.profilTitre || !v.profilHeures || !v.titre || !v.versement || !v.seances || !v.yasmine || !v.nour
    || !v.present || !v.absent || !v.montant || v.ancienModele || !v.section || !v.regleDirection
    || v.occupationDirection || !v.apercuHeure || v.apercus < 1 || v.refusApercu.length
    || !v.reglagePaie || !v.reglageDernier
    || (k === '1440_fr' && v.ecrit !== '{"jourFin": 11, "jourDebut": 1}')).map(([k]) => k);
  if (rouges.length) throw new Error(`rouge a ${rouges.join(', ')}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
