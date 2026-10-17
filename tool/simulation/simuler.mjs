// Rapport complet du modèle économique, en Markdown.
//
//   node tool/simulation/simuler.mjs                     # 216 scénarios × 300 tirages × 12 mois
//   node tool/simulation/simuler.mjs --tirages 100       # plus rapide
//   node tool/simulation/simuler.mjs --sortie rapport.md # écrit dans un fichier
//   node tool/simulation/simuler.mjs --json              # résultats bruts

import { writeFileSync } from 'node:fs';
import { DIMENSIONS, PARAMETRES_DEFAUT, grilleScenarios, parametresScenario, simuler, fusionner } from './modele_academie.mjs';

const args = process.argv.slice(2);
const valeur = (nom) => {
  const i = args.indexOf(nom);
  return i === -1 ? undefined : args[i + 1];
};
const tirages = Number(valeur('--tirages') ?? 300);
const surcharges = { tirages };
if (valeur('--graine')) surcharges.graine = Number(valeur('--graine'));

// --- Calculs ----------------------------------------------------------------

const resume = (r) => ({
  encaisse: r.moisType.encaisse.p50,
  encaisseP10: r.moisType.encaisse.p10,
  resultat: r.moisType.resultat.p50,
  resultatP10: r.moisType.resultat.p10,
  resultatPlafond: r.moisType.resultatAuPlafond.p50,
  objectif: r.moisType.objectifAtteint,
  taux30: r.tauxEnseignantMax.find((x) => x.marge === 0.3).prudent,
  fraisCarte: r.moisType.fraisCarte.p50,
  livekit: r.moisType.livekit.p50,
  groupes: r.population.groupes.length,
  enseignants: r.population.enseignants.length,
  enAttente: r.population.enAttente,
});

const grille = grilleScenarios(surcharges).map(({ choix, parametres }) => ({ choix, ...resume(simuler(parametres)) }));

const PRIX_ENFANT = [40, 45, 50, 55, 60];
const PRIX_ADULTE = [50, 55, 60, 65, 70];
const prix = PRIX_ENFANT.map((enfant) => PRIX_ADULTE.map((adulte) => resume(simuler(
  fusionner(parametresScenario('realiste', surcharges), {
    tarifs: { enfantCentimes: enfant * 100, adulteCentimes: adulte * 100 },
  }),
))));

if (args.includes('--json')) {
  console.log(JSON.stringify({ grille, prix: { PRIX_ENFANT, PRIX_ADULTE, prix } }, null, 2));
  process.exit(0);
}

// --- Mise en forme ------------------------------------------------------------

const usd = (c) => `${(Math.round(c / 100) || 0).toLocaleString('fr-FR')} $`;
const usd2 = (c) => `${(c / 100).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} $`;
const pct = (x) => `${Math.round(x * 100)} %`;
const ligne = (cellules) => `| ${cellules.join(' | ')} |`;
const titre = (dimension, v) => (dimension === 'paiement' ? DIMENSIONS.paiement[v].titre : DIMENSIONS[dimension][v].titre);
const libelle = (choix) => Object.entries(choix).map(([d, v]) => titre(d, v)).join(' · ');
const moyenne = (xs) => xs.reduce((s, x) => s + x, 0) / Math.max(1, xs.length);
const tri = (xs) => [...xs].sort((a, b) => a - b);
const quantile = (xs, q) => tri(xs)[Math.round(q * (xs.length - 1))];
const p = PARAMETRES_DEFAUT;
const objectif = usd(p.objectifs.resultatNetCentimes);
const taux = usd2(p.enseignants.tauxReferenceCentimes);
const plafond = usd2(p.enseignants.plafondCentimes);

const sortie = [];
const ecrire = (...x) => sortie.push(...x);

