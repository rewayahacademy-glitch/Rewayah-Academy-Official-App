// PERSONNES-UNE-PAGE, etape (a) (directeur, 20/11/2026) : captures de la ligne
// entiere de Comptes, sur la VRAIE application et le vrai routeur en
// demonstration d'administration. Avant : la ligne ne repondait pas, seul
// « ... » ouvrait un menu. Apres : la ligne s'ouvre (apercu), le menu reste.
// Comptes fictifs (aucune personne reelle).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Les PNG du lot
// sont ranges dans `docs/current/captures/E2E/personnes-ligne/`.

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

import '../support/demo/mode_demonstration.dart';
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
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group(
    'PERSONNES (a) : la ligne entiere de Comptes',
    skip: sautSansCapture,
    () {
      const String base = Routes.adminPersonnesComptes;
      const Size bureau = Size(1440, 900);
      const Size telephone = Size(390, 844);

      // Le premier eleve de la vue : sa ligne, par son nom.
      Future<void> ouvrirPremiereLigne(WidgetTester tester) async {
        final CompteAdmin premier = _jeu().firstWhere(
          (CompteAdmin c) => c.role == AppRole.student,
        );
        await tester.tap(find.text(premier.libelle).first);
        await stabiliser(tester);
        await stabiliser(tester);
      }

      final List<(String, Size, ThemeMode, AppLocale)> cas =
          <(String, Size, ThemeMode, AppLocale)>[
            ('1440_fr_clair', bureau, ThemeMode.light, AppLocale.fr),
            ('1440_ar_sombre', bureau, ThemeMode.dark, AppLocale.ar),
            ('1440_en_clair', bureau, ThemeMode.light, AppLocale.en),
            ('390_fr_clair', telephone, ThemeMode.light, AppLocale.fr),
            ('390_ar_sombre', telephone, ThemeMode.dark, AppLocale.ar),
          ];
      for (final (String, Size, ThemeMode, AppLocale) c in cas) {
        testWidgets('ligne ouverte ${c.$1}', (WidgetTester tester) async {
          await LocaleSettings.setLocale(c.$4);
          fixerVueCapture(tester, c.$2, c.$2.width < 500 ? 2 : 1);
          await _monter(tester, '$base?vue=eleves', mode: c.$3);
          debugPrint('PNG ${await capturer(tester, 'ligne_liste_${c.$1}')}');
          await ouvrirPremiereLigne(tester);
          debugPrint('PNG ${await capturer(tester, 'ligne_apercu_${c.$1}')}');
        });
      }
    },
  );
}
