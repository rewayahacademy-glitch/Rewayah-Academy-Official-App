import 'package:flutter/material.dart';

import '../finance/finances_profil.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// La periode financee d'un profil (`FinancedPeriodBadge`, guide Finance V4
/// §5.2 ; FI-3b) : « Financé jusqu'au 31 octobre 2026 », ou « Aucune periode
/// financee » (essai, aucun paiement).
///
/// Une icone et une phrase, sans fond : la date porte l'information, pas une
/// teinte. L'etat (financé, a regulariser...) se dit a cote, par
/// `PastilleFinanciere`.
class BadgePeriodeFinancee extends StatelessWidget {
  /// Cree le badge.
  const BadgePeriodeFinancee({required this.periode, super.key});

  /// La periode rendue par la source, `null` sans periode.
  final PeriodeFinancee? periode;

  /// La phrase du badge.
  static String phraseDe(PeriodeFinancee? periode) {
    if (periode == null) return t.argent.periode.aucune;
    final DateTime fin = periode.fin.toLocal();
    return t.argent.periode.jusquau(
      date: t.foyer.membre.date(
        jour: fin.day.toString(),
        mois: t.commun.dates.mois[fin.month - 1],
        annee: fin.year.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
              child: Icon(AppIcons.horloge.repos),
            ),
          ),
          Ecart.hXs,
          Flexible(
            child: Text(
              phraseDe(periode),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
