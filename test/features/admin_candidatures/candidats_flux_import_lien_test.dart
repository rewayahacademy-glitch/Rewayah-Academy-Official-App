// CANDIDATS-FLUX (06/11/2026) : le lien « Importer les formulaires » de la
// file des candidatures, branche sur l'ecran d'import porte de la PR 50.
//
// Ce que le test prouve : le lien n'existe que si le serveur ouvre l'import a
// ce lecteur (`peutImporter` : super administrateur en double verification,
// ou `doubleVerificationRequise` : le meme, a qui l'ecran demandera le code ;
// erreur du robot du 06/11 : sans ce second cas, le lien n'apparaissait
// jamais) ET que le port est servi, jamais grise ; le toucher ouvre l'import.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_import_candidatures.dart';
import 'package:rewayah_academy/features/admin_import_formulaires/routes_candidats_flux.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../fixtures/candidature/faux_import_candidatures.dart';
import 'hote_candidatures.dart';

// BE-LISTE : le lien est une entree du menu « Outils ».
const String _libelle = 'Importer les formulaires';

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
    expect(await entreeOutilsPresente(tester, _libelle), isTrue);
    await toucherOutil(tester, _libelle);
    // Une vraie route (plus une page empilee) : la destination du routeur.
    expect(
      find.text('temoin:${RoutesCandidatsFlux.importFormulaires}'),
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
    expect(await entreeOutilsPresente(tester, _libelle), isTrue);
  });

  testWidgets('absent sans la capacite du serveur', (tester) async {
    await _monter(tester, peutImporter: false, portServi: true);
    expect(await entreeOutilsPresente(tester, _libelle), isFalse);
  });

  testWidgets('absent quand le port n\'est pas servi', (tester) async {
    await _monter(tester, peutImporter: true, portServi: false);
    expect(await entreeOutilsPresente(tester, _libelle), isFalse);
  });
}
