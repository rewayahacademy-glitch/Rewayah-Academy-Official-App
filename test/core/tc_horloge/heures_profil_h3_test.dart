// HEURES-PROFIL H3 (garde-cap, 12/11/2026) : frontieres de jour et
// construction d'instants au fuseau du PROFIL. C'est de la DONNEE : l'instant
// envoye au serveur doit etre l'inverse exact de l'heure choisie a l'ecran.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/admin_planning/planning_libelles.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';

MonHorloge _horloge(Map<String, Object?> moi) => MonHorloge.lire(
  <String, Object?>{'maintenant': '2026-11-12T12:00:00Z', 'moi': moi},
);

final MonHorloge _kolkata = _horloge(<String, Object?>{
  'fuseau': 'Asia/Kolkata',
  'decalage_secondes': 19800,
});

// Paris : +01:00 l'hiver, +02:00 apres le 28 mars 2027 a 01:00 UTC.
final MonHorloge _paris = _horloge(<String, Object?>{
  'fuseau': 'Europe/Paris',
  'decalage_secondes': 3600,
  'prochain_changement': '2027-03-28T01:00:00Z',
  'decalage_apres': 7200,
  'changement_suivant': '2027-10-31T01:00:00Z',
});

void main() {
  tearDown(() => poserMonHorlogePourTest(null));

  group('instantChezMoi : l inverse exact de chezMoi', () {
    test('+05:30 : 17:30 choisi le 12/11 est 12:00 UTC, et retour', () {
      poserMonHorlogePourTest(_kolkata);
      final DateTime i = instantChezMoi(2026, 11, 12, 17, 30);
      expect(i, DateTime.utc(2026, 11, 12, 12));
      expect(heureChezMoi(i), '17:30');
      expect(chezMoi(i).day, 12);
    });

    test('aller-retour sur une journee entiere, par pas de 15 minutes', () {
      for (final MonHorloge h in <MonHorloge>[_kolkata, _paris]) {
        poserMonHorlogePourTest(h);
        for (int m = 0; m < 24 * 60; m += 15) {
          final DateTime i = instantChezMoi(2026, 11, 12, m ~/ 60, m % 60);
          final DateTime retour = chezMoi(i);
          expect(
            (retour.year, retour.month, retour.day, retour.hour, retour.minute),
            (2026, 11, 12, m ~/ 60, m % 60),
          );
        }
      }
    });

    test('Paris apres le passage a l heure d ete : le decalage d apres', () {
      poserMonHorlogePourTest(_paris);
      final DateTime i = instantChezMoi(2027, 4, 1, 9);
      expect(i, DateTime.utc(2027, 4, 1, 7));
      expect(heureChezMoi(i), '09:00');
    });

    test('sans fuseau de profil : l heure de l appareil, comme avant', () {
      poserMonHorlogePourTest(null);
      expect(
        instantChezMoi(2026, 11, 12, 17, 30),
        DateTime(2026, 11, 12, 17, 30),
      );
    });
  });

  test('annonces : les creneaux proposes sont a 08:00 et 18:00 au profil', () {
    poserMonHorlogePourTest(_kolkata);
    // Mercredi 11/11 a 20:00 UTC : deja jeudi 12/11 01:30 a +05:30.
    final List<DateTime> c = creneauxProgrammation(
      DateTime.utc(2026, 11, 11, 20),
    );
    expect(c.map(heureChezMoi).toList(), <String>['08:00', '18:00', '08:00']);
    // Demain, au profil, est vendredi 13/11 (pas jeudi 12/11 de l'appareil).
    expect(chezMoi(c.first).day, 13);
    expect(c.first, DateTime.utc(2026, 11, 13, 2, 30));
    // Le lundi suivant : le 16/11.
    expect(chezMoi(c.last).day, 16);
  });

  test(
    'planning : une seance a 23:30 UTC est rangee au lendemain a +05:30',
    () {
      poserMonHorlogePourTest(_kolkata);
      final SeancePlanning tard = SeancePlanning(
        id: 's1',
        classe: 'Classe fictive',
        debut: DateTime.utc(2026, 11, 12, 23, 30),
        dureeMinutes: 45,
        statut: StatutSeance.planifiee,
      );
      final Map<DateTime, List<SeancePlanning>> jours = parJour(
        <SeancePlanning>[tard],
      );
      expect(jours.keys.single, DateTime(2026, 11, 13));
    },
  );
}
