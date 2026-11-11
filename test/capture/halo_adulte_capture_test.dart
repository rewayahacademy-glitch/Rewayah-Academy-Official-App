// Captures du lot NAV-REFONTE 2c (11/11/2026) : le halo vert du cercle de
// l'eleve adulte quand la carte de sa Classe offre « Rejoindre », et la
// feuille « En ce moment », dont le bouton reprend le libelle de la carte.
//
// Donnees de test seulement. Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/demo/classe_demo.dart';
import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

void main() {
  group('Capture : halo vert de l eleve adulte', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, ThemeMode theme, bool feuille)
        in <(String, ThemeMode, bool)>[
          ('lueur_320_clair', ThemeMode.light, false),
          ('lueur_320_sombre', ThemeMode.dark, false),
          ('feuille_320_clair', ThemeMode.light, true),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 700), 1);
        final List<Destination> d = destinationsPour(
          role: AppRole.student,
          mode: InterfaceMode.standard,
          eleveAdulte: true,
        );
        // Le libelle meme de la carte, par la meme fonction pure.
        final EmplacementEntree carte = DonneesClasseDemo.emplacement(
          RoleEntree.eleve,
          EtatDemoClasse.fenetreOuverte,
        );
        final EtatHaloCompte halo = EtatHaloCompte.salle(
          action: carte.libelle,
          chemin: Routes.eleveAdulte,
          agir: (BuildContext _) {},
        );
        await tester.pumpWidget(
          hoteCapture(
            NavShell(
              destinations: d,
              indexActif: 0,
              onAller: (_) {},
              halo: halo,
              child: PageShell(
                titre: d.first.libelle,
                child: const SizedBox(height: 200),
              ),
            ),
            surcharges: <Override>[sansPersonneConnectee()],
            themeMode: theme,
          ),
        );
        await tester.pumpAndSettle();
        if (feuille) {
          await tester.tap(
            find.bySemanticsLabel(halo.nomAccessible(d.last.libelle)),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'halo-adulte_$nom')}');
      });
    }
  });
}
