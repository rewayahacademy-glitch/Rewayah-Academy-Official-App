// TXT-1 (pilote, 02/11/2026) : trois textes vus par le directeur, sur la pile
// LOCALE, a 390 x 844.
//
// Ce que le parcours prouve :
//   * UX-001 : la page Messages de l'enseignant s'intitule « Messages », et
//     nulle part « Messages métier » ;
//   * UX-005 : au recapitulatif de l'inscription, rouvert par le lien recu
//     (le referentiel des langues n'est pas charge), la langue du cours se dit
//     « Français », jamais le code « francais » ;
//   * UX-012 : prouve a part, par test/capture/txt1_presence_capture_test.dart
//     (le vrai ecran « Suivi » a 390, presence non lue : « Présence pas encore
//     connue », jamais « État inconnu »).
//
// Donnees de test, sur la pile LOCALE seulement : une famille fictive
// (adresse e2e-txt1-...@example.com), menee jusqu'au recapitulatif, sans
// envoyer la demande. Rien n'est efface. Aucune migration.
// Usage : node tool/e2e/txt1_textes.mjs
import { parcours, ouvrir, cliquer, trouver, libelles, taper, connecter,
  activerSemantique, amenerEnVue, MAILPIT, COMPTES } from './commun.mjs';

const p = await parcours('TXT-1 : Messages, langue du recapitulatif, presence inconnue', 'txt-1');
let code = 1;
const net = (s) => s.replace(/[\u2068\u2069]/g, '');
const lus = async (page, n = 200) => net((await libelles(page)).slice(0, n).join(' | '));

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

/// Le questionnaire, sans rien en verifier : seulement pour arriver au
/// compte.
async function questionnaire(c, famille) {
  await ouvrir(c.page, '/#/commencer');
  await c.page.waitForTimeout(2000); await activerSemantique(c.page);
  await c.page.getByRole('radio').nth(1).click(); await c.page.waitForTimeout(800);
  await cliquer(c.page, /^Continuer$/, { pause: 1300 });
  const rep = [
    { q: /Comment s'appelle votre enfant/, saisie: famille.enfant },
    { q: /Quel âge a/, choix: /^9 ans$/ }, { q: / est…/, choix: /^Un garçon$/ },
    { q: /Où en est .* aujourd'hui/, choix: /^Nous commençons par les lettres$/ },
    { q: /Suivez-vous aussi des cours/, choix: /^Non$/ }, { q: /Dans quelle langue/, choix: /^Français$/ },
    { q: /Que souhaitez-vous d'abord/, choix: /^Apprendre à lire$/ },
    { q: /Quels moments/, choix: /^Le soir$/ },
  ];
  for (let k = 0; k < 14 && !c.page.url().includes('/connexion'); k++) {
    await activerSemantique(c.page);
    const l = await libelles(c.page);
    const question = l.filter((x) => /^(flt-semantics|h1|h2|heading):/.test(x)).slice(0, 3).join(' / ');
    if (/Créer votre compte/.test(question)) break;
    const r = rep.find((x) => x.q.test(question));
    if (!r) throw new Error(`questionnaire : question imprevue « ${question} »`);
    if (r.saisie) await taper(c.page, 'input', r.saisie);
    if (r.choix) await cliquer(c.page, r.choix, { pause: 600 });
    await cliquer(c.page, /^Continuer$/, { pause: 1300 });
  }
}

/// Le compte, le recapitulatif, l'envoi, puis « Lire et accepter nos
/// conditions ».
async function jusquAuRecap(c, famille) {
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
}

try {
  const v = {};
  // UX-001 : la page Messages de l'enseignant.
  const e = await p.contexte('enseignant', { vue: { width: 390, height: 844 } });
  await connecter(e.page, COMPTES.enseignant);
  await ouvrir(e.page, '/#/enseignant/messages');
  await e.page.waitForTimeout(3500); await activerSemantique(e.page);
  const lm = await lus(e.page);
  v.messagesTitre = /(^|\| )(h1|h2|heading|flt-semantics):Messages( \||$)/.test(lm) || lm.includes('Messages');
  v.sansMetier = !/métier/.test(lm);
  await p.capture(e, '1_messages');
  await e.ctx.close();

  // UX-005 : le recapitulatif, rouvert par le lien recu.
  const c = await p.contexte('famille', { vue: { width: 390, height: 844 } });
  const n = `${Date.now() % 1000000}`;
  const famille = { courriel: `e2e-txt1-${n}@example.com`, enfant: `Lina${n}`, prenom: 'E2E Parent', nom: `Txt${n}` };
  await questionnaire(c, famille);
  await jusquAuRecap(c, famille);
  await activerSemantique(c.page);
  const lr = await lus(c.page, 300);
  v.langueNommee = lr.includes('Français');
  v.sansCodeBrut = !/(^|[\s|:])francais([\s|]|$)/.test(lr);
  const langue = await trouver(c.page, /Français/, { delai: 4000 });
  if (langue) await amenerEnVue(c.page, langue);
  await p.capture(c, '2_recapitulatif');
  await c.ctx.close();

  // UX-012 : la ligne de presence non lue est capturee par
  // test/capture/txt1_presence_capture_test.dart, sur le vrai ecran « Suivi »
  // (03_suivi_390_ligne_presence.png) : une seance tenue sans trace de
  // presence ne s'obtient pas simplement sur la pile, et la galerie est
  // fermee en build de production.

  p.dire(JSON.stringify(v));
  const ok = Object.values(v).every(Boolean);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(v));
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
