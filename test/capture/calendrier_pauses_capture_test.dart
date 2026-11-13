// CALENDRIER-ET-PAUSES (lot 2 de la charte, 12/11/2026) : les ecrans neufs,
// montes par le VRAI routeur, a 390 et 1440 points, en clair et en sombre, en
// francais et en arabe : Pedagogie > Calendrier (les dates de l'ecole, les
// pauses) et « Demander une pause d'un mois » (le tuteur, l'eleve adulte).
// Donnees de test seulement (les reponses du serveur sont simulees ; rien ne
// vient de la production).
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/calendrier-pauses flutter test --no-pub \
//     test/capture/calendrier_pauses_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/calendrier/port_calendrier.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';

import '../router/support_routeur.dart';
import '../support/calendrier_pauses_faux.dart';
import '../support/harnais.dart';
import '../support/monter_admin_demo.dart';
import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;

Override get _enLigne =>
    horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(false));

FausPauses _pausesFamille() => FausPauses(
  lecture: lecturePausesServeur(
    moisAccordes: 2,
    aLaDirection: <int>{2, 3, 4, 5, 6, 7, 8, 9, 10, 11},
    etats: <int, String>{1: 'acceptee'},
    pauses: <Object?>[
      pauseServeur(
        id: 'a',
        statut: 'acceptee',
        debut: '2027-01-01',
        fin: '2027-01-31',
        annulable: true,
      ),
      pauseServeur(
        id: 'b',
        statut: 'refusee',
        debut: '2026-09-01',
        fin: '2026-09-30',
        motifDecision: 'Deux pauses ont déjà été accordées cette année',
      ),
    ],
  ),
);

void main() {
  group('Capture CALENDRIER-ET-PAUSES', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      final String l = langue.languageCode;
      final TextDirection? direction = langue == AppLocale.ar
          ? TextDirection.rtl
          : null;
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nomTheme = theme == ThemeMode.light ? 'clair' : 'sombre';
        for (final double largeur in <double>[390, 1440]) {
          final String w = '${largeur.toInt()}';
          final String suffixe = '$w-$nomTheme-$l';

          for (final bool pauses in <bool>[false, true]) {
            testWidgets('direction ${pauses ? 'pauses' : 'dates'} $suffixe', (
              WidgetTester tester,
            ) async {
              await tester.runAsync(() => LocaleSettings.setLocale(langue));
              tester.platformDispatcher.platformBrightnessTestValue =
                  theme == ThemeMode.light ? Brightness.light : Brightness.dark;
              addTearDown(
                tester.platformDispatcher.clearPlatformBrightnessTestValue,
              );
              await monterAdminDemo(
                tester,
                route: Routes.adminPedagogieCalendrier,
                taille: Size(largeur, largeur < 600 ? 2600 : 1100),
                direction: direction,
                plus: <Override>[
                  portCalendrierDirectionProvider.overrideWithValue(
                    FauxCalendrierDirection(),
                  ),
                  portPausesProvider.overrideWithValue(FausPauses()),
                  _enLigne,
                ],
              );
              if (pauses) {
                await tester.tap(find.text(t.calendrier.sections.pauses));
                await tester.pump(const Duration(milliseconds: 600));
              }
              await tester.pump(const Duration(milliseconds: 600));
              debugPrint(
                'PNG ${await capturerVue(tester, 'direction-${pauses ? 'pauses' : 'dates'}-$suffixe')}',
              );
            });
          }

          testWidgets('tuteur pause $suffixe', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            await monterRouteur(
              tester,
              Routes.tuteurPause('eleve-mariam'),
              taille: Size(largeur, largeur < 600 ? 3000 : 1700),
              themeMode: theme,
              direction: direction,
              surcharges: <Override>[
                portPausesProvider.overrideWithValue(_pausesFamille()),
                _enLigne,
              ],
            );
            await tester.pump(const Duration(milliseconds: 600));
            debugPrint('PNG ${await capturerVue(tester, 'tuteur-$suffixe')}');
          });

          testWidgets('adulte pause $suffixe', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            await monterRouteur(
              tester,
              Routes.elevePause,
              source: FausseSourceSession(sessionActive(AppRole.student)),
              taille: Size(largeur, largeur < 600 ? 3000 : 1700),
              themeMode: theme,
              direction: direction,
              surcharges: <Override>[
                portPausesProvider.overrideWithValue(
                  FausPauses(
                    lecture: <String, Object?>{
                      ...lecturePausesServeur(prenom: null),
                    },
                  ),
                ),
                portCapaciteEleveProvider.overrideWithValue(
                  const PortCapaciteEleveFactice(
                    autonomes: <String>{'p-student'},
                  ),
                ),
                _enLigne,
              ],
            );
            await tester.pump(const Duration(milliseconds: 600));
            debugPrint('PNG ${await capturerVue(tester, 'adulte-$suffixe')}');
          });
        }
      }
    }
  });
}
