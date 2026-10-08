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
    super.key,
  });

  final int page;
  final int pages;
  final VoidCallback? onPrecedente;
  final VoidCallback? onSuivante;

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
          etendue: false,
          position: t.salle.seance.page(page: page, pages: pages),
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
    final String valeur = t.salle.seance.zoomValeur(
      valeur: (zoom * 100).round(),
    );
    final TextStyle styleValeur = palette.inkStrong.applyTo(
      theme.textTheme.titleSmall ?? const TextStyle(),
    );
    final Widget? libelle = avecLibelle
        ? Flexible(
            child: Text(
              t.salle.seance.zoomLocal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette.inkMuted.applyTo(
                theme.textTheme.labelSmall ?? const TextStyle(),
              ),
            ),
          )
        : null;
    final Widget boite = DecoratedBox(
      decoration: _cadre(palette),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _IconeBarre(
            icone: AppIcons.zoomMoins,
            libelle: t.salle.seance.zoomMoins,
            onPress: onMoins,
          ),
          Text(valeur, style: styleValeur),
          _IconeBarre(
            icone: AppIcons.zoomPlus,
            libelle: t.salle.seance.zoomPlus,
            onPress: onPlus,
          ),
        ],
      ),
    );
    final String motAgrandir = agrandi
        ? t.salle.seance.reduire
        : t.salle.seance.agrandir;
    // Meme bascule que dans le dock (ETATS-BTN-1) : un seul composant, donc
    // le meme rendu a trois signaux (disque plein ou contour, icone reduire
    // / agrandir, mot d'etat).
    final Widget? bascule = agrandir == null
        ? null
        : CommandeSalle(
            key: const ValueKey<String>('bouton-agrandir-barre'),
            icone: (agrandi ? AppIcons.reduire : AppIcons.agrandir).repos,
            libelle: motAgrandir,
            bascule: agrandi,
            onPress: agrandir,
          );
    final Widget rangee = Row(
      key: const ValueKey<String>('zoom-local'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (libelle != null) ...<Widget>[libelle, Ecart.hXl],
        boite,
        if (bascule != null) ...<Widget>[Ecart.hMd, bascule],
      ],
    );
    if (bascule == null) return rangee;
    // DOCK-X2-1 : le mot d'etat d'Agrandir reste entier (decision du
    // 05/10), sa case peut donc s'elargir avec le texte. Si la rangee ne
    // tient plus dans la place donnee, Agrandir passe sous le zoom au lieu
    // de deborder. Quand elle tient, la rangee est rendue telle quelle.
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final double besoin =
            (libelle != null ? AppSpacing.xl : 0) +
            2 * AppSpacing.titreEcran +
            _largeurTexte(contexte, valeur, styleValeur) +
            AppSpacing.md +
            largeurCaseBasculeAvecMot(
              contexte,
              libelle: motAgrandir,
              style: theme.textTheme.labelMedium,
            );
        if (besoin <= contraintes.maxWidth) return rangee;
        return Column(
          key: const ValueKey<String>('zoom-local'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (libelle != null) ...<Widget>[libelle, Ecart.hXl],
                boite,
              ],
            ),
            bascule,
          ],
        );
      },
    );
  }
}

/// La largeur d'un texte d'une ligne, au [style] et a l'echelle courants.
double _largeurTexte(BuildContext context, String texte, TextStyle style) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(text: texte, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final double largeur = peintre.width;
  peintre.dispose();
  return largeur;
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
          data:
              (action == null ? palette.inkFaint : palette.inkStrong)
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
