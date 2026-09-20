import 'package:flutter/foundation.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';

/// Ce qui est masque du support, et ce qui a ete revele.
///
/// L'outil « Masquer » sert la recitation et la memorisation : on cache une
/// plage, l'eleve recite, puis on revele pour verifier. La revelation est donc
/// **controlee** -- elle ne detruit pas le masquage, elle l'ouvre. Refermer
/// rend la plage a son etat masque, sans avoir a la redesigner.
///
/// Un plan de masquage est une **metadonnee de plage**, comme un marqueur :
/// rien n'est peint sur le support, rien n'en est copie.
@immutable
class PlanMasquage {
  /// Cree un plan de masquage.
  PlanMasquage({
    List<ContentRange> plages = const <ContentRange>[],
    List<ContentRange> revelees = const <ContentRange>[],
  }) : plages = List<ContentRange>.unmodifiable(plages),
       revelees = List<ContentRange>.unmodifiable(revelees);

  const PlanMasquage._vide()
    : plages = const <ContentRange>[],
      revelees = const <ContentRange>[];

  /// Le plan ou rien n'est masque.
  static const PlanMasquage aucun = PlanMasquage._vide();

  /// Les plages masquees.
  final List<ContentRange> plages;

  /// Les plages momentanement revelees, parmi celles qui sont masquees.
  final List<ContentRange> revelees;

  /// Vrai quand rien n'est masque.
  bool get estVide => plages.isEmpty;

  /// Vrai quand [position] est cachee **a cet instant**.
  ///
  /// Une position masquee puis revelee n'est plus cachee : la revelation prime,
  /// c'est elle que l'enseignant vient de declencher.
  bool estMasque(ContentPosition position) {
    final bool dansUnMasque = plages.any(
      (ContentRange plage) => plage.contient(position),
    );
    if (!dansUnMasque) {
      return false;
    }
    return !revelees.any((ContentRange plage) => plage.contient(position));
  }

  /// Masque une plage de plus.
  ///
  /// Masquer une plage deja masquee la **referme** : c'est le geste naturel
  /// apres une revelation, et il ne cree pas de doublon.
  PlanMasquage masquer(ContentRange plage) => PlanMasquage(
    plages: plages.contains(plage)
        ? plages
        : <ContentRange>[...plages, plage],
    revelees: _sans(revelees, plage),
  );

  /// Retire une plage du masquage.
  PlanMasquage demasquer(ContentRange plage) => PlanMasquage(
    plages: _sans(plages, plage),
    revelees: _sans(revelees, plage),
  );

  /// Revele une plage masquee.
  ///
  /// Reveler une plage qui n'est pas masquee ne fait rien : il n'y a rien a
  /// decouvrir, et l'enregistrer creerait un etat que personne ne peut annuler.
  PlanMasquage reveler(ContentRange plage) {
    if (!plages.contains(plage) || revelees.contains(plage)) {
      return this;
    }
    return PlanMasquage(
      plages: plages,
      revelees: <ContentRange>[...revelees, plage],
    );
  }

  /// Referme toutes les revelations, sans toucher au masquage.
  PlanMasquage toutRefermer() => PlanMasquage(plages: plages);

  /// Revele tout ce qui est masque.
  PlanMasquage toutReveler() =>
      PlanMasquage(plages: plages, revelees: plages);

  /// Retire tout masquage.
  PlanMasquage vider() => aucun;

  static List<ContentRange> _sans(
    List<ContentRange> source,
    ContentRange plage,
  ) => source
      .where((ContentRange candidate) => candidate != plage)
      .toList(growable: false);

  @override
  bool operator ==(Object other) =>
      other is PlanMasquage &&
      listEquals(other.plages, plages) &&
      listEquals(other.revelees, revelees);

  @override
  int get hashCode => Object.hash(Object.hashAll(plages), Object.hashAll(revelees));
}
