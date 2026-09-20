import 'package:flutter/foundation.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import 'intention_pedagogique.dart';

/// La portee d'une couche d'annotation.
///
/// Trois portees, pas une de plus : c'est ce que la spec section 8.3 demande
/// (« temporaire, limitee a la seance, ou enregistree »).
enum PorteeAnnotation {
  /// Le temps de l'explication. Rien n'est conserve.
  temporaire('temporaire'),

  /// Conservee jusqu'a la fin de la seance, puis oubliee.
  seance('seance'),

  /// Conservee, retrouvee a la prochaine ouverture du support.
  enregistree('enregistree');

  const PorteeAnnotation(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit une portee depuis sa valeur SQL. `null` sur valeur inconnue : une
  /// annotation dont la portee est illisible ne doit pas se retrouver
  /// enregistree par defaut.
  static PorteeAnnotation? depuisSql(String? valeur) {
    for (final PorteeAnnotation portee in PorteeAnnotation.values) {
      if (portee.valeurSql == valeur) {
        return portee;
      }
    }
    return null;
  }

  /// Vrai quand la couche doit survivre a la fermeture du support.
  bool get estDurable => this == PorteeAnnotation.enregistree;
}

/// L'outil qui a pose un trait.
///
/// **Trois outils, aucune palette.** La barre du stylet tient en cinq boutons
/// (stylet, surligner, gomme, annuler, plus) : voir spec section 8.4.
enum OutilTrait {
  /// Encre pleine.
  stylet('stylet'),

  /// Encre large et translucide, posee sous le texte.
  surligneur('surligneur'),

  /// Retire ce qu'elle traverse. Ne laisse aucune trace propre.
  gomme('gomme');

  const OutilTrait(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit un outil depuis sa valeur SQL. `null` sur valeur inconnue.
  static OutilTrait? depuisSql(String? valeur) {
    for (final OutilTrait outil in OutilTrait.values) {
      if (outil.valeurSql == valeur) {
        return outil;
      }
    }
    return null;
  }
}

/// Un point d'un trait, en coordonnees **normalisees**.
///
/// Normalisees **relativement au bloc ancre**, pas a l'ecran ni a la page :
/// c'est toute la difference entre une annotation qui suit son verset apres un
/// reflow et une annotation qui reste ou le texte n'est plus. La resolution en
/// pixels vit dans `ancrage_annotation.dart`.
///
/// Rien n'est stocke en pixels, donc **rien ne depend du zoom**, ni de
/// l'orientation de l'appareil, ni de la taille de la fenetre.
@immutable
class PointNormalise {
  /// Cree un point normalise.
  const PointNormalise(this.x, this.y);

  /// Cree un point normalise en ramenant les deux coordonnees dans `[0, 1]`.
  ///
  /// Le geste deborde forcement du bloc de temps en temps : un doigt ou un
  /// stylet ne s'arrete pas au pixel pres. On borne plutot que de refuser, et
  /// plutot que de laisser filer une coordonnee qui peindrait sur le verset
  /// voisin apres un reflow.
  factory PointNormalise.borne(double x, double y) =>
      PointNormalise(x.clamp(0, 1), y.clamp(0, 1));

  /// Abscisse, de 0 a 1, depuis le bord gauche du bloc ancre.
  ///
  /// **Geometrique, et non directionnelle.** Le rectangle du bloc est fourni
  /// par l'hote dans son propre repere : en arabe, il est deja miroite par le
  /// moteur de mise en page. Mesurer depuis le bord gauche du rectangle rend
  /// donc le meme resultat des deux cotes, alors qu'une mesure « depuis le
  /// debut de la lecture » exigerait de connaitre la direction du texte a la
  /// pose **et** au rendu, et se retournerait le jour ou l'une des deux manque.
  final double x;

