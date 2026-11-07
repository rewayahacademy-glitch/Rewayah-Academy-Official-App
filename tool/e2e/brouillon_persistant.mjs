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

const REPONSES = [
  { q: /Comment vous appelez-vous|Votre prénom/, saisie: 'Amina' },
  { q: /Vous êtes…|Êtes-vous/, choix: /^Une femme$/ },
  { q: /Dans quelle langue/, choix: /^Français$/ },
  { q: /Où en êtes-vous aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
  { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
  { q: /Quels moments/, choix: /^Le soir$/ },
];

async function jusquauCourriel(a) {
  for (let k = 0; k < 14; k++) {
    if (/etape=acces/.test(a.page.url())) return;
    const l = await libelles(a.page);
    const question = l.filter((x) => x.startsWith('flt-semantics:') || x.startsWith('h2:')).slice(0, 4).join(' / ');
    const regle = REPONSES.find((r) => r.q.test(question));
    if (!regle) throw new Error(`questionnaire : question imprevue « ${question} »`);
    if (regle.saisie) await taper(a.page, 'input', regle.saisie);
    if (regle.choix) await cliquer(a.page, regle.choix, { pause: 500 });
    await cliquer(a.page, /^Continuer$/, { pause: 1300 });
  }
  throw new Error('questionnaire : trop d\'etapes');
}

/// Joue le geste complet dans un contexte ; rend { avant, apres }.
async function jouer(nom, options) {
  const a = await p.contexte(nom, { ...options, langue: LANGUE });
  const courriel = `e2e-brouillon-${nom}-${tampon}@example.com`;
  await ouvrir(a.page, '/');
  await cliquer(a.page, /^Je m'inscris pour moi/);
  await cliquer(a.page, /^Continuer$/);
  await jusquauCourriel(a);
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  const depuis = Date.now();
  await cliquer(a.page, /^Recevoir le lien( d'inscription)?$/, { pause: 2500 });
  const recu = await dernierLien(courriel, depuis);
  if (!recu?.lien) throw new Error(`aucun lien recu pour ${courriel}`);
  await a.page.goto(recu.lien);
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  if (!/identite/.test(a.page.url())) throw new Error(`identite non atteinte : ${a.page.url()}`);

  const champPrenom = a.page.locator('input[aria-label="Prénom"]');
  await taper(a.page, 'input[aria-label="Prénom"]', 'Amina');
  await taper(a.page, 'input[aria-label="Nom"]', 'Diallo');
  const avant = await champPrenom.inputValue();
  await p.capture(a, 'avant_rechargement');

  await a.page.reload();
  await a.page.waitForTimeout(6000);
  await activerSemantique(a.page);
  await p.capture(a, 'apres_rechargement');
  const apres = await a.page.locator('input[aria-label="Prénom"]').inputValue().catch(() => '');
  const nomApres = await a.page.locator('input[aria-label="Nom"]').inputValue().catch(() => '');
  p.dire(`${nom} : prenom saisi « ${avant} » ; apres rechargement : prenom « ${apres} », nom « ${nomApres} » ; ${a.page.url()}`);
  await a.ctx.close();
  return { avant, apres, nomApres };
}

let code = 1;
try {
  const tel = await jouer('telephone-390', { telephone: true });
  const bur = await jouer('bureau-1440', { vue: { width: 1440, height: 900 } });
  for (const [nom, r] of [['390', tel], ['1440', bur]]) {
    if (r.apres !== 'Amina' || r.nomApres !== 'Diallo') {
      throw new Error(`${nom} : prenom « ${r.apres} » et nom « ${r.nomApres} » apres rechargement (attendu « Amina » et « Diallo »)`);
    }
  }
  code = await p.fin('vert');
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
