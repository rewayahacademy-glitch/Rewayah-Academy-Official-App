// Captures de recette de FORM-L4-11-12 : calendrier de date (evaluation),
// depot de piece sans carte « Autre » a champ libre, libelle de jeton agent
// prerempli, courriel prerempli sur la recuperation. 390x844 et 1440x900, clair
// et sombre ; 320 a texte x2, clair et sombre (K-61). Saute sans CAPTURE_DIR
// (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/service_agent.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_acces_agents/acces_agents_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';
import 'package:rewayah_academy/features/connexion/recuperation_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../features/support_form_l2.dart';
import '../support/harnais.dart' show FauxSelecteurFichier, FauxServiceDossier;
import 'outil_capture.dart';

enum _Ecran { calendrier, dateChoisie, depot, jeton, recuperation }

class _Agents implements ServiceAgent {
  @override
  Future<List<JetonAgent>> lister() async => const <JetonAgent>[];

  @override
  Future<List<PersonneObservable>> personnes() async =>
      const <PersonneObservable>[
        PersonneObservable(
          id: 'p-maryam',
          identifiant: 'ELV-MS-010',
          prenom: 'Maryam',
          nom: 'Sow',
          role: null,
        ),
      ];

  @override
  Future<JetonEmis> emettre({
    required String libelle,
    required String profilObserve,
    required int dureeHeures,
    required bool identiteMasquee,
  }) async => throw UnimplementedError();

  @override
  Future<bool> revoquer(String id) async => true;
}

Future<void> _ouvrir(
  WidgetTester tester,
  _Ecran ecran, {
  required ThemeMode mode,
  double echelle = 1,
}) async {
  final List<Override> surcharges = <Override>[
    ...surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
    serviceAgentProvider.overrideWithValue(_Agents()),
    serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
    selecteurFichierProvider.overrideWithValue(FauxSelecteurFichier(null)),
  ];
  final Widget page = switch (ecran) {
    _Ecran.calendrier || _Ecran.dateChoisie => const EvaluationsPage(),
    _Ecran.depot => const DepotPiecePage(),
    _Ecran.jeton => const AccesAgentsPage(),
    _Ecran.recuperation => const RecuperationPage(
      courrielInitial: 'awa@exemple.fr',
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
    case _Ecran.calendrier || _Ecran.dateChoisie:
      await toucher(find.text(t.admin.evaluations.planifier).first);
      await toucher(find.byKey(const ValueKey<String>('personne-e-ines')));
      await toucher(find.text(niveauFormL2.nomHumain));
      await toucher(find.byKey(const ValueKey<String>('champ-date')));
      if (ecran == _Ecran.dateChoisie) {
        await tester.tap(find.text('15'));
        await stabiliser(tester);
        await tester.tap(find.text('OK'));
        await stabiliser(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('champ-date')),
        );
        await stabiliser(tester);
      }
    case _Ecran.depot:
      await toucher(find.text(t.kyc.autrePiece));
    case _Ecran.jeton:
      await toucher(find.text('Maryam Sow'));
      await tester.ensureVisible(find.byType(TextField).first);
      await stabiliser(tester);
    case _Ecran.recuperation:
      break;
  }
  expect(tester.takeException(), isNull);
}

void main() {
  group('Capture : FORM-L4-11-12', skip: sautSansCapture, () {
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
            'PNG ${await capturer(tester, 'form_l4_11_12_${ecran.name}_390x844@3_${mode.name}')}',
          );
        });

        testWidgets('320x1400 @2 texte x2, ${ecran.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 1400), 2);
          await _ouvrir(tester, ecran, mode: mode, echelle: 2);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l4_11_12_${ecran.name}_320x1400@2_x2_${mode.name}')}',
          );
        });

        testWidgets('1440x900 @1, ${ecran.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(1440, 900), 1);
          await _ouvrir(tester, ecran, mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l4_11_12_${ecran.name}_1440x900@1_${mode.name}')}',
          );
        });
      }
    }
  });
}
