import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reglages_priere.dart';

/// Les reglages de priere d'un enseignant.
///
/// **Un seul chemin de lecture pour les trois roles.** L'enseignant les pose,
/// ses eleves et leurs tuteurs les lisent, et tous calculent ensuite la meme
/// minute. La policy `prayer_settings_parties_read` borne ce cercle : un
/// enseignant ne lit pas les reglages d'un collegue.
abstract interface class ServicePriere {
  /// Les reglages d'un enseignant. `null` quand il n'en a pas encore pose : ce
  /// n'est pas une erreur, c'est l'etat de depart.
  Future<ReglagesPriere?> reglages(String enseignantId);

  /// Pose ou met a jour ses propres reglages. Reserve a l'enseignant lui-meme.
  Future<void> enregistrer(ReglagesPriere reglages);
}

/// L'implementation reelle.
class ServicePriereSupabase implements ServicePriere {
  /// Cree le service.
  const ServicePriereSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ReglagesPriere?> reglages(String enseignantId) async {
    final Map<String, dynamic>? ligne = await _client
        .from('prayer_settings')
        .select()
        .eq('teacher_id', enseignantId)
        .maybeSingle();
    return ligne == null ? null : ReglagesPriere.depuisJson(ligne);
  }

  @override
  Future<void> enregistrer(ReglagesPriere reglages) => _client
      .from('prayer_settings')
      .upsert(reglages.versJson(), onConflict: 'teacher_id');
}

/// Le service de prieres employe par l'application.
final Provider<ServicePriere> servicePriereProvider = Provider<ServicePriere>(
  (Ref ref) => ServicePriereSupabase(Supabase.instance.client),
);

/// Les reglages d'un enseignant donne.
final FutureProviderFamily<ReglagesPriere?, String> reglagesPriereProvider =
    FutureProvider.family<ReglagesPriere?, String>(
      (Ref ref, String enseignantId) =>
          ref.watch(servicePriereProvider).reglages(enseignantId),
    );
