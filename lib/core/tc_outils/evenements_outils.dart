import 'package:flutter/foundation.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import '../tc_realtime/port_realtime_pedagogique.dart';
import 'annotation_layer.dart';
import 'intention_pedagogique.dart';
import 'masquage.dart';

/// Ce que les outils pedagogiques ont a dire au reste de la classe.
///
/// **Agent D ne transporte rien.** Il produit ces evenements et les confie au
/// port d'Agent F ([DiffusionOutils]) : aucun appel a LiveKit, aucune `Room`,
/// aucun canal de donnees ouvert ici. L'interdiction est nominative dans
/// `TEACHING_CORE_FILE_OWNERSHIP.md`.
///
/// Chaque evenement porte **lui-meme** le canal qui lui convient : c'est la
/// regle « paquets legers pendant le geste, version compacte et stable a la
/// fin » (spec section 8.3), et elle ne doit pas dependre de l'appelant.
@immutable
sealed class EvenementOutil {
  const EvenementOutil();

  /// Le canal qui convient a cet evenement.
  CanalFiabilite get canal;

  /// Le type, qui decide de la lecture de la charge a l'autre bout.
  String get type;

  /// La charge utile, serialisable.
  Map<String, dynamic> charge();
}

/// Le trait avance. **Ephemere** : perdre un paquet ne coute qu'un sursaut.
@immutable
class EvenementTraitEnCours extends EvenementOutil {
  /// Annonce l'avancee d'un trait.
  const EvenementTraitEnCours({
    required this.traitId,
    required this.ancrage,
    required this.pointsNouveaux,
    required this.outil,
    this.intention,
  });

  /// Le trait concerne, pour que les paquets se raccrochent entre eux.
  final String traitId;

  /// L'ancrage du trait.
  final ContentPosition ancrage;

  /// **Uniquement** les points apparus depuis le paquet precedent.
  final List<PointNormalise> pointsNouveaux;

  /// L'outil employe.
  final OutilTrait outil;

  /// L'intention, dont la couleur derive a l'affichage.
  final IntentionPedagogique? intention;

  @override
  CanalFiabilite get canal => CanalFiabilite.ephemere;

  @override
  String get type => 'tc.outils.trait_en_cours';

  @override
  Map<String, dynamic> charge() => <String, dynamic>{
    'trait_id': traitId,
    'ancrage': _positionJson(ancrage),
    'points': _pointsJson(pointsNouveaux),
    'outil': outil.valeurSql,
    'intention': intention?.valeurSql,
  };
}

/// Le trait est termine. **Fiable** : c'est la version qui fait foi.
@immutable
class EvenementTraitTermine extends EvenementOutil {
  /// Annonce un trait termine.
  const EvenementTraitTermine({
    required this.coucheId,
    required this.trait,
    required this.portee,
  });

  /// La couche a laquelle le trait appartient.
  final String coucheId;

  /// Le trait, compacte.
  final TraitVectoriel trait;

  /// La portee de la couche.
  final PorteeAnnotation portee;

  @override
  CanalFiabilite get canal => CanalFiabilite.fiable;

  @override
  String get type => 'tc.outils.trait_termine';

  @override
  Map<String, dynamic> charge() => <String, dynamic>{
    'couche_id': coucheId,
    'portee': portee.valeurSql,
    'trait': <String, dynamic>{
      'id': trait.id,
      'ancrage': _positionJson(trait.ancrage),
      'points': _pointsJson(trait.points),
      'outil': trait.outil.valeurSql,
      'intention': trait.intention?.valeurSql,
      'pression': trait.pression,
      'inclinaison': trait.inclinaison,
    },
  };
}

/// Un trait a ete retire, par la gomme ou par « Annuler ». **Fiable.**
@immutable
class EvenementTraitRetire extends EvenementOutil {
  /// Annonce le retrait d'un trait.
  const EvenementTraitRetire({required this.coucheId, required this.traitId});

  /// La couche concernee.
  final String coucheId;

  /// Le trait retire.
  final String traitId;

  @override
  CanalFiabilite get canal => CanalFiabilite.fiable;

  @override
  String get type => 'tc.outils.trait_retire';

  @override
  Map<String, dynamic> charge() => <String, dynamic>{
    'couche_id': coucheId,
    'trait_id': traitId,
  };
}

/// L'indication ephemere du pointeur. **Ephemere, et jamais persistee.**
@immutable
class EvenementPointeur extends EvenementOutil {
  /// Annonce ou pointe l'enseignant. [position] a `null` retire l'indication.
  const EvenementPointeur({required this.position});

  /// Ou pointe l'indication, ou `null` quand elle s'efface.
  final ContentPosition? position;

  @override
  CanalFiabilite get canal => CanalFiabilite.ephemere;

  @override
  String get type => 'tc.outils.pointeur';

  @override
  Map<String, dynamic> charge() => <String, dynamic>{
    'position': position == null ? null : _positionJson(position!),
  };
}

