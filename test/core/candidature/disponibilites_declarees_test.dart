// CAND-01 : les disponibilites declarees, heure par heure. Les heures de debut
// que la personne choisit deviennent les plages d'heures entieres que le
// serveur attend (`private.questionnaire_creneaux`, CAND-L2A1, C18) ; un
// controle independant rejoue les regles du serveur sur ce qui sort.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/disponibilites_declarees.dart';

DisponibilitesDeclarees _d(Map<int, Set<int>> debuts) =>
    DisponibilitesDeclarees(debuts);

/// Les regles du serveur sur une liste de plages (`questionnaire_creneaux`),
/// rejouees ici : `true` quand le serveur l'accepterait.
bool _accepteParLeServeur(List<Map<String, Object?>> plages) {
  if (plages.isEmpty || plages.length > 168) {
    return false;
  }
  final RegExp debut = RegExp(r'^([01][0-9]|2[0-3]):00$');
  final RegExp fin = RegExp(r'^(([01][0-9]|2[0-3]):00|24:00)$');
  for (final Map<String, Object?> p in plages) {
    if (p.keys.toSet().difference(<String>{
          'jour',
          'debut',
          'fin',
        }).isNotEmpty ||
        p.length != 3) {
      return false;
    }
    final Object? jour = p['jour'];
    if (jour is! int || jour < 1 || jour > 7) {
      return false;
    }
    if (!debut.hasMatch(p['debut']! as String) ||
        !fin.hasMatch(p['fin']! as String)) {
      return false;
    }
    final int d = int.parse((p['debut']! as String).substring(0, 2));
    final int f = int.parse((p['fin']! as String).substring(0, 2));
    if (f <= d) {
      return false;
    }
  }
  // Deux plages d'un meme jour ne se recouvrent pas.
  for (int i = 0; i < plages.length; i++) {
    for (int j = i + 1; j < plages.length; j++) {
      if (plages[i]['jour'] != plages[j]['jour']) {
        continue;
      }
      final int d1 = int.parse((plages[i]['debut']! as String).substring(0, 2));
      final int f1 = int.parse((plages[i]['fin']! as String).substring(0, 2));
      final int d2 = int.parse((plages[j]['debut']! as String).substring(0, 2));
      final int f2 = int.parse((plages[j]['fin']! as String).substring(0, 2));
      if (d1 < f2 && d2 < f1) {
        return false;
      }
    }
  }
  return true;
}

