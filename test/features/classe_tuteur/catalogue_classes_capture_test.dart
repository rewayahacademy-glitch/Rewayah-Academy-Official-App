// Captures de recette du catalogue des classes (lot C, sous-paquet 3), sur le
// VRAI routeur : 390x844 et 1440x900, clair et sombre, tablette 1024x768,
// confirmation, resultats et etats de production.
//
// Saute sans CAPTURE_DIR (la CI ne l'execute jamais). Aucune maquette
// high-fi du catalogue : composition derivee de la carte classe de l'Accueil
// bureau (#1) et des cartes E1 (manifeste section 2), donc pas de planche.
// Donnees : fixtures isolees uniquement, jamais un service reel.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_catalogue_classes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../../capture/outil_capture.dart';
import 'support_classe.dart';

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

const String _chemin = '${Routes.tuteurClassesCatalogue}?eleve=$eleveA2';

Future<void> _monter(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  List<Override>? surcharges,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides:
          surcharges ??
          surchargesClasse(catalogueClasses: FauxCatalogueClasses()),
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
  routeur.go(_chemin);
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, String texte) async {
  final Finder cible = find.text(texte);
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void _telephone(WidgetTester tester) =>
    fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);

void main() {
  final c = t.classe.pageCatalogue;

  group('Capture : catalogue des classes', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('liste 390x844 @3, ${mode.name}', (
        WidgetTester tester,
      ) async {
        _telephone(tester);
        await _monter(tester, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'catalogue_390x844@3_${mode.name}')}',
        );
      });

      testWidgets('liste 1440x900 @1, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, mode: mode);
        debugPrint(
          'PNG ${await capturer(tester, 'catalogue_1440x900@1_${mode.name}')}',
        );
      });

      testWidgets('confirmation 390x844 @3, ${mode.name}', (
        WidgetTester tester,
      ) async {
        _telephone(tester);
        await _monter(tester, mode: mode);
        await _toucher(tester, c.choisir);
        debugPrint(
          'PNG ${await capturer(tester, 'catalogue_confirmation_390x844@3_${mode.name}')}',
        );
      });

      testWidgets('confirmation 1440x900 @1, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await _monter(tester, mode: mode);
        await _toucher(tester, c.choisir);
        debugPrint(
          'PNG ${await capturer(tester, 'catalogue_confirmation_1440x900@1_${mode.name}')}',
        );
      });

      testWidgets('production 390x844 @3, ${mode.name}', (
        WidgetTester tester,
      ) async {
        _telephone(tester);
        await _monter(tester, mode: mode, surcharges: surchargesClasse());
        debugPrint(
          'PNG ${await capturer(tester, 'catalogue_390x844@3_production_${mode.name}')}',
        );
      });
    }

    testWidgets('liste 1024x768 @1, clair', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1024, 768), 1);
      await _monter(tester);
      debugPrint('PNG ${await capturer(tester, 'catalogue_1024x768@1_light')}');
    });

    testWidgets('production 1440x900 @1, clair', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monter(tester, surcharges: surchargesClasse());
      debugPrint(
        'PNG ${await capturer(tester, 'catalogue_1440x900@1_production_light')}',
      );
    });

    for (final (StatutInscription statut, String nom)
        in <(StatutInscription, String)>[
          (StatutInscription.inscrit, 'inscrit'),
          (StatutInscription.enAttenteValidation, 'validation'),
          (StatutInscription.listeAttente, 'liste_attente'),
          (StatutInscription.refuse, 'refuse'),
        ]) {
      testWidgets('resultat $nom 390x844 @3, clair', (
        WidgetTester tester,
      ) async {
        _telephone(tester);
        await _monter(
          tester,
          surcharges: surchargesClasse(
            catalogueClasses: FauxCatalogueClasses(statut: statut),
          ),
        );
        final bool attente = statut == StatutInscription.listeAttente;
        await _toucher(tester, attente ? c.rejoindreAttente : c.choisir);
        await _toucher(tester, attente ? c.confirmerAttente : c.confirmer);
        debugPrint(
          'PNG ${await capturer(tester, 'catalogue_resultat_${nom}_390x844@3_light')}',
        );
      });
    }

    testWidgets('reponse perdue 390x844 @3, clair', (
      WidgetTester tester,
    ) async {
      _telephone(tester);
      await _monter(
        tester,
        surcharges: surchargesClasse(
          catalogueClasses: FauxCatalogueClasses()
            ..erreurInscription = StateError('reponse fictive perdue'),
        ),
      );
      await _toucher(tester, c.choisir);
      await _toucher(tester, c.confirmer);
      debugPrint(
        'PNG ${await capturer(tester, 'catalogue_confirmation_390x844@3_reponse_perdue')}',
      );
    });

    testWidgets('vide 390x844 @3, clair', (WidgetTester tester) async {
      _telephone(tester);
      await _monter(
        tester,
        surcharges: surchargesClasse(
          catalogueClasses: FauxCatalogueClasses(classes: <ClasseOuverte>[]),
        ),
      );
      debugPrint('PNG ${await capturer(tester, 'catalogue_390x844@3_vide')}');
    });

    testWidgets('echec 390x844 @3, clair', (WidgetTester tester) async {
      _telephone(tester);
      await _monter(
        tester,
        surcharges: surchargesClasse(
          catalogueClasses: FauxCatalogueClasses()
            ..erreurLecture = StateError('lecture fictive en echec'),
        ),
      );
      debugPrint('PNG ${await capturer(tester, 'catalogue_390x844@3_echec')}');
    });

    testWidgets('hors ligne 390x844 @3, clair', (WidgetTester tester) async {
      _telephone(tester);
      await _monter(
        tester,
        surcharges: surchargesClasse(
          catalogueClasses: FauxCatalogueClasses(),
          horsLigne: true,
        ),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'catalogue_390x844@3_hors_ligne')}',
      );
    });
  });
}
