// node --test tool/simulation/modele_academie.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  PARAMETRES_DEFAUT, parametresScenario, mensualiteFoyer, remiseFamiliale, repartirEnGroupes,
  seancesParMois, fraisCarte, coutLivekit, genererPopulation, simuler, tauxHoraireMax, coutEnseignants,
  grilleScenarios, fusionner,
} from './modele_academie.mjs';

const tarifs = PARAMETRES_DEFAUT.tarifs;

test('remise familiale : rien à 1 et 2, 5 $ pour la 3e, 7 $ par personne dès la 4e', () => {
  assert.equal(remiseFamiliale(1, tarifs), 0);
  assert.equal(remiseFamiliale(2, tarifs), 0);
  assert.equal(remiseFamiliale(3, tarifs), 500);
  assert.equal(remiseFamiliale(4, tarifs), 1200);
  assert.equal(remiseFamiliale(5, tarifs), 1900);
});

test('mensualité : 50 $ enfant, 60 $ adulte, remise sur le foyer entier', () => {
  assert.equal(mensualiteFoyer(['enfant'], tarifs), 5000);
  assert.equal(mensualiteFoyer(['adulte'], tarifs), 6000);
  assert.equal(mensualiteFoyer(['enfant', 'enfant', 'enfant'], tarifs), 14500);
  assert.equal(mensualiteFoyer(['adulte', 'enfant', 'enfant', 'enfant'], tarifs), 19800);
});

test('rythme : 3 séances par semaine donnent 13 séances par mois', () => {
  assert.equal(seancesParMois(PARAMETRES_DEFAUT.rythme), 13);
});

test('classes de min à max places ; le surplus attend une place', () => {
  assert.deepEqual(repartirEnGroupes(10, 5, 4), { tailles: [5, 5], enAttente: 0 });
  assert.deepEqual(repartirEnGroupes(13, 5, 4), { tailles: [5, 4, 4], enAttente: 0 });
  assert.deepEqual(repartirEnGroupes(11, 5, 4), { tailles: [5, 5], enAttente: 1 });
  assert.deepEqual(repartirEnGroupes(17, 6, 5), { tailles: [6, 6, 5], enAttente: 0 });
  assert.deepEqual(repartirEnGroupes(3, 5, 4), { tailles: [], enAttente: 3 });
  assert.deepEqual(repartirEnGroupes(0, 6, 5), { tailles: [], enAttente: 0 });
});

test('frais de carte : 1,5 % + 2 % de conversion + 0,29 $ sur 50 $', () => {
  assert.equal(fraisCarte(5000, 'eee', PARAMETRES_DEFAUT.paiementEnLigne), 175 + 29);
});

test('LiveKit : forfait seul sous les quotas, surcoût au-delà', () => {
  const lk = PARAMETRES_DEFAUT.livekit;
  assert.equal(coutLivekit(100000, 200, lk), 5000);
  assert.equal(coutLivekit(160000, 260, lk), 5000 + 500 + 120);
});

test('population : 100 élèves, classés ou en attente, classes dans les bornes', () => {
  const g = PARAMETRES_DEFAUT.groupes;
  const pop = genererPopulation(PARAMETRES_DEFAUT);
  assert.equal(pop.eleves.length, 100);
  assert.equal(pop.foyers.reduce((s, f) => s + f.membres.length, 0), 100);
  const classes = pop.groupes.reduce((s, x) => s + x.membres.length, 0);
  assert.equal(classes + pop.eleves.filter((x) => x.enAttente).length, 100);
  for (const x of pop.groupes) {
    const [min, max] = x.type === 'enfant' ? [g.minEnfants, g.maxEnfants] : [g.minAdultes, g.maxAdultes];
    assert.ok(x.membres.length >= min && x.membres.length <= max, `classe ${x.id} hors bornes`);
    assert.ok(x.enseignant !== undefined, `classe ${x.id} sans enseignant`);
  }
  for (const e of pop.enseignants) assert.ok(e.groupes.length <= g.groupesParEnseignant);
  for (const x of pop.groupes.filter((y) => y.public !== 'mixte')) {
    assert.equal(pop.enseignants[x.enseignant].sexe, x.public, 'enseignant du même sexe que la classe');
  }
});

test('grille : 216 scénarios distincts, toutes dimensions croisées', () => {
  const grille = grilleScenarios();
  assert.equal(grille.length, 216);
  assert.equal(new Set(grille.map((x) => JSON.stringify(x.choix))).size, 216);
  const separes = grille.find((x) => x.choix.mixiteEnfants === 'separes' && x.choix.mixiteAdultes === 'mixte');
  assert.equal(separes.parametres.groupes.mixiteEnfants, 'separes');
  assert.equal(separes.parametres.groupes.mixiteAdultes, 'mixte');
});

test('enfants séparés dès 10 ans : les 6-9 ans restent mixtes', () => {
  const pop = genererPopulation(fusionner(PARAMETRES_DEFAUT, { groupes: { mixiteEnfants: 'separes-des-10-ans' } }));
  for (const x of pop.groupes.filter((y) => y.type === 'enfant')) {
    assert.equal(x.public === 'mixte', x.tranche === '6-9');
  }
});

test('déterministe : même graine, mêmes résultats', () => {
  const p = parametresScenario('realiste', { tirages: 20 });
  assert.deepEqual(simuler(p).moisType.encaisse, simuler(p).moisType.encaisse);
});

test('scénario idéal : tout ce qui est facturé est encaissé, sans impayé ni départ', () => {
  const r = simuler(parametresScenario('ideal', { tirages: 5 }));
  assert.equal(r.moisType.encaisse.p50, r.moisType.facture.p50);
  assert.equal(r.moisType.impaye.p90, 0);
  assert.equal(r.moisType.departs.p90, 0);
});

test('les montants restent des entiers en centimes', () => {
  const r = simuler(parametresScenario('pessimiste', { tirages: 10 }));
  for (const cle of ['facture', 'encaisse', 'impaye', 'fraisCarte', 'livekit', 'resultatAvantEnseignants']) {
    for (const q of ['p10', 'p50', 'p90']) assert.ok(Number.isInteger(r.moisType[cle][q]), `${cle}.${q}`);
  }
  for (const t of r.tauxEnseignantMax) assert.ok(Number.isInteger(t.prudent) && Number.isInteger(t.median));
});

test('le taux maximal laisse exactement la marge visée', () => {
  const p = PARAMETRES_DEFAUT;
  const mois = {
    encaisseCentimes: 500000, resultatAvantEnseignantsCentimes: 450000,
    heuresEnseigneesCentiemes: 30000, virementsEnseignants: 10,
  };
  const taux = tauxHoraireMax(mois, 0.3, p);
  const reste = mois.resultatAvantEnseignantsCentimes - coutEnseignants(mois, taux, p).total;
  assert.ok(reste >= 0.3 * mois.encaisseCentimes);
  assert.ok(reste - 0.3 * mois.encaisseCentimes < 400, 'pas plus de 1 centime par heure laissé sur la table');
});
