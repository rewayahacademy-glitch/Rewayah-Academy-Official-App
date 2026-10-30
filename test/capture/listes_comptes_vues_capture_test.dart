// Captures de la page Comptes separee par role (directeur, 30/10/2026), sur la
// VRAIE application et le vrai routeur en demonstration d'administration : la
// coque est dans chaque PNG. Comptes fictifs (aucune personne reelle).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Les PNG du lot
// sont ranges dans `docs/captures/2026-10-31-listes/`.

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
];
const List<String> _classes = <String>[
  'Lettres, mardi 18 h',
  'Lecture, samedi 10 h',
  'Mémorisation, dimanche 15 h',
];

CompteAdmin _compte(
  int i,
  AppRole role, {
  AccountStatus etat = AccountStatus.active,
  EtatPiece piece = EtatPiece.aucune,
  int jours = 20,
  int enfants = 0,
  String? pays,
  TrancheAge? tranche,
  String? classe,
  int? numero,
  String? tuteur,
  bool admission = false,
}) {
  final String prenom = _prenoms[i % _prenoms.length];
  final String nom = _noms[(i * 3) % _noms.length];
  final String id = 'RA-26-${(4000 + i * 37) % 10000}';
  return CompteAdmin(
    profilId: 'p-$i',
    identifiant: id,
    prenom: prenom,
    nom: nom,
    role: role,
    etat: etat,
    inscritLe: DateTime.now().subtract(Duration(days: jours)),
    accesJusquAu: null,
    foyerId: null,
    piece: piece,
    contrats: role == AppRole.teacher ? 2 : 0,
    aEnseignant: classe != null,
    enfantsDuFoyer: enfants,
    paysEnseignant: pays,
    detailsServis: true,
    tranche: tranche,
    classeLibelle: classe,
    classeNumero: numero,
    classesActives: classe == null ? 0 : 1,
    tuteurId: tuteur == null ? null : 't-$tuteur',
    tuteurPrenom: tuteur,
    admissionATraiter: admission,
  );
}

List<CompteAdmin> _jeu() => <CompteAdmin>[
  for (int i = 0; i < 8; i++)
    _compte(
      i,
      AppRole.teacher,
      piece: i < 2 ? EtatPiece.aVerifier : EtatPiece.validee,
      jours: 30 + i * 5,
      pays: const <String>['SN', 'MA', 'FR', 'GN'][i % 4],
    ),
  for (int i = 8; i < 20; i++)
    _compte(
      i,
      AppRole.guardian,
      etat: i == 9 ? AccountStatus.pendingKyc : AccountStatus.active,
      admission: i == 9,
      jours: 2 + i,
      enfants: 1 + i % 3,
    ),
  for (int i = 20; i < 48; i++)
    _compte(
      i,
      AppRole.student,
      jours: 1 + i,
      tranche: i % 5 == 0 ? TrancheAge.adulte : TrancheAge.enfant,
      classe: i % 4 == 0 ? null : _classes[i % 3],
      numero: i % 4 == 0 ? null : 1 + i % 2,
      tuteur: i % 5 == 0 ? null : '${_prenoms[i % 7]} ${_noms[i % 5]}',
    ),
  _compte(48, AppRole.admin, jours: 200),
  _compte(49, AppRole.controller, jours: 180),
];

class _Faux implements ServiceComptes {
  const _Faux(this.liste);

  final List<CompteAdmin> liste;

  @override
  Future<List<CompteAdmin>> comptes() async => liste;
}

Future<void> _monter(
  WidgetTester tester,
  String route, {
  required ThemeMode mode,
}) async {
  late GoRouter routeur;
  final ServiceComptes service = _Faux(_jeu());
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

  group('LISTES : captures de Comptes par role', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    const String base = Routes.adminPersonnesComptes;
    const Size bureau = Size(1366, 768);
    const Size telephone = Size(390, 844);
    final List<(String, String, Size, ThemeMode)> cas =
        <(String, String, Size, ThemeMode)>[
          ('defaut_1366_light', base, bureau, ThemeMode.light),
          ('eleves_1366_light', '$base?vue=eleves', bureau, ThemeMode.light),
          ('eleves_1366_dark', '$base?vue=eleves', bureau, ThemeMode.dark),
          (
            'familles_1366_light',
            '$base?vue=familles',
            bureau,
            ThemeMode.light,
          ),
          (
            'enseignants_1366_light',
            '$base?vue=enseignants',
            bureau,
            ThemeMode.light,
          ),
          (
            'direction_1366_light',
            '$base?vue=direction',
            bureau,
            ThemeMode.light,
          ),
          ('eleves_390_light', '$base?vue=eleves', telephone, ThemeMode.light),
          ('eleves_390_dark', '$base?vue=eleves', telephone, ThemeMode.dark),
          (
            'familles_390_light',
            '$base?vue=familles',
            telephone,
            ThemeMode.light,
          ),
          (
            'enseignants_390_light',
            '$base?vue=enseignants',
            telephone,
            ThemeMode.light,
          ),
        ];

    testWidgets('comptes eleves_1366_ar', (WidgetTester tester) async {
      await LocaleSettings.setLocale(AppLocale.ar);
      fixerVueCapture(tester, bureau, 1);
      await _monter(tester, '$base?vue=eleves', mode: ThemeMode.light);
      debugPrint('PNG ${await capturer(tester, 'comptes_eleves_1366_ar')}');
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
