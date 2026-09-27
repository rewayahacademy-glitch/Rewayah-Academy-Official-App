// MA-5 : l'entree et la salle en Mode Accessibilite. On ouvre la VRAIE route
// de demonstration /demo/accessibilite au moment « fenetre ouverte », on tape
// « Rejoindre » (preparation guidee), puis « Entrer dans la classe » : la
// salle de l'eleve guide, sans navigation d'app ni commande hors de la salle
// existante ; l'observation dit « Ton parent… » a la mineure seulement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../../router/support_routeur.dart' show stabiliser;

Future<void> _monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  EleveDemoAccessibilite eleve = EleveDemoAccessibilite.mariam,
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoAccessibilite(
      eleve,
      moment: MomentDemoAccessibilite.fenetre,
    ),
    routes: routesDemoAccessibilite('local'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp.router(
            routerConfig: routeur,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

void main() {
  for (final (EleveDemoAccessibilite eleve, bool mineur)
      in <(EleveDemoAccessibilite, bool)>[
        (EleveDemoAccessibilite.mariam, true),
        (EleveDemoAccessibilite.idriss, false),
      ]) {
    for (final double echelle in <double>[1, 2]) {
      testWidgets(
        'MA-5 : ${eleve.name}, texte x$echelle, Rejoindre puis la salle',
        (WidgetTester tester) async {
          await _monter(tester, eleve: eleve, echelle: echelle);
          final Finder rejoindre = find.text(LibellesGroupe.rejoindre);
          expect(rejoindre, findsOneWidget);
          await tester.ensureVisible(rejoindre);
          await tester.tap(rejoindre);
          await stabiliser(tester);

          // La preparation guidee : le bouton de l'etape est atteignable.
          final Finder entrer = find.byKey(
            const ValueKey<String>('preparation-entrer'),
          );
          expect(entrer, findsOneWidget);
          await tester.ensureVisible(entrer);
          await tester.tap(entrer);
          await stabiliser(tester);

          // La salle : aucune navigation d'app, les commandes de l'eleve.
          expect(find.byType(NavShell), findsNothing);
          expect(find.text(t.salle.seance.titreGuidee), findsOneWidget);
          // Le micro est present (a 200 %, le libelle peut se replier en
          // icone : on le trouve par sa cle).
          expect(
            find.byKey(const ValueKey<String>('bouton-micro')),
            findsOneWidget,
          );
          for (final String interdit in <String>[
            'Lever la main',
            'Discussion',
            'Participants',
          ]) {
            expect(find.text(interdit), findsNothing);
          }
          // Observation : la phrase existante, tutoiement selon l'age ; un
          // adulte n'est pas concerne par une observation parentale.
          expect(
            find.text(t.salle.seance.tonParentObserve),
            mineur ? findsOneWidget : findsNothing,
          );
          expect(find.text(t.salle.seance.votreParentObserve), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  // L'eleve courant de la salle suit celui de la demonstration : Idriss ne
  // voit jamais « M Mariam » en haut a droite sur bureau.
  testWidgets('MA-5 : la salle d\'Idriss sur bureau porte son prenom', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      eleve: EleveDemoAccessibilite.idriss,
      taille: const Size(1440, 900),
    );
    await tester.tap(find.text(LibellesGroupe.rejoindre));
    await stabiliser(tester);
    final Finder entrer = find.byKey(
      const ValueKey<String>('preparation-entrer'),
    );
    await tester.ensureVisible(entrer);
    await tester.tap(entrer);
    await stabiliser(tester);
    expect(find.text(t.salle.seance.titreGuidee), findsOneWidget);
    expect(find.text('Mariam'), findsNothing);
    expect(find.text('M'), findsNothing);
    expect(find.text('I'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
