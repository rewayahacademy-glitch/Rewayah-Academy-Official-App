// Les doubles de demonstration des graphiques et des exports du Comptable
// (COMPTA-GRAPH-1). Hors production : les series sont fictives, rendues d'un
// bloc comme la source les rendra (aucun calcul cote client).

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/port_export_rapports.dart';
import '../../../core/capacites/port_series_tresorerie.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';

Montant _usd(int unites) => Montant(unites * 100, 'USD');

/// Les series fictives, ancrees sur [aujourdhui].
class SeriesTresorerieDemo implements PortSeriesTresorerie {
  /// Cree le double.
  const SeriesTresorerieDemo({required this.aujourdhui, this.vide = false});

  /// Le jour courant de la demonstration.
  final DateTime aujourdhui;

  /// Vrai : aucune donnee a dessiner.
  final bool vide;

  @override
  Future<SeriesTresorerie> series() async {
    if (vide) {
      return const SeriesTresorerie(
        repartition: <PartCoffre>[],
        mensuel: <PointMensuel>[],
        flux30Jours: <PointJour>[],
        evolution: <PointEvolution>[],
      );
    }
    final DateTime jour = DateTime(
      aujourdhui.year,
      aujourdhui.month,
      aujourdhui.day,
    );
    final List<DateTime> mois = <DateTime>[
      for (int i = 5; i >= 0; i--)
        DateTime(aujourdhui.year, aujourdhui.month - i),
    ];
    const List<int> entrees = <int>[4200, 4650, 4400, 5100, 5600, 6200];
    const List<int> sorties = <int>[3900, 4100, 4300, 4500, 4700, 4800];
    const List<int> detenue = <int>[8800, 9350, 9450, 10050, 10950, 12350];
    const List<int> parts = <int>[3200, 2400, 1800, 900, 1500, 400, 2150];
    return SeriesTresorerie(
      repartition: <PartCoffre>[
        for (int i = 0; i < Coffre.values.length; i++)
          PartCoffre(coffre: Coffre.values[i], montant: _usd(parts[i])),
      ],
      mensuel: <PointMensuel>[
        for (int i = 0; i < 6; i++)
          PointMensuel(
            mois: mois[i],
            entrees: _usd(entrees[i]),
            sorties: _usd(sorties[i]),
          ),
      ],
      flux30Jours: <PointJour>[
        for (int i = 0; i < 30; i++)
          PointJour(
            jour: jour.subtract(Duration(days: 29 - i)),
            encaissements: _usd(120 + (i * 37) % 140),
            decaissements: _usd(i % 7 == 6 ? 480 : 40 + (i * 23) % 90),
          ),
      ],
      evolution: <PointEvolution>[
        for (int i = 0; i < 6; i++)
          PointEvolution(mois: mois[i], detenue: _usd(detenue[i])),
      ],
      entrees30Jours: _usd(6200),
      sorties30Jours: _usd(4800),
      variationEntreesPourMille: 120,
      variationSortiesPourMille: -40,
    );
  }
}

/// Les exports fictifs : une reference, aucun fichier.
class ExportRapportsDemo implements PortExportRapports {
  /// Cree le double.
  const ExportRapportsDemo();

  @override
  Future<ResultatExport> exporterRapport({
    required String cleIdempotence,
  }) async => const ResultatExport(reference: 'EXP-DEMO-0001', lignes: 36);

  @override
  Future<ResultatExport> exporterSelection({
    required List<String> identifiants,
    required String cleIdempotence,
  }) async =>
      ResultatExport(reference: 'EXP-DEMO-0002', lignes: identifiants.length);
}

/// Les surcharges de la demonstration des graphiques et des exports.
List<Override> surchargesDemoSeries({required DateTime aujourdhui}) =>
    <Override>[
      portSeriesTresorerieProvider.overrideWithValue(
        SeriesTresorerieDemo(aujourdhui: aujourdhui),
      ),
      portExportRapportsProvider.overrideWithValue(const ExportRapportsDemo()),
    ];
