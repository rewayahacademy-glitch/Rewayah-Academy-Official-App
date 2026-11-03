// ONBOARDING-FIN (pilote, 02/11/2026) : UX-046 et UX-047, sur la pile LOCALE,
// a 1440 x 900 et 390 x 844, en francais puis en arabe.
//
// Ce que le parcours prouve :
//   * UX-046, le questionnaire dans l'habillage de la connexion : sur
//     ordinateur, deux volets (la question sur la marque, les reponses sur le
//     parchemin) ; la touche B choisit « J'inscris mon enfant » ; des puces
//     pour l'age, le genre, la langue, les moments ; des cartes legeres pour
//     le niveau et l'objectif ; « Continuer » plein.
//   * UX-047, la page des accords : « Suivant » reste actif ; touche sans
//     rien cocher, il n'envoie rien, la page descend a la premiere case, la
//     carte passe en rouge et « Cochez cette case pour continuer » s'affiche
//     sous elle ; le focus y est ; cochee, la phrase passe a la suivante.
//
// Donnees de test, sur la pile LOCALE seulement : une famille fictive par
// largeur (adresse e2e-onb-...@example.com). Un mot de passe de test lui est
// pose en base pour la rouvrir en arabe. Rien n'est efface. Aucune migration.
// Usage : node tool/e2e/onboarding_fin.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, cliquer, trouver, libelles, taper,
  activerSemantique, sql, MAILPIT, MDP, DEPOT } from './commun.mjs';

const lire = (langue) => {
  const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, `assets/i18n/${langue}.i18n.json`), 'utf8'));
  return (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
};
const FR = lire('fr');
const AR = lire('ar');
const p = await parcours('ONBOARDING-FIN : questionnaire habille comme la connexion, accords signales', 'onboarding-fin');
let code = 1;
const net = (s) => s.replace(/[⁨⁩]/g, '');
const lus = async (page, n = 80) => net((await libelles(page)).slice(0, n).join(' | '));

