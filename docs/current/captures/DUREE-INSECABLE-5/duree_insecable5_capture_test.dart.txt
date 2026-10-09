// DUREE-INSECABLE-5 : captures des tableaux d'administration (mode tableau
// de DataCollection, 1440 px) et de Qualite repliee en cartes.
//
// - Comptes, Progression, Qualite : 1440 clair LTR et 1440 sombre RTL. La
//   cellule « 12 jours » / « 9 jours » / « 8 jours » s'affiche seule, avec
//   son ancre de sens en tete ; son libelle parle (« Inscrit depuis : 12
//   jours ») n'a plus d'ancre au milieu. La marque est invisible : la preuve
//   est le test `duree_insecable_5_test.dart` (arbre semantique), la capture
//   montre le contexte.
// - Qualite, repliee en cartes dans le defilement de la page : 390 clair LTR
//   et 320 texte x2 sombre RTL. Avant DUREE-INSECABLE-5, la page levait
//   « Vertical viewport was given unbounded height » et ne montrait rien.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_progression/progression_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_qualite/qualite_page.dart';

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
    CompteAdmin(
      profilId: 'p2',
      identifiant: 'PAR-000002',
      prenom: 'Karim',
      nom: 'Benali',
      role: AppRole.guardian,
      etat: AccountStatus.pendingKyc,
      inscritLe: DateTime.now().subtract(const Duration(days: 3)),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.aucune,
      contrats: 0,
      aEnseignant: false,
      enfantsDuFoyer: 2,
    ),
  ];
}

final List<Override> _comptes = <Override>[
  serviceComptesProvider.overrideWithValue(_FauxServiceComptes()),
];

final List<Override> _progression = <Override>[
  progressionProvider.overrideWith(
    (Ref ref) async => <EleveProgression>[
      EleveProgression(
        studentId: 's1',
        identifiant: 'STUD-000001',
        prenom: 'Sofia',
        nom: 'B.',
        groupeId: 'g1',
        groupeLibelle: 'Groupe du soir',
        niveauId: 'n1',
        niveauNomHumain: 'Niveau 2',
        niveauCycle: 'tajwid',
        niveauDepuis: DateTime.now().subtract(
          const Duration(days: 9, hours: 1),
        ),
        exceptionActiveId: null,
        exceptionActiveType: null,
      ),
    ],
  ),
];

AnomalieQualite _anomalie(String id, TypeAnomalieQualite type, int jours) =>
    AnomalieQualite(
      type: type,
      refId: id,
      studentId: 's$id',
      studentPrenom: 'Sofia',
      studentNom: 'B.',
      teacherId: null,
      teacherPrenom: null,
      teacherNom: null,
      depuis: DateTime.now().subtract(Duration(days: jours, hours: 1)),
      controleStatut: StatutControleQualite.ouvert,
      controleNote: null,
    );

final List<Override> _qualite = <Override>[
  anomaliesQualiteProvider.overrideWith(
    (Ref ref) async => <AnomalieQualite>[
      _anomalie('1', TypeAnomalieQualite.blocageSansSuivi, 8),
      _anomalie('2', TypeAnomalieQualite.evaluationEnRetard, 15),
    ],
  ),
];

_Vue _vue(
  double largeur,
  double hauteur,
  double texte,
  ThemeMode theme,
  TextDirection sens,
) => (
  largeur: largeur,
  hauteur: hauteur,
  texte: texte,
  theme: theme,
  sens: sens,
  mode: InterfaceMode.standard,
);

void main() {
  group(
    'Capture : DUREE-INSECABLE-5, tableaux d administration',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      final List<_Vue> larges = <_Vue>[
        _vue(1440, 900, 1, ThemeMode.light, TextDirection.ltr),
        _vue(1440, 900, 1, ThemeMode.dark, TextDirection.rtl),
      ];
      final List<({String page, Widget ecran, List<Override> s, String v})>
      pages = <({String page, Widget ecran, List<Override> s, String v})>[
        (
          page: 'comptes_tableau',
          ecran: const ComptesPage(),
          s: _comptes,
          v: '12 jours',
        ),
        (
          page: 'progression_tableau',
          ecran: const ProgressionPage(),
          s: _progression,
          v: '9 jours',
        ),
        (
          page: 'qualite_tableau',
          ecran: const QualitePage(),
          s: _qualite,
          v: '8 jours',
        ),
      ];
      for (final ({String page, Widget ecran, List<Override> s, String v}) p
          in pages) {
        for (final _Vue v in larges) {
          final String nom = _nom(p.page, v);
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
            await tester.pumpWidget(
              _hote(
                v,
                ecran: p.ecran,
                surcharges: <Override>[
                  ...p.s,
                  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
                ],
              ),
            );
            await stabiliser(tester);
            expect(find.textContaining(p.v), findsWidgets);
            expect(tester.takeException(), isNull);
            await capturer(tester, nom);
          });
        }
      }

      for (final _Vue v in <_Vue>[
        _vue(390, 1000, 1, ThemeMode.light, TextDirection.ltr),
        _vue(320, 1400, 2, ThemeMode.dark, TextDirection.rtl),
      ]) {
        final String nom = _nom('qualite_cartes', v);
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, Size(v.largeur, v.hauteur), 1);
          await tester.pumpWidget(
            _hote(
              v,
              ecran: const QualitePage(),
              surcharges: <Override>[
                ..._qualite,
                serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
              ],
            ),
          );
          await stabiliser(tester);
          expect(find.textContaining('8 jours'), findsWidgets);
          expect(tester.takeException(), isNull);
          await capturer(tester, nom);
        });
      }
    },
  );
}
