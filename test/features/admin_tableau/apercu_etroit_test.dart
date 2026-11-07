// SANS-BARRE-FIXE, decision (i) du pilote (07/11) : les lignes d'apercu
// touchables d'une tuile compteur ne s'affichent que si elles tiennent a
// l'echelle 1. Sinon la tuile reste un seul lien vers la file, jamais reduite
// sous la cible de 48 (AD-11, androidTapTargetGuideline).
//
// Depuis la vraie coque admin en demonstration (donnees de test).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/admin_tableau/tuiles_compteur.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/dossiers_demo.dart';
import '../../support/demo/mode_demonstration.dart';
import '../../support/demo/repere_demonstration.dart';

Future<void> _stab(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surchargesDemoAdmin(
        environnement: 'staging',
        etat: EtatRevueDemo.initial(superAdmin: true, politiqueGenre: true),
      ),
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stab(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read<GoRouter>(routeurProvider)
      .go(Routes.admin);
  await _stab(tester);
}

/// Les appuis visibles de chaque tuile compteur, apres l'avoir amenee a
/// l'ecran : (appuis de la tuile, hauteurs rendues, hauteur de la tuile).
Future<List<(int, List<double>, double)>> _mesurer(WidgetTester tester) async {
  final List<(int, List<double>, double)> mesures =
      <(int, List<double>, double)>[];
  final int n = find.byType(TuileCompteur).evaluate().length;
  for (int i = 0; i < n; i++) {
    final Finder tuile = find.byType(TuileCompteur).at(i);
    await tester.ensureVisible(tuile);
    await _stab(tester);
    final Finder appuis = find
        .descendant(of: tuile, matching: find.byType(Pressable))
        .hitTestable();
    mesures.add((
      appuis.evaluate().length,
      <double>[
        for (int k = 0; k < appuis.evaluate().length; k++)
          tester.getRect(appuis.at(k)).height,
      ],
      tester.getRect(tuile).height,
    ));
  }
  return mesures;
}

void main() {
  // Comme AD-11 : la police de test par defaut, plus large que celle du
  // depot, la ou l'apercu ne tient pas a 320.

  testWidgets('320x640 : aucune ligne d apercu, la tuile entiere fait 48', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(320, 640));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    final List<(int, List<double>, double)> mesures = await _mesurer(tester);
    expect(mesures, isNotEmpty);
    for (final (int appuis, List<double> hauteurs, double tuile) in mesures) {
      // Un seul lien (vers la file) ou aucun (rapport) : jamais de ligne.
      expect(appuis, lessThanOrEqualTo(1));
      expect(tuile, greaterThanOrEqualTo(48));
      for (final double h in hauteurs) {
        expect(h, greaterThanOrEqualTo(48));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('1440x900 : les lignes d apercu restent, chacune a 48', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(1440, 900));
    final List<(int, List<double>, double)> mesures = await _mesurer(tester);
    // La mesure porte sur quelque chose : au moins une tuile montre ses
    // lignes a cote de son lien.
    expect(mesures.any(((int, List<double>, double) m) => m.$1 > 1), isTrue);
    for (final (int _, List<double> hauteurs, double _) in mesures) {
      for (final double h in hauteurs) {
        expect(h, greaterThanOrEqualTo(48));
      }
    }
    expect(tester.takeException(), isNull);
  });
}
