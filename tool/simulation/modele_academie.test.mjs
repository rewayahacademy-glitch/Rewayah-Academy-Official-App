// node --test tool/simulation/modele_academie.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  PARAMETRES_DEFAUT, parametresScenario, mensualiteFoyer, remiseFamiliale, repartirEnGroupes,
  seancesParMois, fraisCarte, coutLivekit, genererPopulation, simuler, tauxHoraireMax, coutEnseignants,
  grilleScenarios, fusionner, impotSocietesMensuel, beneficeAvantImpotPour, resultatMois, margeDeManoeuvre,
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

test('frais de carte Stripe Royaume-Uni : 2,5 % (EEE) + 2 % de conversion + 0,27 $ sur 50 $', () => {
  assert.equal(fraisCarte(5000, 'eee', PARAMETRES_DEFAUT.paiementEnLigne), 225 + 27);
  assert.equal(fraisCarte(5000, 'royaumeUni', PARAMETRES_DEFAUT.paiementEnLigne), 175 + 27);
});

test('impôt britannique : 19 % sous 50 000 £ par an, 25 % au-delà de 250 000 £, continu entre les deux', () => {
  const f = PARAMETRES_DEFAUT.fiscalite;
  assert.equal(impotSocietesMensuel(-50000, f), 0);
  assert.equal(impotSocietesMensuel(200000, f), 38000);
  const bas = (50000 * f.centimesParLivre) / 12;
  const haut = (250000 * f.centimesParLivre) / 12;
  assert.ok(Math.abs(impotSocietesMensuel(bas + 1, f) - 0.19 * bas) < 2, 'pas de saut au seuil bas');
  assert.equal(impotSocietesMensuel(Math.round(haut), f), Math.round(0.25 * haut));
});

test('bénéfice avant impôt pour garder 2 000 $ net : 2 000 / 0,81', () => {
  const f = PARAMETRES_DEFAUT.fiscalite;
  const avant = beneficeAvantImpotPour(200000, f);
  assert.ok(avant - impotSocietesMensuel(avant, f) >= 200000);
  assert.ok(avant - 1 - impotSocietesMensuel(avant - 1, f) < 200000);
  assert.equal(beneficeAvantImpotPour(0, f), 0);
});

test('marge de manœuvre : perdre exactement ce montant ramène à la cible', () => {
  const p = PARAMETRES_DEFAUT;
  const mois = {
    encaisseCentimes: 500000, fraisCarteCentimes: 25000, resultatAvantEnseignantsCentimes: 350000,
    heuresEnseigneesCentiemes: 30000, virementsEnseignants: 10,
  };
  const m = margeDeManoeuvre(mois, 400, 0, p);
  const avant = resultatMois(mois, 400, p).avantImpot;
  assert.ok(Math.abs(m.encaissementPerdable * 0.95 - avant) < 2);
  assert.equal(m.enfants, Math.floor(m.encaissementPerdable / 5000));
  assert.equal(m.adultes, Math.floor(m.encaissementPerdable / 6000));
  assert.equal(m.remiseMaxBps, Math.floor((m.encaissementPerdable * 10000) / 500000));
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
  for (const t of [r.tauxEnseignantMax.rentable, r.tauxEnseignantMax.objectif, ...r.tauxEnseignantMax.marges]) {
    assert.ok(Number.isInteger(t.prudent) && Number.isInteger(t.median));
  }
  for (const cle of ['avantImpot', 'impot', 'resultat']) assert.ok(Number.isInteger(r.moisType[cle].p50), cle);
});

test('le taux maximal laisse exactement la marge visée, après impôt', () => {
  const p = PARAMETRES_DEFAUT;
  const mois = {
    encaisseCentimes: 500000, resultatAvantEnseignantsCentimes: 450000,
    heuresEnseigneesCentiemes: 30000, virementsEnseignants: 10,
  };
  const cible = (x) => 0.3 * x.encaisseCentimes;
  const taux = tauxHoraireMax(mois, cible, p);
  assert.ok(resultatMois(mois, taux, p).net >= cible(mois));
  assert.ok(resultatMois(mois, taux + 1, p).net < cible(mois), 'un centime de plus fait passer sous la marge');
  assert.equal(tauxHoraireMax({ ...mois, resultatAvantEnseignantsCentimes: -1 }, () => 0, p), 0);
});

test('élèves perdus : places vides sans regroupement, moins de classes avec', () => {
  const base = parametresScenario('ideal', { tirages: 5 });
  const r0 = simuler(base);
  const vides = simuler(fusionner(base, { pertes: { enfants: 10, adultes: 0, regrouper: false } }));
  const regroupes = simuler(fusionner(base, { pertes: { enfants: 10, adultes: 0, regrouper: true } }));
  assert.equal(vides.population.groupes.length, r0.population.groupes.length);
  assert.equal(vides.moisType.elevesActifs.p50, r0.moisType.elevesActifs.p50 - 10);
  assert.ok(regroupes.population.groupes.length < r0.population.groupes.length);
  assert.ok(vides.moisType.resultat.p50 < regroupes.moisType.resultat.p50, 'regrouper coûte moins cher');
});

test('instabilité : plus de changements, plus de travail et moins de résultat', () => {
  const calme = simuler(parametresScenario('realiste', { tirages: 60 }));
  const agite = simuler(parametresScenario('realiste', {
    tirages: 60, comportements: { changementMensuel: 0.1, multiplicateurDeparts: 3, delaiRemplacementMois: 2 },
  }));
  assert.ok(agite.moisType.changements.p50 > calme.moisType.changements.p50);
  assert.ok(agite.moisType.heuresAdministration.p50 > calme.moisType.heuresAdministration.p50);
  assert.ok(agite.moisType.resultat.p50 < calme.moisType.resultat.p50);
});
