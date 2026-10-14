// Le choix du mois d'une vue chiffree (Revenus estimes de l'enseignant, Vue
// globale de la direction ; FI-Q18 (a), revue FI-VAGUE-R R5-05, R6-03).
//
// Le menu ne propose QUE les mois que la source sait rendre (`mois`), le plus
// recent d'abord : aucun mois n'est fabrique ici. Un axe ouvert (la liste
// grandit chaque mois) : un menu, jamais une rangee de pastilles
// (`MenuFiltre`, regle des axes ouverts).

import 'package:flutter/widgets.dart';

import '../i18n/strings.g.dart';
import 'menu_filtre.dart';

/// « Mois : octobre 2026 », ouvert sur les mois rendus par la source.
class SelecteurMois extends StatelessWidget {
  /// Cree le selecteur.
  const SelecteurMois({
    required this.mois,
    required this.choisi,
    required this.onChoix,
    super.key,
  });

  /// Les mois rendus par la source (premier jour), le plus recent d'abord.
  /// Jamais vide : sans mois, l'ecran ne pose pas de selecteur.
  final List<DateTime> mois;

  /// Le mois choisi ; nul : le plus recent (le mois en cours).
  final DateTime? choisi;

  /// Ce qui se passe quand un mois est choisi.
  final ValueChanged<DateTime> onChoix;

  /// Un mois en mots : « octobre 2026 ».
  static String enMots(DateTime mois) => t.commun.dates.moisAnnee(
    mois: t.commun.dates.mois[mois.month - 1],
    annee: '${mois.year}',
  );

  static bool _memeMois(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  @override
  Widget build(BuildContext context) {
    final DateTime courant = choisi == null
        ? mois.first
        : mois.firstWhere(
            (DateTime m) => _memeMois(m, choisi!),
            orElse: () => mois.first,
          );
    return MenuFiltre<DateTime>(
      libelle: t.commun.dates.choixMois,
      valeur: courant,
      entrees: <EntreeFiltre<DateTime>>[
        for (final DateTime m in mois)
          EntreeFiltre<DateTime>(valeur: m, libelle: enMots(m)),
      ],
      onChoix: (DateTime? m) {
        if (m != null) onChoix(m);
      },
    );
  }
}