  /// Ordonnee, de 0 a 1, du haut vers le bas du bloc ancre.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is PointNormalise && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() =>
      'PointNormalise(${x.toStringAsFixed(4)}, ${y.toStringAsFixed(4)})';
}

/// Un trait, en donnees vectorielles.
///
/// **Jamais une copie du support.** Un trait est une liste de points
/// normalises et un ancrage : la ressource d'origine n'est ni relue, ni
/// reecrite, ni dupliquee (invariant 1 du contrat, section 10).
@immutable
class TraitVectoriel {
  /// Cree un trait.
  const TraitVectoriel({
    required this.id,
    required this.ancrage,
    required this.points,
    required this.outil,
    this.intention,
    this.pression,
    this.inclinaison,
  });

  /// L'identifiant du trait.
  final String id;

  /// L'ancrage du trait. **Semantique de preference en mode reflowable.**
  final ContentPosition ancrage;

  /// Les points, normalises relativement au bloc ancre.
  final List<PointNormalise> points;

  /// L'outil employe.
  final OutilTrait outil;

  /// L'intention, quand le trait en porte une. **La couleur en derive.**
  final IntentionPedagogique? intention;

  /// La pression moyenne du geste, `null` si le materiel ne la fournit pas.
  ///
  /// Facultative par construction : rien dans le rendu ne la rend obligatoire,
  /// et un ecran sans capteur de pression dessine exactement le meme trait.
  final double? pression;

  /// L'inclinaison du stylet, `null` si le materiel ne la fournit pas.
  final double? inclinaison;

  /// Le meme trait, avec un autre jeu de points.
  TraitVectoriel avecPoints(List<PointNormalise> nouveaux) => TraitVectoriel(
    id: id,
    ancrage: ancrage,
    points: List<PointNormalise>.unmodifiable(nouveaux),
    outil: outil,
    intention: intention,
    pression: pression,
    inclinaison: inclinaison,
  );

  @override
  bool operator ==(Object other) =>
      other is TraitVectoriel &&
      other.id == id &&
      other.ancrage == ancrage &&
      listEquals(other.points, points) &&
      other.outil == outil &&
      other.intention == intention &&
      other.pression == pression &&
      other.inclinaison == inclinaison;

  @override
  int get hashCode => Object.hash(
    id,
    ancrage,
    Object.hashAll(points),
    outil,
    intention,
    pression,
    inclinaison,
  );
}

/// Un marqueur semantique pose sur une plage.
///
/// **Une metadonnee de plage, pas un dessin** (spec section 8.3). Rien n'est
/// peint dans le support : le rendu compose la plage, l'intention et le texte
/// au moment de l'affichage.
@immutable
class MarqueurSemantique {
  /// Cree un marqueur.
  const MarqueurSemantique({
    required this.id,
    required this.plage,
    required this.intention,
    this.note,
  });

  /// L'identifiant du marqueur.
  final String id;

  /// La plage marquee.
  final ContentRange plage;

  /// L'intention portee par le marqueur.
  final IntentionPedagogique intention;

  /// Une note courte, facultative. **Jamais un formulaire.**
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is MarqueurSemantique &&
      other.id == id &&
      other.plage == plage &&
      other.intention == intention &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, plage, intention, note);
}

/// La couche d'annotation d'un support, independante de la source.
///
/// ```
/// RESSOURCE ORIGINALE IMMUABLE + COUCHE D'ANNOTATION + MARQUEURS = RENDU
/// ```
///
/// La couche ne porte que l'identifiant de la ressource et, quand elle est
/// connue, celui de sa version : **aucun octet du support n'y entre**. C'est ce
/// qui rend vrai l'invariant « une annotation n'altere jamais
/// `resource_version` », et c'est verifiable par lecture du type, pas seulement
/// par lecture du code qui l'emploie.
@immutable
class AnnotationLayer {
  /// Cree une couche d'annotation.
  AnnotationLayer({
    required this.id,
    required this.resourceId,
    required this.auteurProfilId,
    required this.portee,
    required this.majAUtc,
    this.resourceVersionId,
    this.sessionId,
    List<TraitVectoriel> traits = const <TraitVectoriel>[],
    List<MarqueurSemantique> marqueurs = const <MarqueurSemantique>[],
  }) : assert(majAUtc.isUtc, 'tout instant de contrat est en UTC'),
       assert(
         portee != PorteeAnnotation.seance || sessionId != null,
         'une couche de seance sans seance n est pas une couche de seance',
       ),
       traits = List<TraitVectoriel>.unmodifiable(traits),
       marqueurs = List<MarqueurSemantique>.unmodifiable(marqueurs);

