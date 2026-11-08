// Defaut 1.8 (brouillon de l'inscription qui survit a un rechargement) : une
// personne adulte s'inscrit « pour elle », arrive sur l'identite, saisit son
// prenom, RECHARGE la page, et le prenom doit etre encore la.
// Joue au telephone (390) et au bureau (1440), dans la langue du navigateur
// (E2E_LANGUE=fr-FR par defaut). Pile locale seulement.
//
// Usage : node tool/e2e/brouillon_persistant.mjs
import { parcours, ouvrir, cliquer, trouver, libelles, taper, dernierLien,
  activerSemantique } from './commun.mjs';

const LANGUE = process.env.E2E_LANGUE ?? 'fr-FR';
const tampon = Date.now().toString(36);
const p = await parcours(`Brouillon d'inscription persistant (${LANGUE})`, `brouillon-persistant-${LANGUE.slice(0, 2)}`);

// Libelles de l'application par langue (assets/i18n/fr.i18n.json et ar.i18n.json).
const AR = LANGUE.startsWith('ar');
const E = AR
  ? { prenom: 'الاسم', nom: 'اللقب', continuer: /^متابعة$/, retour: /^رجوع$/, lien: /^استلام (الرابط|رابط التسجيل)$/,
      moi: /^أسجّل لنفسي/, choix: [/^امرأة/, /^Français$/, /^نبدأ بالحروف/, /^تعلّم القراءة/, /^المساء/] }
  : { prenom: 'Prénom', nom: 'Nom', continuer: /^Continuer$/, retour: /^Retour$/, lien: /^Recevoir le lien( d'inscription)?$/,
      moi: /^Je m'inscris pour moi/, choix: [/^Une femme$/, /^Français$/, /^Nous commençons par les lettres$/, /^Apprendre à lire$/, /^Le soir$/] };

/// Valeur d'un champ : le champ web ne reflete sa valeur qu'une fois focalise.
async function lire(page, etiquette) {
  const c = page.locator(`input[aria-label="${etiquette}"]`);
  try { await c.click({ force: true, timeout: 5000 }); await page.waitForTimeout(400); return await c.inputValue(); } catch { return ''; }
}

async function jusquauCourriel(a) {
  for (let k = 0; k < 14; k++) {
    if (/etape=acces/.test(a.page.url())) return;
    if (await a.page.locator('input:visible').count()) {
      const premier = a.page.locator('input:visible').first();
      await premier.click({ force: true });
      await a.page.keyboard.type('Amina', { delay: 10 });
    } else {
      let choisi = false;
      for (const motif of E.choix) {
        const c = await trouver(a.page, motif, { delai: 700 });
        if (c) { await c.click(); await a.page.waitForTimeout(500); choisi = true; break; }
      }
      if (!choisi) throw new Error(`questionnaire : aucun choix connu a l'ecran ; ${(await libelles(a.page)).slice(0, 8).join(' | ')}`);
    }
    await cliquer(a.page, E.continuer, { pause: 1300 });
  }
  throw new Error('questionnaire : trop d\'etapes');
}

/// Joue le geste complet dans un contexte ; rend { avant, apres }.
async function jouer(nom, options) {
  const a = await p.contexte(nom, { ...options, langue: LANGUE });
  const courriel = `e2e-brouillon-${nom}-${tampon}@example.com`;
  await ouvrir(a.page, '/');
  await cliquer(a.page, E.moi);
  await cliquer(a.page, E.continuer);
  await jusquauCourriel(a);
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  const depuis = Date.now();
  await cliquer(a.page, E.lien, { pause: 2500 });
  const recu = await dernierLien(courriel, depuis);
  if (!recu?.lien) throw new Error(`aucun lien recu pour ${courriel}`);
  await a.page.goto(recu.lien);
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  if (!/identite/.test(a.page.url())) throw new Error(`identite non atteinte : ${a.page.url()}`);

  // Cas B (geste du piege 1.8) : saisir puis recharger SANS « Continuer ».
  await taper(a.page, `input[aria-label="${E.prenom}"]`, 'Amina');
  await taper(a.page, `input[aria-label="${E.nom}"]`, 'Diallo');
  await p.capture(a, 'B_saisi_sans_continuer');
  // Le brouillon s'ecrit 400 ms apres la derniere frappe (identite_etape.dart).
  await a.page.waitForTimeout(900);
  await a.page.reload();
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  const sansContinuer = await lire(a.page, E.prenom);
  const nomSansContinuer = await lire(a.page, E.nom);
  await p.capture(a, 'B_apres_rechargement');
  p.dire(`${nom} cas B (saisi, sans « Continuer », rechargement) : prenom « ${sansContinuer} », nom « ${nomSansContinuer} »`);

  // Cas A : saisir, « Continuer » (le brouillon s'ecrit), recharger, revenir.
  await taper(a.page, `input[aria-label="${E.prenom}"]`, 'Amina');
  await taper(a.page, `input[aria-label="${E.nom}"]`, 'Diallo');
  await cliquer(a.page, E.continuer, { pause: 1500 });
  await p.capture(a, 'A_avant_rechargement');
  await a.page.reload();
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  const urlApres = a.page.url();
  await p.capture(a, 'A_apres_rechargement');
  if (!/identite/.test(urlApres)) {
    await cliquer(a.page, E.retour, { pause: 1500 });
    await activerSemantique(a.page);
  }
  const apres = await lire(a.page, E.prenom);
  const nomApres = await lire(a.page, E.nom);
  await p.capture(a, 'A_prenom_retrouve');
  const avant = 'Amina';
  p.dire(`${nom} cas A (saisi, « Continuer », rechargement, retour) : prenom « ${apres} », nom « ${nomApres} » ; rechargee sur ${urlApres}`);
  await a.ctx.close();
  return { avant, apres, nomApres, sansContinuer, nomSansContinuer };
}

let code = 1;
try {
  const tel = await jouer('telephone-390', { telephone: true });
  const bur = await jouer('bureau-1440', { vue: { width: 1440, height: 900 } });
  for (const [nom, r] of [['390', tel], ['1440', bur]]) {
    if (r.sansContinuer !== 'Amina' || r.nomSansContinuer !== 'Diallo') {
      throw new Error(`${nom} cas B (geste du piege 1.8) : prenom « ${r.sansContinuer} » et nom « ${r.nomSansContinuer} » apres rechargement sans « Continuer » (attendu « Amina » et « Diallo »)`);
    }
    if (r.apres !== 'Amina' || r.nomApres !== 'Diallo') {
      throw new Error(`${nom} cas A : prenom « ${r.apres} » et nom « ${r.nomApres} » apres rechargement et retour (attendu « Amina » et « Diallo »)`);
    }
  }
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
