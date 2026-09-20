import 'package:flutter/foundation.dart';

import 'ports_externes/content_position.dart';
import 'ports_externes/content_range.dart';
import 'ports_externes/marqueur_semantique.dart';

/// Le mode d'affichage impose a la classe (CONTRACTS section 9).
///
/// Il n'y en a que trois, et ce sont ceux de la spec section 13.1 : la page
/// fidele de l'edition, le verset reflowable, et le focus dirige.
enum ModeAffichagePartage {
  /// Page du mushaf, mise en page figee.
  page('page'),

  /// Verset reflowable : le texte se recompose avec la largeur.
  verse('verse'),

  /// Support dirige, chrome reduit.
  focus('focus');

  const ModeAffichagePartage(this.valeurSql);

  /// La valeur telle que la base l'attendra.
  final String valeurSql;

  /// Lit un mode depuis sa valeur SQL.
  ///
  /// Rend `null` sur valeur inconnue. **Jamais de repli silencieux** : un
  /// paquet ecrit par une version d'application plus recente ne doit pas faire
  /// basculer une classe entiere dans un mode qu'elle n'a pas demande. Le
  /// decodeur traite ce `null` comme un paquet illisible et garde l'etat
  /// courant.
  static ModeAffichagePartage? depuisSql(String? valeur) {
    for (final ModeAffichagePartage m in ModeAffichagePartage.values) {
      if (m.valeurSql == valeur) {
        return m;
      }
    }
    return null;
  }
}

/// Le support actif de la classe, a une revision donnee.
///
/// **[QURAN-STAGE] C'est l'etat PARTAGE de la seance, jamais l'etat personnel
/// de lecture.** Une page tournee par l'enseignant pour toute la classe n'ecrit
/// pas `student_reading_position` : c'est l'invariant J2, inscrit en
/// commentaire dans la migration `0007`, et c'est aussi ce que le socle tient
/// deja pour `ContenuPresente` (`lib/core/video/video_session_provider.dart`).
/// Le zoom local de chacun n'entre pas ici non plus (decision D-21).
///
/// **[revision] est strictement croissante par seance, et c'est le seul ordre
/// qui compte.** Ni l'horodatage d'emission, ni l'ordre d'arrivee des paquets
/// ne font foi : deux appareils n'ont pas la meme horloge, et un canal peut
/// livrer un paquet apres un plus recent. Toute la discipline d'ordonnancement
/// du lot F tient dans `ReducteurEtatPartage`, qui compare des revisions.
///
/// **Aucune donnee sensible n'entre ici** : ni telephone, ni courriel, ni
/// identite de famille. [updatedBy] est un `profile_id`, c'est-a-dire ce que le
/// jeton signe porte deja comme identite de participant LiveKit.
@immutable
class SharedContentState {
  /// Cree un etat partage.
  ///
  /// **Pas `const`, et ce n'est pas un oubli** : [updatedAtUtc] est un
  /// `DateTime`, qui n'est jamais une constante. Un constructeur `const` ne
  /// pourrait donc jamais etre invoque comme tel, et il interdirait en prime
  /// l'assertion qui garantit l'UTC -- un appel de getter n'etant pas une
  /// expression constante. On garde l'assertion, qui protege un invariant de
  /// contrat, plutot qu'un `const` que personne ne peut utiliser.
  SharedContentState({
    required this.sessionId,
    required this.resourceId,
    required this.contentPosition,
    required this.displayMode,
    required this.hiddenRanges,
    required this.semanticMarkers,
    required this.revision,
    required this.updatedBy,
    required this.updatedAtUtc,
    this.resourceVersionId,
    this.contentRange,
    this.groupResumePosition,
  }) : assert(revision >= 0, 'une revision ne descend jamais sous zero'),
       assert(
         updatedAtUtc.isUtc,
         'tout DateTime de contrat est en UTC (CONTRACTS section 0)',
       );

  /// La seance concernee.
  final String sessionId;

