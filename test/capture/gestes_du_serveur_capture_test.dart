// GESTES-DU-SERVEUR (pilote, 16/11/2026) : l'ecran n'affiche que les gestes que
// le serveur sert pour la ligne (cle `gestes`), et ceux qu'il sait faire. Le menu
// « ... » d'un dossier en Salle de verification, le serveur servant un geste que
// l'ecran ne sait pas faire (restreindre) : il n'est pas montre. 360,
// francais et arabe. Donnees fictives. Saute sans CAPTURE_DIR.

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

  group('GESTES-DU-SERVEUR : captures', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('360 $nom menu des gestes servis', (
        WidgetTester tester,
      ) async {
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
                // Ce que le serveur sert : des gestes que l'ecran sait faire,
                // et « restreindre », qu'il ne sait pas faire.
                gestes: const <String>[
                  'restreindre',
                  'mettre_en_pause',
                  'retirer',
                  'demander_complement',
                ],
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
        await capturerVue(tester, 'GESTES-DU-SERVEUR/menu_servi_${nom}_360');
      });
    }
  });
}