/// Un marqueur semantique a ete pose ou retire. **Fiable** : c'est une
/// metadonnee de plage, elle survit a la seance.
@immutable
class EvenementMarqueur extends EvenementOutil {
  /// Annonce la pose d'un marqueur.
  const EvenementMarqueur.pose({
    required this.coucheId,
    required MarqueurSemantique this.marqueur,
  }) : marqueurId = null,
       retire = false;

  /// Annonce le retrait d'un marqueur.
  const EvenementMarqueur.retrait({
    required this.coucheId,
    required String this.marqueurId,
  }) : marqueur = null,
       retire = true;

  /// La couche concernee.
  final String coucheId;

  /// Le marqueur pose, quand il s'agit d'une pose.
  final MarqueurSemantique? marqueur;

  /// Le marqueur retire, quand il s'agit d'un retrait.
  final String? marqueurId;

  /// Vrai pour un retrait.
  final bool retire;

  @override
  CanalFiabilite get canal => CanalFiabilite.fiable;

  @override
  String get type => 'tc.outils.marqueur';

  @override
  Map<String, dynamic> charge() => <String, dynamic>{
    'couche_id': coucheId,
    'retire': retire,
    if (marqueur != null)
      'marqueur': <String, dynamic>{
        'id': marqueur!.id,
        'plage': _plageJson(marqueur!.plage),
        'intention': marqueur!.intention.valeurSql,
        'note': marqueur!.note,
      },
    if (marqueurId != null) 'marqueur_id': marqueurId,
  };
}

/// Le focus de la classe a change. **Fiable.**
@immutable
class EvenementFocus extends EvenementOutil {
  /// Annonce la plage mise au centre, ou `null` pour sortir du focus.
  const EvenementFocus({required this.plage});

  /// La plage au centre, ou `null`.
  final ContentRange? plage;

  @override
  CanalFiabilite get canal => CanalFiabilite.fiable;

  @override
  String get type => 'tc.outils.focus';

  @override
  Map<String, dynamic> charge() => <String, dynamic>{
    'plage': plage == null ? null : _plageJson(plage!),
  };
}

/// Le masquage a change. **Fiable.**
@immutable
class EvenementMasquage extends EvenementOutil {
  /// Annonce l'etat courant du masquage.
  const EvenementMasquage({required this.plan});

  /// Le plan complet, et non un delta : un eleve qui arrive en retard doit
  /// pouvoir se remettre a jour avec un seul message.
  final PlanMasquage plan;

  @override
  CanalFiabilite get canal => CanalFiabilite.fiable;

  @override
  String get type => 'tc.outils.masquage';

  @override
  Map<String, dynamic> charge() => <String, dynamic>{
    'masquees': <Map<String, dynamic>>[
      for (final ContentRange plage in plan.plages) _plageJson(plage),
    ],
    'revelees': <Map<String, dynamic>>[
      for (final ContentRange plage in plan.revelees) _plageJson(plage),
    ],
  };
}

/// Confie les evenements des outils au transport d'Agent F.
///
/// C'est **le seul point de contact** entre le lot D et le realtime, et il tient
/// en une methode : le jour ou la forme canonique de `MessagePedagogique`
/// arrivera, un seul endroit changera.
class DiffusionOutils {
  /// Cree une diffusion pour une seance.
  ///
  /// Le transport est positionnel, comme les trente et un services du depot
  /// qui prennent leur client en premier argument.
  DiffusionOutils(
    this._transport, {
    required this.sessionId,
    required this.emetteurProfilId,
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final PortRealtimePedagogique _transport;
  final DateTime Function() _maintenant;

  /// La seance concernee.
  final String sessionId;

  /// Le profil qui emet.
  final String emetteurProfilId;

  /// Emet un evenement sur le canal qu'il declare.
  Future<void> emettre(EvenementOutil evenement) => _transport.emettre(
    MessagePedagogique(
      type: evenement.type,
      sessionId: sessionId,
      emetteurProfilId: emetteurProfilId,
      charge: evenement.charge(),
      emisLeUtc: _maintenant(),
    ),
    canal: evenement.canal,
  );
}

Map<String, dynamic> _positionJson(ContentPosition position) =>
    <String, dynamic>{
      'resource_id': position.resourceId,
      'resource_version_id': position.resourceVersionId,
      'type_ancrage': position.typeAncrage.valeurSql,
      'page': position.page,
      'sourate': position.sourate,
      'ayah': position.ayah,
      'section_id': position.sectionId,
      'fraction': position.fraction,
    };

Map<String, dynamic> _plageJson(ContentRange plage) => <String, dynamic>{
  'resource_id': plage.resourceId,
  'resource_version_id': plage.resourceVersionId,
  'debut': _positionJson(plage.debut),
  'fin': _positionJson(plage.fin),
};

List<Map<String, double>> _pointsJson(List<PointNormalise> points) =>
    <Map<String, double>>[
      for (final PointNormalise point in points)
        <String, double>{'x': point.x, 'y': point.y},
    ];
