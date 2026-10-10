import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import '../tc_etat_partage/codec_etat_partage.dart';
import 'annotation_layer.dart';
import 'intention_pedagogique.dart';
import 'port_annotations.dart';

/// Adaptateur des couches d'annotation persistantes.
///
/// Les couches temporaires restent dans le double mémoire local. Les autres
/// sont lues/écrites sous RLS; la publication Realtime de la table parent
/// relaie aussi les mutations des traits et marqueurs via maj_le.
class AnnotationsSupabase implements PortAnnotations {
  AnnotationsSupabase(this._client);

  final SupabaseClient _client;
  final Set<String> _idsTemporaires = <String>{};
  final Map<String, AnnotationsMemoire> _memoireParAuteur =
      <String, AnnotationsMemoire>{};

  AnnotationsMemoire get _memoire {
    final String? auteur = _client.auth.currentUser?.id;
    if (auteur == null) {
      throw StateError('Session requise pour les annotations');
    }
    return _memoireParAuteur.putIfAbsent(
      auteur,
      () => AnnotationsMemoire(auteur),
    );
  }

  @override
  Future<AnnotationLayer?> couche({
    required String resourceId,
    String? sessionId,
    required PorteeAnnotation portee,
  }) async {
    if (portee == PorteeAnnotation.temporaire) {
      final AnnotationLayer? couche = await _memoire.couche(
        resourceId: resourceId,
        sessionId: sessionId,
        portee: portee,
      );
      if (couche == null) return null;
      _idsTemporaires.add(couche.id);
      return couche;
    }

    final String? auteur = _client.auth.currentUser?.id;
    if (auteur == null) {
      throw StateError('Session requise pour les annotations');
    }

    final AnnotationLayer? existante = await _trouverCouche(
      resourceId: resourceId,
      sessionId: sessionId,
      portee: portee,
      auteur: auteur,
    );
    if (existante != null) return existante;

    try {
      final dynamic row = await _client
          .from('annotation_layer')
          .insert(<String, dynamic>{
            'resource_id': resourceId,
            'session_id': sessionId,
            'auteur_profile_id': auteur,
            'portee': portee.valeurSql,
          })
          .select('id')
          .single();
      return _chargerCouche(row['id'] as String);
    } on PostgrestException catch (error) {
      // Deux appareils peuvent créer la même portée en parallèle. L'index
      // unique serveur choisit une seule ligne; le perdant relit cette ligne.
      if (error.code != '23505') rethrow;
      final AnnotationLayer? gagnee = await _trouverCouche(
        resourceId: resourceId,
        sessionId: sessionId,
        portee: portee,
        auteur: auteur,
      );
      if (gagnee == null) rethrow;
      return gagnee;
    }
  }

  Future<AnnotationLayer?> _trouverCouche({
    required String resourceId,
    required String? sessionId,
    required PorteeAnnotation portee,
    required String auteur,
  }) async {
    dynamic query = _client
        .from('annotation_layer')
        .select('id')
        .eq('resource_id', resourceId)
        .eq('auteur_profile_id', auteur)
        .eq('portee', portee.valeurSql);
    query = sessionId == null
        ? query.isFilter('session_id', null)
        : query.eq('session_id', sessionId);
    final dynamic row = await query.maybeSingle();
    if (row == null) return null;
    return _chargerCouche(row['id'] as String);
  }

  @override
  Stream<AnnotationLayer> suivre({
    required String resourceId,
    String? sessionId,
  }) {
    dynamic query = _client
        .from('annotation_layer')
        .stream(primaryKey: <String>['id'])
        .eq('resource_id', resourceId)
        .inFilter('portee', <String>['seance', 'enregistree']);
    query = sessionId == null
        ? query.isFilter('session_id', null)
        : query.eq('session_id', sessionId);

    return Stream<AnnotationLayer>.multi((controller) {
      final StreamSubscription<dynamic> distante = query.listen(
        (dynamic rows) {
          unawaited(_emettreCouches(rows, controller));
        },
        onError: (Object error, StackTrace stackTrace) =>
            controller.addError(error, stackTrace),
      );
      final StreamSubscription<AnnotationLayer> locale = _memoire
          .suivre(resourceId: resourceId, sessionId: sessionId)
          .listen(
            controller.add,
            onError: (Object error, StackTrace stackTrace) =>
                controller.addError(error, stackTrace),
          );
      controller.onCancel = () async {
        await distante.cancel();
        await locale.cancel();
      };
    });
  }

