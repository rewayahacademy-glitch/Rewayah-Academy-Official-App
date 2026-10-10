// COUPE-MOTS-4 (2) : la barre basse de l'Interface guidee
// (`lib/core/widgets/nav_shell.dart`) coupait « Contrôl / e »,
// « Historiq / ue », « Échang / es » a 320 px en texte x2 : l'echelle
// commune des libelles ne descendait jamais sous 1 (taille du theme guide),
// et quatre onglets ne laissaient pas a « Historique » sa largeur.
//
// Chaque role a barre basse, en francais (LTR) et en arabe (RTL), en clair :
// aucun mot coupe dans la barre, aucun onglet hors de l'ecran.
// Contre-epreuve : sur l'ancien code (5a52ff30), le test echoue pour le
// Controleur et le tuteur en nommant le mot coupe.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La locale arabe est differee : chargee une fois, hors du test.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    for (final AppRole role in <AppRole>[
      AppRole.controller,
      AppRole.guardian,
      AppRole.teacher,
      AppRole.student,
    ]) {
      for (final double largeur in <double>[320, 390]) {
        testWidgets(
          '${langue.name} ${role.name} $largeur x2 guidee : aucun mot '
          'coupe dans la barre basse',
          (WidgetTester tester) async {
            LocaleSettings.setLocaleSync(langue);
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            tester.view.physicalSize = Size(largeur, 800);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final List<Destination> destinations = destinationsPour(
              role: role,
              mode: InterfaceMode.enfant,
            );
            await tester.pumpWidget(
              hote(
                Directionality(
                  textDirection: langue == AppLocale.ar
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: NavShell(
                    destinations: destinations,
                    indexActif: 0,
                    onAller: (String _) {},
                    child: const SizedBox.expand(),
                  ),
                ),
                mode: InterfaceMode.enfant,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final Finder barre = find.byKey(NavShell.barreBasseKey);
            expect(barre, findsOneWidget);
            expect(motsCoupes(tester, barre), isEmpty);
            for (final Destination d in destinations) {
              final Finder libelle = find.descendant(
                of: barre,
                matching: find.text(d.libelle),
              );
              expect(libelle, findsOneWidget, reason: d.libelle);
              final Rect r = tester.getRect(libelle);
              expect(r.left, greaterThanOrEqualTo(0), reason: d.libelle);
              expect(r.right, lessThanOrEqualTo(largeur), reason: d.libelle);
            }
          },
        );
      }
    }
  }
}
