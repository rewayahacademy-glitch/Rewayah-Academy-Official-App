import 'dart:math' as math;

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
/// [etendue] vaut sur la grille de deux colonnes ou moins (telephone, texte
/// tres agrandi) ; [etendueLarge], quand elle est donnee, vaut a trois
/// colonnes et plus (tablette, ordinateur, palier a 3 du texte agrandi),
/// ramenee par [placerBento] a la largeur de la grille. Le contenu ne porte
/// jamais sa propre hauteur : c'est la grille qui la fixe.
@immutable
class TuileBento {
  /// Cree une tuile.
  const TuileBento({
    required this.etendue,
    required this.child,
    this.etendueLarge,
  });

  /// L'etendue sur deux colonnes ou moins.
  final EtendueBento etendue;

  /// L'etendue a trois colonnes et plus, sinon [etendue].
  final EtendueBento? etendueLarge;

  /// Le contenu, qui remplit toute la tuile.
  final Widget child;

  /// L'etendue retenue pour [colonnes].
  EtendueBento pour(int colonnes) =>
      colonnes >= 3 ? (etendueLarge ?? etendue) : etendue;
}

/// Largeur minimale (texte 100 %) de la carte classe pour qu'elle partage sa
/// bande avec « Avant le prochain cours » (BENTO-2b, revue BENTO-2-R M1) :
/// a 310 px, la colonne « Duree » coupait « Duré/e » et « 45 mi/n ». Elle
/// croit avec l'echelle du texte. Cote a cote des que la grille fait
/// 736 px x echelle (2 x 360 + l'ecart) : a texte 100 %, ecran de 864 px
/// avec le rail replie (80 px, gouttieres 2 x 24), 1040 px avec la barre
/// laterale depliee ; dessous (tablette de 600 a 863 px, texte agrandi),
/// pleine largeur. Les bascules 863/864, 1024 et 1440 x2 sont mesurees par
/// `accueil_famille_test.dart` (BENTO-2c), sans autre source.
///
/// Partagee par l'accueil famille (BENTO-2b) et l'accueil adulte (BENTO-3),
/// qui comparent chaque moitie de grille a cette largeur x echelle du texte
/// (revue BENTO-3b-R m5, BENTO-3c). Sur l'accueil adulte, la grille fait
/// l'ecran moins 128 px : bascule entre 863 et 864 px a texte 100 %, et
/// empilement a 1440 px texte x2, mesures par `accueil_adulte_page_test.dart`.
const double largeurMinCarteClasse = 360;

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
///   (telephone), quatre au-dela (tablette et ordinateur). Texte agrandi
///   seulement : tant qu'une colonne est plus etroite que
///   [largeurMinCellule] multipliee par l'echelle du texte, la grille perd
///   une colonne : 4, 3, 2, puis 1 (BENTO-1b, BENTO-1c). C'est la largeur
///   UTILE par colonne qui decide, jamais l'echelle seule : a 1440 px et
///   texte double, la grille garde plusieurs colonnes et ses tailles variees.
/// * **Ecart** : 16 px entre tuiles, dans les deux sens (K-55).
/// * **Hauteur** : une ligne vaut [hauteurLigne] multipliee par l'echelle du
///   texte quand elle depasse 1 ([hauteurLignePour]) ; une tuile `1 x 2` vaut
///   deux lignes plus un ecart.
/// * **Une colonne** : la grille repasse en une colonne de hauteur libre,
///   dans l'ordre declare. Le contenu ne deborde donc jamais d'une hauteur
///   fixe (320 px et texte double).
/// * **Hauteur du contenu** ([hauteurContenu], BENTO-2) : pour les accueils
///   dont les cartes portent des listes, des boutons et des frises, la place
///   des tuiles (colonnes, ordre) vient de [placerBento], mais chaque tuile
///   prend la hauteur de son contenu, jamais une hauteur fixe : rien n'est
///   reduit ni coupe. Les tuiles s'alignent en haut de leur bande.
class GrilleBento extends StatelessWidget {
  /// Cree la grille.
  const GrilleBento({
    required this.tuiles,
    this.hauteurContenu = false,
    super.key,
  });

  /// Les tuiles, dans l'ordre d'importance.
  final List<TuileBento> tuiles;

  /// Vrai : chaque tuile prend la hauteur de son contenu au lieu de
  /// [hauteurLigne] par ligne couverte.
  final bool hauteurContenu;

  /// Le jeton de hauteur d'une ligne de grille.
  static const double hauteurLigne = 160;

  /// L'ecart entre deux tuiles (K-55).
  static const double ecart = AppSpacing.lg;

  /// Largeur offerte a partir de laquelle la grille passe a quatre colonnes.
  static const double seuilQuatreColonnes = 600;

  /// Largeur utile minimale d'une colonne, multipliee par l'echelle du texte
  /// quand elle depasse 1 (sans effet a 100 % ou moins). 112 garde quatre
  /// colonnes a 600 px et texte 115 % (138 >= 128,8) et donne une colonne a
  /// 320 px et texte double. Valeur sans source externe : a faire valider
  /// par le directeur.
  static const double largeurMinCellule = 112;

