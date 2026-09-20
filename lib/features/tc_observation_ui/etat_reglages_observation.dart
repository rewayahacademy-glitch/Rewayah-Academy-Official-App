import 'package:flutter/foundation.dart';

import '../../core/tc_observation/guardian_observation_policy.dart';

/// Ce qui empeche d'enregistrer un reglage.
enum InvaliditeReglages {
  /// Moins d'une visite par seance : autant desactiver, et le dire.
  visitesTropBas,

  /// Trop peu de temps pour que la visite ait un sens.
  tempsTropBas,
}

/// L'etat du module de reglages d'observation d'un groupe.
///
/// **Fonction pure et sans IO**, comme `deciderRedirection` : les trois choix,
/// leurs bornes et ce qu'ils produisent se verifient sans monter d'ecran.
///
/// Le module lui-meme n'est **pas route** : c'est une consigne explicite du
/// chantier. `lib/core/admin/admin_domaine.dart` est gele a huit domaines, et
/// l'onglet « Classe en ligne » de `ongletsConfiguration()` n'existe pas encore.
/// Agent Z branchera ce module dans « Groupe > Reglages » apres coup. Le
/// declarer dans la liste avant qu'il ait une route ferait echouer la
/// navigation au clic, ce que l'audit Admin interdit nommement.
@immutable
class EtatReglagesObservation {
  /// Cree un etat de reglage.
  const EtatReglagesObservation({
    required this.source,
    required this.maxVisites,
    required this.tempsTotal,
  });

  /// L'etat initial, lu depuis la politique effective du groupe.
  ///
  /// Une politique heritee ou desactivee garde quand meme ses valeurs en
  /// memoire : un administrateur qui bascule sur « Personnaliser » doit
  /// retrouver des champs remplis par ce dont il herite, pas deux zeros.
  factory EtatReglagesObservation.depuis(GuardianObservationPolicy politique) =>
      EtatReglagesObservation(
        source: politique.source,
        maxVisites: politique.maxVisitsPerSession,
        tempsTotal: politique.maxTotalObservationTime,
      );

  /// Le plancher du nombre de visites.
  ///
  /// Zero visite n'est pas un reglage, c'est une desactivation : elle a son
  /// propre choix, qui se journalise comme tel. Deux facons de fermer la meme
  /// porte finiraient par diverger.
  static const int visitesMin = 1;

  /// Le plafond d'entree du nombre de visites.
  ///
  /// **Un garde-fou de saisie, pas une regle produit.** La regle est en base,
  /// tenue par une contrainte `CHECK` demandee dans
  /// `docs/teaching-core/TC_CONTRACT_REQUEST_G.md` ; celle-ci evite seulement
  /// qu'un appui maintenu sur « Augmenter » ne propose mille visites.
  static const int visitesMax = 10;

  /// Le plancher de temps total.
  static const Duration tempsMin = Duration(seconds: 30);

  /// Le plafond d'entree du temps total. Garde-fou de saisie, comme
  /// [visitesMax].
  static const Duration tempsMax = Duration(minutes: 30);

  /// Le pas du champ de temps.
  static const Duration tempsPas = Duration(seconds: 30);

  /// D'ou vient la politique retenue.
  final SourcePolitique source;

  /// Visites par seance, quand le groupe est personnalise.
  final int maxVisites;

  /// Temps total par seance, quand le groupe est personnalise.
  final Duration tempsTotal;

  /// Vrai quand les deux quotas sont modifiables.
  bool get editable => source == SourcePolitique.groupe;

  /// Ce qui empeche d'enregistrer. Vide quand tout va bien.
  ///
  /// Les bornes ne sont controlees que sur un groupe personnalise : une valeur
  /// heritee est la responsabilite de l'Academie, et une politique desactivee
  /// n'a pas de quota du tout.
  Set<InvaliditeReglages> get invalidites {
    if (!editable) {
      return const <InvaliditeReglages>{};
    }
    return <InvaliditeReglages>{
      if (maxVisites < visitesMin) InvaliditeReglages.visitesTropBas,
      if (tempsTotal < tempsMin) InvaliditeReglages.tempsTropBas,
    };
  }

  /// Vrai quand le reglage peut partir au serveur.
  bool get valide => invalidites.isEmpty;

  /// Le meme etat, avec un autre choix de source.
  EtatReglagesObservation avecSource(SourcePolitique nouvelle) =>
      EtatReglagesObservation(
        source: nouvelle,
        maxVisites: maxVisites,
        tempsTotal: tempsTotal,
      );

  /// Le meme etat, avec un nombre de visites deplace de [pas], borne.
  EtatReglagesObservation deplacerVisites(int pas) => EtatReglagesObservation(
    source: source,
    maxVisites: (maxVisites + pas).clamp(visitesMin, visitesMax),
    tempsTotal: tempsTotal,
  );

  /// Le meme etat, avec un temps total deplace de [pas] fois le pas, borne.
  EtatReglagesObservation deplacerTemps(int pas) => EtatReglagesObservation(
    source: source,
    maxVisites: maxVisites,
    tempsTotal: Duration(
      seconds: (tempsTotal.inSeconds + pas * tempsPas.inSeconds).clamp(
        tempsMin.inSeconds,
        tempsMax.inSeconds,
      ),
    ),
  );

  /// La politique que ce reglage produit, appliquee a celle de l'Academie.
  ///
  /// **Trois choix, trois politiques distinctes, une seule resolution.** La
  /// resolution reelle reste serveur -- une fonction unique analogue a
  /// `regle_effective()` -- et cette methode n'en est que l'apercu affiche
  /// avant enregistrement. Deux resolutions, l'une ici l'autre en base,
  /// finiraient par montrer un budget que la seance ne donnerait pas.
  GuardianObservationPolicy appliquerA(GuardianObservationPolicy academie) =>
      switch (source) {
        SourcePolitique.academie => academie.copieAvec(
          source: SourcePolitique.academie,
        ),
        SourcePolitique.desactivee => academie.copieAvec(
          source: SourcePolitique.desactivee,
          observationActivee: false,
        ),
        SourcePolitique.groupe => academie.copieAvec(
          source: SourcePolitique.groupe,
          observationActivee: true,
          maxVisitsPerSession: maxVisites,
          maxTotalObservationTime: tempsTotal,
        ),
      };
}
