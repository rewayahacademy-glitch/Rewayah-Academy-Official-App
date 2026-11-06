// Lot FOYER-UX (06/11/2026), preuve en local : l'eleve adulte inscrit « pour
// moi » ouvre son Foyer (UX-023 : « Vous suivez les cours », plus de « Créer
// mon profil élève ») et son Compte (la version en bas, decision du
// 03/11/2026). Captures 390 et 1440, francais et arabe.
//
// UX-009 n'a pas de capture : il faut une seance en cours dont la fenetre
// n'est pas rendue alors que l'horloge de la classe l'est ; la pile locale
// ne sait pas produire cet etat sur commande. Il est prouve par les tests
// (test/features/accueil_famille/ux009_un_seul_message_test.dart).
import { parcours, connecter, connecterParLien, cliquer, trouver, trouverTexte, libelles,
  allerOnglet, activerSemantique, ouvrir, COMPTES } from './commun.mjs';
import { questionnaire, inscrire, accepterDemande, nouveauCompte } from './inscription.mjs';

const t = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
const p = await parcours('FOYER-UX', 'foyer-ux');
const ecarts = [];
let code = 1;

async function basDePage(page) {
  for (let k = 0; k < 8; k++) { await page.mouse.wheel(0, 4000); await page.waitForTimeout(300); }
  await page.waitForTimeout(800);
}

async function preuves(a, langue) {
  for (const [w, h] of [[390, 844], [1440, 900]]) {
    await a.page.setViewportSize({ width: w, height: h });
    await allerOnglet(a.page, langue === 'fr' ? 'Foyer' : 'العائلة', '/tuteur/foyer', p.dire);
    await a.page.waitForTimeout(2500); await activerSemantique(a.page);
    await p.capture(a, `${langue}_${w}_foyer`);
    const l = (await libelles(a.page)).join(' | ');
    const moi = langue === 'fr' ? /Vous suivez les cours/ : /أنت تتابع الدروس/;
    const creer = langue === 'fr' ? /Créer mon profil élève/ : /إنشاء ملفي كطالب/;
    p.dire(`  ${langue} ${w} Foyer : « vous suivez » ${moi.test(l) ? 'present' : 'ABSENT'} ; « créer mon profil » ${creer.test(l) ? 'PRESENT' : 'absent'}`);
    if (!moi.test(l)) ecarts.push(`${langue} ${w} : « Vous suivez les cours » absent du Foyer`);
    if (creer.test(l)) ecarts.push(`${langue} ${w} : « Créer mon profil élève » encore propose`);
    await basDePage(a.page);
    await p.capture(a, `${langue}_${w}_foyer_bas`);
    await a.page.evaluate(() => { location.hash = '#/tuteur/compte'; });
    await a.page.waitForTimeout(3000); await activerSemantique(a.page);
    await basDePage(a.page);
    await p.capture(a, `${langue}_${w}_compte_bas`);
    const v = (await libelles(a.page)).find((x) => /Version \d+\.\d+\.\d+/.test(x));
    p.dire(`  ${langue} ${w} Compte : ${v ?? 'AUCUNE ligne de version lue dans l arbre'}`);
    if (!v) ecarts.push(`${langue} ${w} : ligne de version absente de l'arbre d'accessibilite`);
  }
}

try {
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  const A = { courriel: `e2e-foyer-ux-${t}@example.com`, prenom: 'E2E Amina', nom: `FoyerUx${t}` };
  const a = await p.contexte('adulte', { telephone: true });
  await nouveauCompte(a, /^Je m'inscris pour moi/);
  await cliquer(a.page, /^Continuer$/);
  const q = await questionnaire(p, a, [
    { q: /Comment vous appelez-vous|Votre prénom/, saisie: A.prenom },
    { q: /Vous êtes…|Êtes-vous/, choix: /^Une femme$/ },
    { q: /Dans quelle langue/, choix: /^Français$/ },
    { q: /Où en êtes-vous aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
    { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
    { q: /Quels moments/, choix: /^Le soir$/ },
  ], 'questionnaire');
  if (q) throw new Error(`questionnaire arrete sur « ${q} »`);
  await inscrire(p, a, { courriel: A.courriel, prenom: A.prenom, nom: A.nom, genre: /^Une femme/ }, 'inscription');
  await accepterDemande(p, d, { liste: 'Élèves adultes', nomComplet: `${A.prenom} ${A.nom}` });
  await connecterParLien(a.page, A.courriel);
  await a.page.waitForTimeout(3000);
  await preuves(a, 'fr');

  // Arabe : meme session, navigateur en arabe (langue suivie au demarrage).
  const stockage = await a.page.evaluate(() => JSON.stringify(Object.entries(localStorage)));
  const ar = await p.contexte('adulte-ar', { telephone: true, langue: 'ar-SA' });
  await ar.ctx.addInitScript((s) => {
    if (sessionStorage.getItem('e2e-pose')) return;
    for (const [k, v] of JSON.parse(s)) {
      if (!/langue|locale|lang/i.test(k)) localStorage.setItem(k, v);
    }
    sessionStorage.setItem('e2e-pose', '1');
  }, stockage);
  await ouvrir(ar.page, '/');
  await ar.page.waitForTimeout(5000); await activerSemantique(ar.page);
  await preuves(ar, 'ar');

  code = await p.fin(ecarts.length ? 'rouge' : 'vert', ecarts.join(' ; '));
} catch (e) {
  p.dire(`ERREUR : ${e.stack ?? e}`);
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
