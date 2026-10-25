// D12 (24/10/2026) : sans identifiant de seance, la presence n'appelle jamais
// le service (plus de `session_id=eq.` toutes les 20 s en production).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';

class _ServiceCompte implements ServicePresence {
  int appels = 0;

  @override
  Future<List<PresenceParticipant>?> presence(String seanceId) async {
    appels++;
    return const <PresenceParticipant>[];
  }
}

void main() {
  for (final String vide in <String>['', '  ']) {
    test('identifiant « $vide » : aucun appel, presence inconnue', () async {
      final _ServiceCompte service = _ServiceCompte();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: [servicePresenceProvider.overrideWithValue(service)],
      );
      addTearDown(conteneur.dispose);
      final ProviderSubscription<AsyncValue<List<PresenceParticipant>?>> abo =
          conteneur.listen(presenceSeanceProvider(vide), (_, _) {});
      addTearDown(abo.close);
      await Future<void>.delayed(Duration.zero);
      final AsyncValue<List<PresenceParticipant>?> lu = conteneur.read(
        presenceSeanceProvider(vide),
      );
      expect(lu.hasError, isFalse);
      expect(lu.value, isNull);
      expect(service.appels, 0);
    });
  }

  test('une vraie seance est lue', () async {
    final _ServiceCompte service = _ServiceCompte();
    final ProviderContainer conteneur = ProviderContainer(
      overrides: [servicePresenceProvider.overrideWithValue(service)],
    );
    addTearDown(conteneur.dispose);
    final ProviderSubscription<AsyncValue<List<PresenceParticipant>?>> abo =
        conteneur.listen(presenceSeanceProvider('s1'), (_, _) {});
    addTearDown(abo.close);
    await conteneur.read(presenceSeanceProvider('s1').future);
    expect(service.appels, 1);
  });
}
