// COM-STU-3 : Le Studio, Mode focus, au clavier et sans mouvement (spec
// section 10.5, section 10.6, section 24, R-COM-09, R-COM-10).
//
// - Echap quitte le Focus seulement sans dialogue prioritaire : un dialogue
//   ouvert par-dessus recoit Echap et se ferme, le Focus reste.
// - Echap marche depuis le champ (texte garde) et quand aucun element de la
//   page n'a le focus clavier ; hors Focus, il ne fait rien.
// - Le focus clavier n'est jamais piege : aucune portee de focus n'est
//   creee, la tabulation va du bandeau au champ et revient ; a l'entree il
//   passe a « Quitter le focus », a la sortie il revient a « Mode focus »,
//   sauf depuis le champ : le champ le garde, avec sa selection.
// - Avec la reduction de mouvement, la transition est directe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_studio/focus/sortie_focus.dart';
import 'package:rewayah_academy/features/com_studio/liste_canaux.dart';

import 'support_focus.dart';
import 'support_studio.dart';

const Size _bureau = Size(1440, 900);

final String _adresseC1 = Routes.canalStudioPour('c1');

Future<GoRouter> _monter(WidgetTester tester, {bool mouvementReduit = false}) =>
    monterStudio(
      tester,
      port: portFocus(),
      depart: _adresseC1,
      taille: _bureau,
      mouvementReduit: mouvementReduit,
    );

bool _enFocus() => find.byKey(BandeauSortieFocus.cle).evaluate().isNotEmpty;

/// Le noeud de focus du champ du fil.
FocusNode _noeudChamp(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(FilDiscussion.champKey),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode;

void main() {
  group('Echap', () {
    testWidgets('depuis « Quitter le focus » : le Focus prend fin, le focus '
        'clavier revient sur « Mode focus »', (WidgetTester tester) async {
      await _monter(tester);
      await entrer(tester);
      final FocusNode sortie = noeudAction(tester, quitterFocus);
      expect(sortie.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_enFocus(), isFalse);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(noeudAction(tester, entrerFocus).hasPrimaryFocus, isTrue);
    });

    testWidgets('depuis le champ : le Focus prend fin, le texte reste', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await entrer(tester);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'En cours');
      await tester.pump();
      expect(_noeudChamp(tester).hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_enFocus(), isFalse);
      expect(champFil(tester).text, 'En cours');
      // Le curseur reste dans le champ : on continue d'ecrire sans
      // revenir au champ (section 20, FocusStateRestorer).
      expect(_noeudChamp(tester).hasPrimaryFocus, isTrue);
      expect(
        champFil(tester).selection,
        const TextSelection.collapsed(offset: 8),
      );
      expect(noeudAction(tester, entrerFocus).hasFocus, isFalse);
    });

    testWidgets('depuis le champ, une selection au milieu du texte : le '
        'champ garde le focus et la selection', (WidgetTester tester) async {
      await _monter(tester);
      await entrer(tester);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Un texte');
      await tester.pump();
      champFil(tester).selection = const TextSelection(
        baseOffset: 3,
        extentOffset: 8,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_enFocus(), isFalse);
      expect(_noeudChamp(tester).hasPrimaryFocus, isTrue);
      expect(
        champFil(tester).selection,
        const TextSelection(baseOffset: 3, extentOffset: 8),
      );
    });

    testWidgets('sans element focalise dans la page (clic sur le fond) : '
        'le Focus prend fin quand meme', (WidgetTester tester) async {
      await _monter(tester);
      await entrer(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(noeudAction(tester, quitterFocus).hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(_enFocus(), isFalse);
    });

    testWidgets('un dialogue prioritaire recoit Echap et se ferme ; le Focus '
        'reste, puis un second Echap le quitte', (WidgetTester tester) async {
      await _monter(tester);
      await entrer(tester);
      final BuildContext contexte = tester.element(find.byType(FilDiscussion));
      unawaited(
        showDialog<void>(
          context: contexte,
          builder: (BuildContext _) =>
              const AlertDialog(content: Text('Dialogue prioritaire')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dialogue prioritaire'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Dialogue prioritaire'), findsNothing);
      expect(_enFocus(), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_enFocus(), isFalse);
    });

    testWidgets('hors Focus, Echap ne fait rien : la page et le canal '
        'restent', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(adresseCourante(routeur), _adresseC1);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(entrerFocus, findsOneWidget);
    });
  });

  group('Le focus clavier n est jamais piege', () {
    testWidgets('aucune portee nouvelle ; la tabulation va de la sortie au '
        'champ, et la sortie se rejoint au clavier', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final FocusScopeNode porteeAvant = noeudAction(
        tester,
        entrerFocus,
      ).nearestScope!;
      await entrer(tester);
      final FocusNode sortie = noeudAction(tester, quitterFocus);
      final FocusNode champ = _noeudChamp(tester);
      // La sortie et le champ sont dans la portee de la page, comme la
      // bascule avant le Focus : rien n'enferme la tabulation.
      expect(sortie.nearestScope, same(porteeAvant));
      expect(champ.nearestScope, same(porteeAvant));

      bool champAtteint = false;
      bool sortieRetrouvee = false;
      for (int i = 0; i < 40 && !(champAtteint && sortieRetrouvee); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (champ.hasFocus) champAtteint = true;
        if (champAtteint && sortie.hasPrimaryFocus) sortieRetrouvee = true;
      }
      expect(champAtteint, isTrue);
      expect(sortieRetrouvee, isTrue);
    });

    testWidgets('« Quitter le focus » est nomme pour le lecteur d ecran', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      await _monter(tester);
      await entrer(tester);
      expect(find.bySemanticsLabel('Quitter le focus'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Focus activé')), findsOneWidget);
      semantique.dispose();
    });
  });

  group('Mouvement', () {
    testWidgets('reduction de mouvement : la transition est directe, rien '
        'n est anime', (WidgetTester tester) async {
      await _monter(tester, mouvementReduit: true);
      await tester.tap(entrerFocus);
      await tester.pump();
      final Finder bandeau = find.byKey(BandeauSortieFocus.cle);
      expect(bandeau, findsOneWidget);
      expect(
        find.ancestor(
          of: bandeau,
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(of: bandeau, matching: find.byType(Opacity)),
        findsNothing,
      );
      // Une seule image suffit : la disposition finale est deja la.
      final Rect bandeauDirect = tester.getRect(bandeau);
      final Rect filDirect = tester.getRect(find.byType(FilDiscussion));
      await tester.pumpAndSettle();
      expect(tester.getRect(bandeau), bandeauDirect);
      expect(tester.getRect(find.byType(FilDiscussion)), filDirect);
    });

    testWidgets('sans reduction : le bandeau apparait en fondu doux', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.tap(entrerFocus);
      await tester.pump();
      expect(
        find.ancestor(
          of: find.byKey(BandeauSortieFocus.cle),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });
  });
}
