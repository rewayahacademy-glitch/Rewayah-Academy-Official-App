// Parcours 6, piege 6.2 rejoue sur le cahier de la classe d'adultes : la position choisie,
// puis « Retour » avant de valider, puis reouverture. Le cahier n'a pas de champ libre.
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, trouverTexte, activerSemantique, COMPTES, TRAVAIL } from './commun.mjs';
const classe = JSON.parse(fs.readFileSync(path.join(TRAVAIL, 'classe_adultes.json'), 'utf8'));
const p = await parcours('Parcours 6 : piege 6.2 (adultes)', 'parcours-6/pieges-adultes');
const e = await p.contexte('enseignant');
await connecter(e.page, COMPTES.enseignant);
const re = new RegExp(`^(Obligatoire : le )?[Cc]ahier de transmission d'${classe.nom}`);
const ouvrir = async () => { const l = await trouver(e.page, re, { delai: 8000 }); if (!l) throw new Error('cahier des adultes introuvable'); await l.click(); await e.page.waitForTimeout(3000); await activerSemantique(e.page); };
await ouvrir();
await p.capture(e, 'cahier_adultes');
await cliquer(e.page, /^(Où la Classe s'est arrêtée|Choisir la sourate)/, { pause: 2500 });
await cliquer(e.page, /^109\. Al-Kaafiroon/, { role: 'radio', pause: 1500 });
await cliquer(e.page, /^6$/, { role: 'button', pause: 800 });
await cliquer(e.page, /^Retenir cette position$/, { pause: 2500 });
await p.capture(e, 'position_choisie');
await cliquer(e.page, /^Retour$/, { role: 'button', pause: 2500 });
await activerSemantique(e.page);
await p.capture(e, 'apres_retour');
const avert = await trouverTexte(e.page, /(perdu|abandonner|enregistr|brouillon|Quitter)[^|]*/i, 2000);
const rester = await trouver(e.page, /^(Rester|Annuler|Continuer)/, { delai: 1000, role: 'button' });
if (rester) { await rester.click(); await e.page.waitForTimeout(1500); } else await ouvrir();
await activerSemantique(e.page);
const garde = await trouverTexte(e.page, /Al-Kaafiroon[^|]*/, 3000);
await p.capture(e, 'reouvert');
p.dire(`[6.2] ${avert ? `avertissement « ${avert} »` : 'aucun avertissement au Retour'} ; position retrouvee a la reouverture : ${garde ? `« ${garde} »` : 'non'}`);
// Valider pour de bon.
if (!garde) { await cliquer(e.page, /^(Où la Classe s'est arrêtée|Choisir la sourate)/, { pause: 2500 }); await cliquer(e.page, /^109\. Al-Kaafiroon/, { role: 'radio', pause: 1500 }); await cliquer(e.page, /^6$/, { role: 'button', pause: 800 }); await cliquer(e.page, /^Retenir cette position$/, { pause: 2500 }); }
await cliquer(e.page, /^Valider le cahier de transmission/, { role: 'button', pause: 3000 });
const c = await trouver(e.page, /^(Valider|Confirmer)/, { delai: 1500, role: 'button' }); if (c) { await c.click(); await e.page.waitForTimeout(3000); }
await activerSemantique(e.page);
await p.capture(e, 'valide');
p.dire(`Cahier des adultes : ${await trouverTexte(e.page, /Cahier de transmission enregistré[^|]*/, 3000) ?? 'pas de confirmation'}`);
await p.fin('joué');
