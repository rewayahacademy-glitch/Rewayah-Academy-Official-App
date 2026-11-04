// Parcours 7, fin : apres le paiement dans l'application et la confirmation du
// prestataire (webhook), la famille lit « Le paiement est reçu », son solde, et
// recoit l'e-mail. Usage : node tool/e2e/parcours_7_credit.mjs
// Pile LOCALE seulement. Sur ce banc, la confirmation est un evenement
// checkout.session.completed signe avec un secret FACTICE du banc et poste au
// webhook local : la signature reelle de Stripe n'est pas prouvee ici.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecterParLien, ouvrir, trouverTexte, libelles, activerSemantique,
  MAILPIT, TRAVAIL } from './commun.mjs';

const { FAMILLE } = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'comptes_parcours3.json'), 'utf8'));
const p = await parcours('Parcours 7, fin : paiement confirme, la famille le lit', 'parcours-7-credit');
const manque = [];
const f = await p.contexte('famille', { telephone: true });
await connecterParLien(f.page, FAMILLE.courriel);
await f.page.waitForTimeout(3000);
await ouvrir(f.page, '/#/tuteur/notifications');
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const recu = await trouverTexte(f.page, /Le paiement est reçu[^|]*/, 15000);
await p.capture(f, 'notifications');
p.dire(`Notification : ${recu ?? 'absente'}`);
if (!recu) manque.push('notification « Le paiement est reçu » absente');
await ouvrir(f.page, '/#/tuteur/foyer/recharge');
await f.page.waitForTimeout(4000); await activerSemantique(f.page);
const solde = await trouverTexte(f.page, /Solde actuel[^|]*/, 10000);
await p.capture(f, 'recharge_apres');
p.dire(`Recharge : ${solde ?? '-'} ; ${(await libelles(f.page)).slice(0, 6).join(' | ').slice(0, 300)}`);
const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${FAMILLE.courriel}`)}`)).json();
const courriel = (r.messages ?? []).find((m) => /paiement/i.test(m.Subject));
if (courriel) {
  await f.page.goto(`${MAILPIT}/view/${courriel.ID}.html`);
  await f.page.waitForTimeout(1500);
  await p.capture(f, 'courriel');
}
p.dire(`E-mail : ${courriel ? courriel.Subject : 'aucun'}`);
if (!courriel) manque.push('e-mail de paiement recu absent');
await f.ctx.close();
process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'paiement confirme : notification, solde et e-mail'));
