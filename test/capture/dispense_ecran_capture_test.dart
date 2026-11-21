// DISPENSE-ECRAN (BE-1g, pilote 16/11/2026) : la feuille « Dispenser
// d'entretien », dans le dossier d'une candidature en Salle de verification
// (entretien a planifier) puis sur une selection de la liste. 360 et 1440,
// francais et arabe. Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart';

import '../features/admin_candidature/hote_candidature.dart';
import '../features/admin_candidatures/hote_candidatures.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/barre_lot.dart';
import '../support/monter_recrutement.dart' show laisser;
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('DISPENSE-ECRAN : captures', skip: sautSansCapture, () {
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
                  etat: EtatCandidature.entretienAPlanifier,
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
          await capturerVue(tester, 'DISPENSE-ECRAN/menu_${nom}_$largeur');
          await tester.tap(
            find.text(libelleGeste(GesteCandidature.dispenserEntretien)),
          );
          await laisser(tester, fois: 6);
          await capturerVue(tester, 'DISPENSE-ECRAN/feuille_${nom}_$largeur');
        });

        testWidgets('$largeur $nom selection', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterCandidatures(
            tester,
            port: FauxCandidaturesDirection(
              lignes: <LigneCandidature>[
                ligneTest(
                  id: 'v1',
                  nom: 'Karim Benali',
                  etape: EtapeCandidature.verifications,
                  etat: EtatCandidature.entretienAPlanifier,
                ),
                ligneTest(
                  id: 'v2',
                  nom: 'Salma Idrissi',
                  etape: EtapeCandidature.verifications,
                  etat: EtatCandidature.entretienPlanifie,
                ),
                ligneTest(id: 'x3', nom: 'Omar Fall'),
              ],
              capacitesRendues: capacitesGestes,
            ),
            largeur: largeur.toDouble(),
            hauteur: hauteur,
            direction: sens,
          );
          await laisser(tester);
          await tester.tap(
            find.byKey(const ValueKey<String>('candidatures-selectionner')),
          );
          await laisser(tester);
          for (final String id in <String>['v1', 'v2', 'x3']) {
            await tester.tap(find.byKey(cleCase(id)));
            await laisser(tester);
          }
          await tester.tap(
            await operationDeLot(
              tester,
              CandidaturesPage.cleOperationLot(GesteLot.dispenserEntretien),
              GesteLot.dispenserEntretien,
            ),
          );
          await laisser(tester, fois: 12);
          await capturerVue(tester, 'DISPENSE-ECRAN/lot_${nom}_$largeur');
        });
      }
    }
  });
}
