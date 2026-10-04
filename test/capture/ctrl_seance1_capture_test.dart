// CTRL-SEANCE-1 : deux visites A et B a terminer ; le compte rendu de A
// montre les faits de A (deplies) et l'observation de A propose les prenoms
// de A, a 320 x2, 390 et 1440, clair et sombre. Jamais sans `CAPTURE_DIR`
// (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';

import 'outil_capture.dart';

final CompteRenduEnSuspens _a = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
);

final CompteRenduEnSuspens _b = CompteRenduEnSuspens(
  seanceId: 'seance-B',
  classe: 'Classe Al-Nour',
  debut: DateTime(2026, 9, 28, 17),
);

FaitsVisite _faits(int presents, int attendus) => FaitsVisite(
  debutPrevu: DateTime(2026, 9, 28, 16),
  finPrevue: DateTime(2026, 9, 28, 17),
  debutReel: DateTime(2026, 9, 28, 16, 2),
  participantsAttendus: attendus,
  participantsPresents: presents,
  reconnexions: 1,
);

List<Override> _surcharges() => <Override>[
  visitesObserveesProvider.overrideWith(
    () => VisitesObservees(<String, CompteRenduEnSuspens>{
      _a.seanceId: _a,
      _b.seanceId: _b,
    }),
  ),
  faitsVisiteProvider.overrideWith(
    (Ref _, String s) async => s == _a.seanceId ? _faits(7, 8) : _faits(3, 12),
  ),
  rosterControleProvider.overrideWith(
    (Ref _, String s) async => s == _a.seanceId
        ? const <EleveRoster>[
            EleveRoster(id: 'a1', prenom: 'Amina'),
            EleveRoster(id: 'a2', prenom: 'Youssef'),
          ]
        : const <EleveRoster>[EleveRoster(id: 'b1', prenom: 'Bilal')],
  ),
];

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group(
    'Capture : CTRL-SEANCE-1, faits et roster par seance',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      for (final (String l, Size taille, double densite)
          in <(String, Size, double)>[
            ('320x2', const Size(320, 700), 2),
            ('390', const Size(390, 844), 1),
            ('1440', const Size(1440, 900), 1),
          ]) {
        for (final (String th, ThemeMode mode) in <(String, ThemeMode)>[
          ('clair', ThemeMode.light),
          ('sombre', ThemeMode.dark),
        ]) {
          testWidgets('ctrl_seance1_faits_a_${l}_$th', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(
                CompteRenduControlePage(seanceId: _a.seanceId),
                themeMode: mode,
                surcharges: _surcharges(),
              ),
            );
            await stabiliser(tester);
            await _toucher(tester, find.text(t.controleur.compteRendu.faits));
            expect(
              find.text(
                t.controleur.compteRendu.presents(presents: 7, attendus: 8),
              ),
              findsOneWidget,
            );
            debugPrint(
              'PNG ${await capturer(tester, 'ctrl_seance1_faits_a_${l}_$th')}',
            );
          });

          testWidgets('ctrl_seance1_roster_a_${l}_$th', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(
                ObservationControlePage(seanceId: _a.seanceId),
                themeMode: mode,
                surcharges: _surcharges(),
              ),
            );
            await stabiliser(tester);
            await _toucher(
              tester,
              find.byKey(
                ObservationControlePage.cleNature(
                  NatureObservation.pointPositif,
                ),
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
                  PersonneConcernee.elevePrecis,
                ),
              ),
            );
            final Finder amina = find.text('Amina');
            expect(amina, findsOneWidget);
            expect(find.text('Bilal'), findsNothing);
            await tester.ensureVisible(amina);
            await stabiliser(tester);
            debugPrint(
              'PNG ${await capturer(tester, 'ctrl_seance1_roster_a_${l}_$th')}',
            );
          });
        }
      }
    },
  );
}
