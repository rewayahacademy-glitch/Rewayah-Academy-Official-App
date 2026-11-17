// REFAIRE-ENTRETIEN (BE-1h, pilote 16/11/2026) : la feuille « Refaire
// l'entretien », dans le dossier d'une candidature en Salle de verification
// (decision en attente). 360 et 1440,
// francais et arabe. Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart';

import '../features/admin_candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/monter_recrutement.dart' show laisser;
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('REFAIRE-ENTRETIEN : captures', skip: sautSansCapture, () {
    for (final (int largeur, double hauteur) in <(int, double)>[
      (360, 800),
      (1440, 900),
    ]) {
      for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
        ('fr', AppLocale.fr),
        ('ar', AppLocale.ar),
      ]) {
        final TextDirection? sens = langue == AppLocale.ar
            ? TextDirection.rtl
            : null;

        testWidgets('$largeur $nom dossier', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterCandidature(
            tester,
            port: FauxCandidaturesDirection(
              capacitesRendues: capacitesGestes,
              details: <DetailCandidature>[
                detailTest(
                  etape: EtapeCandidature.verifications,
                  etat: EtatCandidature.decisionEnAttente,
                  paiement: EtatVersement.compatible,
                ),
              ],
            ),
            largeur: largeur.toDouble(),
            hauteur: hauteur,
            direction: sens,
            ouvrirRubriques: false,
          );
          await laisser(tester);
          await tester.ensureVisible(find.byKey(BarreDecisionDossier.cleMenu));
          await laisser(tester);
          await tester.tap(find.byKey(BarreDecisionDossier.cleMenu));
          await laisser(tester);
          await capturerVue(tester, 'REFAIRE-ENTRETIEN/menu_${nom}_$largeur');
          await tester.tap(
            find.text(libelleGeste(GesteCandidature.refaireEntretien)),
          );
          await laisser(tester, fois: 6);
          await capturerVue(
            tester,
            'REFAIRE-ENTRETIEN/feuille_${nom}_$largeur',
          );
        });
      }
    }
  });
}
