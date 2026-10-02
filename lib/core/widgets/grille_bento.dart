import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// L'etendue d'une tuile : combien de colonnes et de lignes elle couvre.
///
/// `2 x 1` est une tuile large, `1 x 2` une tuile haute, `1 x 1` un carre,
/// `2 x 2` une grande tuile. La taille suit l'importance du contenu (BENTO-1).
@immutable
class EtendueBento {
  /// Cree une etendue.
  const EtendueBento(this.colonnes, this.lignes)
    : assert(colonnes > 0 && lignes > 0, 'etendue nulle');

  /// Une tuile carree.
  static const EtendueBento carree = EtendueBento(1, 1);

  /// Une tuile large.
  static const EtendueBento large = EtendueBento(2, 1);

  /// Une tuile haute.
  static const EtendueBento haute = EtendueBento(1, 2);

  /// Une grande tuile.
  static const EtendueBento grande = EtendueBento(2, 2);

  /// Colonnes couvertes.
  final int colonnes;

  /// Lignes couvertes.
  final int lignes;

  @override
  bool operator ==(Object other) =>
      other is EtendueBento &&
      other.colonnes == colonnes &&
      other.lignes == lignes;

  @override
  int get hashCode => Object.hash(colonnes, lignes);

  @override
  String toString() => '${colonnes}x$lignes';
}

/// Une tuile de [GrilleBento].
///
/// [etendue] vaut sur la grille de deux colonnes (telephone) ;
/// [etendueLarge], quand elle est donnee, vaut sur la grille de quatre
/// (tablette et ordinateur). Le contenu ne porte jamais sa propre hauteur :
/// c'est la grille qui la fixe.
@immutable
class TuileBento {
  /// Cree une tuile.
  const TuileBento({
    required this.etendue,
    required this.child,
    this.etendueLarge,
  });

  /// L'etendue sur deux colonnes.
  final EtendueBento etendue;

  /// L'etendue sur quatre colonnes, sinon [etendue].
  final EtendueBento? etendueLarge;

  /// Le contenu, qui remplit toute la tuile.
  final Widget child;

  /// L'etendue retenue pour [colonnes].
  EtendueBento pour(int colonnes) =>
      colonnes >= 4 ? (etendueLarge ?? etendue) : etendue;
}

/// La place d'une tuile, en cellules de la grille.
@immutable
class PlacementBento {
  /// Cree une place.
  const PlacementBento(this.colonne, this.ligne, this.colonnes, this.lignes);

  /// Premiere colonne (depuis le debut de lecture).
  final int colonne;

  /// Premiere ligne.
  final int ligne;

  /// Colonnes couvertes.
  final int colonnes;

  /// Lignes couvertes.
  final int lignes;

  @override
  bool operator ==(Object other) =>
      other is PlacementBento &&
      other.colonne == colonne &&
      other.ligne == ligne &&
      other.colonnes == colonnes &&
      other.lignes == lignes;

  @override
  int get hashCode => Object.hash(colonne, ligne, colonnes, lignes);

  @override
  String toString() => '($colonne,$ligne ${colonnes}x$lignes)';
}

/// Place les tuiles sans chevauchement et sans trou. Fonction pure.
///
/// 1. Chaque tuile, dans l'ordre, prend la premiere cellule libre (ligne par
///    ligne, puis colonne par colonne) ou elle tient. Une etendue plus large
///    que la grille est ramenee a sa largeur.
/// 2. Les trous restants sont combles en etirant une voisine : la tuile a
///    gauche s'elargit, sinon celle du dessus s'allonge. Aucune case vide ne
///    reste, et le resultat ne depend que de l'ordre et des etendues.
List<PlacementBento> placerBento(List<EtendueBento> etendues, int colonnes) {
  final List<List<int>> grille = <List<int>>[];
  final List<PlacementBento> places = <PlacementBento>[];

  bool libre(int c, int l, int lc, int ll) {
    for (int y = l; y < l + ll; y++) {
      for (int x = c; x < c + lc; x++) {
        if (y < grille.length && grille[y][x] != -1) return false;
      }
    }
    return true;
  }

  void occuper(int index, PlacementBento p) {
    while (grille.length < p.ligne + p.lignes) {
      grille.add(List<int>.filled(colonnes, -1));
    }
    for (int y = p.ligne; y < p.ligne + p.lignes; y++) {
      for (int x = p.colonne; x < p.colonne + p.colonnes; x++) {
        grille[y][x] = index;
      }
    }
  }

  for (int i = 0; i < etendues.length; i++) {
    final int lc = etendues[i].colonnes.clamp(1, colonnes);
    final int ll = etendues[i].lignes;
    PlacementBento? trouve;
    for (int l = 0; trouve == null; l++) {
      for (int c = 0; c + lc <= colonnes; c++) {
        if (libre(c, l, lc, ll)) {
          trouve = PlacementBento(c, l, lc, ll);
          break;
        }
      }
    }
    places.add(trouve);
    occuper(i, trouve);
  }

  // Combler les trous, de haut en bas.
  bool change = true;
  while (change) {
    change = false;
    for (int y = 0; y < grille.length && !change; y++) {
      for (int x = 0; x < colonnes && !change; x++) {
        if (grille[y][x] != -1) continue;
        // a) La tuile de gauche s'elargit si toute sa hauteur est libre ici.
        if (x > 0) {
          final int g = grille[y][x - 1];
          final PlacementBento p = places[g];
          if (p.colonne + p.colonnes == x && libre(x, p.ligne, 1, p.lignes)) {
            places[g] = PlacementBento(
              p.colonne,
              p.ligne,
              p.colonnes + 1,
              p.lignes,
            );
            occuper(g, places[g]);
            change = true;
            continue;
          }
        }
        // b) Sinon la tuile du dessus s'allonge si toute sa largeur est libre.
        if (y > 0) {
          final int h = grille[y - 1][x];
          if (h != -1) {
            final PlacementBento p = places[h];
            if (p.ligne + p.lignes == y && libre(p.colonne, y, p.colonnes, 1)) {
              places[h] = PlacementBento(
                p.colonne,
                p.ligne,
                p.colonnes,
                p.lignes + 1,
              );
              occuper(h, places[h]);
              change = true;
              continue;
            }
          }
        }
        // c) Sinon la tuile de droite s'elargit vers la gauche.
        if (x + 1 < colonnes) {
          final int d = grille[y][x + 1];
          if (d != -1) {
            final PlacementBento p = places[d];
            if (p.colonne == x + 1 && libre(x, p.ligne, 1, p.lignes)) {
              places[d] = PlacementBento(x, p.ligne, p.colonnes + 1, p.lignes);
              occuper(d, places[d]);
              change = true;
            }
          }
        }
      }
    }
  }
  return places;
}

