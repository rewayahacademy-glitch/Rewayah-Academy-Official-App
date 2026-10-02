// Captures de recette MA-NAV-1 : la navigation de l'eleve en Mode Accessibilite
// (barre basse, rail, barre laterale), clair et sombre, texte x1 et x2, a 320,
// tablette et bureau. Sert au avant / apres : le prefixe vient de
// CAPTURE_PREFIX (avant, apres).
//
// Saute sans CAPTURE_DIR. Mode d'emploi : `test/capture/LISEZ-MOI.md`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';

import 'outil_capture.dart';

final String _prefixe = Platform.environment['CAPTURE_PREFIX'] ?? 'apres';

void main() {
  group('Capture : navigation eleve MA-NAV-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final InterfaceMode mode in <InterfaceMode>[
      InterfaceMode.enfant,
      InterfaceMode.standard,
    ]) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final (String nom, Size taille, double echelle) cas
            in <(String, Size, double)>[
              ('320', const Size(320, 640), 1),
              ('320x2', const Size(320, 640), 2),
              ('tablette', const Size(820, 900), 1),
              ('bureau', const Size(1440, 900), 1),
            ]) {
          testWidgets('${mode.name} ${theme.name} ${cas.$1}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, cas.$2, 1);
            final List<Destination> d = destinationsPour(
              role: AppRole.student,
              mode: mode,
            );
            await tester.pumpWidget(
              hoteCapture(
                Scaffold(
                  body: NavShell(
                    destinations: d,
                    indexActif: 0,
                    onAller: (String _) {},
                    child: const SizedBox.expand(),
                  ),
                ),
                themeMode: theme,
                echelleTexte: cas.$3,
                interfaceMode: mode,
              ),
            );
            await stabiliser(tester);
            debugPrint(
              'PNG ${await capturer(tester, 'manav1_${_prefixe}_${mode.name}_${theme.name}_${cas.$1}')}',
            );
          });
        }
      }
    }
  });
}
