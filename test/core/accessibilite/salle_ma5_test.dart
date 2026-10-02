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
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';

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
          // La carte du support : a 200 %, la vignette de l'enseignant passe
          // au-dessus du texte, qui prend toute la largeur (aucun mot coupe) ;
          // a 100 %, elle reste posee en coin.
          final Finder pile = find.byKey(
            const ValueKey<String>('vignette-support-pile'),
          );
          if (echelle >= 2) {
            // MA-CMD-1 (directeur, 02/10/2026, annule M1) : icones seules,
            // sans libelle visible ; chaque commande garde son nom pour le
            // lecteur d'ecran et une infobulle.
            final Finder dock = find.byKey(
              const ValueKey<String>('dock-seance'),
            );
            final Finder boutonsDock = find.descendant(
              of: dock,
              matching: find.byType(BoutonAppel),
            );
            expect(boutonsDock, findsWidgets);
            for (int i = 0; i < boutonsDock.evaluate().length; i++) {
              expect(
                find.descendant(
                  of: boutonsDock.at(i),
                  matching: find.byType(Text),
                ),
                findsNothing,
              );
              expect(
                tester.getSize(boutonsDock.at(i)).height,
                greaterThanOrEqualTo(48),
              );
            }
            final List<Tooltip> bulles = tester
                .widgetList<Tooltip>(
                  find.descendant(of: dock, matching: find.byType(Tooltip)),
                )
                .toList();
            expect(find.byTooltip(t.salle.seance.sortir), findsOneWidget);
            expect(bulles, hasLength(boutonsDock.evaluate().length));
            for (final Tooltip bulle in bulles) {
              expect(find.bySemanticsLabel(bulle.message!), findsWidgets);
            }
            expect(pile, findsOneWidget);
            final Finder chapitre = find.textContaining('Chapitre');
            expect(chapitre, findsWidgets);
            expect(
              tester.getTopLeft(chapitre.first).dy,
              greaterThanOrEqualTo(tester.getBottomLeft(pile).dy),
            );
          } else {
            expect(pile, findsNothing);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  // MA-CMD-1 (directeur, 02/10/2026) : a 200 % et a 390 px, en-tete et
  // commandes tiennent dans 30 % de l'ecran ; les commandes se masquent et
  // une touche sur l'ecran les fait revenir.
  testWidgets('MA-CMD-1 : 390, texte x2, commandes compactes et masquables', (
    WidgetTester tester,
  ) async {
    await _monter(tester, echelle: 2);
    final Finder rejoindre = find.text(LibellesGroupe.rejoindre);
    await tester.ensureVisible(rejoindre);
    await tester.tap(rejoindre);
    await stabiliser(tester);
    final Finder entrer = find.byKey(
      const ValueKey<String>('preparation-entrer'),
    );
    await tester.ensureVisible(entrer);
    await tester.tap(entrer);
    await tester.pump(const Duration(milliseconds: 500));

    final double hauteurEntete = tester
        .getSize(find.byKey(const ValueKey<String>('entete-seance-compacte')))
        .height;
    final double hauteurCommandes = tester
        .getSize(find.byKey(CommandesMasquables.commandesKey))
        .height;
    expect(
      hauteurEntete + hauteurCommandes,
      lessThanOrEqualTo(844 * 0.30),
      reason: 'en-tete $hauteurEntete + commandes $hauteurCommandes',
    );

    double opacite() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(CommandesMasquables.commandesKey),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(opacite(), 1);
    await tester.pump(CommandesMasquables.delaiParDefaut);
    await tester.pump(const Duration(seconds: 1));
    expect(opacite(), 0);
    // Une touche au milieu de l'ecran (sur le support) les fait revenir.
    await tester.tapAt(const Offset(195, 400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacite(), 1);
    expect(find.byTooltip(t.salle.seance.sortir), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