async function lienRecu(courriel, delai = 60000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${courriel}`)}`)).json();
    if (r.messages?.length) {
      const m = await (await fetch(`${MAILPIT}/api/v1/message/${r.messages[0].ID}`)).json();
      const corps = `${m.HTML ?? ''} ${m.Text ?? ''}`;
      const liens = [...corps.matchAll(/https?:\/\/[^\s"'<>]+/g)].map((x) => x[0].replace(/&amp;/g, '&'));
      return liens.find((u) => u.includes('/auth/v1/verify')) ?? liens.find((u) => /token|code=/.test(u));
    }
    await new Promise((res) => setTimeout(res, 1500));
  }
  return null;
}

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

/// Le compte, le recapitulatif, l'envoi, puis « Lire et accepter nos
/// conditions ».
async function jusquAuxAccords(c, famille) {
  await taper(c.page, 'input[autocomplete=email], input[inputmode=email]', famille.courriel);
  await cliquer(c.page, /^Recevoir le lien d'inscription$/, { pause: 2500 });
  const lien = await lienRecu(famille.courriel);
  if (!lien) throw new Error(`aucun lien recu pour ${famille.courriel}`);
  await c.page.goto(lien); await c.page.waitForTimeout(6000); await activerSemantique(c.page);
  let envoyer = null;
  for (let k = 0; k < 8 && !envoyer; k++) {
    const l = await libelles(c.page);
    for (const champ of await c.page.locator('input').all()) {
      const nom = `${await champ.getAttribute('aria-label') ?? ''}`;
      let val = null; if (/prénom/i.test(nom)) val = famille.prenom; else if (/nom/i.test(nom)) val = famille.nom;
      if (val === null) continue;
      await champ.click({ force: true }); await c.page.keyboard.press('Control+A'); await c.page.keyboard.type(val, { delay: 10 });
    }
    if (l.some((x) => x.startsWith('radio:'))) {
      const g = await trouver(c.page, /^Un homme/, { delai: 2000, role: 'radio' });
      if (g) { await g.click(); await c.page.waitForTimeout(400); }
    }
    envoyer = await trouver(c.page, /^Envoyer ma demande$/, { delai: 1500 });
    if (!envoyer) await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  }
  if (!envoyer) throw new Error('recapitulatif : « Envoyer ma demande » introuvable');
  await envoyer.click(); await c.page.waitForTimeout(5000); await activerSemantique(c.page);
  await cliquer(c.page, /^Lire et accepter nos conditions$/, { pause: 2000 });
}

/// UX-047 : « Suivant » sans rien cocher, puis apres la premiere case.
async function accords(c, cle, T) {
  const v = {};
  await activerSemantique(c.page);
  const phrase = net(T('accords.caseManquante'));
  const suivant = new RegExp(`^${T('accords.suivant')}`);
  v.pasDePhraseGenerale = !(await lus(c.page, 200)).includes(net(T('accords.reste.other')).split('{')[0].trim());
  const cases = c.page.getByRole('checkbox');
  const nCases = await cases.count();
  await cliquer(c.page, suivant, { pause: 1500 }); await activerSemantique(c.page);
  v.suivantSignale = (await lus(c.page, 300)).includes(phrase);
  // Le focus est sur la premiere case.
  v.focusSurLaCase = await c.page.evaluate(() => {
    const a = document.activeElement;
    return Boolean(a && (a.getAttribute('role') === 'checkbox' || a.closest?.('[role=checkbox]')));
  });
  // La phrase est visible a l'ecran (la page est descendue jusqu'a elle).
  const enVue = await c.page.evaluate((txt) => {
    const n = [...document.querySelectorAll('flt-semantics, [role]')].find((e) => (e.textContent || '').trim() === txt
      || (e.getAttribute('aria-label') || '').trim() === txt);
    if (!n) return null;
    const r = n.getBoundingClientRect();
    return r.top >= 0 && r.bottom <= window.innerHeight;
  }, phrase);
  v.phraseEnVue = enVue !== false;
  await p.capture(c, `${cle}_6_accords_case_rouge`);
  if (nCases > 1) {
    await cases.first().click(); await c.page.waitForTimeout(800);
    await cliquer(c.page, suivant, { pause: 1500 }); await activerSemantique(c.page);
    v.secondeCaseSignalee = (await lus(c.page, 300)).includes(phrase);
    await p.capture(c, `${cle}_7_accords_seconde_case`);
  }
  return v;
}

try {
  const verdicts = {};
  const tampon = `${Date.now() % 1000000}`;
  const familles = {};
  for (const [largeur, hauteur] of [[1440, 900], [390, 844]]) {
    const cle = `${largeur}`;
    const c = await p.contexte('famille', { vue: { width: largeur, height: hauteur } });
    const famille = { courriel: `e2e-onb-${largeur}-${tampon}@example.com`, enfant: `Sami${largeur}${tampon}`,
      prenom: 'E2E Parent', nom: `Onb${largeur}${tampon}` };
    familles[cle] = famille;
    const v = await questionnaire(c, cle, famille, largeur >= 840);
    await jusquAuxAccords(c, famille);
    Object.assign(v, await accords(c, cle, FR));
    verdicts[cle] = v;
    p.dire(`${cle} : ${JSON.stringify(v)}`);
    await c.ctx.close();
  }

  // L'arabe : le premier ecran, puis la famille rouverte sur ses accords.
  for (const [largeur, hauteur] of [[1440, 900], [390, 844]]) {
    const cle = `${largeur}_ar`;
    const v = {};
    const c = await p.contexte('famille', { vue: { width: largeur, height: hauteur }, langue: 'ar-SA' });
    await ouvrir(c.page, '/#/commencer');
    await c.page.waitForTimeout(2500); await activerSemantique(c.page);
    v.questionArabe = (await lus(c.page)).includes(net(AR('inscription.usage.question')));
    await p.capture(c, `${cle}_1_pour_qui`);
    const famille = familles[`${largeur}`];
    sql(`update auth.users set encrypted_password = crypt('${MDP}', gen_salt('bf')) where email = '${famille.courriel}'`);
    await ouvrir(c.page, '/#/connexion');
    await c.page.waitForTimeout(2000); await activerSemantique(c.page);
    if (!(await c.page.locator('input[type=password]').count())) {
      const deja = await trouver(c.page, new RegExp(`^${AR('connexion.modeConnexion')}`), { delai: 8000 });
      if (deja) { await deja.click(); await c.page.waitForTimeout(1200); }
    }
    await taper(c.page, 'input[autocomplete=email], input[inputmode=email]', famille.courriel);
    await taper(c.page, 'input[type=password]', MDP);
    await c.page.keyboard.press('Enter');
    await c.page.waitForTimeout(6000); await activerSemantique(c.page);
    const lireAr = await trouver(c.page, new RegExp(`^${AR('attente.lireEtAccepter')}`), { delai: 8000 });
    if (!lireAr) throw new Error(`${cle} : « ${AR('attente.lireEtAccepter')} » introuvable`);
    await lireAr.click(); await c.page.waitForTimeout(2000);
    Object.assign(v, await accords(c, cle, AR));
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
