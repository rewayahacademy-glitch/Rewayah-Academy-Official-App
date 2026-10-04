// PT-B-CORAN-ADULTE : l'onglet Coran de l'eleve adulte ouvre la VRAIE page
// Coran de l'eleve (`MushafPage`, celle de `/eleve/coran`), depuis la vraie
// barre (K-07), sur la route reelle comme dans la demonstration. Le rendu du
// Coran n'est pas touche : on ne fait que le rejoindre.
//
// Route reelle : `/eleve/adulte` vit dans la branche 0 de la coquille eleve ;
// l'onglet Coran rejoint la branche 2 (`/eleve/coran`), Accueil y ramene.
// Demonstration : la page provisoire est remplacee par `CoranDemoAdulte`,
// la vraie `MushafPage` dans un conteneur isole, sans serveur (K-28), sur le
// corpus de la base recopie mot pour mot (`service_coran_demo.dart`, verifie
// par `test/features/demo/corpus_demo_coran_test.dart`) : la demonstration
// montre le vrai texte, jamais l'erreur reseau du lecteur (K-59). Ses propres
// etats (attente, echec du chargement differe, reprise) sont verifies ici.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/demo/coran_demo_adulte.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/service_coran_demo.dart';
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

/// Le deuxieme verset d'Al-Faatiha, LU dans la migration 0013 (jamais
/// recopie a la main : un texte du Coran ne se retape pas) : la preuve que le
/// VRAI texte de la base est rendu.
final String _alHamd = (() {
  final RegExpMatch? ligne =
      RegExp(r"^  \(1, 2, '([^']*)', 1\),$", multiLine: true).firstMatch(
        File('supabase/migrations/0013_corpus_coranique.sql')
            .readAsStringSync(),
      );
  return ligne!.group(1)!;
})();

