// GUIDE-COMMENTAIRES (21/11/2026) : l'adaptateur Supabase de la page de la
// direction (`PortCommentairesGuide`), sur `commentaires_guide_direction()` et
// `repondre_commentaire_guide(p_commentaire, p_corps)` de
// `20261130972000_guide_commentaires.sql`.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin_guide/port_commentaires_guide.dart';
import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';

/// La RPC de lecture de la direction.
const String fonctionCommentairesDirection = 'commentaires_guide_direction';

/// La RPC de reponse.
const String fonctionRepondreGuide = 'repondre_commentaire_guide';

/// Un appel RPC injectable (tests) ; en production, `client.rpc`.
typedef AppelCommentairesGuide = Future<Object?> Function(
  String fonction,
  Map<String, dynamic>? params,
);

/// Les commentaires du guide, cote direction, servis par Supabase.
class CommentairesGuideSupabase implements PortCommentairesGuide {
  /// Cree l'adaptateur sur le client de l'application.
  CommentairesGuideSupabase(SupabaseClient client)
    : _rpc = ((String f, Map<String, dynamic>? p) =>
          client.rpc<Object?>(f, params: p));

  /// Cree l'adaptateur sur un appel injecte (tests).
  CommentairesGuideSupabase.avecAppel(this._rpc);

  final AppelCommentairesGuide _rpc;

  Future<Map<String, dynamic>> _appeler(
    String fonction,
    Map<String, dynamic>? params,
  ) async {
    final Object? brut;
    try {
      brut = await _rpc(fonction, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible('GUIDE-COMMENTAIRES');
      }
      rethrow;
    }
    if (brut is! Map) throw FormatException('$fonction : objet attendu');
    return Map<String, dynamic>.from(brut);
  }

  @override
  Future<List<PartieGuideDirection>> lire() async {
    final Map<String, dynamic> r = await _appeler(
      fonctionCommentairesDirection,
      null,
    );
    return <PartieGuideDirection>[
      for (final Object? p in r['parties'] as List<dynamic>)
        PartieGuideDirection.depuisJson(p! as Map<String, dynamic>),
    ];
  }

  @override
  Future<MessageGuide> repondre({
    required String commentaire,
    required String corps,
  }) async => MessageGuide.depuisJson(
    await _appeler(fonctionRepondreGuide, <String, dynamic>{
      'p_commentaire': commentaire,
      'p_corps': corps,
    }),
  );
}
