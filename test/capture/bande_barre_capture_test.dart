// BANDE-BARRE (garde-cap, 11/11/2026, decision du directeur) : relever les
// ecrans sous NavShell ou une bande de couleur se voit sous la barre
// flottante. Vrai routeur, sessions de test (aucune donnee reelle), 390 x
// 844, clair et sombre, tuteur d'abord. Prefixe lu dans `CAPTURE_PREFIXE`
// (« apres » par defaut).
//
// Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart' show FausseSourceSession;
import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;

final String _prefixe = () {
  final String? brut = Platform.environment['CAPTURE_PREFIXE'];
  return brut == null || brut.trim().isEmpty ? 'apres' : brut.trim();
}();

final List<(AppRole, String, String)> _ecrans = <(AppRole, String, String)>[
  (AppRole.guardian, 'tuteur_accueil', Routes.tuteurAccueil),
  (AppRole.guardian, 'tuteur_foyer', Routes.tuteurFoyer),
  (AppRole.guardian, 'tuteur_historique', Routes.tuteurSuivi),
  (AppRole.guardian, 'tuteur_compte', Routes.tuteurCompte),
  (AppRole.teacher, 'enseignant_journee', Routes.enseignantJournee),
  (AppRole.teacher, 'enseignant_classes', Routes.enseignantClasses),
  (AppRole.teacher, 'enseignant_messages', Routes.enseignantMessages),
  (AppRole.teacher, 'enseignant_profil', Routes.enseignantProfil),
  (AppRole.student, 'eleve_accueil', Routes.eleve),
  (AppRole.student, 'eleve_suivi', Routes.eleveSuivi),
  (AppRole.controller, 'controleur', Routes.controleur),
  (AppRole.controller, 'controleur_historique', Routes.controleurHistorique),
];

void main() {
  group('Capture : bande sous la barre', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (AppRole role, String nom, String chemin) in _ecrans) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String t = theme == ThemeMode.light ? 'clair' : 'sombre';
        testWidgets('$nom $t', (WidgetTester tester) async {
          await monterRouteur(
            tester,
            chemin,
            source: FausseSourceSession(sessionActive(role)),
            themeMode: theme,
          );
          for (int i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          debugPrint(
            'PNG ${await capturerVue(tester, 'bande_${_prefixe}_${nom}_$t')}',
          );
          // Le contenu defile : il doit passer SOUS la barre flottante,
          // jamais s'arreter net au bord d'un rectangle.
          final Finder defilant = find.byType(Scrollable);
          // Seule une page plus longue que l'ecran passe sous la barre.
          final bool longue =
              defilant.evaluate().isNotEmpty &&
              tester
                      .state<ScrollableState>(defilant.first)
                      .position
                      .maxScrollExtent >
                  0;
          if (longue) {
            await tester.drag(defilant.first, const Offset(0, -260));
            for (int i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            debugPrint(
              'PNG ${await capturerVue(tester, 'bande_${_prefixe}_${nom}_${t}_defile')}',
            );
            // Tout en bas : la fin du contenu s'arrete au-dessus de la barre.
            await tester.drag(defilant.first, const Offset(0, -6000));
            for (int i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 200));
            }
            debugPrint(
              'PNG ${await capturerVue(tester, 'bande_${_prefixe}_${nom}_${t}_fin')}',
            );
          }
          // Les minuteries des ecrans (squelettes, horloges) se soldent.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 1));
        });
      }
    }
  });
}
