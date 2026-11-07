// MINEUR-FANTOME (07/11/2026), preuve en local : une famille ajoute un
// enfant. La grille d'age s'arrete a 17 ans et dit ou va un adulte ; le genre
// manquant est signale ; un enfant de 17 ans est cree, son genre enregistre.
// Captures 390 et 1440, FR et AR. Base LOCALE seulement.
// Usage : node tool/e2e/mineur_fantome.mjs nouveau|<courriel>
import { parcours, connecter, connecterParLien, trouver, trouverTexte, cliquer, taper, dernierLien,
  libelles, activerSemantique, ouvrir, sql, COMPTES } from './commun.mjs';
import { accepterDemande } from './inscription.mjs';

let courriel = process.argv[2] ?? 'nouveau';
const p = await parcours('MINEUR-FANTOME', 'mineur-fantome');
const ecarts = [];
let code = 1;
const PRENOM = 'Yanis';

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

async function identite(a, langue, w) {
  await a.page.setViewportSize({ width: w, height: w === 390 ? 844 : 900 });
  await a.page.evaluate(() => { location.hash = '#/tuteur/foyer/ajouter'; });
  await a.page.waitForTimeout(3500); await activerSemantique(a.page);
  const enfant = await trouver(a.page, langue === 'fr' ? /^Un enfant|J'ajoute un enfant|^Mon enfant/ : /طفل/, { delai: 4000 });
  if (enfant) { await enfant.click(); await a.page.waitForTimeout(600); }
  const suivant = await trouver(a.page, langue === 'fr' ? /^Suivant$/ : /^التالي$/, { delai: 4000, role: 'button' });
  if (suivant) { await suivant.click(); await a.page.waitForTimeout(1500); await activerSemantique(a.page); }
  const l = (await libelles(a.page)).join(' | ');
  const phrase = langue === 'fr' ? /À partir de 18.ans, l'élève crée son propre compte adulte/ : /ابتداءً من 18 سنة/;
  const p18 = /(^|\|)\s*(button|flt-semantics|checkbox)?:?18\s*(\||$)/.test(l);
  p.dire(`  ${langue} ${w} identite : phrase 18 ans ${phrase.test(l) ? 'presente' : 'ABSENTE'} ; puce 18 ${p18 ? 'PRESENTE' : 'absente'}`);
  if (!phrase.test(l)) ecarts.push(`${langue} ${w} : phrase des 18 ans absente`);
  if (p18) ecarts.push(`${langue} ${w} : puce 18 presente`);
  for (let k = 0; k < 6; k++) { await a.page.mouse.move(w / 2, 400); await a.page.mouse.wheel(0, 300); await a.page.waitForTimeout(150); }
  await p.capture(a, `${langue}_${w}_identite_grille`);
}

try {
  const a = await p.contexte('tuteur', { telephone: true });
  if (courriel === 'nouveau') {
    const t = new Date().toISOString().slice(5, 16).replace(/[-T:]/g, '');
    const F = { courriel: `e2e-foyer-ux-fam-${t}@example.com`, prenom: 'E2E Karim', nom: `Fam${t}` };
    courriel = F.courriel;
    const d = await p.contexte('direction');
    await connecter(d.page, COMPTES.direction);
    await ouvrir(a.page, '/');
    if (await trouver(a.page, /^Créer un compte$/, { delai: 3000 })) await cliquer(a.page, /^Créer un compte$/);
    await cliquer(a.page, /^J'inscris mon enfant/);
    await cliquer(a.page, /^Continuer$/);
    const choix = [/^9 ans$/, /^Un garçon$/, /^Nous commençons par les lettres$/, /^Non$/, /^Français$/, /^Apprendre à lire$/, /^Le soir$/];
    for (let k = 0; k < 14; k++) {
      if (await a.page.locator('input[autocomplete=email], input[inputmode=email]').count()) break;
      await p.capture(a, `questionnaire_${k}`);
      const champ = a.page.locator('input');
      if (await champ.count() && !(await champ.first().inputValue())) await taper(a.page, 'input', PRENOM);
      for (const c of choix) {
        const e = await trouver(a.page, c, { delai: 400 });
        if (e) { await e.click(); await a.page.waitForTimeout(400); break; }
      }
      await cliquer(a.page, /^Continuer$/, { pause: 1300 });
    }
    await inscrireIci(p, a, { courriel: F.courriel, prenom: F.prenom, nom: F.nom, genre: /^Un homme/ }, 'inscription');
    await accepterDemande(p, d, { liste: 'Familles', nomComplet: `${F.prenom} ${F.nom}` });
  }
  await connecterParLien(a.page, courriel);
  await a.page.waitForTimeout(3000);

  // 1. L'ecran d'identite, FR, 390 et 1440 : la grille et la phrase.
  await identite(a, 'fr', 390);
  await identite(a, 'fr', 1440);

  // 2. Genre manquant, puis enfant de 17 ans cree (390, FR).
  await a.page.setViewportSize({ width: 390, height: 844 });
  await identite(a, 'fr', 390);
  for (const c of await a.page.locator('input').all()) {
    const n = `${await c.getAttribute('aria-label') ?? ''}`;
    let v = null;
    if (/prénom/i.test(n)) v = 'Nour'; else if (/nom/i.test(n)) v = 'Fantome';
    if (v === null) continue;
    await c.click({ force: true }); await a.page.keyboard.press('Control+A');
    await a.page.keyboard.type(v, { delay: 10 }); await a.page.waitForTimeout(200);
  }
  const p17 = await trouver(a.page, /^17$/, { delai: 3000 });
  if (!p17) throw new Error('puce 17 introuvable');
  await p17.click(); await a.page.waitForTimeout(400);
  await cliquer(a.page, /^Créer le profil/, { pause: 1500 });
  await activerSemantique(a.page);
  const manque = await trouverTexte(a.page, /Le genre manque/, 3000);
  p.dire(`  genre manquant : ${manque ? 'signale' : 'NON SIGNALE'}`);
  if (!manque) ecarts.push('genre manquant non signale');
  // Le message est sous les puces du genre : il doit etre a l'ecran.
  for (let k = 0; k < 6; k++) { await a.page.mouse.move(195, 400); await a.page.mouse.wheel(0, 400); await a.page.waitForTimeout(150); }
  await a.page.waitForTimeout(500);
  await p.capture(a, 'fr_390_genre_manquant');
  await cliquer(a.page, /^Une fille$/, { pause: 500 });
  await cliquer(a.page, /^Créer le profil/, { pause: 4000 });
  await activerSemantique(a.page);
  await p.capture(a, 'fr_390_apres_creation');
  const cree = sql(`select p.gender || '/' || sp.student_type from public.profiles p join public.student_profiles sp on sp.profile_id = p.id
    join auth.users t on t.id = (select h.id from public.profiles h join auth.users u on u.id = h.id where u.email = '${courriel}')
    where p.household_id = (select household_id from public.profiles where id = t.id) and p.first_name = 'Nour'`);
  p.dire(`  enfant de 17 ans : ${cree || 'NON CREE'} (attendu female/minor)`);
  if (cree !== 'female/minor') ecarts.push(`enfant de 17 ans : ${cree || 'non cree'}`);

  // 3. Arabe : la meme grille, 390 et 1440.
  const stockage = await a.page.evaluate(() => JSON.stringify(Object.entries(localStorage)));
  const ar = await p.contexte('tuteur-ar', { telephone: true, langue: 'ar-SA' });
  await ar.ctx.addInitScript((s) => {
    if (sessionStorage.getItem('e2e-pose')) return;
    for (const [k, v] of JSON.parse(s)) if (!/langue|locale|lang/i.test(k)) localStorage.setItem(k, v);
    sessionStorage.setItem('e2e-pose', '1');
  }, stockage);
  await ouvrir(ar.page, '/');
  await ar.page.waitForTimeout(5000); await activerSemantique(ar.page);
  await identite(ar, 'ar', 390);
  await identite(ar, 'ar', 1440);

  code = await p.fin(ecarts.length ? 'rouge' : 'vert', ecarts.join(' ; '));
} catch (e) {
  p.dire(`ERREUR : ${e.stack ?? e}`);
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
