import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

/// PE-A3 (20/11/2026) : l'etape d'usage commence par deux portes,
/// « Apprendre » et « Enseigner ». Touche [titre], puis « Continuer ».
Future<void> passerLaPorte(WidgetTester tester, String titre) async {
  Future<void> toucher(Finder cible) async {
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
    await tester.tap(cible);
    await tester.pumpAndSettle();
  }

  await toucher(find.text(titre));
  await toucher(find.text(t.commun.continuer));
}

/// Passe la porte « Apprendre » : les cartes « pour moi » / « mon enfant ».
Future<void> passerApprendre(WidgetTester tester) =>
    passerLaPorte(tester, t.inscription.porte.apprendreTitre);

/// Passe la porte « Enseigner » : le parcours de candidature.
Future<void> passerEnseigner(WidgetTester tester) =>
    passerLaPorte(tester, t.inscription.porte.enseignerTitre);
