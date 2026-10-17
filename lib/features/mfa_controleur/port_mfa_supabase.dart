import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_mfa.dart';

/// Le port reel : l'API MFA de Supabase Auth.
///
/// Le niveau `aal2` est pose par le serveur d'authentification dans le jeton ;
/// rien ici ne l'accorde, et la base refuse de toute facon un appel du
/// controleur en `aal1` (SQLSTATE 42501).
class PortMfaSupabase implements PortMfa {
  /// Cree le port a partir d'un client Supabase.
  const PortMfaSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<SituationMfa> situation() async {
    try {
      final AuthMFAListFactorsResponse facteurs = await _client.auth.mfa
          .listFactors();
      // `totp` ne rend que les facteurs verifies.
      return facteurs.totp.isEmpty
          ? const MfaAEnroler()
          : MfaAVerifier(facteurs.totp.first.id);
    } on Object catch (erreur) {
      throw _classer(erreur);
    }
  }

  @override
  Future<EnrolementTotp> enroler() async {
    try {
      // Un enrolement abandonne laisse un facteur non verifie ; il est retire
      // avant d'en creer un autre, sans quoi le serveur refuse le doublon.
      final AuthMFAListFactorsResponse facteurs = await _client.auth.mfa
          .listFactors();
      for (final Factor f in facteurs.all) {
        if (f.factorType == FactorType.totp &&
            f.status == FactorStatus.unverified) {
          await _client.auth.mfa.unenroll(f.id);
        }
      }
      final AuthMFAEnrollResponse reponse = await _client.auth.mfa.enroll(
        issuer: 'Rewayah Academy',
        friendlyName: 'controleur-${DateTime.now().millisecondsSinceEpoch}',
      );
      final TOTPEnrollment? totp = reponse.totp;
      if (totp == null) {
        throw StateError('enrolement TOTP sans donnees');
      }
      return EnrolementTotp(
        facteurId: reponse.id,
        uri: totp.uri,
        secret: totp.secret,
      );
    } on Object catch (erreur) {
      throw _classer(erreur);
    }
  }

  @override
  Future<void> verifier({
    required String facteurId,
    required String code,
  }) async {
    try {
      await _client.auth.mfa.challengeAndVerify(
        factorId: facteurId,
        code: code,
      );
    } on Object catch (erreur) {
      throw _classer(erreur);
    }
  }

  /// Distingue un code refuse, un reseau muet et tout autre echec.
  static Exception _classer(Object erreur) {
    if (erreur is AuthRetryableFetchException) {
      return const MfaHorsLigne();
    }
    if (erreur is AuthException) {
      final String code = erreur.code ?? '';
      if (code == 'mfa_verification_failed' ||
          code == 'mfa_challenge_expired' ||
          erreur.message.toLowerCase().contains('invalid totp')) {
        return const MfaCodeRefuse();
      }
      return erreur;
    }
    final String texte = erreur.toString();
    if (texte.contains('SocketException') ||
        texte.contains('ClientException') ||
        texte.contains('Failed host lookup') ||
        texte.contains('TimeoutException')) {
      return const MfaHorsLigne();
    }
    return erreur is Exception ? erreur : Exception('mfa');
  }
}
