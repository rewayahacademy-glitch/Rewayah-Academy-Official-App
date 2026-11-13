import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/journee.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/pause_prevue.dart';

final DateTime _jour = DateTime.utc(2026, 3, 11);

PausePrevue _pause(String seanceId, DateTime debut) => PausePrevue(
  seanceId: seanceId,
  debut: debut,
  duree: const Duration(minutes: 10),
  priere: Priere.dhuhr,
);

Seance _cours({
  required int heure,
  int minutes = 60,
  String id = 's1',
  StatutSeance statut = StatutSeance.planifiee,
}) {
  final DateTime debut = _jour.add(Duration(hours: heure));
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(Duration(minutes: minutes)),
    statut: statut,
    eleveId: 'e1',
    elevePrenom: 'Khadija',
    eleveIdentifiant: 'STUD-KB-000003',
    enseignantId: 't1',
    enseignantPrenom: 'Omar',
    enseignantIdentifiant: 'TEACH-OS-000001',
  );
}

void main() {
  group('La journee est une seule colonne', () {
    test('cours, pause et priere y sont des entrees de meme nature', () {
      // La pause que le serveur a placee a l'entree du Dhuhr.
      final DateTime dhuhr = _jour.add(const Duration(hours: 12, minutes: 20));
      // Un cours qui contient l'heure du dhuhr, et le suivant une demi-heure
      // apres. C'est la journee que ENS-02 doit rendre de haut en bas.
      final Seance premier = Seance(
        id: 's1',
        debut: dhuhr.subtract(const Duration(minutes: 30)),
        fin: dhuhr.add(const Duration(minutes: 30)),
        statut: StatutSeance.planifiee,
        eleveId: 'e1',
        elevePrenom: 'Khadija',
        eleveIdentifiant: 'STUD-KB-000003',
        enseignantId: 't1',
        enseignantPrenom: 'Omar',
        enseignantIdentifiant: 'TEACH-OS-000001',
      );
      final Seance second = Seance(
        id: 's2',
        debut: premier.fin.add(const Duration(minutes: 30)),
        fin: premier.fin.add(const Duration(minutes: 90)),
        statut: StatutSeance.planifiee,
        eleveId: 'e2',
        elevePrenom: 'Ibrahim',
        eleveIdentifiant: 'STUD-IB-000004',
        enseignantId: 't1',
        enseignantPrenom: 'Omar',
        enseignantIdentifiant: 'TEACH-OS-000001',
      );

      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[second, premier],
        pauses: <PausePrevue>[_pause('s1', dhuhr)],
        debut: premier.debut,
        fin: second.fin,
        pauseMaximale: const Duration(minutes: 30),
      );

      expect(journee.map((EntreeJournee e) => e.sorte), <SorteEntree>[
        SorteEntree.cours,
        SorteEntree.priere,
        SorteEntree.pause,
        SorteEntree.cours,
      ]);
      expect(journee[1].interruption?.priere, Priere.dhuhr);
      expect(journee[2].duree, const Duration(minutes: 30));
    });

    test('un trou plus long que la pause reglee n est pas une pause', () {
      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[
          _cours(heure: 9),
          _cours(heure: 14, id: 's2'),
        ],
        pauses: const <PausePrevue>[],
        debut: _jour,
        fin: _jour.add(const Duration(days: 1)),
        // La valeur vient de `regle_effective`, elle peut differer d'un profil
        // a l'autre : quatre heures d'ecart ne sont pas une pause.
        pauseMaximale: const Duration(minutes: 30),
      );

      expect(journee.map((EntreeJournee e) => e.sorte), <SorteEntree>[
        SorteEntree.cours,
        SorteEntree.cours,
      ]);
    });

    test('une pause plus longue devient une pause si la regle le dit', () {
      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[
          _cours(heure: 9),
          _cours(heure: 11, id: 's2'),
        ],
        pauses: const <PausePrevue>[],
        debut: _jour,
        fin: _jour.add(const Duration(days: 1)),
        pauseMaximale: const Duration(hours: 1),
      );

      expect(journee[1].sorte, SorteEntree.pause);
      expect(journee[1].duree, const Duration(hours: 1));
    });

    test(
      'une seance annulee ne tient aucune place et ne cree aucune pause',
      () {
        final List<EntreeJournee> journee = construireJournee(
          seances: <Seance>[
            _cours(heure: 9, statut: StatutSeance.annulee),
            _cours(heure: 10, id: 's2', statut: StatutSeance.annuleeTard),
            _cours(heure: 11, id: 's3'),
          ],
          pauses: const <PausePrevue>[],
          debut: _jour,
          fin: _jour.add(const Duration(days: 1)),
          pauseMaximale: const Duration(minutes: 30),
        );

        expect(journee.length, 1);
        expect(journee.single.seance?.id, 's3');
      },
    );

    test(
      'sans pause de priere placee, la colonne ne contient que les cours',
      () {
        final List<EntreeJournee> journee = construireJournee(
          seances: <Seance>[_cours(heure: 12)],
          pauses: const <PausePrevue>[],
          debut: _jour,
          fin: _jour.add(const Duration(days: 1)),
          pauseMaximale: const Duration(minutes: 30),
        );

        expect(journee.single.sorte, SorteEntree.cours);
      },
    );

    test('une seance hors de la fenetre ne s y invite pas', () {
      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[
          _cours(heure: 9),
          _cours(heure: 20, id: 's2'),
        ],
        pauses: const <PausePrevue>[],
        debut: _jour.add(const Duration(hours: 8)),
        fin: _jour.add(const Duration(hours: 12)),
        pauseMaximale: const Duration(minutes: 30),
      );

      expect(journee.single.seance?.id, 's1');
    });
  });

  group('Le bloc dominant de ENS-02', () {
    test('c est le premier cours dont la fin n est pas passee', () {
      final List<Seance> seances = <Seance>[
        _cours(heure: 9),
        _cours(heure: 11, id: 's2'),
        _cours(heure: 14, id: 's3'),
      ];

      // 10h30 : le cours de 9h est fini, celui de 11h est le prochain.
      expect(
        prochainCours(
          seances,
          _jour.add(const Duration(hours: 10, minutes: 30)),
        )?.id,
        's2',
      );
      // 9h30 : on est dedans, c'est lui qui domine, pas le suivant.
      expect(
        prochainCours(
          seances,
          _jour.add(const Duration(hours: 9, minutes: 30)),
        )?.id,
        's1',
      );
    });

    test('un cours qui deborde reste le bloc dominant', () {
      // La base le declare en cours alors que son heure de fin est passee. Sans
      // cette priorite, l'enseignant lirait le cours suivant alors qu'il est
      // encore dans le premier.
      final List<Seance> seances = <Seance>[
        _cours(heure: 9, statut: StatutSeance.enCours),
        _cours(heure: 11, id: 's2'),
      ];

      expect(
        prochainCours(
          seances,
          _jour.add(const Duration(hours: 10, minutes: 30)),
        )?.id,
        's1',
      );
    });

    test('une seance annulee ne peut pas etre le prochain cours', () {
      final List<Seance> seances = <Seance>[
        _cours(heure: 11, statut: StatutSeance.annulee),
        _cours(heure: 14, id: 's2', statut: StatutSeance.annuleeTard),
        _cours(heure: 16, id: 's3'),
      ];

      expect(
        prochainCours(seances, _jour.add(const Duration(hours: 10)))?.id,
        's3',
      );
    });

    test('le bloc n est pas borne a la journee courante', () {
      // La colonne dit ce qu'est aujourd'hui, ce bloc dit ce qui vient : un
      // enseignant dont la journee est finie doit lire quand il reprend.
      final Seance demain = _cours(heure: 33, id: 'demain');

      expect(
        prochainCours(<Seance>[
          demain,
        ], _jour.add(const Duration(hours: 20)))?.id,
        'demain',
      );
    });

    test('sans cours a venir, il n y a pas de bloc dominant', () {
      expect(
        prochainCours(<Seance>[
          _cours(heure: 9),
        ], _jour.add(const Duration(hours: 20))),
        isNull,
      );
      expect(prochainCours(const <Seance>[], _jour), isNull);
    });
  });

  group('Ce que ELV-02 annonce avant le cours', () {
    test(
      'l interruption d une seance est la pause que le serveur a placee',
      () {
        final DateTime dhuhr = _jour.add(
          const Duration(hours: 12, minutes: 20),
        );
        final PausePrevue pause = _pause('s1', dhuhr);

        expect(
          interruptionsDe(pause).map((InterruptionPriere i) => i.priere),
          <Priere>[Priere.dhuhr],
        );
        expect(interruptionsDe(pause).single.debut, dhuhr);
        expect(
          interruptionsDe(pause).single.duree,
          const Duration(minutes: 10),
        );
        // Tant que le serveur n'a placé aucune pause, rien n'est annonce : une
        // annonce inventee vaudrait moins que pas d'annonce du tout.
        expect(interruptionsDe(null), isEmpty);
      },
    );
  });
}
