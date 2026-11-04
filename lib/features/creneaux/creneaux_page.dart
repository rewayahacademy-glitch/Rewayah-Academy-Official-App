import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/page_shell.dart';
import 'plages_disponibilite.dart';

/// La section « Classes disponibles » (EN-5), ou `null`.
///
/// **`null` tant qu'aucun serveur ne la nourrit (BR-1)** : la section n'est
/// pas rendue, plutot que d'afficher un vide qui mentirait. Seule la
/// demonstration (`/demo/enseignant`) la fournit, depuis
/// `features/demo/classes_disponibles_demo.dart` : l'ecran ne depend d'aucun
/// type de la demonstration (lot DEMO-PROD, 04/11/2026).
final Provider<Widget?> sectionClassesDisponiblesProvider = Provider<Widget?>(
  (Ref ref) => null,
);

/// `ENS-06` Disponibilites : les plages hebdomadaires de l'enseignant
/// (DISPO-1, une ligne par plage), puis les Classes disponibles (EN-5).
///
/// **L'ancien modele est retire de l'ecran** (doc 04 §15.1, E1) : plus
/// d'onglet « Eleves en attente », plus de « Prendre {jour} a {heure} ». Le
/// serveur n'est pas touche (BR-1).
///
/// **Hebdomadaire, sans date** (E15) : aucun « 16 sept. », aucune navigation
/// de semaine.
///
/// Mobile : une colonne, les heures puis « Classes disponibles ».
/// Bureau : deux colonnes, le planning hebdomadaire et les Classes (doc 04
/// §15.3).
class CreneauxPage extends ConsumerWidget {
  /// Cree l'ecran des disponibilites.
  const CreneauxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Gabarit gabarit = AppGabarit.de(context);
    // Le titre de la page dit deja « Disponibilites » : pas de sous-titre
    // « Mes disponibilites » qui le repete (K-42 §1).
    const Widget heures = PlagesDisponibilite();
    // Sans section, la meme disposition qu'avant le lot DEMO-PROD : rien ne
    // change a l'ecran en production.
    final Widget classes =
        ref.watch(sectionClassesDisponiblesProvider) ?? const SizedBox.shrink();

    return PageShell(
      // Le titre concorde avec la destination de la coquille.
      titre: t.nav.enseignant.creneaux,
      child: gabarit == Gabarit.desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Expanded(child: heures),
                Ecart.hXxl,
                Expanded(child: classes),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[heures, Ecart.vXxl, classes],
            ),
    );
  }
}
