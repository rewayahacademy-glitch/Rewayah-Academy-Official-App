// Captures de recette AD-7 (visionneuse de piece), sur la VRAIE coque admin
// et le vrai routeur, en demonstration (`?demo=admin`). Modele :
// `ad6_revue_capture_test.dart`. Chaque ouverture tape le vrai bouton
// « Voir la piece » de la revue (K-07).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees :
// fixtures synthetiques de la demonstration uniquement (RepereDemonstration
// visible sur chaque capture, piece « Document fictif »).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

late GoRouter _routeur;

Future<void> _monter(WidgetTester tester, Size taille, ThemeMode mode) async {
  // La taille et la densite viennent de `fixerVueCapture` (390 a @3).
  // `MaterialApp.router` sur le vrai routeur plutot que `RewayahApp` : la
  // persistance des preferences appelle `path_provider`, absent sous
  // `runAsync` (meme choix que `ad6_revue_capture_test.dart`).
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[...surchargesDemoAdmin(environnement: 'staging')],
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

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

/// Personnes depuis la coque (tiroir mobile, rail ou barre laterale), la
/// ligne du dossier, puis le VRAI bouton « Voir la piece » (K-07).
Future<void> _voirPiece(WidgetTester tester, String prenom) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final Finder rail = find.byKey(AdminShell.railKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (rail.evaluate().isNotEmpty) {
    await tester.tap(
      find
          .descendant(
            of: rail,
            matching: find.bySemanticsLabel(
              RegExp(AdminDomaine.personnes.libelle),
            ),
          )
          .first,
    );
  } else if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  if (rail.evaluate().isEmpty) {
    await tester.tap(
      find.descendant(
        of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
        matching: find.text(AdminDomaine.personnes.libelle),
      ),
    );
  }
  await _stabiliser(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
  final Finder bouton = find.text(t.dossiers.revue.voirPiece);
  await tester.ensureVisible(bouton);
  await _stabiliser(tester);
  await tester.tap(bouton);
  await _stabiliser(tester);
}

const List<(Size, String)> _tailles = <(Size, String)>[
  (Size(390, 844), '390x844@3'),
  (Size(768, 1024), '768x1024@1'),
  (Size(1440, 900), '1440x900@1'),
];

double _densite(String nom) => nom.contains('@3') ? 3 : 1;

void main() {
  group('Capture : AD-7 visionneuse de piece', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      // 1. Contenu (« Document fictif »), 100 % : 390, 768, 1440.
      for (final (Size taille, String nom) in _tailles) {
        testWidgets('$nom, contenu, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _voirPiece(tester, 'Omar');
          expect(find.byType(VisionneusePiece), findsOneWidget);
          expect(
            find.text(t.dossiers.visionneuse.documentFictif),
            findsOneWidget,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ad7_contenu_${nom}_${mode.name}')}',
          );
        });
      }

      // 2. Zoom a 200 % (4 x Agrandir = 25 x 4 = 100 pts, donc echelle 2.0)
      //    a 390 seulement : verifie la lecture au-dela de 100 %.
      testWidgets('390x844@3, contenu a 200 %, ${mode.name}', (
        WidgetTester tester,
      ) async {
        const Size taille = Size(390, 844);
        fixerVueCapture(tester, taille, 3);
        await _monter(tester, taille, mode);
        await _voirPiece(tester, 'Omar');
        for (int i = 0; i < 4; i++) {
          await tester.tap(
            find.bySemanticsLabel(t.dossiers.visionneuse.agrandir),
          );
          await tester.pump();
        }
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_contenu_200_390x844@3_${mode.name}')}',
        );
      });

      // 3. Lien expire (Karim), puis renouvellement (zoom conserve) : 1440.
      testWidgets('1440x900@1, lien expire puis renouvele, ${mode.name}', (
        WidgetTester tester,
      ) async {
        const Size taille = Size(1440, 900);
        fixerVueCapture(tester, taille, 1);
        await _monter(tester, taille, mode);
        await _voirPiece(tester, 'Karim');
        expect(find.text(t.dossiers.visionneuse.expire), findsOneWidget);
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_expire_1440x900@1_${mode.name}')}',
        );
        await tester.tap(find.text(t.dossiers.visionneuse.recharger));
        await _stabiliser(tester);
        expect(
          find.text(t.dossiers.visionneuse.documentFictif),
          findsOneWidget,
        );
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_expire_renouvele_1440x900@1_${mode.name}')}',
        );
      });

      // 4. Focus visible sur « Voir la piece » apres Echap : 1440.
      testWidgets('1440x900@1, focus apres Echap, ${mode.name}', (
        WidgetTester tester,
      ) async {
        const Size taille = Size(1440, 900);
        fixerVueCapture(tester, taille, 1);
        await _monter(tester, taille, mode);
        await _voirPiece(tester, 'Omar');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _stabiliser(tester);
        expect(find.byType(VisionneusePiece), findsNothing);
        debugPrint(
          'PNG ${await capturer(tester, 'ad7_focus_echap_1440x900@1_${mode.name}')}',
        );
      });
    }
  });
}
