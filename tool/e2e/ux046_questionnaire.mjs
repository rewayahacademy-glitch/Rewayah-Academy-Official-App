// UX-046 (ONBOARDING-FIN, pilote, 02/11/2026) : le questionnaire
// d'inscription dans l'habillage de la connexion, sur la pile LOCALE, a
// 1440 x 900 et 390 x 844, en francais, puis son premier ecran en arabe.
//
// Ce que le parcours prouve : sur ordinateur, deux volets (la question sur la
// marque, les reponses sur le parchemin) et la phrase des lettres ; la touche
// B choisit « J'inscris mon enfant » ; des puces (boutons) pour l'age, le
// genre et les moments ; des cartes legeres pour le niveau ; « Continuer »
// plein ; le questionnaire mene a la creation du compte.
//
// Rien n'est ecrit en base : le parcours s'arrete a la creation du compte.
// Usage : node tool/e2e/ux046_questionnaire.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, cliquer, trouver, libelles, taper,
  activerSemantique, DEPOT } from './commun.mjs';

const lire = (langue) => {
  const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${langue}.i18n.json`), 'utf8'));
  return (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
};
const FR = lire('fr');
const AR = lire('ar');
const p = await parcours('UX-046 : questionnaire habille comme la connexion', 'ux046-questionnaire');
let code = 1;
const net = (s) => s.replace(/[⁨⁩]/g, '');
const lus = async (page, n = 80) => net((await libelles(page)).slice(0, n).join(' | '));

/// La couleur de fond au point (x, y) de la page, en [r, g, b].
async function pixel(page, x, y) {
  const png = await page.screenshot({ clip: { x, y, width: 1, height: 1 } });
  // Une image 1 x 1 : lue par le navigateur, sans dependance.
  return page.evaluate(async (b64) => {
    const img = new Image(); img.src = `data:image/png;base64,${b64}`;
    await img.decode();
    const c = document.createElement('canvas'); c.width = 1; c.height = 1;
    const g = c.getContext('2d'); g.drawImage(img, 0, 0);
    return [...g.getImageData(0, 0, 1, 1).data.slice(0, 3)];
  }, png.toString('base64'));
}

/// UX-046 : le questionnaire, de « Pour qui » a « Moments ».
async function questionnaire(c, cle, famille, bureau) {
  const v = {};
  await ouvrir(c.page, '/#/commencer');
  await c.page.waitForTimeout(2000); await activerSemantique(c.page);
  if (bureau) {
    // Deux volets : la marque au debut de ligne, le parchemin a cote.
    const [r, g, b] = await pixel(c.page, 40, 450);
    const [r2, g2, b2] = await pixel(c.page, 1400, 850);
    v.voletMarque = b > 200 && r < 140;
    v.voletParchemin = r2 > 220 && g2 > 210 && b2 > 190;
    v.lettresAffichees = (await lus(c.page)).includes(net(FR('inscription.questionnaire.clavierLettres')));
    await c.page.keyboard.press('b'); await c.page.waitForTimeout(800); await activerSemantique(c.page);
    v.toucheBChoisitEnfant = (await c.page.getByRole('radio').nth(1).getAttribute('aria-checked')) === 'true';
  } else {
    await c.page.getByRole('radio').nth(1).click(); await c.page.waitForTimeout(800);
  }
  await c.page.mouse.move(2, 2); await c.page.waitForTimeout(300);
  await p.capture(c, `${cle}_1_pour_qui`);
  await cliquer(c.page, /^Continuer$/, { pause: 1300 });
  const rep = [
    { q: /Comment s'appelle votre enfant/, saisie: famille.enfant },
    { q: /Quel âge a/, choix: /^9 ans$/, capture: '2_age_puces' }, { q: / est…/, choix: /^Un garçon$/, capture: '3_genre_puces' },
    { q: /Où en est .* aujourd'hui/, choix: /^Nous commençons par les lettres$/, capture: '4_niveau_cartes' },
    { q: /Suivez-vous aussi des cours/, choix: /^Non$/ }, { q: /Dans quelle langue/, choix: /^Français$/ },
    { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
    { q: /Quels moments/, choix: /^Le soir$/, capture: '5_moments_puces' },
  ];
  v.puces = true;
  for (let k = 0; k < 14 && !c.page.url().includes('/connexion'); k++) {
    await activerSemantique(c.page);
    const l = await libelles(c.page);
    const question = l.filter((x) => /^(flt-semantics|h1|h2|heading):/.test(x)).slice(0, 3).join(' / ');
    // La creation du compte : fin du questionnaire, meme si l'adresse n'a
    // pas encore change a la lecture.
    if (/Créer votre compte/.test(question)) break;
    const r = rep.find((x) => x.q.test(question));
    if (!r) throw new Error(`questionnaire : question imprevue « ${question} »`);
    if (r.saisie) await taper(c.page, 'input', r.saisie);
    if (r.choix) {
      await cliquer(c.page, r.choix, { pause: 600 });
      // Une puce est un bouton (role button) ; une carte, un radio.
      if (/puces/.test(r.capture ?? '')) {
        v.puces = v.puces && Boolean(await trouver(c.page, r.choix, { delai: 1500, role: 'button' }));
      }
    }
    if (r.capture) { await c.page.mouse.move(2, 2); await c.page.waitForTimeout(300); await p.capture(c, `${cle}_${r.capture}`); }
    await cliquer(c.page, /^Continuer$/, { pause: 1300 });
  }
  return v;
}

try {
  const verdicts = {};
  const tampon = `${Date.now() % 1000000}`;
  for (const [largeur, hauteur] of [[1440, 900], [390, 844]]) {
    const cle = `${largeur}`;
    const c = await p.contexte('famille', { vue: { width: largeur, height: hauteur } });
    const famille = { enfant: `Sami${largeur}${tampon}` };
    const v = await questionnaire(c, cle, famille, largeur >= 840);
    v.arriveALaCreationDuCompte = c.page.url().includes('/connexion')
      || (await lus(c.page)).includes('Créer votre compte');
    verdicts[cle] = v;
    p.dire(`${cle} : ${JSON.stringify(v)}`);
    await c.ctx.close();
  }
  for (const [largeur, hauteur] of [[1440, 900], [390, 844]]) {
    const cle = `${largeur}_ar`;
    const c = await p.contexte('famille', { vue: { width: largeur, height: hauteur }, langue: 'ar-SA' });
    await ouvrir(c.page, '/#/commencer');
    await c.page.waitForTimeout(2500); await activerSemantique(c.page);
    const l = await lus(c.page);
    const v = {
      questionArabe: l.includes(net(AR('inscription.usage.question'))),
      lettresArabe: largeur < 840 || l.includes(net(AR('inscription.questionnaire.clavierLettres'))),
    };
    await p.capture(c, `${cle}_1_pour_qui`);
    verdicts[cle] = v;
    p.dire(`${cle} : ${JSON.stringify(v)}`);
    await c.ctx.close();
  }
  const ok = Object.values(verdicts).every((v) => Object.values(v).every(Boolean));
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