/// La demonstration rend la vraie page Coran, avec le vrai texte et son
/// attribution, jamais l'erreur reseau du lecteur ni l'ancienne page
/// provisoire (K-59).
void _verifierVraiePageDemo() {
  expect(find.byType(CoranDemoAdulte), findsOneWidget);
  expect(find.byType(MushafPage), findsOneWidget);
  // Une page, ou deux en vis-a-vis sur grand ecran.
  expect(find.byType(CadrePageMushaf), findsWidgets);
  expect(find.textContaining(_alHamd, findRichText: true), findsWidgets);
  expect(find.text('Al-Faatiha'), findsWidgets);
  expect(find.textContaining(t.eleve.coran.source), findsOneWidget);
  expect(find.text(t.eleve.coran.indisponible), findsNothing);
  expect(find.text(t.eleve.coran.indisponibleDetail), findsNothing);
  expect(find.text(t.eleve.coran.absent), findsNothing);
  expect(find.text(t.eleve.coran.reessayer), findsNothing);
  expect(find.byIcon(AppIcons.horsLigne.repos), findsNothing);
  expect(find.text(_phraseProvisoire), findsNothing);
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
            // Ce que `main.dart` pose a la racine au demarrage sur
            // `/demo/adulte` : la feuille « Aller a » s'y ouvre.
            overrides: surchargesRacineDemoAdulte(
              adresse: Uri.parse('https://exemple.test/#/demo/adulte'),
              environnement: 'dev',
            ),
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

      testWidgets('onglet Coran : la vraie page Coran et son vrai texte, sans '
          'serveur, onglet allume ; Accueil y ramene', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await monterDemo(tester);
        expect(find.byType(AccueilAdultePage), findsOneWidget);
        expect(_actif(tester), 0);

        await tester.tap(_onglet(t.adulte.nav.coran));
        await _poser(tester);

        expect(lieu(routeur), adresseDemoAdulte(EcranDemoAdulte.coran));
        _verifierVraiePageDemo();
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

      // 390 : feuille du bas ; 1440 : dialogue du navigateur racine, qui lit
      // la portee racine (celle que `main.dart` pose sur `/demo/adulte`).
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 1000)),
      ]) {
        testWidgets('demo $nom : « Aller a » 2:255 ouvre la page 42, '
            'Al-Baqara, par la navigation reelle, sans serveur', (
          WidgetTester tester,
        ) async {
          await monterDemo(tester, taille: taille);
          await tester.tap(_onglet(t.adulte.nav.coran));
          await _poser(tester);

          await tester.tap(find.text(t.tc.coran.navigation.ouvrir));
          await _poser(tester);
          await tester.enterText(find.byType(TextField), '2:255');
          await _poser(tester);
          // Le resultat de la feuille (le champ porte aussi « 2:255 »).
          await tester.tap(
            find.text(t.tc.coran.navigation.pageNumero(page: 42)),
          );
          await _poser(tester);

          expect(find.byType(MushafPage), findsOneWidget);
          expect(
            find.textContaining(t.eleve.coran.page(page: '42', total: '604')),
            findsWidgets,
          );
          expect(find.text('Al-Baqara'), findsWidgets);
          expect(find.text(t.eleve.coran.indisponible), findsNothing);
          expect(_actif(tester), 2);
          expect(tester.takeException(), isNull);
        });
      }

      Future<void> monterSeule(
        WidgetTester tester,
        Future<ServiceCoran> Function() charger,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: Scaffold(body: CoranDemoAdulte(charger: charger)),
              ),
            ),
          ),
        );
      }

      testWidgets('corpus en cours de chargement : la vraie page Coran dans '
          'son attente, aucun texte d\'echec', (WidgetTester tester) async {
        final Completer<ServiceCoran> attente = Completer<ServiceCoran>();
        await monterSeule(tester, () => attente.future);
        await tester.pump();
        expect(find.byType(MushafPage), findsOneWidget);
        expect(
          find.byType(CircularProgressIndicator, skipOffstage: false),
          findsWidgets,
        );
        expect(find.text(t.eleve.coran.indisponible), findsNothing);

        attente.complete(const ServiceCoranDemo());
        await _poser(tester);
        expect(find.textContaining(_alHamd, findRichText: true), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('chargement differe en echec : l\'etat d\'echec du lecteur ; '
          '« Reessayer » relance le chargement et montre le texte', (
        WidgetTester tester,
      ) async {
        // Le chargement echoue tant que le reseau manque (Riverpod relance
        // seul une lecture en echec : l'echec doit durer pour etre vu).
        bool reseau = false;
        int appels = 0;
        await monterSeule(tester, () async {
          appels++;
          if (!reseau) {
            throw StateError('bibliotheque differee injoignable');
          }
          return const ServiceCoranDemo();
        });
        await _poser(tester);
        expect(find.byType(MushafPage), findsOneWidget);
        expect(find.text(t.eleve.coran.indisponible), findsOneWidget);
        expect(find.text(t.eleve.coran.reessayer), findsOneWidget);
        expect(find.textContaining(_alHamd, findRichText: true), findsNothing);

        reseau = true;
        final int avant = appels;
        await tester.tap(find.text(t.eleve.coran.reessayer));
        await _poser(tester);
        expect(appels, greaterThan(avant));
        expect(find.text(t.eleve.coran.indisponible), findsNothing);
        expect(find.textContaining(_alHamd, findRichText: true), findsWidgets);
        expect(tester.takeException(), isNull);
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
            _verifierVraiePageDemo();
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

  group('portee racine de main.dart (demarrage sur /demo/adulte)', () {
    test('posee seulement sur la demonstration adulte, hors production', () {
      List<Override> pour(String adresse, String environnement) =>
          surchargesRacineDemoAdulte(
            adresse: Uri.parse(adresse),
            environnement: environnement,
          );
      expect(pour('https://a.test/demo/adulte', 'staging'), hasLength(1));
      expect(
        pour('https://a.test/#/demo/adulte?ecran=coran', 'dev'),
        hasLength(1),
      );
      expect(pour('https://a.test/demo/adulte/x', 'staging'), hasLength(1));
      // Production : jamais, quelle que soit l'adresse.
      expect(pour('https://a.test/demo/adulte', 'production'), isEmpty);
      expect(pour('https://a.test/#/demo/adulte', ''), isEmpty);
      // Toute autre adresse : la racine reste la vraie.
      expect(pour('https://a.test/#/eleve/coran', 'dev'), isEmpty);
      expect(pour('https://a.test/demo/adultes', 'dev'), isEmpty);
      expect(pour('https://a.test/#/demo/classe', 'dev'), isEmpty);
    });
  });
}
