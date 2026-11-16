import 'package:flutter/material.dart';

import '../theme/app_elevation.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import 'carte_groupee.dart';

/// UNE carte de lignes (`SettingRow`, `ConfigLigne...`) separees par des
/// filets fins : le groupe d'un meme sujet (K-55, contenus lies).
///
/// Les lignes se posent a l'interieur d'une surface unique, au rayon de
/// `AppCard`. Une [SettingRow] pose dans ce groupe se rend a plat (sans fond
/// ni rayon propres, voir [LigneDansCarte]) : la carte porte la surface, la
/// ligne ne porte que son contenu. Pour des rubriques decrites par donnees
/// (`LigneRubrique`), `GroupeReglages` reste le composant.
class CarteLignes extends StatelessWidget {
  /// Cree le groupe.
  const CarteLignes({required this.lignes, super.key});

  /// Les lignes, de haut en bas.
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: AppElevation.avecFilet(
        surface: palette.surfaceRaised,
        filet: palette.contourCarte,
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiMd,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.arrondiMd,
        child: LigneDansCarte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < lignes.length; i++) ...<Widget>[
                if (i > 0) const FiletCarte(),
                lignes[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dit aux lignes qu'elles sont posees dans une [CarteLignes] : elles se
/// rendent a plat, la surface est celle de la carte.
class LigneDansCarte extends InheritedWidget {
  /// Cree la marque.
  const LigneDansCarte({required super.child, super.key});

  /// Vrai quand [context] est a l'interieur d'une [CarteLignes].
  static bool de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LigneDansCarte>() != null;

  @override
  bool updateShouldNotify(LigneDansCarte ancien) => false;
}

/// UNE ligne d'une carte a lignes fines construite **ligne a ligne** (liste
/// longue, `ListView.builder`) : chacune peint son morceau de la carte blanche
/// (MESSAGERIE-COULEURS, directeur, 16/11/2026 : « le directeur a des centaines
/// de conversations, il a exige la performance »). Coins arrondis en haut pour
/// la [premiere], en bas pour la [derniere], filet entre deux lignes : l'aspect
/// de [CarteLignes], sans perdre la construction a la demande.
class LigneDeCarte extends StatelessWidget {
  /// Cree le morceau de carte portant [child].
  const LigneDeCarte({
    required this.child,
    required this.premiere,
    required this.derniere,
    super.key,
  });

  /// Le contenu de la ligne.
  final Widget child;

  /// Vrai pour la premiere ligne de la carte : coins du haut arrondis.
  final bool premiere;

  /// Vrai pour la derniere ligne de la carte : coins du bas arrondis.
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    const Radius coin = Radius.circular(AppRadius.md);
    final BorderRadius arrondi = BorderRadius.vertical(
      top: premiere ? coin : Radius.zero,
      bottom: derniere ? coin : Radius.zero,
    );
    return CustomPaint(
      painter: FeuilleDeCarte(
        fond: palette.surfaceRaised.background,
        filet: palette.contourCarte.asBorderSide().color,
        rayon: AppRadius.md,
        premiere: premiere,
        derniere: derniere,
      ),
      child: ClipRRect(
        borderRadius: arrondi,
        child: LigneDansCarte(child: child),
      ),
    );
  }
}

/// Le fond et le contour d'un morceau de carte : fond blanc, filets des deux
/// cotes, trait du haut (premiere) ou filet de separation (autres), trait du
/// bas (derniere), coins arrondis seulement aux extremites de la carte.
/// Public pour que les tests de rendu lisent la couleur du fond.
class FeuilleDeCarte extends CustomPainter {
  /// Cree le peintre.
  const FeuilleDeCarte({
    required this.fond,
    required this.filet,
    required this.rayon,
    required this.premiere,
    required this.derniere,
  });

  /// La couleur du fond.
  final Color fond;

  /// La couleur du filet.
  final Color filet;

  /// Le rayon des coins aux extremites de la carte.
  final double rayon;

  /// Premiere ligne de la carte.
  final bool premiere;

  /// Derniere ligne de la carte.
  final bool derniere;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final Radius coin = Radius.circular(rayon);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        r,
        topLeft: premiere ? coin : Radius.zero,
        topRight: premiere ? coin : Radius.zero,
        bottomLeft: derniere ? coin : Radius.zero,
        bottomRight: derniere ? coin : Radius.zero,
      ),
      Paint()..color = fond,
    );
    final Paint trait = Paint()
      ..color = filet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Le trait est trace a l'interieur : un demi-point de retrait.
    const double g = 0.5;
    final double d = size.width - g;
    final double b = size.height - (derniere ? g : 0);
    final double h = premiere ? g : 0;
    final Path p = Path();
    // Cote de debut, du bas vers le haut.
    p.moveTo(g, derniere ? b - rayon : size.height);
    p.lineTo(g, premiere ? h + rayon : 0);
    if (premiere) {
      p.arcToPoint(Offset(g + rayon, h), radius: coin, clockwise: true);
      p.lineTo(d - rayon, h);
      p.arcToPoint(Offset(d, h + rayon), radius: coin, clockwise: true);
    } else {
      p.moveTo(d, 0);
    }
    // Cote de fin, vers le bas.
    p.lineTo(d, derniere ? b - rayon : size.height);
    if (derniere) {
      p.arcToPoint(Offset(d - rayon, b), radius: coin, clockwise: true);
      p.lineTo(g + rayon, b);
      p.arcToPoint(Offset(g, b - rayon), radius: coin, clockwise: true);
    }
    canvas.drawPath(p, trait);
    if (!premiere) {
      // Le filet entre deux lignes.
      canvas.drawLine(const Offset(0, g), Offset(size.width, g), trait);
    }
  }

  @override
  bool shouldRepaint(FeuilleDeCarte ancien) =>
      fond != ancien.fond ||
      filet != ancien.filet ||
      rayon != ancien.rayon ||
      premiere != ancien.premiere ||
      derniere != ancien.derniere;
}
