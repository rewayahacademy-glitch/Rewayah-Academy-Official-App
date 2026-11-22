// PARCOURS-BOUT-EN-BOUT, partie B (directeur, 22/11/2026 : « bien travailler les
// fuseaux horaires, sinon ce sera dangereux ») :
// - l'apercu d'une offre dit l'heure de La Mecque en second, avec le jour
//   quand il change, et rien quand c'est la meme heure ou que le serveur ne
//   la rend pas ;
// - une date montree a la famille dit son fuseau (ville ou appareil), puis
//   La Mecque ;
// - l'avertissement « cet appareil n'est pas a l'heure de votre ville » :
//   seulement quand la ville est choisie, lue, et differente ;
// - le formulaire d'offre de la direction propose Asia/Riyadh d'abord.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_creneau.dart';
import 'package:rewayah_academy/core/tc_horloge/apercu_offre.dart';
import 'package:rewayah_academy/core/tc_horloge/avertissement_fuseau.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/quand_avec_fuseau.dart';
import 'package:rewayah_academy/features/admin_offres/offres_libelles.dart';

import '../../support/monter_recrutement.dart';

MonHorloge _horloge({
  required String ville,
  required int decalageVille,
  bool? lieuChoisi = true,
}) => MonHorloge.lire(<String, Object?>{
  'maintenant': '2026-11-20T09:00:00Z',
  'moi': <String, Object?>{'fuseau': ville, 'decalage_secondes': decalageVille},
  'academie': <String, Object?>{
    'fuseau': 'Asia/Riyadh',
    'decalage_secondes': 10800,
  },
  'lieu_choisi': ?lieuChoisi,
});

