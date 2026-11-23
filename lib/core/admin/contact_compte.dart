// APERCU-COMPTE (directeur, 22/11/2026 : « l'e-mail qui s'affichait ne s'affiche
// plus »). Le courriel d'un compte, lu par la direction pour l'apercu de la page
// « Personnes ». Une seule lecture (`contact_compte_admin`), gardee cote serveur
// (direction seulement, rien sous masquage d'identite) ; aucune regle ici.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// La lecture du courriel d'un compte.
abstract interface class PortContactCompte {
  /// Le courriel du compte [profilId], ou `null` quand le serveur n'en rend
  /// pas (masquage d'identite, compte hors de portee).
  Future<String?> courriel(String profilId);
}

/// Le port branche sur Supabase.
class ContactCompteSupabase implements PortContactCompte {
  /// Cree le port.
  const ContactCompteSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> courriel(String profilId) async {
    final Object? brut = await _client.rpc<Object?>(
      'contact_compte_admin',
      params: <String, Object?>{'p_profil': profilId},
    );
    return brut is String && brut.trim().isNotEmpty ? brut.trim() : null;
  }
}

/// Le port employe par l'application.
final Provider<PortContactCompte> portContactCompteProvider =
    Provider<PortContactCompte>(
      (Ref ref) => ContactCompteSupabase(Supabase.instance.client),
    );

/// Le courriel du compte [profilId] (relu a chaque ouverture de l'apercu).
final courrielCompteProvider = FutureProvider.autoDispose
    .family<String?, String>(
      (Ref ref, String profilId) =>
          ref.watch(portContactCompteProvider).courriel(profilId),
    );
