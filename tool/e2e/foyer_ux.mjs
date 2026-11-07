// Lot FOYER-UX (06/11/2026), preuve en local : l'eleve adulte inscrit « pour
// moi » ouvre son Foyer (UX-023 : « Vous suivez les cours », plus de « Créer
// mon profil élève ») et son Compte (la version en bas, decision du
// 03/11/2026). Captures 390 et 1440, francais et arabe.
//
// UX-009 n'a pas de capture : il faut une seance en cours dont la fenetre
// n'est pas rendue alors que l'horloge de la classe l'est ; la pile locale
// ne sait pas produire cet etat sur commande. Il est prouve par les tests
// (test/features/accueil_famille/ux009_un_seul_message_test.dart).
import { dernierLien, taper, parcours, connecter, connecterParLien, cliquer, trouver, trouverTexte, libelles,
  allerOnglet, activerSemantique, ouvrir, COMPTES } from './commun.mjs';
import { accepterDemande } from './inscription.mjs';

async function inscrireIci(p, a, { courriel, prenom, nom, genre }, prefixe = 'i') {
  const depuis = Date.now();
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await cliquer(a.page, /^Recevoir le lien( d'inscription)?$/, { pause: 2500 });
  const recu = await dernierLien(courriel, depuis);
  if (!recu?.lien) throw new Error(`aucun lien recu pour ${courriel}`);
  await a.page.goto(recu.lien);
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  const vus = [];
  for (let k = 0; k < 8; k++) {
    const l = await libelles(a.page);
    vus.push(l.filter((x) => x.startsWith('flt-semantics:') || x.startsWith('h2:')).join(' / '));
    for (const c of await a.page.locator('input').all()) {
      const n = `${await c.getAttribute('aria-label') ?? ''}`;
      let v = null;
      if (/prénom/i.test(n)) v = prenom; else if (/nom/i.test(n)) v = nom;
      if (v === null) continue;
      await c.click({ force: true }); await a.page.keyboard.press('Control+A');
      await a.page.keyboard.type(v, { delay: 10 }); await a.page.waitForTimeout(200);
    }
    if (l.some((x) => x.startsWith('radio:'))) {
      const g = await trouver(a.page, genre, { delai: 2000, role: 'radio' });
      if (g) { await g.click(); await a.page.waitForTimeout(400); }
    }
    await p.capture(a, `${prefixe}_identite_${k}`);
    const envoyer = await trouver(a.page, /^Envoyer ma demande$/, { delai: 1500 });
    if (envoyer) { await envoyer.click(); await a.page.waitForTimeout(4000); break; }
    await cliquer(a.page, /^Continuer$/, { pause: 1500 });
  }
  await activerSemantique(a.page);
  for (let k = 0; k < 6; k++) {
    if (await trouverTexte(a.page, /Votre demande est en cours/i, 1500)) break;
    const lire = await trouver(a.page, /^Lire et accepter nos conditions$/, { delai: 1500 });
    if (lire) { await lire.click(); await a.page.waitForTimeout(1500); }
    const cases = a.page.getByRole('checkbox');
    for (let i = 0; i < await cases.count(); i++) {
      if ((await cases.nth(i).getAttribute('aria-checked')) !== 'true') { await cases.nth(i).click(); await a.page.waitForTimeout(300); }
    }
    const suite = await trouver(a.page, /^(Suivant|Continuer)$/, { delai: 2000, role: 'button' });
    if (suite) { await suite.click(); await a.page.waitForTimeout(2500); await activerSemantique(a.page); }
  }
  await p.capture(a, `${prefixe}_demande`);
  return vus;
}


const t = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
const p = await parcours('FOYER-UX', 'foyer-ux');
const ecarts = [];
let code = 1;

async function basDePage(page) {
  const v = page.viewportSize();
  await page.mouse.move(v.width / 2, v.height / 2);
  for (let k = 0; k < 8; k++) { await page.mouse.wheel(0, 4000); await page.waitForTimeout(300); }
  await page.waitForTimeout(800);
}

async function preuves(a, langue) {
  for (const [w, h] of [[390, 844], [1440, 900]]) {
    await a.page.setViewportSize({ width: w, height: h });
    await a.page.evaluate(() => { location.hash = '#/tuteur/foyer'; });
    await a.page.waitForTimeout(3500); await activerSemantique(a.page);
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
    const aucun = (await libelles(a.page)).some((x) => /Aucun profil élève pour le moment|لا ملف طالب حتى الآن/.test(x));
    p.dire(`  ${langue} ${w} Compte, Mon foyer : ${aucun ? 'dit ENCORE « Aucun profil élève »' : 'ne dit plus « Aucun profil élève »'}`);
    if (aucun) ecarts.push(`${langue} ${w} : le Compte dit « Aucun profil élève »`);
  }
}

try {
  const d = await p.contexte('direction');
  await connecter(d.page, COMPTES.direction);
  const A = { courriel: `e2e-foyer-ux-${t}@example.com`, prenom: 'E2E Amina', nom: `FoyerUx${t}` };
  const a = await p.contexte('adulte', { telephone: true });
  await ouvrir(a.page, '/');
  if (await trouver(a.page, /^Créer un compte$/, { delai: 3000 })) await cliquer(a.page, /^Créer un compte$/);
  await cliquer(a.page, /^Je m'inscris pour moi/);
  await cliquer(a.page, /^Continuer$/);
  // Questionnaire « pour moi », tolerant a l'ordre des etapes.
  const choix = [/^Une femme$/, /^Français$/, /^Nous commençons par les lettres$/, /^Apprendre à lire$/, /^Le soir$/];
  for (let k = 0; k < 12; k++) {
    if (await a.page.locator('input[autocomplete=email], input[inputmode=email]').count()) break;
    await p.capture(a, `questionnaire_${k}`);
    const champ = a.page.locator('input');
    if (await champ.count() && !(await champ.first().inputValue())) await taper(a.page, 'input', A.prenom);
    for (const c of choix) {
      const e = await trouver(a.page, c, { delai: 400 });
      if (e) { await e.click(); await a.page.waitForTimeout(400); break; }
    }
    await cliquer(a.page, /^Continuer$/, { pause: 1300 });
  }
  await inscrireIci(p, a, { courriel: A.courriel, prenom: A.prenom, nom: A.nom, genre: /^Une femme/ }, 'inscription');
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
