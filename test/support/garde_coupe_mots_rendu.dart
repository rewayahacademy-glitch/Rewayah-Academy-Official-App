// COUPE-MOTS-FOND-1 : la garde des mots coupes et rognes, sur le RENDU.
//
// Au lieu de corriger les ecrans montres un par un (FILTRES-1b,
// COUPE-MOTS-4, PAGESHELL-200-1e, PUB-1b, EA-HL-DOUBLE-1f), une seule garde
// lit ce que l'ecran dessine vraiment, sur chaque paragraphe VISIBLE :
//
//   * tronque : une ellipse ou une ligne de trop (`didExceedMaxLines`) ;
//   * mot coupe : un mot dont les boites tombent sur deux lignes (les lignes
//     calculees par le moteur de texte, `getBoxesForSelection`), un nom
//     compose pouvant passer a la ligne apres son trait d'union ordinaire ;
//     un identifiant technique (traits, insecables ou non, soulignes, meme
//     avec une espace sans chasse) est un seul mot ;
//   * ponctuation seule : « ? ! : ; » ou un guillemet seul a la ligne ;
//     et, dans un paragraphe RTL sans arabe (repli francais), un signe
//     final dont la boite n'est pas collee a son mot sur la ligne VISUELLE
//     (« ? changement », « .trancher ») ;
//   * rogne : un texte sur une ligne plus large que sa boite, ou un texte
//     coupe par le bord d'un ancetre qui le decoupe (ou de l'ecran), hors
//     defilement horizontal ;
//   * rangee de filtres : un bord qui cache une puce sans fondu, ou une puce
//     coupee visible au-dela de son fondu ;
//   * debordement : toute exception de rendu (`RenderFlex overflowed`).
//
// Les paragraphes des branches inactives (`Offstage`, `IndexedStack`) ne
// comptent pas : l'utilisateur ne les voit pas.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import 'aucun_mot_coupe.dart';

/// Un gabarit de la garde : taille logique et echelle du texte.
typedef GabaritGarde = ({String nom, Size taille, double echelle});

/// Les gabarits de la fiche : 320 x 568 texte x2, 390 x 844, 1440 x 900
/// texte x2.
const List<GabaritGarde> gabaritsGarde = <GabaritGarde>[
  (nom: '320x2', taille: Size(320, 568), echelle: 2),
  (nom: '390', taille: Size(390, 844), echelle: 1),
  (nom: '1440x2', taille: Size(1440, 900), echelle: 2),
];

/// Tolerance de mesure, en pixels logiques.
const double _tolerance = 1;

/// Vrai quand [o] est dessine : aucun ancetre `Offstage` ferme, et dans un
/// `IndexedStack`, seule la branche affichee.
bool rendreVisible(RenderObject o) {
  RenderObject enfant = o;
  RenderObject? parent = o.parent;
  while (parent != null) {
    if (parent is RenderOffstage && parent.offstage) return false;
    if (parent is RenderIndexedStack) {
      final int? index = parent.index;
      int i = 0;
      bool affiche = false;
      parent.visitChildren((RenderObject c) {
        if (identical(c, enfant)) affiche = i == index;
        i++;
      });
      if (!affiche) return false;
    }
    if (parent is RenderAnimatedOpacity && parent.opacity.value == 0) {
      return false;
    }
    if (parent is RenderOpacity && parent.opacity == 0) return false;
    enfant = parent;
    parent = parent.parent;
  }
  return true;
}

/// Les textes visibles de tout l'arbre monte.
Finder textesVisibles() => find.byElementPredicate((Element e) {
  if (e.widget is! RichText) return false;
  final RenderObject? r = e.renderObject;
  if (r is! RenderParagraph || !r.attached || !r.hasSize) return false;
  if (r.size.isEmpty) return false;
  return rendreVisible(r);
});

/// Le rectangle global d'un rendu.
Rect _global(RenderBox b) =>
    MatrixUtils.transformRect(b.getTransformTo(null), Offset.zero & b.size);

/// Vrai quand un ancetre de [e] defile horizontalement.
bool _dansDefilementHorizontal(Element e) {
  bool trouve = false;
  e.visitAncestorElements((Element a) {
    if (a is StatefulElement &&
        a.state is ScrollableState &&
        axisDirectionToAxis((a.state as ScrollableState).axisDirection) ==
            Axis.horizontal) {
      trouve = true;
      return false;
    }
    return true;
  });
  return trouve;
}

