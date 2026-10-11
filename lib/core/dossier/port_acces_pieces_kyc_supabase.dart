import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_acces_pieces_kyc.dart';

/// Adaptateur du verdict serveur C-21. Aucun genre n'est lu ou compare ici.
class PortAccesPiecesKycSupabase implements PortAccesPiecesKyc {
  const PortAccesPiecesKycSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<AccesPieceKyc> pour(String dossierId) async {
    try {
      final Map<String, dynamic> resultat = await _client
          .rpc<Map<String, dynamic>>(
            'verdict_acces_dossier_kyc',
            params: <String, dynamic>{'p_profile_id': dossierId},
          );
      return decoderVerdictAccesKyc(resultat);
    } on PostgrestException catch (erreur) {
      if (erreur.code == '42501') {
        return const AccesRefuse(RefusPieceKyc.profilNonAutorise);
      }
      rethrow;
    }
  }

  @override
  Future<bool> exceptionActive() async =>
      await _client.rpc<bool>('kyc_super_admin_exception_active');
}

/// Decode strictement les categories fixes du RPC sans exposer son SQL brut.
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
