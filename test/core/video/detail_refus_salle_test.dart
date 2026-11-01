// FN-025 : le client lit le motif du 403 tel que le serveur le donne, et rien
// d'autre ; une forme inattendue vaut « aucun motif ».

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/service_video.dart';

void main() {
  test('un motif connu, avec les heures du serveur', () {
    expect(
      DetailRefusSalle.depuis(<String, dynamic>{
        'error': 'acces a la salle refuse',
        'motif': 'terminee',
        'fin_utc': '2026-11-01T18:00:00+00:00',
        'ouverture_utc': '2026-11-01T16:40:00+00:00',
        'grace_minutes': 15,
      }),
      DetailRefusSalle(
        motif: MotifServeurSalle.terminee,
        finUtc: DateTime.utc(2026, 11, 1, 18),
        ouvertureUtc: DateTime.utc(2026, 11, 1, 16, 40),
        graceMinutes: 15,
      ),
    );
    expect(
      DetailRefusSalle.depuis(<String, dynamic>{'motif': 'pas_encore_ouverte'})
          ?.motif,
      MotifServeurSalle.pasEncoreOuverte,
    );
    expect(
      DetailRefusSalle.depuis(<String, dynamic>{'motif': 'annulee'})?.motif,
      MotifServeurSalle.annulee,
    );
  });

  test('le refus generique, ou une forme inattendue : aucun motif', () {
    for (final Object? v in <Object?>[
      null,
      'acces a la salle refuse',
      <String, dynamic>{'error': 'acces a la salle refuse'},
      <String, dynamic>{'motif': 'salle fermee'},
      <String, dynamic>{'motif': 3},
    ]) {
      expect(DetailRefusSalle.depuis(v), isNull, reason: '$v');
    }
  });

  test('une heure ou une grace illisible est tue, le motif reste', () {
    final DetailRefusSalle? d = DetailRefusSalle.depuis(<String, dynamic>{
      'motif': 'terminee',
      'fin_utc': 'hier',
      'grace_minutes': -1,
    });
    expect(d?.motif, MotifServeurSalle.terminee);
    expect(d?.finUtc, isNull);
    expect(d?.graceMinutes, isNull);
  });
}