/// La zone ou [p] peut se dessiner : l'ecran, coupe par chaque ancetre qui
/// decoupe son contenu (hors defilements verticaux, qui laissent voir le
/// reste en defilant).
Rect _zoneDessinable(RenderObject p, Size ecran) {
  Rect zone = Offset.zero & ecran;
  for (RenderObject? a = p.parent; a != null; a = a.parent) {
    if (a is! RenderBox || !a.hasSize) continue;
    final bool decoupe = switch (a) {
      RenderClipRect(clipBehavior: final Clip c) => c != Clip.none,
      RenderClipRRect(clipBehavior: final Clip c) => c != Clip.none,
      RenderClipPath(clipBehavior: final Clip c) => c != Clip.none,
      _ => false,
    };
    if (decoupe) zone = zone.intersect(_global(a));
  }
  return zone;
}

/// Les textes rognes parmi [textes] : une ligne plus large que sa boite
/// (texte sans retour a la ligne), ou un texte que le bord d'un ancetre ou
/// de l'ecran coupe en largeur.
List<String> textesRognes(WidgetTester tester, Finder textes) {
  final Size ecran = tester.view.physicalSize / tester.view.devicePixelRatio;
  final List<String> fautes = <String>[];
  for (final Element e in textes.evaluate()) {
    final RenderParagraph p = e.renderObject! as RenderParagraph;
    final String texte = p.text.toPlainText();
    if (texte.trim().isEmpty) continue;
    if (!p.softWrap || p.maxLines == 1) {
      final double besoin = p.getMaxIntrinsicWidth(double.infinity);
      if (besoin > p.size.width + _tolerance && !p.didExceedMaxLines) {
        fautes.add('$texte : rogne dans sa boite');
        continue;
      }
    }
    if (_dansDefilementHorizontal(e)) continue;
    // La largeur reellement occupee par les glyphes.
    final List<TextBox> boites = p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: texte.length),
    );
    if (boites.isEmpty) continue;
    Rect local = boites.first.toRect();
    for (final TextBox b in boites.skip(1)) {
      local = local.expandToInclude(b.toRect());
    }
    final Rect glyphes = MatrixUtils.transformRect(
      p.getTransformTo(null),
      local,
    );
    final Rect zone = _zoneDessinable(p, ecran);
    if (glyphes.left < zone.left - _tolerance ||
        glyphes.right > zone.right + _tolerance) {
      fautes.add('$texte : rogne au bord');
    }
  }
  return fautes;
}

