// Les series des graphiques du Comptable (COMPTA-GRAPH-1, decision du
// directeur du 11/10 qui leve DR-09 ; maquettes FIN-CPT-W01 a W06, M01 a M03).
//
// **Ce que la source porte, et que Flutter ne calcule jamais** (DR-08, aucun
// calcul financier de reference cote client) : la repartition des coffres,
// les entrees et sorties des six derniers mois, le flux de tresorerie des
// trente derniers jours, l'evolution de la tresorerie sur six mois et les
// variations en pour mille. L'ecran dessine ce qu'on lui rend, il n'additionne
// ni ne compare rien. Les montants se masquent avec les autres (Q-9) : un
// graphique dessine des grandeurs, il se tait quand les montants sont masques.
//
// En production la source n'existe pas encore (`CPT-BR-18`, ligne Contrats a
// demander) : `CapaciteIndisponible`, que l'ecran dit en clair.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// La part d'un coffre dans la repartition (l'anneau).
@immutable
class PartCoffre {
  /// Cree la part.
  const PartCoffre({required this.coffre, required this.montant});

  /// Le coffre.
  final Coffre coffre;

  /// Son montant, rendu par la source.
  final Montant montant;
}

/// Les entrees et les sorties d'un mois.
@immutable
class PointMensuel {
  /// Cree le point.
  const PointMensuel({
    required this.mois,
    required this.entrees,
    required this.sorties,
  });

  /// Le premier jour du mois.
  final DateTime mois;

  /// Les encaissements du mois.
  final Montant entrees;

  /// Les decaissements du mois.
  final Montant sorties;
}

/// Le flux d'un jour.
@immutable
class PointJour {
  /// Cree le point.
  const PointJour({
    required this.jour,
    required this.encaissements,
    required this.decaissements,
  });

  /// Le jour (minuit local).
  final DateTime jour;

  /// Les encaissements du jour.
  final Montant encaissements;

  /// Les decaissements du jour.
  final Montant decaissements;
}

/// La tresorerie detenue a la fin d'un mois.
@immutable
class PointEvolution {
  /// Cree le point.
  const PointEvolution({required this.mois, required this.detenue});

  /// Le premier jour du mois.
  final DateTime mois;

  /// La tresorerie detenue a la fin du mois, rendue par la source.
  final Montant detenue;
}

/// Les series, telles que la source les rend.
@immutable
class SeriesTresorerie {
  /// Cree les series.
  const SeriesTresorerie({
    required this.repartition,
    required this.mensuel,
    required this.flux30Jours,
    required this.evolution,
    this.entrees30Jours,
    this.sorties30Jours,
    this.variationEntreesPourMille,
    this.variationSortiesPourMille,
  });

  /// La repartition par coffre.
  final List<PartCoffre> repartition;

  /// Les six derniers mois, du plus ancien au plus recent.
  final List<PointMensuel> mensuel;

  /// Les trente derniers jours, du plus ancien au plus recent.
  final List<PointJour> flux30Jours;

  /// L'evolution de la tresorerie detenue sur six mois.
  final List<PointEvolution> evolution;

  /// Le total des entrees des trente derniers jours, rendu par la source
  /// (jamais additionne ici, DR-08).
  final Montant? entrees30Jours;

  /// Le total des sorties des trente derniers jours, rendu par la source.
  final Montant? sorties30Jours;

  /// La variation des entrees sur la periode, en pour mille (+120 = +12 %),
  /// ou `null` quand la source ne la rend pas.
  final int? variationEntreesPourMille;

  /// La variation des sorties sur la periode, en pour mille.
  final int? variationSortiesPourMille;

  /// Vrai quand la source n'a rien a dessiner.
  bool get estVide =>
      repartition.isEmpty &&
      mensuel.isEmpty &&
      flux30Jours.isEmpty &&
      evolution.isEmpty;
}

/// Le port des series.
abstract interface class PortSeriesTresorerie {
  /// Les series des graphiques.
  Future<SeriesTresorerie> series();
}

/// **Aucune source serveur a ce jour** (CPT-BR-18).
class SeriesTresorerieIndisponibles implements PortSeriesTresorerie {
  /// Cree l'implementation.
  const SeriesTresorerieIndisponibles();

  @override
  Future<SeriesTresorerie> series() => Future<SeriesTresorerie>.error(
    const CapaciteIndisponible(dependanceSeriesTresorerie),
  );
}

/// L'identifiant de la dependance serveur (jamais affiche).
const String dependanceSeriesTresorerie = 'CPT-BR-18';

/// Le port ; la demonstration le surcharge (`series_demo.dart`).
final Provider<PortSeriesTresorerie> portSeriesTresorerieProvider =
    Provider<PortSeriesTresorerie>(
      (Ref _) => const SeriesTresorerieIndisponibles(),
    );

/// Les series lues. Aucune relance automatique : une capacite absente ne
/// revient pas en insistant, un echec se relit par « Reessayer ».
final FutureProvider<SeriesTresorerie> seriesTresorerieProvider =
    FutureProvider<SeriesTresorerie>(
      (Ref ref) => ref.watch(portSeriesTresorerieProvider).series(),
      retry: (int _, Object _) => null,
      dependencies: <ProviderOrFamily>[portSeriesTresorerieProvider],
    );
