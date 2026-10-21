// CTRL-SALLE-1 (revue du directeur) : la salle vue par le controleur.
// - Les avatars restent dans leur tuile, a 320 et 390 px.
// - La mention « visite de controle possible » n'est pas rendue au
//   controleur (les roles enseignant et eleve la gardent : salle_test.dart).
// - Un seul controle a la fois par Classe : une salle deja controlee ne
//   propose pas « Commencer le controle » et dit quoi faire (K-59).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

Future<void> _monter(
  WidgetTester tester,
  String route,
  Size taille, {
  double texte = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: route,
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
          builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: TextScaler.linear(texte)),
            child: enfant!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Avatars de la salle du controleur, dans leur tuile', () {
    for (final double largeur in <double>[320, 390]) {
      // Texte x1 seulement : a x2, c'est la coquille `PageImmersive` entiere
      // qui deborde (bandeau et commandes), hors du perimetre de cette etape
      // (signale au pilotage).
      for (final double texte in <double>[1]) {
        testWidgets('$largeur px, texte x$texte', (WidgetTester tester) async {
          await _monter(
            tester,
            cheminDemoSalleControleur,
            Size(largeur, 800),
            texte: texte,
          );
          expect(tester.takeException(), isNull);
          final Finder avatars = find.byType(AvatarTile);
          expect(avatars, findsWidgets);
          for (final Element avatar in avatars.evaluate()) {
            // La tuile : le premier `ClipRRect` qui enveloppe l'avatar.
            final Finder tuile = find
                .ancestor(
                  of: find.byWidget(avatar.widget),
                  matching: find.byType(ClipRRect),
                )
                .first;
            final Rect cadre = tester.getRect(tuile);
            final Rect rond = tester.getRect(find.byWidget(avatar.widget));
            expect(
              cadre.inflate(0.5).contains(rond.topLeft) &&
                  cadre.inflate(0.5).contains(rond.bottomRight),
              isTrue,
              reason: 'avatar $rond hors de sa tuile $cadre',
            );
            // Un petit cercle : jamais plus de la moitie de la tuile.
            expect(rond.width, lessThanOrEqualTo(cadre.width / 2));
          }
        });
      }
    }
  });

  testWidgets('La mention permanente n est pas rendue au controleur', (
    WidgetTester tester,
  ) async {
    await _monter(tester, cheminDemoSalleControleur, const Size(390, 844));
    expect(find.text(t.salle.bandeauControle), findsOneWidget);
    expect(find.byType(PermanentNotice), findsNothing);
    expect(find.text(t.salle.bandeauPermanent), findsNothing);
  });

  group('Un seul controle a la fois par Classe', () {
    testWidgets('salle deja controlee : aucun bouton, un message clair', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(
          EcranDemoControleur.controle,
          etat: EtatDemoControleur.dejaControlee,
        ),
        const Size(390, 844),
      );
      expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
      expect(find.text(t.controleur.controle.commencer), findsNothing);
      expect(find.byKey(ControleControleurPage.dejaControleeKey), findsOne);
      expect(
        find.text('Un contrôle est déjà en cours dans cette classe.'),
        findsOneWidget,
      );
      // Quoi faire maintenant (K-59).
      expect(find.text(t.controleur.controle.dejaEnCoursAide), findsOneWidget);
    });

    testWidgets('salle libre : « Commencer le controle » reste propose', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(EcranDemoControleur.controle),
        const Size(390, 844),
      );
      expect(find.byKey(ControleControleurPage.commencerKey), findsOneWidget);
      expect(find.byKey(ControleControleurPage.dejaControleeKey), findsNothing);
    });
  });
}
