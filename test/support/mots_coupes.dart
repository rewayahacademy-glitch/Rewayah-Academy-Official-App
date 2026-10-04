import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les mots coupes au milieu sous [racine] : un mot dont les boites tombent
/// sur plus d'une ligne (FI-2-CORR-MINEURS, factorise en FI-COUPE-2).
List<String> motsCoupes(WidgetTester tester, Finder racine) {
  final List<String> coupes = <String>[];
  for (final Element e
      in find
          .descendant(of: racine, matching: find.byType(RichText))
          .evaluate()) {
    final RenderParagraph p = e.renderObject! as RenderParagraph;
    final String texte = p.text.toPlainText();
    for (final RegExpMatch m in RegExp(r'\S+').allMatches(texte)) {
      final Set<double> lignes = <double>{
        for (final TextBox b in p.getBoxesForSelection(
          TextSelection(baseOffset: m.start, extentOffset: m.end),
        ))
          b.top.roundToDouble(),
      };
      if (lignes.length > 1) coupes.add(m.group(0)!);
    }
  }
  return coupes;
}
