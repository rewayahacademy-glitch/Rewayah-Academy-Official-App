// EA-5c : les captures des ecrans corriges de « Ma famille » du titulaire
// adulte (E5, E6). Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B) ni avec `captures_ea5_test.dart` (matrice de l'etat par defaut).
//
// Chaque capture passe par la VRAIE route /demo/adulte (`adresseDemoAdulte`)
// sous un GoRouter, comme `captures_ea5_test.dart` : 390x844, 768x1024 et
// 1440x900, clair et sombre, plus le texte a 200 % en 390, pour les ecrans
// que EA-5c a corriges : le refus de validation avec « Faire une nouvelle
// demande » (E5, EA-BR-18), la nouvelle demande qu'il relance, « A propos du
// forfait famille » (E6) et « Creer mon profil eleve » vers la page
// indisponible, aux textes de l'adulte (E6, EA-BR-19, revue EA-5c).
//
// Plus, hors demonstration, Ma famille sur la VRAIE coquille du tuteur (vrai
// routeur, `/tuteur/foyer`) en 1440 et 1920, clair et sombre, la place
// adulte surchargee comme le ferait le serveur (EA-BR-14) : la preuve qu'il
// n'y a pas de bande claire en haut de la page sur bureau (releve EA-1b).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show identiteTitulaireProvider;
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';

/// Ma famille sur le VRAI routeur et la VRAIE coquille du tuteur : aucune
/// ligne de retour de la demonstration au-dessus de la page.
Future<void> _capturerCoquilleReelle(
  WidgetTester tester,
  String fichier,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  late GoRouter routeur;
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = FoyersFictifs.foyerA;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        identiteTitulaireProvider.overrideWith(
          (Ref _) async => DonneesAdulteDemo.identite(
            GenreTitulaireDemo.homme,
            VueDemoAdulte.titulaire,
          ),
        ),
        foyerTitulaireProvider.overrideWith(
          (Ref _) async => DonneesAdulteDemo.foyerTitulaire(
            EtatDemoAdulte.titulaireSansConjoint,
            GenreTitulaireDemo.homme,
          ),
        ),
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
  routeur.go(Routes.tuteurFoyer);
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  // La vue grandit de ce qui reste a defiler, jusqu'a ce que plus rien ne
  // defile : la page entiere tient dans le PNG (meme methode que EA-5).
  for (int i = 0; i < 4; i++) {
    double reste = 0;
    for (final ScrollableState s in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      if (s.position.axis == Axis.vertical &&
          s.position.maxScrollExtent > reste) {
        reste = s.position.maxScrollExtent;
      }
    }
    if (reste <= 0) break;
    fixerVueCapture(
      tester,
      Size(taille.width, tester.view.physicalSize.height + reste),
      1,
    );
    await stabiliser(tester);
  }
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : EA-5c', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Les quatre ecrans corriges par EA-5c, chacun sur la matrice complete.
    final List<(String nom, String adresse)> ecrans = <(String, String)>[
      (
        'validation_refusee',
        adresseDemoAdulte(
          EcranDemoAdulte.maFamille,
          etat: EtatDemoAdulte.validationRefusee,
        ),
      ),
      (
        'nouvelle_demande',
        adresseDemoAdulte(
          EcranDemoAdulte.inviterConjoint,
          etat: EtatDemoAdulte.validationRefusee,
        ),
      ),
      ('a_propos_forfait', adresseDemoAdulte(EcranDemoAdulte.aProposForfait)),
      ('profil_non_cree', adresseDemoAdulte(EcranDemoAdulte.profilNonCree)),
      ('creer_mon_profil', adresseDemoAdulte(EcranDemoAdulte.creerMonProfil)),
    ];

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('1440', const Size(1440, 900)),
        ('1920', const Size(1920, 1080)),
      ]) {
        final String fichier = 'ea5c_coquille_reelle_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturerCoquilleReelle(tester, fichier, taille, mode: mode);
        });
      }
    }

    for (final (String nom, String adresse) in ecrans) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('768', const Size(768, 1024)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'ea5c_${nom}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(tester, fichier, adresse, taille, mode: mode);
          });
        }
      }
      final String fichier200 = 'ea5c_${nom}_390_light_200pc';
      testWidgets(fichier200, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier200,
          adresse,
          const Size(390, 844),
          echelle: 2,
        );
      });
    }
  });
}
