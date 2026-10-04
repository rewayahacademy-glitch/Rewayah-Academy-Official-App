// PT-B-CORAN-ADULTE : l'onglet Coran de l'eleve adulte ouvre la VRAIE page
// Coran de l'eleve (`MushafPage`, celle de `/eleve/coran`), depuis la vraie
// barre (K-07), sur la route reelle comme dans la demonstration. Le rendu du
// Coran n'est pas touche : on ne fait que le rejoindre.
//
// Route reelle : `/eleve/adulte` vit dans la branche 0 de la coquille eleve ;
// l'onglet Coran rejoint la branche 2 (`/eleve/coran`), Accueil y ramene.
// Demonstration : la page provisoire est remplacee par `MushafPage` dans un
// conteneur isole, sans serveur (K-28) : sans corpus, elle dit honnetement
// que le texte n'a pas pu etre charge.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show lieu;
import '../../support/aucun_mot_coupe.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';
import 'support_accueil_adulte_route.dart';

/// L'ancienne phrase de la page provisoire, qui ne doit plus paraitre.
const String _phraseProvisoire =
    "Le Coran de votre espace élève s'affichera ici.";

/// L'onglet de la barre portant [libelle] (le texte de la page peut le
/// reprendre : on vise le dernier, celui de la barre posee par-dessus).
Finder _onglet(String libelle) => find
    .descendant(of: find.byType(NavShell), matching: find.text(libelle))
    .last;

int? _actif(WidgetTester tester) =>
    tester.widget<NavShell>(find.byType(NavShell)).indexActif;

