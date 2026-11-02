// FN-109 (pilote, 02/11/2026) : le detail d'une ligne de paie envoyait son
// identifiant compose (`<enseignant>_<mois>`) a `finance_validations_lister`,
// dont `p_objet` est un uuid : le serveur refusait (22P02) et le detail
// affichait « Nous n'avons pas pu lire l'etat de la demande de validation ».
//
// Ce que le parcours prouve, sur la pile LOCALE, a 1440 x 900 et 390 x 844 :
//   * le detail de la paie d'un enseignant du mois s'ouvre avec son montant ;
//   * aucune requete `finance_validations_lister` ne part avec un `p_objet`
//     qui n'est pas un uuid, et aucune n'est refusee ;
//   * le bandeau d'erreur du suivi de validation n'apparait pas.
// Donnees : les seances deja tenues sur la pile ; rien n'est ecrit.
// Usage : node tool/e2e/fn109_paie.mjs
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, ouvrir, activerSemantique, trouverTexte, sql, DEPOT, COMPTES } from './commun.mjs';

const p = await parcours('FN-109 : detail de la paie sans uuid compose', 'fn109-paie');
let code = 1;
const FR = JSON.parse(fs.readFileSync(path.join(DEPOT, 'assets/i18n/fr.i18n.json'), 'utf8'));
const ERREUR = FR.comptable.validation.erreurSuivi;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
try {
  const ligne = sql(`select r.enseignant || '|' || to_char(date_trunc('month', now()), 'YYYY-MM-DD')
    from private.pai_releve_seances(date_trunc('month', now())::date,
      (date_trunc('month', now()) + interval '1 month')::date) r
    where r.devise is not null limit 1`).split('\n')[0];
  if (!ligne) throw new Error('aucune seance payee ce mois sur la pile');
  const [enseignant, mois] = ligne.split('|');
  const id = `${enseignant}_${mois}`;
  p.dire(`Ligne de paie : ${id}`);
  const verdicts = {};
  for (const [largeur, hauteur] of [[390, 844], [1440, 900]]) {
    const v = { lectures: 0, objetsNonUuid: [], refus: [] };
    const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
    c.page.on('request', (r) => {
      if (!r.url().includes('/rpc/finance_validations_lister')) return;
      v.lectures += 1;
      const objet = JSON.parse(r.postData() || '{}').p_objet;
      if (objet != null && !UUID.test(objet)) v.objetsNonUuid.push(objet);
    });
    c.page.on('response', (r) => {
      if (r.url().includes('/rpc/finance_validations_lister') && r.status() >= 400) v.refus.push(r.status());
    });
    await connecter(c.page, COMPTES.direction);
    await ouvrir(c.page, `/#/admin/finance/paie/obligation/${id}`);
    await c.page.waitForTimeout(4000); await activerSemantique(c.page);
    v.montant = Boolean(await trouverTexte(c.page, /Total à payer/, 15000));
    await p.capture(c, `${largeur}_1_detail`);
    await c.page.mouse.wheel(0, 4000); await c.page.waitForTimeout(1500);
    await p.capture(c, `${largeur}_2_bas`);
    v.bandeauErreur = Boolean(await trouverTexte(c.page, ERREUR.slice(0, 40), 3000));
    p.dire(`${largeur} : ${JSON.stringify(v)}`);
    verdicts[largeur] = v;
    await c.ctx.close();
  }
  const rouges = Object.entries(verdicts).filter(([, v]) =>
    !v.montant || v.bandeauErreur || v.objetsNonUuid.length || v.refus.length).map(([k]) => k);
  if (rouges.length) throw new Error(`rouge a ${rouges.join(', ')} : ${JSON.stringify(verdicts)}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
