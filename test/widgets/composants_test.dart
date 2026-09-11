import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_elevation.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/bento_tile.dart';
import 'package:rewayah_academy/core/widgets/child_card.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/local_feedback.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/disponibilites/grille_semaine.dart';

import '../support/harnais.dart';

/// L'hote des composants, avec un reseau fige.
Widget hoteComposant(
  Widget enfant, {
  InterfaceMode mode = InterfaceMode.standard,
}) => hote(
  Scaffold(body: enfant),
  mode: mode,
  surcharges: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  ],
);

/// La palette, pour comparer une couleur rendue a un jeton.
final AppPalette palette = AppPalette.claire();

/// La decoration du premier `Container` ou `DecoratedBox` sous [dessous].
BoxDecoration decorationSous(WidgetTester tester, Finder dessous) {
  final Iterable<Widget> boites = tester.widgetList(
    find.descendant(
      of: dessous,
      matching: find.byWidgetPredicate(
        (Widget w) =>
            (w is Container && w.decoration is BoxDecoration) ||
            (w is DecoratedBox && w.decoration is BoxDecoration),
      ),
    ),
  );
  final Widget premier = boites.first;
  return premier is Container
      ? premier.decoration! as BoxDecoration
      : (premier as DecoratedBox).decoration as BoxDecoration;
}

