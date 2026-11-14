import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// La mention d'une traduction (LANGUES-3, directeur, 14/11/2026) : en tete
/// des textes juridiques et du contrat, une ligne dit que la version
/// francaise fait foi. Rien en francais : la mention n'a de sens que dans une
/// traduction.
class MentionTraduction extends StatelessWidget {
  /// Cree la mention.
  const MentionTraduction({super.key});

  /// Vrai quand la mention s'affiche : dans toute langue autre que le francais.
  static bool get affichee => LocaleSettings.currentLocale != AppLocale.fr;

  @override
  Widget build(BuildContext context) {
    if (!affichee) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Ecart.vSm,
        Text(t.juridique.traduction, style: style),
      ],
    );
  }
}
