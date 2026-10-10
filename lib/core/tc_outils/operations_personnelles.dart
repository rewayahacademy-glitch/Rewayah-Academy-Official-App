// TB-7b (plan V2 §7 ; UX_REVIEW_TB n. 21 ; TB14) : « Annuler » retire la
// derniere operation PERSONNELLE validee sur la surface actuelle, jamais le
// travail d'un autre ; la gomme d'un eleve ne retire que ses propres traits.
//
// L'historique vit ici, hors de la couche d'annotation : la couche se
// remonte (Commandes ouvertes, zoom, rotation) et les boutons « Annuler »
// (panneau, palette courte) ne sont pas dans la couche. Il ne retient que
// ce que le depot a pris (aucun faux succes) : un trait refuse n'y entre
// pas. Il n'est jamais diffuse ; un autre appareil a son propre historique.
//
// Aucun « vieux snapshot » n'est restaure (§7) : chaque annulation est une
// operation ciblee sur des identifiants de traits.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tc_bibliotheque/content_position.dart';
import 'annotation_layer.dart';
import 'port_annotations.dart';

/// Une operation de la personne, validee par le depot.
@immutable
sealed class OperationPersonnelle {
  const OperationPersonnelle({
    required this.surface,
    required this.portee,
    this.sessionId,
  });

  /// La surface ou l'operation a eu lieu (la page, ou le tableau libre).
  final ContentPosition surface;

  /// La portee de la couche touchee.
  final PorteeAnnotation portee;

  /// La seance de la couche touchee.
  final String? sessionId;
}

/// Un trait pose par la personne.
final class TraitPosePersonnel extends OperationPersonnelle {
  /// Le trait [trait], pris par le depot.
  TraitPosePersonnel({
    required this.trait,
    required super.portee,
    super.sessionId,
  }) : super(surface: trait.ancrage);

  /// Le trait pose.
  final TraitVectoriel trait;
}

/// Des traits retires d'un seul geste de gomme.
final class TraitsGommesPersonnels extends OperationPersonnelle {
  /// Les [traits] gommes sur [surface].
  const TraitsGommesPersonnels({
    required this.traits,
    required super.surface,
    required super.portee,
    super.sessionId,
  });

  /// Les traits retires, tels qu'ils etaient (Annuler les rend).
  final List<TraitVectoriel> traits;
}

/// L'historique personnel et les traits que la personne a retires de son
/// ecran (gomme, Annuler) : la couche ne les peint plus, meme si le depot
/// ou la vue les rend encore un instant.
@immutable
class HistoriquePersonnel {
  /// Un historique.
  const HistoriquePersonnel({
    this.operations = const <OperationPersonnelle>[],
    this.retires = const <String>{},
    this.mesTraits = const <String>{},
  });

  /// Les operations, de la plus ancienne a la plus recente.
  final List<OperationPersonnelle> operations;

  /// Les traits retires de l'ecran par la personne.
  final Set<String> retires;

  /// Les traits que la personne a poses (sa gomme d'eleve ne touche
  /// qu'eux).
  final Set<String> mesTraits;

  /// La derniere operation sur la surface que [sur] reconnait, ou `null`.
  OperationPersonnelle? derniere(bool Function(ContentPosition surface) sur) {
    for (int i = operations.length - 1; i >= 0; i--) {
      if (sur(operations[i].surface)) return operations[i];
    }
    return null;
  }

  /// « Annuler » a-t-il quelque chose a defaire sur la surface que [sur]
  /// reconnait ?
  bool peutAnnuler(bool Function(ContentPosition surface) sur) =>
      derniere(sur) != null;
}

/// La surface [surface] exactement (une page, le tableau libre) ; aucune
/// surface si elle est `null`.
bool Function(ContentPosition) surLaSurface(ContentPosition? surface) =>
    (ContentPosition p) => surface != null && p == surface;

/// Ce que [ControleurHistorique.annuler] a defait.
typedef OperationDefaite = ({String coucheId, OperationPersonnelle operation});