  /// La ressource presentee.
  final String resourceId;

  /// Sa version, quand elle est connue.
  final String? resourceVersionId;

  /// La position presentee.
  final ContentPosition contentPosition;

  /// La plage de travail, quand l'enseignant en a designe une.
  final ContentRange? contentRange;

  /// Le mode impose a la classe.
  final ModeAffichagePartage displayMode;

  /// Les plages masquees.
  final List<ContentRange> hiddenRanges;

  /// Les marqueurs poses par l'enseignant.
  final List<MarqueurSemantique> semanticMarkers;

  /// La position ou le groupe reprend le cours.
  final ContentPosition? groupResumePosition;

  /// Numero de revision, strictement croissant par seance.
  final int revision;

  /// L'emetteur de cette revision.
  final String updatedBy;

  /// L'instant de la revision, en UTC.
  final DateTime updatedAtUtc;

  /// La revision suivante, avec les champs qu'on veut changer.
  ///
  /// **[revision] et [updatedAtUtc] ne se choisissent pas** : c'est justement
  /// ce que cette methode empeche. Un appelant qui pourrait poser lui-meme un
  /// numero de revision pourrait le poser plus bas que le courant, et le
  /// reducteur de l'autre cote le rejetterait sans que personne comprenne
  /// pourquoi la classe ne suit plus.
  SharedContentState suivante({
    required String updatedBy,
    required DateTime maintenantUtc,
    String? resourceId,
    Object? resourceVersionId = _absent,
    ContentPosition? contentPosition,
    Object? contentRange = _absent,
    ModeAffichagePartage? displayMode,
    List<ContentRange>? hiddenRanges,
    List<MarqueurSemantique>? semanticMarkers,
    Object? groupResumePosition = _absent,
  }) => SharedContentState(
    sessionId: sessionId,
    resourceId: resourceId ?? this.resourceId,
    resourceVersionId: identical(resourceVersionId, _absent)
        ? this.resourceVersionId
        : resourceVersionId as String?,
    contentPosition: contentPosition ?? this.contentPosition,
    contentRange: identical(contentRange, _absent)
        ? this.contentRange
        : contentRange as ContentRange?,
    displayMode: displayMode ?? this.displayMode,
    hiddenRanges: hiddenRanges ?? this.hiddenRanges,
    semanticMarkers: semanticMarkers ?? this.semanticMarkers,
    groupResumePosition: identical(groupResumePosition, _absent)
        ? this.groupResumePosition
        : groupResumePosition as ContentPosition?,
    revision: revision + 1,
    updatedBy: updatedBy,
    updatedAtUtc: maintenantUtc.toUtc(),
  );

  @override
  bool operator ==(Object other) =>
      other is SharedContentState &&
      other.sessionId == sessionId &&
      other.resourceId == resourceId &&
      other.resourceVersionId == resourceVersionId &&
      other.contentPosition == contentPosition &&
      other.contentRange == contentRange &&
      other.displayMode == displayMode &&
      listEquals(other.hiddenRanges, hiddenRanges) &&
      listEquals(other.semanticMarkers, semanticMarkers) &&
      other.groupResumePosition == groupResumePosition &&
      other.revision == revision &&
      other.updatedBy == updatedBy &&
      other.updatedAtUtc == updatedAtUtc;

  @override
  int get hashCode => Object.hash(
    sessionId,
    resourceId,
    resourceVersionId,
    contentPosition,
    contentRange,
    displayMode,
    Object.hashAll(hiddenRanges),
    Object.hashAll(semanticMarkers),
    groupResumePosition,
    revision,
    updatedBy,
    updatedAtUtc,
  );
}

/// Sentinelle : distingue « parametre non fourni » de « fourni a `null` ».
///
/// Sans elle, `suivante(contentRange: null)` -- « retire la plage de travail »
/// -- serait indiscernable de `suivante()` -- « ne touche pas a la plage ».
const Object _absent = Object();
