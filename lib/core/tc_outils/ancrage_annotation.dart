import 'package:flutter/widgets.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import '../tc_etat_partage/shared_content_state.dart' show ModeAffichagePartage;
import 'annotation_layer.dart';

/// Pourquoi tel ancrage a ete retenu.
///
/// Rendu explicite parce que c'est le point que la spec signale comme « subtil
/// et souvent rate » (section 8.3) : une annotation posee sur un rendu
/// reflowable et ancree spatialement se decale des que le texte se recompose.
enum RaisonAncrage {
  /// Un ancrage semantique etait disponible : c'est lui qui est retenu.
  semantiqueRetenu,

  /// La mise en page est figee : l'ancrage spatial est sans risque, et il
  /// autorise l'annotation libre, entre les lignes comme dans la marge.
  spatialSurPageFigee,

  /// Aucun ancrage semantique n'etait disponible sur un rendu reflowable.
  /// **L'annotation se decalera** au prochain recalcul de la mise en page.
  spatialFauteDeSemantique,

  /// Rien a quoi s'ancrer : l'annotation ne peut pas etre posee.
  aucunAncrage,
}

/// L'ancrage retenu pour un geste, et ce qu'il vaut.
@immutable
class ResultatAncrage {
  /// Cree un resultat d'ancrage.
  const ResultatAncrage({required this.position, required this.raison});

  /// L'ancrage retenu. `null` quand aucun ancrage n'etait disponible.
  final ContentPosition? position;

  /// Pourquoi celui-la.
  final RaisonAncrage raison;

  /// Vrai quand l'ancrage retenu **ne survivra pas** a une recomposition.
  ///
  /// L'appelant en fait ce qu'il veut -- un avertissement discret, un refus --
  /// mais il ne peut pas l'ignorer sans l'avoir lu.
  bool get degrade => raison == RaisonAncrage.spatialFauteDeSemantique;

  @override
  bool operator ==(Object other) =>
      other is ResultatAncrage &&
      other.position == position &&
      other.raison == raison;

  @override
  int get hashCode => Object.hash(position, raison);
}

/// Vrai quand l'ancrage de [p] designe une unite de SENS, et non un emplacement.
///
/// C'est la distinction qui decide du sort d'une annotation apres un reflow :
/// un ancrage semantique suit le texte, un ancrage spatial reste ou il est.
///
/// **Fonction libre, et non membre de [ContentPosition].** Le contrat canonique
/// d'Agent B ne porte aucun comportement : lui en attacher un ferait diverger
/// ce stub du canonique, et le code de D cesserait de compiler le jour ou Agent
/// Z le remplace. Le predicat vit donc dans le namespace de D, qui est le seul
/// a en avoir besoin.
bool estSemantique(ContentPosition p) =>
    p.typeAncrage == TypeAncrage.ayah || p.typeAncrage == TypeAncrage.section;

/// Choisit l'ancrage d'un geste selon le mode de rendu du support.
///
/// - En mode **page** (Mushaf fidele), la mise en page est figee : l'ancrage
///   spatial est prefere, parce que c'est lui qui autorise l'annotation libre
///   demandee par la spec -- une fleche dans la marge n'appartient a aucun
///   verset.
/// - En mode **verset reflowable** et en mode **focus**, le texte se recompose
///   a chaque changement de largeur, de police ou d'orientation : l'ancrage
///   **semantique** est prefere, au verset ou a la section. A defaut, on accepte
///   l'ancrage spatial, mais on le declare degrade.
ResultatAncrage choisirAncrage({
  required ModeAffichagePartage mode,
  ContentPosition? semantique,
  ContentPosition? spatial,
}) {
  assert(
    semantique == null || estSemantique(semantique),
    'un ancrage semantique est un ayah ou une section',
  );
  assert(
    spatial == null || !estSemantique(spatial),
    'un ancrage spatial est une page ou une fraction',
  );

  if (mode == ModeAffichagePartage.page) {
    if (spatial != null) {
      return ResultatAncrage(
        position: spatial,
        raison: RaisonAncrage.spatialSurPageFigee,
      );
    }
    if (semantique != null) {
      return ResultatAncrage(
        position: semantique,
        raison: RaisonAncrage.semantiqueRetenu,
      );
    }
    return const ResultatAncrage(
      position: null,
      raison: RaisonAncrage.aucunAncrage,
    );
  }

  if (semantique != null) {
    return ResultatAncrage(
      position: semantique,
      raison: RaisonAncrage.semantiqueRetenu,
    );
  }
  if (spatial != null) {
    return ResultatAncrage(
      position: spatial,
      raison: RaisonAncrage.spatialFauteDeSemantique,
    );
  }
  return const ResultatAncrage(
    position: null,
    raison: RaisonAncrage.aucunAncrage,
  );
}

