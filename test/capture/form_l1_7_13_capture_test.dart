// Captures de recette de FORM-L1-7-13 : motifs en puces (cloture d'une classe)
// et valeurs proposees d'un reglage entier
// (L13). 390x844 et 1440x900, clair et sombre ; 320 a texte x2, clair et
// sombre (K-61). Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/config_edition.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../features/support_form_l2.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

enum _Ecran { cloture, configuration }

class _Configuration implements ServiceConfiguration {
  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async =>
      const <ValeurConfig>[];

  @override
  Future<void> ecrire(String cle, Object valeur) async {}
}

Future<void> _ouvrir(
  WidgetTester tester,
  _Ecran ecran, {
  required ThemeMode mode,
  double echelle = 1,
}) async {
  final List<Override> surcharges = <Override>[
    ...surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
    serviceAppairageProvider.overrideWithValue(
      FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[
          const EleveDuFoyer(
            id: 'e1',
            prenom: 'Amina',
            identifiantImmuable: 'STUD-AD-000001',
            mode: InterfaceMode.enfant,
            camera: CameraPolicy.forbidden,
          ),
        ],
    ),
    servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
    serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
    serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
    serviceConfigurationProvider.overrideWithValue(_Configuration()),
  ];
  final Widget page = switch (ecran) {
    _Ecran.cloture => const GroupesPage(),
    _Ecran.configuration => Scaffold(
      body: SafeArea(
        child: ConfigLigneEntiere(
          titre: t.admin.regles.dureeSeance,
          description: t.admin.regles.dureeSeanceDetail,
          cle: 'session_duration_minutes',
          valeur: 60,
          affichage: (int n) => t.admin.regles.uniteMinutes(n: '$n'),
          champValeur: t.admin.regles.champValeur,
          envoyer: t.admin.regles.envoyer,
          valeurInvalide: t.admin.regles.valeurInvalide,
          erreurEcriture: (String m) => m,
          onEcrit: () {},
        ),
      ),
    ),
  };
  await tester.pumpWidget(
    hoteCapture(
      page,
      surcharges: surcharges,
      themeMode: mode,
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);

  Future<void> toucher(Finder cible) async {
    await tester.ensureVisible(cible);
    await stabiliser(tester);
    await tester.tap(cible);
    await stabiliser(tester);
  }

  switch (ecran) {
    case _Ecran.cloture:
      // « Autre » retenu, vide, puis Clôturer : le champ dit ce qui manque.
      await toucher(find.byType(MenuActions).first);
      await toucher(find.text(t.admin.groupes.actionCloturer).last);
      await toucher(find.byKey(SelecteurMotif.cleAutre));
      await toucher(
        find.widgetWithText(ActionPrincipale, t.admin.groupes.cloturerEnvoyer),
      );
      await tester.ensureVisible(find.byKey(SelecteurMotif.clePuce(0)));
      await stabiliser(tester);
    case _Ecran.configuration:
      await toucher(find.text(t.admin.regles.dureeSeance));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  group('Capture : FORM-L1-7-13', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    const EdgeInsets zone = EdgeInsets.only(top: 47, bottom: 34);

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final _Ecran ecran in _Ecran.values) {
        testWidgets('390x844 @3, ${ecran.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: zone);
          await _ouvrir(tester, ecran, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l1_7_13_${ecran.name}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('320x1400 @2 texte x2, ${ecran.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 1400), 2);
          await _ouvrir(tester, ecran, mode: mode, echelle: 2);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l1_7_13_${ecran.name}_320x1400@2_x2_${mode.name}')}',
          );
        });

        testWidgets('1440x900 @1, ${ecran.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _ouvrir(tester, ecran, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l1_7_13_${ecran.name}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }
  });
}
