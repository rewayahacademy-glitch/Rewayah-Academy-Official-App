// Recettes R-FIN-24 a R-FIN-29 de la spec Finance operationnelle / Comptable
// V1 (§50-57), rendues mesurables (COMPTA-RECON-1 §3.2 : le comportement est
// dans le code, aucun test ne portait leur nom).
//
// - R-FIN-24 : les surfaces Finance sont sur le design system Rewayah (aucune
//   couleur litterale, aucun Material brut) ;
// - R-FIN-25 : aucun theme hybride, sidebar noire et contenu blanc ;
// - R-FIN-26 : les maquettes divergentes sont harmonisees, chaque ecran du
//   role est dans la coque commune (`PageShell`) ;
// - R-FIN-27 : DM Sans pour les titres ; R-FIN-28 : Plus Jakarta Sans pour le
//   corps ;
// - R-FIN-29 : rendu reel a 1440 px.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../../support/harnais.dart';

/// Les fichiers `.dart` des surfaces du Comptable et de ses composants.
Iterable<File> _sources() sync* {
  for (final String dossier in <String>[
    'lib/features/comptable',
    'lib/core/widgets/comptable',
  ]) {
    for (final FileSystemEntity f in Directory(
      dossier,
    ).listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) yield f;
    }
  }
}

void main() {
  test('R-FIN-24 : aucune couleur litterale, aucun Material brut', () {
    for (final File f in _sources()) {
      final String texte = f.readAsStringSync();
      expect(texte.contains(RegExp(r'Color\(0x')), isFalse, reason: f.path);
      expect(texte.contains(RegExp(r'\bColors\.')), isFalse, reason: f.path);
      expect(texte.contains(RegExp(r'\bIcons\.')), isFalse, reason: f.path);
    }
  });

  test('R-FIN-25 : aucune sidebar noire, aucun theme hybride', () {
    for (final File f in _sources()) {
      final String texte = f.readAsStringSync();
      expect(texte.contains('NavigationRail'), isFalse, reason: f.path);
      expect(texte.contains('Drawer('), isFalse, reason: f.path);
    }
  });

  test('R-FIN-26 : chaque ecran du role est dans la coque commune', () {
    final Iterable<File> pages = _sources().where(
      (File f) => f.path.endsWith('_page.dart'),
    );
    expect(pages.length, greaterThanOrEqualTo(14));
    for (final File f in pages) {
      expect(
        f.readAsStringSync().contains('PageShell('),
        isTrue,
        reason: f.path,
      );
    }
  });

  test('R-FIN-27 : DM Sans pour les titres', () {
    expect(AppFontFamily.titre, 'DMSans');
    for (final TextStyle? s in <TextStyle?>[
      AppTypography.standard.headlineMedium,
      AppTypography.standard.titleLarge,
      AppTypography.standard.titleMedium,
      AppTypography.standard.titleSmall,
    ]) {
      expect(s?.fontFamily, AppFontFamily.titre);
    }
  });

  test('R-FIN-28 : Plus Jakarta Sans conservee pour le corps', () {
    expect(AppFontFamily.corps, 'PlusJakartaSans');
    for (final TextStyle? s in <TextStyle?>[
      AppTypography.standard.bodyLarge,
      AppTypography.standard.bodyMedium,
      AppTypography.standard.bodySmall,
      AppTypography.standard.labelLarge,
    ]) {
      expect(s?.fontFamily, AppFontFamily.corps);
    }
  });

  group('R-FIN-29 : desktop reel a 1440', () {
    setUpAll(chargerPolicesDuDepot);
    for (final EcranDemoComptable ecran in <EcranDemoComptable>[
      EcranDemoComptable.aujourdhui,
      EcranDemoComptable.paiements,
      EcranDemoComptable.tresorerie,
      EcranDemoComptable.rapports,
    ]) {
      testWidgets('${ecran.name} : 1440 x 900, aucune exception', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteRoutant(
            depart: adresseDemoComptable(ecran),
            routes: routesDemoComptable('staging'),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: ecran.name);
        // La coque occupe les 1440 reels ; son contenu en garde moins (rail).
        expect(
          tester.getSize(find.byType(Navigator).first).width,
          1440,
          reason: ecran.name,
        );
      });
    }
  });
}
