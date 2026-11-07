// CAHIER-C2 (06/11/2026) : le programme en donnees, de bout en bout, sur la
// pile LOCALE (rien n'ecrit en production).
// Pour chaque variante (1440 et 390, francais et arabe) :
//   1. la direction cree une version vide, la preremplit avec la proposition
//      des bases, ouvre les objectifs et durees d'une etape, publie la version ;
//      la base dit la version publiee et ses 4 etapes completes (SQL) ;
//   2. une Classe neuve de l'enseignant de test sur l'etape 1 de cette version,
//      un eleve de 6 a 9 ans place a l'etape 2 (SQL LOCAL) ;
//   3. l'enseignant ouvre la fiche de l'eleve depuis la fiche de la Classe :
//      « Lire avec les voyelles », ses objectifs, et la date a laquelle
//      l'etape doit etre finie (18 semaines apres la decision).
// Usage : node tool/e2e/cahier_c2.mjs   (apres pile.sh, amorcer.sh)
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, trouverTexte, libelles, amenerEnVue,
  activerSemantique, sql, COMPTES, DEPOT } from './commun.mjs';

const VARIANTES = [
  { nom: '1440_fr', vue: { width: 1440, height: 900 }, langue: 'fr-FR', code: 'fr' },
  { nom: '390_fr', vue: { width: 390, height: 844 }, langue: 'fr-FR', code: 'fr' },
  { nom: '1440_ar', vue: { width: 1440, height: 900 }, langue: 'ar-SA', code: 'ar' },
  { nom: '390_ar', vue: { width: 390, height: 844 }, langue: 'ar-SA', code: 'ar' },
].filter((v) => !process.env.E2E_C2_VARIANTE || v.nom === process.env.E2E_C2_VARIANTE);

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

