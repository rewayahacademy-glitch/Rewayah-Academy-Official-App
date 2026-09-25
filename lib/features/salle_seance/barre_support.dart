// La barre du support, desktop (I-5, I-7).
//
// Eleve standard : « 1 / 12 » en lecture seule (aucune fleche) et le zoom
// local, qui ne publie rien. La pagination active de l'enseignant vient en T4.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';

/// Le cadre commun des pastilles de la barre : surface surelevee, filet.
BoxDecoration _cadre(AppPalette palette) => palette.surfaceRaised.decoration(
  borderRadius: AppRadius.arrondiMd,
  side: palette.borderHairline.asBorderSide(),
);

/// « 1 / 12 », en lecture seule.
class IndicateurPage extends StatelessWidget {
  const IndicateurPage({required this.page, required this.pages, super.key});

  final int page;
  final int pages;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      label: t.salle.seance.pageSemantique(page: page, pages: pages),
      excludeSemantics: true,
      child: DecoratedBox(
        key: const ValueKey<String>('indicateur-page'),
        decoration: _cadre(palette),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl,
            vertical: AppSpacing.md,
          ),
          child: Text(
            t.salle.seance.page(page: page, pages: pages),
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Zoom local, sans effet sur les autres », (−, 100 %, +) et Agrandir.
class ZoomLocal extends StatelessWidget {
  const ZoomLocal({
    required this.zoom,
    this.onMoins,
    this.onPlus,
    this.onAgrandir,
    super.key,
  });

  /// Le facteur courant (1 = 100 %).
  final double zoom;
  final VoidCallback? onMoins;
  final VoidCallback? onPlus;
  final VoidCallback? onAgrandir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final VoidCallback? agrandir = onAgrandir;
    return Row(
      key: const ValueKey<String>('zoom-local'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            t.salle.seance.zoomLocal,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.inkMuted.applyTo(
              theme.textTheme.labelSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.hXl,
        DecoratedBox(
          decoration: _cadre(palette),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _IconeBarre(
                icone: AppIcons.zoomMoins,
                libelle: t.salle.seance.zoomMoins,
                onPress: onMoins,
              ),
              Text(
                t.salle.seance.zoomValeur(valeur: (zoom * 100).round()),
                style: palette.inkStrong.applyTo(
                  theme.textTheme.titleSmall ?? const TextStyle(),
                ),
              ),
              _IconeBarre(
                icone: AppIcons.zoomPlus,
                libelle: t.salle.seance.zoomPlus,
                onPress: onPlus,
              ),
            ],
          ),
        ),
        if (agrandir != null) ...<Widget>[
          Ecart.hMd,
          DecoratedBox(
            decoration: _cadre(palette),
            child: _IconeBarre(
              icone: AppIcons.agrandir,
              libelle: t.salle.seance.agrandir,
              onPress: agrandir,
            ),
          ),
        ],
      ],
    );
  }
}

class _IconeBarre extends StatelessWidget {
  const _IconeBarre({
    required this.icone,
    required this.libelle,
    required this.onPress,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = onPress;
    final Widget dessin = SizedBox.square(
      dimension: AppSpacing.titreEcran,
      child: Center(
        child: IconTheme(
          data: AppPalette.of(context).inkStrong
              .asIconTheme(size: AppSpacing.xxl),
          child: Icon(icone.repos),
        ),
      ),
    );
    if (action == null) return dessin;
    return Pressable(
      onPress: action,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiMd,
      child: dessin,
    );
  }
}