  /// Le nombre de colonnes pour une largeur offerte et une echelle de texte :
  /// 4 ou 2 selon la largeur. Texte agrandi seulement : une colonne de moins
  /// (4, 3, 2, 1) tant que la largeur utile par colonne est sous
  /// `largeurMinCellule x echelle`. A trois colonnes, les tuiles prennent
  /// leur [TuileBento.etendueLarge] : la grande tuile 2x2 reste la ou deux
  /// colonnes la reduiraient (BENTO-1c). A texte 100 % ou moins, rien ne
  /// change, meme dans une place etroite ; une place sans largeur utile
  /// (premiere image, panneau qui s'ouvre) donne une colonne.
  static int colonnesPour(double largeur, [double echelle = 1]) {
    if (largeur <= ecart) return 1;
    int colonnes = largeur >= seuilQuatreColonnes ? 4 : 2;
    if (echelle <= 1) return colonnes;
    final double minimum = largeurMinCellule * echelle;
    while (colonnes > 1 &&
        (largeur - ecart * (colonnes - 1)) / colonnes < minimum) {
      colonnes--;
    }
    return colonnes;
  }

  /// La hauteur d'une ligne de grille a cette echelle de texte : le texte
  /// agrandi garde sa place au lieu d'etre reduit.
  static double hauteurLignePour(double echelle) =>
      hauteurLigne * math.max(1, echelle);

  @override
  Widget build(BuildContext context) {
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) =>
          _grille(contraintes.maxWidth, echelle),
    );
  }

  Widget _grille(double largeur, double echelle) {
    final int colonnes = colonnesPour(largeur, echelle);
    if (colonnes == 1) {
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
    final double hauteur = hauteurLignePour(echelle);
    final double cellule = (largeur - ecart * (colonnes - 1)) / colonnes;
    // Les etendues se replient sur le nombre de colonnes retenu : celle de
    // quatre colonnes ne vaut qu'a quatre, et `placerBento` ramene une tuile
    // trop large a la largeur de la grille.
    final List<PlacementBento> places = placerBento(<EtendueBento>[
      for (final TuileBento t in tuiles) t.pour(colonnes),
    ], colonnes);
    if (hauteurContenu) {
      return _bloc(
        <int>[for (int i = 0; i < tuiles.length; i++) i],
        places,
        cellule,
      );
    }
    int lignes = 0;
    for (final PlacementBento p in places) {
      if (p.ligne + p.lignes > lignes) lignes = p.ligne + p.lignes;
    }
    return SizedBox(
      height: lignes == 0 ? 0 : lignes * hauteur + (lignes - 1) * ecart,
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < tuiles.length; i++)
            PositionedDirectional(
              start: places[i].colonne * (cellule + ecart),
              top: places[i].ligne * (hauteur + ecart),
              width:
                  places[i].colonnes * cellule +
                  (places[i].colonnes - 1) * ecart,
              height:
                  places[i].lignes * hauteur + (places[i].lignes - 1) * ecart,
              child: tuiles[i].child,
            ),
        ],
      ),
    );
  }

  /// [hauteurContenu] : decoupe les tuiles [ids] en bandes, sans hauteur
  /// fixe. D'abord une coupe horizontale qu'aucune tuile ne traverse (bande
  /// du dessus, puis celle du dessous), sinon une coupe verticale (debut de
  /// lecture, puis fin) ; chaque part a la largeur exacte de ses colonnes.
  /// Une disposition en moulinet, qui n'admet aucune coupe, se lit en une
  /// colonne dans l'ordre declare : rien n'est perdu.
  Widget _bloc(List<int> ids, List<PlacementBento> places, double cellule) {
    if (ids.length == 1) return tuiles[ids.single].child;
    int haut = 1 << 30, bas = 0, debut = 1 << 30, fin = 0;
    for (final int i in ids) {
      final PlacementBento p = places[i];
      haut = math.min(haut, p.ligne);
      bas = math.max(bas, p.ligne + p.lignes);
      debut = math.min(debut, p.colonne);
      fin = math.max(fin, p.colonne + p.colonnes);
    }
    double largeur(int colonnes) => colonnes * cellule + (colonnes - 1) * ecart;

    for (int y = haut + 1; y < bas; y++) {
      final List<int> dessus = <int>[
        for (final int i in ids)
          if (places[i].ligne + places[i].lignes <= y) i,
      ];
      final List<int> dessous = <int>[
        for (final int i in ids)
          if (places[i].ligne >= y) i,
      ];
      if (dessus.length + dessous.length == ids.length) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _bloc(dessus, places, cellule),
            const SizedBox(height: ecart),
            _bloc(dessous, places, cellule),
          ],
        );
      }
    }
    for (int x = debut + 1; x < fin; x++) {
      final List<int> avant = <int>[
        for (final int i in ids)
          if (places[i].colonne + places[i].colonnes <= x) i,
      ];
      final List<int> apres = <int>[
        for (final int i in ids)
          if (places[i].colonne >= x) i,
      ];
      if (avant.length + apres.length == ids.length) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: largeur(x - debut),
              child: _bloc(avant, places, cellule),
            ),
            const SizedBox(width: ecart),
            SizedBox(
              width: largeur(fin - x),
              child: _bloc(apres, places, cellule),
            ),
          ],
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int k = 0; k < ids.length; k++) ...<Widget>[
          if (k > 0) const SizedBox(height: ecart),
          tuiles[ids[k]].child,
        ],
      ],
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
