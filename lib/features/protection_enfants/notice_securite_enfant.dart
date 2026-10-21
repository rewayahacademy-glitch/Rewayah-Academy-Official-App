import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import 'ligne_responsable.dart';

/// Ce que dit l'ecran quand la categorie « Securite d'un enfant » est choisie
/// (PE, 18/10/2026), dans « Signaler un besoin » : le signalement est
/// prioritaire, qui le lit, qui ne le voit pas, qui le recoit, et la phrase
/// d'urgence. Remplace le champ du message pour la famille, qui n'existe pas
/// pour cette categorie.
class NoticeSecuriteEnfant extends StatelessWidget {
  /// Cree la notice.
  const NoticeSecuriteEnfant({super.key});

  /// La cle de la notice.
  static const Key noticeKey = ValueKey<String>('notice-securite-enfant');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      key: noticeKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.protectionEnfants.prioritaireTitre,
            style: textes.titleSmall,
          ),
        ),
        Ecart.vXs,
        TexteSansCoupure(
          t.protectionEnfants.prioritaireDetail,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        const LigneResponsableProtection(),
        Ecart.vSm,
        TexteSansCoupure(
          t.protectionEnfants.urgence,
          style: palette.inkStrong.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