  Future<void> _emettreCouches(
    dynamic rows,
    MultiStreamController<AnnotationLayer> controller,
  ) async {
    if (rows is! List) {
      controller.addError(
        const FormatException('Flux annotation_layer invalide'),
      );
      return;
    }
    for (final dynamic raw in rows) {
      try {
        final Map<String, dynamic> row = Map<String, dynamic>.from(raw as Map);
        final AnnotationLayer couche = await _chargerCouche(row['id'] as String);
        controller.add(couche);
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }
  }

  Future<AnnotationLayer> _chargerCouche(String id) async {
    final dynamic rowBrute = await _client
        .from('annotation_layer')
        .select()
        .eq('id', id)
        .single();
    final Map<String, dynamic> row = Map<String, dynamic>.from(rowBrute as Map);

    final List<dynamic> traitsBruts = await _client
        .from('annotation_trait')
        .select()
        .eq('layer_id', id)
        .order('cree_le');
    final List<dynamic> marqueursBruts = await _client
        .from('annotation_marqueur')
        .select()
        .eq('layer_id', id)
        .order('cree_le');

    return AnnotationLayer(
      id: row['id'] as String,
      resourceId: row['resource_id'] as String,
      resourceVersionId: row['resource_version_id'] as String?,
      sessionId: row['session_id'] as String?,
      auteurProfilId: row['auteur_profile_id'] as String,
      portee: _portee(row['portee'] as String?),
      majAUtc: _instant(row['maj_le'], 'maj_le'),
      traits: traitsBruts
          .map(
            (dynamic raw) => _traitDepuisJson(
              Map<String, dynamic>.from(raw as Map),
            ),
          )
          .toList(growable: false),
      marqueurs: marqueursBruts
          .map(
            (dynamic raw) => _marqueurDepuisJson(
              Map<String, dynamic>.from(raw as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> ajouterTrait(String coucheId, TraitVectoriel trait) async {
    if (_idsTemporaires.contains(coucheId)) {
      await _memoire.ajouterTrait(coucheId, trait);
      return;
    }
    final AnnotationLayer couche = await _chargerCouche(coucheId);
    if (trait.ancrage.resourceId != couche.resourceId) {
      throw ArgumentError('Le trait doit rester ancré à sa ressource');
    }
    await _client.from('annotation_trait').insert(<String, dynamic>{
      'layer_id': coucheId,
      'ancrage': positionVersJson(trait.ancrage),
      'points': <Map<String, double>>[
        for (final PointNormalise point in trait.points)
          <String, double>{'x': point.x, 'y': point.y},
      ],
      'outil': trait.outil.valeurSql,
      'intention': trait.intention?.valeurSql,
      'pression': trait.pression,
      'inclinaison': trait.inclinaison,
    });
  }

  @override
  Future<void> retirerTrait(String coucheId, String traitId) async {
    if (_idsTemporaires.contains(coucheId)) {
      await _memoire.retirerTrait(coucheId, traitId);
      return;
    }
    await _client
        .from('annotation_trait')
        .delete()
        .eq('layer_id', coucheId)
        .eq('id', traitId);
  }

  @override
  Future<void> poserMarqueur(
    String coucheId,
    MarqueurSemantique marqueur,
  ) async {
    if (_idsTemporaires.contains(coucheId)) {
      await _memoire.poserMarqueur(coucheId, marqueur);
      return;
    }
    final AnnotationLayer couche = await _chargerCouche(coucheId);
    if (marqueur.plage.resourceId != couche.resourceId) {
      throw ArgumentError('Le marqueur doit rester ancré à sa ressource');
    }
    await _client.rpc<void>(
      'tc_poser_annotation_marqueur',
      params: <String, dynamic>{
        'p_layer_id': coucheId,
        'p_id': marqueur.id,
        'p_plage': plageVersJson(marqueur.plage),
        'p_intention': marqueur.intention.valeurSql,
        'p_note': marqueur.note,
      },
    );
  }

  @override
  Future<void> retirerMarqueur(String coucheId, String marqueurId) async {
    if (_idsTemporaires.contains(coucheId)) {
      await _memoire.retirerMarqueur(coucheId, marqueurId);
      return;
    }
    await _client
        .from('annotation_marqueur')
        .delete()
        .eq('layer_id', coucheId)
        .eq('id', marqueurId);
  }

  @override
  Future<void> annulerDernier(String coucheId) async {
    if (_idsTemporaires.contains(coucheId)) {
      await _memoire.annulerDernier(coucheId);
      return;
    }
    await _client.rpc<void>(
      'tc_annuler_derniere_annotation',
      params: <String, dynamic>{'p_layer_id': coucheId},
    );
  }

  static TraitVectoriel _traitDepuisJson(Map<String, dynamic> row) {
    final ContentPosition? ancrage = positionDepuisJson(row['ancrage']);
    final OutilTrait? outil = OutilTrait.depuisSql(row['outil'] as String?);
    final String? intentionSql = row['intention'] as String?;
    final IntentionPedagogique? intention = intentionSql == null
        ? null
        : IntentionPedagogique.depuisSql(intentionSql);
    final Object? pointsBruts = row['points'];

    if (ancrage == null ||
        outil == null ||
        (intentionSql != null && intention == null) ||
        pointsBruts is! List) {
      throw const FormatException('Trait Supabase invalide');
    }
    return TraitVectoriel(
      id: row['id'] as String,
      ancrage: ancrage,
      points: pointsBruts.map((dynamic point) {
        final Map<String, dynamic> valeurs = Map<String, dynamic>.from(point as Map);
        final num? x = valeurs['x'] as num?;
        final num? y = valeurs['y'] as num?;
        if (x == null || y == null || x < 0 || x > 1 || y < 0 || y > 1) {
          throw const FormatException('Point de trait invalide');
        }
        return PointNormalise(x.toDouble(), y.toDouble());
      }).toList(growable: false),
      outil: outil,
      intention: intention,
      pression: (row['pression'] as num?)?.toDouble(),
      inclinaison: (row['inclinaison'] as num?)?.toDouble(),
    );
  }

  static MarqueurSemantique _marqueurDepuisJson(Map<String, dynamic> row) {
    final ContentRange? plage = plageDepuisJson(row['plage']);
    final IntentionPedagogique? intention = IntentionPedagogique.depuisSql(
      row['intention'] as String?,
    );
    if (plage == null || intention == null) {
      throw const FormatException('Marqueur Supabase invalide');
    }
    return MarqueurSemantique(
      id: row['id'] as String,
      plage: plage,
      intention: intention,
      note: row['note'] as String?,
    );
  }

  static ContentPosition? positionDepuisJson(Object? row) {
    if (row is! Map) return null;
    final Map<String, dynamic> valeurs = Map<String, dynamic>.from(row);
    final String? resourceId = valeurs['resource_id'] as String?;
    final String? type = valeurs['type_ancrage'] as String?;
    final String? version = valeurs['resource_version_id'] as String?;
    if (resourceId == null || type == null) return null;
    switch (type) {
      case 'page':
        final int? page = valeurs['page'] as int?;
        return page == null
            ? null
            : ContentPosition.page(
                resourceId: resourceId,
                page: page,
                resourceVersionId: version,
              );
      case 'ayah':
        final int? sourate = valeurs['sourate'] as int?;
        final int? ayah = valeurs['ayah'] as int?;
        return sourate == null || ayah == null
            ? null
            : ContentPosition.ayah(
                resourceId: resourceId,
                sourate: sourate,
                ayah: ayah,
                resourceVersionId: version,
              );
      case 'section':
        final String? sectionId = valeurs['section_id'] as String?;
        return sectionId == null
            ? null
            : ContentPosition.section(
                resourceId: resourceId,
                sectionId: sectionId,
                resourceVersionId: version,
              );
      case 'fraction':
        final num? fraction = valeurs['fraction'] as num?;
        return fraction == null
            ? null
            : ContentPosition.fraction(
                resourceId: resourceId,
                fraction: fraction.toDouble(),
                resourceVersionId: version,
              );
      default:
        return null;
    }
  }

  static PorteeAnnotation _portee(String? valeur) {
    final PorteeAnnotation? portee = PorteeAnnotation.depuisSql(valeur);
    if (portee == null || portee == PorteeAnnotation.temporaire) {
      throw const FormatException('Portée annotation Supabase invalide');
    }
    return portee;
  }

  static DateTime _instant(Object? valeur, String champ) {
    final DateTime? instant = DateTime.tryParse(valeur?.toString() ?? '');
    if (instant == null) {
      throw FormatException('Horodatage annotation invalide: $champ');
    }
    return instant.toUtc();
  }
}