/// L'historique personnel de cet appareil.
final NotifierProvider<ControleurHistorique, HistoriquePersonnel>
historiquePersonnelProvider =
    NotifierProvider<ControleurHistorique, HistoriquePersonnel>(
      ControleurHistorique.new,
    );

/// Tient l'historique personnel.
class ControleurHistorique extends Notifier<HistoriquePersonnel> {
  @override
  HistoriquePersonnel build() => const HistoriquePersonnel();

  /// Le depot a pris [trait], pose par la personne.
  void traitPose(
    TraitVectoriel trait, {
    required PorteeAnnotation portee,
    String? sessionId,
  }) => state = HistoriquePersonnel(
    operations: <OperationPersonnelle>[
      ...state.operations,
      TraitPosePersonnel(trait: trait, portee: portee, sessionId: sessionId),
    ],
    retires: state.retires,
    mesTraits: <String>{...state.mesTraits, trait.id},
  );

  /// La gomme retire [id] de l'ecran, avant meme la reponse du depot.
  void masquer(String id) => state = HistoriquePersonnel(
    operations: state.operations,
    retires: <String>{...state.retires, id},
    mesTraits: state.mesTraits,
  );

  /// Le depot a refuse le retrait de [id] : le trait revient.
  void restaurer(String id) => state = HistoriquePersonnel(
    operations: state.operations,
    retires: <String>{...state.retires}..remove(id),
    mesTraits: state.mesTraits,
  );

  /// Un geste de gomme a retire [traits] de [surface].
  void traitsGommes(
    List<TraitVectoriel> traits, {
    required ContentPosition surface,
    required PorteeAnnotation portee,
    String? sessionId,
  }) {
    if (traits.isEmpty) return;
    state = HistoriquePersonnel(
      operations: <OperationPersonnelle>[
        ...state.operations,
        TraitsGommesPersonnels(
          traits: List<TraitVectoriel>.unmodifiable(traits),
          surface: surface,
          portee: portee,
          sessionId: sessionId,
        ),
      ],
      retires: <String>{
        ...state.retires,
        for (final TraitVectoriel trait in traits) trait.id,
      },
      mesTraits: state.mesTraits,
    );
  }

  /// Defait la derniere operation personnelle sur [surface] : un trait pose
  /// est retire, des traits gommes reviennent. Rien d'autre n'est touche.
  /// Rend ce qui a ete defait, ou `null` ; sans depot, rien n'est defait
  /// (l'operation reste, l'ecran ne ment pas).
  Future<OperationDefaite?> annuler(
    bool Function(ContentPosition surface) sur,
    PortAnnotations depot,
  ) async {
    final OperationPersonnelle? operation = state.derniere(sur);
    if (operation == null) return null;
    final AnnotationLayer? couche;
    try {
      couche = await depot.couche(
        resourceId: operation.surface.resourceId,
        sessionId: operation.sessionId,
        portee: operation.portee,
      );
      if (couche == null) return null;
      switch (operation) {
        case TraitPosePersonnel(:final TraitVectoriel trait):
          await depot.retirerTrait(couche.id, trait.id);
        case TraitsGommesPersonnels(:final List<TraitVectoriel> traits):
          for (final TraitVectoriel trait in traits) {
            await depot.ajouterTrait(couche.id, trait);
          }
      }
    } on Object {
      return null;
    }
    final Set<String> retires = <String>{...state.retires};
    switch (operation) {
      case TraitPosePersonnel(:final TraitVectoriel trait):
        retires.add(trait.id);
      case TraitsGommesPersonnels(:final List<TraitVectoriel> traits):
        retires.removeAll(<String>{
          for (final TraitVectoriel trait in traits) trait.id,
        });
    }
    state = HistoriquePersonnel(
      operations: <OperationPersonnelle>[
        for (final OperationPersonnelle o in state.operations)
          if (!identical(o, operation)) o,
      ],
      retires: retires,
      mesTraits: state.mesTraits,
    );
    return (coucheId: couche.id, operation: operation);
  }
}
