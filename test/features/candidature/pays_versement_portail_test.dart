// PAYS-VERSEMENT (directeur, 15/11/2026) : apres l'envoi, le candidat change
// lui-meme le pays de son compte de versement depuis son portail ; la
// candidature n'est jamais refusee pour ce motif.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

CandidatureDossier _envoyee({
  IssueCandidature issue = IssueCandidature.enCours,
}) => CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.paiementNonDisponible,
  issue: issue,
  version: 4,
  questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 11, 10)),
);

Future<void> _monter(
  WidgetTester tester,
  CandidatureDossier candidature,
  FauxMaCandidature port, {
  Size taille = const Size(1440, 900),
}) async {
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = etatCandidat(candidature: candidature);
  await monterQuestionnaire(
    tester,
    port: port,
    depart: Routes.attente,
    taille: taille,
    dossier: dossier,
  );
}

void main() {
  for (final Size taille in <Size>[
    const Size(1440, 900),
    const Size(390, 844),
  ]) {
    testWidgets(
      'apres l envoi, le candidat change le pays de versement (${taille.width.toInt()})',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        await _monter(tester, _envoyee(), port, taille: taille);
        expect(_cle('pays-versement-lien'), findsOneWidget);
        await tester.ensureVisible(_cle('pays-versement-lien'));
        await tester.tap(_cle('pays-versement-lien'));
        await tester.pumpAndSettle();
        expect(
          find.text(t.recrutement.portail.paysVersementExplication),
          findsOneWidget,
        );
        // Pas de bouton tant qu'aucun pays n'est choisi.
        expect(_cle('pays-versement-enregistrer'), findsNothing);
        await tester.tap(_cle('pays-versement-FR'));
        await tester.pumpAndSettle();
        await tester.tap(_cle('pays-versement-enregistrer'));
        await tester.pumpAndSettle();
        expect(port.paysVersementModifies, <String>['FR']);
        expect(_cle('pays-versement-message'), findsOneWidget);
      },
    );
  }

  testWidgets('un refus du serveur se dit, rien n est change', (
    WidgetTester tester,
  ) async {
    final FauxMaCandidature port = FauxMaCandidature()
      ..erreurPaysVersement = const TransitionInterdite();
    await _monter(tester, _envoyee(), port);
    await tester.ensureVisible(_cle('pays-versement-lien'));
    await tester.tap(_cle('pays-versement-lien'));
    await tester.pumpAndSettle();
    await tester.tap(_cle('pays-versement-FR'));
    await tester.pumpAndSettle();
    await tester.tap(_cle('pays-versement-enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text(t.recrutement.portail.paysVersementInterdit),
      findsOneWidget,
    );
  });

  testWidgets('candidature refusee : aucun lien', (WidgetTester tester) async {
    await _monter(
      tester,
      _envoyee(issue: IssueCandidature.refusee),
      FauxMaCandidature(),
    );
    expect(_cle('pays-versement-lien'), findsNothing);
  });

  testWidgets('aucune reponse envoyee : aucun lien', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      const CandidatureDossier(
        existe: true,
        etape: EtapeCandidature.prequalification,
        etat: EtatCandidature.aCompleter,
        version: 1,
      ),
      FauxMaCandidature(),
    );
    expect(_cle('pays-versement-lien'), findsNothing);
  });

  // Captures R3 (sautees sans CAPTURE_DIR).
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String nom =
            'pays-versement-${taille.width.toInt()}-${langue.languageCode}';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            _envoyee(),
            FauxMaCandidature(),
            taille: taille,
          );
          await stabiliser(tester);
          await capturerVue(tester, 'PAYS-VERSEMENT/$nom-portail');
          await tester.ensureVisible(_cle('pays-versement-lien'));
          await tester.tap(_cle('pays-versement-lien'));
          await tester.pumpAndSettle();
          await tester.tap(_cle('pays-versement-FR'));
          await tester.pumpAndSettle();
          await capturerVue(tester, 'PAYS-VERSEMENT/$nom-panneau');
        });
      }
    }
  }, skip: sautSansCapture);
}
