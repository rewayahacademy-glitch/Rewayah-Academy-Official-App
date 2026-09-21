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
/// Le module est branche depuis Admin > Operations > Groupes, en feuille sur la
/// ligne du groupe (`lib/features/admin_groupes/feuille_observation_groupe
/// .dart`) : la politique que le serveur ecrit est PAR GROUPE, elle se regle
/// donc depuis le groupe. `lib/core/admin/admin_domaine.dart` reste gele a huit
/// domaines et `ongletsConfiguration()` n'en parle toujours pas -- Configuration
/// porterait les defauts de l'Academie, qui vivent dans `app_config` et
/// qu'aucune RPC dediee n'ecrit aujourd'hui.
@immutable
class EtatReglagesObservation {
  /// Cree un etat de reglage.
  const EtatReglagesObservation({
    required this.source,
    required this.maxVisites,
    required this.tempsTotal,
    this.plafondParVisite,
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
        plafondParVisite: politique.maxParVisite,
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

  /// Le pas du champ de temps, et celui du plafond par visite.
  static const Duration tempsPas = Duration(seconds: 30);

  /// Le plancher du plafond par visite.
  ///
  /// Le meme que [tempsMin] : une visite de moins de trente secondes ne laisse
  /// pas le temps de voir si son enfant participe, qui est toute la raison
  /// d'etre de ce reglage.
  static const Duration plafondMin = tempsMin;

  /// D'ou vient la politique retenue.
  final SourcePolitique source;

  /// Visites par seance, quand le groupe est personnalise.
  final int maxVisites;

  /// Temps total par seance, quand le groupe est personnalise.
  final Duration tempsTotal;

  /// Plafond d'une seule visite. Nul quand le groupe n'en porte aucun.
  ///
  /// C'est le cinquieme parametre de `definir_politique_observation_groupe`,
  /// ajoute par la migration `0036`. Nul ici veut dire « aucun plafond propre » :
  /// [plafondEffectif] retombe alors sur le temps total, ce que
  /// `GuardianObservationPolicy.plafondDeVisite` fait deja a l'execution.
  final Duration? plafondParVisite;

  /// Le plafond reellement applique a une visite.
  ///
  /// **Le minimum du plafond et du total, toujours** : c'est l'invariant de
  /// `GuardianObservationPolicy.plafondDeVisite`, et le `least(...)` que la RPC
  /// de `0036` rejoue au moment d'ecrire. L'ecrire une troisieme fois ici evite
  /// d'afficher une promesse que ni le serveur ni la visite ne tiendraient --
  /// par exemple deux minutes par visite sur un total d'une minute.
  Duration get plafondEffectif {
    final Duration? propre = plafondParVisite;
    if (propre == null || propre > tempsTotal) {
      return tempsTotal;
    }
    return propre;
  }

  /// Vrai quand les quotas sont modifiables.
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
        plafondParVisite: plafondParVisite,
      );

  /// Le meme etat, avec un nombre de visites deplace de [pas], borne.
  EtatReglagesObservation deplacerVisites(int pas) => EtatReglagesObservation(
    source: source,
    maxVisites: (maxVisites + pas).clamp(visitesMin, visitesMax),
    tempsTotal: tempsTotal,
    plafondParVisite: plafondParVisite,
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
    plafondParVisite: plafondParVisite,
  );

  /// Le meme etat, avec un plafond de visite deplace de [pas] fois le pas.
  ///
  /// Borne haute : le temps total, jamais plus. Un plafond par visite au-dessus
  /// du total ne veut rien dire -- la premiere visite consommerait tout, et la
  /// seconde, qui est toute la raison d'etre du reglage, naitrait vide.
  EtatReglagesObservation deplacerPlafond(int pas) {
    // Le plancher s'efface devant le plafond quand le total est plus bas que
    // lui : `clamp` leve une assertion si sa borne basse depasse sa borne
    // haute, et un total de trente secondes est un reglage licite.
    final int haut = tempsTotal.inSeconds;
    final int bas = haut < plafondMin.inSeconds ? haut : plafondMin.inSeconds;
    return EtatReglagesObservation(
      source: source,
      maxVisites: maxVisites,
      tempsTotal: tempsTotal,
      plafondParVisite: Duration(
        seconds: (plafondEffectif.inSeconds + pas * tempsPas.inSeconds).clamp(
          bas,
          haut,
        ),
      ),
    );
  }

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
          // Toujours renseigne sur un groupe personnalise, jamais laisse nul :
          // la RPC de `0036` refuse « illimite par visite », et un plafond nul
          // rendrait le reste total entier d'un seul coup.
          maxParVisite: plafondEffectif,
        ),
      };
}
