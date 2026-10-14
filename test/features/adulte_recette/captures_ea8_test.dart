// EA-8 : les captures de la sortie du forfait famille et du delai, depuis la
// VRAIE route /demo/adulte (`adresseDemoAdulte`), comme `captures_ea7_test.dart` :
// 390x844, 768x1024 et 1440x900, clair et sombre, plus le texte a 200 % en
// 390, sur la place occupee (titulaire), sa confirmation destructive, son
// resultat sans coche ni « succes », le delai (planche 3.3) et sa feuille
// « Pourquoi cette attente ? », puis la page Forfait famille du second
// adulte, sa confirmation et son resultat. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).
//
// Fichier propre a l'agent : ne pas confondre avec `captures_ea_test.dart`
// (poste B, ne pas modifier) ni avec les fichiers des agents precedents
// (`captures_ea2..ea7_test.dart`).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  Future<void> Function(WidgetTester tester)? avant,
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
  if (avant != null) {
    await avant(tester);
    await stabiliser(tester);
  }
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Adresse de la place du titulaire pour [etat] (occupee par defaut).
String _adressePlace({EtatDemoAdulte etat = EtatDemoAdulte.conjointActif}) =>
    adresseDemoAdulte(EcranDemoAdulte.placeAdulte, etat: etat);

/// Adresse de la page Forfait famille du second adulte.
String get _adresseForfait => adresseDemoAdulte(
  EcranDemoAdulte.forfaitFamille,
  vue: VueDemoAdulte.secondAdulte,
);

Future<void> _ouvrirConfirmRetirer(WidgetTester tester) async {
  await tester.tap(find.byKey(PlaceConjointPage.retirerKey));
  await tester.pumpAndSettle();
}

Future<void> _confirmerRetrait(WidgetTester tester) async {
  await _ouvrirConfirmRetirer(tester);
  await tester.tap(
    find.widgetWithText(ActionPrincipale, t.adulte.sortie.retirerElle).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _ouvrirConfirmQuitter(WidgetTester tester) async {
  await tester.tap(find.byKey(ForfaitFamillePage.quitterKey));
  await tester.pumpAndSettle();
}

Future<void> _confirmerDepart(WidgetTester tester) async {
  await _ouvrirConfirmQuitter(tester);
  await tester.tap(
    find
        .widgetWithText(ActionPrincipale, t.adulte.sortie.quitterConfirmer)
        .last,
  );
  await tester.pumpAndSettle();
}

Future<void> _ouvrirPourquoi(WidgetTester tester) async {
  await tester.tap(find.byKey(DelaiPlacePage.pourquoiKey));
  await tester.pumpAndSettle();
}

void main() {
  group('Capture : EA-8', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // La place occupee (titulaire) : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea8_place_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(tester, fichier, _adressePlace(), taille, mode: mode);
        });
      }
    }

    // Le texte a 200 % sur la place occupee, en 390.
    testWidgets('ea8_place_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea8_place_390_light_200pc',
        _adressePlace(),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // La confirmation destructive (« Retirer ma conjointe ? », doc section
    // 19) : 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea8_confirmation_retrait_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea8_confirmation_retrait_390_${mode.name}',
          _adressePlace(),
          const Size(390, 844),
          mode: mode,
          avant: _ouvrirConfirmRetirer,
        );
      });
    }

    // La confirmation a 1440 (boite de dialogue, meme ordre).
    testWidgets('ea8_confirmation_retrait_1440_light', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea8_confirmation_retrait_1440_light',
        _adressePlace(),
        const Size(1440, 900),
        avant: _ouvrirConfirmRetirer,
      );
    });

    // Le resultat, sans coche ni « succes » (E7) : 390/768/1440, clair et
    // sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea8_resultat_titulaire_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adressePlace(),
            taille,
            mode: mode,
            avant: _confirmerRetrait,
          );
        });
      }
    }

    // Le texte a 200 % sur le resultat, en 390.
    testWidgets('ea8_resultat_titulaire_390_light_200pc', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea8_resultat_titulaire_390_light_200pc',
        _adressePlace(),
        const Size(390, 844),
        echelle: 2,
        avant: _confirmerRetrait,
      );
    });

    // Le delai (planche 3.3) : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea8_delai_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            _adressePlace(etat: EtatDemoAdulte.delai60),
            taille,
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % sur le delai, en 390.
    testWidgets('ea8_delai_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea8_delai_390_light_200pc',
        _adressePlace(etat: EtatDemoAdulte.delai60),
        const Size(390, 844),
        echelle: 2,
      );
    });

    // « Pourquoi cette attente ? » (feuille d'une phrase) : 390, clair et
    // sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea8_pourquoi_390_${mode.name}', (WidgetTester tester) async {
        await _capturer(
          tester,
          'ea8_pourquoi_390_${mode.name}',
          _adressePlace(etat: EtatDemoAdulte.delai60),
          const Size(390, 844),
          mode: mode,
          avant: _ouvrirPourquoi,
        );
      });
    }

    // Forfait famille (second adulte) : 390/768/1440, clair et sombre.
    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String fichier = 'ea8_forfait_${l}_${mode.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(tester, fichier, _adresseForfait, taille, mode: mode);
        });
      }
    }

    // Le texte a 200 % sur Forfait famille, en 390.
    testWidgets('ea8_forfait_390_light_200pc', (WidgetTester tester) async {
      await _capturer(
        tester,
        'ea8_forfait_390_light_200pc',
        _adresseForfait,
        const Size(390, 844),
        echelle: 2,
      );
    });

    // La confirmation destructive de Forfait famille (« Quitter le forfait
    // famille ? ») : 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea8_confirmation_depart_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea8_confirmation_depart_390_${mode.name}',
          _adresseForfait,
          const Size(390, 844),
          mode: mode,
          avant: _ouvrirConfirmQuitter,
        );
      });
    }

    // Le resultat du second adulte, sans date (le delai porte sur le
    // titulaire) : 390, clair et sombre.
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ea8_resultat_second_adulte_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'ea8_resultat_second_adulte_390_${mode.name}',
          _adresseForfait,
          const Size(390, 844),
          mode: mode,
          avant: _confirmerDepart,
        );
      });
    }

    // Le texte a 200 % sur le resultat du second adulte, en 390.
    testWidgets('ea8_resultat_second_adulte_390_light_200pc', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea8_resultat_second_adulte_390_light_200pc',
        _adresseForfait,
        const Size(390, 844),
        echelle: 2,
        avant: _confirmerDepart,
      );
    });
  });
}
