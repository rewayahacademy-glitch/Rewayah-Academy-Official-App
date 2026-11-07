// SALLE-2-ENTRETIEN (07/11/2026) : sur le portail (`/attente`), l'en-tete de
// la salle mene a « Faisons connaissance » quand l'entretien est a fixer ou
// fixe, et seulement alors (jamais en pause, apres un refus, ni avant).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/portail_candidature.dart';

import '../../support/monter_recrutement.dart';

Future<void> _monter(WidgetTester tester, CandidatureDossier c) =>
    monterRecrutement(
      tester,
      chemin: '/attente',
      ecran: (_) => Scaffold(body: EnteteSalle(candidature: c)),
      autres: <String>['/attente/entretien'],
    );

CandidatureDossier _en(EtatCandidature etat, {bool pause = false}) =>
    CandidatureDossier(
      existe: true,
      etape: EtapeCandidature.verifications,
      etat: etat,
      version: 3,
      enPause: pause,
    );

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final e = t.recrutement.entretien;

  testWidgets('a fixer : « Choisir le moment », qui mene a la page', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _en(EtatCandidature.entretienAPlanifier));
    expect(find.text(e.portailChoisir), findsOneWidget);
    await tester.tap(find.byKey(EnteteSalle.entretienKey));
    await laisser(tester);
    expect(find.byKey(EnteteSalle.entretienKey), findsNothing);
  });

  testWidgets('fixe : « Voir mon entretien »', (WidgetTester tester) async {
    await _monter(tester, _en(EtatCandidature.entretienPlanifie));
    expect(find.text(e.portailVoir), findsOneWidget);
  });

  testWidgets('decision en attente, en pause : aucun lien', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _en(EtatCandidature.decisionEnAttente));
    expect(find.byKey(EnteteSalle.entretienKey), findsNothing);
    await _monter(
      tester,
      _en(EtatCandidature.entretienAPlanifier, pause: true),
    );
    expect(find.byKey(EnteteSalle.entretienKey), findsNothing);
  });
}