/// Ou se trouvent, a cet instant et dans ce rendu, les blocs ancrables.
///
/// **Fournie par l'hote, jamais calculee ici.** Agent D ne compose pas le
/// texte : il ne sait pas ou tombe l'ayah 2:255 apres un changement de largeur.
/// L'hote -- le moteur Mushaf d'Agent C, ou l'ecran de Classe Live d'Agent E --
/// lui donne la geometrie courante, et la couche d'annotation s'y pose.
///
/// C'est **le mecanisme qui fait survivre une annotation a un reflow** : les
/// traits sont stockes en fractions du bloc, la carte dit ou est le bloc
/// maintenant, et la composition des deux rend des pixels justes. Rien n'est
/// stocke en pixels, donc rien ne se decale.
@immutable
class CarteDesBlocs {
  /// Cree une carte a partir de rectangles deja clefs.
  const CarteDesBlocs._(this._blocs, this.cadre);

  /// Cree une carte depuis les positions que l'hote sait placer.
  ///
  /// [cadre] est le rectangle du support lui-meme -- la page, la zone de
  /// lecture. Il sert d'ancre aux positions **spatiales** (page, fraction), qui
  /// ne designent aucun bloc de texte.
  factory CarteDesBlocs({
    Map<ContentPosition, Rect> blocs = const <ContentPosition, Rect>{},
    Rect? cadre,
  }) {
    final Map<String, BlocAncre> parClef = <String, BlocAncre>{};
    for (final MapEntry<ContentPosition, Rect> entree in blocs.entries) {
      parClef[clefDe(entree.key)] = BlocAncre(entree.key, entree.value);
    }
    return CarteDesBlocs._(Map<String, BlocAncre>.unmodifiable(parClef), cadre);
  }

  /// Une carte sans aucun bloc connu.
  static const CarteDesBlocs vide = CarteDesBlocs._(
    <String, BlocAncre>{},
    null,
  );

  final Map<String, BlocAncre> _blocs;

  /// Le rectangle du support courant, s'il est connu.
  final Rect? cadre;

  /// La clef de bloc d'une position.
  ///
  /// La ressource entre dans la clef : deux supports ouverts cote a cote ne
  /// partagent pas leurs blocs.
  static String clefDe(ContentPosition position) =>
      switch (position.typeAncrage) {
        TypeAncrage.ayah =>
          '${position.resourceId}|ayah:${position.sourate}:${position.ayah}',
        TypeAncrage.section =>
          '${position.resourceId}|section:${position.sectionId}',
        TypeAncrage.page => '${position.resourceId}|page:${position.page}',
        TypeAncrage.fraction => '${position.resourceId}|cadre',
      };

  /// Le rectangle courant d'une position, ou `null` si elle n'est pas rendue.
  ///
  /// `null` n'est pas un echec : c'est la reponse juste quand l'ancrage n'est
  /// pas a l'ecran. Une annotation du verset 2:255 **ne doit pas** se peindre
  /// sur la page qui ne le contient pas.
  Rect? rectDe(ContentPosition position) {
    final BlocAncre? bloc = _blocs[clefDe(position)];
    if (bloc != null) {
      return bloc.rect;
    }
    // Un ancrage spatial se resout sur le cadre du support, jamais sur un bloc
    // de texte : c'est exactement ce qui le fait rester en place quand le texte
    // bouge.
    return estSemantique(position) ? null : cadre;
  }

  /// Vrai quand la carte sait placer cette position.
  bool connait(ContentPosition position) => rectDe(position) != null;

  /// Les blocs connus, dans un ordre quelconque.
  Iterable<BlocAncre> get blocs => _blocs.values;

