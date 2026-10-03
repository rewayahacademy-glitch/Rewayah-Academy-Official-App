// Le controle mesurable de la lecon 8 (K-54, K-61, COUPE-MOTS-1) : un
// libelle passe a la ligne ENTRE les mots, jamais dans un mot, et n'est pas
// tronque par une ellipse.
//
// Pour chaque paragraphe rendu sous un finder, chaque mot (suite de
// caracteres sans espace) est mesure par `getBoxesForSelection` : toutes ses
// boites doivent etre sur la meme ligne. Un « Remplacem / ent » donne deux
// boites a deux hauteurs differentes, et le test echoue en nommant le mot.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les mots coupes (ou tronques) des paragraphes trouves sous [ou], sous la
/// forme « texte : mot ». Vide quand tout est lisible.
List<String> motsCoupes(WidgetTester tester, Finder ou) {
  final List<String> fautes = <String>[];
  final Iterable<RenderParagraph> paragraphes = tester
      .renderObjectList<RenderObject>(ou)
      .expand(_paragraphesSous);
  for (final RenderParagraph p in paragraphes) {
    final String texte = p.text.toPlainText();
    if (p.didExceedMaxLines) {
      fautes.add('$texte : tronque');
    }
    for (final RegExpMatch m in RegExp(r'\S+').allMatches(texte)) {
      final List<TextBox> boites = p.getBoxesForSelection(
        TextSelection(baseOffset: m.start, extentOffset: m.end),
      );
      // Deux boites sont sur la meme ligne quand leurs hauteurs se
      // recouvrent : un glyphe d'une police de repli (le trait d'union
      // insecable U+2011 de « An‑Nour ») a une boite plus haute sur la MEME
      // ligne (BENTO-3) ; un mot coupe a deux boites l'une sous l'autre.
      if (_lignesDistinctes(boites) > 1) {
        fautes.add('$texte : ${m.group(0)}');
      }
    }
  }
  return fautes;
}

/// Echoue en nommant chaque mot coupe sous [ou].
void verifierAucunMotCoupe(WidgetTester tester, Finder ou) {
  expect(motsCoupes(tester, ou), isEmpty, reason: 'Un mot coupe ou tronque');
}

/// Le nombre de lignes occupees par [boites] : une boite appartient a une
/// ligne deja vue quand son milieu vertical tombe dans la hauteur d'une
/// boite de cette ligne ; sinon elle ouvre une nouvelle ligne.
int _lignesDistinctes(List<TextBox> boites) {
  final List<TextBox> lignes = <TextBox>[];
  for (final TextBox b in boites) {
    final double milieu = (b.top + b.bottom) / 2;
    final bool connue = lignes.any(
      (TextBox l) =>
          (milieu >= l.top && milieu <= l.bottom) ||
          ((l.top + l.bottom) / 2 >= b.top &&
              (l.top + l.bottom) / 2 <= b.bottom),
    );
    if (!connue) {
      lignes.add(b);
    }
  }
  return lignes.length;
}

Iterable<RenderParagraph> _paragraphesSous(RenderObject racine) {
  final List<RenderParagraph> trouves = <RenderParagraph>[];
  void visiter(RenderObject o) {
    if (o is RenderParagraph) {
      trouves.add(o);
    }
    o.visitChildren(visiter);
  }

  visiter(racine);
  return trouves;
}