/// La grille Bento partagee de tous les tableaux de bord (BENTO-1).
///
/// Des tuiles de tailles variees (larges, hautes, carrees, grandes) qui
/// s'imbriquent sans trou, jamais un damier de carres identiques.
///
/// * **Colonnes** : deux sous [seuilQuatreColonnes] de largeur offerte
///   (telephone), quatre au-dela (tablette et ordinateur).
/// * **Ecart** : 16 px entre tuiles, dans les deux sens (K-55).
/// * **Hauteur** : une ligne vaut [hauteurLigne] ; une tuile `1 x 2` vaut deux
///   lignes plus un ecart.
/// * **Texte agrandi** : au-dela de [seuilUneColonne], la grille repasse en
///   une seule colonne de hauteur libre, dans l'ordre declare. Le contenu ne
///   deborde donc jamais d'une hauteur fixe.
class GrilleBento extends StatelessWidget {
  /// Cree la grille.
  const GrilleBento({required this.tuiles, super.key});

  /// Les tuiles, dans l'ordre d'importance.
  final List<TuileBento> tuiles;

  /// Le jeton de hauteur d'une ligne de grille.
  static const double hauteurLigne = 160;

  /// L'ecart entre deux tuiles (K-55).
  static const double ecart = AppSpacing.lg;

  /// Largeur offerte a partir de laquelle la grille passe a quatre colonnes.
  static const double seuilQuatreColonnes = 600;

  /// Echelle de texte au-dela de laquelle la grille passe en une colonne.
  static const double seuilUneColonne = 1.15;

  /// Le nombre de colonnes pour une largeur offerte.
  static int colonnesPour(double largeur) =>
      largeur >= seuilQuatreColonnes ? 4 : 2;

  @override
  Widget build(BuildContext context) {
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    if (echelle > seuilUneColonne) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < tuiles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: ecart),
            tuiles[i].child,
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double largeur = contraintes.maxWidth;
        final int colonnes = colonnesPour(largeur);
        final double cellule = (largeur - ecart * (colonnes - 1)) / colonnes;
        final List<PlacementBento> places = placerBento(<EtendueBento>[
          for (final TuileBento t in tuiles) t.pour(colonnes),
        ], colonnes);
        int lignes = 0;
        for (final PlacementBento p in places) {
          if (p.ligne + p.lignes > lignes) lignes = p.ligne + p.lignes;
        }
        return SizedBox(
          height: lignes == 0
              ? 0
              : lignes * hauteurLigne + (lignes - 1) * ecart,
          child: Stack(
            children: <Widget>[
              for (int i = 0; i < tuiles.length; i++)
                PositionedDirectional(
                  start: places[i].colonne * (cellule + ecart),
                  top: places[i].ligne * (hauteurLigne + ecart),
                  width:
                      places[i].colonnes * cellule +
                      (places[i].colonnes - 1) * ecart,
                  height:
                      places[i].lignes * hauteurLigne +
                      (places[i].lignes - 1) * ecart,
                  child: tuiles[i].child,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Le contenu d'une tuile de [GrilleBento] : il remplit la hauteur de la
/// tuile (le chiffre en haut, le libelle en bas) et **ne deborde jamais**.
///
/// Dans une tuile de hauteur fixe, une colonne trop haute (police tres large,
/// libelle long) est reduite d'un bloc juste assez pour tenir, sans ellipse ni
/// mot coupe. En une colonne de hauteur libre (texte agrandi), elle garde sa
/// taille naturelle.
class ContenuTuileBento extends StatelessWidget {
  /// Cree le contenu.
  const ContenuTuileBento({required this.children, super.key});

  /// Les lignes du contenu, de haut en bas.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) {
      final Widget colonne = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      );
      if (!c.hasBoundedHeight || !c.hasBoundedWidth) return colonne;
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: c.maxWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: colonne,
          ),
        ),
      );
    },
  );
}
