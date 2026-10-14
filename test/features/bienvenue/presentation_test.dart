// PUB-1 : la presentation publique avant la connexion. Defilement
// automatique, pause (toucher, focus, mouvement reduit), croix, glissement,
// derniere page, vue une seule fois par appareil, 320 texte x2 en LTR et RTL,
// 1440.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/preferences/presentation_vue.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/features/bienvenue/bienvenue_page.dart';

import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Les titres des cinq pages, dans l'ordre, tels qu'affiches (isoles dans
/// leur propre sens de lecture).
List<String> get _titres => <String>[
  t.bienvenue.accroche,
  t.bienvenue.pointClasseTitre,
  t.bienvenue.pointEnseignantTitre,
  t.bienvenue.pointParcoursTitre,
  t.bienvenue.pointFoyerTitre,
].map(isolerSens).toList();

/// Un pas de defilement automatique : le temps de lecture, puis le passage.
const Duration _pas = Duration(milliseconds: 6400);

Future<StockagePreferencesMemoire> _monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  TextDirection? direction,
  double echelle = 1,
  bool mouvementReduit = false,
  bool lecteurEcran = false,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final StockagePreferencesMemoire stockage = StockagePreferencesMemoire();
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.bienvenue,
      themeMode: themeMode,
      direction: direction,
      echelle: echelle,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.bienvenue,
          builder: (BuildContext _, GoRouterState _) =>
              mouvementReduit || lecteurEcran
              ? Builder(
                  builder: (BuildContext contexte) => MediaQuery(
                    data: MediaQuery.of(contexte).copyWith(
                      disableAnimations: mouvementReduit,
                      accessibleNavigation: lecteurEcran,
                    ),
                    child: const BienvenuePage(),
                  ),
                )
              : const BienvenuePage(),
        ),
        GoRoute(
          path: Routes.connexion,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('connexion', textDirection: TextDirection.ltr),
        ),
      ],
      surcharges: <Override>[
        stockagePresentationProvider.overrideWithValue(stockage),
      ],
    ),
  );
  await tester.pump();
  return stockage;
}

