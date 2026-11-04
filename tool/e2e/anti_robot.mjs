// ANTI-ROBOT (03/11/2026) : le controle Turnstile devant la connexion, sur la
// pile LOCALE, par l'interface (fiche PLAN-LOTS §13, R3).
//
// Deux passages, a 390 et a 1440 :
//   1. reglage vide (`securite.turnstile_cle_site` = "") : aucun widget de
//      Cloudflare dans la page ; le lien de connexion part sans jeton
//      (`gotrue_meta_security.captcha_token` nul dans la demande : le client
//      Supabase envoie toujours la cle, a `null` sans jeton) ; la connexion par mot
//      de passe (banc de demonstration) aboutit ;
//   2. la cle de TEST publique de Cloudflare (reglage du BANC seulement,
//      jamais d'une migration) : le widget est dans la page (cadre
//      challenges.cloudflare.com) ; le lien part AVEC un jeton ; la
//      recuperation aussi ; la connexion par mot de passe aboutit (la pile
//      locale n'active pas le captcha : elle laisse passer le jeton).
// Le reglage est remis a vide a la fin.
//
// Prerequis : pile LOCALE avec la migration 20261109000000, comptes amorces.
// Cloudflare est joint par le proxy de l'environnement : E2E_PROXY doit etre
// pose (comme pour le paiement integre). Usage :
//   E2E_PROXY=$HTTPS_PROXY node tool/e2e/anti_robot.mjs
import { parcours, activerSemantique, connecter, attendreTexte, cliquer, taper, sql, COMPTES, APP } from './commun.mjs';

// La cle de site de TEST publique de Cloudflare (« passe toujours »), pour le
// banc seulement.
const CLE_TEST = '1x00000000000000000000AA';
const CLOUDFLARE = /(^|\.)challenges\.cloudflare\.com$/;
const p = await parcours('ANTI-ROBOT : controle Turnstile a la connexion', 'ANTI-ROBOT');
const VUES = [
  { nom: '390', vue: { width: 390, height: 844 } },
  { nom: '1440', vue: { width: 1440, height: 900 } },
];

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

function regler(cle) {
  sql(`update public.app_config set value = to_jsonb('${cle}'::text) where key = 'securite.turnstile_cle_site'`);
}

/// Un contexte qui laisse passer Cloudflare (et seulement lui) en plus des
/// regles du banc, et qui garde les demandes de lien pour les lire.
async function contexte(vue) {
  const a = await p.contexte('visiteur', { vue: vue.vue });
  a.demandes = [];
  await a.ctx.route('**/*', async (route) => {
    const u = new URL(route.request().url());
    if (CLOUDFLARE.test(u.hostname)) return route.continue();
    if (u.pathname.endsWith('/auth/v1/otp')) a.demandes.push(route.request().postData() ?? '');
    return route.fallback();
  });
  return a;
}

async function ouvrirConnexion(page) {
  await page.goto(`${APP}/#/connexion`);
  await page.waitForTimeout(6000);
  await activerSemantique(page);
}

const cadreCloudflare = async (page) => {
  for (let i = 0; i < 20; i++) {
    if (page.frames().some((f) => CLOUDFLARE.test(new URL(f.url() || 'about:blank', APP).hostname))) return true;
    await page.waitForTimeout(500);
  }
  return false;
};

/// Le jeton porte par une demande de lien (`null` : aucun jeton).
function jeton(corps) {
  try {
    return JSON.parse(corps)?.gotrue_meta_security?.captcha_token ?? null;
  } catch {
    return null;
  }
}

async function demanderLien(a, champ, bouton, attendu) {
  await taper(a.page, champ, `e2e-anti-robot-${Date.now() % 100000}@example.com`);
  await cliquer(a.page, bouton, { pause: 6000 });
  verifier(await attendreTexte(a.page, attendu, 20000), `« ${attendu} » apres l'envoi`);
}

async function passage(vue, cle) {
  const etiquette = cle ? 'cle_test' : 'vide';
  regler(cle ?? '');
  p.dire(`-- ${vue.nom}, reglage ${etiquette}`);

  // La connexion par lien.
  const a = await contexte(vue);
  await ouvrirConnexion(a.page);
  await a.page.waitForTimeout(cle ? 4000 : 1000);
  const widget = await cadreCloudflare(a.page);
  verifier(widget === Boolean(cle), cle ? 'le widget de Cloudflare est dans la page' : 'aucun widget de Cloudflare');
  await p.capture(a, `${vue.nom}_${etiquette}_1_connexion`);
  await demanderLien(a, 'input[autocomplete=email], input[inputmode=email]', /^Recevoir le lien$/, 'Lien envoyé');
  const demande = a.demandes.at(-1) ?? '';
  verifier(cle ? typeof jeton(demande) === 'string' && jeton(demande).length > 0 : jeton(demande) === null,
    cle ? 'la demande de lien porte le jeton (captcha_token)' : 'la demande de lien part sans jeton, comme avant');
  await p.capture(a, `${vue.nom}_${etiquette}_2_lien_envoye`);

  // La recuperation.
  await a.page.goto(`${APP}/#/connexion/recuperation`);
  await a.page.waitForTimeout(5000);
  await activerSemantique(a.page);
  await p.capture(a, `${vue.nom}_${etiquette}_3_recuperation`);
  await demanderLien(a, 'input[autocomplete=email], input[inputmode=email]', /^Recevoir un nouveau lien$/, 'Nouveau lien envoyé');
  const demande2 = a.demandes.at(-1) ?? '';
  verifier(cle ? typeof jeton(demande2) === 'string' && jeton(demande2).length > 0 : jeton(demande2) === null,
    cle ? 'la recuperation porte le jeton' : 'la recuperation part sans jeton');
  await p.capture(a, `${vue.nom}_${etiquette}_4_recuperation_envoyee`);
  await a.ctx.close();

  // La connexion par mot de passe (banc de demonstration).
  const b = await contexte(vue);
  await connecter(b.page, COMPTES.enseignant);
  await b.page.waitForTimeout(3000);
  verifier(!/#\/connexion/.test(b.page.url()), `connexion par mot de passe aboutie (${b.page.url().replace(APP, '')})`);
  await p.capture(b, `${vue.nom}_${etiquette}_5_connecte`);
  await b.ctx.close();
}

let code = 1;
try {
  if (!process.env.E2E_PROXY) throw new Error('E2E_PROXY attendu : Cloudflare est joint par le proxy');
  for (const vue of VUES) {
    await passage(vue, null);
    await passage(vue, CLE_TEST);
  }
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
} finally {
  try { regler(''); } catch { /* pile arretee */ }
}
process.exit(code);
