// EN-TETES AU TELEPHONE (10/11/2026) : au telephone, sous 600, la barre compacte
// d'une page de niveau 2 abrege un titre qui ne tient pas en deux lignes, en
// fin de mot et suivi de « … » (le titre entier reste lu par le lecteur
// d'ecran et en infobulle). Avec la police de test (chaque lettre aussi large
// que le corps), presque tout titre est abrege : un test qui cherche le titre
// d'une page le cherche donc entier OU abrege.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les `Text` qui portent [titre], entier ou abrege par la barre compacte :
/// ses premiers mots entiers, puis « … ».
Finder titreDePage(String titre) => find.byWidgetPredicate((Widget w) {
  if (w is! Text) return false;
  // Sans le joint invisible (U+2060) qu'un nom compose recoit pour ne pas se
  // couper apres son trait d'union (« An-Nour »).
  final String? texte = (w.data ?? w.textSpan?.toPlainText())?.replaceAll(
    '\u2060',
    '',
  );
  if (texte == null) return false;
  if (texte == titre) return true;
  if (!texte.endsWith('…')) return false;
  final String debut = texte.substring(0, texte.length - 1);
  return debut.isNotEmpty &&
      titre.length > debut.length &&
      titre.startsWith(debut) &&
      (titre[debut.length] == ' ' || titre[debut.length] == '\u00A0');
}, description: 'titre de page « $titre » (entier ou abrege)');
