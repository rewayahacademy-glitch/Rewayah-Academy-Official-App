// TB-2 (VIS-01) : la barre de l'appel revelee (plan V2 §4.1, §18, §23).
//
// Chaque test part de la VRAIE coquille (`routeurProvider`), ouvre
// /demo/salle, tape le lien de la situation VIS-01 (K-07), puis agit comme
// une personne : un doigt, une souris, le clavier. UX-01 a UX-06 et UX-08,
// plus : panneau ouvert, Quitter au-dessus de la feuille (UX-07, en partie),
// micro bloque jamais rendu actif par la revelation.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';

import '../../capture/outil_capture.dart' show fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

/// Ouvre la salle de la situation depuis la liste de /demo/salle.
Future<GoRouter> _ouvrir(
  WidgetTester tester,
  RoleSeance role, {
  SituationTb situation = SituationTb.vis01,
  Size taille = _telephone,
  PointerDeviceKind appareil = PointerDeviceKind.touch,
}) async {
  final GoRouter routeur = await monterRouteur(
    tester,
    Routes.demoSalle,
    taille: taille,
  );
  final Finder lien = find.byKey(
    ValueKey<String>('lien-${role.name}-tb-${situation.name}'),
  );
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien, kind: appareil);
  await stabiliser(tester);
  expect(lieu(routeur), adresseDemoSalleTb(role, situation));
  expect(tester.takeException(), isNull);
  return routeur;
}

AnimatedOpacity _fondu(WidgetTester tester) => tester.widget<AnimatedOpacity>(
  find.ancestor(
    of: find.byKey(CommandesMasquables.commandesKey),
    matching: find.byType(AnimatedOpacity),
  ),
);

bool _visible(WidgetTester tester) => _fondu(tester).opacity == 1;

/// Vrai si les commandes ignorent le doigt (masquees, rien d'activable).
bool _ignorees(WidgetTester tester) => tester
    .widget<IgnorePointer>(
      find
          .ancestor(
            of: find.byKey(CommandesMasquables.commandesKey),
            matching: find.byType(IgnorePointer),
          )
          .first,
    )
    .ignoring;

