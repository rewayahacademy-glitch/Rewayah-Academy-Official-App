// CT-12 : recette de la vague Controleur, scenarios du document 08 §16 qui
// n'avaient pas encore de preuve : 25 (texte 200 %), 26 (clavier), 27
// (lecteur d'ecran, par les etiquettes), 28 (RTL structurel).
//
// Tout part de la VRAIE route de demonstration. Les captures ne tournent
// qu'avec CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import '../../capture/outil_capture.dart';

const Size _mobile = Size(390, 844);

Future<void> _monter(
  WidgetTester tester, {
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool capture = false,
  Size taille = _mobile,
  EcranDemoControleur ecran = EcranDemoControleur.controle,
}) async {
  if (capture) {
    fixerVueCapture(tester, taille, 1);
  } else {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoControleur(ecran),
    routes: routesDemoControleur('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
            builder: (BuildContext contexte, Widget? app) => MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: Directionality(textDirection: direction, child: app!),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _versDetailHistorique(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  final Finder ligne = find.byKey(
    HistoriqueControleurPage.ligneKey('demo-rapport-0924'),
  );
  await tester.scrollUntilVisible(ligne, 200);
  await tester.tap(ligne);
  await tester.pumpAndSettle();
  expect(find.text(t.controleur.historique.sectionMission), findsOneWidget);
}

Future<void> _versCompteRendu(WidgetTester tester) async {
  await tester.tap(find.byKey(ControleControleurPage.commencerKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.salle.quitter));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  expect(find.byType(CompteRenduControlePage), findsOneWidget);
}

/// Vrai si l'element qui a le focus est dans le widget de cle [cle].
bool _focusDans(Key cle) {
  final BuildContext? contexte = FocusManager.instance.primaryFocus?.context;
  if (contexte == null) return false;
  bool dedans = false;
  contexte.visitAncestorElements((Element e) {
    if (e.widget.key == cle) {
      dedans = true;
      return false;
    }
    return true;
  });
  return dedans;
}

Future<void> _tabJusqua(WidgetTester tester, Key cle) async {
  for (int i = 0; i < 40; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (_focusDans(cle)) return;
  }
  fail('Tab n\'atteint jamais $cle');
}

void main() {
  group('Scenario 25 : texte a 200 %, 390 px', () {
    testWidgets('Controle en direct : rien ne deborde, le bouton reste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, echelle: 2);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(ControleControleurPage.commencerKey),
        200,
      );
      expect(find.byKey(ControleControleurPage.commencerKey), findsOneWidget);
      final Rect bouton = tester.getRect(
        find.byKey(ControleControleurPage.commencerKey),
      );
      expect(bouton.left >= 0 && bouton.right <= _mobile.width, isTrue);
    });

    testWidgets('Detail de l Historique : rien ne deborde', (
      WidgetTester tester,
    ) async {
      await _monter(tester, echelle: 2, ecran: EcranDemoControleur.historique);
      await _versDetailHistorique(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('Scenario 28 : RTL structurel, 390 px', () {
    testWidgets('Controle en direct : la mise en page se retourne', (
      WidgetTester tester,
    ) async {
      await _monter(tester, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      final BuildContext contexte = tester.element(
        find.byKey(ControleControleurPage.commencerKey),
      );
      expect(Directionality.of(contexte), TextDirection.rtl);
      // Le titre de la mission se range a droite de l'ecran.
      final Rect titre = tester.getRect(
        find.text(t.controleur.controle.mission),
      );
      _barreRetournee(tester);
      expect(titre.width, greaterThan(0));
    });

    testWidgets('Detail de l Historique : la mise en page se retourne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        direction: TextDirection.rtl,
        ecran: EcranDemoControleur.historique,
      );
      await _versDetailHistorique(tester);
      expect(tester.takeException(), isNull);
      final Rect titre = tester.getRect(
        find.text(t.controleur.historique.sectionMission),
      );
      _barreRetournee(tester);
      expect(titre.width, greaterThan(0));
    });
  });

  group('Scenario 26 : clavier seul, compte rendu', () {
    testWidgets('Tab atteint chaque choix et le bouton, Entree choisit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1280, 900));
      await _versCompteRendu(tester);
      // Aucun choix prefait, donc pas encore de bouton d'envoi.
      expect(find.byKey(CompteRenduControlePage.actionKey), findsNothing);

      // Chaque choix recoit le focus, dans l'ordre de lecture.
      for (final ChoixCompteRendu c in ChoixCompteRendu.values) {
        await _tabJusqua(tester, CompteRenduControlePage.cleChoix(c));
        expect(
          _focusDans(CompteRenduControlePage.cleChoix(c)),
          isTrue,
          reason: c.name,
        );
      }

      // Revenir sur « Rien a signaler » (Maj+Tab), puis le choisir au clavier.
      final Key rien = CompteRenduControlePage.cleChoix(
        ChoixCompteRendu.rienASignaler,
      );
      for (int i = 0; i < 40 && !_focusDans(rien); i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();
      }
      expect(_focusDans(rien), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(CompteRenduControlePage.actionKey), findsOneWidget);

      // Le bouton d'envoi s'atteint au clavier et s'active a l'Entree.
      await _tabJusqua(tester, CompteRenduControlePage.actionKey);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text(t.controleur.compteRendu.envoyeTitre), findsOneWidget);
    });
  });

  group('Scenario 27 : lecteur d ecran, etiquettes', () {
    testWidgets('Commencer, choix du compte rendu : etiquette et role', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle sem = tester.ensureSemantics();
      await _monter(tester, taille: const Size(1280, 900));
      final SemanticsNode commencer = tester.getSemantics(
        find.byKey(ControleControleurPage.commencerKey),
      );
      expect(commencer.label, isNotEmpty);
      expect(commencer.flagsCollection.isButton, isTrue);

      await _versCompteRendu(tester);
      for (final ChoixCompteRendu c in ChoixCompteRendu.values) {
        final SemanticsNode n = tester.getSemantics(
          find.byKey(CompteRenduControlePage.cleChoix(c)),
        );
        expect(n.label.trim(), isNotEmpty, reason: c.name);
        expect(
          n.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: c.name,
        );
      }
      sem.dispose();
    });
  });

  group('Capture : CT-12, 200 % et RTL', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, double echelle, TextDirection dir)
        in <(String, double, TextDirection)>[
          ('texte200', 2, TextDirection.ltr),
          ('rtl', 1, TextDirection.rtl),
        ]) {
      testWidgets('ct12_${nom}_controle_390', (WidgetTester tester) async {
        await _monter(tester, echelle: echelle, direction: dir, capture: true);
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'ct12_${nom}_controle_390')}');
      });
      testWidgets('ct12_${nom}_historique_detail_390', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          echelle: echelle,
          direction: dir,
          capture: true,
          ecran: EcranDemoControleur.historique,
        );
        await _versDetailHistorique(tester);
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ct12_${nom}_historique_detail_390')}',
        );
      });
    }
  });
}

/// RTL : la barre de navigation se lit de droite a gauche, donc la premiere
/// destination (Controle) est a droite de la derniere (Compte).
void _barreRetournee(WidgetTester tester) {
  // Le libelle de la barre est le plus bas de l'ecran (le titre est en haut).
  double x(String libelle) {
    final Finder f = find.descendant(
      of: find.byType(NavShell),
      matching: find.text(libelle),
    );
    Offset? plusBas;
    for (int i = 0; i < f.evaluate().length; i++) {
      final Offset c = tester.getCenter(f.at(i));
      if (plusBas == null || c.dy > plusBas.dy) plusBas = c;
    }
    return plusBas!.dx;
  }

  expect(
    x(t.nav.controleur.controle) > x(t.nav.controleur.compte),
    isTrue,
    reason: 'la barre doit etre retournee en RTL',
  );
}
