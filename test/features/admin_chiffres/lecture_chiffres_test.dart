// CHIFFRES-ACADEMIE : le rythme de lecture. Une lecture a la fois, une par
// minute, aucune onglet cache, tout de suite au retour si la minute est
// passee.

import 'dart:async';

// ignore: depend_on_referenced_packages, fourni par flutter_test.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/admin_chiffres/lecture_chiffres.dart';

void main() {
  const Duration minute = Duration(minutes: 1);

  test('une lecture au demarrage, puis une par minute, pas plus', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      final LectureRythmee<int> l = LectureRythmee<int>(
        lire: () async => ++appels,
      )..demarrer(visible: true);
      temps.flushMicrotasks();
      expect(appels, 1);
      expect(l.etat.requireValue, 1);
      temps.elapse(const Duration(seconds: 59));
      expect(appels, 1);
      temps.elapse(const Duration(seconds: 1));
      expect(appels, 2);
      temps.elapse(const Duration(minutes: 10));
      expect(appels, 12);
      l.dispose();
      temps.elapse(const Duration(minutes: 10));
      expect(appels, 12, reason: 'page quittee : plus aucune lecture');
    });
  });

  test('jamais deux lectures a la fois, meme si on insiste', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      int enVol = 0;
      int maxEnVol = 0;
      final LectureRythmee<int> l = LectureRythmee<int>(
        lire: () async {
          appels++;
          enVol++;
          if (enVol > maxEnVol) maxEnVol = enVol;
          // Une lecture tres lente : trois minutes.
          await Future<void>.delayed(const Duration(minutes: 3));
          enVol--;
          return appels;
        },
        delai: const Duration(minutes: 10),
      )..demarrer(visible: true);
      temps.elapse(const Duration(seconds: 30));
      l
        ..relire()
        ..relire()
        ..visible = false
        ..visible = true;
      temps.elapse(const Duration(minutes: 2));
      expect(appels, 1, reason: 'la lecture lente est toujours la seule');
      temps.elapse(const Duration(minutes: 30));
      expect(maxEnVol, 1);
      // Trois minutes de lecture, puis une minute d'attente : un cycle de 4.
      expect(appels, lessThanOrEqualTo(9));
      l.dispose();
    });
  });

  test('onglet cache : aucune lecture ; retour apres la minute : tout de '
      'suite', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      final LectureRythmee<int> l = LectureRythmee<int>(
        lire: () async => ++appels,
      )..demarrer(visible: true);
      temps.flushMicrotasks();
      expect(appels, 1);
      l.visible = false;
      temps.elapse(const Duration(hours: 3));
      expect(appels, 1, reason: 'cache pendant trois heures : rien');
      expect(temps.pendingTimers, isEmpty, reason: 'plus rien ne tourne');
      l.visible = true;
      temps.flushMicrotasks();
      expect(appels, 2, reason: 'au retour, tout de suite');
      expect(temps.pendingTimers.length, 1);
      temps.elapse(minute);
      expect(appels, 3);
      l.dispose();
    });
  });

  test(
    'retour avant la minute : pas de lecture en plus, le rythme reprend',
    () {
      fakeAsync((FakeAsync temps) {
        int appels = 0;
        final LectureRythmee<int> l = LectureRythmee<int>(
          lire: () async => ++appels,
        )..demarrer(visible: true);
        temps.flushMicrotasks();
        temps.elapse(const Duration(seconds: 20));
        // Dix allers et retours rapides sur l'onglet.
        for (int i = 0; i < 10; i++) {
          l
            ..visible = false
            ..visible = true;
          temps.elapse(const Duration(seconds: 1));
        }
        expect(appels, 1, reason: 'la minute n\'est pas passee');
        temps.elapse(const Duration(seconds: 30));
        expect(appels, 2, reason: 'une minute apres la premiere lecture');
        l.dispose();
      });
    },
  );

  test('demarrage onglet cache : rien avant qu\'il soit visible', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      final LectureRythmee<int> l = LectureRythmee<int>(
        lire: () async => ++appels,
      )..demarrer(visible: false);
      temps.elapse(const Duration(minutes: 5));
      expect(appels, 0);
      expect(l.etat.isLoading, isTrue);
      l.visible = true;
      temps.flushMicrotasks();
      expect(appels, 1);
      l.dispose();
    });
  });

  test('une lecture sans reponse est tenue pour perdue apres 12 s, et le '
      'rythme continue', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      final LectureRythmee<int> l = LectureRythmee<int>(
        lire: () {
          appels++;
          // La premiere ne repond jamais ; les suivantes repondent.
          return appels == 1 ? Completer<int>().future : Future<int>.value(7);
        },
      )..demarrer(visible: true);
      temps.elapse(const Duration(seconds: 11));
      expect(l.etat.isLoading, isTrue);
      temps.elapse(const Duration(seconds: 2));
      expect(l.etat.hasError, isTrue, reason: 'perdue a 12 s');
      temps.elapse(minute);
      expect(appels, 2);
      expect(l.etat.requireValue, 7);
      l.dispose();
    });
  });

  test('un echec garde les chiffres deja lus ; un premier echec se dit', () {
    fakeAsync((FakeAsync temps) {
      int appels = 0;
      bool panne = true;
      final LectureRythmee<int> l = LectureRythmee<int>(
        lire: () async {
          appels++;
          if (panne) throw StateError('panne');
          return appels;
        },
      )..demarrer(visible: true);
      temps.flushMicrotasks();
      expect(l.etat.hasError, isTrue);
      panne = false;
      l.relire();
      temps.flushMicrotasks();
      expect(l.etat.requireValue, 2);
      panne = true;
      temps.elapse(minute);
      expect(appels, 3);
      expect(l.etat.hasError, isFalse);
      expect(l.etat.requireValue, 2, reason: 'les chiffres lus restent');
      l.dispose();
    });
  });
}
