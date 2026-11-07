// SALLE-1-TOUT-ICI (lot 4, 07/11/2026) : captures du portail du candidat
// avec les noms de salles cote candidat (« Votre candidature »,
// « Faisons connaissance ») au lieu de « Vous etes en Salle d'examen ».
// Etats : salle 1 tout a faire (page unique « Votre candidature »), salle 1
// accords faits (la piece est la prochaine action), envoyee, salle 2 ;
// francais et arabe, 390 x 844 et 1440 x 900, clair. Donnees de test
// seulement. Jamais sans `CAPTURE_DIR`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

/// Un etat : la candidature, et ce qui est deja fait dans le dossier.
typedef _Etat = ({CandidatureDossier c, bool accords, bool piece});

final Map<String, _Etat> _etats = <String, _Etat>{
  'a_completer': (
    c: candidatureAFaire(cadreAccepte: false),
    accords: false,
    piece: false,
  ),
  'a_completer_piece': (c: candidatureAFaire(), accords: true, piece: false),
  'envoyee': (
    c: const CandidatureDossier(
      existe: true,
      etape: EtapeCandidature.prequalification,
      etat: EtatCandidature.enExamen,
      version: 4,
    ),
    accords: true,
    piece: false,
  ),
  'faisons_connaissance': (
    c: const CandidatureDossier(
      existe: true,
      etape: EtapeCandidature.verifications,
      etat: EtatCandidature.entretienAPlanifier,
      version: 5,
    ),
    accords: true,
    piece: true,
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
          for (final MapEntry<String, _Etat> e in _etats.entries) {
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
                  ..etatRendu = etatCandidat(
                    candidature: e.value.c,
                    accordsFaits: e.value.accords,
                    pieceDeposee: e.value.piece,
                  ),
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
