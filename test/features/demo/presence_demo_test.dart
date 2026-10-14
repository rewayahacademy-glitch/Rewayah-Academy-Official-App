import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/presence_demo.dart';

void main() {
  group('presence de demonstration', () {
    test('passe finalisee, a venir planifiee, inconnue sinon', () async {
      const PresenceDemo p = PresenceDemo();
      final List<PresenceParticipant>? passe = await p.presence(
        'demo-seance-${DonneesDemo.aichaId}--7',
      );
      expect(passe!.single.profilId, DonneesDemo.aichaId);
      expect(passe.single.etat, EtatPresence.finalisee);
      final List<PresenceParticipant>? avenir = await p.presence(
        'demo-seance-${DonneesDemo.yusufId}-2',
      );
      expect(avenir!.single.etat, EtatPresence.planifiee);
      expect(await p.presence('autre'), isNull);
    });

    test('surcharges : presence et acceptations hors serveur', () async {
      final ProviderContainer c = ProviderContainer(
        overrides: surchargesDemoTuteur(environnement: 'preview'),
      );
      addTearDown(c.dispose);
      expect(c.read(servicePresenceProvider), isA<PresenceDemo>());
      expect(await c.read(acceptationsProvider.future), isEmpty);
    });
  });
}
