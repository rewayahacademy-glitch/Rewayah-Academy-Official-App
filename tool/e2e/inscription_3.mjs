// INSCRIPTION-3 (pilote, 02/11/2026) : deux defauts du parcours 3 vus par le
// directeur en production le 01/11, rejoues sur la pile LOCALE, a 1440 x 900
// et 390 x 844, en francais puis en arabe.
//
// Ce que le parcours prouve :
//   * « Pour qui » (UX-042) : un toucher sur « J'inscris mon enfant » choisit
//     la carte (case cochee, annoncee) et reste sur la question ; un second
//     toucher ne saute rien ; seul « Continuer » passe au prenom. Avant, la
//     page passait au prenom dans les 150 ms, sans etat choisi.
//   * L'arrivee apres « Envoyer ma demande » (UX-043) : l'ecran ne passe plus
//     par « Reessayer » (rien n'a echoue) ni par « Votre dossier » ; les
//     lignes du recapitulatif restent jusqu'au depart ; puis « Votre compte ».
//     « Nos conditions » reste immobile (deux images a 600 ms d'ecart,
//     identiques au pixel). Arrive sur `/attente`, les reponses du
//     questionnaire ont quitte l'appareil.
//   * L'arabe : la carte choisie, « Votre compte » et « Nos conditions ».
//
// Donnees de test, sur la pile LOCALE seulement : une famille fictive par
// largeur (adresse e2e-i3-…@example.com). Un mot de passe de test lui est
// pose en base pour la rouvrir en arabe. Rien n'est efface. Aucune migration.
// Usage : node tool/e2e/inscription_3.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, ouvrir, cliquer, trouver, libelles, taper,
  activerSemantique, sql, MAILPIT, MDP, DEPOT } from './commun.mjs';

const AR = (() => {
  const brut = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/ar.i18n.json'), 'utf8'));
  return (cle) => cle.split('.').reduce((o, k) => o?.[k], brut);
})();
const p = await parcours('INSCRIPTION-3 : la carte choisie et l\'arrivee sur les conditions', 'inscription-3');
let code = 1;
const lus = async (page, n = 80) => (await libelles(page)).slice(0, n).join(' | ');
const net = (s) => s.replace(/[⁨⁩]/g, '');

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

/// Les cartes de « Pour qui » (role radio) : [moi, famille].
const cartes = (page) => page.getByRole('radio');

/// UX-042 : la carte choisie reste ; seul « Continuer » avance.
async function carteChoisie(c, cle, { continuer = true } = {}) {
  const v = {};
  await ouvrir(c.page, '/#/commencer');
  await c.page.waitForTimeout(1500); await activerSemantique(c.page);
  v.adresseFixee = c.page.url().includes('etape=pourQui');
  const famille = cartes(c.page).nth(1);
  await famille.click(); await c.page.waitForTimeout(1200);
  await activerSemantique(c.page);
  v.resteSurLaQuestion = c.page.url().includes('etape=pourQui')
    && (await c.page.locator('input').count()) === 0;
  v.choisieAnnoncee = (await cartes(c.page).nth(1).getAttribute('aria-checked')) === 'true';
  await c.page.mouse.move(2, 2); await c.page.waitForTimeout(300);
  await p.capture(c, `${cle}_carte_choisie`);
  await cartes(c.page).nth(1).click(); await c.page.waitForTimeout(1000);
  v.doubleToucherSansSaut = c.page.url().includes('etape=pourQui');
  p.dire(`${cle}, adresse a l'ouverture puis apres le choix : ${c.page.url()}`);
  if (continuer) {
    await cliquer(c.page, /^Continuer$/, { pause: 1500 });
    v.continuerAvance = c.page.url().includes('etape=prenom-0');
    await p.capture(c, `${cle}_apres_continuer`);
    // Retour arriere depuis « Prenom » : la reponse « Pour qui » reste
    // choisie (pilote, 02/11).
    await cliquer(c.page, /^Retour$/, { pause: 1500 });
    await activerSemantique(c.page);
    v.retourGardeLeChoix = c.page.url().includes('etape=pourQui')
      && (await cartes(c.page).nth(1).getAttribute('aria-checked')) === 'true';
    await c.page.mouse.move(2, 2); await c.page.waitForTimeout(300);
    await p.capture(c, `${cle}_retour_depuis_prenom`);
    await cliquer(c.page, /^Continuer$/, { pause: 1500 });
  }
  return v;
}

