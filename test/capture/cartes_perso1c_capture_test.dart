// CARTES-PERSO-1c : captures de preuve des reserves de la revue
// CARTES-PERSO-1b.
//
// (1) Lignes « Echeance : {date} » et « Aucune echeance » isolees : bloc de
// la famille et feuille de l'enseignant, 320 px texte x2, arabe (RTL donne
// par la langue) et francais. (2) La demonstration de la direction
// (`surchargesDemoAdmin`) lit les cartes de demonstration, en lecture seule.
//
// Ancien en-tete CARTES-PERSO-1b, garde pour memoire :
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
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
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

Widget _defilant(Widget enfant) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: enfant,
  ),
);

void main() {
  group('Capture : CARTES-PERSO-1c', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      // La traduction arabe est differee : chargee hors du temps simule.
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    const List<(AppLocale, Brightness)> variantes = <(AppLocale, Brightness)>[
      (AppLocale.fr, Brightness.light),
      (AppLocale.ar, Brightness.light),
      (AppLocale.ar, Brightness.dark),
    ];

    for (final (AppLocale langue, Brightness lum) in variantes) {
      final String suffixe = _suffixe(langue, lum);

      testWidgets('bloc famille 320 x2 $suffixe', (WidgetTester tester) async {
        _langue(langue);
        fixerVueCapture(tester, const Size(320, 2200), 2);
        await tester.pumpWidget(
          _app(
            ecran: (_) => _defilant(const BlocCartesClasse(groupeId: _id)),
            langue: langue,
            surcharges: _demo(peutModifier: false),
            echelle: 2,
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        await capturer(tester, 'bloc_famille_echeances_320x2_$suffixe');
      });

      testWidgets('feuille, aucune echeance, 320 x2 $suffixe', (
        WidgetTester tester,
      ) async {
        _langue(langue);
        fixerVueCapture(tester, const Size(320, 3600), 2);
        await tester.pumpWidget(
          _app(
            ecran: (_) => _defilant(const FeuilleCarteClasse(groupeId: _id)),
            langue: langue,
            surcharges: _demo(peutModifier: true),
            echelle: 2,
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        await tester.ensureVisible(
          find.byKey(FeuilleCarteClasse.enregistrerKey),
        );
        await stabiliser(tester);
        await capturer(tester, 'feuille_aucune_echeance_320x2_$suffixe');
      });

      testWidgets('feuille, devoir date, 320 x2 $suffixe', (
        WidgetTester tester,
      ) async {
        _langue(langue);
        fixerVueCapture(tester, const Size(320, 3600), 2);
        await tester.pumpWidget(
          _app(
            ecran: (_) => _defilant(
              FeuilleCarteClasse(
                groupeId: _id,
                carte: cartesClasseDemo(DateTime(2026, 10, 8)).first,
              ),
            ),
            langue: langue,
            surcharges: _demo(peutModifier: true),
            echelle: 2,
            luminosite: lum,
          ),
        );
        await stabiliser(tester);
        await tester.ensureVisible(
          find.byKey(FeuilleCarteClasse.enregistrerKey),
        );
        await stabiliser(tester);
        await capturer(tester, 'feuille_devoir_echeance_320x2_$suffixe');
      });
    }

    // Les surcharges reelles de la demonstration de la direction, sans
    // injection de cartes : le bloc les lit en lecture seule.
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      final String suffixe = _suffixe(langue, Brightness.light);
      testWidgets('demonstration direction, bloc 390 $suffixe', (
        WidgetTester tester,
      ) async {
        _langue(langue);
        fixerVueCapture(tester, const Size(390, 1600), 1);
        await tester.pumpWidget(
          _app(
            ecran: (_) => _defilant(const BlocCartesClasse(groupeId: _id)),
            langue: langue,
            surcharges: surchargesDemoAdmin(environnement: 'staging'),
          ),
        );
        await stabiliser(tester);
        expect(find.byType(VueCarteClasse), findsNWidgets(3));
        await capturer(tester, 'demo_direction_bloc_390_$suffixe');
      });
    }
  });
}
