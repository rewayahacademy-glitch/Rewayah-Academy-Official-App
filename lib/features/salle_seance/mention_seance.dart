// La mention d'enregistrement et la notice de visite de la salle (I-1, I-2).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/permanent_notice.dart';
import 'vue_seance.dart';

/// Au repos : la mention permanente ([PermanentNotice], sans parametre).
/// Pendant une visite annoncee a ce role : le point (clignotant, sauf en
/// guidee), l'oeil en guidee, puis la notice a la place du texte, meme
/// taille, sans fond. Le libelle d'accessibilite garde la mention ET la
/// notice. Enregistrement non confirme ou seance finie : rien.
///
/// Aucun role ne voit jamais un controleur : la vue ne porte que la visite
/// d'un tuteur.
class MentionSeance extends StatelessWidget {
  const MentionSeance({required this.vue, super.key});

  final VueSeance vue;

  @override
  Widget build(BuildContext context) {
    final String? mention = vue.texteMention;
    if (mention == null) return const SizedBox.shrink();
    final String? notice = vue.texteNotice;
    if (notice == null) return const PermanentNotice();

    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    return Semantics(
      label: t.salle.seance.mentionEtNotice(mention: mention, notice: notice),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PointEnregistrement(clignote: vue.pointClignote),
          Ecart.hSm,
          if (vue.voitOeilNotice) ...<Widget>[
            IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
              child: Icon(AppIcons.observationEnCours.repos),
            ),
            Ecart.hXs,
          ],
          Flexible(child: Text(notice, style: style)),
        ],
      ),
    );
  }
}