/// Laisse les lectures du Coran se resoudre sans `pumpAndSettle` (l'indicateur
/// de chargement tournerait sans fin).
Future<void> _poser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  /// Le corpus de reference des tests : aucun serveur, aucune position.
  List<Override> corpus() => <Override>[
    portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
    portLayoutMushafProvider.overrideWithValue(
      const LayoutLignesIndisponible(),
    ),
    portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
  ];

  Future<GoRouter> monterReel(
    WidgetTester tester, {
    bool capacite = true,
    Size taille = const Size(390, 844),
    double echelle = 1,
    TextDirection direction = TextDirection.ltr,
  }) async {
    final GoRouter routeur = await monterAccueilAdulteReel(
      tester,
      taille: taille,
      echelle: echelle,
      direction: direction,
      surcharges: <Override>[
        if (capacite)
          ...surchargesAccueilAdulte(accueil: Valeur(accueilDemo()))
        else
          ...surchargesAccueilAdulte(),
        ...corpus(),
      ],
      depart: Routes.eleve,
    );
    return routeur;
  }

  group('route reelle (K-07)', () {
    testWidgets('Accueil adulte -> onglet Coran : la vraie page Coran, onglet '
        'allume ; Accueil ramene a /eleve/adulte', (WidgetTester tester) async {
      final GoRouter routeur = await monterReel(tester);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(_actif(tester), 0);

      await tester.tap(_onglet(t.nav.eleve.coran));
      await _poser(tester);

      expect(lieu(routeur), Routes.eleveCoran);
      expect(find.byType(MushafPage), findsOneWidget);
      // Le vrai texte du corpus de reference, rendu par le vrai lecteur.
      expect(find.byType(CadrePageMushaf), findsOneWidget);
      expect(find.byType(AccueilAdultePage), findsNothing);
      expect(find.text(_phraseProvisoire), findsNothing);
      expect(_actif(tester), 2);

      await tester.tap(_onglet(t.nav.eleve.accueil));
      await _poser(tester);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(find.byType(MushafPage), findsNothing);
      expect(_actif(tester), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('contre-epreuve, capacite fausse : meme page Coran, et Accueil '
        'ramene a l\'accueil de l\'eleve, jamais a l\'adulte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterReel(tester, capacite: false);
      expect(lieu(routeur), Routes.eleve);

      await tester.tap(_onglet(t.nav.eleve.coran));
      await _poser(tester);
      expect(lieu(routeur), Routes.eleveCoran);
      expect(find.byType(MushafPage), findsOneWidget);
      expect(_actif(tester), 2);

      await tester.tap(_onglet(t.nav.eleve.accueil));
      await _poser(tester);
      expect(lieu(routeur), Routes.eleve);
      expect(find.byType(AccueilElevePage), findsOneWidget);
      expect(find.byType(AccueilAdultePage), findsNothing);
    });
  });

  group(
    'demonstration /demo/adulte (K-07) ; aucun mot coupe (demo et reel)',
    () {
      Future<GoRouter> monterDemo(
        WidgetTester tester, {
        Size taille = const Size(390, 844),
        double echelle = 1,
        TextDirection direction = TextDirection.ltr,
      }) async {
        tester.view.physicalSize = taille;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final GoRouter routeur = GoRouter(
          initialLocation: adresseDemoAdulte(EcranDemoAdulte.accueil),
          routes: routesDemoAdulte('dev'),
        );
        addTearDown(routeur.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp.router(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (BuildContext c, Widget? app) => MediaQuery(
                  data: MediaQuery.of(c)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: Directionality(textDirection: direction, child: app!),
                ),
                routerConfig: routeur,
              ),
            ),
          ),
        );
        await _poser(tester);
        return routeur;
      }

      testWidgets('onglet Coran : la vraie page Coran, sans serveur, onglet '
          'allume ; Accueil y ramene', (WidgetTester tester) async {
        final GoRouter routeur = await monterDemo(tester);
        expect(find.byType(AccueilAdultePage), findsOneWidget);
        expect(_actif(tester), 0);

        await tester.tap(_onglet(t.adulte.nav.coran));
        await _poser(tester);

        expect(lieu(routeur), adresseDemoAdulte(EcranDemoAdulte.coran));
        expect(find.byType(CoranDemoAdulte), findsOneWidget);
        expect(find.byType(MushafPage), findsOneWidget);
        // Aucun corpus hors serveur : l'etat honnete du lecteur (K-59), jamais
        // un texte invente, jamais l'ancienne page provisoire.
        expect(find.text(t.eleve.coran.indisponible), findsOneWidget);
        expect(find.text(_phraseProvisoire), findsNothing);
        expect(_actif(tester), 2);
        expect(
          tester.widget<NavShell>(find.byType(NavShell)).destinations,
          hasLength(4),
        );

        await tester.tap(_onglet(t.adulte.nav.accueil));
        await _poser(tester);
        expect(lieu(routeur), adresseDemoAdulte(EcranDemoAdulte.accueil));
        expect(find.byType(AccueilAdultePage), findsOneWidget);
        expect(find.byType(MushafPage), findsNothing);
        expect(_actif(tester), 0);
        expect(tester.takeException(), isNull);
      });

      testWidgets('le conteneur isole rend le vrai texte quand un corpus est '
          'pose (tests et captures)', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Scaffold(body: CoranDemoAdulte(surchargesCoran: corpus())),
            ),
          ),
        );
        await _poser(tester);
        expect(find.byType(CadrePageMushaf), findsOneWidget);
        expect(find.text(t.eleve.coran.indisponible), findsNothing);
      });

      // Aucun mot coupe : 320 x2 et 1440, LTR et RTL, demo et route reelle.
      for (final (String nom, Size taille, double echelle)
          in <(String, Size, double)>[
            ('320 x2', const Size(320, 1400), 2),
            ('1440', const Size(1440, 1000), 1),
          ]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('demo : aucun mot coupe $nom ${sens.name}', (
            WidgetTester tester,
          ) async {
            await monterDemo(
              tester,
              taille: taille,
              echelle: echelle,
              direction: sens,
            );
            await tester.tap(_onglet(t.adulte.nav.coran));
            await _poser(tester);
            expect(find.byType(MushafPage), findsOneWidget);
            verifierEcranSansMotCoupe(tester);
            expect(tester.takeException(), isNull);
          });

          testWidgets('route reelle : aucun mot coupe $nom ${sens.name}', (
            WidgetTester tester,
          ) async {
            final GoRouter routeur = await monterReel(
              tester,
              taille: taille,
              echelle: echelle,
              direction: sens,
            );
            await tester.tap(_onglet(t.nav.eleve.coran));
            await _poser(tester);
            expect(lieu(routeur), Routes.eleveCoran);
            expect(find.byType(MushafPage), findsOneWidget);
            verifierEcranSansMotCoupe(tester);
            expect(tester.takeException(), isNull);
          });
        }
      }
    },
  );
}
