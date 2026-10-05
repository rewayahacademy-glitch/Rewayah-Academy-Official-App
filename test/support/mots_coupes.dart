import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les mots coupes au milieu sous [racine] : un mot dont les boites tombent
/// sur plus d'une ligne (FI-2-CORR-MINEURS, factorise en FI-COUPE-2).
///
/// Le trait d'union d'un mot compose est une coupure admise par la
/// typographie francaise : « mois- / ci », « An- / Nour » passent a la ligne
/// sur le trait que le texte porte deja, sans en inserer aucun. Chaque
/// segment termine par son trait est donc mesure seul (R8-03) ; une coupure
/// ailleurs dans le segment reste un mot coupe.
///
/// [sauf] exclut les textes poses sous les widgets qu'il trouve : une zone
/// hors du perimetre mesure, dont l'exception est ecrite par l'appelant
/// (R8-03 : la barre basse de la coquille, R8-01, hors vague).
List<String> motsCoupes(WidgetTester tester, Finder racine, {Finder? sauf}) {
  final Set<Element> exclus = sauf == null
      ? <Element>{}
      : find
            .descendant(of: sauf, matching: find.byType(RichText))
            .evaluate()
            .toSet();
  final List<String> coupes = <String>[];
  for (final Element e
      in find
          .descendant(of: racine, matching: find.byType(RichText))
          .evaluate()) {
    if (exclus.contains(e)) continue;
    final RenderParagraph p = e.renderObject! as RenderParagraph;
    final String texte = p.text.toPlainText();
    for (final RegExpMatch m in RegExp(r'[^\s-]*-|[^\s-]+').allMatches(texte)) {
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
