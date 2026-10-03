import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/grille_bento.dart';

/// Un compteur dans sa tuile : le chiffre, ce qu'il compte, et, pour les
/// plus urgents, ce qu'un tap y fait.
///
/// Public pour que la galerie montre la vraie tuile du Centre de commande,
/// jamais une recopie (GALERIE-BENTO-2, K-10).
class TuileCompteur extends StatelessWidget {
  /// Cree la tuile.
  const TuileCompteur({
    super.key,
    required this.valeur,
    required this.libelle,
    this.detail,
    this.onPress,
    this.enLigne = false,
    this.apercu = const <String>[],
  });

  /// Le chiffre, zero compris (invariant I9).
  final int valeur;

  /// Ce que le chiffre compte.
  final String libelle;

  /// Ce qu'un tap y fait, pour les tuiles qui menent a une file.
  final String? detail;

  /// L'ecran d'action ; sans lui, la tuile est un rapport, jamais un bouton
  /// grise.
  final VoidCallback? onPress;

  /// Vrai pour la tuile large : son chiffre est plus grand.
  final bool enLigne;

  /// Un apercu de la file, montre seulement quand la tuile a la place
  /// (grande tuile, au moins une ligne et demie de grille).
  final List<String> apercu;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = palette.surfaceRaised;
    final Widget chiffre = Text(
      '$valeur',
      style: AppTypography.tabulaire(
        // Le chiffre de la tuile large domine ; dans un carre, il laisse
        // au libelle la place de ses deux lignes.
        paire.applyTo(
          (enLigne ? textes.displayMedium : textes.headlineLarge) ??
              const TextStyle(),
        ),
      ),
    );
    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          libelle,
          style: paire.applyTo(
            (detail == null ? textes.labelMedium : textes.labelLarge) ??
                const TextStyle(),
          ),
        ),
        if (detail != null) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(
            detail!,
            style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
          ),
        ],
      ],
    );
    return AppCard(
      surface: paire,
      marge: AppSpacing.lg,
      onPress: onPress,
      // Le libelle lu tient le chiffre ET ce qu'il compte.
      libelleSemantique: '$valeur $libelle',
      // Le chiffre en haut, ce qu'il compte en bas : la tuile est remplie
      // quelle que soit sa forme. En une colonne (texte agrandi), la hauteur
      // est libre et les deux se suivent.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool place =
              apercu.isNotEmpty &&
              c.hasBoundedHeight &&
              c.maxHeight >=
                  GrilleBento.hauteurLignePour(
                        MediaQuery.textScalerOf(context).scale(1),
                      ) *
                      1.5;
          return ContenuTuileBento(
            children: <Widget>[
              chiffre,
              if (place)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final String ligne in apercu) ...<Widget>[
                      TexteSansCoupure(
                        ligne,
                        style: paire.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                      Ecart.vXs,
                    ],
                  ],
                ),
              Ecart.vXs,
              texte,
            ],
          );
        },
      ),
    );
  }
}

/// Deux compteurs calmes dans une seule tuile large, chacun avec son libelle.
class TuileDouble extends StatelessWidget {
  /// Cree la tuile double.
  const TuileDouble({super.key, required this.gauche, required this.droite});

  /// Le premier compteur : chiffre et libelle.
  final (int, String) gauche;

  /// Le second compteur : chiffre et libelle.
  final (int, String) droite;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = palette.surfaceRaised;
    Widget chiffre(int v) => Expanded(
      child: Text(
        '$v',
        style: AppTypography.tabulaire(
          paire.applyTo(textes.headlineMedium ?? const TextStyle()),
        ),
      ),
    );
    Widget libelle(String l) => Expanded(
      child: TexteSansCoupure(
        l,
        style: paire.applyTo(textes.labelMedium ?? const TextStyle()),
      ),
    );
    return AppCard(
      surface: paire,
      marge: AppSpacing.lg,
      libelleSemantique: '${gauche.$1} ${gauche.$2}, ${droite.$1} ${droite.$2}',
      // Les chiffres en haut, leurs libelles en bas, chacun sous le sien.
      child: ContenuTuileBento(
        children: <Widget>[
          Row(
            children: <Widget>[
              chiffre(gauche.$1),
              Ecart.hLg,
              chiffre(droite.$1),
            ],
          ),
          Ecart.vXs,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              libelle(gauche.$2),
              Ecart.hLg,
              libelle(droite.$2),
            ],
          ),
        ],
      ),
    );
  }
}
