// QUESTIONNAIRE-FIN (directeur, 04/11/2026) : captures avant et apres du
// questionnaire d'inscription, sur la pile LOCALE, a 360 et 1280 px, en clair
// et en sombre. Sans compte : le visiteur repond au questionnaire.
//
// Ce que chaque passage montre (parcours « J'inscris mon enfant ») :
//   1. la carte choisie de « Pour qui » : titre, description et repere ;
//   2. le champ du prenom, vide : son indication ;
//   3. la fin du questionnaire : AVANT, la page de connexion ; APRES, le
//      dernier ecran du questionnaire (meme habillage, barre au bout) ;
//   4. APRES seulement : « Lien envoye », dans le meme habillage.
// Usage : node tool/e2e/questionnaire_fin.mjs avant|apres
// (construire et servir d'abord la version voulue : `main` pour « avant », la
// branche pour « apres »).
import fs from 'node:fs';
import path from 'node:path';
import { parcours, trouver, cliquer, attendreTexte, ouvrir, activerSemantique,
  amenerEnVue } from './commun.mjs';

const mode = process.argv[2] === 'avant' ? 'avant' : 'apres';
const p = await parcours(`QUESTIONNAIRE-FIN (${mode})`, `questionnaire-fin/${mode}`);
const n = Date.now() % 1000000;

// LOGO-G (04/11/2026) : `alleger` (commun.mjs) ramene chaque capture a 96
// couleurs ; les quelques centaines de pixels du logo Google y prenaient le
// violet et les gris de la page (garde-cap mesurait un G gris et violet). La
// fin du questionnaire et « Lien envoye » sont donc aussi gardees en couleurs
// pleines, dans `brut/`, que `alleger` ne parcourt pas.
async function brute(c, etiquette) {
  const dossier = path.join(p.sortie, 'brut');
  fs.mkdirSync(dossier, { recursive: true });
  await c.page.screenshot({ path: path.join(dossier, `${etiquette}.png`) });
}

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

async function continuer(page) {
  await cliquer(page, /^Continuer/, { pause: 1500 });
  await activerSemantique(page);
}

async function choisir(page, motif, role) {
  const e = await trouver(page, motif, { delai: 10000, ...(role ? { role } : {}) });
  verifier(e !== null, `la reponse ${motif}`);
  await amenerEnVue(page, e); await e.click(); await page.waitForTimeout(700);
}

async function premiereCarte(page) {
  const e = await trouver(page, /./, { delai: 10000, role: 'radio' });
  verifier(e !== null, 'une carte de reponse');
  await amenerEnVue(page, e); await e.click(); await page.waitForTimeout(700);
}

async function passage(largeur, hauteur, sombre) {
  const tag = `${largeur}_${sombre ? 'sombre' : 'clair'}`;
  const c = await p.contexte('visiteur', { vue: { width: largeur, height: hauteur }, sombre });
  c.page.on('response', async (r) => {
    if (/auth\/v1\/otp/.test(r.url())) {
      p.dire(`  otp ${r.status()} ${(await r.text().catch(() => '')).slice(0, 200)}`);
    }
  });
  await ouvrir(c.page, '/#/commencer');
  await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /J'inscris mon enfant/, 30000), `${tag} : « Pour qui »`);

  // 1. La carte choisie.
  await choisir(c.page, /J'inscris mon enfant/);
  await p.capture(c, `${tag}_1_carte_choisie`);
  await continuer(c.page);

  // 2. Le prenom, champ vide.
  verifier(await attendreTexte(c.page, /prénom/i, 15000), `${tag} : le prenom`);
  await p.capture(c, `${tag}_2_prenom_vide`);
  const champ = c.page.locator('input').first();
  await champ.click(); await champ.fill('Yasmine'); await c.page.waitForTimeout(500);
  await continuer(c.page);

  // La suite, sans capture : age, genre, niveau, parent, langue, objectif,
  // moments.
  await choisir(c.page, /^8\s?ans$/); await continuer(c.page);
  await choisir(c.page, /^Une fille$/); await continuer(c.page);
  await premiereCarte(c.page); await continuer(c.page);
  await choisir(c.page, /^Non$/); await continuer(c.page);
  await choisir(c.page, /^Français$/); await continuer(c.page);
  await premiereCarte(c.page); await continuer(c.page);
  await choisir(c.page, /matin/i); await continuer(c.page);
  await c.page.waitForTimeout(2500); await activerSemantique(c.page);

  // 3. La fin du questionnaire.
  p.dire(`  ${tag} : fin a ${c.page.url()}`);
  if (mode === 'apres') {
    verifier(/etape=acces/.test(c.page.url()), `${tag} : la fin reste dans le questionnaire (?etape=acces)`);
    verifier(await attendreTexte(c.page, /Vos réponses sont gardées/, 15000), `${tag} : « Vos réponses sont gardées »`);
  } else {
    verifier(/connexion/.test(c.page.url()), `${tag} : la fin mene a la connexion (avant)`);
  }
  await p.capture(c, `${tag}_3_fin_du_questionnaire`);
  await brute(c, `${tag}_3_fin_du_questionnaire`);

  // 4. Apres : le lien envoye, dans le meme habillage.
  if (mode === 'apres') {
    // Le champ de Flutter web se recree au premier rendu : on tape, puis on
    // relit la valeur, et on recommence si elle s'est perdue.
    const adresse = `e2e-qfin-${tag}-${n}@example.com`;
    for (let essai = 0; essai < 3; essai++) {
      await c.page.waitForTimeout(800);
      const courriel = c.page.locator('input').first();
      await courriel.click(); await courriel.fill(adresse);
      await c.page.waitForTimeout(400);
      if (await courriel.inputValue().catch(() => '') === adresse) break;
    }
    await cliquer(c.page, /^Recevoir le lien$/, { pause: 3000 });
    await activerSemantique(c.page);
    if (!await attendreTexte(c.page, /Lien envoyé/, 20000)) {
      await p.capture(c, `${tag}_4_ROUGE_envoi`);
    }
    verifier(await attendreTexte(c.page, /Lien envoyé/, 1000), `${tag} : « Lien envoyé »`);
    await p.capture(c, `${tag}_4_lien_envoye`);
    await brute(c, `${tag}_4_lien_envoye`);
  }
  await c.ctx.close();
}

let code = 1;
try {
  for (const [l, h] of [[360, 780], [1280, 800]]) {
    for (const sombre of [false, true]) {
      await passage(l, h, sombre);
    }
  }
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
