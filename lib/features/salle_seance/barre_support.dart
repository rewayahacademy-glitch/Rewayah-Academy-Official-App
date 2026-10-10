// La barre du support, desktop (I-5, I-7).
//
// Eleve standard : « 1 / 12 » en lecture seule (aucune fleche) et le zoom
// local, qui ne publie rien. La pagination active de l'enseignant vient en T4.

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/commande_salle.dart';
import '../../core/widgets/pressable.dart';

/// Les noms du focus : le mot visible de l'action ([libelle], Commandes),
/// le mot d'etat de la bascule ([etat], barre de l'appel et barre du
/// support), le nom lu, le pictogramme.
typedef NomsFocus = ({
  String libelle,
  String etat,
  String semantique,
  AppIcon icone,
});

/// Revue TB-R m1 et m2 (plan V2 §5 et §20) : un seul nom pour entrer dans le
/// focus et en sortir, le meme dans les Commandes, la barre de l'appel et la
/// barre du support. « Focus » / « Quitter le focus » ; en Interface guidee,
/// « Agrandir » / « Arreter d'agrandir ». Jamais « Reduire » (le mot de la
/// fermeture d'un panneau). Le nom lu contient le mot visible (W-253).
///
/// Une bascule montre son etat par un mot court (ETATS-BTN-1) : la barre de
/// l'appel et celle du support disent « Focus » (« Agrandir » en guidee)
/// dans les deux etats, l'etat se lisant au disque plein et a l'icone ; le
/// nom lu dit l'action (« Quitter le focus et revoir les panneaux »). Le mot
/// garde une ligne : la barre ne grandit pas en focus (decide par
/// delegation le 10/10, regle ETATS-BTN-1 et garantie TB-5 « la surface
/// descend au moins aussi bas en focus »).
NomsFocus nomsFocus(BuildContext context, {required bool agrandi}) {
  final bool guidee = AppMetriques.of(context).mode == InterfaceMode.enfant;
  if (guidee) {
    return agrandi
        ? (
            libelle: t.salle.seance.commandes.quitterFocusGuide,
            etat: t.salle.seance.commandes.focusGuide,
            semantique: t.salle.seance.commandes.quitterFocusGuide,
            icone: AppIcons.reduire,
          )
        : (
            libelle: t.salle.seance.commandes.focusGuide,
            etat: t.salle.seance.commandes.focusGuide,
            semantique: t.salle.seance.commandes.focusGuide,
            icone: AppIcons.agrandir,
          );
  }
  return agrandi
      ? (
          libelle: t.salle.seance.commandes.quitterFocus,
          etat: t.salle.seance.commandes.focus,
          semantique: t.salle.seance.commandes.quitterFocusSemantique,
          icone: AppIcons.reduire,
        )
      : (
          libelle: t.salle.seance.commandes.focus,
          etat: t.salle.seance.commandes.focus,
          semantique: t.salle.seance.commandes.focusSemantique,
          icone: AppIcons.agrandir,
        );
}

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
    // TB_RAPPORT n. 9 : en version longue, « Page 1 sur 12 » peut passer a
    // la ligne (texte agrandi) ; la pastille devient un rectangle arrondi et
    // garde une marge tout autour : les disques des fleches restent dedans,
    // jamais poses sur son bord ni au-dela de son arrondi.
    return DecoratedBox(
      key: const ValueKey<String>('pagination-support'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: longue ? AppRadius.arrondiLg : AppRadius.arrondiFull,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: longue
            ? const EdgeInsets.all(AppSpacing.xs)
            : const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
    final NomsFocus noms = nomsFocus(context, agrandi: agrandi);
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
          // Revue TB-R m1 : le nom du focus, le meme partout ([nomsFocus]).
          CommandeSalle(
            key: const ValueKey<String>('bouton-agrandir-barre'),
            icone: noms.icone.repos,
            libelle: noms.etat,
            libelleSemantique: noms.semantique,
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
