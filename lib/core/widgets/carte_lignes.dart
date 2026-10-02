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
