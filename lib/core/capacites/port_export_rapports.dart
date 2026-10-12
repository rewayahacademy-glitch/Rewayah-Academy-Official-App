// Les exports des rapports du Comptable (COMPTA-GRAPH-1 ; maquettes
// « Exporter le rapport », « Exporter la sélection »).
//
// Le fichier est produit par la source, jamais par Flutter (aucun calcul
// financier de reference cote client). Le port rend une reference de
// l'export demande ; en production il n'existe pas encore (`CPT-BR-19`) :
// l'ecran le dit en clair a la place de l'action, sans bouton grise.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import 'capacite_indisponible.dart';

/// Ce que l'export contient.
enum PerimetreExport {
  /// Le rapport de la periode affichee.
  rapport,

  /// Les lignes selectionnees (paiements a effectuer).
  selection,
}

/// Le resultat d'un export.
@immutable
class ResultatExport {
  /// Cree le resultat.
  const ResultatExport({required this.reference, required this.lignes});

  /// La reference de l'export, rendue par la source.
  final String reference;

  /// Le nombre de lignes exportees.
  final int lignes;
}

/// Le port des exports.
abstract interface class PortExportRapports {
  /// Exporte le rapport de la periode.
  Future<ResultatExport> exporterRapport({required String cleIdempotence});

  /// Exporte les lignes [identifiants].
  Future<ResultatExport> exporterSelection({
    required List<String> identifiants,
    required String cleIdempotence,
  });
}

/// L'identifiant de la dependance serveur (jamais affiche).
const String dependanceExportRapports = 'CPT-BR-19';

/// **Aucune source serveur a ce jour** (CPT-BR-19).
class ExportRapportsIndisponible implements PortExportRapports {
  /// Cree l'implementation.
  const ExportRapportsIndisponible();

  static const CapaciteIndisponible _manque = CapaciteIndisponible(
    dependanceExportRapports,
  );

  @override
  Future<ResultatExport> exporterRapport({required String cleIdempotence}) =>
      Future<ResultatExport>.error(_manque);

  @override
  Future<ResultatExport> exporterSelection({
    required List<String> identifiants,
    required String cleIdempotence,
  }) => Future<ResultatExport>.error(_manque);
}

/// Le port ; la demonstration le surcharge (`series_demo.dart`).
final Provider<PortExportRapports> portExportRapportsProvider =
    Provider<PortExportRapports>((Ref _) => const ExportRapportsIndisponible());

/// Vrai quand l'export est possible : le port n'est pas l'implementation
/// absente. L'ecran ne rend alors pas l'action et dit pourquoi.
final Provider<bool> exportDisponibleProvider = Provider<bool>(
  (Ref ref) =>
      ref.watch(portExportRapportsProvider) is! ExportRapportsIndisponible,
  dependencies: <ProviderOrFamily>[portExportRapportsProvider],
);