/// Les rangees de filtres dont un bord cache du contenu sans le dire :
/// chaque cote qui cache une puce (entiere ou en partie) porte un fondu, et
/// la partie visible d'une puce coupee tient dans ce fondu (qui couvre au
/// plus la moitie de la rangee).
///
/// Ce qui est lu sans passer par le composant : la geometrie des puces
/// (leurs rectangles a l'ecran) et le CALQUE reellement compose
/// (`ShaderMaskLayer`) : quand un bord cache une puce, le masque doit etre
/// actif (`BlendMode.dstIn`) et couvrir la rangee. Seules les largeurs du
/// degrade viennent du rendu (`etatPeint`, l'etat tel qu'il a ete peint),
/// car un shader ne se relit pas.
List<String> rangeesSansFondu(WidgetTester tester) {
  final List<String> fautes = <String>[];
  for (final Element e in find.byType(FonduBordsRangee).evaluate()) {
    final RenderObject? r = e.renderObject;
    if (r is! RenduFonduBordsRangee || !r.hasSize || !rendreVisible(r)) {
      continue;
    }
    final TextDirection sens = Directionality.of(e);
    final Rect vue = _global(r);
    // Les puces : chaque enfant de la rangee.
    final List<Rect> puces = <Rect>[];
    void chercher(RenderObject o) {
      // L4-07 : la rangee pose les puces qui tiennent et « Plus » ; les
      // autres, rangees sous « Plus », ne sont ni peintes ni a l'ecran.
      if (o is RenduRangeeFiltres) {
        for (final RenderBox c in o.montres) {
          if (c.hasSize) puces.add(_global(c));
        }
        return;
      }
      if (o is RenderFlex && o.direction == Axis.horizontal) {
        o.visitChildren((RenderObject c) {
          if (c is RenderBox && c.hasSize) puces.add(_global(c));
        });
        return;
      }
      o.visitChildren(chercher);
    }

    r.visitChildren(chercher);
    final String nom = e.toStringShort();
    final bool cachee = puces.any(
      (Rect p) =>
          p.left < vue.left - _tolerance || p.right > vue.right + _tolerance,
    );
    // Le calque compose, lu independamment de l'etat du composant.
    final Layer? calque = r.debugLayer;
    final bool masqueActif =
        calque is ShaderMaskLayer &&
        calque.blendMode == BlendMode.dstIn &&
        calque.maskRect != null &&
        calque.maskRect!.width >= r.size.width - _tolerance;
    if (cachee && !masqueActif) {
      fautes.add('$nom : puce cachee, aucun masque de fondu compose');
      continue;
    }
    final EtatFonduRangee f = r.etatPeint;
    // Les bords physiques : gauche et droite, selon le sens de lecture.
    final bool gaucheEstDebut = sens == TextDirection.ltr;
    final bool fonduGauche = gaucheEstDebut ? f.avant : f.apres;
    final bool fonduDroite = gaucheEstDebut ? f.apres : f.avant;
    final double largeurGauche = gaucheEstDebut
        ? f.largeurAvant
        : f.largeurApres;
    final double largeurDroite = gaucheEstDebut
        ? f.largeurApres
        : f.largeurAvant;
    for (final Rect p in puces) {
      if (p.left < vue.left - _tolerance) {
        if (!fonduGauche) {
          fautes.add('$nom : puce cachee a gauche sans fondu');
        } else if (p.right > vue.left + largeurGauche + _tolerance &&
            largeurGauche < vue.width / 2 - _tolerance) {
          fautes.add(
            '$nom : puce coupee a gauche, visible au-dela du fondu '
            '(${(p.right - vue.left).toStringAsFixed(0)} > '
            '${largeurGauche.toStringAsFixed(0)})',
          );
        }
      }
      if (p.right > vue.right + _tolerance) {
        if (!fonduDroite) {
          fautes.add('$nom : puce cachee a droite sans fondu');
        } else if (p.left < vue.right - largeurDroite - _tolerance &&
            largeurDroite < vue.width / 2 - _tolerance) {
          fautes.add(
            '$nom : puce coupee a droite, visible au-dela du fondu '
            '(${(vue.right - p.left).toStringAsFixed(0)} > '
            '${largeurDroite.toStringAsFixed(0)})',
          );
        }
      }
    }
  }
  return fautes;
}

/// Un identifiant technique, quel que soit le caractere place entre ses
/// segments : « TEACHER-AS-000001 » (trait ordinaire ou insecable U+2011,
/// segments en capitales et chiffres, un chiffre au moins) ou
/// « observation_entry_recorded » (soulignes). Une espace sans chasse
/// (U+200B) glissee a cote d'un trait ou d'un souligne ne le scinde pas :
/// il reste UN mot (COUPE-MOTS-FOND-1, point 2).
final RegExp _identifiant = RegExp(
  '(?<![A-Za-z0-9])(?:'
  '(?=[A-Z0-9\u200B\u2011-]*[0-9])'
  '[A-Z0-9]+(?:\u200B?[-\u2011]\u200B?[A-Z0-9]+)+'
  '|[a-z0-9]+(?:\u200B?_\u200B?[a-z0-9]+)+'
  ')(?![A-Za-z0-9])',
);

/// Les identifiants coupes parmi [textes] : un identifiant technique dont
/// les glyphes tombent sur deux lignes, meme a un point de coupure voulu
/// (trait ordinaire, espace sans chasse). Un identifiant ne se coupe jamais :
/// il se reduit, ou sa place change (sous-titre, cartes).
List<String> identifiantsCoupes(WidgetTester tester, Finder textes) {
  final List<String> fautes = <String>[];
  for (final Element e in textes.evaluate()) {
    final RenderParagraph p = e.renderObject! as RenderParagraph;
    final String texte = p.text.toPlainText();
    for (final RegExpMatch m in _identifiant.allMatches(texte)) {
      final List<TextBox> boites = p.getBoxesForSelection(
        TextSelection(baseOffset: m.start, extentOffset: m.end),
      );
      final Set<double> lignes = <double>{};
      for (final TextBox b in boites) {
        if (lignes.every((double h) => (h - b.top).abs() > b.bottom - b.top)) {
          lignes.add(b.top);
        }
      }
      if (lignes.length > 1) {
        fautes.add('$texte : identifiant coupe ${m.group(0)}');
      }
    }
  }
  return fautes;
}

