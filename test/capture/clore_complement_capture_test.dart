// CLORE-COMPLEMENT-VRAI (directeur, 16/11/2026, capture de production
// CAND-00068 : « Clore le complement » propose sans demande en cours). Le menu
// « ... » du dossier en Salle de verification et d'entretien, ouvert : sans
// complement en cours (le geste n'y est pas), avec un complement en cours (il y
// est). 360, francais et arabe. Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';

import '../features/admin_candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/monter_recrutement.dart' show laisser;
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('CLORE-COMPLEMENT-VRAI : captures', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      for (final (String etat, bool complement) in <(String, bool)>[
        ('sans_complement', false),
        ('complement_en_cours', true),
      ]) {
        testWidgets('360 $nom $etat', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterCandidature(
            tester,
            port: FauxCandidaturesDirection(
              capacitesRendues: capacitesGestes,
              details: <DetailCandidature>[
                detailTest(
                  etape: EtapeCandidature.verifications,
                  etat: EtatCandidature.entretienAPlanifier,
                  paiement: EtatVersement.compatible,
                  complementEnCours: complement,
                ),
              ],
            ),
            largeur: 360,
            hauteur: 800,
            direction: langue == AppLocale.ar ? TextDirection.rtl : null,
            ouvrirRubriques: false,
          );
          await laisser(tester);
          await tester.ensureVisible(find.byKey(BarreDecisionDossier.cleMenu));
          await laisser(tester);
          await tester.tap(find.byKey(BarreDecisionDossier.cleMenu));
          await laisser(tester);
          await capturerVue(
            tester,
            'CLORE-COMPLEMENT-VRAI/menu_${etat}_${nom}_360',
          );
        });
      }
    }
  });
}
