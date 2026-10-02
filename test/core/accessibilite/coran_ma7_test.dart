// MA-7 : le Coran en Mode Accessibilite, AUTOUR du rendu. Depuis la VRAIE
// route /demo/accessibilite : destination « Coran » -> action principale ->
// le VRAI lecteur (`MushafPage`). « Lecture en grand texte » ouvre le mode
// verset agrandi existant ; sinon le Mushaf. Reprise « la ou tu t'es
// arrete(e) » quand le port la connait, tutoiement selon l'age.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
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
import 'package:rewayah_academy/features/accueil_eleve/coran_accessibilite.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_verset_agrandi.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
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
  setUpAll(() async {
    // Les vraies polices : la mesure des mots coupes en depend.
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

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
        await tester.tap(
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(t.nav.eleve.coran),
          ),
        );
        await stabiliser(tester);
        expect(
          tester.widget<NavShell>(find.byType(NavShell)).indexActif,
          EcranAccessibiliteDemo.indexCoran,
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
        // Revue MA-7 (3) : sans corpus hors serveur, la demonstration dit la
        // vraie cause (texte non charge dans la demonstration), sans faux
        // motif reseau ni « Reessayer » qui ne peut pas aboutir.
        expect(
          find.byKey(const ValueKey<String>('coran-ma-demo-sans-texte')),
          findsOneWidget,
        );
        expect(find.text(t.accessibilite.coran.demoSansTexte), findsOneWidget);
        // Mariam est mineure : tutoiement (A4 = a).
        expect(
          find.text(t.accessibilite.coran.demoSansTexteDetail),
          findsOneWidget,
        );
        expect(find.text(t.eleve.coran.indisponibleDetail), findsNothing);
        expect(find.text(t.eleve.coran.reessayer), findsNothing);
        expect(find.byType(LecteurCoranAccessibilite), findsNothing);
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
        tester.element(find.byType(LecteurCoranAccessibilite)),
      );
      expect(c.read(lectureCoranProvider).page, page);
      expect(find.text(t.eleve.coran.pageSuivante), findsOneWidget);
      expect(find.text(t.eleve.coran.pagePrecedente), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  // MA-RC (M2, MA22, K-51) : comme `MushafPage`, le grossissement enregistre
  // avec la position est retabli a l'ouverture, puis garde a l'ecriture.
  testWidgets('le grossissement enregistre est retabli puis garde', (
    WidgetTester tester,
  ) async {
    await _taille(tester, const Size(390, 844));
    final int page = reference.pages.first.numero;
    final FauxNavigationCoran navigation = FauxNavigationCoran(
      personnelle: PositionLecture(
        page: page,
        sourate: 1,
        verset: 1,
        zoom: 1.6,
      ),
    );
    await tester.pumpWidget(
      _hote(
        EcranAccessibiliteDemo(
          eleve: EleveDemoAccessibilite.mariam,
          destinationInitiale: EcranAccessibiliteDemo.indexCoran,
          surchargesCoran: <Override>[
            portCorpusCoranProvider.overrideWithValue(
              FauxCorpusCoran(reference),
            ),
            portLayoutMushafProvider.overrideWithValue(
              const LayoutLignesIndisponible(),
            ),
            portNavigationCoranProvider.overrideWithValue(navigation),
          ],
        ),
      ),
    );
    await poser(tester);
    await tester.tap(find.byKey(_principale));
    await poser(tester);
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(LecteurCoranAccessibilite)),
    );
    expect(c.read(lectureCoranProvider).zoomLocal, 1.6);
    final Finder suivante = find.text(t.eleve.coran.pageSuivante);
    await tester.ensureVisible(suivante);
    await tester.tap(suivante);
    // La page se charge, puis la minuterie (3 s) ecrit la position.
    await poser(tester);
    expect(c.read(lectureCoranProvider).page, isNot(page));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(navigation.ecritures, isNotEmpty);
    expect(navigation.ecritures.last.position.zoom, 1.6);
    expect(tester.takeException(), isNull);
  });

  // Revue MA-7 (1) et (2) : commandes de page flechees, jamais coupees en
  // plein mot, visibles sans defilement a 390 et a 1440 ; a 200 % elles
  // restent atteignables.
  for (final (Size taille, double echelle) cas in <(Size, double)>[
    (const Size(390, 844), 1),
    (const Size(1440, 900), 1),
    (const Size(390, 844), 2),
  ]) {
    for (final bool grande in <bool>[false, true]) {
      testWidgets(
        'commandes de page : ${cas.$1.width.toInt()} px, texte x${cas.$2}, '
        'grand texte = $grande',
        (WidgetTester tester) async {
          await _taille(tester, cas.$1);
          final ProviderContainer racine = ProviderContainer();
          addTearDown(racine.dispose);
          racine
              .read(preferencesLocalesProvider.notifier)
              .lectureGrande(grande);
          tester.platformDispatcher.textScaleFactorTestValue = cas.$2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            _hote(
              EcranAccessibiliteDemo(
                eleve: EleveDemoAccessibilite.mariam,
                destinationInitiale: EcranAccessibiliteDemo.indexCoran,
                surchargesCoran: corpus(
                  personnelle: PositionLecture(
                    page: reference.pages.last.numero,
                    sourate: 1,
                    verset: 1,
                  ),
                ),
              ),
              racine: racine,
            ),
          );
          await poser(tester);
          await tester.tap(find.byKey(_principale));
          await poser(tester);
          expect(find.byType(LecteurCoranAccessibilite), findsOneWidget);
          expect(
            find.byType(VueVersetAgrandi),
            grande ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(VuePageMushaf),
            grande ? findsNothing : findsOneWidget,
          );
          final double bas = tester.view.physicalSize.height;
          for (final String cle in <String>[
            'coran-ma-page-precedente',
            'coran-ma-page-suivante',
          ]) {
            final Finder bouton = find.byKey(ValueKey<String>(cle));
            expect(bouton, findsOneWidget);
            if (cas.$2 == 1) {
              // Visible sans defilement.
              expect(tester.getRect(bouton).bottom, lessThanOrEqualTo(bas));
            } else {
              await tester.ensureVisible(bouton);
              await tester.pump();
              expect(tester.getRect(bouton).bottom, lessThanOrEqualTo(bas));
            }
            // Une fleche directionnelle dans chaque bouton (a texte tres
            // agrandi sur ecran etroit, elle peut ceder sa place au mot).
            if (cas.$2 == 1) {
              expect(
                find.descendant(of: bouton, matching: find.byType(Icon)),
                findsOneWidget,
              );
            }
            // Aucun mot coupe : chaque libelle tient sur une ligne par mot,
            // donc au plus autant de lignes que de mots.
            final Finder libelle = find.descendant(
              of: bouton,
              matching: find.byType(Text),
            );
            final RenderParagraph rendu = tester.renderObject(libelle);
            final String texte = rendu.text.toPlainText();
            final int mots = texte.split(' ').length;
            final TextPainter peintre = TextPainter(
              text: rendu.text,
              textDirection: rendu.textDirection,
              textScaler: rendu.textScaler,
              textAlign: rendu.textAlign,
            )..layout(maxWidth: rendu.size.width);
            final int lignes = peintre.computeLineMetrics().length;
            peintre.dispose();
            expect(lignes, lessThanOrEqualTo(mots), reason: texte);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
