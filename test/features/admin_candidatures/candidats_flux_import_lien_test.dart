// CANDIDATS-FLUX (06/11/2026) : le lien « Importer les formulaires » de la
// file des candidatures, branche sur l'ecran d'import porte de la PR 50.
//
// Ce que le test prouve : le lien n'existe que si le serveur ouvre l'import a
// ce lecteur (`peutImporter` : super administrateur en double verification,
// ou `doubleVerificationRequise` : le meme, a qui l'ecran demandera le code ;
// erreur du robot du 06/11 : sans ce second cas, le lien n'apparaissait
// jamais) ET que le port est servi, jamais grise ; le toucher ouvre l'import.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/import_formulaires_page.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_import_candidatures.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

const Key _lien = ValueKey<String>('candidatures-importer');

Future<void> _monter(
  WidgetTester tester, {
  required bool peutImporter,
  required bool portServi,
  bool doubleRequise = false,
}) => monterCandidatures(
  tester,
  port: FauxCandidaturesDirection(
    lignes: <LigneCandidature>[ligneTest(id: 'a1')],
    capacitesRendues: CapacitesCandidatures(
      peutLire: true,
      genreLecteurConnu: true,
      peutImporter: peutImporter,
    ),
  ),
  surcharges: <Override>[
    portImportCandidaturesProvider.overrideWithValue(
      portServi
          ? FauxImportCandidatures(
              capacitesRendues: CapacitesImportCandidatures(
                peutImporter: peutImporter,
                doubleVerificationRequise: doubleRequise,
              ),
            )
          : null,
    ),
  ],
);

void main() {
  testWidgets('present pour qui peut importer, et il ouvre l\'import', (
    tester,
  ) async {
    await _monter(tester, peutImporter: true, portServi: true);
    expect(find.byKey(_lien), findsOneWidget);
    expect(find.text('Importer les formulaires'), findsOneWidget);
    await tester.ensureVisible(find.byKey(_lien));
    await tester.pump();
    await tester.tap(find.byKey(_lien));
    await laisser(tester);
    expect(find.byType(ImportFormulairesPage), findsOneWidget);
    // Le faux port ouvre l'import : le parcours en huit pas est rendu.
    expect(
      find.byKey(const ValueKey<String>('import-parcours')),
      findsOneWidget,
    );
  });

  testWidgets('present quand le code reste a saisir (aal1)', (tester) async {
    await _monter(
      tester,
      peutImporter: false,
      portServi: true,
      doubleRequise: true,
    );
    expect(find.byKey(_lien), findsOneWidget);
  });

  testWidgets('absent sans la capacite du serveur', (tester) async {
    await _monter(tester, peutImporter: false, portServi: true);
    expect(find.byKey(_lien), findsNothing);
  });

  testWidgets('absent quand le port n\'est pas servi', (tester) async {
    await _monter(tester, peutImporter: true, portServi: false);
    expect(find.byKey(_lien), findsNothing);
  });
}
