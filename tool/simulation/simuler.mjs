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
  impot: r.moisType.impot.p50,
  resultat: r.moisType.resultat.p50,
  resultatP10: r.moisType.resultat.p10,
  resultatPlafond: r.moisType.resultatAuPlafond.p50,
  objectif: r.moisType.objectifAtteint,
  rentable: r.moisType.rentable,
  tauxRentable: r.tauxEnseignantMax.rentable.prudent,
  tauxObjectif: r.tauxEnseignantMax.objectif.prudent,
  taux30: r.tauxEnseignantMax.marges.find((x) => x.marge === 0.3).prudent,
  // Prudent : tenu 9 mois sur 10.
  perdableRentable: r.margeDeManoeuvre.rentable.encaissementPerdable.prudent,
  enfantsRentable: r.margeDeManoeuvre.rentable.enfants.prudent,
  adultesRentable: r.margeDeManoeuvre.rentable.adultes.prudent,
  remiseRentable: r.margeDeManoeuvre.rentable.remiseMaxBps.prudent,
  perdableObjectif: r.margeDeManoeuvre.objectif.encaissementPerdable.prudent,
  remiseObjectif: r.margeDeManoeuvre.objectif.remiseMaxBps.prudent,
  reporte: r.moisType.reporte.p50,
  elevesActifs: r.moisType.elevesActifs.p50,
  departs: r.moisType.departs.p50,
  changements: r.moisType.changements.p50,
  refus: r.moisType.changementsRefuses.p50,
  heuresAdmin: r.moisType.heuresAdministration.p50,
  groupes: r.population.groupes.length,
  enseignants: r.population.enseignants.length,
  enAttente: r.population.enAttente,
});

const reference = (sur = {}) => resume(simuler(fusionner(parametresScenario('realiste', surcharges), sur)));

const grille = grilleScenarios(surcharges).map(({ choix, parametres }) => ({ choix, ...resume(simuler(parametres)) }));

const PRIX_ENFANT = [40, 45, 50, 55, 60];
const PRIX_ADULTE = [50, 55, 60, 65, 70];
const prix = PRIX_ENFANT.map((enfant) => PRIX_ADULTE.map((adulte) => reference({
  tarifs: { enfantCentimes: enfant * 100, adulteCentimes: adulte * 100 },
})));

// « Et si… » : un seul levier bouge, le reste suit le scénario de référence.
// Chaque mois, une part des familles ne paie pas et une autre paie le mois
// suivant ; personne n'est suspendu, pour lire l'effet du seul impayé.
const profilsPurs = (jamais, retard) => ({
  comportements: {
    paiement: {
      avance: { poids: 0 }, ponctuel: { poids: 1, dansLeMois: 1 - jamais - retard, moisSuivant: retard, impaye: jamais },
      retardLeger: { poids: 0 }, retardLourd: { poids: 0 }, defaillant: { poids: 0 },
    },
    moisImpayesAvantSuspension: 1000,
  },
});
const NE_PAIENT_JAMAIS = [0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.5];
const EN_RETARD = [0, 0.2, 0.4, 0.6];
const paiements = NE_PAIENT_JAMAIS.map((j) => EN_RETARD.map((t) => (j + t > 1 ? null : reference(profilsPurs(j, t)))));

const PERTES = [0, 5, 10, 15, 20, 30];
const pertes = ['enfants', 'adultes'].flatMap((type) => [false, true].map((regrouper) => ({
  type, regrouper,
  lignes: PERTES.map((n) => ({ n, ...reference({ pertes: { [type]: n, regrouper } }) })),
})));

const INSTABILITE = [
  { titre: 'Calme', detail: 'départs ÷ 2, 1 % demandent à changer, place reprise en 1 mois', c: { multiplicateurDeparts: 0.5, changementMensuel: 0.01, delaiRemplacementMois: 1 } },
  { titre: 'Normal (référence)', detail: 'départs du scénario, 2 % demandent à changer, 1 mois', c: {} },
  { titre: 'Agité', detail: 'départs × 2, 6 % demandent à changer, 1 mois', c: { multiplicateurDeparts: 2, changementMensuel: 0.06 } },
  { titre: 'Très agité', detail: 'départs × 3, 10 % demandent à changer, place reprise en 2 mois', c: { multiplicateurDeparts: 3, changementMensuel: 0.1, delaiRemplacementMois: 2 } },
  { titre: 'Personne ne remplace', detail: 'départs du scénario, aucune nouvelle inscription', c: { delaiRemplacementMois: null } },
];
const instabilite = INSTABILITE.map((x) => ({ ...x, ...reference({ comportements: x.c }) }));

