import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
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
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 2).
///
/// **Le lot C lui donne sa profondeur.** Jusque la, une tuile etait posee sur
/// `surfaceCanvas`, c'est-a-dire sur la couleur du fond de page, sans ombre et
/// avec un filet optionnel : elle ne se distinguait donc de la page par rien du
/// tout. Elle vit maintenant sur `surfaceRaised`, avec son filet et son ombre,
/// comme toute surface elevee du produit
/// (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 2).
class BentoTile extends StatelessWidget {
  /// Cree une tuile.
  const BentoTile({
    required this.child,
    super.key,
    this.taille = TailleBento.pleine,
    this.surface,
    this.onPress,
    this.libelleSemantique,
    this.contourFort = false,
  });

  /// Le contenu de la tuile.
  final Widget child;

  /// La largeur occupee dans la grille.
  final TailleBento taille;

  /// La paire de couleurs de la tuile. Par defaut, la surface elevee.
  ///
  /// C'est une paire : impossible de poser un fond sans son texte.
  final AppColorPair? surface;

  /// Vrai quand la tuile porte un contour `borderStrong` au repos, sans etre
  /// survolee ni pressee.
  ///
  /// Meme prise que [AppCard.contourFort], et pour la meme raison : il existe
  /// des etats ou une bordure porte du sens en dehors de l'interaction. Le cas
  /// du produit est le bloc imminent d'`ELV-02` sous mouvement reduit, ou la
  /// bordure fixe **remplace** la pulsation supprimee : l'information portee par
  /// la pulsation doit survivre (`docs/archive/2026-09-pre-remise-a-plat/design/04-systeme-mouvement.md`
  /// section 5).
  final bool contourFort;

  /// Action au tap. Passe par [Pressable], jamais par un `onTap` nu.
  final VoidCallback? onPress;

  /// Libelle lu par les technologies d'assistance.
  final String? libelleSemantique;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final AppColorPair paire = surface ?? palette.surfaceRaised;

    if (onPress == null) {
      return _corps(
        palette,
        metriques,
        paire,
        const EtatPression(actif: false),
      );
    }

    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: libelleSemantique,
      respecterCibleTactile: false,
      arrondiFocus: metriques.arrondi,
      constructeur: (BuildContext _, EtatPression etat) =>
          _corps(palette, metriques, paire, etat),
    );
  }

  Widget _corps(
    AppPalette palette,
    AppMetriques metriques,
    AppColorPair paire,
    EtatPression etat,
  ) {
    final bool eveillee = etat.survole || etat.presse;

    return Container(
      constraints: BoxConstraints(minHeight: metriques.cibleTactile),
      padding: EdgeInsets.all(metriques.marge),
      decoration: AppElevation.avecFilet(
        surface: paire,
        // Le filet decoratif au repos, le filet porteur de sens des que la
        // tuile dit quelque chose : contour impose, survolee ou pressee.
        filet: contourFort || eveillee
            ? palette.borderStrong
            : palette.borderHairline,
        ombre: palette.ombre,
        arrondi: metriques.arrondi,
        // Tiles are list/grid content, not floating chrome. Their hierarchy is
        // carried by surface and border; shadows are reserved for one dominant
        // card or a dialog.
        ombres: AppElevation.niveau0,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: paire.onBackground),
        child: IconTheme.merge(
          data: IconThemeData(color: paire.onBackground),
          child: child,
        ),
      ),
    );
  }
}
