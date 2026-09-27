// CT-1b : squelette des captures de la vague Controleur. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Chaque lot CT-2 a CT-11
// ajoute ses ecrans ici ; CT-12 en fait la recette.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import '../../capture/outil_capture.dart';

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(hoteCapture(ecran, themeMode: mode));
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// Heberge [route] sur la VRAIE route de demonstration
/// (`routesDemoControleur`) : la salle (CTR-02) et le compte rendu (CTR-03)
/// lisent le routeur (Quitter, retour), un `home:` nu ne suffit pas.
Future<void> _capturerRoute(
  WidgetTester tester,
  String fichier,
  String route,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  Future<void> Function(WidgetTester tester)? avant,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: route,
    routes: routesDemoControleur('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext contexte) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(contexte).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
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

void main() {
  group('Capture : CT-1b, coquille controleur', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // La VRAIE coquille (4 destinations, C13) sur chaque destination, aux
    // trois largeurs de reference, clair et sombre.
    for (final EcranDemoControleur ecran in EcranDemoControleur.values) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 900)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier =
              'ct1b_coquille_${ecran.name}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              CoquilleControleurDemo(ecran: ecran),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });

  group('Capture : CT-2, CTR-01 Controle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // Les quatre situations de mission, sur la VRAIE coquille.
    for (final EtatDemoControleur etat in EtatDemoControleur.values) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'ct2_controle_${etat.name}_${l}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              CoquilleControleurDemo(
                ecran: EcranDemoControleur.controle,
                etat: etat,
              ),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });

  group(
    'Capture : CT-3, CTR-02 salle et compte rendu',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      // La salle (CTR-02, `SalleControleurDemo(seanceId: 'demo-controle')`) et
      // le compte rendu provisoire (CTR-03), tous deux atteints par la VRAIE
      // route de demonstration `/demo/controleur/salle` et
      // `/demo/controleur/compte-rendu`.
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('768', const Size(768, 1000)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String s = '${l}_${mode.name}';
          testWidgets('ct3_salle_$s', (WidgetTester tester) async {
            await _capturerRoute(
              tester,
              'ct3_salle_$s',
              cheminDemoSalleControleur,
              taille,
              mode: mode,
            );
          });
          testWidgets('ct3_compte_rendu_$s', (WidgetTester tester) async {
            await _capturerRoute(
              tester,
              'ct3_compte_rendu_$s',
              cheminDemoCompteRenduControleur,
              taille,
              mode: mode,
            );
          });
        }
      }
    },
  );

  group('Capture : CT-4, CTR-03 compte rendu', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // Trois etats par la VRAIE route `/demo/controleur/compte-rendu` :
    // initial (faits replies, aucune preselection), « Rien a signaler »
    // choisi (faits deplies, notice, bouton), resultat apres envoi.
    Future<void> choisir(WidgetTester tester) async {
      await tester.tap(find.text(t.controleur.compteRendu.faits));
      await tester.pumpAndSettle();
      final Finder carte = find.byKey(
        CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
      );
      await tester.ensureVisible(carte);
      await tester.tap(carte);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pumpAndSettle();
    }

    Future<void> envoyer(WidgetTester tester) async {
      await choisir(tester);
      await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1000)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String s = '${l}_${mode.name}';
        for (final (String nom, Future<void> Function(WidgetTester)? avant)
            in <(String, Future<void> Function(WidgetTester)?)>[
              ('initial', null),
              ('rien_a_signaler', choisir),
              ('resultat', envoyer),
            ]) {
          testWidgets('ct4_compte_rendu_${nom}_$s', (
            WidgetTester tester,
          ) async {
            await _capturerRoute(
              tester,
              'ct4_compte_rendu_${nom}_$s',
              cheminDemoCompteRenduControleur,
              taille,
              mode: mode,
              avant: avant,
            );
          });
        }
      }
    }
  });
}
