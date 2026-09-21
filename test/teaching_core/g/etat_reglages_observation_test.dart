import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/features/tc_observation_ui/etat_reglages_observation.dart';

const GuardianObservationPolicy _academie =
    GuardianObservationPolicy.defautsNormatifs(policyVersion: 'academie-3');

EtatReglagesObservation _etat({
  SourcePolitique source = SourcePolitique.academie,
  int visites = 1,
  Duration temps = const Duration(seconds: 120),
  Duration? plafond,
}) => EtatReglagesObservation(
  source: source,
  maxVisites: visites,
  tempsTotal: temps,
  plafondParVisite: plafond,
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

  group('Le plafond par visite, cinquieme parametre de la migration 0036', () {
    test('un groupe sans plafond propre retombe sur le temps total', () {
      // C'est deja ce que `plafondDeVisite` fait a l'execution : un plafond nul
      // ne veut pas dire zero seconde, il veut dire « tout le reste ».
      expect(
        _etat(temps: const Duration(seconds: 240)).plafondEffectif,
        const Duration(seconds: 240),
      );
    });

    test('un plafond au-dessus du total est ramene au total', () {
      // Le meme invariant que `GuardianObservationPolicy.plafondDeVisite` et
      // que le `least(...)` de la RPC : promettre deux minutes par visite sur
      // un total d'une minute serait un compte a rebours qui ment.
      expect(
        _etat(
          temps: const Duration(seconds: 60),
          plafond: const Duration(seconds: 120),
        ).plafondEffectif,
        const Duration(seconds: 60),
      );
    });

    test('les pas du plafond restent entre le plancher et le total', () {
      final EtatReglagesObservation depart = _etat(
        source: SourcePolitique.groupe,
        temps: const Duration(seconds: 240),
        plafond: const Duration(seconds: 120),
      );

      expect(depart.deplacerPlafond(1).plafondEffectif, const Duration(seconds: 150));
      expect(
        depart.deplacerPlafond(99).plafondEffectif,
        const Duration(seconds: 240),
        reason: 'le plafond ne depasse jamais le temps total',
      );
      expect(
        depart.deplacerPlafond(-99).plafondEffectif,
        EtatReglagesObservation.plafondMin,
      );
    });

    test('un total au plancher ne fait pas exploser le pas du plafond', () {
      // `clamp` leve une assertion si sa borne basse depasse sa borne haute, et
      // trente secondes de total est un reglage licite.
      final EtatReglagesObservation serre = _etat(
        source: SourcePolitique.groupe,
        temps: const Duration(seconds: 30),
      );

      expect(serre.deplacerPlafond(-1).plafondEffectif, const Duration(seconds: 30));
    });

    test('personnaliser envoie toujours un plafond, jamais nul', () {
      // « Illimite par visite » n'est pas un reglage : la premiere visite
      // consommerait tout et la seconde naitrait vide.
      final GuardianObservationPolicy produite = _etat(
        source: SourcePolitique.groupe,
        temps: const Duration(seconds: 240),
        plafond: const Duration(seconds: 120),
      ).appliquerA(_academie);

      expect(produite.maxParVisite, const Duration(seconds: 120));
      expect(
        produite.plafondDeVisite(const Duration(seconds: 240)),
        const Duration(seconds: 120),
      );
    });

    test('la politique de depart rapporte le plafond du groupe', () {
      const GuardianObservationPolicy groupe = GuardianObservationPolicy(
        policyVersion: 'groupe:4',
        source: SourcePolitique.groupe,
        observationActivee: true,
        maxVisitsPerSession: 2,
        maxTotalObservationTime: Duration(seconds: 240),
        maxParVisite: Duration(seconds: 90),
      );

      expect(
        EtatReglagesObservation.depuis(groupe).plafondParVisite,
        const Duration(seconds: 90),
      );
    });
  });
}
