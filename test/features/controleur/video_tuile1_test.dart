// VIDEO-TUILE-1 (revue du directeur du 02/10/2026) : dans la salle du
// controleur, a 320 et 390 px,
// - chaque tuile video reste entiere dans l'ecran, a 16 px du bord ;
// - chaque tuile finit 8 px au moins au-dessus du bandeau (SUPERPOS-1) ;
// - une tuile sans image pose le nom centre sous le cercle (a 1 px pres),
//   sans etiquette en bas a gauche ni « Sans image » ecrit.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

const Key _cercle = ValueKey<String>('tuile-sans-image-cercle');
const Key _nom = ValueKey<String>('tuile-sans-image-nom');

Future<void> _monter(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: cheminDemoSalleControleur,
    routes: routesDemoControleur('dev'),
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final double largeur in <double>[320, 390]) {
    testWidgets('salle du controleur, $largeur px : tuiles dans l\'ecran a '
        '16 px, nom centre sous le cercle', (WidgetTester tester) async {
      await _monter(tester, Size(largeur, 800));
      expect(tester.takeException(), isNull);

      final List<Element> cercles = find.byKey(_cercle).evaluate().toList();
      final List<Element> noms = find.byKey(_nom).evaluate().toList();
      expect(cercles, isNotEmpty);
      expect(noms.length, cercles.length);
      expect(find.text('Sans image'), findsNothing);
      final double bandeau = tester
          .getRect(find.byKey(PageImmersive.contenuKey))
          .bottom;

      for (int i = 0; i < cercles.length; i++) {
        final Rect rond = tester.getRect(find.byWidget(cercles[i].widget));
        final Rect nom = tester.getRect(find.byWidget(noms[i].widget));
        expect(
          (rond.center.dx - nom.center.dx).abs(),
          lessThanOrEqualTo(1),
          reason: 'nom $nom pas centre sous le cercle $rond',
        );
        expect(nom.top, greaterThanOrEqualTo(rond.bottom));

        final Rect tuile = tester.getRect(
          find
              .ancestor(
                of: find.byWidget(cercles[i].widget),
                matching: find.byType(ClipRRect),
              )
              .first,
        );
        expect(
          tuile.left,
          greaterThanOrEqualTo(16 - 0.5),
          reason: 'tuile $tuile trop pres du bord gauche',
        );
        expect(
          tuile.right,
          lessThanOrEqualTo(largeur - 16 + 0.5),
          reason: 'tuile $tuile trop pres du bord droit',
        );
        // SUPERPOS-1 : la tuile finit au-dessus du bandeau « Visite de
        // controle » (qui commence au bas de la zone de contenu), 8 px au
        // moins.
        expect(
          tuile.bottom,
          lessThanOrEqualTo(bandeau - 8),
          reason: 'tuile $tuile sous le bandeau ($bandeau)',
        );
        expect(tuile.inflate(0.5).contains(nom.topLeft), isTrue);
        expect(tuile.inflate(0.5).contains(nom.bottomRight), isTrue);
      }
    });
  }
}
