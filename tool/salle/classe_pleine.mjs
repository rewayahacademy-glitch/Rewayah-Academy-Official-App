// Banc de la salle : une classe pleine. Un enseignant et 12 eleves dans la meme
// salle, toutes les cameras allumees : ce que le directeur n'a jamais pu
// essayer (cahier de la salle §4). L'enseignant et trois eleves (telephone,
// tablette, ordinateur en theme sombre) utilisent la VRAIE application ; les
// neuf autres sont des robots legers (tool/salle/robots.mjs).
//
// Le script ne juge pas a la place d'un humain : il capture chaque ecran, note
// ce que chacun voit (libelles), ce que chacun recoit (flux video, images par
// seconde) et la fluidite de la page, dans un journal.
//
// Usage : node tool/salle/classe_pleine.mjs [--eleves=12] [--dossier=classe-pleine]
import fs from 'node:fs';
import path from 'node:path';
import { participant, connecter, appuyer } from './banc.mjs';
import { amorcerClasse } from './amorce.mjs';
import { robots } from './robots.mjs';
import { COMPTES, DEPOT, alleger, libelles } from '../e2e/commun.mjs';

const arg = (nom, defaut) => (process.argv.find((a) => a.startsWith(`--${nom}=`)) ?? `=${defaut}`).split('=')[1];
const N = Number(arg('eleves', '12'));
const SORTIE = path.join(DEPOT, 'docs/current/captures/E2E/salle-banc', arg('dossier', 'classe-pleine'));
fs.mkdirSync(SORTIE, { recursive: true });
for (const f of fs.readdirSync(SORTIE)) if (/\.png$|^journal\.txt$/.test(f)) fs.rmSync(path.join(SORTIE, f));
const journal = [];
const dire = (m) => { console.log(m); journal.push(m); fs.writeFileSync(path.join(SORTIE, 'journal.txt'), `${journal.join('\n')}\n`); };
let n = 0;
const capture = async (p, etiquette) => {
  n += 1;
  await p.page.screenshot({ path: path.join(SORTIE, `${String(n).padStart(2, '0')}_${p.nom}_${etiquette}.png`) });
};

/// Ce que la page recoit et sa fluidite : flux video recus (taille, images par
/// seconde), et images dessinees par seconde par l'application sur 4 s.
async function mesurer(p) {
  const s = await p.stats();
  const videos = s.recu.filter((x) => x.genre === 'video' && (x.images ?? 0) > 0);
  const fluidite = await p.page.evaluate(() => new Promise((fini) => {
    let k = 0; const t0 = performance.now();
    const tour = () => { k += 1; if (performance.now() - t0 < 4000) requestAnimationFrame(tour); else fini(Math.round(k / 4)); };
    requestAnimationFrame(tour);
  }));
  return { videosRecues: videos.length, tailles: videos.map((v) => `${v.largeur}x${v.hauteur}@${Math.round(v.ips ?? 0)}`).join(' '),
    audiosRecus: s.recu.filter((x) => x.genre === 'audio').length, imagesParSeconde: fluidite };
}

const c = amorcerClasse({ n: N, etiquette: `classe pleine ${Date.now() % 100000}` });
dire(`== Classe pleine : ${N} eleves ; ${new Date().toISOString()} ; classe « ${c.nom} »`);
const ouverts = [];
let bots = null;
try {
  const ens = await participant('enseignant', {});
  ouverts.push(ens);
  await connecter(ens, COMPTES.enseignant);
  if (!(await appuyer(ens, /^Rejoindre la salle/, { delai: 25000, pause: 9000 }))) throw new Error(`enseignant : pas de « Rejoindre la salle » ; ${await ens.lus(20)}`);
  dire(`enseignant, micro : ${await appuyer(ens, /^Ouvrir le micro/, { pause: 2500 })} ; camera : ${await appuyer(ens, /^Allumer la caméra/, { pause: 3500 })}`);
  await capture(ens, 'seul');

  // Les trois eleves sur la vraie application.
  const vrais = [
    { nom: 'eleve-telephone', options: { telephone: true } },
    { nom: 'eleve-tablette', options: { vue: { width: 820, height: 1180 } } },
    { nom: 'eleve-ordinateur-sombre', options: { vue: { width: 1280, height: 800 }, sombre: true } },
  ].slice(0, Math.min(3, N));
  for (const [i, v] of vrais.entries()) {
    const p = await participant(v.nom, v.options);
    ouverts.push(p);
    await connecter(p, c.eleves[i].courriel);
    if (!(await appuyer(p, /^Rejoindre/, { delai: 25000, pause: 9000 }))) { dire(`${v.nom} : pas de « Rejoindre » ; ${await p.lus(20)}`); continue; }
    dire(`${v.nom} (${c.eleves[i].prenom}), camera : ${await appuyer(p, /^Allumer la caméra/, { delai: 5000, pause: 3000 })} ; micro : ${await appuyer(p, /^Ouvrir le micro/, { delai: 5000, pause: 1500 })}`);
  }

  // Les autres : des robots, camera allumee, micro ferme.
  bots = await robots(c.eleves.slice(vrais.length), c.seance, { camera: true, micro: false });
  for (const b of bots.pages) dire(`robot ${b.eleve.prenom} : pistes ${b.etat.pistes.join('+') || 'aucune'}${b.etat.camera ? ` ; camera refusee : ${b.etat.camera}` : ''}`);
  await ens.page.waitForTimeout(15000);

  for (const p of ouverts) {
    await capture(p, 'classe-pleine');
    dire(`${p.nom} : ${JSON.stringify(await mesurer(p))}`);
    dire(`${p.nom} voit : ${(await libelles(p.page)).slice(0, 70).join(' | ').slice(0, 1800)}`);
    if (p.journal.length) dire(`${p.nom}, erreurs de page : ${p.journal.slice(0, 6).join(' ; ')}`);
  }

  // L'enseignant ouvre le panneau des eleves, puis le Coran.
  const elevesBouton = await appuyer(ens, /^Élèves/, { delai: 4000, pause: 2500 });
  dire(`enseignant, « Élèves » : ${elevesBouton}`);
  await capture(ens, 'panneau-eleves');
  const coran = await appuyer(ens, /^Ouvrir le Coran$/, { delai: 4000, pause: 5000 })
    ?? await appuyer(ens, /^Coran, Mushaf de Médine/, { delai: 4000, pause: 5000 });
  dire(`enseignant, Coran : ${coran}`);
  const presenter = await appuyer(ens, /^Présenter/, { delai: 5000, pause: 5000 });
  dire(`enseignant, « Présenter » : ${presenter}`);
  await ens.page.waitForTimeout(5000);
  for (const p of ouverts) {
    await capture(p, 'page-partagee');
    dire(`${p.nom}, page partagee : ${JSON.stringify(await mesurer(p))}`);
  }
  dire('== fin sans erreur de script');
} catch (e) {
  dire(`ECHEC : ${String(e.message ?? e).slice(0, 600)}`);
} finally {
  for (const p of ouverts) await p.fermer().catch(() => {});
  if (bots) await bots.fermer().catch(() => {});
  alleger(SORTIE);
}
