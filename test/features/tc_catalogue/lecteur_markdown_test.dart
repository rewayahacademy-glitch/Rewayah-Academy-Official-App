// PX-BD-SUPPORT : le lecteur des textes que Praxis redige, dans l'application.
//
// Ce que les cas prouvent (sur le vrai widget) :
//  - chaque bloc du Markdown ferme se rend (titres, paragraphes, puces,
//    numerotees, citation, separateur, gras, italique) ;
//  - le sens se lit PARAGRAPHE par paragraphe : arabe a droite, francais a
//    gauche, y compris dans une interface francaise ou arabe ;
//  - l'arabe se rend dans la police du contenu et la vocalisation arrive
//    intacte au moteur (aucune normalisation) ;
//  - un texte refuse n'est pas « repare » : la phrase le dit ;
//  - aucun debordement a 320 px, texte x2 ; aucune barre de defilement propre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/features/tc_catalogue/lecteur_markdown.dart';

import '../../support/harnais.dart';

const String _verset = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

const String _document =
    '# Les bases de la lecture\n\n'
    'Un paragraphe en **gras** et en *italique*.\n\n'
    '$_verset\n\n'
    'نقرأ **الحمد** (Al-Hamd) ensemble.\n\n'
    '- une puce\n- une autre\n\n'
    '1. un\n2. deux\n\n'
    '> Une citation.\n\n'
    '---\n\n'
    '### Fin';

Future<void> _monter(
  WidgetTester tester,
  String source, {
  Size taille = const Size(1440, 2400),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Builder(
        builder: (BuildContext c) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: LecteurMarkdown(source: source),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Le TextSpan que pose le lecteur : `Text.rich` l'enveloppe dans le style du
/// theme, l'enfant porte le style du contenu.
TextSpan _span(RichText r) => (r.text as TextSpan).children!.first as TextSpan;

/// Le RichText dont le texte brut passe [test].
RichText _riche(WidgetTester tester, bool Function(String) test) =>
    tester.widget<RichText>(
      find.byWidgetPredicate(
        (Widget w) => w is RichText && test(w.text.toPlainText()),
      ),
    );

/// Le sens dans lequel se lit le texte qui contient [fragment].
TextDirection _sens(WidgetTester tester, String fragment) {
  final Finder f = find.byWidgetPredicate(
    (Widget w) => w is RichText && w.text.toPlainText().contains(fragment),
  );
  expect(f, findsOneWidget, reason: fragment);
  return Directionality.of(tester.element(f));
}

void main() {
  group('rendu', () {
    testWidgets('chaque bloc se rend', (tester) async {
      await _monter(tester, _document);
      expect(find.byKey(ClesLecteurMarkdown.document), findsOneWidget);
      expect(find.byKey(ClesLecteurMarkdown.illisible), findsNothing);
      expect(find.textContaining('Les bases de la lecture'), findsOneWidget);
      expect(
        find.textContaining('Un paragraphe en gras et en italique.'),
        findsOneWidget,
      );
      expect(find.textContaining('une puce'), findsOneWidget);
      expect(find.textContaining('une autre'), findsOneWidget);
      expect(find.textContaining('deux'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.textContaining('Une citation.'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('le gras et l italique sont des styles, pas des signes', (
      tester,
    ) async {
      await _monter(tester, 'Un **gras** et un *italique*.');
      final RichText r = _riche(tester, (String t) => t.contains('gras'));
      final List<InlineSpan> enfants = _span(r).children!;
      expect(r.text.toPlainText(), 'Un gras et un italique.');
      expect(
        (enfants[1] as TextSpan).style!.fontWeight!.value,
        greaterThan(_span(r).style!.fontWeight!.value),
      );
      expect((enfants[3] as TextSpan).style?.fontStyle, FontStyle.italic);
      expect(find.textContaining('*'), findsNothing);
    });

    testWidgets('une liste numerotee commence a son numero', (tester) async {
      await _monter(tester, '3. trois\n4. quatre');
      expect(find.text('3.'), findsOneWidget);
      expect(find.text('4.'), findsOneWidget);
    });
  });

  group('sens de lecture, paragraphe par paragraphe', () {
    for (final TextDirection ambiant in TextDirection.values) {
      testWidgets('interface $ambiant : arabe a droite, francais a gauche', (
        tester,
      ) async {
        await _monter(tester, _document, direction: ambiant);
        expect(_sens(tester, 'Un paragraphe en'), TextDirection.ltr);
        expect(_sens(tester, 'ٱلرَّحِيمِ'), TextDirection.rtl);
        // Mixte : il COMMENCE par de l'arabe, il se lit de droite a gauche.
        expect(_sens(tester, 'نقرأ'), TextDirection.rtl);
      });
    }

    testWidgets(
      'un paragraphe francais qui contient de l arabe reste a gauche',
      (tester) async {
        await _monter(tester, 'On lit بِسْمِ ٱللَّهِ puis on explique.');
        expect(_sens(tester, 'On lit'), TextDirection.ltr);
      },
    );
  });

  group('arabe et vocalisation', () {
    testWidgets('l arabe se rend dans la police du contenu', (tester) async {
      await _monter(tester, _verset);
      final RichText r = _riche(tester, (String t) => t == _verset);
      expect(_span(r).style?.fontFamily, AppFontFamily.arabeMushaf);
    });

    testWidgets('la vocalisation arrive intacte : meme suite de signes', (
      tester,
    ) async {
      await _monter(tester, _verset);
      final RichText r = tester.widget<RichText>(
        find.byWidgetPredicate(
          (Widget w) =>
              w is RichText && w.text.toPlainText().contains('بِسْمِ'),
        ),
      );
      expect(r.text.toPlainText().runes.toList(), _verset.runes.toList());
    });

    testWidgets('le francais garde la police du theme', (tester) async {
      await _monter(tester, 'Un texte francais.');
      final RichText r = tester.widget<RichText>(
        find.byWidgetPredicate(
          (Widget w) =>
              w is RichText && w.text.toPlainText().contains('Un texte'),
        ),
      );
      expect(
        (r.text as TextSpan).style?.fontFamily,
        isNot(AppFontFamily.arabeMushaf),
      );
    });
  });

  group('refus', () {
    for (final String refuse in <String>[
      '<b>x</b>',
      '[a](https://exemple.org)',
      '| a | b |',
      'un **mot',
    ]) {
      testWidgets('« $refuse » : la phrase, jamais une reparation', (
        tester,
      ) async {
        await _monter(tester, refuse);
        expect(find.byKey(ClesLecteurMarkdown.illisible), findsOneWidget);
        expect(
          find.text(t.tc.bibliotheque.rendu.texteIllisible),
          findsOneWidget,
        );
        expect(find.byKey(ClesLecteurMarkdown.document), findsNothing);
      });
    }
  });

  group('garde d interface', () {
    for (final Size taille in const <Size>[Size(320, 900), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets(
            '${taille.width.toInt()} x$echelle $sens : aucun debordement, '
            'aucun defilement propre',
            (tester) async {
              await _monter(
                tester,
                _document,
                taille: taille,
                echelle: echelle,
                direction: sens,
              );
              expect(tester.takeException(), isNull);
              // La page seule defile : le lecteur ne pose aucun defilement.
              expect(
                find.descendant(
                  of: find.byKey(ClesLecteurMarkdown.document),
                  matching: find.byType(Scrollable),
                ),
                findsNothing,
              );
            },
          );
        }
      }
    }
  });
}
