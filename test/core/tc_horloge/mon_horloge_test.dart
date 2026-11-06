// FUSEAUX : l'heure d'une personne vient du fuseau de son profil (mon_horloge),
// sinon de l'appareil, dit comme tel ; jamais une heure fausse apres un
// changement d'heure non decrit.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

void main() {
  tearDown(() => poserMonHorlogePourTest(null));

  test('le fuseau du profil : 07:00 UTC fait 08:00 a Paris l hiver', () {
    poserMonHorlogePourTest(
      MonHorloge.lire(const <String, Object?>{
        'maintenant': '2026-11-04T07:00:00Z',
        'moi': <String, Object?>{
          'fuseau': 'Europe/Paris',
          'decalage_secondes': 3600,
          'prochain_changement': '2027-03-28T01:00:00Z',
          'decalage_apres': 7200,
          'changement_suivant': '2027-10-31T01:00:00Z',
        },
      }),
    );
    expect(heureChezMoi(DateTime.utc(2026, 11, 4, 7)), '08:00');
    // Apres le passage a l'heure d'ete : le decalage d'apres.
    expect(heureChezMoi(DateTime.utc(2027, 4, 1, 7)), '09:00');
    expect(estHeureDeLAppareil(DateTime.utc(2026, 11, 4, 7)), isFalse);
    // Le jour civil suit le fuseau : 23:30 UTC est le lendemain a Paris.
    expect(chezMoi(DateTime.utc(2026, 11, 4, 23, 30)).day, 5);
  });

  test('profil sans fuseau : l heure de l appareil, et l ecran le sait', () {
    poserMonHorlogePourTest(
      MonHorloge.lire(const <String, Object?>{
        'maintenant': '2026-11-04T07:00:00Z',
        'moi': null,
      }),
    );
    final DateTime instant = DateTime.utc(2026, 11, 4, 7);
    expect(chezMoi(instant), instant.toLocal());
    expect(estHeureDeLAppareil(instant), isTrue);
  });

  test('sans lecture : l heure de l appareil', () {
    final DateTime instant = DateTime.utc(2026, 11, 4, 7);
    expect(chezMoi(instant), instant.toLocal());
    expect(estHeureDeLAppareil(instant), isTrue);
  });

  test('une reponse sans instant serveur est refusee', () {
    expect(
      () => MonHorloge.lire(const <String, Object?>{'moi': null}),
      throwsFormatException,
    );
  });

  // Constat du 05/11/2026 : le flux d'authentification rejoue son dernier
  // evenement a chaque abonne ; relire sur ce rejeu bouclait sans fin.
  group('relire seulement quand le compte change', () {
    test('rejeu de la connexion du meme compte : pas de relecture', () {
      expect(compteAChange(AuthChangeEvent.signedIn, 'a', 'a'), isFalse);
    });
    test('connexion d un autre compte, ou depuis aucun : relecture', () {
      expect(compteAChange(AuthChangeEvent.signedIn, 'b', 'a'), isTrue);
      expect(compteAChange(AuthChangeEvent.signedIn, 'a', null), isTrue);
    });
    test('deconnexion : relecture seulement si un compte etait lu', () {
      expect(compteAChange(AuthChangeEvent.signedOut, null, 'a'), isTrue);
      expect(compteAChange(AuthChangeEvent.signedOut, null, null), isFalse);
    });
    test('jeton renouvele, session initiale : pas de relecture', () {
      expect(compteAChange(AuthChangeEvent.tokenRefreshed, 'a', 'a'), isFalse);
      expect(compteAChange(AuthChangeEvent.initialSession, 'a', 'a'), isFalse);
    });
  });
}
