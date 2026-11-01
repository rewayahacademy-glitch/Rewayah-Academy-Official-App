// Gestes d'inscription d'une famille ou d'un adulte, et acceptation par la
// direction, partages par les cas reels et les pieges (meme chemin que le
// parcours 3, sans en changer le script).
import { ouvrir, cliquer, trouver, trouverTexte, libelles, taper, dernierLien, activerSemantique } from './commun.mjs';

/// Repond au questionnaire ; `reponses` : [{ q: /question/, saisie?, choix? }].
/// Une question sans regle arrete et rend la question (piege a observer).
export async function questionnaire(p, a, reponses, prefixe = 'q') {
  for (let k = 0; k < 14; k++) {
    if (a.page.url().includes('/connexion')) return null;
    const l = await libelles(a.page);
    const question = l.filter((x) => x.startsWith('flt-semantics:')).slice(0, 3).join(' / ');
    const regle = reponses.find((r) => r.q.test(question));
    await p.capture(a, `${prefixe}_${k}`);
    if (!regle) return question;
    if (regle.saisie) await taper(a.page, 'input', regle.saisie);
    if (regle.choix) await cliquer(a.page, regle.choix, { pause: 500 });
    await cliquer(a.page, /^Continuer$/, { pause: 1300 });
  }
  return 'trop d\'etapes';
}

/// Courriel, lien recu dans Mailpit, identite (prenom, nom, genre), accords,
/// jusqu'a « Votre demande est en cours ». Rend les libelles de l'identite.
export async function inscrire(p, a, { courriel, prenom, nom, genre }, prefixe = 'i') {
  const depuis = Date.now();
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await cliquer(a.page, /^Recevoir le lien d'inscription$/, { pause: 2500 });
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

/// Direction : Personnes › Demandes › liste › « Ouvrir la demande d'… » › « Accepter la demande ».
export async function accepterDemande(p, d, { liste, nomComplet }) {
  await cliquer(d.page, 'Personnes Onglet');
  await cliquer(d.page, /^Sections de la page/);
  await cliquer(d.page, /^Demandes/);
  await cliquer(d.page, new RegExp(`^${liste}$`), { pause: 2000 });
  await cliquer(d.page, new RegExp(`^Ouvrir la demande d.${nomComplet}`), { pause: 2500 });
  await p.capture(d, `demande_${nomComplet.replace(/\W/g, '')}`);
  await cliquer(d.page, /^Accepter la demande/, { role: 'button', pause: 2500 });
  await d.page.keyboard.press('Escape');
  await d.page.waitForTimeout(800);
  await d.page.mouse.click(1150, 700);
  await d.page.waitForTimeout(1200);
}

export async function nouveauCompte(a, choix) {
  await ouvrir(a.page, '/');
  await cliquer(a.page, /^Créer un compte$/);
  await cliquer(a.page, choix);
}
