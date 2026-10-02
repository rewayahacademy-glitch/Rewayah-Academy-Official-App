// EA-5 : les captures de « Ma famille » du titulaire adulte. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Fichier propre a l'agent :
// ne pas confondre avec `captures_ea_test.dart` (poste B).
//
// Chaque capture passe par la VRAIE route /demo/adulte (`adresseDemoAdulte`)
// sous un GoRouter, comme `captures_ea4_test.dart` : 390x844, 768x1024 et
// 1440x900, clair et sombre, plus le texte a 200 % en 390, et les variantes
// de la place adulte (titulaire femme, adulte seul, delai) et « Paiements du
// foyer ».
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool pleineHauteur = false,
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
  if (pleineHauteur) {
    // La vue grandit de ce qui reste a defiler, jusqu'a ce que plus rien ne
    // defile : la page entiere tient dans le PNG.
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
  }
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : EA-5', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea5_ma_famille_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresseDemoAdulte(EcranDemoAdulte.maFamille),
            taille,
            mode: mode,
            pleineHauteur: true,
          );
        });
      }
    }

    // Le texte a 200 % sur l'etat par defaut (conjointActif : carte du
    // titulaire, place occupee, enfants, boutons).
    testWidgets('ea5_ma_famille_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea5_ma_famille_390_light_200pc',
        adresseDemoAdulte(EcranDemoAdulte.maFamille),
        const Size(390, 844),
        echelle: 2,
        pleineHauteur: true,
      );
    });

    // Titulaire femme (« Ajouter un conjoint », F3), adulte seul (« Ajouter
    // ma famille », jamais le Foyer, F6), et un delai en cours (F17).
    for (final (String nom, String adresse) in <(String, String)>[
      (
        'titulaire_femme',
        adresseDemoAdulte(
          EcranDemoAdulte.maFamille,
          genre: GenreTitulaireDemo.femme,
        ),
      ),
      (
        'adulte_seul',
        adresseDemoAdulte(
          EcranDemoAdulte.maFamille,
          etat: EtatDemoAdulte.adulteSeul,
        ),
      ),
      (
        'delai',
        adresseDemoAdulte(
          EcranDemoAdulte.maFamille,
          etat: EtatDemoAdulte.delai60,
        ),
      ),
      // EA-5c : refus de validation (E5), « A propos du forfait famille »
      // (E6) et la creation de demonstration qui dit que rien n'est cree.
      (
        'validation_refusee',
        adresseDemoAdulte(
          EcranDemoAdulte.maFamille,
          etat: EtatDemoAdulte.validationRefusee,
        ),
      ),
      ('a_propos_forfait', adresseDemoAdulte(EcranDemoAdulte.aProposForfait)),
      ('profil_non_cree', adresseDemoAdulte(EcranDemoAdulte.profilNonCree)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea5_ma_famille_390_${mode.name}_$nom';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresse,
            const Size(390, 844),
            mode: mode,
            pleineHauteur: true,
          );
        });
      }
    }

    // Les chemins de Ma famille (revue d'EA-5) : les vraies pages du tuteur
    // dans sa coquille, et la place adulte provisoire.
    for (final (String nom, String adresse) in <(String, String)>[
      ('ajouter_profil', adresseDemoAdulte(EcranDemoAdulte.ajouterProfil)),
      ('fiche_enfant', adresseDemoAdulte(EcranDemoAdulte.ficheEleve)),
      ('appareils', adresseDemoAdulte(EcranDemoAdulte.appareils)),
      (
        'place_adulte',
        adresseDemoAdulte(
          EcranDemoAdulte.placeAdulte,
          etat: EtatDemoAdulte.titulaireSansConjoint,
        ),
      ),
    ]) {
      final String fichier = 'ea5_${nom}_390_light';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(tester, fichier, adresse, const Size(390, 844));
      });
    }

    // « Paiements du foyer », ouverts depuis Ma famille : la vraie page.
    testWidgets('ea5_paiements_foyer_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea5_paiements_foyer_390_light',
        adresseDemoAdulte(EcranDemoAdulte.paiementsFoyer),
        const Size(390, 844),
      );
    });
  });
}
