// RECH-2 : captures de l'ecran de recherche reel (vrai routeur, vraies
// polices, vrai theme) sur le port de demonstration, aux formats de la spec
// RECH-03 §10.3 : 390, 768, 1440, 320 texte x2, clair, sombre, arabe RTL,
// Interface guidee, et les etats de la planche IMG-RECH-06.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Sortie de preuve : docs/current/captures/RECH-2/.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/moteur_recherche_demo.dart';
import 'package:rewayah_academy/core/recherche/moteurs_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;

import '../router/support_routeur.dart' show sessionActive, surchargesRouteur;
import '../support/harnais.dart';
import 'outil_capture.dart';

Future<GoRouter> _monter(
  WidgetTester tester, {
  required Size taille,
  AppRole role = AppRole.guardian,
  InterfaceMode mode = InterfaceMode.standard,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  ThemeMode theme = ThemeMode.light,
  List<MoteurRechercheDomaine>? moteurs,
  bool horsLigne = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(role, mode: mode)),
        ),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        moteursRechercheProvider.overrideWithValue(
          moteurs ?? moteursDemoRecherche(),
        ),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(mode, Brightness.light),
                darkTheme: AppTheme.pour(mode, Brightness.dark),
                themeMode: theme,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
                builder: (BuildContext contexte, Widget? child) =>
                    Directionality(
                      textDirection: direction,
                      child: MediaQuery(
                        data: MediaQuery.of(contexte)
                            .copyWith(textScaler: TextScaler.linear(echelle)),
                        child: RepereDemonstration(child: child),
                      ),
                    ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.recherche);
  await stabiliser(tester);
  return routeur;
}

Future<void> _saisir(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await stabiliser(tester);
}

typedef _Cas = (
  String nom,
  Size taille,
  AppRole role,
  InterfaceMode mode,
  double echelle,
  TextDirection direction,
  ThemeMode theme,
  String requete,
);

const List<_Cas> _cas = <_Cas>[
  (
    'famille_390_clair',
    Size(390, 844),
    AppRole.guardian,
    InterfaceMode.standard,
    1,
    TextDirection.ltr,
    ThemeMode.light,
    'fatiha',
  ),
  (
    'famille_390_sombre',
    Size(390, 844),
    AppRole.guardian,
    InterfaceMode.standard,
    1,
    TextDirection.ltr,
    ThemeMode.dark,
    'fatiha',
  ),
  (
    'guidee_390_clair',
    Size(390, 844),
    AppRole.student,
    InterfaceMode.enfant,
    1,
    TextDirection.ltr,
    ThemeMode.light,
    'fatiha',
  ),
  (
    'famille_768_clair',
    Size(768, 1024),
    AppRole.guardian,
    InterfaceMode.standard,
    1,
    TextDirection.ltr,
    ThemeMode.light,
    'fatiha',
  ),
  (
    'enseignant_1440_sombre',
    Size(1440, 900),
    AppRole.teacher,
    InterfaceMode.standard,
    1,
    TextDirection.ltr,
    ThemeMode.dark,
    'fatiha',
  ),
  (
    'admin_1440_clair',
    Size(1440, 900),
    AppRole.admin,
    InterfaceMode.standard,
    1,
    TextDirection.ltr,
    ThemeMode.light,
    'fatiha',
  ),
  (
    'famille_320x2_clair',
    Size(320, 1800),
    AppRole.guardian,
    InterfaceMode.standard,
    2,
    TextDirection.ltr,
    ThemeMode.light,
    'fatiha',
  ),
  (
    'famille_320x2_ar_rtl',
    Size(320, 1800),
    AppRole.guardian,
    InterfaceMode.standard,
    2,
    TextDirection.rtl,
    ThemeMode.light,
    'fatiha',
  ),
  (
    'famille_390_ar_rtl',
    Size(390, 844),
    AppRole.guardian,
    InterfaceMode.standard,
    1,
    TextDirection.rtl,
    ThemeMode.light,
    'fatiha',
  ),
  (
    'enseignant_1440_ar_rtl',
    Size(1440, 900),
    AppRole.teacher,
    InterfaceMode.standard,
    1,
    TextDirection.rtl,
    ThemeMode.light,
    'fatiha',
  ),
];