const p = await parcours('CAHIER-C2 : le programme en donnees (direction, fiche de l\'eleve)', 'cahier-c2');
const verifier = (condition, libelle) => {
  if (!condition) throw new Error(`ROUGE : ${libelle}`);
  p.dire(`  OK ${libelle}`);
};
const vers = async (page, chemin) => {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(4000);
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

/// Un eleve de 6 a 9 ans, son foyer, et la Classe neuve (SQL LOCAL).
function preparerClasse(nomVariante, profId, adminId, versionId) {
  const suffixe = `${nomVariante}-${Date.now().toString(36)}`;
  const libelle = `E2E C2 ${suffixe}`;
  const n1 = sql(`select id from public.programme_niveaux where version_id = '${versionId}' and ordre = 1`);
  const n2 = sql(`select id from public.programme_niveaux where version_id = '${versionId}' and ordre = 2`);
  sql(`update public.groupes set ended_at = now(), ended_by = '${profId}', end_reason = 'Banc E2E CAHIER-C2'
       where libelle like 'E2E C2 %' and ended_at is null`);
  let groupe = null;
  for (let essai = 0; essai < 48 && !groupe; essai++) {
    const heure = Math.floor(Math.random() * 24);
    try {
      groupe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, programme_niveau_id)
         values ('${profId}', 'enfant', 5, '${libelle}', ((extract(isodow from now())::int + 3) % 7) + 1, ${heure}, 'Europe/Paris', '${n1}')
         returning id`).split('\n')[0];
    } catch (_) { /* heure prise : une autre */ }
  }
  if (!groupe) throw new Error('aucune heure libre pour la Classe d\'essai');
  const eleve = sql(`with u as (
      insert into auth.users (instance_id, id, aud, role, email, created_at, updated_at)
      values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
              'e2e-eleve-c2-${suffixe}@example.com', now(), now()) returning id),
    f as (insert into public.households (id, timezone) values (gen_random_uuid(), 'Europe/Paris') returning id)
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    select u.id, 'E2E-C2-' || upper(substr(md5(u.id::text), 1, 6)), 'student', f.id, 'Yasmine', 'C2', 'active', 'female'
      from u, f returning id`).split('\n')[0];
  sql(`insert into public.student_profiles (profile_id, student_type, interface_mode, cohorte)
       values ('${eleve}', 'minor', 'child', 'enfant_6_9');
     insert into public.groupe_membres (groupe_id, student_id) values ('${groupe}', '${eleve}');
     insert into public.progression_historique (student_id, niveau_id, type_mouvement, decide_par, motif)
       values ('${eleve}', '${n2}', 'diagnostic_initial', '${adminId}', 'Banc E2E CAHIER-C2')`);
  return { libelle, groupe, eleve };
}

let code = 1;
try {
  const profId = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  const adminId = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  if (!profId || !adminId) throw new Error('comptes de test absents : lancer tool/e2e/amorcer.sh');
  for (const v of VARIANTES) {
    p.dire(`-- variante ${v.nom}`);
    // 1. La direction : version vide, proposition des bases, publication.
    const a = await p.contexte(`direction_${v.nom}`, { vue: v.vue, langue: v.langue });
    await connecter(a.page, COMPTES.direction);
    await vers(a.page, '/admin/pedagogie/programmes');
    // Banc local : les versions publiees des passages precedents sont
    // archivees, pour rejouer « aucune version publiee » (la mention de
    // proposition ne vaut que dans ce cas).
    sql("update public.programme_versions set statut = 'archivee' where statut = 'publiee'");
    const avant = Number(sql('select coalesce(max(numero_version), 0) from public.programme_versions'));
    await appuyer(a, motif(v.code, 'admin.programmes.creerVersion', {}, { fin: true }), 'Créer une version');
    await appuyer(a, motif(v.code, 'admin.programmes.enregistrerVersion', {}, { fin: true }), 'Enregistrer la version', { role: 'button' });
    const versionId = sql(`select id from public.programme_versions where numero_version = ${avant + 1}`);
    verifier(!!versionId, `base : version ${avant + 1} creee en brouillon`);
    await p.capture(a, '1_brouillon_vide');
    await appuyer(a, motif(v.code, 'admin.programmes.contenu.preremplir', {}, { fin: true }), 'Préremplir les bases');
    await p.capture(a, '2_proposition_question');
    await appuyer(a, motif(v.code, 'admin.programmes.contenu.preremplirEnvoyer', {}, { fin: true }), 'Ajouter la proposition', { role: 'button' });
    await a.page.waitForTimeout(2000);
    await p.capture(a, '3_quatre_etapes');
    verifier(!!(await trouverTexte(a.page, motif(v.code, 'admin.programmes.contenu.proposition', {}, { fin: true }), 10000)),
      'ecran : le brouillon est marque « Proposition a valider par la direction »');
    verifier(sql(`select count(*) from public.programme_niveaux where version_id = '${versionId}'
                   and cardinality(objectifs) between 3 and 5`) === '4', 'base : 4 etapes proposees, 3 a 5 objectifs chacune');
    const pret = await trouverTexte(a.page, motif(v.code, 'admin.programmes.contenu.pret', {}, { fin: true }), 10000);
    verifier(!!pret, `ecran : l'etat « ${nettoyer(cle(v.code, 'admin.programmes.contenu.pret'))} » s'affiche`);
    // Les objectifs et durees de l'etape 2, par le menu de sa ligne.
    p.dire(`  libelles de l'etape 2 : ${(await libelles(a.page)).filter((x) => /voyelles/.test(x)).join(' | ')}`);
    await appuyer(a, motif(v.code, 'commun.listes.actionsDe', { objet: 'Lire avec les voyelles' }, { debut: false }), 'menu de l etape 2');
    await appuyer(a, motif(v.code, 'admin.programmes.contenu.ouvrir', {}, { fin: true }), 'Objectifs et durées');
    // Le texte d'un champ Flutter web n'est pas lisible par le DOM : le robot
    // verifie la feuille ouverte (titre, champs), la capture montre le texte.
    const objectif = await trouver(a.page, motif(v.code, 'admin.programmes.contenu.objectifNumero', { numero: '3' }), { delai: 10000 })
      ?? await trouver(a.page, motif(v.code, 'admin.programmes.contenu.titre', { nom: 'Lire avec les voyelles' }), { delai: 3000 });
    p.dire(`  feuille : ${(await libelles(a.page)).slice(0, 12).join(' | ')}`);
    await p.capture(a, '4_objectifs_et_durees');
    verifier(!!objectif, 'feuille : « Objectifs et durees » de l\'etape 2 ouverte (texte preremplis : voir la capture)');
    await a.page.keyboard.press('Escape');
    await a.page.waitForTimeout(1500);
    // La publication.
    await appuyer(a, motif(v.code, 'admin.programmes.publierVersion', {}, { fin: true }), 'Publier la version', { role: 'button' });
    const motifChamp = a.page.locator('textarea, input[type=text]').last();
    await motifChamp.fill('Version des bases, banc E2E C2');
    await appuyer(a, motif(v.code, 'admin.programmes.publierVersionEnvoyer', {}, { fin: true }), 'Publier', { role: 'button' });
    await a.page.waitForTimeout(2500);
    await p.capture(a, '5_publiee');
    verifier(sql(`select statut from public.programme_versions where id = '${versionId}'`) === 'publiee',
      'base : la version est publiee');
    await a.ctx.close();

    // 2. La Classe et l'eleve (SQL LOCAL).
    const c = preparerClasse(v.nom, profId, adminId, versionId);
    p.dire(`  Classe « ${c.libelle} » ${c.groupe} ; eleve ${c.eleve} (6-9 ans, etape 2)`);
    const attendue = sql(`select to_char(now()::date + 18 * 7, 'YYYY-MM-DD')`);

    // 3. L'enseignant ouvre la fiche de l'eleve.
    const e = await p.contexte(`enseignant_${v.nom}`, { vue: v.vue, langue: v.langue });
    await connecter(e.page, COMPTES.enseignant);
    await vers(e.page, `/enseignant/groupe/${c.groupe}`);
    await appuyer(e, /Yasmine/, 'ligne de l eleve');
    const etape = await trouverTexte(e.page, /Lire avec les voyelles/, 15000);
    const n = await trouver(e.page, /Lire avec les voyelles/, { delai: 3000 });
    if (n) await amenerEnVue(e.page, n);
    await p.capture(e, '6_fiche_eleve_etape');
    verifier(!!etape, 'fiche de l\'eleve : l\'etape « Lire avec les voyelles » s\'affiche');
    const [annee, mois, jour] = attendue.split('-').map(Number);
    const date = motif(v.code, 'enseignant.eleve.aFinirAvantDate', {
      numero: String(jour), mois: cle(v.code, 'commun.dates.mois')[mois - 1], annee: String(annee), prevue: '14',
    }, { debut: false });
    const lu = await trouverTexte(e.page, date, 10000);
    const d = await trouver(e.page, date, { delai: 3000 });
    if (d) await amenerEnVue(e.page, d);
    await p.capture(e, '7_fiche_eleve_date_limite');
    verifier(!!lu, `fiche de l'eleve : a finir avant le ${attendue}, 14 semaines prevues (${lu ?? 'absent'})`);
    await e.ctx.close();
  }
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