  /// L'identifiant de la couche.
  final String id;

  /// La ressource annotee. **Referencee, jamais copiee.**
  final String resourceId;

  /// La version annotee, quand elle est connue.
  final String? resourceVersionId;

  /// La seance, quand la couche appartient a une seance. `null` pour une
  /// couche personnelle, hors classe.
  final String? sessionId;

  /// L'auteur de la couche.
  final String auteurProfilId;

  /// La portee de la couche.
  final PorteeAnnotation portee;

  /// Les traits de la couche, dans l'ordre de pose.
  final List<TraitVectoriel> traits;

  /// Les marqueurs de la couche.
  final List<MarqueurSemantique> marqueurs;

  /// La derniere mise a jour, en UTC.
  final DateTime majAUtc;

  /// Vrai quand la couche ne porte rien.
  bool get estVide => traits.isEmpty && marqueurs.isEmpty;

  /// La meme couche, avec un trait de plus.
  AnnotationLayer avecTrait(TraitVectoriel trait, {required DateTime majAUtc}) =>
      _copie(
        traits: <TraitVectoriel>[...traits, trait],
        majAUtc: majAUtc,
      );

  /// La meme couche, sans le trait [traitId].
  AnnotationLayer sansTrait(String traitId, {required DateTime majAUtc}) =>
      _copie(
        traits: traits
            .where((TraitVectoriel trait) => trait.id != traitId)
            .toList(growable: false),
        majAUtc: majAUtc,
      );

  /// La meme couche, avec un marqueur de plus.
  ///
  /// Un marqueur pose sur une plage deja marquee **remplace** le precedent :
  /// deux intentions contradictoires sur le meme passage ne veulent rien dire,
  /// et la derniere exprimee est la bonne.
  AnnotationLayer avecMarqueur(
    MarqueurSemantique marqueur, {
    required DateTime majAUtc,
  }) => _copie(
    marqueurs: <MarqueurSemantique>[
      ...marqueurs.where(
        (MarqueurSemantique pose) => pose.plage != marqueur.plage,
      ),
      marqueur,
    ],
    majAUtc: majAUtc,
  );

  /// La meme couche, sans le marqueur [marqueurId].
  AnnotationLayer sansMarqueur(String marqueurId, {required DateTime majAUtc}) =>
      _copie(
        marqueurs: marqueurs
            .where((MarqueurSemantique marqueur) => marqueur.id != marqueurId)
            .toList(growable: false),
        majAUtc: majAUtc,
      );

  /// La meme couche, sans son dernier geste.
  ///
  /// **Un seul « Annuler » pour les deux natures de geste.** Le dernier trait
  /// et le dernier marqueur ne vivent pas dans deux piles separees du point de
  /// vue de l'enseignant : il annule ce qu'il vient de faire. Les traits sont
  /// tentes d'abord parce qu'un trait se pose au geste, donc plus souvent.
  AnnotationLayer sansDernier({required DateTime majAUtc}) {
    if (traits.isNotEmpty) {
      return sansTrait(traits.last.id, majAUtc: majAUtc);
    }
    if (marqueurs.isNotEmpty) {
      return sansMarqueur(marqueurs.last.id, majAUtc: majAUtc);
    }
    return this;
  }

  AnnotationLayer _copie({
    required DateTime majAUtc,
    List<TraitVectoriel>? traits,
    List<MarqueurSemantique>? marqueurs,
  }) => AnnotationLayer(
    id: id,
    resourceId: resourceId,
    resourceVersionId: resourceVersionId,
    sessionId: sessionId,
    auteurProfilId: auteurProfilId,
    portee: portee,
    traits: traits ?? this.traits,
    marqueurs: marqueurs ?? this.marqueurs,
    majAUtc: majAUtc,
  );
}