if (args.includes('--json')) {
  console.log(JSON.stringify({ grille, prix: { PRIX_ENFANT, PRIX_ADULTE, prix }, paiements, pertes, instabilite }, null, 2));
  process.exit(0);
}

// --- Mise en forme ------------------------------------------------------------

const usd = (c) => `${(Math.round(c / 100) || 0).toLocaleString('fr-FR')} $`;
const usd2 = (c) => `${(c / 100).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} $`;
const pct = (x) => `${Math.round(x * 100)} %`;
const bps = (x) => `${Math.round(x / 100)} %`;
const signe = (c) => (c < 0 ? `manque ${usd(-c)}` : usd(c));
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
const admin = `${p.administration.effectif} × ${usd(p.administration.salaireMensuelCentimes)}`;

const sortie = [];
const ecrire = (...x) => sortie.push(...x);

ecrire(
  `# Simulation économique — ${grille.length} scénarios`,
  '',
  `${grille.length} combinaisons × ${tirages} tirages × ${p.mois} mois, graine ${p.graine}, modèle v2. ` +
    `Chiffres d'un mois type (mois ${p.premierMoisStable} à ${p.mois}, médiane). ` +
    `Enseignants payés ${taux} / h, administration ${admin}, impôt britannique sur les sociétés sur le bénéfice, ` +
    `cartes Stripe Royaume-Uni. Objectif ${objectif} net par mois après tout cela.`,
  '',
  '« Prudent » veut dire tenu 9 mois sur 10 : un mois sur 10 seulement fait moins bien.',
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
etendue('Impôt sur les sociétés', 'impot', usd);
etendue(`Net à ${taux} / h`, 'resultat', usd);
etendue(`Net au plafond ${plafond} / h`, 'resultatPlafond', usd);
etendue(`Mois où l'objectif ${objectif} est atteint`, 'objectif', pct);
etendue('Mois sans perte', 'rentable', pct);
etendue('Taux max pour ne pas perdre d’argent (prudent)', 'tauxRentable', usd2);
etendue(`Taux max pour garder ${objectif} (prudent)`, 'tauxObjectif', usd2);
etendue('Taux max pour 30 % de marge (prudent)', 'taux30', usd2);
etendue('Encaissement qu’on peut perdre sans perte (prudent)', 'perdableRentable', usd);
etendue('Remise max sur tous, sans perte (prudent)', 'remiseRentable', bps);
etendue('Élèves sans classe', 'enAttente', (x) => `${x}`);
etendue('Classes', 'groupes', (x) => `${x}`);

ecrire(
  '',
  `L'objectif de ${objectif} net est atteint dans au moins 9 mois sur 10 pour ` +
    `${grille.filter((x) => x.objectif >= 0.9).length} scénarios sur ${grille.length}. ` +
    `L'académie ne perd pas d'argent 9 mois sur 10 dans ${grille.filter((x) => x.rentable >= 0.9).length} scénarios sur ${grille.length}.`,
  '',
  '## Ce que change chaque choix',
  '',
  'Moyenne sur tous les scénarios qui partagent ce choix.',
  '',
  ligne(['Dimension', 'Choix', 'Encaissé', `Net à ${taux} / h`, 'Objectif atteint', 'Taux max sans perte', 'Sans classe', 'Classes']),
  ligne(['---', '---', '---:', '---:', '---:', '---:', '---:', '---:']),
);
for (const [dimension, valeurs] of Object.entries(DIMENSIONS)) {
  for (const v of Object.keys(valeurs)) {
    const xs = grille.filter((x) => x.choix[dimension] === v);
    ecrire(ligne([
      dimension, titre(dimension, v),
      usd(moyenne(xs.map((x) => x.encaisse))), usd(moyenne(xs.map((x) => x.resultat))),
      pct(moyenne(xs.map((x) => x.objectif))), usd2(moyenne(xs.map((x) => x.tauxRentable))),
      moyenne(xs.map((x) => x.enAttente)).toFixed(1), moyenne(xs.map((x) => x.groupes)).toFixed(1),
    ]));
  }
}

// --- Et si… -----------------------------------------------------------------

const ref = 'Scénario de référence : comportement réaliste, adultes séparés, enfants mixtes, 50 % Europe / 50 % Amérique du Nord, 45 % d’enfants, ' +
  `enseignants à ${taux} / h. Un seul levier bouge à la fois.`;

ecrire(
  '',
  '## Et si des familles ne paient pas ?',
  '',
  ref,
  '',
  'Chaque mois, une part des familles ne paie pas du tout et une autre paie avec un mois de retard. Elles restent inscrites. ' +
    'Chaque case : net par mois, puis l’argent qui manque en caisse à la fin du mois à cause des retards (il arrive le mois suivant).',
  '',
  ligne(['Ne paient pas ↓ / En retard d’un mois →', ...EN_RETARD.map((t) => pct(t))]),
  ligne(['---', ...EN_RETARD.map(() => '---:')]),
  ...NE_PAIENT_JAMAIS.map((j, i) => ligne([`**${pct(j)}**`, ...paiements[i].map((x) => (x ? `${usd(x.resultat)} · caisse −${usd(x.reporte)}` : '—'))])),
  '',
);
const premier = (critere) => NE_PAIENT_JAMAIS.find((_, i) => critere(paiements[i][0]));
const sousObjectif = premier((x) => x.resultat < p.objectifs.resultatNetCentimes);
const sousZero = premier((x) => x.resultat < 0);
ecrire(
  (sousObjectif === undefined ? `L’objectif de ${objectif} tient jusqu’à ${pct(NE_PAIENT_JAMAIS.at(-1))} d’impayés. `
    : sousObjectif === 0 ? `L’objectif de ${objectif} n’est pas atteint même sans aucun impayé. `
      : `L’objectif de ${objectif} est manqué dès ${pct(sousObjectif)} d’impayés. `) +
    (sousZero === undefined ? `L’académie ne perd pas d’argent jusqu’à ${pct(NE_PAIENT_JAMAIS.at(-1))} d’impayés.`
      : `L’académie perd de l’argent dès ${pct(sousZero)} de familles qui ne paient pas.`),
  'Le retard seul ne fait presque rien perdre sur l’année : il vide la caisse en fin de mois. Il faut donc une réserve au moins égale à la colonne « caisse ».',
  '',
  '## Et si on perd des élèves ?',
  '',
  ref,
  '',
  'Les élèves perdus ne sont pas remplacés. « Places vides » : les classes restent telles quelles, les enseignants sont payés pareil. ' +
    '« Classes regroupées » : l’administration refait les classes avec ceux qui restent, il y a moins d’heures à payer.',
  '',
  ligne(['Élèves perdus', ...pertes.map((x) => `${x.type}, ${x.regrouper ? 'classes regroupées' : 'places vides'}`)]),
  ligne(['---', ...pertes.map(() => '---:')]),
  ...PERTES.map((n, i) => ligne([`**${n}**`, ...pertes.map((x) => `${usd(x.lignes[i].resultat)} · ${x.lignes[i].groupes} classes`)])),
  '',
  '## Et si ça bouge trop ?',
  '',
  ref,
  '',
  'Un élève qui change de classe ou de créneau libère sa place : elle reste vide jusqu’à ce qu’une nouvelle famille la prenne. ' +
    'S’il n’y a aucune place libre dans une autre classe de son âge, la demande est refusée et 3 élèves sur 10 partent alors. ' +
    'Les heures d’administration sont une estimation (relance 10 min, plainte 15 min, changement 30 min, départ 20 min, arrivée 45 min).',
  '',
  ligne(['Stabilité', 'Ce que ça veut dire', 'Élèves présents', 'Départs / mois', 'Changements / mois', 'Refusés', 'Heures d’administration / mois', 'Net / mois']),
  ligne(['---', '---', '---:', '---:', '---:', '---:', '---:', '---:']),
  ...instabilite.map((x) => ligne([
    `**${x.titre}**`, x.detail, x.elevesActifs, x.departs, x.changements, x.refus, Math.round(x.heuresAdmin), usd(x.resultat),
  ])),
  '',
);

// --- Marge de manœuvre par scénario --------------------------------------------

const classement = [...grille].sort((a, b) => a.resultat - b.resultat);
const tableau = (liste) => [
  ligne(['Scénario', 'Encaissé', `Net à ${taux} / h`, 'Net 1 mois sur 10', 'Objectif', 'Taux max sans perte',
    'Perte max sans perte', 'Enfants / adultes perdus ou boursiers max', 'Remise max sans perte', `Remise max pour ${objectif}`]),
  ligne(['---', '---:', '---:', '---:', '---:', '---:', '---:', '---:', '---:', '---:']),
  ...liste.map((x) => ligne([
    libelle(x.choix), usd(x.encaisse), usd(x.resultat), usd(x.resultatP10), pct(x.objectif), usd2(x.tauxRentable),
    usd(x.perdableRentable), `${x.enfantsRentable} / ${x.adultesRentable}`, bps(x.remiseRentable),
    x.remiseObjectif < 0 ? `aucune (${signe(x.perdableObjectif)})` : bps(x.remiseObjectif),
  ])),
];
ecrire(
  '## Ce qu’on peut se permettre, scénario par scénario',
  '',
  'Toutes les valeurs sont prudentes (tenues 9 mois sur 10), enseignants à ' + taux + ' / h.',
  '',
  '- **Perte max sans perte** : encaissement mensuel qu’on peut perdre (impayés, départs, bourses, remises) avant que l’académie perde de l’argent.',
  '- **Enfants / adultes perdus ou boursiers max** : même montant, compté en mensualités d’enfant (50 $) ou d’adulte (60 $). ' +
    'Une bourse complète coûte exactement comme un élève perdu dont la place reste vide ; deux demi-bourses comptent pour une.',
  '- **Remise max** : remise en pourcentage qu’on peut faire sur toutes les mensualités. Elle donne le prix plancher : ' +
    'prix × (1 − remise). « Aucune » : la cible est déjà manquée, du montant indiqué.',
  '',
  '### Les 10 pires scénarios',
  '',
  ...tableau(classement.slice(0, 10)),
  '',
  '### Les 10 meilleurs scénarios',
  '',
  ...tableau(classement.slice(-10).reverse()),
);

ecrire(
  '',
  '## Quel prix fixer',
  '',
  `${ref.replace(' Un seul levier bouge à la fois.', '')} Chaque case : net médian, puis part des mois qui atteignent ${objectif}.`,
  '',
  ligne(['Enfant ↓ / Adulte →', ...PRIX_ADULTE.map((a) => `${a} $`)]),
  ligne(['---', ...PRIX_ADULTE.map(() => '---:')]),
  ...PRIX_ENFANT.map((e, i) => ligne([`**${e} $**`, ...prix[i].map((x) => `${usd(x.resultat)} · ${pct(x.objectif)}`)])),
  '',
  'Taux enseignant maximal (prudent) pour ne pas perdre d’argent, puis pour garder ' + objectif + ' :',
  '',
  ligne(['Enfant ↓ / Adulte →', ...PRIX_ADULTE.map((a) => `${a} $`)]),
  ligne(['---', ...PRIX_ADULTE.map(() => '---:')]),
  ...PRIX_ENFANT.map((e, i) => ligne([`**${e} $**`, ...prix[i].map((x) => `${usd2(x.tauxRentable)} · ${x.tauxObjectif ? usd2(x.tauxObjectif) : 'impossible'}`)])),
  '',
  `## Les ${grille.length} scénarios`,
  '',
  ...tableau([...grille].sort((a, b) => b.resultat - a.resultat)),
);

const texte = sortie.join('\n') + '\n';
if (valeur('--sortie')) writeFileSync(valeur('--sortie'), texte);
else process.stdout.write(texte);
