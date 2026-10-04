import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/pressable.dart';

/// Une ligne de l'apercu d'une tuile : ce qu'elle nomme et, quand elle nomme
/// une personne, l'ecran de cette personne (DASH_STRATEGIE D4 (a)).
@immutable
class LigneApercu {
  /// Cree une ligne.
  const LigneApercu(this.libelle, {this.onPress});

  /// Ce que la ligne nomme, avec son anciennete.
  final String libelle;

  /// Ouvre la fiche de ce que la ligne nomme, jamais la file entiere.
  final VoidCallback? onPress;
}

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
    this.apercu = const <LigneApercu>[],
    this.apercuErreur,
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
  ///
  /// Des qu'une ligne a son propre appui, la tuile n'est plus un seul
  /// bouton : le chiffre et le libelle menent a la file, chaque ligne a sa
  /// fiche (DASH_STRATEGIE D4 (a)). Jamais un bouton dans un bouton.
  final List<LigneApercu> apercu;

  /// Dit a la place de l'apercu que sa lecture a echoue : le chiffre, lu
  /// ailleurs, reste juste (DASH_STRATEGIE D11, erreur par source).
  final String? apercuErreur;

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
    final bool lignesActives = apercu.any((LigneApercu l) => l.onPress != null);
    final List<Widget> lignesApercu = <Widget>[
      if (apercuErreur != null)
        TexteSansCoupure(
          apercuErreur!,
          style: palette.inkAlert.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        )
      else
        for (final LigneApercu ligne in apercu)
          if (ligne.onPress == null) ...<Widget>[
            TexteSansCoupure(
              ligne.libelle,
              style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
            Ecart.vXs,
          ] else
            // La ligne nomme une personne : elle ouvre sa fiche, cible
            // tactile entiere (48), jamais la file (modification UX n°2).
            Pressable(
              onPress: ligne.onPress,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TexteSansCoupure(
                  ligne.libelle,
                  style: palette.inkAccent.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ),
    ];
    final bool aApercu = apercu.isNotEmpty || apercuErreur != null;

    // Des lignes qui ouvrent chacune leur fiche : la carte n'est plus un seul
    // bouton. Le chiffre et ce qu'il compte forment le lien vers la file, en
    // haut ; les lignes suivent, chacune son appui.
    if (lignesActives || apercuErreur != null) {
      return AppCard(
        surface: paire,
        marge: AppSpacing.lg,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget entete = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[chiffre, Ecart.vXs, texte],
            );
            // Une seule colonne : les noms suivent l'en-tete, au lieu d'etre
            // repousses au bas de la grande tuile.
            return ContenuTuileBento(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (onPress == null)
                      entete
                    else
                      Pressable(
                        onPress: onPress,
                        respecterCibleTactile: false,
                        libelleSemantique: '$valeur $libelle',
                        child: SizedBox(width: double.infinity, child: entete),
                      ),
                    if (_aLaPlace(context, c)) ...<Widget>[
                      Ecart.vMd,
                      ...lignesApercu,
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

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
          return ContenuTuileBento(
            children: <Widget>[
              chiffre,
              if (aApercu && _aLaPlace(context, c))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lignesApercu,
                ),
              Ecart.vXs,
              texte,
            ],
          );
        },
      ),
    );
  }

  /// L'apercu ne se montre que si la tuile a la place : une ligne et demie
  /// de grille au moins, ou une hauteur libre (une colonne, texte agrandi).
  static bool _aLaPlace(BuildContext context, BoxConstraints c) =>
      !c.hasBoundedHeight ||
      c.maxHeight >=
          GrilleBento.hauteurLignePour(
                MediaQuery.textScalerOf(context).scale(1),
              ) *
              1.5;
}

/// Deux compteurs de meme nature dans une seule tuile large, chacun avec son
/// libelle, quelles que soient leurs valeurs (DASH_STRATEGIE D3).
///
/// Un compteur dont la page s'ouvre filtree sur ce qu'il compte devient un
/// lien ([onPressGauche], [onPressDroite]) ; l'autre reste un rapport (D9).
class TuileDouble extends StatelessWidget {
  /// Cree la tuile double.
  const TuileDouble({
    super.key,
    required this.gauche,
    required this.droite,
    this.titre,
    this.onPressGauche,
    this.onPressDroite,
  });

  /// Ce que les deux compteurs ont en commun, au-dessus des chiffres.
  final String? titre;

  /// Le premier compteur : chiffre et libelle.
  final (int, String) gauche;

  /// Le second compteur : chiffre et libelle.
  final (int, String) droite;

  /// La page filtree du premier compteur, s'il en a une.
  final VoidCallback? onPressGauche;

  /// La page filtree du second compteur (DASH-ADM-ECHUS : les acces echus).
  final VoidCallback? onPressDroite;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = palette.surfaceRaised;
    Widget compteur((int, String) c, VoidCallback? onPress) {
      final Widget bloc = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${c.$1}',
            style: AppTypography.tabulaire(
              paire.applyTo(textes.headlineMedium ?? const TextStyle()),
            ),
          ),
          Ecart.vXs,
          TexteSansCoupure(
            c.$2,
            // Le libelle d'un lien prend l'encre d'accent, comme les noms
            // de l'apercu des dossiers.
            style: onPress == null
                ? paire.applyTo(textes.labelMedium ?? const TextStyle())
                : palette.inkAccent.applyTo(
                    textes.labelMedium ?? const TextStyle(),
                  ),
          ),
        ],
      );
      return Expanded(
        child: onPress == null
            ? Semantics(
                label: '${c.$1} ${c.$2}',
                child: ExcludeSemantics(child: bloc),
              )
            : Pressable(
                onPress: onPress,
                lien: true,
                libelleSemantique: '${c.$1} ${c.$2}',
                child: SizedBox(width: double.infinity, child: bloc),
              ),
      );
    }

    return AppCard(
      surface: paire,
      marge: AppSpacing.lg,
      child: ContenuTuileBento(
        children: <Widget>[
          if (titre != null)
            Semantics(
              header: true,
              child: TexteSansCoupure(
                titre!,
                style: paire.applyTo(textes.labelLarge ?? const TextStyle()),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              compteur(gauche, onPressGauche),
              Ecart.hLg,
              compteur(droite, onPressDroite),
            ],
          ),
        ],
      ),
    );
  }
}
