// SALLE-1-TOUT-ICI (lot 4, 07/11/2026) : captures du portail du candidat
// avec les noms de salles cote candidat (« Votre candidature »,
// « Faisons connaissance ») au lieu de « Vous etes en Salle d'examen ».
// Trois etats (a completer, envoyee, salle 2), francais et arabe, 390 x 844
// et 1440 x 900, clair. Donnees de test seulement. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

final Map<String, CandidatureDossier> _etats = <String, CandidatureDossier>{
  'a_completer': candidatureAFaire(cadreAccepte: false),
  'envoyee': const CandidatureDossier(
    existe: true,
    etape: EtapeCandidature.prequalification,
    etat: EtatCandidature.enExamen,
    version: 4,
  ),
  'faisons_connaissance': const CandidatureDossier(
    existe: true,
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienAPlanifier,
    version: 5,
  ),
};

void main() {
  group(
    'Capture : portail du candidat (SALLE-1-TOUT-ICI)',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      setUp(masquerRubanDebug);

      for (final bool arabe in <bool>[false, true]) {
        final String langue = arabe ? 'ar' : 'fr';
        for (final Size taille in <Size>[
          const Size(390, 844),
          const Size(1440, 900),
        ]) {
          final String s = '${taille.width.toInt()}x${taille.height.toInt()}';
          for (final MapEntry<String, CandidatureDossier> e in _etats.entries) {
            testWidgets('${e.key}, $langue $s', (WidgetTester tester) async {
              await tester.runAsync(
                () => LocaleSettings.setLocale(
                  arabe ? AppLocale.ar : AppLocale.fr,
                ),
              );
              addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
              await monterQuestionnaire(
                tester,
                port: FauxMaCandidature(),
                depart: Routes.attente,
                taille: taille,
                direction: arabe ? TextDirection.rtl : null,
                dossier: FauxServiceDossier()
                  ..etatRendu = etatCandidat(candidature: e.value),
              );
              await stabiliser(tester);
              debugPrint(
                'PNG ${await capturerVue(tester, '${e.key}_${langue}_$s')}',
              );
            });
          }
        }
      }
    },
  );
}
