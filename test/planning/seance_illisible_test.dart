import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';

void main() {
  group('Une ligne de seance illisible est ecartee, jamais completee', () {
    const Map<String, dynamic> lisible = <String, dynamic>{
      'session_id': 's1',
      'started_at': '2026-09-21T17:00:00Z',
      'ended_at': '2026-09-21T17:45:00Z',
      'status': 'planned',
    };

    test('une ligne lisible se lit par les deux chemins', () {
      expect(Seance.lire(lisible)?.id, 's1');
      expect(Seance.depuisJson(lisible).duree, const Duration(minutes: 45));
    });

    test('une borne absente ne devient jamais l instant de la lecture', () {
      // L'ancien repli `DateTime.now()` fabriquait une seance « en cours » a
      // l'heure exacte ou l'ecran s'ouvrait.
      for (final String cle in <String>['started_at', 'ended_at']) {
        final Map<String, dynamic> sansBorne = Map<String, dynamic>.of(lisible)
          ..remove(cle);
        final Map<String, dynamic> illisible = Map<String, dynamic>.of(lisible)
          ..[cle] = 'pas une date';

        expect(Seance.lire(sansBorne), isNull, reason: cle);
        expect(Seance.lire(illisible), isNull, reason: cle);
        expect(
          () => Seance.depuisJson(sansBorne),
          throwsFormatException,
          reason: cle,
        );
      }
    });

    test('une ligne sans identifiant est ecartee', () {
      final Map<String, dynamic> sansId = Map<String, dynamic>.of(lisible)
        ..remove('session_id');

      expect(Seance.lire(sansId), isNull);
    });
  });
}
