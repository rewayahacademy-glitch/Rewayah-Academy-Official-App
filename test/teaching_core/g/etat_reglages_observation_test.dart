import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/features/tc_observation_ui/etat_reglages_observation.dart';

const GuardianObservationPolicy _academie =
    GuardianObservationPolicy.defautsNormatifs(policyVersion: 'academie-3');

EtatReglagesObservation _etat({
  SourcePolitique source = SourcePolitique.academie,
  int visites = 1,
  Duration temps = const Duration(seconds: 120),
}) => EtatReglagesObservation(
  source: source,
  maxVisites: visites,
  tempsTotal: temps,
);

void main() {
  group('Trois choix, trois politiques distinctes', () {
    test('heriter rend la politique de l\'Academie, inchangee', () {
      final GuardianObservationPolicy produite = _etat().appliquerA(_academie);

      expect(produite.source, SourcePolitique.academie);
      expect(produite.observationActivee, isTrue);
      expect(produite.maxVisitsPerSession, 1);
      expect(produite.maxTotalObservationTime, const Duration(seconds: 120));
    });

    test('desactiver ferme la porte, et se journalise comme tel', () {
      final GuardianObservationPolicy produite = _etat(
        source: SourcePolitique.desactivee,
      ).appliquerA(_academie);

      expect(produite.source, SourcePolitique.desactivee);
      expect(produite.observationActivee, isFalse);
      expect(produite.observationPossible, isFalse);
    });

    test('personnaliser porte les valeurs du groupe', () {
      final GuardianObservationPolicy produite = _etat(
        source: SourcePolitique.groupe,
        visites: 3,
        temps: const Duration(seconds: 300),
      ).appliquerA(_academie);

      expect(produite.source, SourcePolitique.groupe);
      expect(produite.observationActivee, isTrue);
      expect(produite.maxVisitsPerSession, 3);
      expect(produite.maxTotalObservationTime, const Duration(seconds: 300));
    });

    test('la politique de depart remplit les champs, meme heritee', () {
      // Un administrateur qui bascule sur « Personnaliser » doit retrouver ce
      // dont il herite, pas deux zeros.
      final EtatReglagesObservation depuisHeritage =
          EtatReglagesObservation.depuis(_academie);

      expect(depuisHeritage.source, SourcePolitique.academie);
      expect(depuisHeritage.maxVisites, 1);
      expect(depuisHeritage.tempsTotal, const Duration(seconds: 120));
      expect(depuisHeritage.avecSource(SourcePolitique.groupe).maxVisites, 1);
    });
  });

  group('Les quotas ne se modifient que sur un groupe personnalise', () {
    test('herite ou desactive, les champs sont fermes', () {
      expect(_etat().editable, isFalse);
      expect(_etat(source: SourcePolitique.desactivee).editable, isFalse);
      expect(_etat(source: SourcePolitique.groupe).editable, isTrue);
    });

    test('zero visite n\'est pas un reglage : c\'est une desactivation', () {
      final EtatReglagesObservation invalide = _etat(
        source: SourcePolitique.groupe,
        visites: 0,
      );

      expect(invalide.valide, isFalse);
      expect(invalide.invalidites, contains(InvaliditeReglages.visitesTropBas));
    });

    test('un temps sous le plancher est refuse', () {
      final EtatReglagesObservation invalide = _etat(
        source: SourcePolitique.groupe,
        temps: const Duration(seconds: 10),
      );

      expect(invalide.valide, isFalse);
      expect(invalide.invalidites, contains(InvaliditeReglages.tempsTropBas));
    });

    test('une valeur heritee hors bornes n\'est pas reprochee au groupe', () {
      // Les bornes sont celles de la saisie : une politique Academie
      // surprenante est la responsabilite de l'Academie.
      final EtatReglagesObservation herite = _etat(visites: 0, temps: Duration.zero);

      expect(herite.valide, isTrue);
    });

    test('les pas restent dans les bornes', () {
      final EtatReglagesObservation depart = _etat(
        source: SourcePolitique.groupe,
      );

      expect(depart.deplacerVisites(-5).maxVisites, EtatReglagesObservation.visitesMin);
      expect(depart.deplacerVisites(99).maxVisites, EtatReglagesObservation.visitesMax);
      expect(depart.deplacerTemps(-99).tempsTotal, EtatReglagesObservation.tempsMin);
      expect(depart.deplacerTemps(999).tempsTotal, EtatReglagesObservation.tempsMax);
    });

    test('un pas de temps vaut trente secondes', () {
      final EtatReglagesObservation depart = _etat(
        source: SourcePolitique.groupe,
      );

      expect(depart.deplacerTemps(1).tempsTotal, const Duration(seconds: 150));
      expect(depart.deplacerTemps(-1).tempsTotal, const Duration(seconds: 90));
    });
  });
}
