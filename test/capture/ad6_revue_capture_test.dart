// Captures de recette AD-6 (revue ADM-02B), sur la VRAIE coque admin et le
// vrai routeur, en demonstration (`?demo=admin`). Modele : `ad5_dossiers_capture_test.dart`.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees :
// fixtures synthetiques de la demonstration uniquement (RepereDemonstration
// visible sur chaque capture).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/etat_file_dossiers.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Un port qui ne repond jamais : le detail reste sur son squelette.
Future<DossierPourRevue> _jamais() => Completer<DossierPourRevue>().future;

Future<void> _monter(
  WidgetTester tester,
  Size taille,
  ThemeMode mode, {
  List<Override> plus = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        ...plus,
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: RewayahApp(
            themeMode: mode,
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(Routes.admin);
  await _stabiliser(tester);
}

/// Personnes depuis la coque : tiroir sur mobile, barre laterale sur bureau.
Future<void> _ouvrirDossiers(WidgetTester tester) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final bool mobile = barre.evaluate().isEmpty;
  if (mobile) {
    await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
    await _stabiliser(tester);
  }
  await tester.tap(
    find.descendant(
      of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
}

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

Future<void> _ouvrir(WidgetTester tester, String prenom) async {
  await _ouvrirDossiers(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
}

Future<void> _taperTexte(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle));
  await _stabiliser(tester);
  await tester.tap(find.text(libelle));
  await _stabiliser(tester);
}

const List<String> _points = <String>[
  'La pièce est lisible',
  'Le nom correspond à celui du compte',
  "La pièce n'est pas expirée",
];

const List<(Size, String)> _tailles = <(Size, String)>[
  (Size(390, 844), '390x844@3'),
  (Size(768, 1024), '768x1024@1'),
  (Size(1440, 900), '1440x900@1'),
];

double _densite(String nom) => nom.contains('@3') ? 3 : 1;

void main() {
  group('Capture : AD-6 revue du dossier', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      // 1. Nominal (Omar Haddad) : vérifications incomplètes, 390/768/1440.
      for (final (Size taille, String nom) in _tailles) {
        testWidgets('$nom, nominal Omar, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrir(tester, 'Omar');
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_nominal_${nom}_${mode.name}')}',
          );
          if (nom.startsWith('390')) {
            await tester.dragUntilVisible(
              find.text('Valider le dossier'),
              find.byType(Scrollable).first,
              const Offset(0, -200),
            );
            await _stabiliser(tester);
            debugPrint(
              'PNG ${await capturer(tester, 'ad6_nominal_actions_${nom}_${mode.name}')}',
            );
          }
        });
      }

      // 2. Trois cases cochées, Valider actif : 390 et 1440.
      for (final (Size taille, String nom) in _tailles.where(
        (r) => r.$2 != '768x1024@1',
      )) {
        testWidgets('$nom, pret (3 cases), ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrir(tester, 'Omar');
          for (final String p in _points) {
            await _taperTexte(tester, p);
          }
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_pret_${nom}_${mode.name}')}',
          );
        });
      }

      // 3. Chacun des 8 etats, a 390x844@3 et 1440x900@1.
      for (final (Size taille, String nom) in _tailles.where(
        (r) => r.$2 != '768x1024@1',
      )) {
        testWidgets('$nom, etat chargement, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(
            tester,
            taille,
            mode,
            plus: <Override>[
              dossierPourRevueProvider.overrideWith(
                (Ref ref, String id) => _jamais(),
              ),
            ],
          );
          await _ouvrirDossiers(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_chargement_${nom}_${mode.name}')}',
          );
        });

        testWidgets('$nom, etat hors ligne, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(
            tester,
            taille,
            mode,
            plus: <Override>[
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(true),
              ),
            ],
          );
          await _ouvrirDossiers(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_hors_ligne_${nom}_${mode.name}')}',
          );
        });

        testWidgets('$nom, etat acces perdu, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(
            tester,
            taille,
            mode,
            plus: <Override>[
              dossierPourRevueProvider.overrideWith(
                (Ref ref, String id) =>
                    throw const ErreurRevueDossier(CodeErreurRevue.interdit),
              ),
            ],
          );
          await _ouvrirDossiers(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_acces_perdu_${nom}_${mode.name}')}',
          );
        });

        testWidgets('$nom, etat verifications incompletes, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrir(tester, 'Omar');
          const String lien = 'Terminez les vérifications requises.';
          await _taperTexte(tester, lien);
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_verifications_incompletes_${nom}_${mode.name}')}',
          );
        });

        testWidgets('$nom, etat accord manquant, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrir(tester, 'Sofia');
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_accord_manquant_${nom}_${mode.name}')}',
          );
        });

        testWidgets('$nom, etat decision indisponible, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrir(tester, 'Nabil');
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_decision_indisponible_${nom}_${mode.name}')}',
          );
        });

        testWidgets('$nom, etat dossier modifie, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrir(tester, 'Lina');
          for (final String p in _points) {
            await _taperTexte(tester, p);
          }
          await _taperTexte(tester, 'Valider le dossier');
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_dossier_modifie_${nom}_${mode.name}')}',
          );
        });

        testWidgets('$nom, etat refus non autorise, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, taille, mode);
          await _ouvrir(tester, 'Adam');
          debugPrint(
            'PNG ${await capturer(tester, 'ad6_refus_non_autorise_${nom}_${mode.name}')}',
          );
        });
      }

      // 4. Controle des actions a 200 % (390 seulement) : rien de coupe.
      testWidgets('390, actions a 200 %, ${mode.name}', (
        WidgetTester tester,
      ) async {
        const Size taille = Size(390, 844);
        fixerVueCapture(tester, taille, 3);
        await _monter(tester, taille, mode);
        await _ouvrir(tester, 'Omar');
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _stabiliser(tester);
        await tester.dragUntilVisible(
          find.text('Valider le dossier'),
          find.byType(Scrollable).first,
          const Offset(0, -300),
        );
        await _stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'ad6_actions_390x844@3_texte200_${mode.name}')}',
        );
      });
    }
  });
}
