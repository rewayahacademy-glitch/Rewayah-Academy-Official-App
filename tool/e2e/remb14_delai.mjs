// REMB-14 (directeur, 02/11/2026) : le texte « Annulation et remboursement »
// dit le delai de retractation lu dans la politique, jamais ecrit en dur.
// Usage : node tool/e2e/remb14_delai.mjs
// Pile LOCALE seulement, sans compte : la page s'ouvre sans connexion. Le
// robot lit le delai de la politique du banc (7, comme la production le
// 02/11), le passe a 14 (la decision) sur la base LOCALE, verifie que le texte
// suit, puis remet 7. « Premiere semaine » et « sauf geste de la direction »
// ne doivent plus se lire nulle part dans le texte.
import { parcours, ouvrir, trouver, trouverTexte, amenerEnVue, activerSemantique, sql } from './commun.mjs';

const p = await parcours('REMB-14 : delai de retractation lu dans la politique', 'remb-14');
const manque = [];
const CHEMIN = '/#/juridique/annulation-remboursement';
const espace = '[\\s\\u00a0]';

/// Le delai de la politique du banc (base locale seulement).
function regler(jours) {
  sql(`ALTER TABLE public.politiques_commerciales DISABLE TRIGGER politiques_commerciales_immuable;
       UPDATE public.politiques_commerciales SET remboursement_delai_jours = ${Number(jours)};
       ALTER TABLE public.politiques_commerciales ENABLE TRIGGER politiques_commerciales_immuable;`);
  return sql(`select public.tarifs_publics()#>>'{courante,remboursementDelaiJours}'`);
}

/// Tout le texte lisible de la page.
async function texteEntier(page) {
  return page.evaluate(() => document.body.innerHTML
    .replace(/<script[\s\S]*?<\/script>/g, ' ').replace(/<[^>]+>/g, '\n')
    .replace(/&nbsp;/g, ' ').replace(/[⁨⁩ ]/g, ' '));
}

async function verifier(acteur, jours, etiquette, { droit = true } = {}) {
  await ouvrir(acteur.page, CHEMIN);
  await acteur.page.waitForTimeout(3500);
  await activerSemantique(acteur.page);
  const phrase = await trouverTexte(acteur.page,
    new RegExp(`délai de rétractation est de ${jours}${espace}jours à compter du paiement`), 15000);
  p.dire(`[${etiquette}] delai ${jours} : ${phrase ?? 'absent'}`);
  if (!phrase) manque.push(`${etiquette} : « ${jours} jours à compter du paiement » absent`);
  await p.capture(acteur, `${etiquette}_delai_${jours}`);
  const tout = (await texteEntier(acteur.page)).toLowerCase();
  for (const interdit of ['première semaine', 'geste de la direction']) {
    if (tout.includes(interdit)) manque.push(`${etiquette} : « ${interdit} » encore lu`);
  }
  if (droit) {
    // La phrase du droit, amenee a l'ecran (pas le haut de la page).
    const noeud = await trouver(acteur.page, /arrêter une formule payée d'avance/, { delai: 8000 });
    if (noeud) await amenerEnVue(acteur.page, noeud);
    await acteur.page.waitForTimeout(800);
    await activerSemantique(acteur.page);
    const d = await trouverTexte(acteur.page, /arrêter une formule payée d'avance[^|]*reste un droit/, 8000);
    p.dire(`[${etiquette}] apres le delai : ${d ?? 'absent'}`);
    if (!d) manque.push(`${etiquette} : « reste un droit » absent`);
    await p.capture(acteur, `${etiquette}_apres_delai`);
  }
}

const avant = sql(`select public.tarifs_publics()#>>'{courante,remboursementDelaiJours}'`);
p.dire(`Politique du banc : delai ${avant} jours`);
try {
  // 1. La valeur d'aujourd'hui (7).
  if (regler(7) !== '7') manque.push('politique du banc non reglee a 7');
  const bureau = await p.contexte('visiteur', { vue: { width: 1440, height: 900 } });
  await verifier(bureau, 7, '1440_clair');
  const tel = await p.contexte('visiteur', { telephone: true, sombre: true });
  await verifier(tel, 7, '390_sombre');

  // 2. La decision (14) : le texte suit la politique, sans nouveau build. Un
  // onglet deja ouvert garde la valeur lue jusqu'a son rechargement : chaque
  // verification part d'un onglet neuf.
  if (regler(14) !== '14') manque.push('politique du banc non reglee a 14');
  const bureau14 = await p.contexte('visiteur', { vue: { width: 1440, height: 900 } });
  await verifier(bureau14, 14, '1440_clair', { droit: false });
  const bureauSombre = await p.contexte('visiteur', { vue: { width: 1440, height: 900 }, sombre: true });
  await verifier(bureauSombre, 14, '1440_sombre', { droit: false });
  const telClair = await p.contexte('visiteur', { telephone: true });
  await verifier(telClair, 14, '390_clair', { droit: false });

  // 3. L'arabe, a 390.
  const ar = await p.contexte('visiteur', { telephone: true, langue: 'ar-SA' });
  await ouvrir(ar.page, CHEMIN);
  await ar.page.waitForTimeout(3500);
  await activerSemantique(ar.page);
  const phraseAr = await trouverTexte(ar.page, /مهلة التراجع[\s⁨]*14/, 15000);
  p.dire(`[390_ar] delai 14 : ${phraseAr ?? 'absent'}`);
  if (!phraseAr) manque.push('arabe : « مهلة التراجع 14 » absent');
  const toutAr = await texteEntier(ar.page);
  if (toutAr.includes('الأسبوع الأول')) manque.push('arabe : « الأسبوع الأول » encore lu');
  await p.capture(ar, '390_ar_delai_14');
  for (const a of [bureau, tel, bureau14, bureauSombre, telClair, ar]) await a.ctx.close();
} finally {
  regler(Number(avant) || 7);
  p.dire(`Politique du banc remise a ${sql(`select public.tarifs_publics()#>>'{courante,remboursementDelaiJours}'`)} jours`);
}
process.exit(manque.length
  ? await p.fin('rouge', `manque : ${manque.join(' ; ')}`)
  : await p.fin('vert', 'le texte dit le delai de la politique (7, puis 14 sans nouveau build), en fr et en ar ; « premiere semaine » et « geste de la direction » absents'));
