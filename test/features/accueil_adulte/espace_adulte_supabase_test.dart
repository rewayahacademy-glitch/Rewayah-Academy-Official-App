import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/tc_horloge/horloge_supabase.dart'
    show dateRendue;
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/espace_adulte_supabase.dart';
import 'package:rewayah_academy/features/accueil_adulte/historique_seances_adulte_page.dart';
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';

void main() {
  group('seancePasseeDepuisLigne', () {
    Map<String, dynamic> ligne({bool absent = false}) => <String, dynamic>{
      'session_id': 's1',
      'started_at': '2026-10-27T17:00:00Z',
      'ended_at': '2026-10-27T18:00:00Z',
      'status': 'ended',
      'groupe_id': 'g1',
      'teacher_id': 't1',
      'teacher_first_name': 'Hakim',
      'absent': absent,
      'jour_iso': 2,
      'date_locale': '2026-10-27',
    };

    test('lit la seance, la date rendue par le serveur et l absence', () {
      final SeancePasseeAdulte? s = seancePasseeDepuisLigne(
        ligne(absent: true),
      );
      expect(s, isNotNull);
      expect(s!.seance.id, 's1');
      expect(s.absence, isTrue);
      expect(s.dateRendue, dateRendue(jourIso: 2, dateIso: '2026-10-27'));
    });

    test('une presence ne porte aucune absence', () {
      expect(seancePasseeDepuisLigne(ligne())!.absence, isFalse);
    });

    test('une ligne sans date rendue ou sans bornes est ecartee', () {
      expect(
        seancePasseeDepuisLigne(ligne()..remove('date_locale')),
        isNull,
      );
      expect(seancePasseeDepuisLigne(ligne()..remove('started_at')), isNull);
    });
  });

  group('participantDepuisLigne', () {
    test('lit le prenom, la photo et la personne qui regarde', () {
      final ParticipantClasseAdulte? p = participantDepuisLigne(
        <String, dynamic>{
          'profile_id': 'a1',
          'prenom': 'Karim',
          'cle_avatar': 'avatars/a1.jpg',
          'est_moi': true,
        },
      );
      expect(p!.prenom, 'Karim');
      expect(p.cleAvatar, 'avatars/a1.jpg');
      expect(p.estMoi, isTrue);
    });

    test('une ligne sans prenom est ecartee', () {
      expect(
        participantDepuisLigne(<String, dynamic>{'profile_id': 'a1'}),
        isNull,
      );
    });
  });

  test('sans adaptateur, les trois lectures restent indisponibles', () async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    await expectLater(
      c.read(accueilAdulteProvider.future),
      throwsA(isA<CapaciteIndisponible>()),
    );
    await expectLater(
      c.read(maClasseAdulteProvider.future),
      throwsA(isA<CapaciteIndisponible>()),
    );
    await expectLater(
      c.read(historiqueSeancesAdulteProvider.future),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });
}
