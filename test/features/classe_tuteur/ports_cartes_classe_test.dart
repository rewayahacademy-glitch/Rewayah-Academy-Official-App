// PORTS-CARTES-CLASSE (pilote, 11/11/2026) : sans serveur des cartes de
// classe (port de production « indisponible »), le bloc des cartes n'est pas
// montre, jamais « pas encore ouvertes ». Contre-epreuve : avec le port de
// demonstration, il revient.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';

import '../../router/support_routeur.dart';
import '../../support/demo/cartes_classe_demo.dart';
import 'support_classe.dart';

Future<void> _monter(WidgetTester tester, List<Override> surcharges) async {
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.classePour(classeA, eleveId: eleveA1));
  await stabiliser(tester);
}

void main() {
  test('la capacite suit le port : fermee sur « indisponible »', () {
    final ProviderContainer production = ProviderContainer();
    addTearDown(production.dispose);
    expect(production.read(cartesClasseOuvertesProvider), isFalse);
    final ProviderContainer demo = ProviderContainer(
      overrides: surchargesCartesClasseDemo(classeA, peutModifier: false),
    );
    addTearDown(demo.dispose);
    expect(demo.read(cartesClasseOuvertesProvider), isTrue);
  });

  testWidgets('Classe du tuteur sans serveur des cartes : aucun bloc, aucun '
      '« pas encore ouvertes »', (WidgetTester tester) async {
    await _monter(tester, surchargesClasse());
    expect(find.byType(ClasseTuteurPage), findsOneWidget);
    expect(find.byType(BlocCartesClasse), findsNothing);
    expect(find.byKey(BlocCartesClasse.sansDonneesKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'contre-epreuve : avec le port de demonstration, le bloc revient',
    (WidgetTester tester) async {
      await _monter(tester, <Override>[
        ...surchargesClasse(),
        ...surchargesCartesClasseDemo(classeA, peutModifier: false),
      ]);
      expect(find.byType(BlocCartesClasse), findsOneWidget);
    },
  );
}