/// Laisse passer le delai de masquage, sans aucune interaction.
Future<void> _attendreDelai(WidgetTester tester) async {
  await tester.pump(CommandesMasquables.delaiParDefaut);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Le fondu : un cadre pour le lancer, puis sa duree.
Future<void> _fondre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Le bouton d'appel de ce libelle (icone seule en Mode Accessibilite).
Finder _bouton(String libelle) => find.byWidgetPredicate(
  (Widget w) => w is BoutonAppel && w.libelle == libelle,
);

Finder get _quitter => _bouton(t.salle.quitter);

Finder get _question => find.text(t.salle.seance.quitterQuestion);

Rect _support(WidgetTester tester) =>
    tester.getRect(find.byType(ZoneSupport).first);

void main() {
  group('UX-01 : un doigt sur le contenu revele Micro, Camera, Quitter', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        await _ouvrir(tester, role);
        // Entree dans la salle : la barre est visible, puis se masque.
        expect(_visible(tester), isTrue);
        await _attendreDelai(tester);
        expect(_visible(tester), isFalse);
        expect(_ignorees(tester), isTrue);
        final String micro =
            find.byTooltip(t.salle.microOuvert).evaluate().isEmpty
            ? t.salle.microCoupe
            : t.salle.microOuvert;
        // Un doigt au milieu du support.
        await tester.tapAt(_support(tester).center);
        await _fondre(tester);
        expect(_visible(tester), isTrue);
        expect(_ignorees(tester), isFalse);
        // Dans cet ordre : Micro, Camera, Quitter (eleve, guidee) ; aucune
        // action d'appel executee.
        if (role != RoleSeance.enseignant) {
          final List<String> ordre = <String>[
            micro,
            t.salle.cameraAllumee,
            t.salle.quitter,
          ];
          final List<double> x = <double>[
            for (final String l in ordre) tester.getCenter(_bouton(l)).dx,
          ];
          expect(x[0], lessThan(x[1]));
          expect(x[1], lessThan(x[2]));
        }
        expect(find.byTooltip(micro), findsWidgets);
        expect(_question, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('UX-02 : la souris qui bouge revele la barre, sans clic', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        await _ouvrir(tester, role, taille: _bureau);
        final TestGesture souris = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await souris.addPointer(location: const Offset(700, 200));
        await _attendreDelai(tester);
        expect(_visible(tester), isFalse);
        await souris.moveTo(const Offset(720, 260));
        await _fondre(tester);
        expect(_visible(tester), isTrue);
        // Aucun panneau ouvert, aucune action : la salle est la meme.
        expect(_question, findsNothing);
        expect(
          find.byKey(const ValueKey<String>('panneau-supports')),
          findsNothing,
        );
        await souris.removePointer();
      });
    }
  });

  testWidgets('UX-03 : un geste commence sous la barre masquee n\'active '
      'jamais Quitter ; le geste suivant l\'active', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, RoleSeance.eleve);
    await _attendreDelai(tester);
    expect(_visible(tester), isFalse);
    final Offset ou = tester.getCenter(_quitter);
    // Le doigt se pose ou Quitter va apparaitre, y reste, puis se leve.
    final TestGesture doigt = await tester.startGesture(ou);
    await _fondre(tester);
    expect(_visible(tester), isTrue, reason: 'revelee pendant le geste');
    await doigt.up();
    await _fondre(tester);
    expect(_question, findsNothing, reason: 'Quitter vole par le geste');
    // Les commandes sont activables au geste suivant.
    await tester.tapAt(ou);
    await _fondre(tester);
    expect(_question, findsOneWidget);
  });

  testWidgets('UX-04 : barre visible, Micro coupe une fois, rien d\'autre', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, RoleSeance.eleve);
    final Rect avant = _support(tester);
    expect(find.byTooltip(t.salle.microOuvert), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('bouton-micro')));
    await _fondre(tester);
    expect(find.byTooltip(t.salle.microCoupe), findsOneWidget);
    expect(find.byTooltip(t.salle.microOuvert), findsNothing);
    expect(find.byTooltip(t.salle.cameraAllumee), findsOneWidget);
    expect(_question, findsNothing);
    expect(_support(tester), avant);
    // Aucun calque d'annotation n'est monte avant TB-7a : la part
    // « aucune annotation creee » se prouve la (UX_REVIEW_TB, UX-04).
  });

  group('UX-05 : survolee ou focalisee, la barre reste au-dela du delai', () {
    testWidgets('survol de la barre', (WidgetTester tester) async {
      await _ouvrir(tester, RoleSeance.eleve, taille: _bureau);
      final TestGesture souris = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: const Offset(700, 200));
      await souris.moveTo(
        tester.getCenter(find.byKey(CommandesMasquables.commandesKey)),
      );
      await tester.pump();
      await _attendreDelai(tester);
      await _attendreDelai(tester);
      expect(_visible(tester), isTrue);
      expect(_ignorees(tester), isFalse);
      // Le pointeur sort : la barre se masque apres le delai.
      await souris.moveTo(const Offset(700, 200));
      await tester.pump();
      await _attendreDelai(tester);
      expect(_visible(tester), isFalse);
      await souris.removePointer();
    });

    testWidgets('focus sur une commande, meme apres un mouvement de souris', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.eleve, taille: _bureau);
      // Tab jusqu'a Micro.
      for (int i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (FocusManager.instance.primaryFocus?.debugLabel == 'bouton-micro') {
          break;
        }
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'bouton-micro');
      // La souris bouge hors de la barre : le parcours clavier n'est plus la
      // derniere interaction, mais une commande garde le focus.
      final TestGesture souris = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: const Offset(700, 200));
      await souris.moveTo(const Offset(710, 210));
      await tester.pump();
      await _attendreDelai(tester);
      await _attendreDelai(tester);
      expect(_visible(tester), isTrue);
      expect(_ignorees(tester), isFalse);
      await souris.removePointer();
    });
  });

  group('UX-06 : sans interaction, la barre se masque ; rien ne bouge', () {
    for (final RoleSeance role in RoleSeance.values) {
      for (final Size taille in <Size>[_telephone, _bureau]) {
        testWidgets('${role.name} ${taille.width.toInt()}', (
          WidgetTester tester,
        ) async {
          await _ouvrir(tester, role, taille: taille);
          final Rect avant = _support(tester);
          final Rect barre = tester.getRect(
            find.byKey(CommandesMasquables.commandesKey),
          );
          // Marge de lecture : la barre ne couvre pas le support.
          expect(avant.bottom, lessThanOrEqualTo(barre.top));
          await _attendreDelai(tester);
          expect(_visible(tester), isFalse);
          expect(_support(tester), avant, reason: 'contenu et repere');
          expect(
            tester.getRect(find.byKey(CommandesMasquables.commandesKey)),
            barre,
          );
        });
      }
    }
  });

  // Revue TB-2 : un bureau ouvert a la SOURIS (Web bureau) est en mode de
  // focus `traditional` des l'entree ; sans touche pressee, ce n'est pas un
  // parcours clavier : l'eleve qui regarde sans toucher la souris voit la
  // barre se masquer (UX-06). La premiere touche la ramene et la garde.
  group('UX-06 : ouverte a la souris sur un bureau, sans interaction, la '
      'barre se masque', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        await _ouvrir(
          tester,
          role,
          taille: _bureau,
          appareil: PointerDeviceKind.mouse,
        );
        expect(
          FocusManager.instance.highlightMode,
          FocusHighlightMode.traditional,
        );
        expect(_visible(tester), isTrue);
        final Rect avant = _support(tester);
        await _attendreDelai(tester);
        await _fondre(tester);
        expect(_visible(tester), isFalse);
        expect(_ignorees(tester), isTrue);
        expect(_support(tester), avant, reason: 'contenu et repere');
        // Une touche : le parcours clavier commence, la barre revient et
        // ne se masque plus (Quitter jamais masque au clavier).
        await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
        await _fondre(tester);
        expect(_visible(tester), isTrue);
        await _attendreDelai(tester);
        await _attendreDelai(tester);
        expect(_visible(tester), isTrue);
        expect(_ignorees(tester), isFalse);
      });
    }
  });

  // Plan V2 §18.1 : lecteur d'ecran actif, la barre ne se masque pas.
  group('lecteur d\'ecran : la barre reste visible et activable', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(accessibleNavigation: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _ouvrir(tester, role);
        // Ouverte au doigt (mode tactile) : seul le lecteur d'ecran la
        // retient.
        expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
        await _attendreDelai(tester);
        await _attendreDelai(tester);
        await _fondre(tester);
        expect(_visible(tester), isTrue);
        expect(_ignorees(tester), isFalse);
        await tester.tap(_quitter);
        await _fondre(tester);
        expect(_question, findsOneWidget);
      });
    }
  });

  // UX-07 (plan V2 §18.2) : quand la barre depasse le tiers de la hauteur
  // (petit ecran, telephone couche), elle se pose PAR-DESSUS le contenu. Elle
  // est peinte au-dessus de lui et c'est elle qui recoit le doigt : Quitter
  // se tape a travers le chevauchement.
  group('UX-07 : barre posee par-dessus le contenu, Quitter au-dessus', () {
    for (final (RoleSeance, Size) cas in <(RoleSeance, Size)>[
      // TB-4 : la barre de l'enseignant n'a plus que Micro, Camera, Quitter
      // (une rangee a 320 x 568) ; le cas du petit ecran couche la garde
      // au-dessus du tiers.
      (RoleSeance.enseignant, const Size(700, 320)),
      (RoleSeance.eleve, const Size(844, 390)),
    ]) {
      final (RoleSeance role, Size taille) = cas;
      testWidgets('${role.name} ${taille.width.toInt()}x'
          '${taille.height.toInt()}', (WidgetTester tester) async {
        await _ouvrir(tester, role, taille: taille);
        final RenderCustomMultiChildLayoutBox pile = tester
            .renderObject<RenderCustomMultiChildLayoutBox>(
              find
                  .descendant(
                    of: find.byType(CommandesMasquables),
                    matching: find.byType(CustomMultiChildLayout),
                  )
                  .first,
            );
        final RenderBox dessous = pile.firstChild!;
        final RenderBox dessus = pile.lastChild!;
        final Rect barre = tester.getRect(
          find.byKey(CommandesMasquables.commandesKey),
        );
        // Standard des commandes d'appel : une seule pilule d'icones, d'une
        // rangee a ces tailles ; elle tient sous le tiers de l'ecran et ne
        // cache plus de contenu a elle seule (avant : barre a mots, plus
        // haute, qui chevauchait le contenu).
        expect(
          barre.height,
          lessThanOrEqualTo(taille.height / 3),
          reason: 'la pilule tient sur une rangee, sous le tiers',
        );
        expect(
          find.descendant(
            of: find.byKey(CommandesMasquables.commandesKey),
            matching: find.byType(Text),
          ),
          findsNothing,
          reason: 'aucun mot visible dans la barre',
        );
        // L'ordre de peinture : le contenu d'abord, la barre ensuite.
        final RenderObject quitter = tester.renderObject(_quitter);
        bool sous(RenderObject o, RenderObject parent) {
          RenderObject? r = o;
          while (r != null) {
            if (identical(r, parent)) return true;
            r = r.parent;
          }
          return false;
        }

        expect(sous(quitter, dessus), isTrue, reason: 'barre peinte dessus');
        expect(sous(quitter, dessous), isFalse);
        // Le doigt : la barre d'abord.
        final Offset ou = tester.getCenter(_quitter);
        final HitTestResult touche = tester.hitTestOnBinding(ou);
        expect(
          touche.path.any((HitTestEntry e) => identical(e.target, quitter)),
          isTrue,
        );
        await tester.tapAt(ou);
        await _fondre(tester);
        expect(_question, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // Standard des commandes d'appel (24/10/2026) : Quitter est un bouton rond
  // rouge, plus large, sans aucun mot visible ; son nom est l'infobulle et
  // la voix du lecteur d'ecran. Il reste entier dans l'ecran, a 48 au moins.
  group(
    'Quitter reste nomme, sans mot visible (standard des commandes d\'appel)',
    () {
      for (final RoleSeance role in RoleSeance.values) {
        for (final Size taille in <Size>[const Size(320, 700), _telephone]) {
          testWidgets('${role.name} ${taille.width.toInt()} x1', (
            WidgetTester tester,
          ) async {
            await _ouvrir(tester, role, taille: taille);
            expect(
              find.descendant(of: _quitter, matching: find.byType(Text)),
              findsNothing,
              reason: 'aucun mot visible dans le bouton',
            );
            expect(
              find.descendant(
                of: _quitter,
                matching: find.byTooltip(t.salle.quitter),
              ),
              findsOneWidget,
            );
            final Rect r = tester.getRect(
              find.descendant(
                of: _quitter,
                matching: find.byKey(const ValueKey<String>('disque-appel')),
              ),
            );
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(taille.width));
            expect(r.bottom, lessThanOrEqualTo(taille.height));
            expect(r.height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
          });
        }
      }
    },
  );

  testWidgets('UX-08 : Tab revele la barre, entre par « Commandes de '
      'l\'appel », puis Micro', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.eleve, taille: _bureau);
    // Un doigt a touche la salle (mode tactile), puis le delai passe.
    await tester.tapAt(_support(tester).center);
    await _attendreDelai(tester);
    expect(_visible(tester), isFalse);
    expect(_ignorees(tester), isTrue, reason: 'aucune cible cachee active');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _fondre(tester);
    expect(_visible(tester), isTrue);
    for (int i = 0; i < 30; i++) {
      if (FocusManager.instance.primaryFocus?.debugLabel ==
          'commandes-de-l-appel') {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      // Pendant tout le parcours, la barre reste visible.
      expect(_visible(tester), isTrue);
    }
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'commandes-de-l-appel',
    );
    expect(find.bySemanticsLabel(t.salle.seance.commandesAppel), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'bouton-micro');
    // Le temps passe, le focus reste dans la barre : elle reste.
    await _attendreDelai(tester);
    await _attendreDelai(tester);
    expect(_visible(tester), isTrue);
  });

  testWidgets('panneau ouvert : la barre reste, Quitter au-dessus de la '
      'feuille et activable (UX-07, telephone)', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.enseignant, situation: SituationTb.lib01);
    // TB-8 : LIB-01 ouvre la Bibliotheque en seance.
    final Finder panneau = find.byType(BibliothequeSeance);
    expect(panneau, findsOneWidget);
    await _attendreDelai(tester);
    await _attendreDelai(tester);
    expect(_visible(tester), isTrue);
    final Rect barre = tester.getRect(
      find.byKey(CommandesMasquables.commandesKey),
    );
    expect(tester.getRect(panneau).bottom, lessThanOrEqualTo(barre.top));
    await tester.tap(_quitter);
    await _fondre(tester);
    expect(_question, findsOneWidget);
  });

  testWidgets('micro bloque : erreur critique media, la barre reste sans '
      'toucher l\'ecran ; elle ne rend jamais le micro actif', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterRouteur(
      tester,
      adresseDemoSalle(RoleSeance.eleve, EtatDemoSalle.microBloque),
    );
    expect(lieu(routeur), contains('microBloque'));
    expect(find.byTooltip(t.salle.microOuvert), findsNothing);
    // Aucune interaction : deux delais passent, la barre reste (§18.1).
    await _attendreDelai(tester);
    await _attendreDelai(tester);
    expect(_visible(tester), isTrue);
    expect(_ignorees(tester), isFalse);
    // Un doigt sur le contenu : toujours pas de micro actif.
    await tester.tapAt(_support(tester).center);
    await _fondre(tester);
    await _attendreDelai(tester);
    expect(_visible(tester), isTrue);
    expect(find.byTooltip(t.salle.microOuvert), findsNothing);
    expect(find.byTooltip(t.salle.microCoupe), findsOneWidget);
  });

  // Plan V2 §18.1 : « Erreur critique de connexion ou media : barre
  // visible ». Reconnexion, echec, hors ligne : la barre ne se masque pas,
  // meme apres un toucher et deux delais.
  group('erreur critique de connexion : la barre reste', () {
    for (final EtatDemoSalle etat in <EtatDemoSalle>[
      EtatDemoSalle.reconnexion,
      EtatDemoSalle.echec,
      EtatDemoSalle.horsLigne,
    ]) {
      for (final RoleSeance role in RoleSeance.values) {
        testWidgets('${etat.name} ${role.name}', (WidgetTester tester) async {
          final GoRouter routeur = await monterRouteur(
            tester,
            adresseDemoSalle(role, etat),
          );
          expect(lieu(routeur), contains(etat.name));
          expect(find.byKey(CommandesMasquables.commandesKey), findsOneWidget);
          await _attendreDelai(tester);
          await _attendreDelai(tester);
          expect(_visible(tester), isTrue);
          expect(_ignorees(tester), isFalse);
          expect(_quitter, findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('temoin : seance en cours, la meme attente masque la barre', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        adresseDemoSalle(RoleSeance.eleve, EtatDemoSalle.repos),
      );
      await _attendreDelai(tester);
      await _attendreDelai(tester);
      expect(_visible(tester), isFalse);
    });
  });

  // Plan V2 §18.1 : « Parcours clavier actif, focus hors de la barre : pas
  // de masquage automatique » ; Quitter jamais masque au clavier.
  for (final RoleSeance role in RoleSeance.values) {
    testWidgets('clavier, focus hors de la barre : jamais masquee '
        '(${role.name})', (WidgetTester tester) async {
      await _ouvrir(tester, role, taille: _bureau);
      // Un doigt d'abord (mode tactile) : la barre se masque.
      await tester.tapAt(_support(tester).center);
      await _attendreDelai(tester);
      expect(_visible(tester), isFalse);
      // Le clavier reprend ; le focus avance jusqu'a une cible HORS de la
      // barre et de son entree.
      final Element barre = tester.element(
        find.byKey(CommandesMasquables.entreeKey),
      );
      bool dansBarre() {
        final BuildContext? c = FocusManager.instance.primaryFocus?.context;
        if (c == null) return false;
        if (identical(c, barre)) return true;
        bool dedans = false;
        c.visitAncestorElements((Element e) {
          if (identical(e, barre)) {
            dedans = true;
            return false;
          }
          return true;
        });
        return dedans;
      }

      bool horsBarre = false;
      for (int i = 0; i < 40; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final FocusNode? f = FocusManager.instance.primaryFocus;
        if (f != null &&
            f.context != null &&
            !dansBarre() &&
            f.debugLabel != 'commandes-de-l-appel') {
          horsBarre = true;
          break;
        }
      }
      expect(horsBarre, isTrue, reason: 'une cible focalisable hors barre');
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      await _fondre(tester);
      expect(_visible(tester), isTrue);
      // Le temps passe, focus toujours hors de la barre : elle reste,
      // Quitter activable.
      await _attendreDelai(tester);
      await _attendreDelai(tester);
      await _attendreDelai(tester);
      expect(dansBarre(), isFalse);
      expect(_visible(tester), isTrue);
      expect(_ignorees(tester), isFalse);
      expect(tester.getRect(_quitter).height, greaterThanOrEqualTo(48));
    });
  }

  // Plan V2 §18.1 : « Trait ou geste de zoom en cours : ne pas masquer ».
  testWidgets('un doigt pose au-dela du delai : la barre reste ; leve, '
      'elle se masque apres le delai', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.eleve);
    final TestGesture doigt = await tester.startGesture(
      _support(tester).center,
    );
    await _fondre(tester);
    expect(_visible(tester), isTrue);
    await _attendreDelai(tester);
    await _attendreDelai(tester);
    await _attendreDelai(tester);
    expect(_visible(tester), isTrue, reason: 'geste en cours');
    // Deux doigts (zoom) : le premier se leve, le second reste.
    final TestGesture second = await tester.startGesture(
      _support(tester).center + const Offset(40, 0),
      pointer: 7,
    );
    await doigt.up();
    await _attendreDelai(tester);
    await _attendreDelai(tester);
    expect(_visible(tester), isTrue, reason: 'un contact reste pose');
    await second.up();
    await tester.pump();
    expect(_visible(tester), isTrue);
    await _attendreDelai(tester);
    expect(_visible(tester), isFalse);
    expect(_question, findsNothing);
  });

  // RTL force (K-41 n. 12), 320 px et texte x2 (SALLE-200) : la barre tient,
  // sans debordement ; Quitter reste dans l'ecran, cible de 48 au moins.
  for (final RoleSeance role in RoleSeance.values) {
    for (final (Size, double) cas in <(Size, double)>[
      (const Size(320, 700), 1),
      (const Size(320, 700), 2),
      (_telephone, 2),
    ]) {
      testWidgets(
        '${role.name} RTL ${cas.$1.width.toInt()} x${cas.$2.toInt()}',
        (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$1, 1);
          await tester.pumpWidget(
            hoteCapture(
              Directionality(
                textDirection: TextDirection.rtl,
                child: DemoSallePage(role: role, situation: SituationTb.vis01),
              ),
              echelleTexte: cas.$2,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull, reason: 'debordement');
          final Rect q = tester.getRect(_quitter);
          expect(q.left, greaterThanOrEqualTo(0));
          expect(q.right, lessThanOrEqualTo(cas.$1.width));
          expect(q.bottom, lessThanOrEqualTo(cas.$1.height));
          expect(q.height, greaterThanOrEqualTo(48));
          await _attendreDelai(tester);
          expect(_visible(tester), isFalse);
          await tester.tapAt(_support(tester).center);
          await _fondre(tester);
          expect(_visible(tester), isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
