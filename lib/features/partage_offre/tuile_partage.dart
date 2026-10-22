// La tuile « Un proche veut apprendre le Coran ? » du portail `/attente`
// (CAND-06).
//
// Une carte entiere qui se touche et mene a la page de partage. **Pas de
// bouton plein** : le portail garde une seule action pleine, celle de l'etat de
// la candidature.
//
// **Elle parle de la personne qui apprendra, jamais de l'academie** (consigne
// du directeur du 22/10/2026, apres coup : « tu leur demandes de faire une
// action sans aucune contrepartie […] Il faut leur parler de l'interet que
// l'eleve va avoir »). Dans l'ordre : la question, ce que la personne y gagne,
// le hadith en motif personnel de celui qui partage, puis « Facultatif ».
//
// Sans lien d'offre (aucune adresse de site connue), la tuile n'est pas rendue :
// elle mene a une carte qui ne pourrait pas exister.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/partage_offre/lien_offre.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';

/// La tuile du portail.
class TuilePartageOffre extends ConsumerWidget {
  /// Cree la tuile.
  const TuilePartageOffre({super.key});

  /// La cle de la tuile.
  static const Key tuileKey = ValueKey<String>('portail-partage');

  /// La cle du titre (la question).
  static const Key titreKey = ValueKey<String>('portail-partage-titre');

  /// La cle du texte (ce que la personne y gagne).
  static const Key texteKey = ValueKey<String>('portail-partage-texte');

  /// La cle du motif (le hadith, pour celui qui partage).
  static const Key motifKey = ValueKey<String>('portail-partage-motif');

  /// La cle de la mention « Facultatif ».
  static const Key facultatifKey = ValueKey<String>(
    'portail-partage-facultatif',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(lienOffreProvider) == null) {
      return const SizedBox.shrink();
    }
    final c = t.recrutement.partage;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    return Padding(
      key: tuileKey,
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: AppCard(
        lien: true,
        libelleSemantique: '${c.titre} ${c.introduction}',
        onPress: () => GoRouter.maybeOf(context)?.go(Routes.attentePartage),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconTheme(
              data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
              child: Icon(AppIcons.partager.repos),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TexteSansCoupure(
                    c.titre,
                    key: titreKey,
                    style: palette.inkStrong.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vXs,
                  TexteSansCoupure(
                    c.introduction,
                    key: texteKey,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vSm,
                  TexteSansCoupure(c.motif, key: motifKey, style: muet),
                  Ecart.vSm,
                  TexteSansCoupure(
                    c.facultatif,
                    key: facultatifKey,
                    style: muet,
                  ),
                ],
              ),
            ),
            Ecart.hSm,
            ExcludeSemantics(
              child: IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.chevron.repos),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
