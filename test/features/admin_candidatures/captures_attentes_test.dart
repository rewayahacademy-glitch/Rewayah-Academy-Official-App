// VISION-RECRUTEMENT (14/11/2026) : « Qui attend quoi » au-dessus de la file
// des candidatures, 1440 et 390, francais et arabe. Donnees de test seulement
// (nombres releves en production le 14/11, aucun nom reel). Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidatures.dart';

class _Attentes implements PortAttentesRecrutement {
  @override
  Future<AttentesRecrutement> lire() async {
    final DateTime m = DateTime.now().toUtc();
    String il(int h) => m.subtract(Duration(hours: h)).toIso8601String();
    return AttentesRecrutement.depuisJson(<String, Object?>{
      'etats': <String, Object?>{
        'en_examen': <String, Object?>{'nombre': 41, 'plusAncien': il(6)},
        'entretien_a_planifier': <String, Object?>{
          'nombre': 1,
          'plusAncien': il(1),
        },
        'a_completer': <String, Object?>{'nombre': 18, 'plusAncien': il(7)},
        'paiement_non_disponible': <String, Object?>{
          'nombre': 11,
          'plusAncien': il(6),
        },
      },
      'pieceAValider': <String, Object?>{'nombre': 13, 'plusAncien': il(5)},
      'enPause': 0,
      'creneauxOuverts': 0,
      'entretiensSansIssue': 0,
      'deuxCotes': true,
    });
  }
}

void main() {
  group('Capture : VISION-RECRUTEMENT', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (String langue, AppLocale locale, TextDirection sens)
        in <(String, AppLocale, TextDirection)>[
          ('fr', AppLocale.fr, TextDirection.ltr),
          ('ar', AppLocale.ar, TextDirection.rtl),
        ]) {
      for (final (String nom, double largeur, double hauteur)
          in <(String, double, double)>[
            ('390', 390, 1600),
            ('1440', 1440, 900),
          ]) {
        testWidgets('qui attend quoi, $langue $nom', (tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(locale));
          await monterCandidatures(
            tester,
            port: FauxCandidaturesDirection(
              lignes: <LigneCandidature>[
                ligneTest(
                  id: 'a1',
                  nom: 'Amina Diallo',
                  etat: EtatCandidature.enExamen,
                ),
                ligneTest(
                  id: 'b2',
                  nom: 'Bilal Haddad',
                  etat: EtatCandidature.aCompleter,
                ),
                ligneTest(
                  id: 'c3',
                  nom: 'Yusuf Ahmed',
                  etat: EtatCandidature.paiementNonDisponible,
                ),
              ],
              capacitesRendues: capacitesGestes,
            ),
            largeur: largeur,
            hauteur: hauteur,
            direction: sens,
            surcharges: [
              portAttentesRecrutementProvider.overrideWithValue(_Attentes()),
            ],
          );
          await laisser(tester);
          debugPrint(
            'PNG ${await capturerVue(tester, 'qui_attend_quoi_${langue}_$nom')}',
          );
        });
      }
    }
  });
}
