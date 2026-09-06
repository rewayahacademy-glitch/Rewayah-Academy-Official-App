import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/journee.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';

const ReglagesPriere _paris = ReglagesPriere(
  enseignantId: 't1',
  latitude: 48.85341,
  longitude: 2.34880,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  lieu: 'Paris',
);

final DateTime _jour = DateTime.utc(2026, 3, 11);

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
      final DateTime dhuhr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;
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
        reglages: _paris,
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
        reglages: null,
        debut: _jour,
        fin: _jour.add(const Duration(days: 1)),
        // La valeur vient de `regle_effective`, elle peut differer d'un profil
        // a l'autre : quatre heures d'ecart ne sont pas une pause.
        pauseMaximale: const Duration(minutes: 30),
      );

      expect(
        journee.map((EntreeJournee e) => e.sorte),
        <SorteEntree>[SorteEntree.cours, SorteEntree.cours],
      );
    });

    test('une pause plus longue devient une pause si la regle le dit', () {
      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[
          _cours(heure: 9),
          _cours(heure: 11, id: 's2'),
        ],
        reglages: null,
        debut: _jour,
        fin: _jour.add(const Duration(days: 1)),
        pauseMaximale: const Duration(hours: 1),
      );

      expect(journee[1].sorte, SorteEntree.pause);
      expect(journee[1].duree, const Duration(hours: 1));
    });

    test('une seance annulee ne tient aucune place et ne cree aucune pause', () {
      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[
          _cours(heure: 9, statut: StatutSeance.annulee),
          _cours(heure: 10, id: 's2', statut: StatutSeance.annuleeTard),
          _cours(heure: 11, id: 's3'),
        ],
        reglages: null,
        debut: _jour,
        fin: _jour.add(const Duration(days: 1)),
        pauseMaximale: const Duration(minutes: 30),
      );

      expect(journee.length, 1);
      expect(journee.single.seance?.id, 's3');
    });

    test('sans reglages de priere, la colonne ne contient que les cours', () {
      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[_cours(heure: 12)],
        reglages: null,
        debut: _jour,
        fin: _jour.add(const Duration(days: 1)),
        pauseMaximale: const Duration(minutes: 30),
      );

      expect(journee.single.sorte, SorteEntree.cours);
    });

    test('une seance hors de la fenetre ne s y invite pas', () {
      final List<EntreeJournee> journee = construireJournee(
        seances: <Seance>[_cours(heure: 9), _cours(heure: 20, id: 's2')],
        reglages: null,
        debut: _jour.add(const Duration(hours: 8)),
        fin: _jour.add(const Duration(hours: 12)),
        pauseMaximale: const Duration(minutes: 30),
      );

      expect(journee.single.seance?.id, 's1');
    });
  });

  group('Ce que ELV-02 annonce avant le cours', () {
    test('les interruptions d une seance sont celles qui tombent dedans', () {
      final DateTime dhuhr = HorairesPriere.duJour(
        reglages: _paris,
        jour: _jour,
      )[Priere.dhuhr]!;
      final Seance seance = Seance(
        id: 's1',
        debut: dhuhr.subtract(const Duration(minutes: 20)),
        fin: dhuhr.add(const Duration(minutes: 40)),
        statut: StatutSeance.planifiee,
        eleveId: 'e1',
        elevePrenom: 'Khadija',
        eleveIdentifiant: 'STUD-KB-000003',
        enseignantId: 't1',
        enseignantPrenom: 'Omar',
        enseignantIdentifiant: 'TEACH-OS-000001',
      );

      expect(
        interruptionsDe(seance, _paris).map((InterruptionPriere i) => i.priere),
        <Priere>[Priere.dhuhr],
      );
      // Tant que l'enseignant n'a pas pose ses reglages, rien n'est annonce :
      // une annonce inventee vaudrait moins que pas d'annonce du tout.
      expect(interruptionsDe(seance, null), isEmpty);
    });
  });
}
