import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/strings.g.dart';

/// Le representant dans l'Union europeenne, tel que la direction l'a saisi
/// (decision du directeur, 19/10/2026).
///
/// **Rien n'est en dur** : le nom est un reglage de `app_config`
/// (`conformite.representant_ue`), vide tant que la direction n'a rien saisi.
/// Vide, non connecte ou lecture en erreur, les textes juridiques affichent
/// « Rewayah Academy » ([representantUeAffiche]). Meme modele que le
/// responsable de la protection des enfants.
abstract interface class PortRepresentantUe {
  /// Le nom du representant (vide si rien n'est saisi). Leve si la lecture
  /// n'a pas abouti : l'ecran de la direction dit alors l'erreur, les textes
  /// juridiques retombent sur le defaut.
  Future<String> lire();
}

/// L'adaptateur reel : la fonction `representant_ue_conformite()`.
class RepresentantUeSupabase implements PortRepresentantUe {
  /// Cree l'adaptateur.
  const RepresentantUeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<String> lire() async {
    final Map<String, dynamic> ligne = await _client.rpc<Map<String, dynamic>>(
      'representant_ue_conformite',
    );
    final Object? nom = ligne['nom'];
    return nom is String ? nom.trim() : '';
  }
}

/// Le port employe par l'application.
final Provider<PortRepresentantUe> portRepresentantUeProvider =
    Provider<PortRepresentantUe>(
      (Ref ref) => RepresentantUeSupabase(Supabase.instance.client),
    );

/// Le nom du representant, relu a chaque invalidation.
final FutureProvider<String> representantUeProvider = FutureProvider<String>(
  (Ref ref) => ref.watch(portRepresentantUeProvider).lire(),
);

/// Le nom a afficher dans un texte : celui de la direction, ou « Rewayah
/// Academy » quand il est vide ou que la lecture n'a rien rendu ([lu] nul).
String representantUeAffiche(String? lu) {
  final String nom = lu?.trim() ?? '';
  return nom.isEmpty ? t.juridique.valeurs.representantUeDefaut : nom;
}

/// La cle `app_config` du representant.
abstract final class ClesConformite {
  /// Le nom du representant dans l'Union europeenne.
  static const String representantUe = 'conformite.representant_ue';
}
