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

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
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
            // MA-CMD-1 (directeur, 02/10/2026), amende par ETATS-MA-1
            // (decision du 05/10/2026, WCAG 1.4.1) : au-dela de 130 %, les
            // commandes passent sur deux rangees ; les bascules gardent leur
            // mot d'etat sous le disque, la commande ordinaire (Quitter)
            // reste en icone seule, nom lu et en infobulle.
            final Finder dock = find.byKey(
              const ValueKey<String>('dock-seance'),
            );
            expect(
              find.descendant(
                of: dock,
                matching: find.byKey(
                  const ValueKey<String>('commandes-deux-rangees'),
                ),
              ),
              findsOneWidget,
            );
            final Finder boutonsDock = find.descendant(
              of: dock,
              matching: find.byType(BoutonAppel),
            );
            expect(boutonsDock, findsWidgets);
            for (final BoutonAppel b in tester.widgetList<BoutonAppel>(
              boutonsDock,
            )) {
              final Finder bouton = find.byWidget(b);
              final Finder mot = find.descendant(
                of: bouton,
                matching: find.byType(Text),
              );
              // Une bascule montre son mot d'etat ; une commande, rien.
              expect(
                mot,
                b.bascule == null ? findsNothing : findsOneWidget,
                reason: b.libelle,
              );
              if (b.bascule != null) {
                expect(tester.widget<Text>(mot).data, b.libelle);
              }
              expect(tester.getSize(bouton).height, greaterThanOrEqualTo(48));
              final String lu = b.libelleSemantique ?? b.libelle;
              // Le nom lu est l'acte ; le mot d'etat visible s'y ajoute.
              expect(
                find.bySemanticsLabel(RegExp('^${RegExp.escape(lu)}')),
                findsWidgets,
                reason: lu,
              );
            }
            expect(find.byTooltip(t.salle.seance.sortir), findsOneWidget);
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

  // Mesure faite avec les polices du depot, comme les autres mesures de mise
  // en page de la salle (information_controle_test) : la police de test
  // (Ahem, glyphes carres de 1 em) elargit chaque texte d'environ moitie et
  // fait passer la mention de l'en-tete sur trois lignes, ce qu'aucun ecran
  // reel ne montre. Mesure du 05/10/2026 a 390 x 844, texte x2 : en-tete 155
  // + commandes 88 = 243 pour une limite de 253,2 (avec Ahem : 272).
  group('MA-CMD-1 avec les vraies polices', () {
    setUpAll(chargerPolicesDuDepot);

    // MA-CMD-1 (directeur, 02/10/2026) : a 200 % et a 390 px, en-tete et
    // commandes tenaient dans 30 % de l'ecran ; les commandes se masquent et
    // une touche sur l'ecran les fait revenir. ETATS-MA-1 (decision du
    // 05/10/2026, option (a) : « le support cede un peu de hauteur ») : les
    // commandes passent sur deux rangees pour garder le mot d'etat ; la
    // borne passe a la moitie de l'ecran (mesure du 05/10/2026 : en-tete 155
    // + commandes 240 = 395 pour 422). Le support garde l'autre moitie, et
    // tout l'ecran quand les commandes se masquent.
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

      // Le lien « En savoir plus » (JUR-APP-1) est bien la : la mesure le
      // compte, il ne passe pas en etant cache.
      expect(find.text(t.salle.informationControle.lien), findsOneWidget);

      final double hauteurEntete = tester
          .getSize(find.byKey(const ValueKey<String>('entete-seance-compacte')))
          .height;
      final double hauteurCommandes = tester
          .getSize(find.byKey(CommandesMasquables.commandesKey))
          .height;
      expect(
        hauteurEntete + hauteurCommandes,
        lessThanOrEqualTo(844 * 0.50),
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

    // Q-3 = b (directeur, 05/10/2026) : sous 388 de large, le lien « En
    // savoir plus » n'est pas affiche. Mesures avec le lien (avant) : 31,3 %
    // a 320 x 690 texte x1,5 ; 30,8 % a 360 x 779 texte x2. Sans lien : 27,8 %
    // et 26,7 %. Integration du 08/10 avec ETATS-MA-1 (decision du
    // 05/10/2026, option (a)) : texte au-dela de 130 % en Mode Accessibilite,
    // les commandes passent sur deux rangees pour garder le mot d'etat et la
    // borne MA-CMD-1 passe a la moitie de l'ecran (comme le test 390 x 844
    // ci-dessus). Mesure du 08/10/2026, sans lien : 104 + 216 = 320 pour 690
    // (46,4 %) ; 120 + 240 = 360 pour 779 (46,2 %).
    for (final (Size taille, double echelle) in <(Size, double)>[
      (const Size(320, 690), 1.5),
      (const Size(360, 779), 2),
    ]) {
      testWidgets('MA-CMD-1 : ${taille.width.toInt()} x '
          '${taille.height.toInt()}, texte x$echelle, en-tete et commandes '
          '(deux rangees, ETATS-MA-1) dans 50 %, sans le lien', (
        WidgetTester tester,
      ) async {
        await _monter(tester, echelle: echelle, taille: taille);
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

        expect(find.text(t.salle.informationControle.lien), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('commandes-deux-rangees')),
          findsOneWidget,
        );
        final double hauteurEntete = tester
            .getSize(
              find.byKey(const ValueKey<String>('entete-seance-compacte')),
            )
            .height;
        final double hauteurCommandes = tester
            .getSize(find.byKey(CommandesMasquables.commandesKey))
            .height;
        expect(
          hauteurEntete + hauteurCommandes,
          lessThanOrEqualTo(taille.height * 0.50),
          reason: 'en-tete $hauteurEntete + commandes $hauteurCommandes',
        );
        expect(tester.takeException(), isNull);
      });
    }

    // m1 (verification d'ETATS-MA-1) : la meme borne, mesuree aussi au plus
    // petit ecran de reference, 320 x 568, texte x2. Resultat honnete de la
    // mesure du 08/10/2026 : en-tete 152 + commandes 240 = 392 pour une
    // borne de 284 (50 % de 568) : la borne N'EST PAS tenue a 320 x 568
    // (69 %). Les commandes se masquent (le support reprend alors tout
    // l'ecran) et une touche les rend. Ce test garde la mesure (pas de
    // regression au-dela de 70 %) et le masquage ; la borne a 320 x 568 est
    // rendue au directeur comme reste (DOCK-X2-1).
    // ZOOM-LIB-1 (09/10/2026) : mesure reprise, en-tete 120 + commandes 240
    // = 360 (63,4 %). Reduire l'en-tete seul ne peut pas tenir la borne :
    // les commandes laissent 284 - 240 = 44, moins que la cible du chevron
    // (48), et la mention, visible par principe (Children's Code), prend deux
    // lignes (64). L'en-tete compact est deja a son minimum (4 + 48 + 64 + 4).
    // La garde est resserree a la mesure actuelle.
    testWidgets('MA-CMD-1 : 320 x 568, texte x2, borne mesuree (m1)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(320, 568), echelle: 2);
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
      final double total = hauteurEntete + hauteurCommandes;
      debugPrint(
        'MESURE m1 320x568 x2 : en-tete $hauteurEntete + commandes '
        '$hauteurCommandes = $total pour une borne de ${568 * 0.50}',
      );
      // La borne de 50 % n'est pas tenue ici (voir plus haut) ; on garde
      // la mesure contre toute regression.
      expect(total, lessThanOrEqualTo(360.5), reason: 'regression');

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
      await tester.tapAt(const Offset(160, 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(opacite(), 1);
      expect(tester.takeException(), isNull);
    });
  });
}