void main() {
  setUp(() => poserMonHorlogePourTest(null));
  tearDown(() => poserMonHorlogePourTest(null));

  test('le formulaire d\'offre propose Asia/Riyadh par defaut', () {
    expect(fuseauParDefaut, 'Asia/Riyadh');
    expect(fuseauxProposes, contains('Asia/Riyadh'));
  });

  group('phraseMecqueApercu', () {
    test('l\'heure de La Mecque, en second', () {
      const ApercuCreneau c = ApercuCreneau(
        jourMaintenant: 3,
        heureMaintenant: '18:00',
        meme: true,
        mecque: '20:00',
        jourMecque: 3,
      );
      expect(
        phraseMecqueApercu(c),
        t.tc.groupe.horloges.mecqueEnSecond(heure: '20:00'),
      );
    });

    test('le jour est dit quand il change', () {
      const ApercuCreneau c = ApercuCreneau(
        jourMaintenant: 3,
        heureMaintenant: '22:00',
        meme: true,
        mecque: '00:00',
        jourMecque: 4,
      );
      expect(phraseMecqueApercu(c), contains(t.disponibilites.joursLongs[3]));
    });

    test('rien quand c\'est la meme heure, ou quand le serveur se tait', () {
      const ApercuCreneau pareil = ApercuCreneau(
        jourMaintenant: 3,
        heureMaintenant: '20:00',
        meme: true,
        mecque: '20:00',
        jourMecque: 3,
      );
      const ApercuCreneau muet = ApercuCreneau(
        jourMaintenant: 3,
        heureMaintenant: '20:00',
        meme: true,
      );
      expect(phraseMecqueApercu(pareil), isNull);
      expect(phraseMecqueApercu(muet), isNull);
    });

    test('lit les cles mecque et jour_mecque du serveur', () {
      final ApercuCreneau? c = ApercuCreneau.lire(<String, Object?>{
        'jour_maintenant': 3,
        'maintenant': '17:00',
        'meme': true,
        'mecque': '20:00',
        'jour_mecque': 3,
      });
      expect(c?.mecque, '20:00');
      expect(c?.jourMecque, 3);
    });
  });

  group('quandAvecFuseau', () {
    final DateTime instant = DateTime.utc(2026, 11, 20, 9);

    test('sans ville choisie : l\'heure de l\'appareil, dite', () {
      poserMonHorlogePourTest(
        _horloge(ville: 'Africa/Conakry', decalageVille: 0, lieuChoisi: false),
      );
      expect(
        quandAvecFuseau(instant).toLowerCase(),
        contains(t.lieu.heureAppareil.toLowerCase()),
      );
    });

    test('avec la ville de l\'appareil : le nom de la ville', () {
      // La ville a le decalage de l'appareil : aucun voyage.
      final int decalage = instant.toLocal().timeZoneOffset.inSeconds;
      poserMonHorlogePourTest(
        _horloge(ville: 'Africa/Conakry', decalageVille: decalage),
      );
      final String phrase = quandAvecFuseau(instant);
      expect(phrase, contains('Conakry'));
      // La Mecque en second, sauf si l'appareil y vit deja.
      if (decalage != 10800) {
        expect(phrase, contains(t.tc.groupe.horloges.laMecque));
        expect(phrase.indexOf('Conakry'), lessThan(phrase.indexOf('Mecque')));
      }
    });
  });

  group('villeEnDesaccord', () {
    final DateTime maintenant = DateTime.utc(2026, 11, 20, 9);

    test('la ville differe de l\'appareil : on la nomme', () {
      expect(
        villeEnDesaccord(
          horloge: _horloge(ville: 'Europe/Paris', decalageVille: 3600),
          decalageAppareil: const Duration(hours: 3),
          maintenant: maintenant,
        ),
        'Europe/Paris',
      );
    });

    test('meme heure : rien', () {
      expect(
        villeEnDesaccord(
          horloge: _horloge(ville: 'Europe/Paris', decalageVille: 3600),
          decalageAppareil: const Duration(hours: 1),
          maintenant: maintenant,
        ),
        isNull,
      );
    });

    test('ville non choisie, non lue, ou serveur muet : rien', () {
      for (final MonHorloge? h in <MonHorloge?>[
        _horloge(ville: 'Europe/Paris', decalageVille: 3600, lieuChoisi: false),
        _horloge(ville: 'Europe/Paris', decalageVille: 3600, lieuChoisi: null),
        null,
      ]) {
        expect(
          villeEnDesaccord(
            horloge: h,
            decalageAppareil: const Duration(hours: 3),
            maintenant: maintenant,
          ),
          isNull,
        );
      }
    });
  });

  group('AvertissementFuseau', () {
    Future<void> monter(
      WidgetTester tester,
      MonHorloge horloge, {
      double largeur = 390,
      ThemeMode theme = ThemeMode.light,
    }) => monterRecrutement(
      tester,
      chemin: '/accueil',
      autres: <String>['/ville'],
      ecran: (_) => Scaffold(
        body: SingleChildScrollView(
          child: AvertissementFuseau(
            decalageAppareil: const Duration(hours: 3),
            maintenant: DateTime.utc(2026, 11, 20, 9),
          ),
        ),
      ),
      surcharges: <Override>[
        monHorlogeProvider.overrideWith((Ref _) async {
          poserMonHorlogePourTest(horloge);
          return horloge;
        }),
      ],
      largeur: largeur,
      themeMode: theme,
    );

    for (final (String nom, double l, ThemeMode th)
        in <(String, double, ThemeMode)>[
          ('390', 390, ThemeMode.light),
          ('1280', 1280, ThemeMode.light),
          ('1440 sombre', 1440, ThemeMode.dark),
        ]) {
      testWidgets('$nom : dit la ville et mene a la page Votre ville', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          _horloge(ville: 'Europe/Paris', decalageVille: 3600),
          largeur: l,
          theme: th,
        );
        expect(find.byKey(AvertissementFuseau.cle), findsOneWidget);
        expect(find.text(t.avertissementFuseau.action), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(t.avertissementFuseau.action));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('temoin:/ville'), findsOneWidget);
      });
    }

    testWidgets('meme heure : rien', (WidgetTester tester) async {
      await monter(
        tester,
        _horloge(ville: 'Asia/Riyadh', decalageVille: 10800),
      );
      expect(find.byKey(AvertissementFuseau.cle), findsNothing);
    });
  });
}
