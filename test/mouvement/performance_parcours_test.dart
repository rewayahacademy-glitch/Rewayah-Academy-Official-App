// P2-16 : mesure de performance des animations sur 3 parcours du role
// Tuteur. Compte les images dessinees jusqu'a la fin des animations
// (pumpAndSettle renvoie ce nombre) et verifie qu'elles restent bornees,
// puis qu'aucune animation ne tourne encore une fois stabilise.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

/// Sous 40 images (environ 0,7 s a 60 i/s), large marge au-dessus des
/// 280 ms de transition de page les plus longues du socle de mouvement.
const int _bornePumpAndSettle = 40;

void main() {
  group('Performance des parcours animes (P2-16)', () {
    testWidgets('ouverture de l Accueil : images bornees, rien ne tourne '
        'apres stabilisation', (WidgetTester tester) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.tuteurAccueil,
        source: FausseSourceSession(sessionActive(AppRole.guardian)),
      );
      expect(lieu(routeur), Routes.tuteurAccueil);

      final int images = await tester.pumpAndSettle();
      expect(
        images,
        lessThan(_bornePumpAndSettle),
        reason: 'Ouverture Accueil : trop d images dessinees avant '
            'stabilisation.',
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('Accueil -> Foyer -> fiche : images bornees a chaque '
        'etape, rien ne tourne a la fin', (WidgetTester tester) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.tuteurAccueil,
        source: FausseSourceSession(sessionActive(AppRole.guardian)),
      );

      routeur.go(Routes.tuteurFoyer);
      final int versFoyer = await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.tuteurFoyer);
      expect(versFoyer, lessThan(_bornePumpAndSettle));
      expect(tester.binding.hasScheduledFrame, isFalse);

      routeur.go(Routes.ficheElevePour('e1'));
      final int versFiche = await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.ficheElevePour('e1'));
      expect(versFiche, lessThan(_bornePumpAndSettle));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('ouverture de l Historique : images bornees, rien ne '
        'tourne apres stabilisation', (WidgetTester tester) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.tuteurSuivi,
        source: FausseSourceSession(sessionActive(AppRole.guardian)),
      );
      expect(lieu(routeur), Routes.tuteurSuivi);

      final int images = await tester.pumpAndSettle();
      expect(
        images,
        lessThan(_bornePumpAndSettle),
        reason: 'Ouverture Historique : trop d images dessinees avant '
            'stabilisation.',
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
