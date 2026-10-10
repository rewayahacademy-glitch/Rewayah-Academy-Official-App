import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/historique_observations_admin_provider.dart';
import 'package:rewayah_academy/core/tc_observation/historique_observations_admin_supabase.dart';

void main() {
  test('le provider admin utilise l adaptateur Supabase en production', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(portHistoriqueObservationsAdminProvider),
      isA<HistoriqueObservationsAdminSupabase>(),
    );
  });
}
