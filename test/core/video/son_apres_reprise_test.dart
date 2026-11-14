import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';

/// HORS-SALLE-1 (directeur, 12/11/2026 au soir : « je dois revenir vite pour
/// que le son revienne ») : apres toute reprise, le son recu est relance ; un
/// refus du navigateur se dit (`sonBloque`).
///
/// Limite : `lk.Room` ne se remplace pas par un double dans ce moteur ; la
/// logique est tenue par [relancerSonRecu], et son branchement aux trois
/// reprises est verifie sur la source (dernier test).
void main() {
  group('le son recu apres une reprise', () {
    test('startAudio est tente ; le navigateur accepte : son libre', () async {
      int essais = 0;
      final List<bool> poses = <bool>[];
      await relancerSonRecu(
        demarrer: () async => essais++,
        peutJouer: () => true,
        poser: poses.add,
      );
      expect(essais, 1);
      expect(poses, <bool>[false]);
    });

    test('refus faute de geste : sonBloque vrai', () async {
      final List<bool> poses = <bool>[];
      await relancerSonRecu(
        demarrer: () async {},
        peutJouer: () => false,
        poser: poses.add,
      );
      expect(poses, <bool>[true]);
    });

    test(
      'une erreur de l essai n arrete pas la reprise et se dit bloquee',
      () async {
        final List<bool> poses = <bool>[];
        await relancerSonRecu(
          demarrer: () async => throw StateError('NotAllowedError'),
          peutJouer: () => false,
          poser: poses.add,
        );
        expect(poses, <bool>[true]);
      },
    );

    test('branche aux trois reprises : SDK, salle neuve, retour a l ecran', () {
      final String source = File('lib/core/video/livekit_session_provider.dart')
          .readAsStringSync();
      final int sdk = source.indexOf('on<lk.RoomReconnectedEvent>');
      final int finSdk = source.indexOf('on<lk.RoomDisconnectedEvent>');
      expect(source.substring(sdk, finSdk), contains('_relancerSon()'));
      final int neuve = source.indexOf('Future<bool> _connecterSansGeste(');
      expect(
        source.substring(neuve, source.indexOf('Future<void> quitter()')),
        contains('await _relancerSon()'),
      );
      final int retour = source.indexOf('Future<void> _reprendreAuRetour()');
      expect(
        source.substring(
          retour,
          source.indexOf('Future<void> _relancerPistesMuettes()'),
        ),
        contains('await _relancerSon()'),
      );
      expect(source, contains('demarrer: salle.startAudio'));
    });
  });
}
