// CTRL-MSG-2 (revue C1-CTRL-R) : la seance inconnue avec ses deux sorties
// (compte rendu et observation), et l'echec d'envoi de l'observation et du
// complement a 320 px et VRAI texte x2 (densite 1), en LTR et en RTL, clair
// et sombre. Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/complement_rapport_page.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';

import 'outil_capture.dart';

final CompteRenduEnSuspens _visite = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
);

final RapportControle _parent = RapportControle(
  id: 'rapport-parent',
  missionId: 'mission-A',
  classe: 'Al-Badr',
  enseignant: 'Sayyid Karim',
  debut: DateTime(2026, 9, 24, 17),
  dureeObservee: const Duration(minutes: 20),
  statut: StatutRapport.envoye,
  choix: ChoixCompteRendu.rienASignaler,
);

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

Widget _dans(TextDirection d, Widget ecran) =>
    Directionality(textDirection: d, child: ecran);

void main() {
  group('Capture : CTRL-MSG-2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String th, ThemeMode mode) in <(String, ThemeMode)>[
      ('clair', ThemeMode.light),
      ('sombre', ThemeMode.dark),
    ]) {
      for (final (String l, Size taille, double echelle)
          in <(String, Size, double)>[
            ('320x2', const Size(320, 700), 2),
            ('390', const Size(390, 844), 1),
            ('1440', const Size(1440, 900), 1),
          ]) {
        for (final (String p, Widget page) in <(String, Widget)>[
          (
            'compte_rendu',
            const CompteRenduControlePage(seanceId: 'seance-inconnue'),
          ),
          (
            'observation',
            const ObservationControlePage(seanceId: 'seance-inconnue'),
          ),
        ]) {
          // L'observation n'est capturee qu'a 320 x2 : meme ecran partage.
          if (p == 'observation' && l != '320x2') continue;
          testWidgets('ctrl_msg2_inconnue_${p}_${l}_$th', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(page, themeMode: mode, echelleTexte: echelle),
            );
            await stabiliser(tester);
            expect(find.byKey(VisiteInconnue.ecrireAdminKey), findsOneWidget);
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 'ctrl_msg2_inconnue_${p}_${l}_$th')}',
            );
            // A 320 x2, les deux sorties sont sous le texte : une seconde
            // vue, defilee jusqu'a elles.
            if (l == '320x2') {
              final Finder revenir = find.text(
                t.controleur.compteRendu.revenir,
              );
              await tester.ensureVisible(revenir);
              await stabiliser(tester);
              expect(tester.getRect(revenir).bottom, lessThanOrEqualTo(700));
              debugPrint(
                'PNG ${await capturer(tester, 'ctrl_msg2_inconnue_${p}_${l}_${th}_bas')}',
              );
            }
          });
        }
      }

      for (final TextDirection d in TextDirection.values) {
        testWidgets('ctrl_msg2_echec_observation_320x2_${d.name}_$th', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 700), 1);
          await tester.pumpWidget(
            hoteCapture(
              _dans(d, ObservationControlePage(seanceId: _visite.seanceId)),
              themeMode: mode,
              echelleTexte: 2,
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
          expect(
            find.text(t.controleur.observation.echecSansTexte),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'ctrl_msg2_echec_observation_320x2_${d.name}_$th')}',
          );
        });

        testWidgets('ctrl_msg2_echec_complement_320x2_${d.name}_$th', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, const Size(320, 700), 1);
          await tester.pumpWidget(
            hoteCapture(
              _dans(
                d,
                ComplementRapportPage(
                  rapport: _parent,
                  onRetour: () {},
                  onTermine: (RapportControle _) {},
                ),
              ),
              themeMode: mode,
              echelleTexte: 2,
            ),
          );
          await stabiliser(tester);
          await _toucher(tester, find.text(t.commun.continuer).last);
          await tester.enterText(
            find.byKey(ComplementRapportPage.texteKey),
            'La Classe a fini plus tôt.',
          );
          await stabiliser(tester);
          await _toucher(tester, find.text(t.commun.continuer).last);
          await _toucher(
            tester,
            find.text(t.controleur.complement.envoyer).last,
          );
          expect(find.text(t.controleur.complement.echec), findsOneWidget);
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'ctrl_msg2_echec_complement_320x2_${d.name}_$th')}',
          );
        });
      }
    }
  });
}
