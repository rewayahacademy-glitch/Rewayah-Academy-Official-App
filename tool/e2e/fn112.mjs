// FN-112 : borner la cause de « Vous n'avez pas accès à cette page » apres une heure
// d'Accueil ouvert (eleve adulte). Observe, ne corrige rien : toutes les 5 min, l'expiration
// du jeton d'acces (localStorage) et l'ecran ; a la fin, « Retour a l'accueil », puis rechargement.
import fs from 'node:fs';
import { parcours, connecterParLien, cliquer, trouver, libelles, activerSemantique, TRAVAIL } from './commun.mjs';
const MINUTES = Number(process.argv[2] ?? 70);
const { ADULTE } = JSON.parse(fs.readFileSync(TRAVAIL + '/comptes_parcours3.json', 'utf8'));
const p = await parcours('FN-112 : Accueil ouvert plus d\'une heure', 'constats/FN-112');
const a = await p.contexte('adulte', { telephone: true });
const requetes = [];
a.page.on('response', (r) => { if (/auth\/v1\/token|rest\/v1\/rpc|rest\/v1\//.test(r.url()) && r.status() >= 400) requetes.push(`${new Date().toISOString()} ${r.status()} ${r.url().replace(/\?.*/, '').slice(-60)}`); });
a.page.on('request', (r) => { if (/auth\/v1\/token/.test(r.url())) requetes.push(`${new Date().toISOString()} demande ${r.url().replace(/^.*auth\/v1\//, '')}`); });
await connecterParLien(a.page, ADULTE.courriel);
const jeton = () => a.page.evaluate(() => {
  for (const k of Object.keys(localStorage)) if (/auth-token/.test(k)) { try { const v = JSON.parse(localStorage.getItem(k)); return { cle: k, expire: new Date(v.expires_at * 1000).toISOString(), debut: v.access_token.slice(-8) }; } catch { return { cle: k, brut: true }; } }
  return null;
});
const ecran = async () => { await activerSemantique(a.page); return (await libelles(a.page)).slice(0, 4).join(' | ').slice(0, 200); };
p.dire(`Depart : jeton ${JSON.stringify(await jeton())} ; ecran ${await ecran()}`);
await p.capture(a, 'depart');
for (let m = 5; m <= MINUTES; m += 5) {
  await a.page.waitForTimeout(5 * 60 * 1000);
  p.dire(`+${m} min : jeton ${JSON.stringify(await jeton())} ; url ${a.page.url()} ; ecran ${await ecran()}`);
}
await p.capture(a, 'apres_attente');
p.dire(`Requetes d'authentification ou en erreur : ${requetes.join(' ; ') || 'aucune'}`);
const retour = await trouver(a.page, /^Retour à l'accueil/, { delai: 2000 });
if (retour) { await retour.click(); await a.page.waitForTimeout(5000); p.dire(`Apres « Retour à l'accueil » : url ${a.page.url()} ; ${await ecran()}`); await p.capture(a, 'apres_retour_accueil'); }
else p.dire('Pas de « Retour à l\'accueil » a l\'ecran');
const r1 = await trouver(a.page, /^Rejoindre/, { delai: 3000, role: 'button' });
p.dire(`« Rejoindre » visible : ${!!r1}`);
await a.page.reload(); await a.page.waitForTimeout(8000);
p.dire(`Apres rechargement : url ${a.page.url()} ; ${await ecran()} ; jeton ${JSON.stringify(await jeton())}`);
await p.capture(a, 'apres_rechargement');
const r2 = await trouver(a.page, /^Rejoindre/, { delai: 5000, role: 'button' });
p.dire(`« Rejoindre » visible apres rechargement : ${!!r2}`);
p.dire(`Requetes (fin) : ${requetes.slice(-12).join(' ; ') || 'aucune'}`);
await p.fin('joué');
