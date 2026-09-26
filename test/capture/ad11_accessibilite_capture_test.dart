// Captures de preuve AD-11 (accessibilite) sur la VRAIE coque admin et le
// vrai routeur, en demonstration (`?demo=admin`). Modele :
// `ad10_parcours_capture_test.dart`. Deux configurations : 320x640 (reflow a
// 400 %) et 390x844 avec le texte a 200 %, en clair et en sombre. Etats :
// coque, file, revue, visionneuse, refus (02D), validation (02E), politique.
//
// Une capture de preuve montre aussi un defaut : les erreurs de rendu
// (debordements) sont relevees dans le journal (`DEFAUT ...`) au lieu de
// faire echouer le test ; un parcours bloque s'arrete et le dit (`ARRET ...`)
// sans empecher les autres cas. La politique est ouverte par sa route : son onglet deborde de la
// vue a 320 (reste AD-11 en attente de decision, voir admin_ad11_test.dart).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// ad11_<etat>_<config>_<mode>.png.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

late GoRouter _routeur;

Future<void> _monter(WidgetTester tester, ThemeMode mode) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surchargesDemoAdmin(
        environnement: 'staging',
        etat: EtatRevueDemo.initial(maintenant: DateTime.utc(2026, 9, 26, 12)),
      ),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              _routeur = ref.read(routeurProvider);
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
                routerConfig: _routeur,
                builder: (BuildContext context, Widget? child) =>
                    RepereDemonstration(child: child),
              );
            },
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  _routeur.go(Routes.admin);
  await _stabiliser(tester);
}

/// Personnes depuis la coque : rail, barre laterale ou tiroir mobile.
Future<void> _personnes(WidgetTester tester) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final Finder rail = find.byKey(AdminShell.railKey);
  const AdminDomaine domaine = AdminDomaine.personnes;
  if (rail.evaluate().isNotEmpty) {
    await tester.tap(
      find
          .descendant(
            of: rail,
            matching: find.bySemanticsLabel(RegExp(domaine.libelle)),
          )
          .first,
    );
  } else {
    final bool mobile = barre.evaluate().isEmpty;
    if (mobile) {
      await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
      await _stabiliser(tester);
    }
    await tester.tap(
      find.descendant(
        of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
        matching: find.text(domaine.libelle),
      ),
    );
  }
  await _stabiliser(tester);
}

Finder _ligne(String prenom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$prenom"));

Future<void> _ouvrirOmar(WidgetTester tester) async {
  await _personnes(tester);
  await tester.ensureVisible(_ligne('Omar'));
  await _stabiliser(tester);
  await tester.tap(_ligne('Omar'), warnIfMissed: false);
  await _stabiliser(tester);
}

Future<void> _vers(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await _stabiliser(tester);
}

const List<(Size, double, double, String)> _configs =
    <(Size, double, double, String)>[
      (Size(320, 640), 1, 1, '320x640@1'),
      (Size(390, 844), 3, 2, '390x844@3_200pc'),
    ];

void main() {
  group('Capture : AD-11 accessibilite', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, double densite, double echelle, String nom)
          in _configs) {
        String fichier(String etat) => 'ad11_${etat}_${nom}_${mode.name}';

        /// Monte, joue [parcours] (qui capture), releve sans echouer les
        /// erreurs de rendu : la capture est la preuve, defaut compris.
        void cas(
          String titre,
          Future<void> Function(WidgetTester, Future<void> Function(String))
          parcours,
        ) {
          testWidgets('$nom, $titre, ${mode.name}', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, densite);
            tester.platformDispatcher.textScaleFactorTestValue = echelle;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final void Function(FlutterErrorDetails)? avant =
                FlutterError.onError;
            final List<String> defauts = <String>[];
            FlutterError.onError = (FlutterErrorDetails d) =>
                defauts.add(d.exceptionAsString().split('\n').first);
            Future<void> capture(String etat) async {
              debugPrint('PNG ${await capturer(tester, fichier(etat))}');
            }

            try {
              await _monter(tester, mode);
              await parcours(tester, capture);
            } catch (e) {
              debugPrint('ARRET ${fichier(titre)} : $e');
            } finally {
              FlutterError.onError = avant;
            }
            for (final String d in defauts.toSet()) {
              debugPrint('DEFAUT ${fichier(titre)} : $d');
            }
          });
        }

        cas('coque, file, revue, visionneuse', (
          WidgetTester tester,
          Future<void> Function(String) capture,
        ) async {
          await capture('1_coque');
          await _personnes(tester);
          await capture('2_file');
          await tester.ensureVisible(_ligne('Omar'));
          await _stabiliser(tester);
          await tester.tap(_ligne('Omar'), warnIfMissed: false);
          await _stabiliser(tester);
          await capture('3_revue');
          final Finder voir = find.text(t.dossiers.revue.voirPiece).first;
          await _vers(tester, voir);
          await tester.tap(voir, warnIfMissed: false);
          await _stabiliser(tester);
          expect(find.byType(VisionneusePiece), findsOneWidget);
          await capture('4_visionneuse');
        });

        cas('refus', (
          WidgetTester tester,
          Future<void> Function(String) capture,
        ) async {
          await _ouvrirOmar(tester);
          await _vers(tester, find.text(t.dossiers.refuser).first);
          await tester.tap(find.text(t.dossiers.refuser).first);
          await _stabiliser(tester);
          await capture('5_refus');
          await tester.tap(find.text(t.dossiers.refuser).last);
          await _stabiliser(tester);
          await capture('5_refus_erreur');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await _stabiliser(tester);
        });

        cas('validation', (
          WidgetTester tester,
          Future<void> Function(String) capture,
        ) async {
          await _ouvrirOmar(tester);
          for (final String point in <String>[
            t.dossiers.pointLisible,
            t.dossiers.pointNom,
            t.dossiers.pointValidite,
          ]) {
            await _vers(tester, find.text(point).first);
            await tester.tap(find.text(point).first, warnIfMissed: false);
            await _stabiliser(tester);
          }
          await _vers(tester, find.text(t.dossiers.approuver).first);
          await tester.tap(find.text(t.dossiers.approuver).first);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.validation.titre), findsOneWidget);
          await capture('6_validation');
        });

        cas('politique', (
          WidgetTester tester,
          Future<void> Function(String) capture,
        ) async {
          _routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
          await _stabiliser(tester);
          await _stabiliser(tester);
          await capture('7_politique');
        });
      }
    }
  });
}
