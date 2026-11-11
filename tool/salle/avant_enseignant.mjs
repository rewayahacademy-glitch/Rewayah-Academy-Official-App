// Banc de la salle : l'eleve entre avant son enseignant, dans la VRAIE
// application (MICRO-AVANT-ENSEIGNANT, ILE-SALLE, ATTENTE-SALLE).
//
//  1. l'eleve (telephone) entre seul : pas de bouton micro, une phrase le dit ;
//  2. l'enseignant entre : le bouton micro apparait chez l'eleve, micro ferme ;
//  3. l'eleve ouvre son micro : l'enseignant recoit sa voix ;
//  4. l'enseignant presente une page du Coran : l'ile de l'eleve, d'abord
//     depliee, se replie (chrono et cercle seuls).
//
// Usage : node tool/salle/avant_enseignant.mjs [--dossier=avant-enseignant]
import fs from 'node:fs';
import path from 'node:path';
import { participant, connecter, appuyer } from './banc.mjs';
import { amorcerClasse } from './amorce.mjs';
import { COMPTES, DEPOT, alleger, libelles } from '../e2e/commun.mjs';

const arg = (nom, defaut) => (process.argv.find((a) => a.startsWith(`--${nom}=`)) ?? `=${defaut}`).split('=')[1];
const SORTIE = path.join(DEPOT, 'docs/current/captures/E2E/salle-banc', arg('dossier', 'avant-enseignant'));
fs.mkdirSync(SORTIE, { recursive: true });
for (const f of fs.readdirSync(SORTIE)) if (/\.png$|^journal\.txt$/.test(f)) fs.rmSync(path.join(SORTIE, f));
const journal = [];
const dire = (m) => { console.log(m); journal.push(m); fs.writeFileSync(path.join(SORTIE, 'journal.txt'), `${journal.join('\n')}\n`); };
let n = 0;
const capture = async (p, etiquette) => {
  n += 1;
  await p.page.screenshot({ path: path.join(SORTIE, `${String(n).padStart(2, '0')}_${p.nom}_${etiquette}.png`) });
};
const micro = async (p) => (await libelles(p.page)).filter((l) => /micro/i.test(l)).slice(0, 4);
const octetsAudioRecus = async (p) => (await p.stats()).recu.filter((x) => x.genre === 'audio').reduce((s, x) => s + (x.octets ?? 0), 0);
const ouverts = [];
let echecs = 0;
const verifier = (nom, vrai, detail = '') => { if (!vrai) echecs += 1; dire(`${vrai ? 'OK   ' : 'ECHEC'} ${nom}${detail ? ` : ${detail}` : ''}`); };
try {
  const c = amorcerClasse({ n: 1, etiquette: `avant enseignant ${Date.now() % 100000}` });
  dire(`== L'eleve avant son enseignant ; ${new Date().toISOString()} ; classe « ${c.nom} »`);
  const eleve = await participant('eleve-telephone', { telephone: true });
  ouverts.push(eleve);
  await connecter(eleve, c.eleves[0].courriel);
  if (!(await appuyer(eleve, /^Rejoindre/, { delai: 25000, pause: 9000 }))) throw new Error(`eleve : pas de « Rejoindre » ; ${await eleve.lus(20)}`);
  await eleve.page.waitForTimeout(3000);
  let m = await micro(eleve);
  verifier('1. eleve seul : aucun bouton pour ouvrir le micro', !m.some((l) => /^button:.*(Ouvrir|Fermer) le micro/.test(l)), JSON.stringify(m));
  verifier('1. eleve seul : une phrase dit que le micro attend l\'enseignant', m.some((l) => /micro (s'ouvrira|attend)/i.test(l)), JSON.stringify(m));
  await capture(eleve, 'seul-avant-enseignant');

  const ens = await participant('enseignant', {});
  ouverts.push(ens);
  await connecter(ens, COMPTES.enseignant);
  if (!(await appuyer(ens, /^Rejoindre la salle/, { delai: 25000, pause: 9000 }))) throw new Error(`enseignant : pas de « Rejoindre la salle » ; ${await ens.lus(20)}`);
  await eleve.page.waitForTimeout(4000);
  m = await micro(eleve);
  verifier('2. enseignant entre : le bouton micro apparait chez l\'eleve, micro ferme', m.some((l) => /^button:.*Ouvrir le micro/.test(l)), JSON.stringify(m));
  await capture(eleve, 'enseignant-entre');

  const avant = await octetsAudioRecus(ens);
  const appui = await appuyer(eleve, /^Ouvrir le micro/, { delai: 8000, pause: 6000 });
  const apres = await octetsAudioRecus(ens);
  verifier('3. l\'eleve ouvre son micro, l\'enseignant recoit sa voix', Boolean(appui) && apres - avant > 3000, `octets recus par l'enseignant : ${apres - avant}`);
  await capture(eleve, 'micro-ouvert');

  dire(`enseignant, micro : ${await appuyer(ens, /^Ouvrir le micro/, { pause: 2000 })}`);
  const coran = await appuyer(ens, /^Ouvrir le Coran$/, { delai: 4000, pause: 5000 })
    ?? await appuyer(ens, /^Coran, Mushaf de Médine/, { delai: 4000, pause: 5000 });
  dire(`enseignant, Coran : ${coran} ; « Présenter » : ${await appuyer(ens, /^Présenter/, { delai: 5000, pause: 4000 })}`);
  await capture(eleve, 'page-ile-apres-4s');
  await capture(ens, 'page-partagee');
  await eleve.page.waitForTimeout(14000);
  await capture(eleve, 'page-ile-repliee');
  dire(`eleve, apres 18 s, voit : ${(await eleve.lus(30)).slice(0, 700)}`);
  if (eleve.journal.length) dire(`eleve, erreurs de page : ${eleve.journal.slice(-4).join(' ; ').slice(0, 600)}`);
  dire(echecs === 0 ? '== fin : tout est verifie' : `== fin : ${echecs} ECHEC(S)`);
} catch (e) {
  dire(`ECHEC : ${String(e.message ?? e).slice(0, 600)}`);
} finally {
  for (const p of ouverts) await p.fermer().catch(() => {});
  alleger(SORTIE);
}
