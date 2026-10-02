// MA-7 : le Coran en Mode Accessibilite, AUTOUR du rendu. Depuis la VRAIE
// route /demo/accessibilite : destination « Coran » -> action principale ->
// le VRAI lecteur (`MushafPage`). « Lecture en grand texte » ouvre le mode
// verset agrandi existant ; sinon le Mushaf. Reprise « la ou tu t'es
// arrete(e) » quand le port la connait, tutoiement selon l'age.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../router/support_routeur.dart' show stabiliser;
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';

const Key _principale = ValueKey<String>('coran-ma-principale');

Widget _hote(Widget app, {ProviderContainer? racine}) {
  final Widget coeur = TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: app,
    ),
  );
  return racine == null
      ? ProviderScope(child: coeur)
      : UncontrolledProviderScope(container: racine, child: coeur);
}

Future<void> _taille(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late CorpusReference reference;
  setUpAll(() => reference = CorpusReference.charger());

  List<Override> corpus({PositionLecture? personnelle}) => <Override>[
    portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
    portLayoutMushafProvider.overrideWithValue(
      const LayoutLignesIndisponible(),
    ),
    portNavigationCoranProvider.overrideWithValue(
      FauxNavigationCoran(personnelle: personnelle),
    ),
  ];

  Future<void> poser(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  for (final bool grande in <bool>[true, false]) {
    testWidgets(
      'depuis la vraie route : Coran -> action principale -> lecteur ; '
      'lecture en grand texte = $grande',
      (WidgetTester tester) async {
        await _taille(tester, const Size(390, 844));
        final ProviderContainer racine = ProviderContainer();
        addTearDown(racine.dispose);
        racine.read(preferencesLocalesProvider.notifier).lectureGrande(grande);
        final GoRouter routeur = GoRouter(
          initialLocation: adresseDemoAccessibilite(
            EleveDemoAccessibilite.mariam,
          ),
          routes: routesDemoAccessibilite('local'),
        );
        addTearDown(routeur.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: racine,
            child: TranslationProvider(
              child: MaterialApp.router(
                routerConfig: routeur,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
              ),
            ),
          ),
        );
        await stabiliser(tester);
        // MA-NAV-1 : le Coran n'est plus dans la barre du Mode Accessibilite ;
        // on y va par l'Accueil (« Lire le Coran »), sur la meme route.
        await tester.tap(
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(t.nav.eleve.accueil),
          ),
        );
        await stabiliser(tester);
        final Finder lire = find.text(t.accessibilite.accueil.lireCoran);
        await tester.ensureVisible(lire);
        await tester.pump();
        await tester.tap(lire);
        await stabiliser(tester);
        // Aucune destination de la barre n'est surlignee sur le Coran.
        expect(
          tester.widget<NavShell>(find.byType(NavShell)).indexActif,
          isNull,
        );
        // Une seule action dominante ; la demonstration ne connait aucune
        // position : « Ouvrir le Coran ».
        final Finder action = find.byKey(_principale);
        expect(action, findsOneWidget);
        expect(
          find.descendant(
            of: action,
            matching: find.text(t.accessibilite.coran.ouvrir),
          ),
          findsOneWidget,
        );
        expect(
          find.text(t.accessibilite.coran.lectureGrande),
          grande ? findsOneWidget : findsNothing,
        );
        expect(find.text(t.accessibilite.accueil.aide), findsOneWidget);
        await tester.tap(action);
        await poser(tester);
        expect(find.byType(MushafPage), findsOneWidget);
        expect(
          find.byType(VueVersetAgrandi),
          grande ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(VuePageMushaf),
          grande ? findsNothing : findsOneWidget,
        );
        // Sans corpus hors serveur, le lecteur dit honnetement son etat.
        expect(find.text(t.eleve.coran.indisponible), findsWidgets);
        // Retour a l'entree.
        await tester.tap(find.text(t.accessibilite.coran.retour));
        await poser(tester);
        expect(find.byKey(_principale), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final EleveDemoAccessibilite eleve in EleveDemoAccessibilite.values) {
    testWidgets('${eleve.name} : reprise la ou l eleve s etait arrete(e)', (
      WidgetTester tester,
    ) async {
      await _taille(tester, const Size(390, 844));
      final int page = reference.pages.last.numero;
      final bool tu = DonneesAccessibiliteDemo.mineur(eleve);
      await tester.pumpWidget(
        _hote(
          EcranAccessibiliteDemo(
            eleve: eleve,
            destinationInitiale: EcranAccessibiliteDemo.indexCoran,
            surchargesCoran: corpus(
              personnelle: PositionLecture(page: page, sourate: 1, verset: 1),
            ),
          ),
        ),
      );
      await poser(tester);
      final String libelle = tu
          ? t.accessibilite.coran.reprendre
          : t.accessibilite.coran.reprendreVous;
      expect(
        find.descendant(
          of: find.byKey(_principale),
          matching: find.text(libelle),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          tu
              ? t.accessibilite.coran.reprendreDetail(page: '$page')
              : t.accessibilite.coran.reprendreDetailVous(page: '$page'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(_principale));
      await poser(tester);
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(MushafPage)),
      );
      expect(c.read(lectureCoranProvider).page, page);
      // NAV-FLECHES-1 : deux fleches rondes (le verbe entier est lu par le
      // lecteur d'ecran), pas deux boutons a libelle.
      expect(
        find.byKey(const ValueKey<String>('nav-suivant')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('nav-precedent')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