/// La famille jusqu'au recapitulatif, puis l'envoi observe (UX-043).
async function familleJusquAuxConditions(c, cle, famille) {
  // Reprise la ou la carte choisie s'est arretee : la question du prenom.
  const v = {};
  const rep = [
    { q: /Comment s'appelle votre enfant/, saisie: famille.enfant },
    { q: /Quel âge a/, choix: /^9 ans$/ }, { q: / est…/, choix: /^Un garçon$/ },
    { q: /Où en est .* aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
    { q: /Suivez-vous aussi des cours/, choix: /^Non$/ }, { q: /Dans quelle langue/, choix: /^Français$/ },
    { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ }, { q: /Quels moments/, choix: /^Le soir$/ },
  ];
  for (let k = 0; k < 14 && !c.page.url().includes('/connexion'); k++) {
    const l = await libelles(c.page);
    const question = l.filter((x) => x.startsWith('flt-semantics:')).slice(0, 2).join(' / ');
    const r = rep.find((x) => x.q.test(question));
    if (!r) throw new Error(`questionnaire : question imprevue « ${question} »`);
    if (r.saisie) await taper(c.page, 'input', r.saisie);
    if (r.choix) await cliquer(c.page, r.choix, { pause: 500 });
    await cliquer(c.page, /^Continuer$/, { pause: 1300 });
  }
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
  const lignesAvant = (await lus(c.page, 60)).match(new RegExp(famille.enfant)) ? 1 : 0;
  await p.capture(c, `${cle}_recapitulatif`);
  // L'arrivee, lue toutes les 40 ms pendant 4 s : titres et boutons vus ;
  // puis une suite d'images (apres/), comparable a celle d'avant la
  // correction (avant/, version de main 483992a8).
  const suite = path.join(p.sortie, 'apres');
  fs.mkdirSync(suite, { recursive: true });
  for (const f of fs.readdirSync(suite)) if (f.startsWith(`${cle}_`)) fs.rmSync(path.join(suite, f));
  await envoyer.click();
  let image = 0;
  const vus = [];
  const t0 = Date.now();
  const fin = t0 + 4000;
  while (Date.now() < fin) {
    const l = (await libelles(c.page)).map(net);
    const titre = l.find((x) => /^(flt-semantics|h1|h2):(Voici ce que nous avons compris|Votre compte|Votre dossier)/.test(x)) ?? '';
    const marque = `${titre.replace(/^[^:]*:/, '')}${l.some((x) => /Réessayer/.test(x)) ? ' + Réessayer' : ''}`
      + `${titre.includes('Voici') && !l.some((x) => x.includes(famille.enfant)) ? ' + lignes perdues' : ''}`;
    if (marque && vus[vus.length - 1]?.split(' @')[0] !== marque) vus.push(`${marque} @${Date.now() - t0} ms`);
    if (image < 12) {
      await c.page.screenshot({ path: path.join(suite, `${cle}_${String(image).padStart(2, '0')}_${Date.now() - t0}ms.png`) });
      image += 1;
    }
    await c.page.waitForTimeout(40);
  }
  p.dire(`${cle}, arrivee apres l'envoi : ${vus.join(' -> ')}`);
  v.recapitulatifComplet = lignesAvant === 1;
  v.jamaisReessayer = !vus.some((x) => x.includes('Réessayer'));
  v.jamaisLignesPerdues = !vus.some((x) => x.includes('lignes perdues'));
  v.jamaisVotreDossier = !vus.some((x) => x.startsWith('Votre dossier'));
  v.arriveeVotreCompte = vus[vus.length - 1]?.startsWith('Votre compte') ?? false;
  await activerSemantique(c.page);
  // Arrivee sur `/attente` : les reponses du questionnaire ont quitte
  // l'appareil (elles restaient affichees jusqu'au depart).
  await c.page.waitForTimeout(800);
  v.reponsesQuittentLAppareil = await c.page.evaluate(
    () => !localStorage.getItem('rewayah.inscription.questionnaire'));
  await p.capture(c, `${cle}_votre_compte`);
  const lire = await trouver(c.page, /^Lire et accepter nos conditions$/, { delai: 5000 });
  v.conditionsStables = false;
  if (lire) {
    await lire.click(); await c.page.waitForTimeout(1500);
    const a = await c.page.screenshot(); await c.page.waitForTimeout(600);
    const b = await c.page.screenshot();
    v.conditionsStables = a.equals(b);
    await p.capture(c, `${cle}_conditions`);
    // Cocher une case : seule la case et la phrase du compte changent.
    const caseA = c.page.getByRole('checkbox').first();
    await caseA.click(); await c.page.waitForTimeout(1200);
    const d = await c.page.screenshot(); await c.page.waitForTimeout(600);
    v.stablesApresUneCase = d.equals(await c.page.screenshot());
    await p.capture(c, `${cle}_conditions_une_case`);
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
    const v = await carteChoisie(c, cle);
    const famille = { courriel: `e2e-i3-${largeur}-${tampon}@example.com`, enfant: `Yanis${largeur}${tampon}`,
      prenom: 'E2E Parent', nom: `Iii${largeur}${tampon}` };
    familles[cle] = famille;
    Object.assign(v, await familleJusquAuxConditions(c, cle, famille));
    verdicts[cle] = v;
    p.dire(`${cle} : ${JSON.stringify(v)}`);
  }

  // L'arabe : la carte choisie, puis la famille de 390 rouverte en arabe.
  for (const [largeur, hauteur] of [[1440, 900], [390, 844]]) {
    const cle = `${largeur}_ar`;
    const c = await p.contexte('famille', { vue: { width: largeur, height: hauteur }, langue: 'ar-SA' });
    const v = await carteChoisie(c, cle, { continuer: false });
    const famille = familles[`${largeur}`];
    sql(`update auth.users set encrypted_password = crypt('${MDP}', gen_salt('bf')) where email = '${famille.courriel}'`);
    await ouvrir(c.page, '/');
    if (!(await c.page.locator('input[type=password]').count())) {
      const deja = await trouver(c.page, new RegExp(`^${AR('connexion.modeConnexion')}`), { delai: 8000 });
      if (deja) { await deja.click(); await c.page.waitForTimeout(1200); }
    }
    await taper(c.page, 'input[autocomplete=email], input[inputmode=email]', famille.courriel);
    await taper(c.page, 'input[type=password]', MDP);
    await c.page.keyboard.press('Enter');
    await c.page.waitForTimeout(6000); await activerSemantique(c.page);
    const l = net(await lus(c.page, 60));
    v.votreCompteArabe = l.includes(AR('attente.titreCompte'));
    await p.capture(c, `${cle}_votre_compte`);
    const lire = await trouver(c.page, new RegExp(`^${AR('attente.lireEtAccepter')}`), { delai: 5000 });
    v.conditionsArabe = false;
    if (lire) {
      await lire.click(); await c.page.waitForTimeout(2000); await activerSemantique(c.page);
      v.conditionsArabe = net(await lus(c.page, 40)).includes(AR('accords.titre'));
      await p.capture(c, `${cle}_conditions`);
    }
    verdicts[cle] = v;
    p.dire(`${cle} : ${JSON.stringify(v)}`);
  }

  const ok = Object.values(verdicts).every((v) => Object.values(v).every(Boolean));
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(code);
