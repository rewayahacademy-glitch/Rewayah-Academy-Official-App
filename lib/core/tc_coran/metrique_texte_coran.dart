import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../coran/service_coran.dart';

/// Ce que le renderer recalcule a chaque largeur et a chaque zoom.
///
/// **Ce n'est pas un `Transform.scale`.** Un facteur d'echelle applique a un
/// bloc deja compose agrandit aussi ses debordements, et plus le zoom monte,
/// plus le texte sort du cadre. Ici, la largeur de colonne, la taille de
/// caractere, l'interligne et le nombre de lignes sont **recalcules** a partir
/// de la place reellement disponible.
///
/// La taille est ensuite **bornee par la geometrie de la colonne**, pour une
/// raison qui n'est pas technique : au dela de cette borne, le plus long mot du
/// corpus ne tient plus sur une ligne, et le moteur de texte le couperait en
/// deux. **On ne coupe pas un mot du texte revele au milieu.** Le zoom demande
/// est donc reduit, et [zoomBride] le dit a l'ecran, qui le dit a l'usager --
/// plutot que de laisser l'usager decouvrir la coupure lui-meme.
///
/// Les deux constantes d'avance de glyphe sont des **majorants conservateurs**,
/// pas des mesures de la police : elles servent uniquement a garantir la borne,
/// et c'est le moteur de texte de Flutter qui compose reellement.
@immutable
class MetriqueTexteCoran {
  const MetriqueTexteCoran._({
    required this.largeurColonne,
    required this.tailleTexte,
    required this.interligne,
    required this.echelleRosace,
    required this.zoomDemande,
    required this.zoomApplique,
  });

  /// Calcule les metriques d'une colonne de texte coranique.
  ///
  /// [largeurDisponible] est la place brute ; [marge] en est retiree deux fois.
  /// [largeurMaximaleColonne] borne la mesure sur les grands ecrans : un
  /// paragraphe pose sur 1400 points ne se lit pas, il se survole.
  factory MetriqueTexteCoran.calculer({
    required double largeurDisponible,
    required double zoom,
    double marge = 0,
    double? largeurMaximaleColonne,
  }) {
    final double utile = math.max(0, largeurDisponible - marge * 2);
    final double colonne = largeurMaximaleColonne == null
        ? utile
        : math.min(utile, largeurMaximaleColonne);

    final double zoomBorne = zoom.clamp(
      PositionLecture.zoomMin,
      PositionLecture.zoomMax,
    );

    // 1. La taille de reference vient de la COLONNE, pas de l'appareil : une
    //    colonne deux fois plus large porte un texte deux fois plus grand, donc
    //    la meme mesure, donc les memes reperes de lecture. Elle est bornee aux
    //    deux bouts : sur un tres grand ecran, une taille proportionnelle
    //    donnerait un texte de titre, et le zoom n'aurait plus de course.
    final double base = (colonne / _facteurMesure).clamp(
      _tailleBaseMinimale,
      _tailleBaseMaximale,
    );

    // 2. La borne d'integrite du mot. Elle remplace le clamp arbitraire de
    //    l'ecran actuel (0,8 a 2,4), qui ne dependait d'aucune largeur : le
    //    meme zoom y donnait un texte confortable sur tablette et un texte
    //    coupe sur un petit telephone.
    final double plafond = colonne / largeurMotLePlusLongEnEm;

    // Le plancher cede devant le plafond, jamais l'inverse : sur une colonne
    // minuscule, mieux vaut un texte trop petit qui tient qu'un texte lisible
    // qui coupe les mots.
    final double plancher = math.min(_tailleMinimale, plafond);
    final double taille = (base * zoomBorne).clamp(plancher, plafond);

    return MetriqueTexteCoran._(
      largeurColonne: colonne,
      tailleTexte: taille,
      interligne: _interlignePour(taille),
      echelleRosace: taille / _tailleReference,
      zoomDemande: zoomBorne,
      zoomApplique: base <= 0 ? zoomBorne : taille / base,
    );
  }

  /// La largeur reellement employee par la colonne de texte.
  final double largeurColonne;

  /// La taille de caractere rendue, en points logiques.
  final double tailleTexte;

