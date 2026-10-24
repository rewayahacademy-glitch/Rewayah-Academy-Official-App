// Captures de la page Comptes refondue (LISTES-3, 23/10/2026), sur la VRAIE
// application et le vrai routeur en demonstration d'administration : la coque
// est dans chaque PNG. Soixante-dix comptes fictifs (aucune personne reelle).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../support/comptes_capture.dart';
import 'outil_capture.dart';

const List<String> _prenoms = <String>[
  'Amine',
  'Salma',
  'Yasmine',
  'Ismael',
  'Maryam',
  'Hamza',
  'Lina',
  'Zaynab',
  'Idriss',
  'Nadia',
  'Bilal',
  'Sara',
  'Anas',
  'Imane',
  'Ayoub',
  'Hana',
  'Karim',
  'Leila',
  'Omar',
  'Rania',
  'Sami',
  'Tasnim',
  'Walid',
  'Yara',
];
const List<String> _noms = <String>[
  'Diop',
  'Benali',
  'Camara',
  'Kone',
  'Rahmani',
  'Sow',
  'Barry',
  'Traore',
  'Haddad',
  'Diallo',
  'Kane',
  'Ndiaye',
  'Cisse',
  'Fofana',
  'Toure',
  'Bah',
];

CompteAdmin _compte(
  int i,
  AppRole role, {
  AccountStatus etat = AccountStatus.active,
  EtatPiece piece = EtatPiece.aucune,
  int jours = 20,
  bool aEnseignant = false,
  int enfants = 0,
  String? pays,
}) {
  final String sigle = switch (role) {
    AppRole.student => 'STUD',
    AppRole.guardian => 'GUAR',
    AppRole.teacher => 'TEACH',
    _ => 'STAFF',
  };
  final String prenom = _prenoms[i % _prenoms.length];
  final String nom = _noms[(i * 7) % _noms.length];
  final String id =
      '$sigle-${prenom[0]}${nom[0]}-${(100000 + i).toString().substring(1)}';
  return CompteAdmin(
    profilId: id,
    identifiant: id,
    prenom: prenom,
    nom: nom,
    role: role,
    etat: etat,
    inscritLe: DateTime.now().subtract(Duration(days: jours)),
    accesJusquAu: null,
    foyerId: null,
    piece: piece,
    contrats: role == AppRole.student ? 0 : 2,
    aEnseignant: aEnseignant,
    enfantsDuFoyer: enfants,
    paysEnseignant: pays,
  );
}

List<CompteAdmin> _soixanteDix() {
  const List<String> pays = <String>[
    'Guinée',
    'Sénégal',
    'France',
    'Mali',
    'Maroc',
  ];
  return <CompteAdmin>[
    for (int i = 0; i < 14; i++)
      _compte(
        i,
        AppRole.teacher,
        etat: i < 2 ? AccountStatus.pendingKyc : AccountStatus.active,
        piece: i == 0
            ? EtatPiece.aucune
            : (i < 4 ? EtatPiece.aVerifier : EtatPiece.validee),
        jours: i < 2 ? 9 + i : 40 + i * 5,
        pays: pays[i % pays.length],
      ),
    for (int i = 14; i < 36; i++)
      _compte(
        i,
        AppRole.guardian,
        etat: i == 20 ? AccountStatus.provisionalActive : AccountStatus.active,
        jours: 3 + i * 2,
        enfants: 1 + i % 3,
      ),
    for (int i = 36; i < 68; i++)
      _compte(
        i,
        AppRole.student,
        etat: i == 50 ? AccountStatus.disabled : AccountStatus.active,
        jours: 1 + i,
        aEnseignant: i % 4 != 0,
      ),
    _compte(68, AppRole.admin, jours: 200),
    _compte(69, AppRole.accountant, jours: 180),
  ];
}

Future<void> _monter(
  WidgetTester tester,
  String route, {
  required ThemeMode mode,
}) async {
  late GoRouter routeur;
  final ServiceComptes service = FauxComptesCapture(_soixanteDix());
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        comptesProvider.overrideWith((Ref ref) => service.comptes()),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(route);
  await stabiliser(tester);
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('LISTES-3 : captures de Comptes', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    const String base = Routes.adminPersonnesComptes;
    final List<(String, String, Size, ThemeMode)> cas =
        <(String, String, Size, ThemeMode)>[
          ('tous_1440_light', base, const Size(1440, 900), ThemeMode.light),
          ('tous_1440_dark', base, const Size(1440, 900), ThemeMode.dark),
          (
            'eleves_1440_light',
            '$base?role=student',
            const Size(1440, 900),
            ThemeMode.light,
          ),
          (
            'eleves_1440_dark',
            '$base?role=student',
            const Size(1440, 900),
            ThemeMode.dark,
          ),
          (
            'tuteurs_1440_light',
            '$base?role=guardian',
            const Size(1440, 900),
            ThemeMode.light,
          ),
          (
            'tuteurs_1440_dark',
            '$base?role=guardian',
            const Size(1440, 900),
            ThemeMode.dark,
          ),
          (
            'enseignants_1440_light',
            '$base?role=teacher',
            const Size(1440, 900),
            ThemeMode.light,
          ),
          (
            'filtres_actifs_1440_light',
            '$base?role=teacher&etat=attente&q=diop',
            const Size(1440, 900),
            ThemeMode.light,
          ),
          ('tous_390_light', base, const Size(390, 844), ThemeMode.light),
          (
            'eleves_390_dark',
            '$base?role=student',
            const Size(390, 844),
            ThemeMode.dark,
          ),
        ];
    testWidgets('comptes tuteurs_1440_ar', (WidgetTester tester) async {
      await LocaleSettings.setLocale(AppLocale.ar);
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monter(tester, '$base?role=guardian', mode: ThemeMode.light);
      debugPrint('PNG ${await capturer(tester, 'comptes_tuteurs_1440_ar')}');
    });

    for (final (String, String, Size, ThemeMode) c in cas) {
      testWidgets('comptes ${c.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, c.$3, c.$3.width < 500 ? 2 : 1);
        await _monter(tester, c.$2, mode: c.$4);
        debugPrint('PNG ${await capturer(tester, 'comptes_${c.$1}')}');
      });
    }
  });
}