  /// Le bloc le plus fin qui contient ce point d'ecran.
  ///
  /// C'est ainsi qu'un trait recoit son ancrage **semantique** sans que
  /// personne n'ait rien a selectionner : on ecrit sur un mot, et le mot dit a
  /// quel verset il appartient. Le plus petit rectangle l'emporte, parce qu'un
  /// bloc de section contient les blocs de versets qui le composent.
  BlocAncre? blocA(Offset point) {
    BlocAncre? retenu;
    for (final BlocAncre bloc in _blocs.values) {
      if (!bloc.rect.contains(point)) {
        continue;
      }
      final BlocAncre? courant = retenu;
      if (courant == null || _surface(bloc.rect) < _surface(courant.rect)) {
        retenu = bloc;
      }
    }
    return retenu;
  }

  static double _surface(Rect rect) => rect.width * rect.height;
}

/// Un bloc ancrable : ce qu'il designe, et ou il est a cet instant.
@immutable
class BlocAncre {
  /// Declare un bloc.
  const BlocAncre(this.position, this.rect);

  /// Ce que le bloc designe.
  final ContentPosition position;

  /// Ou il se trouve dans le rendu courant.
  final Rect rect;

  @override
  bool operator ==(Object other) =>
      other is BlocAncre && other.position == position && other.rect == rect;

  @override
  int get hashCode => Object.hash(position, rect);
}

/// Resout un trait en points d'ecran, dans le rendu courant.
///
/// Rend `null` quand l'ancrage du trait n'est pas visible : la couche ne peint
/// alors rien, plutot que de peindre au mauvais endroit.
List<Offset>? resoudreTrait(TraitVectoriel trait, CarteDesBlocs carte) {
  final Rect? bloc = carte.rectDe(trait.ancrage);
  if (bloc == null) {
    return null;
  }
  return <Offset>[
    for (final PointNormalise point in trait.points)
      Offset(
        bloc.left + point.x * bloc.width,
        bloc.top + point.y * bloc.height,
      ),
  ];
}

/// Les blocs du rendu courant que couvre une plage marquee.
///
/// C'est ainsi qu'un marqueur « A revoir » se rend **sans etre un dessin** : il
/// n'a pas de geometrie propre, il emprunte celle des blocs qu'il designe. Un
/// reflow le suit donc sans rien avoir a recalculer, exactement comme un trait
/// ancre semantiquement.
List<BlocAncre> blocsDansPlage(CarteDesBlocs carte, ContentRange plage) =>
    <BlocAncre>[
      for (final BlocAncre bloc in carte.blocs)
        if (plage.contient(bloc.position)) bloc,
    ];

/// Vrai quand la ligne brisee [points] passe a moins de [rayon] de [cible].
///
/// La mesure porte sur les **segments**, pas sur les sommets : un trait droit
/// n'a que deux points, et une gomme qui ne testerait que les sommets ne
/// pourrait pas effacer son milieu.
bool passePres(List<Offset> points, Offset cible, double rayon) {
  if (points.isEmpty) {
    return false;
  }
  if (points.length == 1) {
    return (points.first - cible).distance <= rayon;
  }
  for (int i = 0; i < points.length - 1; i++) {
    if (_distanceAuSegment(cible, points[i], points[i + 1]) <= rayon) {
      return true;
    }
  }
  return false;
}

double _distanceAuSegment(Offset point, Offset a, Offset b) {
  final Offset segment = b - a;
  final double longueur = segment.distanceSquared;
  if (longueur == 0) {
    return (point - a).distance;
  }
  final double t =
      (((point - a).dx * segment.dx + (point - a).dy * segment.dy) / longueur)
          .clamp(0, 1);
  return (point - (a + segment * t)).distance;
}

/// Normalise un point d'ecran dans le bloc qui l'ancre.
///
/// L'operation inverse de [resoudreTrait], employee pendant le geste.
PointNormalise normaliserDans(Rect bloc, Offset point) {
  if (bloc.width <= 0 || bloc.height <= 0) {
    // Un bloc sans surface n'a pas de coordonnees relatives : on ramene au
    // coin, plutot que de diviser par zero et de produire un NaN qui
    // traverserait la serialisation sans bruit.
    return const PointNormalise(0, 0);
  }
  return PointNormalise.borne(
    (point.dx - bloc.left) / bloc.width,
    (point.dy - bloc.top) / bloc.height,
  );
}
