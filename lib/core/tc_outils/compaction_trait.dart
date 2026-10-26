import 'dart:math' as math;

import '../tc_bibliotheque/content_position.dart';
import 'annotation_layer.dart';
import 'intention_pedagogique.dart';

/// Simplifie une ligne polygonale en gardant sa forme.
///
/// Algorithme de Ramer-Douglas-Peucker, ecrit ici plutot qu'importe : il tient
/// en trente lignes, et ajouter une dependance pour cela serait exactement le
/// genre de dette que `pubspec.yaml` est gele pour eviter.
///
/// [tolerance] est exprimee dans le repere **normalise** du bloc ancre : 0.004
/// vaut quatre millienes de la largeur du bloc, soit moins d'un pixel sur un
/// verset rendu a 250 points de large. En dessous, deux points ne se
/// distinguent plus a l'oeil, mais ils pesent tous les deux dans le message.
List<PointNormalise> simplifierTrait(
  List<PointNormalise> points, {
  double tolerance = toleranceCompaction,
}) {
  if (points.length <= 2 || tolerance <= 0) {
    return List<PointNormalise>.unmodifiable(points);
  }
  final List<PointNormalise> retenus = <PointNormalise>[];
  _rdp(points, 0, points.length - 1, tolerance, retenus);
  retenus.add(points.last);
  return List<PointNormalise>.unmodifiable(retenus);
}

/// La tolerance de compaction par defaut, dans le repere normalise du bloc.
const double toleranceCompaction = 0.004;

void _rdp(
  List<PointNormalise> points,
  int debut,
  int fin,
  double tolerance,
  List<PointNormalise> sortie,
) {
  double pireEcart = 0;
  int pire = debut;
  for (int i = debut + 1; i < fin; i++) {
    final double ecart = _distanceAuSegment(points[i], points[debut], points[fin]);
    if (ecart > pireEcart) {
      pireEcart = ecart;
      pire = i;
    }
  }
  if (pireEcart > tolerance) {
    _rdp(points, debut, pire, tolerance, sortie);
    _rdp(points, pire, fin, tolerance, sortie);
  } else {
    sortie.add(points[debut]);
  }
}

double _distanceAuSegment(
  PointNormalise point,
  PointNormalise a,
  PointNormalise b,
) {
  final double dx = b.x - a.x;
  final double dy = b.y - a.y;
  final double longueur = dx * dx + dy * dy;
  if (longueur == 0) {
    return math.sqrt(
      math.pow(point.x - a.x, 2) + math.pow(point.y - a.y, 2),
    ).toDouble();
  }
  double t = ((point.x - a.x) * dx + (point.y - a.y) * dy) / longueur;
  t = t.clamp(0, 1);
  final double projX = a.x + t * dx;
  final double projY = a.y + t * dy;
  return math.sqrt(
    math.pow(point.x - projX, 2) + math.pow(point.y - projY, 2),
  ).toDouble();
}

/// Un trait en cours de trace.
///
/// **Deux regimes, et c'est tout l'objet de cette classe** (spec section 8.3) :
///
/// - *pendant* le geste, on emet des paquets legers -- uniquement les points
///   nouveaux depuis le dernier envoi, sur le canal ephemere, ou une perte ne
///   coute qu'un frisson de latence ;
/// - *a la fin* du trait, on emet une version compacte et stable, sur le canal
///   fiable, et c'est elle seule qui sera conservee.
///
/// L'accumulateur ne connait ni LiveKit ni le realtime : il rend des donnees.
/// C'est `evenements_outils.dart` qui les confie au transport d'Agent F.
class TraitEnCours {
  /// Ouvre un trait.
  TraitEnCours({
    required this.ancrage,
    required this.outil,
    this.intention,
    this.epaisseur,
    this.couleur,
    this.pointsParPaquet = pointsParPaquetParDefaut,
  }) : assert(pointsParPaquet > 0, 'un paquet porte au moins un point');

  /// Nombre de points accumules avant qu'un paquet ephemere soit propose.
  ///
  /// Trois points : assez pour que le trait avance visiblement chez les autres,
  /// assez peu pour ne pas dessiner en retard. C'est un reglage de confort, pas
  /// une regle metier.
  static const int pointsParPaquetParDefaut = 3;

  /// L'ancrage du trait.
  final ContentPosition ancrage;

  /// L'outil employe.
  final OutilTrait outil;

  /// L'intention portee, quand il y en a une.
  final IntentionPedagogique? intention;

  /// TB-7b : l'epaisseur choisie, `null` = moyenne.
  final EpaisseurTrait? epaisseur;

  /// Plan de la salle du 26/10/2026 : la couleur franche, ou `null`.
  final CouleurFranche? couleur;

  /// Le seuil d'emission d'un paquet ephemere.
  final int pointsParPaquet;

  final List<PointNormalise> _points = <PointNormalise>[];
  final List<double> _pressions = <double>[];
  final List<double> _inclinaisons = <double>[];
  int _dejaEmis = 0;

  /// Le nombre de points accumules.
  int get nombreDePoints => _points.length;

  /// Vrai quand assez de points nouveaux se sont accumules pour un paquet.
  bool get paquetPret => _points.length - _dejaEmis >= pointsParPaquet;

  /// Ajoute un point au trait.
  ///
  /// [pression] et [inclinaison] sont **facultatives** : un ecran sans capteur
  /// ne les fournit pas, et rien dans la suite ne les rend obligatoires.
  void ajouter(
    PointNormalise point, {
    double? pression,
    double? inclinaison,
  }) {
    _points.add(point);
    if (pression != null) {
      _pressions.add(pression);
    }
    if (inclinaison != null) {
      _inclinaisons.add(inclinaison);
    }
  }

  /// Les points nouveaux depuis le dernier appel, et les marque comme emis.
  ///
  /// Rend une liste vide quand rien n'est nouveau : l'appelant n'emet alors
  /// rien du tout, plutot qu'un paquet vide sur le fil.
  List<PointNormalise> prendrePaquet() {
    if (_dejaEmis >= _points.length) {
      return const <PointNormalise>[];
    }
    final List<PointNormalise> paquet = List<PointNormalise>.unmodifiable(
      _points.sublist(_dejaEmis),
    );
    _dejaEmis = _points.length;
    return paquet;
  }

  /// Ferme le trait et rend sa version compacte et stable.
  ///
  /// La pression et l'inclinaison rendues sont les **moyennes** des
  /// echantillons recus, et restent `null` si le materiel n'en a fourni aucun.
  /// Le contrat ne porte qu'une valeur par trait : garder la derniere ferait
  /// dependre l'epaisseur du trait de la maniere dont le stylet a ete releve.
  TraitVectoriel terminer({
    required String id,
    double tolerance = toleranceCompaction,
  }) => TraitVectoriel(
    id: id,
    ancrage: ancrage,
    points: simplifierTrait(_points, tolerance: tolerance),
    outil: outil,
    intention: intention,
    pression: _moyenne(_pressions),
    inclinaison: _moyenne(_inclinaisons),
    epaisseur: epaisseur,
    couleur: couleur,
  );

  static double? _moyenne(List<double> valeurs) {
    if (valeurs.isEmpty) {
      return null;
    }
    double somme = 0;
    for (final double valeur in valeurs) {
      somme += valeur;
    }
    return somme / valeurs.length;
  }
}
