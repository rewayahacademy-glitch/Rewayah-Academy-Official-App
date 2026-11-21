// L'adaptateur Supabase des chiffres de l'academie, sur la RPC
// `chiffres_academie` (migration 20261130969500). Un appel, quelques
// centaines d'octets ; le serveur compte tout et memorise 10 minutes ce qui
// coute.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import 'port_chiffres_academie.dart';

/// Les chiffres servis par Supabase.
class ChiffresAcademieSupabase implements PortChiffresAcademie {
  /// Cree l'adaptateur sur le client de l'application.
  const ChiffresAcademieSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ChiffresAcademie> lire() async {
    final Object? brut;
    try {
      brut = await _client.rpc<Object?>('chiffres_academie');
    } on PostgrestException catch (e) {
      throw erreurChiffres(e.code) ?? e;
    }
    if (brut is! Map) throw const FormatException('Objet attendu.');
    return ChiffresAcademie.json(Map<String, dynamic>.from(brut));
  }
}

/// L'erreur vraie derriere un code du serveur, ou nul : un refus (42501) dit
/// que la page est reservee a la direction ; une fonction absente (PGRST202,
/// 42883 : migration pas encore installee) dit que les chiffres ne sont pas
/// encore disponibles. Tout autre code reste un echec de lecture.
Exception? erreurChiffres(String? code) => switch (code) {
  '42501' => const ChiffresReserves(),
  'PGRST202' ||
  '42883' => const CapaciteIndisponible(dependanceChiffresAcademie),
  _ => null,
};
