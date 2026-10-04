// PT-B : l'onglet Coran de l'eleve adulte.
//
// Route reelle (K-07) : `/eleve/adulte` vit dans la branche 0 de la coquille
// eleve ; l'onglet Coran de la VRAIE barre rejoint la branche 2
// (`/eleve/coran`), la vraie `MushafPage` ; Accueil y ramene.
//
// Demonstration `/demo/adulte` : aucun corpus coranique n'y est embarque
// (decision deleguee du 04/10). L'onglet Coran ne mene plus a la page
// provisoire d'EA-1b : il dit que le Coran est disponible apres connexion,
// sans aucun appel serveur (K-28), sans lecteur (son erreur reseau mentirait,
// K-59), sans bouton. Hors ligne, la page est la meme.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/demo/coran_demo_adulte.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_page_mushaf.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show lieu;
import '../../support/aucun_mot_coupe.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';
import 'support_accueil_adulte_route.dart';

/// L'ancienne phrase de la page provisoire d'EA-1b, qui ne doit plus
/// paraitre nulle part.
const String _phraseProvisoire =
    "Le Coran de votre espace élève s'affichera ici.";

/// L'onglet de la barre portant [libelle] (le titre de la page peut le
/// reprendre : on vise le dernier, celui de la barre).
Finder _onglet(String libelle) => find
    .descendant(of: find.byType(NavShell), matching: find.text(libelle))
    .last;

int? _actif(WidgetTester tester) =>
    tester.widget<NavShell>(find.byType(NavShell)).indexActif;

/// Laisse les lectures du Coran se resoudre sans `pumpAndSettle` (un
/// indicateur de chargement tournerait sans fin).
Future<void> _poser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Un `ServiceCoran` qui compte chaque appel : la demonstration ne doit en
/// faire aucun (K-28).
class _ServiceEspion implements ServiceCoran {
  int appels = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    appels++;
    throw StateError('appel serveur en demonstration');
  }
}

/// La demonstration dit « disponible apres connexion » : l'etat
/// indisponible, sans bouton, sans lecteur, sans erreur reseau.
void _verifierDisponibleApresConnexion(WidgetTester tester) {
  expect(find.byType(CoranDemoAdulte), findsOneWidget);
  final Finder etat = find.byKey(CoranDemoAdulte.etatKey);
  expect(etat, findsOneWidget);
  expect(tester.widget<EtatSysteme>(etat).nature, NatureEtat.indisponible);
  expect(find.text(t.adulte.coranDemo.titre), findsOneWidget);
  expect(find.text(t.adulte.coranDemo.phrase), findsOneWidget);
  // Aucun bouton : il n'y a rien a reessayer.
  expect(
    find.descendant(of: etat, matching: find.byType(ButtonStyleButton)),
    findsNothing,
  );
  expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
  // Ni lecteur, ni erreur reseau du lecteur, ni page provisoire.
  expect(find.byType(MushafPage), findsNothing);
  expect(find.text(t.eleve.coran.indisponible), findsNothing);
  expect(find.text(t.eleve.coran.reessayer), findsNothing);
  expect(find.text(_phraseProvisoire), findsNothing);
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  /// Le corpus de reference des tests de la route reelle : aucun serveur.
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
  }) => monterAccueilAdulteReel(
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

  group('route reelle (K-07)', () {
    testWidgets('Accueil adulte -> onglet Coran : /eleve/coran, la vraie page '
        'Coran, onglet allume ; Accueil ramene a /eleve/adulte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterReel(tester);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(_actif(tester), 0);

      await tester.tap(_onglet(t.nav.eleve.coran));
      await _poser(tester);

      expect(lieu(routeur), Routes.eleveCoran);
      expect(find.byType(MushafPage), findsOneWidget);
      // Le texte du corpus de reference, rendu par le vrai lecteur.
      expect(find.byType(CadrePageMushaf), findsOneWidget);
      expect(find.byType(AccueilAdultePage), findsNothing);
      expect(find.byType(CoranDemoAdulte), findsNothing);
      expect(find.text(_phraseProvisoire), findsNothing);
      expect(find.text(t.adulte.coranDemo.titre), findsNothing);
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
      expect(find.byType(AccueilAdultePage), findsNothing);

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

  group('demonstration /demo/adulte : disponible apres connexion', () {
    Future<GoRouter> monterDemo(
      WidgetTester tester, {
      String? depart,
      Size taille = const Size(390, 844),
      double echelle = 1,
      TextDirection direction = TextDirection.ltr,
      List<Override> surcharges = const <Override>[],
    }) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = GoRouter(
        initialLocation: depart ?? adresseDemoAdulte(EcranDemoAdulte.accueil),
        routes: routesDemoAdulte('dev'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: surcharges,
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

    testWidgets('onglet Coran : disponible apres connexion, onglet allume, '
        'aucun appel serveur ; Accueil y ramene', (WidgetTester tester) async {
      final _ServiceEspion espion = _ServiceEspion();
      final GoRouter routeur = await monterDemo(
        tester,
        surcharges: <Override>[serviceCoranProvider.overrideWithValue(espion)],
      );
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(_actif(tester), 0);

      await tester.tap(_onglet(t.adulte.nav.coran));
      await _poser(tester);

      expect(lieu(routeur), adresseDemoAdulte(EcranDemoAdulte.coran));
      _verifierDisponibleApresConnexion(tester);
      expect(_actif(tester), 2);
      expect(
        tester.widget<NavShell>(find.byType(NavShell)).destinations,
        hasLength(4),
      );
      expect(espion.appels, 0);

      await tester.tap(_onglet(t.adulte.nav.accueil));
      await _poser(tester);
      expect(lieu(routeur), adresseDemoAdulte(EcranDemoAdulte.accueil));
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(find.byType(CoranDemoAdulte), findsNothing);
      expect(_actif(tester), 0);
      expect(espion.appels, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hors ligne (reseau=coupe) : la meme page, aucune erreur '
        'reseau (elle ne depend d\'aucun reseau)', (WidgetTester tester) async {
      await monterDemo(
        tester,
        depart: adresseDemoAdulte(EcranDemoAdulte.coran, reseauCoupe: true),
      );
      _verifierDisponibleApresConnexion(tester);
      expect(find.text(t.commun.etats.horsLigne.titre), findsNothing);
      expect(_actif(tester), 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ouverte directement par son adresse : la meme page', (
      WidgetTester tester,
    ) async {
      await monterDemo(
        tester,
        depart: adresseDemoAdulte(EcranDemoAdulte.coran),
      );
      _verifierDisponibleApresConnexion(tester);
      expect(_actif(tester), 2);
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
          _verifierDisponibleApresConnexion(tester);
          // Le titre et la phrase sont entiers et atteignables.
          await tester.ensureVisible(find.text(t.adulte.coranDemo.phrase));
          await tester.pump();
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
  });
}
