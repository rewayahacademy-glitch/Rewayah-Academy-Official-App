// FOYER-PARCOURS (directeur et garde-cap, 07/11/2026) : rouvrir le parcours
// d'un profil dont la demande vit montre le recapitulatif et l'etat de la
// demande, avec « Modifier mes reponses ». FR et AR, 390 et 1440. Prefixe
// des PNG : `foyer_parcours_`. Saute sans CAPTURE_DIR.
//
// Ce ne sont pas les captures du robot de la pile locale (R3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';

import '../parcours/faux_service_offres.dart';
import 'outil_capture.dart';

void main() {
  group('Capture : FOYER-PARCOURS', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String nom =
            'foyer_parcours_recapitulatif_${taille.width.toInt()}_${langue.languageCode}';
        testWidgets(nom, (WidgetTester tester) async {
          LocaleSettings.setLocaleSync(langue);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, taille, 1);
          final ParcoursApprenant ibrahim = ParcoursApprenant(
            eleveId: 'e1',
            prenom: 'Ibrahim',
            diagnostic: StatutDiagnostic.aPlanifier,
            cohorteCode: 'adulte_18_plus',
            langueCode: 'francais',
            onboardingFaitLe: DateTime(2026, 11, 7, 7, 29),
            intentionEtat: EtatIntention.enregistree,
            fuseauFoyer: 'Europe/Paris',
            offreId: 'o1',
            niveauDeclare: NiveauDeclare.values.first,
            objectif: ObjectifApprentissage.values.first,
          );
          await tester.pumpWidget(
            hoteCapture(
              const ParcoursOffresPage(eleveId: 'e1'),
              surcharges: <Override>[
                serviceOffresProvider.overrideWithValue(
                  FauxServiceOffres(
                    parcoursRendu: <ParcoursApprenant>[ibrahim],
                    offresRendues: <OffreHoraire>[offreDeTest()],
                  ),
                ),
              ],
            ),
          );
          await stabiliser(tester);
          expect(
            find.byKey(ParcoursOffresPage.recapitulatifKey),
            findsOneWidget,
          );
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }
  });
}
