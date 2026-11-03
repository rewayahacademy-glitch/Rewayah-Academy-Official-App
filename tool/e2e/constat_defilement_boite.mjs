// REJEU-E2E (03/11/2026), constat pour un autre lot, rien n'est corrige :
// « Ajouter un élève » (Opérations > Classes > Actions d'une classe) defile
// DANS la boite (AppBottomSheet : Flexible(SingleChildScrollView(corps))),
// ce qu'interdit DECISION-DEFILEMENT-2026-11-01 (regle 1).
//
// Pile LOCALE seulement. Captures a 390 et 1440 : la boite ouverte, puis
// apres un tour de molette DANS la boite ; le journal dit si la page derriere
// a bouge (elle ne doit pas) et si le contenu de la boite a bouge.
// Usage : CLASSE="<nom d'une classe active>" node tool/e2e/constat_defilement_boite.mjs
import { parcours, connecter, cliquer, libelles, activerSemantique, ouvrir, COMPTES } from './commun.mjs';

const classe = process.env.CLASSE;
const p = await parcours('Constat : Ajouter un élève defile dans la boite', 'rejeu-2026-11-03/constats/ajouter-un-eleve');
let code = 1;
try {
  for (const [w, h] of [[1440, 900], [390, 844]]) {
    const c = await p.contexte('direction', { vue: { width: w, height: h } });
    await connecter(c.page, COMPTES.direction);
    // Par l'adresse : au telephone, l'onglet de bureau n'existe pas.
    await ouvrir(c.page, '/#/admin/operations/groupes');
    await c.page.waitForTimeout(3000); await activerSemantique(c.page);
    const actives = c.page.getByRole('button', { name: /^Actives, / });
    if (await actives.count()) { await actives.first().click(); await c.page.waitForTimeout(1500); }
    await cliquer(c.page, new RegExp(`^Actions : ${classe}`));
    await cliquer(c.page, /^Ajouter un élève$/, { role: 'menuitem', pause: 2000 });
    await activerSemantique(c.page);
    const avant = (await libelles(c.page)).filter((x) => x.startsWith('radio:')).map((x) => x.slice(6, 30));
    await p.capture(c, `${w}_boite_ouverte`);
    // Molette au centre de la boite.
    await c.page.mouse.move(w / 2, h * 0.6);
    for (let i = 0; i < 4; i++) { await c.page.mouse.wheel(0, 400); await c.page.waitForTimeout(300); }
    await c.page.waitForTimeout(800);
    await activerSemantique(c.page);
    const apres = (await libelles(c.page)).filter((x) => x.startsWith('radio:')).map((x) => x.slice(6, 30));
    const titre = await c.page.getByRole('heading').first().boundingBox();
    await p.capture(c, `${w}_apres_molette_dans_la_boite`);
    p.dire(`${w} : radios visibles avant « ${avant.join(' / ')} » ; apres molette « ${apres.join(' / ')} » ; position du premier titre apres molette y=${Math.round(titre?.y ?? -1)}`);
    await c.ctx.close();
  }
  code = await p.fin('joué', 'constat : voir les captures avant et apres la molette');
} catch (e) {
  code = await p.fin('rouge', String(e).slice(0, 300));
}
process.exit(0);