/// Laisse passer [secondes] secondes, image par image (un seul `pump` long
/// ne rendrait pas le passage de page qu'il declenche).
Future<void> _attendre(WidgetTester tester, int secondes) async {
  for (int i = 0; i < secondes * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// La position annoncee par la barre du bas (« 1 / 5 »), isolee.
Finder _position(int numero) =>
    find.text(isolerSens(t.bienvenue.position(numero: numero, total: 5)));

double _valeurSegment(WidgetTester tester, int i) => tester
    .widget<LinearProgressIndicator>(
      find.byKey(ValueKey<String>('bienvenue-segment-$i')),
    )
    .value!;

void main() {
  test('3 a 5 pages, une idee chacune', () {
    expect(nombrePagesPresentation, inInclusiveRange(3, 5));
  });

  test('le rythme est de 5 a 7 secondes', () {
    expect(rythmePresentation.inMilliseconds, inInclusiveRange(5000, 7000));
  });

  group('defilement automatique', () {
    testWidgets('passe a la page suivante au rythme, la ligne se charge', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.text(_titres[0]), findsOneWidget);
      expect(_valeurSegment(tester, 0), 0);

      await tester.pump(const Duration(seconds: 3));
      expect(_valeurSegment(tester, 0), closeTo(0.5, 0.05));
      expect(find.text(_titres[0]), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(AppMouvement.navigation);
      await tester.pump(AppMouvement.navigation);
      expect(find.text(_titres[1]), findsOneWidget);
      expect(_valeurSegment(tester, 0), 1);
      expect(_position(2), findsOne);
    });

    testWidgets('s arrete a la derniere page, sans boucler', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      for (int i = 1; i < 5; i++) {
        await tester.pump(_pas);
        await tester.pump(AppMouvement.navigation);
      }
      expect(find.text(_titres[4]), findsOneWidget);
      await _attendre(tester, 30);
      expect(_position(5), findsOneWidget);
      expect(find.text(_titres[4]), findsOneWidget);
      expect(find.text(_titres[0]), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('bienvenue-commencer')),
        findsOne,
      );
    });

    testWidgets('en pause tant qu un doigt touche la page', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.pump(const Duration(seconds: 2));
      final TestGesture doigt = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('bienvenue-pages'))),
      );
      await _attendre(tester, 20);
      expect(_position(1), findsOneWidget);
      expect(find.text(_titres[0]), findsOneWidget);
      final double gele = _valeurSegment(tester, 0);
      expect(gele, closeTo(1 / 3, 0.05));

      await doigt.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(AppMouvement.navigation);
      await tester.pump(AppMouvement.navigation);
      expect(find.text(_titres[1]), findsOneWidget);
    });

    testWidgets('en pause tant que le focus clavier est dans la page', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await _attendre(tester, 20);
      expect(_position(1), findsOneWidget);
      expect(find.text(_titres[0]), findsOneWidget);
    });

    // Reprise PUB-1 (revue adverse) : la page occupe tout l'ecran ; si le
    // survol mettait en pause, la presentation ne defilerait jamais seule
    // sur ordinateur.
    testWidgets(
      '1440 : la souris posee sur la page ne bloque pas le defilement',
      (WidgetTester tester) async {
        await _monter(tester, taille: const Size(1440, 900));
        final TestGesture souris = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await souris.addPointer(location: Offset.zero);
        addTearDown(souris.removePointer);
        await souris.moveTo(const Offset(720, 600));
        await tester.pump();
        await _attendre(tester, 30);
        expect(_position(5), findsOneWidget);
        expect(find.text(_titres[4]), findsOneWidget);
        expect(_valeurSegment(tester, 0), 1);
      },
    );

    testWidgets('jamais quand reduire les animations est actif', (
      WidgetTester tester,
    ) async {
      await _monter(tester, mouvementReduit: true);
      await _attendre(tester, 30);
      expect(_position(1), findsOneWidget);
      expect(find.text(_titres[0]), findsOneWidget);
      // La ligne dit la position, sans se charger.
      expect(_valeurSegment(tester, 0), 1);
      expect(_valeurSegment(tester, 1), 0);
    });
  });

  group('lecteur d ecran', () {
    testWidgets('pas de defilement automatique, la ligne dit la position', (
      WidgetTester tester,
    ) async {
      await _monter(tester, lecteurEcran: true);
      await _attendre(tester, 30);
      expect(_position(1), findsOneWidget);
      expect(find.text(_titres[0]), findsOneWidget);
      expect(_valeurSegment(tester, 0), 1);
      expect(_position(1), findsOne);
    });
  });

  group('navigation par le visiteur', () {
    testWidgets('le glissement change de page et arrete le defilement', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.fling(
        find.byKey(const ValueKey<String>('bienvenue-pages')),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle(AppMouvement.navigation);
      expect(find.text(_titres[1]), findsOneWidget);

      await _attendre(tester, 30);
      expect(_position(2), findsOneWidget);
      expect(find.text(_titres[1]), findsOneWidget);
      expect(_valeurSegment(tester, 1), 1);
    });

    testWidgets('en arabe, le glissement vers la droite avance', (
      WidgetTester tester,
    ) async {
      await _monter(tester, direction: TextDirection.rtl);
      await tester.fling(
        find.byKey(const ValueKey<String>('bienvenue-pages')),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle(AppMouvement.navigation);
      expect(find.text(_titres[1]), findsOneWidget);
    });

    testWidgets('les fleches et le clavier changent de page', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      // Au debut, pas de fleche precedente (ni grisee ni rendue).
      expect(find.bySemanticsLabel(t.bienvenue.precedente), findsNothing);
      await tester.tap(find.bySemanticsLabel(t.bienvenue.suivante));
      await tester.pumpAndSettle(AppMouvement.navigation);
      expect(find.text(_titres[1]), findsOneWidget);

      // Les fleches du clavier agissent des que le focus est dans la page.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle(AppMouvement.navigation);
      expect(find.text(_titres[2]), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle(AppMouvement.navigation);
      expect(find.text(_titres[1]), findsOneWidget);
    });
  });

  group('sortie vers la connexion, vue une seule fois', () {
    testWidgets('la croix passe tout, mene a la connexion et note la visite', (
      WidgetTester tester,
    ) async {
      final StockagePreferencesMemoire stockage = await _monter(tester);
      final Finder croix = find.byKey(
        const ValueKey<String>('bienvenue-passer'),
      );
      expect(croix, findsOneWidget);
      expect(find.bySemanticsLabel(t.bienvenue.passer), findsOneWidget);

      await tester.tap(croix);
      await tester.pumpAndSettle();

      expect(find.text('connexion'), findsOneWidget);
      expect(stockage.valeurs[clefPresentationVue], 'oui');
    });

    testWidgets('la croix est atteinte au clavier et s active par Entree', (
      WidgetTester tester,
    ) async {
      final StockagePreferencesMemoire stockage = await _monter(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('connexion'), findsOneWidget);
      expect(stockage.valeurs[clefPresentationVue], 'oui');
    });

    testWidgets('« Commencer » de la derniere page mene a la connexion', (
      WidgetTester tester,
    ) async {
      final StockagePreferencesMemoire stockage = await _monter(tester);
      for (int i = 1; i < 5; i++) {
        await tester.tap(find.bySemanticsLabel(t.bienvenue.suivante));
        await tester.pumpAndSettle(AppMouvement.navigation);
      }
      expect(find.bySemanticsLabel(t.bienvenue.suivante), findsNothing);
      verifierUnSeulBoutonPlein(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('bienvenue-commencer')),
      );
      await tester.pumpAndSettle();
      expect(find.text('connexion'), findsOneWidget);
      expect(stockage.valeurs[clefPresentationVue], 'oui');
    });

    test('la racine d un visiteur : presentation, puis connexion', () {
      String? racine(EtatPresentation etat) => deciderRedirection(
        session: const SessionState.deconnecte(),
        cheminDemande: Routes.racine,
        maintenant: DateTime.utc(2026, 10, 5),
        presentation: etat,
      );
      expect(racine(EtatPresentation.inconnu), isNull);
      expect(racine(EtatPresentation.aVoir), Routes.bienvenue);
      expect(racine(EtatPresentation.vue), Routes.connexion);
    });

    testWidgets('routeur reel : premiere visite, la presentation', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        null,
        source: FausseSourceSession(),
        surcharges: <Override>[
          stockagePresentationProvider.overrideWithValue(
            StockagePreferencesMemoire(),
          ),
        ],
      );
      expect(lieu(routeur), Routes.bienvenue);
      expect(find.byType(BienvenuePage), findsOneWidget);
    });

    testWidgets('routeur reel : deja vue sur cet appareil, la connexion', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        null,
        source: FausseSourceSession(),
        surcharges: <Override>[
          stockagePresentationProvider.overrideWithValue(
            StockagePreferencesMemoire(<String, String>{
              clefPresentationVue: 'oui',
            }),
          ),
        ],
      );
      expect(lieu(routeur), Routes.connexion);
      expect(find.byType(BienvenuePage), findsNothing);
    });
  });

  group('mise en page', () {
    // Reprise PUB-1 (revue adverse) : sans cle arabe, le texte francais
    // s'affiche dans l'interface RTL ; son point final doit rester a la fin
    // de la phrase, a droite du dernier mot, pas en tete de ligne.
    testWidgets('RTL : la ponctuation finale reste en fin de phrase', (
      WidgetTester tester,
    ) async {
      await _monter(tester, direction: TextDirection.rtl);
      final String phrase = t.bienvenue.phrase;
      expect(phrase.endsWith('.'), isTrue);
      final RenderParagraph rendu = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere(
            (RenderParagraph p) => p.text.toPlainText().contains(phrase),
          );
      final String affiche = rendu.text.toPlainText();
      final int point = affiche.lastIndexOf('.');
      TextBox boite(int i) => rendu
          .getBoxesForSelection(
            TextSelection(baseOffset: i, extentOffset: i + 1),
          )
          .single;
      final TextBox boitePoint = boite(point);
      final TextBox boiteLettre = boite(point - 1);
      // Meme ligne que la derniere lettre, et a sa droite (sens francais).
      expect(boitePoint.top, closeTo(boiteLettre.top, 1));
      expect(boitePoint.left, greaterThanOrEqualTo(boiteLettre.right - 1));
    });

    // Reprise PUB-1 : en RTL, « 1 / 5 » s'affichait « 5 / 1 » (les chiffres
    // n'ont pas de sens fort, la barre est en sens arabe).
    testWidgets('RTL : la position se lit 1 / 5, pas 5 / 1', (
      WidgetTester tester,
    ) async {
      await _monter(tester, direction: TextDirection.rtl);
      final RenderParagraph rendu = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere(
            (RenderParagraph p) => p.text.toPlainText().contains(' / 5'),
          );
      final String affiche = rendu.text.toPlainText();
      double gauche(int i) => rendu
          .getBoxesForSelection(
            TextSelection(baseOffset: i, extentOffset: i + 1),
          )
          .single
          .left;
      expect(
        gauche(affiche.indexOf('1')),
        lessThan(gauche(affiche.lastIndexOf('5'))),
      );
    });

    // Reprise PUB-1 (revue adverse) : a 320 px texte x2, la fin d'une page
    // est sous le bord ; la barre de defilement reste affichee pour le dire.
    testWidgets('320 px, texte x2 : la barre de defilement dit la suite', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(320, 640), echelle: 2);
      final Finder barre = find.byKey(
        const ValueKey<String>('bienvenue-barre-service'),
      );
      expect(barre, findsOneWidget);
      final Scrollbar scrollbar = tester.widget<Scrollbar>(barre);
      expect(scrollbar.thumbVisibility, isTrue);
      final ScrollableState defilable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('bienvenue-page-service')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(defilable.position.maxScrollExtent, greaterThan(0));
      expect(barre, paints..rrect());
    });

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 px, texte x2, ${sens.name} : chaque page lisible', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          taille: const Size(320, 640),
          direction: sens,
          echelle: 2,
        );
        for (int i = 0; i < 5; i++) {
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byType(BienvenuePage));
          verifierSansChevauchement(tester, <Finder>[
            find.byKey(const ValueKey<String>('bienvenue-passer')),
            find.byKey(const ValueKey<String>('bienvenue-ligne-etat')),
            find.byKey(const ValueKey<String>('bienvenue-pages')),
            find.byKey(const ValueKey<String>('nav-precedent-suivant')),
          ]);
          if (i < 4) {
            await tester.tap(find.bySemanticsLabel(t.bienvenue.suivante));
            await tester.pumpAndSettle(AppMouvement.navigation);
          }
        }
        // Derniere page : les sorties, entieres et centrees.
        final Finder commencer = find.byKey(
          const ValueKey<String>('bienvenue-commencer'),
        );
        await tester.ensureVisible(commencer);
        await tester.pumpAndSettle();
        verifierBoutonCentre(tester, commencer, t.bienvenue.commencer);
        verifierUnSeulBoutonPlein(tester);
      });
    }

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('1440 px (${theme.name}) : bouton a la largeur du libelle', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: const Size(1440, 900), themeMode: theme);
        expect(tester.takeException(), isNull);
        for (int i = 1; i < 5; i++) {
          await tester.tap(find.bySemanticsLabel(t.bienvenue.suivante));
          await tester.pumpAndSettle(AppMouvement.navigation);
        }
        final Finder commencer = find.byKey(
          const ValueKey<String>('bienvenue-commencer'),
        );
        expect(tester.getSize(commencer).width, lessThan(400));
        verifierUnSeulBoutonPlein(tester);
        verifierAucunMotCoupe(tester, find.byType(BienvenuePage));
      });
    }
  });
}
