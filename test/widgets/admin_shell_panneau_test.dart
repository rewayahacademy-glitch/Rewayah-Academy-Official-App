// NAV-REFONTE etape 4, part sans decision ouverte (feu vert du pilote du
// 11/11/2026) : la colonne de la direction recoit le bouton fixe du panneau
// (a partir de 1200), le compte au pied (photo, nom, menu) et garde ses huit
// domaines. Sous 1200, le rail reste fige, sans bouton : ouvrir le panneau a
// 800 attend la decision du directeur (question 6 de la revue du 09/11).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/aucun_mot_coupe.dart';

Future<({ProviderContainer conteneur, List<String> journal})> _monter(
  WidgetTester tester, {
  required Size taille,
  TextDirection sens = TextDirection.ltr,
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ProviderContainer conteneur = ProviderContainer();
  addTearDown(conteneur.dispose);
  final List<String> journal = <String>[];
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: conteneur,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: theme,
          builder: (BuildContext contexte, Widget? enfant) => Directionality(
            textDirection: sens,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: enfant!,
            ),
          ),
          home: AdminShell(
            domaines: domainesAdmin(voitDirection: true),
            domaineActif: AdminDomaine.accueil,
            onAller: journal.add,
            onCompte: () => journal.add('compte'),
            onDeconnexion: () => journal.add('sortie'),
            child: const PageShell(child: SizedBox()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return (conteneur: conteneur, journal: journal);
}

Finder _bouton() => find.byKey(AdminShell.boutonPanneauKey);
Finder _pied() => find.byKey(NavShell.piedCompteKey);

void main() {
  for (final TextDirection sens in TextDirection.values) {
    testWidgets('1440 (${sens.name}) : un seul bouton, meme place ouvert et '
        'replie', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(1440, 900), sens: sens);
      expect(find.byKey(AdminShell.barreLateraleKey), findsOneWidget);
      final Rect ouvert = tester.getRect(_bouton());
      await tester.tap(_bouton());
      await tester.pump();
      expect(find.byKey(AdminShell.railKey), findsOneWidget);
      final Rect replie = tester.getRect(_bouton());
      expect(replie.top, ouvert.top);
      if (sens == TextDirection.ltr) {
        expect(replie.left, ouvert.left);
      } else {
        expect(replie.right, ouvert.right);
      }
      expect(_bouton(), findsOneWidget);
    });
  }

  testWidgets('le choix est garde par appareil (navigation.repliee)', (
    WidgetTester tester,
  ) async {
    final ({ProviderContainer conteneur, List<String> journal}) m =
        await _monter(tester, taille: const Size(1440, 900));
    await tester.tap(_bouton());
    await tester.pump();
    expect(m.conteneur.read(navigationReplieeProvider), isTrue);
  });

  testWidgets('800 : rail fige, sans bouton (question 6 du directeur)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(800, 1000));
    expect(find.byKey(AdminShell.railKey), findsOneWidget);
    expect(_bouton(), findsNothing);
    expect(_pied(), findsOneWidget);
  });

  testWidgets('les huit domaines restent, dans le meme ordre', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 900));
    for (final AdminDomaine d in domainesAdmin(voitDirection: true)) {
      expect(
        find.descendant(
          of: find.byKey(AdminShell.barreLateraleKey),
          matching: find.text(d.libelle),
        ),
        findsOneWidget,
        reason: d.libelle,
      );
    }
  });

  testWidgets('pied : menu Mon compte, theme, Se deconnecter', (
    WidgetTester tester,
  ) async {
    final ({ProviderContainer conteneur, List<String> journal}) m =
        await _monter(tester, taille: const Size(1440, 900));
    await tester.tap(_pied());
    await tester.pumpAndSettle();
    expect(find.text(t.commun.theme.sombre), findsOneWidget);
    await tester.tap(find.text(t.compte.deconnexion));
    await tester.pumpAndSettle();
    expect(m.journal, <String>['sortie']);
    await tester.tap(_pied());
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.nav.compte).last);
    await tester.pumpAndSettle();
    expect(m.journal, <String>['sortie', 'compte']);
  });

  for (final Size taille in const <Size>[Size(800, 1000), Size(1440, 900)]) {
    for (final double echelle in const <double>[1, 2]) {
      for (final ThemeMode theme in const <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('${taille.width.toInt()} x$echelle ${theme.name} '
              '${sens.name} : pied dans la colonne, rien de coupe', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              taille: taille,
              echelle: echelle,
              theme: theme,
              sens: sens,
            );
            final Finder colonne = find.byKey(
              taille.width < 1200
                  ? AdminShell.railKey
                  : AdminShell.barreLateraleKey,
            );
            final Rect r = tester.getRect(colonne);
            final Rect p = tester.getRect(_pied());
            expect(p.left, greaterThanOrEqualTo(r.left));
            expect(p.right, lessThanOrEqualTo(r.right));
            expect(p.bottom, lessThanOrEqualTo(r.bottom));
            verifierAucunMotCoupe(tester, _pied());
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
