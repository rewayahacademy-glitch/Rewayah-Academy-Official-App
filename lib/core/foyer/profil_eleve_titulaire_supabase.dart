import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_profil_eleve_titulaire_serveur.dart';

/// Raccord des RPC de profil élève titulaire. La navigation reste côté écran.
class ProfilEleveTitulaireSupabase
    implements PortProfilEleveTitulaireServeur {
  const ProfilEleveTitulaireSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> existe() async {
    final Object? result =
        await _client.rpc<Object?>('profil_eleve_titulaire_existe');
    if (result is! bool) {
      throw const FormatException('Réponse de profil titulaire invalide');
    }
    return result;
  }

  @override
  Future<void> creer() async {
    await _client.rpc<Object?>('creer_profil_eleve_titulaire');
  }
}
