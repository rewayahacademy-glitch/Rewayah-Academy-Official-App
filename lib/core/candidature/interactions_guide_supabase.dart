// GUIDE-AVIS (directeur, 21/11/2026 : « il faut ajouter les J'aime et
// l'autre ») : l'adaptateur Supabase des avis du guide de l'enseignant
// (`PortInteractionsGuide`), sur les RPC `public.lire_interactions_guide()` et
// `public.donner_avis_guide(p_partie text, p_avis text)` de
// `20261130971000_guide_avis.sql`.
//
// Les commentaires n'ont pas encore de serveur : le serveur rend
// `commentaires_ouverts = false`, l'ecran ne propose ni « Commenter » ni le fil,
// et `commenter` reste une capacite indisponible. Une fonction que le serveur ne
// connait pas encore est une capacite indisponible : la barre d'avis ne
// s'affiche pas et la lecture du guide reste entiere.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/candidature/lettre/port_interactions_guide.dart';
import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';

/// La dependance que nomme la capacite indisponible.
const String dependanceAvisGuide = 'GUIDE-AVIS';

/// La RPC de lecture des totaux.
const String fonctionLireInteractions = 'lire_interactions_guide';

/// La RPC qui pose ou retire un avis.
const String fonctionDonnerAvis = 'donner_avis_guide';

/// Un appel RPC injectable (tests) ; en production, `client.rpc`.
typedef AppelAvisGuide = Future<Object?> Function(
  String fonction,
  Map<String, dynamic>? params,
);

AppelAvisGuide _client(SupabaseClient client) =>
    (String fonction, Map<String, dynamic>? params) =>
        client.rpc<Object?>(fonction, params: params);

/// Les avis du guide servis par Supabase.
class InteractionsGuideSupabase implements PortInteractionsGuide {
  /// Cree l'adaptateur sur le client de l'application.
  InteractionsGuideSupabase(SupabaseClient client) : _rpc = _client(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  InteractionsGuideSupabase.avecAppel(this._rpc);

  final AppelAvisGuide _rpc;

  Future<Map<String, dynamic>> _appeler(
    String fonction,
    Map<String, dynamic>? params,
  ) async {
    final Object? brut;
    try {
      brut = await _rpc(fonction, params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      // PGRST202 : fonction absente du cache de schema ; 42883 : fonction
      // inconnue de la base. La migration n'est pas encore installee.
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceAvisGuide);
      }
      rethrow;
    }
    if (brut is! Map) throw FormatException('$fonction : objet attendu');
    return Map<String, dynamic>.from(brut);
  }

  @override
  Future<InteractionsGuide> lire() async => InteractionsGuide.depuisJson(
    await _appeler(fonctionLireInteractions, null),
  );

  @override
  Future<AvisPartie> donnerAvis({
    required String partie,
    AvisGuide? avis,
  }) async => AvisPartie.depuisJson(
    await _appeler(fonctionDonnerAvis, <String, dynamic>{
      'p_partie': partie,
      'p_avis': avis?.cle,
    }),
  );

  @override
  Future<CommentaireGuide> commenter({
    required String partie,
    required String corps,
  }) => Future<CommentaireGuide>.error(
    const CapaciteIndisponible(dependanceAvisGuide),
  );
}
