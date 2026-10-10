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
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/commande_salle.dart';
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

/// Pagination active de l'enseignant, desktop : ‹ 1 / 12 ›, par
/// [BarrePrecedentSuivant]. Elle change la page de tous (I-5) ; une fleche sans
/// rappel, ou au bout du support, n'est pas rendue.
class PaginationSupport extends StatelessWidget {
  const PaginationSupport({
    required this.page,
    required this.pages,
    this.onPrecedente,
    this.onSuivante,
    this.longue = false,
    super.key,
  });

  final int page;
  final int pages;
  final VoidCallback? onPrecedente;
  final VoidCallback? onSuivante;

  /// TB-4 (Commandes, plan V2 §20) : « Page {numero} sur {total} » ecrit en
  /// entier (le texte lu, W-253) entre les fleches, sur toute la largeur
  /// offerte ; a 200 % il passe a la ligne, jamais tronque. Faux : la
  /// pastille courte « 1 / 12 ».
  final bool longue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Aux bornes la fleche disparait (NAV-FLECHES-1), elle n'est pas grisee.
    final VoidCallback? precedente = page > 1 ? onPrecedente : null;
    final VoidCallback? suivante = page < pages ? onSuivante : null;
    return DecoratedBox(
      key: const ValueKey<String>('pagination-support'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiFull,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: BarrePrecedentSuivant(
          etendue: longue,
          position: longue
              ? t.salle.seance.pageSemantique(page: page, pages: pages)
              : t.salle.seance.page(page: page, pages: pages),
          positionSemantique: t.salle.seance.pageSemantique(
            page: page,
            pages: pages,
          ),
          libellePrecedent: t.salle.seance.pagePrecedente,
          libelleSuivant: t.salle.seance.pageSuivante,
          onPrecedent: precedente,
          onSuivant: suivante,
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
    this.agrandi = false,
    this.avecLibelle = true,
    super.key,
  });

  /// « Zoom local, sans effet sur les autres » : eleve seulement (l'image
  /// CLV-06 de l'enseignant montre les seules commandes).
  final bool avecLibelle;

  /// Le facteur courant (1 = 100 %).
  final double zoom;
  final VoidCallback? onMoins;
  final VoidCallback? onPlus;
  final VoidCallback? onAgrandir;

  /// Le support occupe l'ecran : le bouton devient « Reduire ».
  final bool agrandi;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final VoidCallback? agrandir = onAgrandir;
    return Row(
      key: const ValueKey<String>('zoom-local'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (avecLibelle) ...<Widget>[
          Flexible(
            // TB-12 : a texte x2 (1440), une ligne coupait la phrase
            // (« sans effet sur les a… ») ; deux lignes tiennent sous la
            // hauteur d'« Agrandir », la rangee ne grandit pas.
            child: Text(
              t.salle.seance.zoomLocal,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: palette.inkMuted.applyTo(
                theme.textTheme.labelSmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.hXl,
        ],
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
          // Meme bascule que dans le dock (ETATS-BTN-1) : un seul composant,
          // donc le meme rendu a trois signaux (disque plein ou contour,
          // icone reduire / agrandir, mot d'etat).
          CommandeSalle(
            key: const ValueKey<String>('bouton-agrandir-barre'),
            icone: (agrandi ? AppIcons.reduire : AppIcons.agrandir).repos,
            libelle: agrandi ? t.salle.seance.reduire : t.salle.seance.agrandir,
            bascule: agrandi,
            onPress: agrandir,
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
    final AppPalette palette = AppPalette.of(context);
    final Widget dessin = SizedBox.square(
      dimension: AppSpacing.titreEcran,
      child: Center(
        child: IconTheme(
          // Un bouton sans rappel (fin de pagination, etc.) : estompe, inactif.
          data: (action == null ? palette.inkFaint : palette.inkStrong)
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
