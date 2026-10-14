// CARTES-PERSO-1b : captures de preuve de la deuxieme revue adverse.
//
// En arabe (locale `ar`, sens RTL donne par la langue, pas force) : la
// feuille de l'enseignant a 320 px texte x2 avec ses aides, ses erreurs et
// les descriptions des modeles ; l'emplacement de l'enseignant (phrase de
// contexte) et celui de la famille (pictogrammes distincts) ; la vraie
// feuille ouverte depuis la page de demonstration de l'enseignant. La
// demonstration tuteur reelle est capturee par
// `test/features/demo/demo_tuteur_cartes_test.dart`.
//
// Sautees sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

const String _id = 'classe-capture';

Widget _app({
  required Widget Function(BuildContext) ecran,
  required AppLocale langue,
  List<Override> surcharges = const <Override>[],
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  String? adresse,
}) {
  final GoRouter routeur = GoRouter(
    initialLocation: adresse ?? '/capture',
    routes: <RouteBase>[
      GoRoute(path: '/capture', builder: (BuildContext c, _) => ecran(c)),
      ...routesDemoClasse('dev'),
    ],
  );
  addTearDown(routeur.dispose);
  return ProviderScope(
    overrides: <Override>[
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ...surcharges,
    ],
    child: TranslationProvider(
      child: RepaintBoundary(
        key: cadreCapture,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, luminosite),
          // Le sens vient de la langue : `ar` rend l'interface RTL.
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext c, Widget? app) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: app!,
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
}

List<Override> _demo({required bool peutModifier}) => <Override>[
  portCartesClasseProvider.overrideWith(
    (Ref _) => PortCartesClasseDemo(
      peutModifier: peutModifier,
      cartes: cartesClasseDemo(DateTime(2026, 10, 8)),
    ),
  ),
];

void _langue(AppLocale langue) {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

String _suffixe(AppLocale langue, Brightness lum) =>
    '${langue == AppLocale.ar ? 'ar_rtl' : 'fr_ltr'}_'
    '${lum == Brightness.light ? 'clair' : 'sombre'}';

void main() {
  group('Capture : CARTES-PERSO-1b', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      // La traduction arabe est differee : chargee hors du temps simule.
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    const List<(AppLocale, Brightness)> variantes = <(AppLocale, Brightness)>[
      (AppLocale.fr, Brightness.light),
      (AppLocale.ar, Brightness.dark),
      (AppLocale.ar, Brightness.light),
    ];

    for (final (AppLocale langue, Brightness lum) in variantes) {
      final String suffixe = _suffixe(langue, lum);
      testWidgets('feuille 320 x2 $suffixe', (WidgetTester tester) async {
        _langue(langue);
        fixerVueCapture(tester, const Size(320, 3600), 2);
        await tester.pumpWidget(
          _app(
            ecran: (_) => const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: FeuilleCarteClasse(groupeId: _id),
              ),
            ),
            langue: langue,
            surcharges: _demo(peutModifier: true),
            echelle: 2,
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        expect(
          Directionality.of(tester.element(find.byType(FeuilleCarteClasse))),
          langue == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr,
        );
        // Un devoir sans echeance (aucune seance connue), un titre vide, un
        // lien incomplet : les trois erreurs.
        await tester.tap(
          find.byKey(const ValueKey<String>('classe.cartes.modele.devoir')),
        );
        await stabiliser(tester);
        await tester.enterText(find.byKey(FeuilleCarteClasse.titreKey), '');
        await tester.enterText(find.byKey(FeuilleCarteClasse.lienKey), 'www');
        await tester.ensureVisible(
          find.byKey(FeuilleCarteClasse.enregistrerKey),
        );
        await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
        await stabiliser(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 8000));
        await stabiliser(tester);
        await capturer(tester, 'feuille_320x2_$suffixe');
      });

      for (final (String nom, bool peutModifier) in <(String, bool)>[
        ('enseignant', true),
        ('famille', false),
      ]) {
        testWidgets('bloc $nom 320 x2 $suffixe', (WidgetTester tester) async {
          _langue(langue);
          fixerVueCapture(tester, const Size(320, 2200), 2);
          await tester.pumpWidget(
            _app(
              ecran: (_) => const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: BlocCartesClasse(groupeId: _id),
                ),
              ),
              langue: langue,
              surcharges: _demo(peutModifier: peutModifier),
              echelle: 2,
              luminosite: lum,
            ),
          );
          await stabiliser(tester);
          await capturer(tester, 'bloc_${nom}_320x2_$suffixe');
        });
      }
    }

    // La vraie feuille, ouverte depuis la page de demonstration de
    // l'enseignant, en arabe.
    testWidgets('page enseignant 390, feuille, ar_rtl_clair', (
      WidgetTester tester,
    ) async {
      _langue(AppLocale.ar);
      fixerVueCapture(tester, const Size(390, 3000), 1);
      await tester.pumpWidget(
        _app(
          ecran: (_) => const SizedBox.shrink(),
          langue: AppLocale.ar,
          adresse: adresseDemoClasse(
            RoleEntree.enseignant,
            EtatDemoClasse.aVenir,
          ),
        ),
      );
      await stabiliser(tester);
      expect(find.byType(BlocCartesClasse), findsOneWidget);
      await tester.ensureVisible(find.byType(BlocCartesClasse));
      await stabiliser(tester);
      await capturer(tester, 'page_enseignant_390_ar_rtl_clair');
      await tester.ensureVisible(find.text(texteAffiche('Récitation modèle')));
      await tester.tap(find.text(texteAffiche('Récitation modèle')));
      await stabiliser(tester);
      expect(find.byType(FeuilleCarteClasse), findsOneWidget);
      await capturer(tester, 'page_enseignant_feuille_390_ar_rtl_clair');
    });
  });
}
