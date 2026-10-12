// LIVE-CHRONO-01 : le chrono est une fonction pure des horodatages.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/fenetre_seance.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 10, 12, 18);
  final BornesChrono bornes = BornesChrono(
    debutUtc: t0,
    finPrevueUtc: t0.add(const Duration(minutes: 45)),
  );

  group('ChronoSeance.a', () {
    test('la duree vient des bornes de la seance', () {
      expect(bornes.duree, const Duration(minutes: 45));
    });

    test('avant T0 : rien a dire', () {
      final ChronoSeance c = ChronoSeance.a(
        bornes,
        t0.subtract(const Duration(seconds: 1)),
      );
      expect(c.phase, PhaseChrono.avantDebut);
      expect(c.visible, isFalse);
    });

    test('a T0 : zero ecoule, toute la duree restante', () {
      final ChronoSeance c = ChronoSeance.a(bornes, t0);
      expect(c.phase, PhaseChrono.enCours);
      expect(c.ecoule, Duration.zero);
      expect(c.restant, const Duration(minutes: 45));
      expect(c.visible, isTrue);
    });

    test('pendant la seance : ecoule + restant = duree, toujours', () {
      for (int s = 0; s < 45 * 60; s += 37) {
        final ChronoSeance c = ChronoSeance.a(
          bornes,
          t0.add(Duration(seconds: s)),
        );
        expect(c.ecoule + c.restant, bornes.duree, reason: 'a $s s');
        expect(c.ecoule, Duration(seconds: s));
      }
    });

    test('a la fin prevue : 00:00:00 et « temps prevu ecoule »', () {
      final ChronoSeance c = ChronoSeance.a(bornes, bornes.finPrevueUtc);
      expect(c.phase, PhaseChrono.prevuEcoule);
      expect(c.prevuEcoule, isTrue);
      expect(c.restant, Duration.zero);
      expect(formaterChrono(c.restant), '00:00:00');
    });

    test('apres la fin prevue : jamais de temps negatif', () {
      for (final Duration apres in <Duration>[
        const Duration(seconds: 1),
        const Duration(minutes: 3),
        const Duration(hours: 5),
        const Duration(days: 40),
      ]) {
        final ChronoSeance c = ChronoSeance.a(
          bornes,
          bornes.finPrevueUtc.add(apres),
        );
        expect(c.phase, PhaseChrono.prevuEcoule);
        expect(c.restant.isNegative, isFalse);
        expect(c.ecoule, bornes.duree, reason: 'borne a la duree prevue');
        expect(formaterChrono(c.restant), isNot(contains('-')));
      }
    });

    test('un instant donne dans un autre fuseau donne le meme chrono', () {
      final DateTime local = DateTime.parse('2026-10-12T20:12:34+02:00');
      final ChronoSeance a = ChronoSeance.a(bornes, local);
      final ChronoSeance b = ChronoSeance.a(
        bornes,
        DateTime.utc(2026, 10, 12, 18, 12, 34),
      );
      expect(a, b);
      expect(a.ecoule, const Duration(minutes: 12, seconds: 34));
    });

    test('recalcul apres une longue absence : aucune derive', () {
      // Un minuteur endormi trois heures n'a rien cumule : le temps se lit
      // depuis les horodatages, jamais depuis un compteur.
      final ChronoSeance avant = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 10)),
      );
      final ChronoSeance apres = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 30)),
      );
      expect(avant.ecoule, const Duration(minutes: 10));
      expect(apres.ecoule, const Duration(minutes: 30));
      expect(apres.restant, const Duration(minutes: 15));
    });

    test('depuis une FenetreSeance : T0 et fin prevue', () {
      final FenetreSeance fenetre = FenetreSeance(
        debutUtc: t0,
        finPrevueUtc: t0.add(const Duration(minutes: 30)),
        fenetreAcces: const Duration(minutes: 20),
        graceApresFin: const Duration(minutes: 15),
      );
      expect(
        BornesChrono.depuisFenetre(fenetre).duree,
        const Duration(minutes: 30),
      );
    });
  });

  group('minutes annoncees au lecteur d\'ecran', () {
    test('ecoulees et restantes changent a la meme seconde', () {
      // Duree non ronde (45 min 30 s) : sans derivation commune, le lecteur
      // annoncerait deux fois par minute.
      final BornesChrono b = BornesChrono(
        debutUtc: t0,
        finPrevueUtc: t0.add(const Duration(minutes: 45, seconds: 30)),
      );
      String? precedent;
      int annonces = 0;
      for (int s = 0; s < 3 * 60; s++) {
        final ChronoSeance c = ChronoSeance.a(b, t0.add(Duration(seconds: s)));
        final String cle = '${c.minutesEcoulees}/${c.minutesRestantes}';
        if (cle != precedent) {
          annonces++;
        }
        precedent = cle;
      }
      expect(annonces, 3, reason: 'une annonce par minute, pas par seconde');
    });

    test('a T0 : 0 minute ecoulee, la duree entiere restante', () {
      final ChronoSeance c = ChronoSeance.a(bornes, t0);
      expect(c.minutesEcoulees, 0);
      expect(c.minutesRestantes, 45);
    });

    test('jamais de minutes restantes negatives', () {
      final ChronoSeance c = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 44, seconds: 59)),
      );
      expect(c.minutesRestantes, 1);
    });
  });

  group('formaterChrono', () {
    test('HH:MM:SS avec deux chiffres par champ', () {
      expect(formaterChrono(Duration.zero), '00:00:00');
      expect(
        formaterChrono(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
      expect(formaterChrono(const Duration(minutes: 45)), '00:45:00');
      expect(
        formaterChrono(const Duration(hours: 12, seconds: 59)),
        '12:00:59',
      );
    });

    test('une duree negative est ramenee a zero', () {
      expect(formaterChrono(const Duration(seconds: -5)), '00:00:00');
    });
  });

  group('pauses (LIVE-PAUSE-01)', () {
    test('une pause terminee sort du temps ecoule, pas du temps restant', () {
      final PauseChrono pause = PauseChrono(
        debutUtc: t0.add(const Duration(minutes: 20)),
        finUtc: t0.add(const Duration(minutes: 30)),
      );
      final ChronoSeance c = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 35)),
        pauses: <PauseChrono>[pause],
      );
      expect(c.ecoule, const Duration(minutes: 25), reason: '35 - 10 de pause');
      expect(c.restant, const Duration(minutes: 10), reason: 'fin prevue fixe');
      expect(c.pause, const Duration(minutes: 10));
      expect(c.enPause, isFalse);
    });

    test('pendant la pause : le temps ecoule est fige, le restant court', () {
      final PauseChrono pause = PauseChrono(
        debutUtc: t0.add(const Duration(minutes: 20)),
      );
      final ChronoSeance a = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 22)),
        pauses: <PauseChrono>[pause],
      );
      final ChronoSeance b = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 27)),
        pauses: <PauseChrono>[pause],
      );
      expect(a.enPause, isTrue);
      expect(a.ecoule, const Duration(minutes: 20));
      expect(b.ecoule, const Duration(minutes: 20), reason: 'fige');
      expect(b.restant, a.restant - const Duration(minutes: 5));
    });

    test('une pause avant T0 ou apres maintenant ne compte pas', () {
      final ChronoSeance c = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 10)),
        pauses: <PauseChrono>[
          PauseChrono(
            debutUtc: t0.subtract(const Duration(minutes: 30)),
            finUtc: t0.subtract(const Duration(minutes: 20)),
          ),
          PauseChrono(debutUtc: t0.add(const Duration(minutes: 15))),
        ],
      );
      expect(c.ecoule, const Duration(minutes: 10));
      expect(c.enPause, isFalse);
    });

    test('jamais negatif, meme avec des pauses qui se chevauchent', () {
      final ChronoSeance c = ChronoSeance.a(
        bornes,
        t0.add(const Duration(minutes: 10)),
        pauses: <PauseChrono>[
          PauseChrono(debutUtc: t0),
          PauseChrono(debutUtc: t0),
        ],
      );
      expect(c.ecoule.isNegative, isFalse);
      expect(c.restant.isNegative, isFalse);
    });

    test('apres la fin prevue : « temps prevu ecoule », pauses ou non', () {
      final ChronoSeance c = ChronoSeance.a(
        bornes,
        bornes.finPrevueUtc.add(const Duration(minutes: 3)),
        pauses: <PauseChrono>[PauseChrono(debutUtc: t0)],
      );
      expect(c.prevuEcoule, isTrue);
      expect(c.restant, Duration.zero);
    });

    test('annonce : jamais deux changements a moins d\'une minute', () {
      final PauseChrono pause = PauseChrono(
        debutUtc: t0.add(const Duration(minutes: 20, seconds: 17)),
        finUtc: t0.add(const Duration(minutes: 22, seconds: 41)),
      );
      String? precedent;
      final List<int> instants = <int>[];
      for (int s = 0; s < 8 * 60; s++) {
        final ChronoSeance c = ChronoSeance.a(
          bornes,
          t0.add(Duration(minutes: 19, seconds: s)),
          pauses: <PauseChrono>[pause],
        );
        final String cle = '${c.minutesEcoulees}/${c.minutesRestantes}';
        if (precedent != null && cle != precedent) {
          instants.add(s);
        }
        precedent = cle;
      }
      for (int i = 1; i < instants.length; i++) {
        expect(
          instants[i] - instants[i - 1],
          greaterThanOrEqualTo(1),
          reason: 'changements aux secondes $instants',
        );
      }
      // Hors bordure d'une pause, une annonce par minute : au plus
      // `minutes + 2` changements sur huit minutes (un par minute, plus la
      // reprise apres la pause).
      expect(instants.length, lessThanOrEqualTo(8 + 2));
    });
  });
}
