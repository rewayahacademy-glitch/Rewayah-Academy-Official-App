// AR-SALLE-1 / AR-TC-1 (revue du 09/10) : une donnee latine (prenom, titre,
// date, compteur venus des donnees) rendue dans un paragraphe de droite a
// gauche doit etre isolee (U+2068 ... U+2069), sinon l'algorithme bidi
// renvoie ses chiffres et sa ponctuation de bord du mauvais cote
// (« Chapitre 1 (les bonnes manieres) » rendu « les bonnes) (manieres »).
//
// Ce que lit ce module : le texte REELLEMENT confie au moteur de rendu
// (chaque `RenderParagraph` de l'arbre) et le sens de son paragraphe.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final RegExp _isolat = RegExp('\u2068[^\u2068\u2069]*\u2069');
final RegExp _horsArabe = RegExp('[^؀-ۿ\u2063]+');
final RegExp _lettreLatine = RegExp('[A-Za-zÀ-ɏ]');
final RegExp _finSure = RegExp('[A-Za-zÀ-ɏ0-9]');

/// Le texte sans ses segments isoles (remplaces par un separateur neutre).
String _sansIsolats(String texte) {
  String avant;
  String apres = texte;
  do {
    avant = apres;
    apres = avant.replaceAll(_isolat, '\u2063');
  } while (apres != avant);
  return apres;
}

/// Les segments latins de [texte] qui, dans un paragraphe RTL, sortent dans
/// le desordre : un segment hors isolat, contenant une lettre latine, qui
/// finit par autre chose qu'une lettre ou un chiffre (la ponctuation de fin
/// passe du cote arabe), ou qui OUVRE la ligne par autre chose qu'une lettre
/// (« 3 seances » sort « seances 3 »). Un separateur pose entre un mot arabe
/// et une donnee (« درس · Bonnes manieres ») reste a sa place : il n'est pas
/// signale.
List<String> segmentsLatinsBrouilles(String texte) {
  final List<String> sortie = <String>[];
  for (final String ligne in _sansIsolats(texte).split('\n')) {
    for (final Match m in _horsArabe.allMatches(ligne)) {
      final String segment = m[0]!.trim();
      if (segment.isEmpty || !_lettreLatine.hasMatch(segment)) continue;
      final bool apresArabe =
          m.start > 0 && ligne.codeUnitAt(m.start - 1) != 0x2063;
      final String premier = segment.substring(0, 1);
      final String dernier = segment.substring(segment.length - 1);
      final bool debutBrouille =
          !apresArabe && !_lettreLatine.hasMatch(premier);
      if (debutBrouille || !_finSure.hasMatch(dernier)) sortie.add(segment);
    }
  }
  return sortie;
}

/// Les textes rendus de droite a gauche dont une donnee latine est brouillee.
List<String> paragraphesRtlBrouilles(WidgetTester tester) {
  final List<String> sortie = <String>[];
  final Iterable<RenderParagraph> paragraphes = tester.allRenderObjects
      .whereType<RenderParagraph>();
  for (final RenderParagraph p in paragraphes) {
    if (p.textDirection != TextDirection.rtl) continue;
    final String texte = p.text.toPlainText(includeSemanticsLabels: false);
    if (segmentsLatinsBrouilles(texte).isNotEmpty) sortie.add(texte);
  }
  return sortie;
}
