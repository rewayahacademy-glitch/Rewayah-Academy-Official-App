// FN-111 (lot 13 FN-DIVERS, 06/11/2026) : un lien de connexion ouvert sur un
// autre appareil (un autre navigateur) que celui ou il a ete demande.
// Avant : « Se connecter » sans un mot (parcours 3, piege 3.1, 31/10).
// Attendu : le bandeau « Ce lien a été ouvert sur un autre appareil », en
// tete de la page ; et, temoin, le meme lien ouvert dans le navigateur qui
// l'a demande ouvre la session, sans bandeau.
// Usage : node tool/e2e/fn111_lien_ailleurs.mjs   (pile locale, comptes amorces)
import { parcours, ouvrir, cliquer, taper, trouverTexte, dernierLien, libelles,
  activerSemantique, COMPTES } from './commun.mjs';

const p = await parcours('FN-111 : lien de connexion ouvert sur un autre appareil', 'fn-divers/robot');
const TITRE = /Ce lien a été ouvert sur un autre appareil/;
const resultats = [];

for (const vue of [{ nom: '390', telephone: true }, { nom: '1440', vue: { width: 1440, height: 900 } }]) {
  // A demande le lien ; B l'ouvre (autre navigateur, stockage vide).
  const a = await p.contexte(`demandeur-${vue.nom}`, vue);
  await ouvrir(a.page, '/#/connexion?mode=connexion');
  const depuis = Date.now();
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', COMPTES.enseignant);
  await cliquer(a.page, /^Recevoir le lien$/, { pause: 2500 });
  const recu = await dernierLien(COMPTES.enseignant, depuis, 60000);
  if (!recu?.lien) {
    resultats.push(`${vue.nom} : aucun lien recu`);
    await a.ctx.close();
    continue;
  }
  const b = await p.contexte(`autre-appareil-${vue.nom}`, vue);
  await b.page.goto(recu.lien); await b.page.waitForTimeout(8000); await activerSemantique(b.page);
  const bandeau = await trouverTexte(b.page, TITRE, 15000);
  p.dire(`  ${vue.nom}, autre appareil : ${b.page.url()} ; bandeau : ${bandeau ?? 'absent'}`);
  await p.capture(b, `fn111_${vue.nom}_autre_appareil`);

  // Temoin : un second lien, ouvert dans le navigateur qui l'a demande.
  const depuis2 = Date.now();
  await ouvrir(a.page, '/#/connexion?mode=connexion');
  await taper(a.page, 'input[autocomplete=email], input[inputmode=email]', COMPTES.enseignant);
  await cliquer(a.page, /^Recevoir le lien$/, { pause: 2500 });
  const recu2 = await dernierLien(COMPTES.enseignant, depuis2, 60000);
  let temoin = 'non joue';
  if (recu2?.lien) {
    await a.page.goto(recu2.lien); await a.page.waitForTimeout(8000); await activerSemantique(a.page);
    const bandeauA = await trouverTexte(a.page, TITRE, 3000);
    const seConnecter = await trouverTexte(a.page, /^Se connecter$/, 3000);
    temoin = !bandeauA && !seConnecter ? 'session ouverte, sans bandeau' : `bandeau ${bandeauA ?? 'absent'} ; Se connecter ${seConnecter ? 'visible' : 'absent'}`;
    p.dire(`  ${vue.nom}, meme navigateur : ${a.page.url()} ; ${temoin} ; ${(await libelles(a.page)).slice(0, 4).join(' | ')}`);
    await p.capture(a, `fn111_${vue.nom}_meme_navigateur`);
  }
  resultats.push(`${vue.nom} : autre appareil ${bandeau ? 'bandeau present' : 'SANS bandeau'} ; meme navigateur ${temoin}`);
  if (!bandeau || temoin !== 'session ouverte, sans bandeau') resultats.push('ROUGE');
  await a.ctx.close(); await b.ctx.close();
}
process.exit(await p.fin(resultats.includes('ROUGE') || resultats.some((r) => /aucun lien/.test(r)) ? 'rouge' : 'vert', resultats.join(' ; ')));