ecrire(
  `# Simulation économique — ${grille.length} scénarios`,
  '',
  `${grille.length} combinaisons × ${tirages} tirages × ${p.mois} mois, graine ${p.graine}. ` +
    `Chiffres d'un mois type (mois ${p.premierMoisStable} à ${p.mois}, médiane). ` +
    `Enseignants payés ${taux} / h (taux de référence) ; objectif ${objectif} net par mois.`,
  '',
  '## Vue d’ensemble',
  '',
  ligne(['', 'Pire scénario', '1 sur 10', 'Médian', '9 sur 10', 'Meilleur']),
  ligne(['---', '---:', '---:', '---:', '---:', '---:']),
);
const etendue = (libelleLigne, cle, f) => {
  const xs = grille.map((x) => x[cle]);
  ecrire(ligne([libelleLigne, ...[0, 0.1, 0.5, 0.9, 1].map((q) => f(quantile(xs, q)))]));
};
etendue('Encaissé par mois', 'encaisse', usd);
etendue(`Résultat à ${taux} / h`, 'resultat', usd);
etendue(`Résultat au plafond ${plafond} / h`, 'resultatPlafond', usd);
etendue(`Mois où l'objectif ${objectif} est atteint`, 'objectif', pct);
etendue('Taux max pour 30 % de marge (9 mois sur 10)', 'taux30', usd2);
etendue('Élèves sans classe', 'enAttente', (x) => `${x}`);
etendue('Classes', 'groupes', (x) => `${x}`);
etendue('Enseignants', 'enseignants', (x) => `${x}`);

ecrire(
  '',
  `L'objectif de ${objectif} est atteint dans au moins 9 mois sur 10 pour ` +
    `${grille.filter((x) => x.objectif >= 0.9).length} scénarios sur ${grille.length}.`,
  '',
  '## Ce que change chaque choix',
  '',
  'Moyenne sur tous les scénarios qui partagent ce choix.',
  '',
  ligne(['Dimension', 'Choix', 'Encaissé', `Résultat à ${taux} / h`, 'Objectif atteint', 'Taux max 30 %', 'Sans classe', 'Classes']),
  ligne(['---', '---', '---:', '---:', '---:', '---:', '---:', '---:']),
);
for (const [dimension, valeurs] of Object.entries(DIMENSIONS)) {
  for (const v of Object.keys(valeurs)) {
    const xs = grille.filter((x) => x.choix[dimension] === v);
    ecrire(ligne([
      dimension, titre(dimension, v),
      usd(moyenne(xs.map((x) => x.encaisse))), usd(moyenne(xs.map((x) => x.resultat))),
      pct(moyenne(xs.map((x) => x.objectif))), usd2(moyenne(xs.map((x) => x.taux30))),
      moyenne(xs.map((x) => x.enAttente)).toFixed(1), moyenne(xs.map((x) => x.groupes)).toFixed(1),
    ]));
  }
}

const classement = [...grille].sort((a, b) => a.resultat - b.resultat);
const tableau = (liste) => [
  ligne(['Scénario', 'Encaissé', `Résultat à ${taux} / h`, '1 mois sur 10 sous', 'Objectif', 'Taux max 30 %', 'Sans classe']),
  ligne(['---', '---:', '---:', '---:', '---:', '---:', '---:']),
  ...liste.map((x) => ligne([
    libelle(x.choix), usd(x.encaisse), usd(x.resultat), usd(x.resultatP10), pct(x.objectif), usd2(x.taux30), x.enAttente,
  ])),
];
ecrire('', '## Les 10 pires scénarios', '', ...tableau(classement.slice(0, 10)));
ecrire('', '## Les 10 meilleurs scénarios', '', ...tableau(classement.slice(-10).reverse()));

ecrire(
  '',
  '## Quel prix fixer',
  '',
  `Comportement réaliste, adultes séparés, enfants mixtes, 50 % Europe / 50 % Amérique du Nord, 45 % d'enfants. ` +
    `Chaque case : résultat médian à ${taux} / h, puis part des mois qui atteignent ${objectif}.`,
  '',
  ligne(['Enfant ↓ / Adulte →', ...PRIX_ADULTE.map((a) => `${a} $`)]),
  ligne(['---', ...PRIX_ADULTE.map(() => '---:')]),
  ...PRIX_ENFANT.map((e, i) => ligne([`**${e} $**`, ...prix[i].map((x) => `${usd(x.resultat)} · ${pct(x.objectif)}`)])),
  '',
  'Taux enseignant maximal tenant 30 % de marge 9 mois sur 10, selon le prix :',
  '',
  ligne(['Enfant ↓ / Adulte →', ...PRIX_ADULTE.map((a) => `${a} $`)]),
  ligne(['---', ...PRIX_ADULTE.map(() => '---:')]),
  ...PRIX_ENFANT.map((e, i) => ligne([`**${e} $**`, ...prix[i].map((x) => usd2(x.taux30))])),
  '',
  `## Les ${grille.length} scénarios`,
  '',
  ...tableau([...grille].sort((a, b) => b.resultat - a.resultat)),
);

const texte = sortie.join('\n') + '\n';
if (valeur('--sortie')) writeFileSync(valeur('--sortie'), texte);
else process.stdout.write(texte);
