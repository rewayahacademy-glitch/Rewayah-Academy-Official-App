// « Rapports » du Comptable (COMPTA-GRAPH-1, maquettes W01 a W06 : entree
// « Rapports » et « Exporter le rapport »). Onglet de Tresorerie.
//
// Repond a « Comment evoluent les entrees, les sorties et la tresorerie ? » :
// entrees et sorties sur 6 mois (barres), flux sur 30 jours, evolution sur
// 6 mois. Chaque graphique a sa legende ecrite et son tableau des valeurs
// (alternative accessible) ; les montants masques masquent le dessin.
// Cinq etats par bloc (`BlocSerie`). Une seule action : « Exporter le
// rapport », par un port, avec une phrase quand la capacite n'existe pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_export_rapports.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import 'action_export.dart';
import 'blocs_graphiques.dart';

/// L'onglet « Rapports ».
class RapportsPage extends ConsumerWidget {
  /// Cree la page.
  const RapportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = t.comptable.graphiques;
    return PageShell(
      titre: g.rapportsTitre,
      sousTitre: g.rapportsSousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsTresorerieComptable(),
        indexActif: 3,
      ),
      actionsEntete: const <Widget>[BasculeMontants(avecEtat: true)],
      child: const ColonneCorps(
        children: <Widget>[
          BlocEntreesSorties6Mois(),
          Ecart.vXxl,
          BlocFlux30Jours(),
          Ecart.vXxl,
          ActionExport(perimetre: PerimetreExport.rapport),
        ],
      ),
    );
  }
}
