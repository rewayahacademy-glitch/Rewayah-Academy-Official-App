// FUSEAUX (garde-cap, 04/11/2026) : sans heure du foyer rendue par
// horloge_seance, le bloc seance lit le fuseau du profil (mon_horloge) ;
// « Heure de cet appareil » ne reste que pour un profil sans fuseau.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';

import '../../fixtures/tuteur/faux_seances_famille.dart';

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() => poserMonHorlogePourTest(null));

  final DateTime debut = DateTime.utc(2026, 11, 6, 8);

  test('tuteur a Paris, sans heure du foyer : « Heure de Paris », 09:00', () {
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
    final AffichageSeance a = AffichageSeance.depuis(
      seanceFictive(debutUtc: debut),
      maintenantServeurUtc: DateTime.utc(2026, 11, 4, 7),
    );
    expect(a.heure, '09:00');
    expect(a.ville, 'Paris');
    expect(a.fuseau, isNot(t.tuteur.accueil.heureAppareil));
    expect(a.fuseau, contains('Paris'));
    expect(a.date, contains('6 novembre'));
  });

  test('profil sans fuseau : « Heure de cet appareil »', () {
    poserMonHorlogePourTest(
      MonHorloge.lire(const <String, Object?>{
        'maintenant': '2026-11-04T07:00:00Z',
        'moi': null,
      }),
    );
    final AffichageSeance a = AffichageSeance.depuis(
      seanceFictive(debutUtc: debut),
      maintenantServeurUtc: DateTime.utc(2026, 11, 4, 7),
    );
    expect(a.fuseau, t.tuteur.accueil.heureAppareil);
    expect(a.ville, isNull);
  });
}
