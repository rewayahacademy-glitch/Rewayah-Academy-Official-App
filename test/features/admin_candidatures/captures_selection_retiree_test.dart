// SELECTION-RETIREE (2a, pilote du 11/11/2026) : la file des candidatures
// apres un changement de filtre, selection retiree et message affiche.
// Donnees de test seulement. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';
import '../../support/rangee_plus.dart';
import 'hote_candidatures.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  group('Capture : SELECTION-RETIREE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final (String nom, double largeur, double hauteur)
        in <(String, double, double)>[
          ('390', 390, 1100),
          ('1440', 1440, 900),
        ]) {
      testWidgets('selection retiree apres un filtre, $nom', (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: <LigneCandidature>[
            ligneTest(id: 'a1', nom: 'Amina Diallo'),
            ligneTest(id: 'b2', nom: 'Bilal Haddad'),
          ],
          capacitesRendues: capacitesGestes,
        );
        await monterCandidatures(
          tester,
          port: port,
          largeur: largeur,
          hauteur: hauteur,
        );
        await tester.tap(_cle('candidatures-selectionner'));
        await laisser(tester);
        await tester.tap(_cle('candidature-a1'));
        await laisser(tester);
        await tester.tap(_cle('candidature-b2'));
        await laisser(tester);
        expect(find.byKey(CandidaturesPage.cleBarreLot), findsOneWidget);
        await toucherFiltre(tester, _cle('candidatures-filtre-examen'));
        await laisser(tester);
        expect(find.byKey(CandidaturesPage.cleBarreLot), findsNothing);
        final Finder message = find.text(
          t.admin.candidatures.lot.selectionRetiree,
        );
        expect(message, findsOneWidget);
        await tester.ensureVisible(message);
        await laisser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'selection_retiree_${nom}_clair')}',
        );
      });
    }
  });
}
