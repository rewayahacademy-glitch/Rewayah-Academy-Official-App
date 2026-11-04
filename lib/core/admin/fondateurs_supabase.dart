// V2-e (04/11/2026) : l'adaptateur Supabase de la coche fondateur, sur les RPC
// `fondateurs_personnel` (lecture) et `poser_fondateur` (20261108000001). Le
// serveur decide de tout ; l'adaptateur traduit ses reponses et ses refus.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_fondateurs.dart';

/// Les identifiants rendus par `fondateurs_personnel` (SETOF uuid).
Set<String> fondateursDepuisJson(Object? reponse) => <String>{
  for (final Object? l in reponse is List ? reponse : const <Object?>[])
    if (l is String && l.isNotEmpty)
      l
    else if (l is Map && l.values.isNotEmpty && l.values.first is String)
      l.values.first as String,
};

/// Le motif d'un refus de `poser_fondateur`, d'apres son code SQL.
MotifFondateurRefuse motifFondateurRefuse(String? code) => switch (code) {
  '42501' => MotifFondateurRefuse.nonAutorise,
  '22023' => MotifFondateurRefuse.personnelInactif,
  _ => MotifFondateurRefuse.inconnu,
};

/// La coche fondateur sur Supabase.
class FondateursSupabase implements PortFondateurs {
  /// Cree l'adaptateur.
  const FondateursSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> lire() async =>
      fondateursDepuisJson(await _client.rpc<Object?>('fondateurs_personnel'));

  @override
  Future<bool> poser(String profilId, {required bool fondateur}) async {
    try {
      final Object? pose = await _client.rpc<Object?>(
        'poser_fondateur',
        params: <String, Object?>{
          'p_profil': profilId,
          'p_fondateur': fondateur,
        },
      );
      return pose is bool ? pose : fondateur;
    } on PostgrestException catch (e) {
      throw FondateurRefuse(motifFondateurRefuse(e.code));
    }
  }
}
