// BE-DOSSIER-2 (16/11/2026) : captures du dossier corrige, 360 et 1366,
// francais et arabe, en haut puis EN DEFILANT JUSQU'AU BOUT (la derniere
// capture montre la fin de la page). Donnees fictives. Saute sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../features/admin_candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

FauxCandidaturesDirection _port() => FauxCandidaturesDirection(
  capacitesRendues: capacitesGestes,
  details: <DetailCandidature>[
    detailTest(
      paiement: EtatVersement.compatible,
      controles: const <ControleCandidature>[
        ControleCandidature(nom: 'paiement_compatible', valeur: true),
        ControleCandidature(nom: 'accords_signes', valeur: true),
        ControleCandidature(nom: 'cadre_religieux', valeur: true),
        ControleCandidature(nom: 'entretien_conclu', valeur: false),
        ControleCandidature(nom: 'piece_validee', valeur: false),
      ],
    ),
  ],
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  Future<void> prises(
    WidgetTester tester,
    String nom, {
    required double largeur,
    required AppLocale langue,
  }) async {
    masquerRubanDebug();
    await tester.runAsync(() => LocaleSettings.setLocale(langue));
    await monterCandidature(
      tester,
      port: _port(),
      largeur: largeur,
      hauteur: largeur < 600 ? 800 : 768,
      direction: langue == AppLocale.ar ? TextDirection.rtl : null,
      ouvrirRubriques: false,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await capturerVue(tester, 'BE-DOSSIER-2/${nom}_haut');
    final ScrollableState s = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    s.position.jumpTo(s.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 500));
    await capturerVue(tester, 'BE-DOSSIER-2/${nom}_fin');
  }

  group('BE-DOSSIER-2 : captures', skip: sautSansCapture, () {
    testWidgets('360 fr', (WidgetTester t) async {
      await prises(t, 'dossier2_360_fr', largeur: 360, langue: AppLocale.fr);
    });
    testWidgets('1366 fr', (WidgetTester t) async {
      await prises(t, 'dossier2_1366_fr', largeur: 1366, langue: AppLocale.fr);
    });
    testWidgets('360 ar', (WidgetTester t) async {
      await prises(t, 'dossier2_360_ar', largeur: 360, langue: AppLocale.ar);
    });
    testWidgets('1366 ar', (WidgetTester t) async {
      await prises(t, 'dossier2_1366_ar', largeur: 1366, langue: AppLocale.ar);
    });
  });
}