void main() {
  group('les heures de debut deviennent des plages d heures entieres', () {
    test(
      'des enfants (60 minutes) : une heure de debut, une heure declaree',
      () {
        final DisponibilitesDeclarees d = _d(<int, Set<int>>{
          1: <int>{18},
        });
        expect(d.versPlages(dureeSeanceEnfantMinutes), <Map<String, Object?>>[
          <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '19:00'},
        ]);
      },
    );

    test('des heures qui se suivent forment une seule plage', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        1: <int>{18, 19, 20},
      });
      expect(d.versPlages(60), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '21:00'},
      ]);
    });

    test('des heures separees font deux plages du meme jour', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        2: <int>{9, 10, 18},
      });
      expect(d.versPlages(60), <Map<String, Object?>>[
        <String, Object?>{'jour': 2, 'debut': '09:00', 'fin': '11:00'},
        <String, Object?>{'jour': 2, 'debut': '18:00', 'fin': '19:00'},
      ]);
    });

    test('des adultes (90 minutes) : l heure suivante est declaree aussi', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        1: <int>{18},
      });
      expect(d.versPlages(dureeSeanceAdulteMinutes), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
      ]);
    });

    test('des adultes : 18 h et 20 h se rejoignent (18-20 puis 20-22)', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        1: <int>{18, 20},
      });
      expect(d.versPlages(90), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '22:00'},
      ]);
    });

    test('un cours qui passe minuit : deux plages, une par jour', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        3: <int>{23},
      });
      expect(d.versPlages(90), <Map<String, Object?>>[
        <String, Object?>{'jour': 3, 'debut': '23:00', 'fin': '24:00'},
        <String, Object?>{'jour': 4, 'debut': '00:00', 'fin': '01:00'},
      ]);
    });

    test('le dimanche soir rejoint le lundi matin', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        7: <int>{23},
      });
      expect(d.versPlages(90), <Map<String, Object?>>[
        <String, Object?>{'jour': 1, 'debut': '00:00', 'fin': '01:00'},
        <String, Object?>{'jour': 7, 'debut': '23:00', 'fin': '24:00'},
      ]);
    });

    test('23 h pour des enfants reste dans la journee', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        3: <int>{23},
      });
      expect(d.versPlages(60), <Map<String, Object?>>[
        <String, Object?>{'jour': 3, 'debut': '23:00', 'fin': '24:00'},
      ]);
    });

    test('aucun jour, aucune plage', () {
      expect(const DisponibilitesDeclarees().versPlages(60), isEmpty);
      expect(const DisponibilitesDeclarees().estVide, isTrue);
    });

    test('les plages sont dans l ordre des jours puis des heures', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        5: <int>{20},
        1: <int>{8},
        3: <int>{14},
      });
      expect(
        d.versPlages(60).map((Map<String, Object?> p) => p['jour']).toList(),
        <Object?>[1, 3, 5],
      );
    });

    test('sans fuseau ni demi-heure : la forme exacte du serveur', () {
      final List<Map<String, Object?>> plages = _d(<int, Set<int>>{
        1: <int>{18},
      }).versPlages(60);
      for (final Map<String, Object?> p in plages) {
        expect(p.keys.toSet(), <String>{'jour', 'debut', 'fin'});
        expect(p['debut'], matches(RegExp(r'^\d\d:00$')));
        expect(p['fin'], matches(RegExp(r'^\d\d:00$')));
      }
    });
  });

  group('ce que le serveur accepte', () {
    test(
      'toute combinaison d heures donne des plages que le serveur accepte',
      () {
        final math.Random hasard = math.Random(22102026);
        for (int essai = 0; essai < 400; essai++) {
          final Map<int, Set<int>> debuts = <int, Set<int>>{
            for (int jour = 1; jour <= 7; jour++)
              if (hasard.nextBool())
                jour: <int>{
                  for (int h = 0; h < 24; h++)
                    if (hasard.nextInt(3) == 0) h,
                },
          };
          final DisponibilitesDeclarees d = _d(debuts);
          if (d.estVide) {
            continue;
          }
          for (final int duree in <int>[60, 90]) {
            final List<Map<String, Object?>> plages = d.versPlages(duree);
            expect(
              _accepteParLeServeur(plages),
              isTrue,
              reason: 'duree $duree, essai $essai : $plages',
            );
          }
        }
      },
    );

    test('les 168 heures de la semaine tiennent dans 168 plages au plus', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        for (int jour = 1; jour <= 7; jour++)
          jour: <int>{0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22},
      });
      final List<Map<String, Object?>> plages = d.versPlages(60);
      expect(plages.length, 7 * 12);
      expect(_accepteParLeServeur(plages), isTrue);
    });

    test('le controle du test refuse bien ce que le serveur refuse', () {
      expect(_accepteParLeServeur(<Map<String, Object?>>[]), isFalse);
      expect(
        _accepteParLeServeur(<Map<String, Object?>>[
          <String, Object?>{'jour': 1, 'debut': '08:30', 'fin': '12:00'},
        ]),
        isFalse,
      );
      expect(
        _accepteParLeServeur(<Map<String, Object?>>[
          <String, Object?>{'jour': 1, 'debut': '08:00', 'fin': '12:00'},
          <String, Object?>{'jour': 1, 'debut': '11:00', 'fin': '13:00'},
        ]),
        isFalse,
      );
      expect(
        _accepteParLeServeur(<Map<String, Object?>>[
          <String, Object?>{'jour': 1, 'debut': '08:00', 'fin': '12:00'},
          <String, Object?>{'jour': 1, 'debut': '12:00', 'fin': '13:00'},
        ]),
        isTrue,
      );
    });
  });

  group('relire des plages', () {
    test('des enfants : chaque heure declaree est un debut possible', () {
      final DisponibilitesDeclarees d = DisponibilitesDeclarees.depuisPlages(
        const <Map<String, Object?>>[
          <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '21:00'},
        ],
        dureeMinutes: 60,
      );
      expect(d.debuts(1), <int>[18, 19, 20]);
      expect(d.jours, <int>[1]);
    });

    test(
      'des adultes : un debut doit tenir 90 minutes dans les heures declarees',
      () {
        final DisponibilitesDeclarees d = DisponibilitesDeclarees.depuisPlages(
          const <Map<String, Object?>>[
            <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '21:00'},
          ],
          dureeMinutes: 90,
        );
        // 18 h (18 et 19), 19 h (19 et 20) ; 20 h demanderait 21, non declaree.
        expect(d.debuts(1), <int>[18, 19]);
      },
    );

    test('un cours d adultes de 23 h demande le lendemain a 0 h', () {
      final DisponibilitesDeclarees d = DisponibilitesDeclarees.depuisPlages(
        const <Map<String, Object?>>[
          <String, Object?>{'jour': 3, 'debut': '23:00', 'fin': '24:00'},
          <String, Object?>{'jour': 4, 'debut': '00:00', 'fin': '01:00'},
        ],
        dureeMinutes: 90,
      );
      expect(d.debuts(3), <int>[23]);
      expect(d.debuts(4), isEmpty);
      final DisponibilitesDeclarees seule =
          DisponibilitesDeclarees.depuisPlages(const <Map<String, Object?>>[
            <String, Object?>{'jour': 3, 'debut': '23:00', 'fin': '24:00'},
          ], dureeMinutes: 90);
      expect(seule.estVide, isTrue);
    });

    test(
      'aller et retour : les debuts consecutifs reviennent a l identique',
      () {
        for (final int duree in <int>[60, 90]) {
          final DisponibilitesDeclarees d = _d(<int, Set<int>>{
            1: <int>{18, 19, 20},
            3: <int>{9},
            6: <int>{14, 15},
          });
          final DisponibilitesDeclarees relue =
              DisponibilitesDeclarees.depuisPlages(
                d.versPlages(duree),
                dureeMinutes: duree,
              );
          expect(relue, d, reason: 'duree $duree');
        }
      },
    );

    test('une valeur mal formee ne donne aucune disponibilite', () {
      for (final Object? mauvais in <Object?>[
        null,
        'lundi',
        <String, Object?>{'fuseau': 'Europe/Paris', 'creneaux': <Object>[]},
        <Object?>[
          <String, Object?>{'jour': 8, 'debut': '08:00', 'fin': '09:00'},
        ],
        <Object?>[
          <String, Object?>{'jour': 1, 'debut': '08:30', 'fin': '09:00'},
        ],
        <Object?>[
          <String, Object?>{'jour': 1, 'debut': '09:00', 'fin': '09:00'},
        ],
        <Object?>[
          <String, Object?>{'jour': 1, 'debut': '09:00', 'fin': '25:00'},
        ],
        <Object?>[
          <String, Object?>{'jour': '1', 'debut': '09:00', 'fin': '10:00'},
        ],
        <Object?>['x'],
      ]) {
        expect(
          DisponibilitesDeclarees.depuisPlages(
            mauvais,
            dureeMinutes: 60,
          ).estVide,
          isTrue,
          reason: '$mauvais',
        );
        expect(DisponibilitesDeclarees.plagesBienFormees(mauvais), isFalse);
      }
    });

    test('une fin a 24:00 est bien formee', () {
      expect(
        DisponibilitesDeclarees.plagesBienFormees(<Object?>[
          <String, Object?>{'jour': 7, 'debut': '22:00', 'fin': '24:00'},
        ]),
        isTrue,
      );
    });
  });

  group('ce que la personne enseigne', () {
    test('18 h, 60 minutes : de 18 h a 19 h', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        1: <int>{18},
      });
      expect(d.intervalles(1, 60), const <IntervalleCours>[
        IntervalleCours(1080, 1140),
      ]);
    });

    test('18 h, 90 minutes : de 18 h a 19 h 30', () {
      final DisponibilitesDeclarees d = _d(<int, Set<int>>{
        1: <int>{18},
      });
      expect(d.intervalles(1, 90), const <IntervalleCours>[
        IntervalleCours(1080, 1170),
      ]);
    });

    test('des cours qui se touchent ou se recouvrent se fusionnent', () {
      expect(
        intervallesDesCours(<int>[18, 19, 20], 90),
        const <IntervalleCours>[IntervalleCours(1080, 1290)],
      );
      expect(
        intervallesDesCours(<int>[18, 19, 20], 60),
        const <IntervalleCours>[IntervalleCours(1080, 1260)],
      );
      expect(intervallesDesCours(<int>[9, 18], 60), const <IntervalleCours>[
        IntervalleCours(540, 600),
        IntervalleCours(1080, 1140),
      ]);
    });

    test('heuresTouchees compte chaque heure entiere que le cours touche', () {
      expect(heuresTouchees(18, 60).toList(), <int>[18]);
      expect(heuresTouchees(18, 90).toList(), <int>[18, 19]);
      expect(heuresTouchees(23, 90).toList(), <int>[23, 24]);
    });

    test('trois seances par semaine, 60 et 90 minutes', () {
      expect(seancesParClasse, 3);
      expect(dureeSeanceEnfantMinutes, 60);
      expect(dureeSeanceAdulteMinutes, 90);
    });
  });
}
