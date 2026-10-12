import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_acces_pieces_kyc.dart';

/// Adaptateur du verdict serveur C-21. Aucun genre n'est lu ou compare ici.
class PortAccesPiecesKycSupabase implements PortAccesPiecesKyc {
  const PortAccesPiecesKycSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<AccesPieceKyc> pour(String dossierId) async {
    if (dossierId.trim().isEmpty) {
      return const AccesRefuse(RefusPieceKyc.profilNonAutorise);
    }
    try {
      final Object? resultat = await _client.rpc<Object?>(
        'verdict_acces_dossier_kyc',
        params: <String, dynamic>{'p_profile_id': dossierId},
      );
      if (resultat is! Map<String, dynamic>) {
        throw const FormatException('Verdict KYC inconnu.');
      }
      return decoderVerdictAccesKyc(resultat);
    } on PostgrestException catch (erreur) {
      if (erreur.code == '42501') {
        return const AccesRefuse(RefusPieceKyc.profilNonAutorise);
      }
      rethrow;
    }
  }

  @override
  Future<bool> exceptionActive() async {
    final Object? resultat = await _client.rpc<Object?>(
      'ma_exception_kyc_active',
    );
    if (resultat is bool) return resultat;
    throw const FormatException('Statut exception KYC inconnu.');
  }
}

/// Décode strictement les catégories fixes du RPC sans exposer son SQL brut.
AccesPieceKyc decoderVerdictAccesKyc(Map<String, dynamic> resultat) {
  switch (resultat['type']) {
    case 'memeGenre':
      return const AccesMemeGenre();
    case 'exceptionSuperAdmin':
      return const AccesExceptionSuperAdmin();
    case 'refus':
      final RefusPieceKyc raison = switch (resultat['raison']) {
        'genreDifferent' => RefusPieceKyc.genreDifferent,
        'adminSansGenre' => RefusPieceKyc.adminSansGenre,
        'profilNonAutorise' => RefusPieceKyc.profilNonAutorise,
        _ => throw const FormatException('Motif de refus KYC inconnu.'),
      };
      return AccesRefuse(raison);
    default:
      throw const FormatException('Verdict KYC inconnu.');
  }
}
