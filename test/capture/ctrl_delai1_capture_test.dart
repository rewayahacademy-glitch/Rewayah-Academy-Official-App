// CTRL-DELAI-1 : le compte rendu apres un serveur muet (delai maximal
// depasse) : « non confirme », Reessayer, « Plus tard » disponible ; a
// 320 x2, 390 et 1440, clair et sombre. Jamais sans `CAPTURE_DIR` (voir
// test/capture/LISEZ-MOI.md).

import 'dart:async';

import 'package:flutter/material.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';

import 'outil_capture.dart';

/// Un port dont aucun appel ne recoit jamais de reponse.
class _PortMuet implements EnvoiCompteRendu {
  @override
  Future<void> transmettreVisite(String seanceId) => Completer<void>().future;

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) =>
      Completer<void>().future;

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) => Completer<void>().future;
}

final CompteRenduEnSuspens _visite = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
);

void main() {
  group('Capture : CTRL-DELAI-1, serveur muet', skip: sautSansCapture, () {
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
        testWidgets('ctrl_delai1_${l}_$th', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              CompteRenduControlePage(seanceId: _visite.seanceId),
              themeMode: mode,
              surcharges: <Override>[
                visitesObserveesProvider.overrideWith(
                  () => VisitesObservees(<String, CompteRenduEnSuspens>{
                    _visite.seanceId: _visite,
                  }),
                ),
                envoiCompteRenduProvider.overrideWithValue(_PortMuet()),
              ],
            ),
          );
          await stabiliser(tester);
          final Finder rien = find.byKey(
            CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
          );
          await tester.ensureVisible(rien);
          await stabiliser(tester);
          await tester.tap(rien);
          await stabiliser(tester);
          final Finder envoyer = find.byKey(CompteRenduControlePage.actionKey);
          await tester.ensureVisible(envoyer);
          await stabiliser(tester);
          await tester.tap(envoyer);
          await stabiliser(tester);
          await tester.pump(AppDelais.requeteMax);
          await stabiliser(tester);
          final Finder echec = find.text(t.controleur.compteRendu.echecRien);
          expect(echec, findsOneWidget);
          await tester.ensureVisible(echec);
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, 'ctrl_delai1_${l}_$th')}');
        });
      }
    }
  });
}
