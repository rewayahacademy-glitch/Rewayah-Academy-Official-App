// S1 (24/10/2026) : la reception des evenements d'ecriture de la salle, en
// face de [DiffusionOutils]. L'enseignant pose un trait (ou le retire) ; le
// message part sur le canal fiable du protocole pedagogique ; chez l'eleve,
// cette reception le pose dans son depot local, que la surface relit deja
// (`notesDeposeesProvider`). Aucune table : le depot est en memoire, le temps
// de la seance.

import 'dart:async';

import '../tc_bibliotheque/content_position.dart';
import '../tc_realtime/port_realtime_pedagogique.dart';
import 'annotation_layer.dart';
import 'annotations_supabase.dart' show AnnotationsSupabase;
import 'intention_pedagogique.dart';
import 'port_annotations.dart';

/// Les types d'evenements d'ecriture que la reception applique.
const String typeTraitTermine = 'tc.outils.trait_termine';
const String typeTraitRetire = 'tc.outils.trait_retire';

/// Applique au depot local les traits poses et retires par les autres.
class ReceptionOutils {
  /// Ecoute [realtime] pour [sessionId] ; ignore ce que [profilLocalId] a
  /// lui-meme emis (son depot l'a deja).
  ReceptionOutils(
    PortRealtimePedagogique realtime, {
    required this.sessionId,
    required this.profilLocalId,
    required this.depot,
  }) {
    _abonnement = realtime
        .messagesFiables(sessionId)
        .listen(_recevoir, onError: (Object _) {});
  }

  /// La seance ecoutee.
  final String sessionId;

  /// Le profil de cet appareil.
  final String profilLocalId;

  /// Le depot local de la seance, que la surface relit.
  final AnnotationsMemoire depot;
  late final StreamSubscription<MessagePedagogique> _abonnement;

  Future<void> _recevoir(MessagePedagogique message) async {
    if (message.emetteurProfilId == profilLocalId) return;
    switch (message.type) {
      case typeTraitTermine:
        final TraitVectoriel? trait = traitDepuisCharge(message.charge);
        if (trait == null) return;
        // La meme couche que celle ou la surface relit : la ressource du
        // trait, sans seance (`ContexteDock` de la salle). Chez qui recoit, la
        // copie n'est qu'un affichage, rien n'est conserve : couche
        // temporaire, quelle que soit la portee de l'auteur.
        final AnnotationLayer? couche = await depot.couche(
          resourceId: trait.ancrage.resourceId,
          portee: PorteeAnnotation.temporaire,
        );
        if (couche == null) return;
        if (couche.traits.any((TraitVectoriel t) => t.id == trait.id)) return;
        await depot.ajouterTrait(couche.id, trait);
      case typeTraitRetire:
        final String? traitId = message.charge['trait_id'] as String?;
        if (traitId == null) return;
        for (final AnnotationLayer couche in depot.couches.toList()) {
          if (couche.traits.any((TraitVectoriel t) => t.id == traitId)) {
            await depot.retirerTrait(couche.id, traitId);
          }
        }
    }
  }

  /// Cesse d'ecouter.
  Future<void> liberer() => _abonnement.cancel();
}

/// Le trait d'un message `tc.outils.trait_termine` ([EvenementTraitTermine]),
/// ou `null` s'il est illisible (une autre version de l'application). La
/// position se lit par le meme decodeur que le depot serveur.
TraitVectoriel? traitDepuisCharge(Map<String, dynamic> charge) {
  final Object? brut = charge['trait'];
  if (brut is! Map) return null;
  final Map<String, dynamic> trait = Map<String, dynamic>.from(brut);
  final ContentPosition? ancrage = AnnotationsSupabase.positionDepuisJson(
    trait['ancrage'],
  );
  final OutilTrait? outil = OutilTrait.depuisSql(trait['outil'] as String?);
  final Object? points = trait['points'];
  final String? id = trait['id'] as String?;
  if (ancrage == null || outil == null || points is! List || id == null) {
    return null;
  }
  final List<PointNormalise> lus = <PointNormalise>[];
  for (final Object? point in points) {
    if (point is! Map) return null;
    final num? x = point['x'] as num?;
    final num? y = point['y'] as num?;
    if (x == null || y == null) return null;
    lus.add(PointNormalise.borne(x.toDouble(), y.toDouble()));
  }
  return TraitVectoriel(
    id: id,
    ancrage: ancrage,
    points: lus,
    outil: outil,
    intention: IntentionPedagogique.depuisSql(trait['intention'] as String?),
    pression: (trait['pression'] as num?)?.toDouble(),
    inclinaison: (trait['inclinaison'] as num?)?.toDouble(),
    epaisseur: EpaisseurTrait.depuisSql(trait['epaisseur'] as String?),
  );
}
