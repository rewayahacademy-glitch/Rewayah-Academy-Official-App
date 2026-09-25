// Le panneau ouvert a cote du support (enseignant) : Eleves ou Supports.
//
// T4 : le cadre seul (titre et fermeture). Le contenu vient en T5 (Eleves,
// CLV-07) et T6 (Supports, CLV-08). Desktop : colonne a gauche du support,
// jamais par-dessus ; web etroit et telephone : volet par-dessus le support.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';

/// La largeur du panneau en desktop et en web etroit (≈ 340).
const double largeurPanneauSeance = AppSpacing.respiration * 5 + AppSpacing.xl;

/// Le cadre d'un panneau : titre, croix de fermeture, [enfant].
class PanneauSeance extends StatelessWidget {
  const PanneauSeance({
    required this.titre,
    required this.onFermer,
    this.enfant = const SizedBox.shrink(),
    super.key,
  });

  final String titre;
  final VoidCallback? onFermer;
  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final VoidCallback? fermer = onFermer;
    return DecoratedBox(
      key: const ValueKey<String>('panneau-seance'),
      decoration: palette.surfaceRaised
          .decoration(
            borderRadius: AppRadius.arrondiLg,
            side: palette.borderHairline.asBorderSide(),
          )
          .copyWith(boxShadow: AppElevation.niveau1(palette.ombre)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.inkStrong.applyTo(
                        Theme.of(context).textTheme.titleMedium ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                ),
                if (fermer != null)
                  Pressable(
                    onPress: fermer,
                    libelleSemantique: t.salle.seance.fermerPanneau,
                    arrondiFocus: AppRadius.arrondiFull,
                    child: SizedBox.square(
                      dimension: AppSpacing.titreEcran,
                      child: Center(
                        child: IconTheme(
                          data: palette.inkStrong.asIconTheme(
                            size: AppSpacing.xxl,
                          ),
                          child: Icon(AppIcons.fermer.repos),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Ecart.vMd,
            Expanded(child: enfant),
          ],
        ),
      ),
    );
  }
}
