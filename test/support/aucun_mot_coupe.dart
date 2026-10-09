// Le controle mesurable de la lecon 8 (K-54, K-61, COUPE-MOTS-1) : un
// libelle passe a la ligne ENTRE les mots, jamais dans un mot, et n'est pas
// tronque par une ellipse.
//
// Pour chaque paragraphe rendu sous un finder, chaque mot (suite de
// caracteres sans espace) est mesure par `getBoxesForSelection` : toutes ses
// boites doivent etre sur la meme ligne. Un « Remplacem / ent » donne deux
// boites a deux hauteurs differentes, et le test echoue en nommant le mot.

import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les mots coupes (ou tronques) des paragraphes trouves sous [ou], sous la
/// forme « texte : mot ». Vide quand tout est lisible.
///
/// [traitDUnionPermis] : vrai, un nom compose peut passer a la ligne apres
/// son trait d'union (« Classe Al- / Badr »), comme le fait le moteur de
/// texte de Flutter ; chaque partie doit alors rester entiere. Faux (defaut),
/// le mot compose doit tenir sur une ligne.
///
/// [exceptions] : les paragraphes (texte entier) exclus de la mesure, chacun
/// pour une raison ecrite par l'appelant (ellipse permise parce que le texte
/// entier est lu ailleurs, par exemple). Une liste EXPLICITE : tout le reste
/// de l'arbre sous [ou] est mesure.
List<String> motsCoupes(
  WidgetTester tester,
  Finder ou, {
  bool traitDUnionPermis = false,
  Set<String> exceptions = const <String>{},
}) {
  // L'espace sans chasse (U+200B) est un point de coupure voulu (une adresse
  // e-mail, `coupuresAdresse`) : elle separe deux mots comme une espace.
  final RegExp mot = traitDUnionPermis
      ? RegExp('[^\\s\u200B-]+-?')
      : RegExp('[^\\s\u200B]+');
  final List<String> fautes = <String>[];
  final Set<RenderParagraph> paragraphes = <RenderParagraph>{
    ...tester.renderObjectList<RenderObject>(ou).expand(_paragraphesSous),
  };
  for (final RenderParagraph p in paragraphes) {
    if (!p.hasSize || !p.attached) continue;
    final String texte = p.text.toPlainText();
    if (exceptions.contains(texte)) continue;
    if (p.didExceedMaxLines) {
      fautes.add('$texte : tronque');
    }
    for (final RegExpMatch m in mot.allMatches(texte)) {
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
void verifierAucunMotCoupe(
  WidgetTester tester,
  Finder ou, {
  Set<String> exceptions = const <String>{},
}) {
  expect(
    motsCoupes(tester, ou, exceptions: exceptions),
    isEmpty,
    reason: 'Un mot coupe ou tronque',
  );
}

/// L'ecran ENTIER (chaque `Scaffold` monte, corps, en-tetes, cartes, listes,
/// navigation) : aucun mot coupe ni tronque, sauf [exceptions].
void verifierEcranSansMotCoupe(
  WidgetTester tester, {
  Set<String> exceptions = const <String>{},
}) {
  final Finder ecrans = find.byType(Scaffold);
  expect(ecrans, findsWidgets, reason: 'Aucun ecran monte a mesurer');
  verifierAucunMotCoupe(tester, ecrans, exceptions: exceptions);
}

/// Une duree rendue : « 3 h 28 », « 2 h », « 45 min » (espaces ordinaires
/// ou insecables, U+00A0 et U+202F). Le mot qui suit l'unite ne compte pas
/// (« heures », « minutes » ne sont pas des unites courtes).
final RegExp motifDuree = RegExp(
  r'\d+[ \u00A0\u202F]*(?:h|min)(?![\p{L}])(?:[ \u00A0\u202F]*\d+)?',
  unicode: true,
);

/// DUREE-INSECABLE-1 : les durees des paragraphes trouves sous [ou].
///
/// [mesurees] : chaque duree rendue (« texte : duree »), pour prouver que la
/// mesure porte sur quelque chose ; [coupees] : celles qui occupent plus
/// d'une ligne (« Cours dans 3 h / 28 »). Le detecteur de mots
/// ([motsCoupes]) ne les voit pas : la coupure tombe ENTRE deux mots.
({List<String> mesurees, List<String> coupees}) mesurerDurees(
  WidgetTester tester,
  Finder ou,
) {
  final List<String> mesurees = <String>[];
  final List<String> coupees = <String>[];
  final Set<RenderParagraph> paragraphes = <RenderParagraph>{
    ...tester.renderObjectList<RenderObject>(ou).expand(_paragraphesSous),
  };
  for (final RenderParagraph p in paragraphes) {
    if (!p.hasSize || !p.attached) continue;
    final String texte = p.text.toPlainText();
    for (final RegExpMatch m in motifDuree.allMatches(texte)) {
      final String fiche = '$texte : ${m.group(0)}';
      mesurees.add(fiche);
      final List<TextBox> boites = p.getBoxesForSelection(
        TextSelection(baseOffset: m.start, extentOffset: m.end),
      );
      if (_lignesDistinctes(boites) > 1) {
        coupees.add(fiche);
      }
    }
  }
  return (mesurees: mesurees, coupees: coupees);
}

/// Echoue si une duree sous [ou] passe sur deux lignes, ou si aucune duree
/// n'y est rendue (la mesure doit porter sur quelque chose).
void verifierDureesSurUneLigne(WidgetTester tester, Finder ou) {
  final ({List<String> mesurees, List<String> coupees}) r = mesurerDurees(
    tester,
    ou,
  );
  expect(r.mesurees, isNotEmpty, reason: 'Aucune duree rendue a mesurer');
  expect(r.coupees, isEmpty, reason: 'Une duree scindee sur deux lignes');
}

/// COUPE-MOTS-3 : une taille de fichier rendue (« 8,1 Mo », « 640 Ko »),
/// espaces ordinaires ou insecables entre le nombre et l'unite.
final RegExp motifTaille = RegExp(
  r'\d+(?:[,.]\d+)?[ \u00A0\u202F]*(?:o|Ko|Mo|Go|To|KB|MB|GB|TB)(?![\p{L}\p{N}])',
  unicode: true,
);

/// COUPE-MOTS-3 : les tailles de fichier des paragraphes trouves sous [ou].
///
/// [mesurees] : chaque taille rendue (« texte : taille »), pour prouver que
/// la mesure porte sur quelque chose ; [coupees] : celles qui occupent plus
/// d'une ligne (« 8,1 / Mo »). Le detecteur de mots ([motsCoupes]) ne les
/// voit pas : la coupure tombe ENTRE deux mots.
({List<String> mesurees, List<String> coupees}) mesurerTailles(
  WidgetTester tester,
  Finder ou,
) {
  final List<String> mesurees = <String>[];
  final List<String> coupees = <String>[];
  final Set<RenderParagraph> paragraphes = <RenderParagraph>{
    ...tester.renderObjectList<RenderObject>(ou).expand(_paragraphesSous),
  };
  for (final RenderParagraph p in paragraphes) {
    if (!p.hasSize || !p.attached) continue;
    final String texte = p.text.toPlainText();
    for (final RegExpMatch m in motifTaille.allMatches(texte)) {
      final String fiche = '$texte : ${m.group(0)}';
      mesurees.add(fiche);
      final List<TextBox> boites = p.getBoxesForSelection(
        TextSelection(baseOffset: m.start, extentOffset: m.end),
      );
      if (_lignesDistinctes(boites) > 1) {
        coupees.add(fiche);
      }
    }
  }
  return (mesurees: mesurees, coupees: coupees);
}

/// COUPE-MOTS-4 : les ponctuations hautes (« ? ! : ; ») et les guillemets
/// fermants rendus seuls en debut de ligne, et les guillemets ouvrants
/// laisses seuls en fin de ligne, dans les paragraphes trouves sous [ou],
/// sous la forme « texte : signe ». La typographie francaise les lie au mot
/// voisin par une espace insecable ; une espace ordinaire les laisse partir
/// a la ligne (« Pourquoi ce changement / ? »).
List<String> ponctuationsIsolees(WidgetTester tester, Finder ou) {
  final List<String> fautes = <String>[];
  final Set<RenderParagraph> paragraphes = <RenderParagraph>{
    ...tester.renderObjectList<RenderObject>(ou).expand(_paragraphesSous),
  };
  final RegExp blanc = RegExp(r'\s');
  for (final RenderParagraph p in paragraphes) {
    if (!p.hasSize || !p.attached) continue;
    final String texte = p.text.toPlainText();
    for (int i = 0; i < texte.length; i++) {
      final String c = texte[i];
      final bool avant = '?!:;»'.contains(c);
      final bool apres = c == '«';
      if (!avant && !apres) continue;
      // Le voisin lie : le dernier caractere visible avant le signe, ou le
      // premier apres le guillemet ouvrant.
      int j = avant ? i - 1 : i + 1;
      while (j >= 0 && j < texte.length && blanc.hasMatch(texte[j])) {
        j += avant ? -1 : 1;
      }
      if (j < 0 || j >= texte.length || j == (avant ? i - 1 : i + 1)) {
        continue;
      }
      final List<TextBox> boites = <TextBox>[
        ...p.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1),
        ),
        ...p.getBoxesForSelection(
          TextSelection(baseOffset: j, extentOffset: j + 1),
        ),
      ];
      if (_lignesDistinctes(boites) > 1) {
        fautes.add('$texte : $c');
      }
    }
  }
  return fautes;
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
