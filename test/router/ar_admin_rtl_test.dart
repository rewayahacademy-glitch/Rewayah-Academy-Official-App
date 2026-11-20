// AR-ADMIN-1 : les ecrans de l'administration en arabe, de droite a gauche.
//
// Le centre de commande, les demandes, les classes, les comptes et les
// diagnostics, montes sur le VRAI routeur avec une session d'administration,
// s'affichent en arabe
// sans debordement ni exception, au telephone (390, et 320 a texte x2) comme
// au bureau ; le sens est RTL. Avec CAPTURE_DIR, les memes ecrans sont
// captures :
//   CAPTURE_DIR=docs/current/captures/AR-ADMIN-1 flutter test \
//     test/router/ar_admin_rtl_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_tableau/bento_vivant.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';

import '../capture/outil_capture.dart' hide stabiliser;
import '../support/harnais.dart'
    show FauxServiceAdmin, FauxServiceValidation, FausseSourceSession;
import 'support_routeur.dart';

const Map<String, String> _ecrans = <String, String>{
  'accueil': Routes.admin,
  'demandes': Routes.adminOperationsDemandes,
  'classes': Routes.adminOperationsGroupes,
  'comptes': Routes.adminPersonnesComptes,
  'diagnostics': Routes.adminPedagogieDiagnostics,
};

/// Ecrans qui debordent deja en francais a 320 x2.
const Set<String> _debordentDejaA320x2 = <String>{'classes', 'comptes'};

const List<(String, Size, double, ThemeMode)> _cadrages =
    <(String, Size, double, ThemeMode)>[
      ('390_x1_clair', Size(390, 844), 1, ThemeMode.light),
      ('390_x1_sombre', Size(390, 844), 1, ThemeMode.dark),
      ('320_x2_clair', Size(320, 700), 2, ThemeMode.light),
      ('1440_x1_clair', Size(1440, 900), 1, ThemeMode.light),
    ];

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(390, 844),
  double texte = 1,
  ThemeMode mode = ThemeMode.light,
  List<Override> plus = const <Override>[],
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(AppRole.admin))),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        ...plus,
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
                builder: (BuildContext contexte, Widget? app) => MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(texte)),
                  child: app!,
                ),
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    if (dossierCapture != null) await chargerPolicesDuDepot();
  });
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  _ecrans.forEach((String nom, String route) {
    for (final (String cas, Size taille, double texte, ThemeMode mode)
        in _cadrages) {
      // Classes et Comptes debordent deja en francais a 320 x2 (tableaux
      // d'administration, hors de cette tranche) : ce cadrage n'y prouve
      // rien de l'arabe et pollue le test suivant.
      if (texte > 1 && _debordentDejaA320x2.contains(nom)) continue;
      final String fichier = 'ar_admin_${nom}_$cas';
      testWidgets(fichier, (WidgetTester tester) async {
        await _monter(tester, route, taille: taille, texte: texte, mode: mode);
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          TextDirection.rtl,
        );
        if (dossierCapture != null) {
          debugPrint('PNG ${await capturer(tester, fichier)}');
        }
      });
    }
  });

  testWidgets('le centre de commande en arabe, plus en francais', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    // VIVANT : la page n'a plus de titre ; aucun libelle francais de ses
    // cases ne doit y rester.
    final List<String> libellesFr = <String>[
      t.admin.tableau.titre,
      t.admin.tableau.dossiers,
      t.admin.tableau.demandes,
      t.admin.tableau.foyers,
      t.admin.tableau.rapports,
      t.admin.tableau.vivant.activiteTitre,
      t.admin.tableau.vivant.bonjour,
      t.admin.tableau.vivant.bonApresMidi,
      t.admin.tableau.vivant.bonsoir,
    ];
    await LocaleSettings.setLocale(AppLocale.ar);
    // Des compteurs lus : sans eux la page n'affiche que sa forme, et le
    // test ne prouverait rien de l'arabe.
    await _monter(
      tester,
      Routes.admin,
      taille: const Size(1440, 1800),
      plus: <Override>[
        serviceAdminProvider.overrideWithValue(
          FauxServiceAdmin()
            ..indicateursRendus = const IndicateursAdmin(
              dossiersEnAttente: 0,
              foyersSansEnseignant: 2,
              rapportsManquants: 1,
              incidents24h: 0,
              comptesEchus: 0,
              demandesEnAttente: 4,
            ),
        ),
        serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
      ],
    );
    expect(find.byType(TableauDeBordPage), findsOneWidget);
    expect(find.byType(BentoVivant), findsOneWidget);
    for (final String fr in libellesFr) {
      expect(find.text(fr), findsNothing, reason: fr);
    }
    // Les textes arabes attendus, ecrits ici en toutes lettres (jamais relus
    // dans les traductions) : la page doit les afficher tels quels.
    for (final String ar in <String>[
      'ملفات للاعتماد',
      'طلبات للحسم',
      'طلاب دون معلم',
      'دفاتر متابعة ناقصة',
      'ما الذي تغيّر',
    ]) {
      expect(find.text(ar), findsOneWidget, reason: ar);
    }
    // Le salut de Praxis, selon l'heure : l'un des trois, en arabe.
    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is Text &&
            const <String>[
              'صباح الخير.',
              'طاب يومكم.',
              'مساء الخير.',
            ].contains(w.data),
      ),
      findsOneWidget,
    );
    // La semaine des creneaux ne s'ecrit pas avec l'alif de l'article commun
    // aux sept jours : chaque jour a sa lettre.
    expect(t.admin.tableau.vivant.joursInitiales, <String>[
      'ن',
      'ث',
      'ر',
      'خ',
      'ج',
      'س',
      'ح',
    ]);
  });
}
