// DEBLOQUER-VERSEMENT-ECRAN (pilote, 16/11/2026) : le geste « Debloquer le
// versement » a cote du versement du dossier, puis sa feuille ouverte (motif et
// consequence dite avant le choix). 360, francais et arabe. Donnees fictives.
// Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../features/admin_candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/monter_recrutement.dart' show laisser;
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('DEBLOQUER-VERSEMENT-ECRAN : captures', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('360 $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        await monterCandidature(
          tester,
          port: FauxCandidaturesDirection(
            capacitesRendues: capacitesAvecDeblocage,
            details: <DetailCandidature>[
              detailTest(paiement: EtatVersement.inconnu),
            ],
          ),
          largeur: 360,
          hauteur: 800,
          direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          ouvrirRubriques: true,
        );
        await laisser(tester);
        final Finder lien = find.byKey(
          const ValueKey<String>('rubrique-geste-debloquerVersement'),
        );
        await tester.ensureVisible(lien);
        await laisser(tester);
        await capturerVue(
          tester,
          'DEBLOQUER-VERSEMENT-ECRAN/dossier_${nom}_360',
        );
        await tester.tap(lien);
        await laisser(tester);
        await capturerVue(
          tester,
          'DEBLOQUER-VERSEMENT-ECRAN/feuille_${nom}_360',
        );
      });
    }
  });
}