void main() {
  group('Pressable : le survol et le focus, ajoutes au lot C', () {
    testWidgets('une zone pressable prend le focus et repond a Entree', (
      WidgetTester tester,
    ) async {
      int presses = 0;
      await tester.pumpWidget(
        hoteComposant(
          Pressable(
            onPress: () => presses++,
            libelleSemantique: 'Continuer',
            autofocus: true,
            child: const Text('Continuer'),
          ),
        ),
      );
      await tester.pump();

      // Un anneau de focus qui ne menerait a rien serait pire qu'un focus
      // absent : la touche Entree doit declencher l'action.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(presses, 1);
    });

    testWidgets('une zone inerte ne prend pas le focus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const Pressable(
            onPress: null,
            libelleSemantique: 'Continuer',
            autofocus: true,
            child: Text('Continuer'),
          ),
        ),
      );
      await tester.pump();

      final FocusableActionDetector detecteur = tester.widget(
        find.byType(FocusableActionDetector),
      );
      expect(detecteur.enabled, isFalse);
    });

    testWidgets('le forcage d etat peint le survol sans souris', (
      WidgetTester tester,
    ) async {
      // C'est ce qui rend la galerie possible : sans lui, les etats de survol
      // et de focus ne seraient visibles qu'en promenant une souris.
      await tester.pumpWidget(
        hoteComposant(
          const PressionForcee(
            etat: EtatPression(survole: true),
            child: AppCard(onPress: _rien, child: Text('Une carte')),
          ),
        ),
      );

      final BoxDecoration d = decorationSous(tester, find.byType(AppCard));
      // Survolee, la carte porte le filet FORT et l'ombre de niveau 2.
      expect(d.border, isNotNull);
      expect(d.boxShadow, AppElevation.niveau2(palette.ombre));
    });
  });

  group('ActionPrincipale : quatre niveaux, pas cinq', () {
    testWidgets('le niveau principal est le seul aplat sature', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const ActionPrincipale(libelle: 'Continuer', onPress: _rien),
        ),
      );
      final BoxDecoration d = decorationSous(
        tester,
        find.byType(ActionPrincipale),
      );
      expect(d.color, palette.surfacePrimary.background);
    });

    testWidgets('le destructif n a jamais de fond rouge plein', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const ActionPrincipale(
            libelle: 'Retirer Aicha',
            niveau: NiveauAction.destructive,
            onPress: _rien,
          ),
        ),
      );
      final BoxDecoration d = decorationSous(
        tester,
        find.byType(ActionPrincipale),
      );
      expect(d.color, isNull);
      expect(d.color, isNot(palette.surfaceAlert.background));
    });

    testWidgets('le secondaire porte le contour porteur de sens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const ActionPrincipale(
            libelle: 'Refuser',
            niveau: NiveauAction.secondaire,
            onPress: _rien,
          ),
        ),
      );
      final BoxDecoration d = decorationSous(
        tester,
        find.byType(ActionPrincipale),
      );
      expect(d.color, palette.surfaceRaised.background);
      expect(d.border!.top.color, palette.borderStrong.asBorderSide().color);
    });

    testWidgets('un bouton inerte change de paire, jamais d opacite', (
      WidgetTester tester,
    ) async {
      // Baisser l'opacite ferait tomber tout le sous-arbre sous le seuil de
      // contraste : l'inertie se dit par la surface enfoncee.
      await tester.pumpWidget(
        hoteComposant(
          const ActionPrincipale(libelle: 'Continuer', onPress: null),
        ),
      );
      final BoxDecoration d = decorationSous(
        tester,
        find.byType(ActionPrincipale),
      );
      // Le lot T2 a change la paire de l'inerte, et ce test avait garde
      // l'ancienne : `surfaceSunken` ne mesurait que 1,06:1 d'ecart avec le
      // fond, si bien que le bouton le plus important de l'ecran disparaissait
      // au premier champ vide et se lisait comme une panne. Il reste desormais
      // sur `surfaceRaised`, avec le filet le plus epais du produit -- plus
      // lourd qu'un secondaire au repos, qui porte 2.
      expect(d.color, palette.surfaceRaised.background);
      expect(d.color, isNot(palette.surfaceSunken.background));
      expect(d.border!.top.color, palette.borderStrong.asBorderSide().color);
      expect(d.border!.top.width, 3);
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('AppCard : une surface elevee porte un filet ET une ombre', () {
    testWidgets('au repos, filet decoratif et ombre de niveau 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(const AppCard(child: Text('Une carte'))),
      );
      final BoxDecoration d = decorationSous(tester, find.byType(AppCard));
      expect(d.color, palette.surfaceRaised.background);
      expect(d.boxShadow, AppElevation.niveau1(palette.ombre));
      expect(d.border!.top.color, palette.borderHairline.asBorderSide().color);
    });

    testWidgets('retenue, le contour passe au filet porteur de sens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const AppCard(selectionnee: true, child: Text('Une carte')),
        ),
      );
      final BoxDecoration d = decorationSous(tester, find.byType(AppCard));
      expect(d.border!.top.color, palette.borderStrong.asBorderSide().color);
    });
  });

  group('Skeleton : rien avant 200 ms', () {
    testWidgets('il n affiche rien pendant le delai', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(const Skeleton(hauteur: AppSpacing.section)),
      );
      await tester.pump();
      expect(find.byType(DecoratedBox), findsNothing);

      // Juste avant l'echeance, toujours rien.
      await tester.pump(
        AppMouvement.delaiSquelette - const Duration(milliseconds: 1),
      );
      expect(find.byType(DecoratedBox), findsNothing);

      await tester.pump(const Duration(milliseconds: 2));
      expect(find.byType(DecoratedBox), findsOneWidget);
    });

    testWidgets('la forme du texte raccourcit sa derniere ligne', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(const Skeleton.texte(differe: false)),
      );
      final List<FractionallySizedBox> blocs = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .toList();
      expect(blocs.length, 3);
      expect(blocs.first.widthFactor, 1);
      expect(blocs.last.widthFactor, lessThan(1));
    });
  });

  group('LocalFeedback : 3 secondes, puis il s efface', () {
    testWidgets('il disparait de lui-meme', (WidgetTester tester) async {
      await tester.pumpWidget(
        hoteComposant(const LocalFeedback(message: 'Creneau ajoute')),
      );
      await tester.pump();
      expect(find.text('Creneau ajoute'), findsOneWidget);

      await tester.pump(AppMouvement.retourLocalMaintien);
      await tester.pumpAndSettle();
      expect(find.text('Creneau ajoute'), findsNothing);
    });

    testWidgets('le persistant reste : c est le cas de la file hors ligne', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const LocalFeedback(message: 'En file', persistant: true),
        ),
      );
      await tester.pump(AppMouvement.retourLocalMaintien * 2);
      await tester.pump();
      expect(find.text('En file'), findsOneWidget);
    });

    testWidgets('sans message, il n occupe aucune place', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(const LocalFeedback(message: null)),
      );
      await tester.pump();
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('sous mouvement reduit, la duree d apparition reste pleine', (
      WidgetTester tester,
    ) async {
      // « Retour local | Inchange, sans translation » (04-systeme-mouvement.md
      // section 5) : la seule ligne du tableau qui garde 200 / 160 ms au lieu
      // de retomber a 120. Seule la translation tombe a zero.
      await tester.pumpWidget(
        hote(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: LocalFeedback(message: 'Creneau ajoute')),
          ),
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      final AnimatedSwitcher bascule = tester.widget(
        find.byType(AnimatedSwitcher),
      );
      expect(bascule.duration, AppMouvement.apparition);
      expect(bascule.reverseDuration, AppMouvement.micro);
    });
  });

  group('StatusPill : jamais la couleur seule', () {
    testWidgets('la pastille est toujours accompagnee de son mot', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
        ),
      );
      expect(find.text(t.etat.enDirect), findsOneWidget);
    });

    testWidgets('le lecteur d ecran lit le mot, pas la couleur', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await tester.pumpWidget(
        hoteComposant(StatusPill(libelle: t.etat.annule, ton: TonEtat.alerte)),
      );
      expect(find.bySemanticsLabel(t.etat.annule), findsOneWidget);
      poignee.dispose();
    });

    testWidgets('le fond est doux, la pastille seule est saturee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
        ),
      );
      final BoxDecoration d = decorationSous(tester, find.byType(StatusPill));
      expect(d.color, palette.washSuccess.background);
    });
  });

  group('StatTile : le zero s affiche comme les autres valeurs', () {
    testWidgets('zero est rendu, jamais masque', (WidgetTester tester) async {
      await tester.pumpWidget(
        hoteComposant(const StatTile(valeur: 0, libelle: 'Dossiers')),
      );
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('le chiffre est tabulaire', (WidgetTester tester) async {
      // Sans `tnum`, un compteur qui passe de 17 a 18 fait bouger la ligne.
      await tester.pumpWidget(
        hoteComposant(const StatTile(valeur: 17, libelle: 'Foyers')),
      );
      final Text chiffre = tester.widget(find.text('17'));
      expect(
        chiffre.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('NavShell : une seule liste, trois formes', () {
    Widget coquille(double largeur, int destinations) => hoteComposant(
      MediaQuery(
        data: MediaQueryData(size: Size(largeur, 800)),
        child: NavShell(
          destinations: <Destination>[
            for (int i = 0; i < destinations; i++)
              Destination(
                libelle: 'D$i',
                icone: AppIcons.foyer,
                chemin: '/d$i',
              ),
          ],
          indexActif: 0,
          onAller: _allerNullePart,
          child: const Text('contenu'),
        ),
      ),
    );

    testWidgets('sous 600, la barre est en bas', (WidgetTester tester) async {
      await tester.pumpWidget(coquille(390, 3));
      final Offset barre = tester.getCenter(find.text('D0'));
      final Offset contenu = tester.getCenter(find.text('contenu'));
      expect(barre.dy, greaterThan(contenu.dy));
    });

    testWidgets('au dela de 600, la navigation passe sur le cote', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(coquille(768, 3));
      final Offset rail = tester.getCenter(find.text('D0'));
      final Offset contenu = tester.getCenter(find.text('contenu'));
      expect(rail.dx, lessThan(contenu.dx));
    });

    testWidgets('la barre laterale est plus large que le rail', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(coquille(768, 3));
      final double rail = tester.getSize(find.byType(SizedBox).first).width;
      await tester.pumpWidget(coquille(1440, 3));
      final double laterale = tester.getSize(find.byType(SizedBox).first).width;
      expect(rail, AppGabarit.largeurRail);
      expect(laterale, AppGabarit.largeurBarreLaterale);
      expect(laterale, greaterThan(rail));
    });

    testWidgets('une seule destination ne fait aucun chrome', (
      WidgetTester tester,
    ) async {
      // Le controleur n'a qu'une destination, l'eleve en mode enfant aucune :
      // dans les deux cas, l'ecran prend toute la place.
      await tester.pumpWidget(coquille(390, 1));
      expect(find.text('D0'), findsNothing);
      expect(find.text('contenu'), findsOneWidget);
    });

    test('au dela de quatre destinations, la construction est refusee', () {
      // La seule chose qui empeche la barre basse de devenir un menu.
      expect(
        () => NavShell(
          destinations: <Destination>[
            for (int i = 0; i < 5; i++)
              Destination(
                libelle: 'D$i',
                icone: AppIcons.foyer,
                chemin: '/d$i',
              ),
          ],
          indexActif: 0,
          onAller: _allerNullePart,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('PageShell : la gouttiere suit le gabarit', () {
    Future<double> gouttiere(WidgetTester tester, double largeur) async {
      await tester.pumpWidget(
        hoteComposant(
          MediaQuery(
            data: MediaQueryData(size: Size(largeur, 800)),
            child: const PageShell(child: Text('corps')),
          ),
        ),
      );
      final Padding p = tester.widget(
        find
            .descendant(
              of: find.byType(PageShell),
              matching: find.byType(Padding),
            )
            .last,
      );
      return p.padding.resolve(TextDirection.ltr).left;
    }

    testWidgets('20 sur mobile, 32 sur tablette, 48 sur desktop', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      expect(await gouttiere(tester, 390), AppPage.gouttiereMobile);
      expect(await gouttiere(tester, 768), AppPage.gouttiereTablette);
      expect(await gouttiere(tester, 1440), AppPage.gouttiereDesktop);
    });

    testWidgets('la colonne se borne a 1200 et se centre', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        hoteComposant(
          const MediaQuery(
            data: MediaQueryData(size: Size(1920, 800)),
            child: PageShell(child: Text('corps')),
          ),
        ),
      );
      final ConstrainedBox borne = tester.widget(
        find
            .descendant(
              of: find.byType(PageShell),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(borne.constraints.maxWidth, AppPage.largeurMaxContenu);
    });

    testWidgets('l entete ne defile pas avec le contenu', (
      WidgetTester tester,
    ) async {
      // `07-catalogue-composants.md` section 2 fait de l'en-tete une zone
      // distincte de la zone defilante : le selecteur d'enfant de `TUT-01` ou
      // un onglet doit rester visible quand le corps defile.
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        hoteComposant(
          const MediaQuery(
            data: MediaQueryData(size: Size(390, 800)),
            child: PageShell(
              entete: Text('SELECTEUR'),
              child: SizedBox(height: 4000, child: Text('tres long corps')),
            ),
          ),
        ),
      );

      final double avant = tester.getTopLeft(find.text('SELECTEUR')).dy;
      await tester.drag(
        find.descendant(
          of: find.byType(PageShell),
          matching: find.byType(Scrollable),
        ),
        const Offset(0, -400),
      );
      await tester.pump();
      final double apres = tester.getTopLeft(find.text('SELECTEUR')).dy;

      // Le corps a defile, l'en-tete n'a pas bouge.
      expect(tester.getTopLeft(find.text('tres long corps')).dy, lessThan(0));
      expect(apres, avant);
    });
  });

  group('EmptyState : trois registres, pas un seul', () {
    testWidgets('le registre subi ne propose aucune action', (
      WidgetTester tester,
    ) async {
      // « Votre enseignant n'a pas encore publie votre planning. » Proposer un
      // bouton ici serait mentir sur ce que la personne peut obtenir.
      await tester.pumpWidget(
        hoteComposant(
          const EmptyState(
            message: 'Aucun planning',
            libelleAction: 'Agir',
            onAction: _rien,
            registre: RegistreVide.subi,
          ),
        ),
      );
      expect(find.text('Agir'), findsNothing);
    });

    testWidgets('le registre actionnable rend son bouton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const EmptyState(
            message: 'Aucun creneau',
            libelleAction: 'Agir',
            onAction: _rien,
          ),
        ),
      );
      expect(find.text('Agir'), findsOneWidget);
    });
  });

  group('ChildCard : sept etats, et aucune pulsation', () {
    testWidgets('le cours imminent ne pulse pas', (WidgetTester tester) async {
      // Une seule zone pulse par ecran, et c'est celle d'`ELV-02`. Quatre
      // cartes qui battraient ensemble annuleraient le sens des quatre.
      //
      // La mesure porte sur les animations en cours et non sur un type de
      // widget : chercher un `FadeTransition` ne prouve rien, l'ecran en
      // contient quatre qui appartiennent aux transitions de route. C'est le
      // piege deja paye au lot L7, ou le test de la pulsation d'`ELV-02`
      // trouvait les `ScaleTransition` du retour tactile de `Pressable`.
      await tester.pumpWidget(
        hoteComposant(
          const ChildCard(
            prenom: 'Aicha',
            etat: EnfantImminent(heure: '17:00', minuteur: 'Dans 4 min'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      // Une periode entiere de pulsation plus tard, rien n'a bouge.
      await tester.pump(AppMouvement.pulsation);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('hors ligne, aucune action n est rendue', (
      WidgetTester tester,
    ) async {
      // Un bouton qui echouerait apres le geste coute plus cher en confiance
      // qu'un bouton absent.
      await tester.pumpWidget(
        hoteComposant(
          const ChildCard(
            prenom: 'Aicha',
            etat: EnfantEnCours(enseignant: 'Youssef', depuis: 'il y a 12 min'),
            horsLigne: true,
            onAssister: _rien,
          ),
        ),
      );
      expect(find.text(t.tuteur.accueil.assister), findsNothing);
      expect(find.text(t.reseau.syncImpossible), findsOneWidget);
    });

    testWidgets('sans planning : fond washWarning ET contour borderStrong', (
      WidgetTester tester,
    ) async {
      // Les trois attributs de la ligne « Aucun planning » de
      // `07-catalogue-composants.md` section 3 : fond `washWarning`, encre
      // `inkWarning`, **contour `borderStrong`** tout autour (et non le lisere
      // gauche, reserve a l'imminence).
      await tester.pumpWidget(
        hoteComposant(
          const ChildCard(prenom: 'Ibrahim', etat: EnfantSansPlanning()),
        ),
      );
      final BoxDecoration d = decorationSous(tester, find.byType(ChildCard));
      expect(d.color, palette.washWarning.background);
      expect(d.color, isNot(palette.surfaceWarning.background));
      expect(d.border!.top.color, palette.borderStrong.asBorderSide().color);
    });

    testWidgets('en recherche : le detail lit en encre attenuee inkMuted', (
      WidgetTester tester,
    ) async {
      // « Carte normale, encre `inkMuted` » (section 3) : l'encre attenuee
      // nommee, et non celle que `encreSecondaireSur` choisit pour la surface
      // (`inkFaint`, qui mesure 4,48 sur l'enfonce).
      await tester.pumpWidget(
        hoteComposant(
          const ChildCard(
            prenom: 'Ibrahim',
            etat: EnfantEnRecherche('Demande deposee le 2 septembre'),
          ),
        ),
      );
      final Text detail = tester.widget(
        find.text('Demande deposee le 2 septembre'),
      );
      expect(detail.style!.color, palette.inkMuted.debugValue);
      expect(detail.style!.color, isNot(palette.inkFaint.debugValue));
    });
  });

  group('GrilleSemaine : les trois surfaces', () {
    testWidgets('une case vide est enfoncee, une case posee est douce', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const SingleChildScrollView(
            child: GrilleSemaine(
              creneaux: <Creneau>[
                Creneau(jour: 1, heure: 6, fuseau: 'Europe/Paris'),
              ],
              fuseau: 'Europe/Paris',
              onBasculer: _basculeIgnoree,
            ),
          ),
        ),
      );

      final Iterable<DecoratedBox> cases = tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final Set<Color?> fonds = cases
          .map((DecoratedBox b) => (b.decoration as BoxDecoration).color)
          .toSet();
      expect(fonds, contains(palette.surfaceSunken.background));
      expect(fonds, contains(palette.washAccent.background));
      // L'aplat violet d'avant la refonte n'y est plus.
      expect(fonds, isNot(contains(palette.surfacePrimary.background)));
    });
  });

  group('BentoTile : registre unique, jamais un filet sans ombre', () {
    testWidgets('au repos : surfaceRaised, filet hairline, ombre niveau 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(const BentoTile(child: Text('Une tuile'))),
      );
      final BoxDecoration d = decorationSous(tester, find.byType(BentoTile));
      expect(d.color, palette.surfaceRaised.background);
      expect(d.border!.top.color, palette.borderHairline.asBorderSide().color);
      expect(d.boxShadow, AppElevation.niveau1(palette.ombre));
    });

    testWidgets('eveillee : filet fort et ombre au niveau 2, jamais plate', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteComposant(
          const PressionForcee(
            etat: EtatPression(survole: true),
            child: BentoTile(onPress: _rien, child: Text('Une tuile')),
          ),
        ),
      );
      final BoxDecoration d = decorationSous(tester, find.byType(BentoTile));
      expect(d.border!.top.color, palette.borderStrong.asBorderSide().color);
      expect(d.boxShadow, AppElevation.niveau2(palette.ombre));
      expect(d.boxShadow, isNot(AppElevation.niveau0));
    });

    testWidgets('contour fort : le filet porteur de sens des le repos', (
      WidgetTester tester,
    ) async {
      // La bordure `borderStrong` fixe qui remplace la pulsation d'`ELV-02`
      // sous mouvement reduit : elle est la sans survol ni pression, mais la
      // tuile reste posee, ombre de niveau 1.
      await tester.pumpWidget(
        hoteComposant(
          const BentoTile(contourFort: true, child: Text('Une tuile')),
        ),
      );
      final BoxDecoration d = decorationSous(tester, find.byType(BentoTile));
      expect(d.border!.top.color, palette.borderStrong.asBorderSide().color);
      expect(d.boxShadow, AppElevation.niveau1(palette.ombre));
    });
  });

  group('ConfirmDestructive : le destructif ni au pouce ni au clavier', () {
    testWidgets('« Annuler » est plus bas que le bouton destructif', (
      WidgetTester tester,
    ) async {
      // La feuille est ancree au bas de l'ecran : le bas est la zone du pouce,
      // et le destructif n'y est jamais (`02-regles-ux.md` section 5).
      late BuildContext ctx;
      await tester.pumpWidget(
        hoteComposant(
          Builder(
            builder: (BuildContext context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      unawaited(
        ConfirmDestructive.demander(
          ctx,
          question: 'Retirer Aicha du foyer ?',
          consequence: 'Son acces sera desactive.',
          libelleConfirmer: 'Retirer Aicha',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getCenter(find.text(t.commun.annuler)).dy,
        greaterThan(tester.getCenter(find.text('Retirer Aicha')).dy),
      );
    });

    testWidgets('l ordre de tabulation garde « Annuler » en premier', (
      WidgetTester tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        hoteComposant(
          Builder(
            builder: (BuildContext context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      unawaited(
        ConfirmDestructive.demander(
          ctx,
          question: 'Retirer Aicha du foyer ?',
          consequence: 'Son acces sera desactive.',
          libelleConfirmer: 'Retirer Aicha',
        ),
      );
      await tester.pumpAndSettle();

      // Le rang de tabulation est force : « Annuler » porte 1, le destructif 2,
      // quel que soit leur ordre physique.
      final FocusTraversalOrder rangAnnuler = tester.widget(
        find.ancestor(
          of: find.text(t.commun.annuler),
          matching: find.byType(FocusTraversalOrder),
        ),
      );
      final FocusTraversalOrder rangDestructif = tester.widget(
        find.ancestor(
          of: find.text('Retirer Aicha'),
          matching: find.byType(FocusTraversalOrder),
        ),
      );
      expect(
        (rangAnnuler.order as NumericFocusOrder).order,
        lessThan((rangDestructif.order as NumericFocusOrder).order),
      );
    });
  });

  group('AppBottomSheet : une feuille est une surface elevee', () {
    testWidgets('elle porte un filet ET une ombre de niveau 3', (
      WidgetTester tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        hoteComposant(
          Builder(
            builder: (BuildContext context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      unawaited(
        AppBottomSheet.ouvrir<void>(
          ctx,
          titre: 'Changer d enseignant',
          constructeur: (BuildContext _) => const Text('corps'),
        ),
      );
      await tester.pumpAndSettle();

      final BoxDecoration d = decorationSous(
        tester,
        find.byType(AppBottomSheet),
      );
      expect(d.border, isNotNull);
      expect(d.boxShadow, AppElevation.niveau3(palette.ombre));
    });
  });
}

void _rien() {}

void _allerNullePart(String chemin) {}

void _basculeIgnoree(Creneau creneau, bool posee) {}
