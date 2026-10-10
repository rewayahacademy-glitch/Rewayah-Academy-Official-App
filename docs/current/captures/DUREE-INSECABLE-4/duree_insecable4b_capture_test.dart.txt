// DUREE-INSECABLE-4 (reprise apres relecture adverse) : captures sur les
// PAGES REELLES, et non plus sur la carte seule.
//
// - Ma classe adulte (demonstration adulte) : 1440 clair LTR, 390 clair LTR,
//   390 sombre RTL, 320 texte x2 sombre RTL, 390 Interface guidee clair RTL ;
// - Mode Accessibilite (Mariam, Idriss) : 1440 clair RTL, 320 texte x2
//   sombre RTL, 390 Interface guidee sombre LTR ;
// - Comptes (administration), repliee en cartes : 800 clair LTR et 320
//   texte x2 sombre RTL ; la colonne « 12 jours » est jointe sans ancre de
//   sens au milieu (la marque est invisible : la preuve est le test
//   `duree_insecable_4_test.dart`, la capture montre le rendu).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

typedef _Vue = ({
  double largeur,
  double hauteur,
  double texte,
  ThemeMode theme,
  TextDirection sens,
  InterfaceMode mode,
});

String _nom(String page, _Vue v) =>
    '${page}_${v.largeur.toInt()}x${v.texte.toInt()}_${v.theme.name}_'
    '${v.sens.name}${v.mode == InterfaceMode.enfant ? '_guidee' : ''}';

Widget _hote(
  _Vue v, {
  String? depart,
  List<RouteBase> routes = const <RouteBase>[],
  Widget? ecran,
  List<Override> surcharges = const <Override>[],
}) {
  Widget builder(BuildContext c, Widget? app) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(v.texte)),
    child: Directionality(textDirection: v.sens, child: app!),
  );
  return ProviderScope(
    overrides: surcharges,
    child: TranslationProvider(
      child: RepaintBoundary(
        key: cadreCapture,
        child: ecran == null
            ? MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(v.mode, Brightness.light),
                darkTheme: AppTheme.pour(v.mode, Brightness.dark),
                themeMode: v.theme,
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: builder,
                routerConfig: GoRouter(initialLocation: depart, routes: routes),
              )
            : MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(v.mode, Brightness.light),
                darkTheme: AppTheme.pour(v.mode, Brightness.dark),
                themeMode: v.theme,
                locale: AppLocale.fr.flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: builder,
                home: ecran,
              ),
      ),
    ),
  );
}

class _FauxServiceComptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    CompteAdmin(
      profilId: 'p1',
      identifiant: 'TEACHER-AS-000001',
      prenom: 'Aicha',
      nom: 'Sow',
      role: AppRole.teacher,
      etat: AccountStatus.pendingKyc,
      inscritLe: DateTime.now().subtract(const Duration(days: 12)),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.aucune,
      contrats: 2,
      aEnseignant: false,
      enfantsDuFoyer: 0,
    ),
  ];
}

const _Vue _v1440 = (
  largeur: 1440,
  hauteur: 1100,
  texte: 1,
  theme: ThemeMode.light,
  sens: TextDirection.ltr,
  mode: InterfaceMode.standard,
);

void main() {
  group(
    'Capture : DUREE-INSECABLE-4, pages reelles',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      final List<_Vue> vuesMaClasse = <_Vue>[
        _v1440,
        (
          largeur: 390,
          hauteur: 1500,
          texte: 1,
          theme: ThemeMode.light,
          sens: TextDirection.ltr,
          mode: InterfaceMode.standard,
        ),
        (
          largeur: 390,
          hauteur: 1500,
          texte: 1,
          theme: ThemeMode.dark,
          sens: TextDirection.rtl,
          mode: InterfaceMode.standard,
        ),
        (
          largeur: 320,
          hauteur: 2600,
          texte: 2,
          theme: ThemeMode.dark,
          sens: TextDirection.rtl,
          mode: InterfaceMode.standard,
        ),
        (
          largeur: 390,
          hauteur: 1700,
          texte: 1,
          theme: ThemeMode.light,
          sens: TextDirection.rtl,
          mode: InterfaceMode.enfant,
        ),
      ];
      for (final _Vue v in vuesMaClasse) {
        final String nom = _nom('ma_classe_adulte', v);
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
          await tester.pumpWidget(
            _hote(
              v,
              depart: adresseDemoAdulte(EcranDemoAdulte.maClasse),
              routes: routesDemoAdulte('dev'),
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          await capturer(tester, nom);
        });
      }

      final List<(EleveDemoAccessibilite, MomentDemoAccessibilite, _Vue)>
      vuesAccessibilite =
          <(EleveDemoAccessibilite, MomentDemoAccessibilite, _Vue)>[
            (
              EleveDemoAccessibilite.idriss,
              MomentDemoAccessibilite.fenetre,
              (
                largeur: 1440,
                hauteur: 1100,
                texte: 1,
                theme: ThemeMode.light,
                sens: TextDirection.rtl,
                mode: InterfaceMode.standard,
              ),
            ),
            (
              EleveDemoAccessibilite.mariam,
              MomentDemoAccessibilite.avant,
              (
                largeur: 320,
                hauteur: 2600,
                texte: 2,
                theme: ThemeMode.dark,
                sens: TextDirection.rtl,
                mode: InterfaceMode.standard,
              ),
            ),
            (
              EleveDemoAccessibilite.mariam,
              MomentDemoAccessibilite.avant,
              (
                largeur: 390,
                hauteur: 1700,
                texte: 1,
                theme: ThemeMode.dark,
                sens: TextDirection.ltr,
                mode: InterfaceMode.enfant,
              ),
            ),
          ];
      for (final (
            EleveDemoAccessibilite eleve,
            MomentDemoAccessibilite moment,
            _Vue v,
          )
          in vuesAccessibilite) {
        final String nom = _nom(
          'accessibilite_${eleve.name}_${moment.name}',
          v,
        );
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
          await tester.pumpWidget(
            _hote(
              v,
              depart: adresseDemoAccessibilite(eleve, moment: moment),
              routes: routesDemoAccessibilite('dev'),
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          await capturer(tester, nom);
        });
      }

      final List<_Vue> vuesComptes = <_Vue>[
        (
          largeur: 800,
          hauteur: 900,
          texte: 1,
          theme: ThemeMode.light,
          sens: TextDirection.ltr,
          mode: InterfaceMode.standard,
        ),
        (
          largeur: 320,
          hauteur: 1600,
          texte: 2,
          theme: ThemeMode.dark,
          sens: TextDirection.rtl,
          mode: InterfaceMode.standard,
        ),
      ];
      for (final _Vue v in vuesComptes) {
        final String nom = _nom('comptes_cartes', v);
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
          await tester.pumpWidget(
            _hote(
              v,
              ecran: const ComptesPage(),
              surcharges: <Override>[
                serviceComptesProvider.overrideWithValue(_FauxServiceComptes()),
                serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              ],
            ),
          );
          await stabiliser(tester);
          expect(find.textContaining('12 jours'), findsWidgets);
          expect(tester.takeException(), isNull);
          await capturer(tester, nom);
        });
      }
    },
  );
}
