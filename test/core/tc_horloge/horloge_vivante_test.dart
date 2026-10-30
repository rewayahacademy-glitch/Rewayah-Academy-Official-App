// Mes classes (30/10/2026) : l'horloge vivante d'une Classe est lue a
// l'affichage, puis a chaque bascule (T-20, T0, fin, fin de grace), jamais
// toutes les 30 s ; entre deux, elle vieillit a la minute.

import 'dart:async';

// fake_async porte l'horloge simulee de flutter_test (meme usage que
// `sondage_regulier_test.dart`).
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/horloge_vivante.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

import '../../support/port_horloge_simule.dart';

void main() {
  final DateTime debut = DateTime.utc(2026, 10, 30, 17);
  // T-21 : une minute avant l'ouverture de la salle.
  final DateTime depart = debut.subtract(const Duration(minutes: 21));

  test('une lecture a l affichage, puis une a chaque bascule, aucune entre '
      'deux ; Rejoindre ouvert a T-20 pile', () {
    fakeAsync((FakeAsync temps) {
      final PortHorlogeSimule port = PortHorlogeSimule(
        debutUtc: debut,
        maintenant: () => depart.add(temps.elapsed),
      );
      final List<SessionClockVM?> emis = <SessionClockVM?>[];
      final StreamSubscription<SessionClockVM?> abonnement = suivreAuxBascules(
        () => port.horlogeDe(groupeId: 'g'),
      ).listen(emis.add);

      temps.flushMicrotasks();
      expect(port.lectures, 1, reason: 'lue a l affichage');
      expect(emis.last!.rejoindreOuvert, isFalse, reason: 'T-21');

      temps.elapse(const Duration(seconds: 59));
      expect(emis.last!.rejoindreOuvert, isFalse, reason: 'T-20 moins 1 s');
      expect(port.lectures, 1);

      temps.elapse(const Duration(seconds: 1));
      expect(emis.last!.rejoindreOuvert, isTrue, reason: 'T-20 pile');
      expect(emis.last!.phase, isNot(PhaseSeance.enCours));

      temps.elapse(margeBascule);
      expect(port.lectures, 2, reason: 'relue a la bascule T-20');
      expect(emis.last!.rejoindreOuvert, isTrue);

      // Vingt minutes plus tard : une seule lecture de plus, a T0.
      temps.elapse(const Duration(minutes: 20));
      expect(port.lectures, 3, reason: 'relue a T0, jamais entre deux');
      expect(emis.last!.enDirect, isTrue, reason: 'En cours a T0');

      // La fin (45 min) puis la fin de la grace (15 min).
      temps.elapse(const Duration(minutes: 45));
      expect(port.lectures, 4, reason: 'relue a la fin');
      temps.elapse(const Duration(minutes: 15));
      expect(port.lectures, 5, reason: 'relue a la fin de la grace');
      expect(emis.last!.rejoindreOuvert, isFalse);

      // Seance finie : plus aucune lecture programmee.
      temps.elapse(const Duration(hours: 3));
      expect(port.lectures, 5);
      unawaited(abonnement.cancel());
    });
  });

  test('le compte a rebours avance a la minute sans relire', () {
    fakeAsync((FakeAsync temps) {
      final DateTime loin = debut.subtract(const Duration(hours: 2));
      final PortHorlogeSimule port = PortHorlogeSimule(
        debutUtc: debut,
        maintenant: () => loin.add(temps.elapsed),
      );
      final List<SessionClockVM?> emis = <SessionClockVM?>[];
      final StreamSubscription<SessionClockVM?> abonnement = suivreAuxBascules(
        () => port.horlogeDe(groupeId: 'g'),
      ).listen(emis.add);
      temps.flushMicrotasks();
      expect(emis.last!.restant, const Duration(hours: 2));
      temps.elapse(const Duration(minutes: 7));
      expect(emis.last!.restant, const Duration(hours: 1, minutes: 53));
      expect(port.lectures, 1);
      unawaited(abonnement.cancel());
    });
  });

  test(
    'prochaineBascule : ouverture, debut, fin, fin de grace, puis rien',
    () async {
      final PortHorlogeSimule port = PortHorlogeSimule(
        debutUtc: debut,
        maintenant: () => depart,
      );
      final SessionClockVM h = (await port.horlogeDe(groupeId: 'g'))!;
      expect(
        prochaineBascule(h, depart),
        debut.subtract(const Duration(minutes: 20)),
      );
      expect(
        prochaineBascule(h, debut),
        debut.add(const Duration(minutes: 45)),
      );
      expect(prochaineBascule(h, debut.add(const Duration(hours: 2))), isNull);
    },
  );
}
