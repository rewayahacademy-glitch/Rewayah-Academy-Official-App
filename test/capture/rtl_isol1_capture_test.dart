// RTL-ISOL-1 : valeurs et phrases francaises dans l'interface arabe (RTL).
// Pages entieres, de haut en bas, pour que la pastille de capacite et le
// conseil d'appareil soient dans le cadre (reserve de COUPE-MOTS-3b) :
// - `espaceclasse_ens` / `espaceclasse_elv` : l'Espace Classe de
//   demonstration (pastille « 3 élèves sur 6 places », conseil d'appareil,
//   progression, ligne des eleves, duree avant le cours) ;
// - `ma_classe_adulte` : la section « A propos » (« ... règles de tajwid. ») ;
// - `comptes` : l'introduction de Comptes (point final) ;
// Prefixe des PNG : variable `CAPTURE_PREFIXE` (avant | apres).
// `CAPTURE_ARABE_SEUL=1` ne garde que l'arabe. Saute sans CAPTURE_DIR.

import 'dart:io';

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
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart'
    show EtatDemoClasse;
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

final String _prefixe = Platform.environment['CAPTURE_PREFIXE'] ?? 'apres';
final bool _arabeSeul = Platform.environment['CAPTURE_ARABE_SEUL'] == '1';

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    CompteAdmin(
      profilId: 'GUARDIAN-FB-000003',
      identifiant: 'GUARDIAN-FB-000003',
      prenom: 'Fatoumata',
      nom: 'Diallo',
      role: AppRole.guardian,
      etat: AccountStatus.active,
      inscritLe: DateTime(2026, 9, 1),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.validee,
      contrats: 1,
      aEnseignant: true,
      enfantsDuFoyer: 2,
    ),
  ];
}

typedef _Variante = ({
  String nom,
  double largeur,
  double hauteur,
  double echelle,
  Brightness clarte,
});

const List<_Variante> _variantes = <_Variante>[
  (
    nom: '320x2_clair',
    largeur: 320,
    hauteur: 6400,
    echelle: 2,
    clarte: Brightness.light,
  ),
  (
    nom: '390_sombre',
    largeur: 390,
    hauteur: 3000,
    echelle: 1,
    clarte: Brightness.dark,
  ),
];

/// Un routeur de demonstration, a la langue et a la variante donnees.
Future<void> _monterRoutes(
  WidgetTester tester,
  _Variante v,
  String adresse,
  List<RouteBase> routes,
) async {
  final GoRouter routeur = GoRouter(initialLocation: adresse, routes: routes);
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, v.clarte),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext c, Widget? app) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(v.echelle)),
                child: app!,
              ),
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : RTL-ISOL-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final AppLocale langue in AppLocale.values) {
      if (_arabeSeul && langue != AppLocale.ar) continue;
      for (final _Variante v in _variantes) {
        final String suffixe = '${v.nom}_${langue.languageCode}';

        void cas(String nom, Future<void> Function(WidgetTester) corps) {
          testWidgets('${_prefixe}_${nom}_$suffixe', (
            WidgetTester tester,
          ) async {
            LocaleSettings.setLocaleSync(langue);
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
            await corps(tester);
            debugPrint(
              'PNG ${await capturer(tester, '${_prefixe}_${nom}_$suffixe')}',
            );
          });
        }

        for (final RoleEntree role in <RoleEntree>[
          RoleEntree.enseignant,
          RoleEntree.eleve,
        ]) {
          final String ecran = role == RoleEntree.enseignant ? 'ens' : 'elv';
          cas('espaceclasse_$ecran', (WidgetTester tester) async {
            fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
            await _monterRoutes(
              tester,
              v,
              adresseDemoClasse(role, EtatDemoClasse.aVenir),
              routesDemoClasse('dev'),
            );
          });
        }

        cas('ma_classe_adulte', (WidgetTester tester) async {
          fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
          await _monterRoutes(
            tester,
            v,
            adresseDemoAdulte(EcranDemoAdulte.maClasse),
            routesDemoAdulte('dev'),
          );
        });

        cas('comptes', (WidgetTester tester) async {
          fixerVueCapture(
            tester,
            Size(v.largeur, v.echelle == 2 ? 1600 : 900),
            1,
          );
          await tester.pumpWidget(
            hoteCapture(
              const ComptesPage(),
              surcharges: <Override>[
                serviceComptesProvider.overrideWithValue(_Comptes()),
                serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              ],
              themeMode: v.clarte == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              echelleTexte: v.echelle,
            ),
          );
          await stabiliser(tester);
        });
      }
    }
  });
}
