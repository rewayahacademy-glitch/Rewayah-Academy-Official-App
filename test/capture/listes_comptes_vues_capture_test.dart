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
  for (int i = 0; i < 24; i++)
    _compte(
      i,
      AppRole.teacher,
      piece: i < 2 ? EtatPiece.aVerifier : EtatPiece.validee,
      jours: 30 + i * 5,
      pays: const <String>['Sénégal', 'Maroc', 'France', 'Guinée'][i % 4],
    ),
  for (int i = 100; i < 130; i++)
    _compte(
      i,
      AppRole.guardian,
      etat: i == 109 ? AccountStatus.pendingKyc : AccountStatus.active,
      admission: i == 109,
      jours: 2 + i,
      enfants: 1 + i % 3,
    ),
  for (int i = 200; i < 260; i++)
    _compte(
      i,
      AppRole.student,
      jours: 1 + i,
      tranche: i % 5 == 0 ? TrancheAge.adulte : TrancheAge.enfant,
      classe: i % 4 == 0 ? null : _classes[i % 3],
      numero: i % 4 == 0 ? null : 1 + i % 2,
      tuteur: i % 5 == 0 ? null : '${_prenoms[i % 7]} ${_noms[i % 5]}',
    ),
  _compte(300, AppRole.admin, jours: 200),
  _compte(301, AppRole.controller, jours: 180),
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
    const Size bureau1440 = Size(1440, 900);
    const Size telephone = Size(390, 844);
    final List<(String, String, Size, ThemeMode)>
    cas = <(String, String, Size, ThemeMode)>[
      ('defaut_1366_light', base, bureau, ThemeMode.light),
      ('eleves_1440_light', '$base?vue=eleves', bureau1440, ThemeMode.light),
      (
        'familles_1440_light',
        '$base?vue=familles',
        bureau1440,
        ThemeMode.light,
      ),
      (
        'enseignants_1440_light',
        '$base?vue=enseignants',
        bureau1440,
        ThemeMode.light,
      ),
      ('eleves_1440_dark', '$base?vue=eleves', bureau1440, ThemeMode.dark),
      ('eleves_1366_light', '$base?vue=eleves', bureau, ThemeMode.light),
      ('eleves_1366_dark', '$base?vue=eleves', bureau, ThemeMode.dark),
      ('familles_1366_light', '$base?vue=familles', bureau, ThemeMode.light),
      (
        'enseignants_1366_light',
        '$base?vue=enseignants',
        bureau,
        ThemeMode.light,
      ),
      ('direction_1366_light', '$base?vue=direction', bureau, ThemeMode.light),
      ('eleves_390_light', '$base?vue=eleves', telephone, ThemeMode.light),
      ('eleves_390_dark', '$base?vue=eleves', telephone, ThemeMode.dark),
      ('familles_390_light', '$base?vue=familles', telephone, ThemeMode.light),
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
        debugPrint('MESURE comptes_${c.$1} ${_mesurer(tester, c.$3)}');
        debugPrint('PNG ${await capturer(tester, 'comptes_${c.$1}')}');
      });
    }

    // Preuve qu'il ne reste rien de fixe au-dessus des lignes : apres
    // defilement, seules la barre de l'application et (au bureau) la rangee
    // d'en-tetes de colonnes restent.
    for (final (String, Size) c in <(String, Size)>[
      ('apres_defilement_390', telephone),
      ('apres_defilement_1440', bureau1440),
    ]) {
      testWidgets('comptes ${c.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, c.$2, c.$2.width < 500 ? 2 : 1);
        await _monter(tester, '$base?vue=eleves', mode: ThemeMode.light);
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -400),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'comptes_${c.$1}')}');
      });
    }
  });
}

/// Le haut de la premiere ligne de la liste et le nombre de lignes entieres
/// visibles sans defiler, en points logiques.
String _mesurer(WidgetTester tester, Size vue) {
  final List<Rect> lignes =
      find
          .byWidgetPredicate(
            (Widget w) =>
                w is KeyedSubtree &&
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('p-'),
          )
          .evaluate()
          .map((Element e) => tester.getRect(find.byWidget(e.widget)))
          .toList()
        ..sort((Rect a, Rect b) => a.top.compareTo(b.top));
  if (lignes.isEmpty) return 'aucune ligne';
  final int entieres = lignes
      .where((Rect r) => r.top >= 0 && r.bottom <= vue.height)
      .length;
  return 'premiere ligne y=${lignes.first.top.toStringAsFixed(0)}, '
      'lignes entieres visibles=$entieres';
}
