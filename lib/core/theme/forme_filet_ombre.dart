import 'package:flutter/widgets.dart';

import 'app_elevation.dart';
import 'app_palette.dart';
import 'app_radius.dart';

/// Le contour d'une surface qui flotte (liste d'un menu) : un filet et les
/// ombres des jetons ([AppElevation]), a la place de l'elevation de Material.
///
/// Les ombres sont peintes **hors** de la forme (la liste reste nette), puis
/// le filet par-dessus le bord. « Une surface elevee porte un filet ET une
/// ombre » ([AppElevation]) ; en sombre, la liste se detache par sa surface et
/// son filet ([AppElevation.dialogue]).
///
/// **Une seule forme pour tous les menus** (LISTES-1, 23/10/2026) : posee par
/// `AppTheme.pour` dans `popupMenuTheme`, elle habille `MenuActions` et
/// `MenuFiltre` sans que l'un ni l'autre n'ait a la repeter. Elle sortait de
/// `menu_filtre.dart` (ONGLETS-COUPE-1), ou elle etait privee : le correctif
/// n'avait ete fait que d'un cote, et les menus d'actions retombaient sur le
/// rectangle de rayon 4 et l'ombre noire de Material.
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class FormeFiletEtOmbre extends ShapeBorder {
  /// Cree la forme.
  const FormeFiletEtOmbre({
    required this.filet,
    required this.ombres,
    required this.arrondi,
  });

  /// La forme d'un menu de la palette [palette] : un filet **franc**
  /// (l'encre attenuee a moitie, ~3:1 contre la ligne qu'il recouvre : le filet
  /// de contour des cartes, a 1,1:1, laissait le menu se confondre avec la
  /// liste, en clair comme en sombre), l'ombre des surfaces qui recouvrent
  /// ([AppElevation.niveau3]) **y compris en sombre** (l'ombre de dialogue y
  /// etait nulle) et le rayon des champs.
  factory FormeFiletEtOmbre.menu(AppPalette palette) => FormeFiletEtOmbre(
    filet: BorderSide(
      color: palette.inkFaint.asBorderSide().color.withValues(alpha: 0.5),
    ),
    ombres: AppElevation.niveau3(palette.ombreDialogue),
    arrondi: AppRadius.arrondiSm,
  );

  /// Le filet du bord.
  final BorderSide filet;

  /// Les ombres, peintes hors de la forme.
  final List<BoxShadow> ombres;

  /// L'arrondi des quatre coins.
  final BorderRadius arrondi;

  RRect _forme(Rect rect, TextDirection? sens) =>
      arrondi.resolve(sens).toRRect(rect);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(filet.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_forme(rect, textDirection).deflate(filet.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_forme(rect, textDirection));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final RRect forme = _forme(rect, textDirection);
    if (ombres.isNotEmpty) {
      canvas
        ..save()
        ..clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect.inflate(rect.shortestSide + rect.longestSide)),
            Path()..addRRect(forme),
          ),
        );
      for (final BoxShadow ombre in ombres) {
        canvas.drawRRect(
          forme.shift(ombre.offset).inflate(ombre.spreadRadius),
          ombre.toPaint(),
        );
      }
      canvas.restore();
    }
    canvas.drawRRect(forme.deflate(filet.strokeInset), filet.toPaint());
  }

  @override
  ShapeBorder scale(double t) => FormeFiletEtOmbre(
    filet: filet.scale(t),
    ombres: <BoxShadow>[for (final BoxShadow o in ombres) o.scale(t)],
    arrondi: arrondi * t,
  );

  @override
  bool operator ==(Object other) =>
      other is FormeFiletEtOmbre &&
      other.filet == filet &&
      other.arrondi == arrondi &&
      _memesOmbres(other.ombres, ombres);

  @override
  int get hashCode => Object.hash(filet, arrondi, Object.hashAll(ombres));
}

bool _memesOmbres(List<BoxShadow> a, List<BoxShadow> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
