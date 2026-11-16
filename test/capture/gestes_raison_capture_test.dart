// GESTES-RAISON (directeur, 16/11/2026) : la rangee des gestes du dossier dit
// toujours son etat, au meme endroit, et les fleches precedent / suivant sont
// chacune sur son bord de la carte de profil. 360, francais et arabe, quatre
// etats. Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';

import '../features/admin_candidature/hote_candidature.dart';
import '../features/admin_candidature/suivant_dossier_test.dart'
    show monterFileTest, portFileTest;
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/monter_recrutement.dart' show laisser;
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('GESTES-RAISON : captures', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      final TextDirection? sens = langue == AppLocale.ar
          ? TextDirection.rtl
          : null;
      for (final (String etat, DetailCandidature Function() detail)
          in <(String, DetailCandidature Function())>[
            (
              'examen_compatible',
              () => detailTest(
                paiement: EtatVersement.compatible,
                controles: const <ControleCandidature>[],
              ),
            ),
            ('a_completer', () => detailTest(etat: EtatCandidature.aCompleter)),
            (
              'versement_impossible',
              () => detailTest(paiement: EtatVersement.incompatible),
            ),
            (
              'entretien_a_planifier',
              () => detailTest(
                etape: EtapeCandidature.verifications,
                etat: EtatCandidature.entretienAPlanifier,
              ),
            ),
          ]) {
        testWidgets('360 $nom $etat', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await monterCandidature(
            tester,
            port: FauxCandidaturesDirection(
              capacitesRendues: capacitesGestes,
              details: <DetailCandidature>[detail()],
            ),
            largeur: 360,
            hauteur: 800,
            direction: sens,
            ouvrirRubriques: false,
          );
          await laisser(tester);
          await tester.ensureVisible(find.byKey(BarreDecisionDossier.cle));
          await laisser(tester);
          await capturerVue(tester, 'GESTES-RAISON/gestes_${etat}_${nom}_360');
        });
      }

      testWidgets('360 $nom fleches aux deux bords', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        await monterFileTest(
          tester,
          portFileTest(),
          ouvert: 'c2',
          largeur: 360,
          direction: sens,
        );
        await laisser(tester);
        await capturerVue(tester, 'GESTES-RAISON/fleches_${nom}_360');
      });
    }
  });
}