  /// Le multiplicateur d'interligne.
  final double interligne;

  /// Le grossissement a donner a la rosace de verset, pour qu'elle suive.
  final double echelleRosace;

  /// Le zoom demande par le lecteur, borne aux valeurs que la base accepte.
  final double zoomDemande;

  /// Le zoom reellement obtenu une fois la borne d'integrite appliquee.
  final double zoomApplique;

  /// Vrai quand la colonne n'a pas pu tenir le zoom demande.
  ///
  /// **Un ecart de plus d'un pour cent**, et non une egalite stricte : deux
  /// doubles issus d'une division ne sont jamais exactement egaux, et une
  /// comparaison exacte afficherait la notice en permanence.
  bool get zoomBride => zoomApplique < zoomDemande * 0.99;

  /// La largeur du plus long mot du corpus, a la taille rendue.
  ///
  /// **L'invariant du mode verset se verifie avec elle** : elle ne depasse
  /// jamais [largeurColonne], a aucune largeur d'ecran et a aucun zoom.
  double get largeurMotLePlusLong => tailleTexte * largeurMotLePlusLongEnEm;

  /// Une estimation du nombre de lignes qu'occuperait un texte.
  ///
  /// Sert au mode focus pour decider si une plage tient sans defilement. C'est
  /// une **estimation majorante**, jamais une mesure : le moteur de texte reste
  /// seul juge de la composition reelle.
  int lignesEstimees(int nombreGlyphes) {
    if (largeurColonne <= 0 || tailleTexte <= 0 || nombreGlyphes <= 0) {
      return 0;
    }
    final double largeurTexte = nombreGlyphes * _avanceGlyphe * tailleTexte;
    return math.max(1, (largeurTexte / largeurColonne).ceil());
  }

  /// La hauteur qu'occuperait un texte de [nombreGlyphes] glyphes.
  double hauteurEstimee(int nombreGlyphes) =>
      lignesEstimees(nombreGlyphes) * tailleTexte * interligne;

  /// La largeur du plus long mot du corpus, exprimee en cadratins.
  ///
  /// Onze lettres porteuses au plus, et une avance majoree a 0,62 cadratin par
  /// lettre : les signes diacritiques du trace uthmani sont des marques
  /// combinantes d'avance nulle et ne comptent pas, mais les lettres larges
  /// (sin, shin, sad) comptent plus que les etroites (ba, ta, nun), donc la
  /// moyenne ne suffit pas pour un majorant.
  static const double largeurMotLePlusLongEnEm = 11 * 0.62;

  /// La mesure visee : environ vingt-huit avances de glyphe par ligne.
  ///
  /// Calibre sur le rendu actuel d'`ELV-04` (26 points sur une colonne de 358
  /// points en 390 de large) pour qu'un lecteur ne voie pas sa taille de texte
  /// changer sous lui a l'arrivee du moteur.
  static const double _facteurMesure = 13.75;

  /// Avance horizontale moyenne d'un glyphe, en fraction de la taille.
  static const double _avanceGlyphe = 0.5;

  /// La taille a laquelle la rosace de verset est dessinee a l'echelle 1.
  static const double _tailleReference = 26;

  /// Sous cette taille, le trace uthmani cesse d'etre lisible.
  ///
  /// Le plancher cede devant le plafond : sur une colonne minuscule, mieux vaut
  /// un texte petit qui tient qu'un texte lisible qui deborde. C'est le
  /// `math.min` du calcul.
  static const double _tailleMinimale = 14;

  /// Les bornes de la taille de reference, avant zoom.
  static const double _tailleBaseMinimale = 18;

  /// Au dela, on lit un titre et non un texte, et le zoom n'a plus de course.
  static const double _tailleBaseMaximale = 34;

  /// L'interligne d'une taille donnee.
  ///
  /// Le trace uthmani porte ses diacritiques haut et bas : il lui faut plus
  /// d'air qu'a un texte latin. L'interligne se resserre quand la taille monte,
  /// parce qu'un interligne proportionnel a une tres grande taille creerait des
  /// bandes vides entre les lignes.
  static double _interlignePour(double taille) =>
      (2.3 - taille / 160).clamp(1.7, 2.3);
}
