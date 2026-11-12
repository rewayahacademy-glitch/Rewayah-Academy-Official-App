// HEURES-PROFIL H1 (garde-cap, 12/11/2026) : les heures des ecrans famille,
// eleve et enseignant se lisent au fuseau du PROFIL, jamais a celui de
// l'appareil. Un fuseau de profil a +05:30 (Asia/Kolkata), different de
// l'appareil de test : 12:00 UTC doit se dire 17:30.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/accueil_eleve/apres_seance_accessibilite.dart';
import 'package:rewayah_academy/features/appareils/liste_appareils_eleve.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/foyer/fiche/mouvements_page.dart';
import 'package:rewayah_academy/features/journee/absence_remplacement_vue.dart';

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    poserMonHorlogePourTest(
      MonHorloge.lire(const <String, Object?>{
        'maintenant': '2026-11-12T12:00:00Z',
        'moi': <String, Object?>{
          'fuseau': 'Asia/Kolkata',
          'decalage_secondes': 19800,
        },
      }),
    );
  });
  tearDown(() => poserMonHorlogePourTest(null));

  final DateTime midi = DateTime.utc(2026, 11, 12, 12);
  // L'appareil de test n'est pas a +05:30 : sans le lot, ces heures seraient
  // celles de l'appareil.
  test('l appareil de test n est pas au fuseau du profil', () {
    expect(midi.toLocal().timeZoneOffset, isNot(const Duration(minutes: 330)));
  });

  test('remplacements et absence : hhmmAbsence', () {
    expect(hhmmAbsence(midi), '17:30');
    // Une valeur deja passee par toLocal (les adaptateurs) donne la meme.
    expect(hhmmAbsence(midi.toLocal()), '17:30');
  });

  test('messages : momentCourt et horodatageMessage', () {
    expect(momentCourt(midi, midi.add(const Duration(minutes: 5))), '17:30');
    // 20:00 UTC est deja le lendemain au fuseau du profil (01:30) : le jour
    // civil suit le profil, pas l'appareil.
    final DateTime soir = DateTime.utc(2026, 11, 12, 20);
    expect(momentCourt(soir, soir), '01:30');
    expect(horodatageMessage(midi), contains('17:30'));
  });

  test('appareils, mouvements, prochaine seance', () {
    expect(dateLisible(midi), contains('17:30'));
    expect(dateHeureMouvement(midi), contains('17:30'));
    expect(ApresSeanceAccessibilite.libelleProchaine(midi), contains('17:30'));
  });
}