void main() {
  for (final bool arabe in <bool>[false, true]) {
    group(
      'Capture : RECH-2, resultats ${arabe ? 'arabe' : 'francais'}',
      skip: sautSansCapture,
      () {
        setUpAll(chargerPolicesDuDepot);
        setUp(masquerRubanDebug);
        setUp(
          () => LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
        );
        tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

        for (final _Cas cas in _cas.where(
          (_Cas c) => (c.$6 == TextDirection.rtl) == arabe,
        )) {
          testWidgets(cas.$1, (WidgetTester tester) async {
            await _monter(
              tester,
              taille: cas.$2,
              role: cas.$3,
              mode: cas.$4,
              echelle: cas.$5,
              direction: cas.$6,
              theme: cas.$7,
            );
            await _saisir(
              tester,
              cas.$3 == AppRole.teacher && cas.$1.contains('1440')
                  ? 'mariam'
                  : cas.$8,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, 'rech2_${cas.$1}')}');
          });
        }
      },
    );
  }

  group(
    'Capture : RECH-2, etats (planche IMG-RECH-06)',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      setUp(masquerRubanDebug);

      Future<void> etat(
        WidgetTester tester,
        String nom, {
        String requete = 'fatiha',
        ComportementDemo? comportement,
        bool horsLigne = false,
        bool seulementSupports = false,
      }) async {
        final List<MoteurRechercheDomaine> moteurs = moteursDemoRecherche();
        if (comportement != null) {
          for (final MoteurRechercheDomaine m in moteurs) {
            (m as MoteurRechercheDemo).comportement = comportement;
          }
        }
        await _monter(
          tester,
          taille: const Size(390, 844),
          moteurs: moteurs,
          horsLigne: horsLigne,
        );
        if (nom != 'initial') await _saisir(tester, requete);
        if (comportement == ComportementDemo.silencieux) {
          await tester.pump(const Duration(seconds: 3));
          await stabiliser(tester);
        }
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'rech2_etat_$nom')}');
      }

      testWidgets('initial', (WidgetTester t) => etat(t, 'initial'));
      testWidgets(
        'courte',
        (WidgetTester t) => etat(t, 'courte', requete: 'al'),
      );
      testWidgets(
        'vide',
        (WidgetTester t) => etat(t, 'vide', requete: 'zzzzzz'),
      );
      testWidgets('domaine_en_panne', (WidgetTester t) async {
        final List<MoteurRechercheDomaine> moteurs = moteursDemoRecherche();
        (moteurs[1] as MoteurRechercheDemo).comportement =
            ComportementDemo.indisponible;
        await _monter(t, taille: const Size(390, 844), moteurs: moteurs);
        await _saisir(t, 'fatiha');
        debugPrint('PNG ${await capturer(t, 'rech2_etat_domaine_en_panne')}');
      });
      testWidgets(
        'erreur',
        (WidgetTester t) =>
            etat(t, 'erreur', comportement: ComportementDemo.indisponible),
      );
      testWidgets(
        'delai',
        (WidgetTester t) =>
            etat(t, 'delai', comportement: ComportementDemo.silencieux),
      );
      testWidgets(
        'hors_ligne',
        (WidgetTester t) => etat(t, 'hors_ligne', horsLigne: true),
      );
      testWidgets(
        'session_expiree',
        (WidgetTester t) => etat(
          t,
          'session_expiree',
          comportement: ComportementDemo.sessionExpiree,
        ),
      );
      testWidgets('non_raccorde', (WidgetTester t) async {
        await _monter(
          t,
          taille: const Size(390, 844),
          moteurs: const <MoteurRechercheDomaine>[],
        );
        await _saisir(t, 'fatiha');
        debugPrint('PNG ${await capturer(t, 'rech2_etat_non_raccorde')}');
      });
    },
  );
}
