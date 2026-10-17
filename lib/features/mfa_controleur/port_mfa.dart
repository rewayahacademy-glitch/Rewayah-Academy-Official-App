import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_mfa_supabase.dart';

/// Ce que le serveur d'authentification sait du second facteur du compte.
sealed class SituationMfa {
  const SituationMfa();
}

/// Aucun facteur TOTP verifie : le compte doit en enroler un.
class MfaAEnroler extends SituationMfa {
  /// Cree la situation.
  const MfaAEnroler();
}

/// Un facteur TOTP verifie existe : cette connexion doit encore le prouver.
///
/// Un controleur qui a enrole un facteur mais s'est connecte sans le verifier
/// est en `aal1` ; l'ecran propose alors la verification, jamais l'enrolement.
class MfaAVerifier extends SituationMfa {
  /// Cree la situation pour le facteur [facteurId].
  const MfaAVerifier(this.facteurId);

  /// Le facteur a verifier.
  final String facteurId;
}

/// Un facteur tout juste cree, pas encore verifie.
class EnrolementTotp {
  /// Cree un enrolement.
  const EnrolementTotp({
    required this.facteurId,
    required this.uri,
    required this.secret,
  });

  /// Le facteur a verifier avec le premier code.
  final String facteurId;

  /// L'adresse `otpauth://` que l'application d'authentification lit dans le
  /// QR. Ne se journalise jamais.
  final String uri;

  /// La cle, a saisir a la main quand le QR ne peut pas etre scanne. Ne se
  /// journalise jamais.
  final String secret;
}

/// Le reseau ne repond pas : l'ecran dit « hors ligne ».
class MfaHorsLigne implements Exception {
  /// Cree l'exception.
  const MfaHorsLigne();
}

/// Le code a six chiffres a ete refuse par le serveur.
class MfaCodeRefuse implements Exception {
  /// Cree l'exception.
  const MfaCodeRefuse();
}

/// La seconde etape de connexion (TOTP), derriere une interface : l'ecran et
/// ses tests tournent sans reseau.
abstract interface class PortMfa {
  /// Lit la situation du compte.
  Future<SituationMfa> situation();

  /// Cree un facteur TOTP et rend de quoi l'ajouter a l'application.
  Future<EnrolementTotp> enroler();

  /// Verifie [code] pour [facteurId]. Reussir eleve le jeton a `aal2` : la
  /// session se met a jour d'elle-meme, et le routeur libere le compte.
  Future<void> verifier({required String facteurId, required String code});
}

/// Le port employe par l'application.
final Provider<PortMfa> portMfaProvider = Provider<PortMfa>(
  (Ref ref) => PortMfaSupabase(Supabase.instance.client),
);
