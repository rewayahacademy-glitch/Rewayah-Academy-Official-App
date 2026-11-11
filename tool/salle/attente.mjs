// Banc de la salle : l'attente. L'enseignant seul dans sa salle (ordinateur),
// puis un eleve seul dans la sienne (telephone, clair et sombre) : la scene
// d'attente telle que la vraie application la rend.
//
// Usage : node tool/salle/attente.mjs [--dossier=attente]
import fs from 'node:fs';
import path from 'node:path';
import { participant, connecter, appuyer } from './banc.mjs';
import { amorcerClasse } from './amorce.mjs';
import { COMPTES, DEPOT, alleger } from '../e2e/commun.mjs';

const arg = (nom, defaut) => (process.argv.find((a) => a.startsWith(`--${nom}=`)) ?? `=${defaut}`).split('=')[1];
const SORTIE = path.join(DEPOT, 'docs/current/captures/E2E/salle-banc', arg('dossier', 'attente'));
fs.mkdirSync(SORTIE, { recursive: true });
const journal = [];
const dire = (m) => { console.log(m); journal.push(m); fs.writeFileSync(path.join(SORTIE, 'journal.txt'), `${journal.join('\n')}\n`); };
const ouverts = [];
try {
  const c = amorcerClasse({ n: 1, etiquette: `attente ${Date.now() % 100000}` });
  dire(`== Attente ; ${new Date().toISOString()} ; classe « ${c.nom} »`);
  // L'eleve seul, avant son enseignant : telephone clair, puis sombre.
  for (const [nom, options] of [['eleve-telephone-clair', { telephone: true }], ['eleve-telephone-sombre', { telephone: true, sombre: true }]]) {
    const p = await participant(nom, options);
    ouverts.push(p);
    await connecter(p, c.eleves[0].courriel);
    const entre = await appuyer(p, /^Rejoindre/, { delai: 25000, pause: 9000 });
    dire(`${nom} : entree ${entre} ; voit : ${(await p.lus(25)).slice(0, 500)}`);
    await p.page.screenshot({ path: path.join(SORTIE, `${nom}.png`) });
    await p.fermer(); ouverts.pop();
  }
  // L'enseignant seul, avant ses eleves : ordinateur.
  const ens = await participant('enseignant-ordinateur', {});
  ouverts.push(ens);
  await connecter(ens, COMPTES.enseignant);
  const entre = await appuyer(ens, /^Rejoindre la salle/, { delai: 25000, pause: 9000 });
  dire(`enseignant : entree ${entre} ; voit : ${(await ens.lus(25)).slice(0, 500)}`);
  await ens.page.screenshot({ path: path.join(SORTIE, 'enseignant-ordinateur.png') });
  dire('== fin sans erreur de script');
} catch (e) {
  dire(`ECHEC : ${String(e.message ?? e).slice(0, 600)}`);
} finally {
  for (const p of ouverts) await p.fermer().catch(() => {});
  alleger(SORTIE);
}
