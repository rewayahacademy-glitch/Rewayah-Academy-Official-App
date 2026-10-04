// CTRL-MSG-1 : le message d'une visite qui n'est plus en memoire (compte
// rendu), et l'echec d'envoi d'une observation sans texte, a 320 et texte x2
// (densite 1), 390 et 1440, clair et sombre. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';

import 'outil_capture.dart';

final CompteRenduEnSuspens _visite = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
);

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('Capture : CTRL-MSG-1, messages du controleur', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    // « 320x2 » est un vrai texte x2 a densite 1 (revue C1-CTRL-R m4) : a
    // densite 2 et texte x1, le debordement de l'echec ne se voyait pas.
    for (final (String l, Size taille, double densite, double echelle)
        in <(String, Size, double, double)>[
          ('320x2', const Size(320, 700), 1, 2),
          ('390', const Size(390, 844), 1, 1),
          ('1440', const Size(1440, 900), 1, 1),
        ]) {
      for (final (String th, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        testWidgets('ctrl_msg1_inconnue_${l}_$th', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              const CompteRenduControlePage(seanceId: 'seance-inconnue'),
              themeMode: mode,
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          expect(
            find.text(t.controleur.compteRendu.visiteInconnue),
            findsOneWidget,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ctrl_msg1_inconnue_${l}_$th')}',
          );
        });

        testWidgets('ctrl_msg1_echec_sans_texte_${l}_$th', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              ObservationControlePage(seanceId: _visite.seanceId),
              themeMode: mode,
              echelleTexte: echelle,
              surcharges: <Override>[
                visitesObserveesProvider.overrideWith(
                  () => VisitesObservees(<String, CompteRenduEnSuspens>{
                    _visite.seanceId: _visite,
                  }),
                ),
              ],
            ),
          );
          await stabiliser(tester);
          await _toucher(
            tester,
            find.byKey(
              ObservationControlePage.cleNature(NatureObservation.pointPositif),
            ),
          );
          await _toucher(tester, find.text(t.commun.continuer).last);
          await _toucher(
            tester,
            find.byKey(
              ObservationControlePage.cleDomaine(
                DomaineObservation.interaction,
              ),
            ),
          );
          await _toucher(tester, find.text(t.commun.continuer).last);
          await _toucher(
            tester,
            find.byKey(
              ObservationControlePage.clePersonne(
                PersonneConcernee.classeEntiere,
              ),
            ),
          );
          await _toucher(tester, find.text(t.commun.continuer).last);
          await _toucher(tester, find.text(t.commun.continuer).last);
          await _toucher(
            tester,
            find.text(t.controleur.compteRendu.envoyer).last,
          );
          final Finder echec = find.text(
            t.controleur.observation.echecSansTexte,
          );
          expect(echec, findsOneWidget);
          await tester.ensureVisible(echec);
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'ctrl_msg1_echec_sans_texte_${l}_$th')}',
          );
        });
      }
    }
  });
}
