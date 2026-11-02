// FN-115a : la famille lit les conditions de remboursement et de contestation
// avant de payer. Usage : node tool/e2e/fn115a_conditions.mjs
// Prerequis : le parcours 3 a cree la famille (comptes_parcours3.json).
// Pile LOCALE seulement. Rien n'est paye : le lien sous « Payer » ouvre le texte
// « Annulation et remboursement », qui dit la premiere semaine (sauf les
// seances suivies), l'acces sans paiement et la contestation aupres de la banque.
import fs from 'node:fs';
import { parcours, connecterParLien, ouvrir, trouver, trouverTexte, libelles,
  activerSemantique, TRAVAIL } from './commun.mjs';

const { FAMILLE } = JSON.parse(fs.readFileSync(TRAVAIL + '/comptes_parcours3.json', 'utf8'));
const p = await parcours('FN-115a : conditions de remboursement et de contestation, lues avant de payer',
  'fn115a-conditions');
const manque = [];

const f = await p.contexte('tuteur', { telephone: true });
await connecterParLien(f.page, FAMILLE.courriel);
await f.page.waitForTimeout(3000);
await ouvrir(f.page, '/#/tuteur/foyer/recharge');
await f.page.waitForTimeout(3000); await activerSemantique(f.page);
// Un profil coche fait paraitre le recapitulatif et « Payer ».
const coche = await trouver(f.page, new RegExp(FAMILLE.enfant), { delai: 10000, role: 'checkbox' });
if (coche) { await coche.click(); await f.page.waitForTimeout(2500); await activerSemantique(f.page); }
const lien = await trouver(f.page, /^Remboursement et contestation/, { delai: 15000 });
if (lien) await lien.scrollIntoViewIfNeeded().catch(() => {});
await f.page.waitForTimeout(800);
await p.capture(f, 'recharge_lien_conditions');
const payer = await trouver(f.page, /^Payer/, { delai: 3000, role: 'button' });
p.dire(`Recharge : « Payer » ${payer ? 'present' : 'absent'} ; lien ${lien ? (await lien.getAttribute('aria-label')) : 'absent'}`);
const fraisPage = await trouverTexte(f.page, /frais de la contestation sont ajoutés au solde de votre foyer/, 5000);
p.dire(`Phrase des frais sur la page de paiement : ${fraisPage ? 'oui' : 'non'}`);
if (!fraisPage) manque.push('phrase des frais de contestation absente de la page de paiement');
if (!lien) manque.push('lien « Remboursement et contestation » absent de la page de paiement');
else {
  await lien.click(); await f.page.waitForTimeout(4000); await activerSemantique(f.page);
  const url = f.page.url();
  const semaine = await trouverTexte(f.page, /sauf les séances déjà suivies[^|]*/, 10000);
  await p.capture(f, 'annulation_haut');
  const litige = await trouverTexte(f.page, /Contester un paiement auprès de sa banque/, 10000);
  // Le texte defile en entier (la liste est la page) : la molette amene la
  // section de la contestation a l'ecran.
  await f.page.mouse.move(195, 400);
  for (let i = 0; i < 12; i++) { await f.page.mouse.wheel(0, 300); await f.page.waitForTimeout(150); }
  await f.page.waitForTimeout(800); await activerSemantique(f.page);
  const frais = await trouverTexte(f.page, /ajoutés au solde de votre foyer[^|]*/, 5000);
  const sansPaiement = await trouverTexte(f.page, /accès aux séances et aux ressources est suspendu[^|]*/, 5000);
  await p.capture(f, 'annulation_contestation');
  p.dire(`Texte : ${url} ; premiere semaine : ${semaine ?? 'absente'} ; contestation : ${litige ?? 'absente'} ; frais : ${frais ? 'oui' : 'non'} ; sans paiement : ${sansPaiement ? 'oui' : 'non'}`);
  // GoRouter.push ne change pas l'adresse affichee (retour arriere vers la
  // page de paiement) : on verifie le titre du texte ouvert, pas l'URL.
  const titreTexte = await trouverTexte(f.page, /^Annulation et remboursement$/, 5000);
  if (!titreTexte) manque.push(`le lien n ouvre pas le texte (${url})`);
  if (!semaine) manque.push('premiere semaine « sauf les seances deja suivies » absente');
  if (!litige) manque.push('section contestation absente');
  if (!frais) manque.push('frais de contestation au solde du foyer absents');
  if (!sansPaiement) manque.push('« acces aux seances et aux ressources suspendu » absent');
}
p.dire(`Ecran : ${(await libelles(f.page)).slice(0, 6).join(' | ')}`);
await f.ctx.close();
process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'le lien sous « Payer » ouvre les conditions : premiere semaine, acces sans paiement, contestation'));
