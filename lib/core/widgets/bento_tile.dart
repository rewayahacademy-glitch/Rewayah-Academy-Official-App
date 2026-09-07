import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import 'pressable.dart';

/// La largeur d'une tuile dans la grille.
enum TailleBento {
  /// Toute la largeur.
  pleine(1),

  /// Une demie.
  demie(1 / 2),

  /// Un tiers.
  tiers(1 / 3),

  /// Un quart.
  quart(1 / 4);

  const TailleBento(this.fraction);

  /// La fraction de largeur occupee.
  final double fraction;
}

/// Un bloc de grille Bento.
///
/// Seul bloc de grille de l'application : aucun ecran ne redefinit sa propre
/// carte. La cible tactile suit le mode d'interface, 72pt en mode enfant et
/// 44pt en mode standard, sans que l'ecran ait a le savoir
/// (`docs/architecture/etape-2-core-flutter.md` section 2).
class BentoTile extends StatelessWidget {
  /// Cree une tuile.
  const BentoTile({
    required this.child,
    super.key,
    this.taille = TailleBento.pleine,
    this.surface,
    this.onPress,
    this.libelleSemantique,
    this.avecBordure = false,
  });

  /// Le contenu de la tuile.
  final Widget child;

  /// La largeur occupee dans la grille.
  final TailleBento taille;

  /// La paire de couleurs de la tuile. Par defaut, le fond general.
  ///
  /// C'est une paire : impossible de poser un fond sans son texte.
  final AppColorPair? surface;

  /// Action au tap. Passe par [Pressable], jamais par un `onTap` nu.
  final VoidCallback? onPress;

  /// Libelle lu par les technologies d'assistance.
  final String? libelleSemantique;

  /// Ajoute le filet de contour de la tuile. Il est decoratif et ne porte
  /// jamais de sens a lui seul : une selection ou une erreur passe par
  /// `borderStrong` ou par une couleur semantique
  /// (`docs/produit/design-tokens.md` section 1.3).
  final bool avecBordure;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final AppColorPair paire = surface ?? palette.surfaceCanvas;

    final Widget corps = Container(
      constraints: BoxConstraints(minHeight: metriques.cibleTactile),
      padding: EdgeInsets.all(metriques.marge),
      decoration: paire.decoration(
        borderRadius: metriques.arrondi,
        side: avecBordure ? palette.borderHairline.asBorderSide() : null,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: paire.onBackground),
        child: IconTheme.merge(
          data: IconThemeData(color: paire.onBackground),
          child: child,
        ),
      ),
    );

    if (onPress == null) {
      return corps;
    }

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelleSemantique,
      respecterCibleTactile: false,
      child: corps,
    );
  }
}
