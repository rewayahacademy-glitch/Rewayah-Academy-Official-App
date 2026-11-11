// Captures de REPRISE-CAND-2 (decision du directeur du 23/10/2026, « Les noms
// dans une seule ecriture sur les listes ») : la confirmation du nom en
// lettres latines, avant le questionnaire de candidature, quand le nom du
// dossier est dans une autre ecriture. Deux etats : la proposition
// pre-remplie, puis l'envoi refuse par le reseau (« non confirme »).
// 390x844 et 1440x900, francais et arabe. Donnees fictives.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_nom_latin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/nom_latin_etape.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../fixtures/candidature/faux_nom_latin.dart';
import 'outil_capture.dart';

const String _nomArabe = 'محمد الدوسري';

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('REPRISE-CAND-2 : captures', skip: sautSansCapture, () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final bool echec in <bool>[false, true]) {
          final String nom =
              'nl_${taille.width.toInt()}_${langue.languageCode}_'
              '${echec ? 'echec' : 'proposition'}';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            final FauxNomLatin port = FauxNomLatin(nomComplet: _nomArabe)
              ..panneConfirmation = echec ? StateError('reseau') : null;
            await monterQuestionnaire(
              tester,
              port: FauxMaCandidature(),
              taille: taille,
              surchargesEnPlus: <Override>[
                portNomLatinProvider.overrideWithValue(port),
              ],
            );
            expect(find.byType(NomLatinEtape), findsOneWidget);
            if (echec) {
              final Finder bouton = find.byKey(NomLatinEtape.confirmerKey);
              await tester.ensureVisible(bouton);
              await tester.tap(bouton);
              await tester.pumpAndSettle();
              expect(find.text(t.recrutement.nomLatin.echec), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturerVue(tester, 'reprise-cand-2/$nom')}',
            );
          });
        }
      }
    }
  });
}
