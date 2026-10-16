import 'package:supabase_flutter/supabase_flutter.dart';

import 'capacite_indisponible.dart';
import 'port_profil_eleve_titulaire.dart';

/// Le profil eleve du titulaire servi par les RPC `profil_eleve_titulaire_existe`
/// et `creer_profil_eleve_titulaire` (migrations 0052 et 0056 ; reprise de
/// l'adaptateur Codex `11bb298b`).
///
/// La creation est idempotente cote serveur ; un refus remonte a l'appelant.
/// La bascule vers l'espace eleve n'a pas de contrat serveur : elle reste
/// indisponible, jamais simulee.
class ProfilEleveTitulaireSupabase implements PortProfilEleveTitulaire {
  /// Cree l'adaptateur sur le client de l'application.
  const ProfilEleveTitulaireSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> existe() async {
    final Object? result = await _client.rpc<Object?>(
      'profil_eleve_titulaire_existe',
    );
    if (result is! bool) {
      throw const FormatException('Reponse de profil titulaire invalide');
    }
    return result;
  }

  @override
  Future<void> creer() async {
    await _client.rpc<Object?>('creer_profil_eleve_titulaire');
  }

  @override
  Future<void> ouvrirEspaceEleve() =>
      Future<void>.error(const CapaciteIndisponible('DB-FOY-01'));
}