/// Le marqueur de dette qui excuse les exceptions de rendu d'un ecran
/// (`dette_coupe_mots.dart`) : elles sont prises, pas comptees.
const String debordementConnu = '!debordement connu';

/// Toutes les exceptions de rendu en attente (debordements compris).
List<String> exceptionsDeRendu(WidgetTester tester) {
  final List<String> fautes = <String>[];
  for (
    Object? x = tester.takeException();
    x != null;
    x = tester.takeException()
  ) {
    final String brut = x.toString();
    fautes.add('exception : ${brut.split('\n').first}');
  }
  return fautes;
}

/// Les defauts de texte de l'ecran tel qu'il est dessine maintenant.
///
/// [exceptions] : des textes entiers exclus, chacun pour une raison ecrite
/// par l'appelant.
///
/// [ligneVisuelleRtl] : la ponctuation d'un texte latin dans un paragraphe
/// RTL est lue sur la ligne VISUELLE (defaut) ; faux seulement pour un ecran
/// dont l'arabe est connu incomplet (`ecransTraduitsEnArabe`).
List<String> defautsDeTexte(
  WidgetTester tester, {
  Set<String> exceptions = const <String>{},
  bool ligneVisuelleRtl = true,
}) {
  final Set<Element> visibles = textesVisibles().evaluate().where((Element e) {
    final String texte = (e.renderObject! as RenderParagraph).text
        .toPlainText();
    return !exceptions.contains(texte);
  }).toSet();
  final Finder mesures = find.byElementPredicate(visibles.contains);
  return <String>[
    ...exceptionsDeRendu(tester)
        .where((String _) => !exceptions.contains(debordementConnu)),
    ...motsCoupes(tester, mesures, traitDUnionPermis: true),
    ...identifiantsCoupes(tester, mesures),
    ...ponctuationsIsolees(tester, mesures, ligneVisuelleRtl: ligneVisuelleRtl),
    ...textesRognes(tester, mesures),
    ...rangeesSansFondu(tester),
  ];
}

/// Les defauts de l'ecran entier, page defilee de haut en bas : chaque
/// defilement vertical est mesure a son debut, puis page par page JUSQU'A
/// SA FIN (une liste paresseuse ne construit que ce qui se voit, et sa fin
/// recule a mesure qu'elle se construit : elle est relue a chaque pas).
///
/// [pagesMax] n'est qu'un garde-fou contre une liste sans fin : l'atteindre
/// est un defaut ecrit (« bas de page non mesure »), jamais un silence.
Future<List<String>> defautsEcranDefile(
  WidgetTester tester, {
  Set<String> exceptions = const <String>{},
  int pagesMax = 200,
  bool ligneVisuelleRtl = true,
}) async {
  final Set<String> fautes = <String>{
    ...defautsDeTexte(
      tester,
      exceptions: exceptions,
      ligneVisuelleRtl: ligneVisuelleRtl,
    ),
  };
  final List<ScrollableState> verticaux = <ScrollableState>[
    for (final Element e in find.byType(Scrollable).evaluate())
      if ((e as StatefulElement).state case final ScrollableState s)
        if (axisDirectionToAxis(s.axisDirection) == Axis.vertical &&
            e.renderObject != null &&
            rendreVisible(e.renderObject!) &&
            s.position.hasContentDimensions &&
            s.position.maxScrollExtent > 0)
          s,
  ];
  for (final ScrollableState s in verticaux) {
    if (!s.mounted) continue;
    final ScrollPosition pos = s.position;
    final double pas = pos.viewportDimension * 0.8;
    int pages = 0;
    while (s.mounted && pos.pixels < pos.maxScrollExtent - 0.5) {
      if (pages == pagesMax) {
        fautes.add(
          '${s.widget.runtimeType} : bas de page non mesure apres '
          '$pagesMax pages',
        );
        break;
      }
      pos.jumpTo(
        (pos.pixels + pas).clamp(pos.minScrollExtent, pos.maxScrollExtent),
      );
      await tester.pump();
      pages++;
      fautes.addAll(
        defautsDeTexte(
          tester,
          exceptions: exceptions,
          ligneVisuelleRtl: ligneVisuelleRtl,
        ),
      );
    }
    if (s.mounted) {
      pos.jumpTo(pos.minScrollExtent);
      await tester.pump();
    }
  }
  return fautes.toList();
}
