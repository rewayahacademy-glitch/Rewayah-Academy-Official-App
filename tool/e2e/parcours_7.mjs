// Parcours 7 : la famille voit la classe, la presence, et paie.
// 1. Accueil : l'enfant, sa classe, sa prochaine seance ; « Voir la classe ».
// 2. « Historique » : une seance passee, heure d'arrivee, de sortie, minutes, presence.
// 3. « Foyer » › « Recharger » › « Payer … » : sans cle Stripe (ni en production
//    ni en local), on constate ce que l'ecran dit ; l'etape reste rouge.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecterParLien, cliquer, trouver, trouverTexte, libelles, allerOnglet,
  activerSemantique, amenerEnVue, TRAVAIL } from './commun.mjs';

const lire = (f) => JSON.parse(fs.readFileSync(path.join(TRAVAIL, f), 'utf8'));
const p = await parcours('Parcours 7 : la famille voit la classe, la presence, et paie', 'parcours-7');
const echecs = [];
let code = 1;
try {
  const { FAMILLE } = lire('comptes_parcours3.json');
  const f = await p.contexte('famille', { telephone: true });
  await connecterParLien(f.page, FAMILLE.courriel);
  await f.page.waitForTimeout(3000);
  await p.capture(f, 'accueil');
  // 1. L'enfant, sa classe, sa prochaine seance.
  const enfant = await trouverTexte(f.page, FAMILLE.enfant, 10000);
  const classe = await trouverTexte(f.page, /E2E Classe [^|]*/, 5000);
  const heure = await trouverTexte(f.page, /(Heure de cet appareil|Prochaine séance|\d{1,2}:\d{2})[^|]*/, 5000);
  p.dire(`Accueil : enfant « ${enfant ?? '-'} » ; classe « ${classe ?? '-'} » ; heure « ${heure ?? '-'} »`);
  if (!enfant || !classe) echecs.push(`Accueil : ${!enfant ? 'enfant' : 'classe'} absent(e)`);
  const voir = await trouver(f.page, /^Voir la classe/, { delai: 5000, role: 'link' });
  if (voir) {
    await amenerEnVue(f.page, voir);
    await voir.click(); await f.page.waitForTimeout(3000); await activerSemantique(f.page);
    await p.capture(f, 'voir_la_classe');
    p.dire(`« Voir la classe » : ${(await libelles(f.page)).filter((x) => x.startsWith('flt-semantics:') || x.startsWith('h2:')).slice(0, 10).join(' | ')}`);
    const r = await trouver(f.page, /^Retour$/, { delai: 2000, role: 'button' });
    if (r) { await r.click(); await f.page.waitForTimeout(1500); }
  } else echecs.push('Accueil : pas de « Voir la classe »');

  // 2. Historique : une seance passee, arrivee, sortie, minutes, presence.
  await allerOnglet(f.page, 'Historique', '/tuteur/historique', p.dire);
  await f.page.waitForTimeout(2000);
  await p.capture(f, 'historique');
  p.dire(`Historique : ${(await libelles(f.page)).filter((x) => /^(button|flt-semantics|a):/.test(x)).slice(0, 14).join(' | ').slice(0, 700)}`);
  const seance = await trouver(f.page, /^Séance du /, { delai: 8000, role: 'button' });
  if (!seance) echecs.push('Historique : aucune seance passee a ouvrir');
  else {
    await seance.click(); await f.page.waitForTimeout(3000); await activerSemantique(f.page);
    await p.capture(f, 'seance_passee');
    const detail = (await libelles(f.page)).filter((x) => /(arriv|sorti|minute|présen|partiel|absent)/i.test(x));
    p.dire(`Seance passee : ${detail.join(' | ').slice(0, 600)}`);
    if (!detail.some((x) => /\bmin\b|minute/i.test(x))) echecs.push('Historique, seance passee : minutes absentes');
    if (!detail.some((x) => /(présen|partiel|absent)/i.test(x))) echecs.push('Historique, seance passee : presence absente');
    if (!detail.some((x) => /arriv/i.test(x))) echecs.push('Historique, seance passee : heure d\'arrivee absente');
  }

  // 3. Recharger, Payer : par « Finances de … » (Accueil), le chemin du carnet
  // (« Foyer › Recharger ») n'existe pas dans cet ecran.
  await allerOnglet(f.page, 'Foyer', '/tuteur/foyer', p.dire);
  let recharger = await trouver(f.page, /Recharger/, { delai: 4000 });
  if (!recharger) {
    p.dire('  ECART : pas de « Recharger » sur le Foyer ; essai par l\'Accueil, « Finances de … »');
    await allerOnglet(f.page, 'Accueil', '/tuteur', p.dire);
    const fin = await trouver(f.page, /^Finances de/, { delai: 5000, role: 'link' });
    if (fin) { await amenerEnVue(f.page, fin); await fin.click(); await f.page.waitForTimeout(3000); await activerSemantique(f.page); await p.capture(f, 'finances'); }
    p.dire(`  Finances : ${(await libelles(f.page)).filter((x) => /^(button|flt-semantics|a|h2):/.test(x)).slice(0, 16).join(' | ').slice(0, 600)}`);
    recharger = await trouver(f.page, /Recharger/, { delai: 4000 });
  }
  if (!recharger) {
    // « Recharger » ne s'affiche que quand le solde le demande (ici : « Accès
    // sans échéance ») ; l'ecran de recharge s'ouvre alors par son adresse.
    p.dire('  « Recharger » absent (acces sans echeance) : ecran de recharge ouvert par /tuteur/foyer/recharge');
    await f.page.evaluate(() => { location.hash = '#/tuteur/foyer/recharge'; });
    await f.page.waitForTimeout(3000); await activerSemantique(f.page);
  } else {
    await amenerEnVue(f.page, recharger);
    await recharger.click(); await f.page.waitForTimeout(3000); await activerSemantique(f.page);
  }
  {
    await p.capture(f, 'recharger');
    p.dire(`  Recharge : ${(await libelles(f.page)).filter((x) => /^(button|flt-semantics|radio|checkbox|h2):/.test(x)).slice(0, 18).join(' | ').slice(0, 700)}`);
    const cocher = f.page.getByRole('checkbox');
    if (await cocher.count() && (await cocher.first().getAttribute('aria-checked')) !== 'true') await cocher.first().click();
    // Le montant : le bouton « + » de la carte du profil (sans nom lisible :
    // touche a sa position, 390 x 780 : x 329, y 279).
    const plus = await trouver(f.page, /^(Augmenter|Ajouter|Plus)/, { delai: 1500, role: 'button' });
    if (plus) await plus.click(); else await f.page.mouse.click(329, 279);
    await f.page.waitForTimeout(1500); await activerSemantique(f.page);
    await p.capture(f, 'recharge_ecran');
    p.dire(`  apres « + » : ${(await libelles(f.page)).filter((x) => /\$|Total|Payer/.test(x)).join(' | ').slice(0, 300)}`);
    const payer = await trouver(f.page, /^Payer/, { delai: 5000, role: 'button' });
    if (payer) {
      await amenerEnVue(f.page, payer);
      const actif = await payer.isEnabled().catch(() => false);
      if (!actif) p.dire('  « Payer » inactif (montant 0 $ par defaut ; aucun montant propose a choisir dans l\'arbre d\'accessibilite)');
      else { await payer.click({ timeout: 5000 }).catch(() => {}); await f.page.waitForTimeout(4000); await activerSemantique(f.page); await p.capture(f, 'payer'); }
    }
    const msg = await trouverTexte(f.page, /(pas encore disponible|indisponible|Stripe|paiement)[^|]*/i, 5000);
    p.dire(`Paiement : ${msg ?? 'aucun message'} ; ${f.page.url()}`);
    echecs.push(`paiement non joue : cle Stripe absente (production et pile locale) ; l'ecran dit « ${msg ?? '-'} »`);
  }
  code = await p.fin(echecs.length ? 'rouge' : 'vert', echecs.join(' ; '));
} catch (err) {
  code = await p.fin('rouge', String(err.message ?? err).slice(0, 700));
}
process.exit(code);
