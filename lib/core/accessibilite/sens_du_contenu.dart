// Le sens d'ecriture d'un contenu ecrit par une personne (message, publication,
// reponse, annonce), lu sur le contenu lui-meme et non sur la langue de
// l'interface (COM-RC tour 3).
//
// En arabe, un message ecrit en francais rendu de droite a gauche mettait son
// point final en tete de ligne (« .eleves »). Le contenu prend le sens de sa
// premiere lettre (algorithme bidi, regle P2 : premier caractere fort) ; un
// contenu sans lettre (chiffres, symboles) garde le sens de l'interface. Les
// textes de l'interface ne passent jamais par ici.

import 'package:flutter/widgets.dart';

/// Une lettre (toutes ecritures).
final RegExp _lettre = RegExp(r'\p{L}', unicode: true);

/// Les ecritures de droite a gauche : hebreu, arabe, syriaque, thaana, nko,
/// samaritain, mandeen, et leurs formes de presentation.
bool _deDroiteAGauche(int point) =>
    (point >= 0x0590 && point <= 0x08FF) ||
    (point >= 0xFB1D && point <= 0xFDFF) ||
    (point >= 0xFE70 && point <= 0xFEFF) ||
    (point >= 0x10800 && point <= 0x10FFF) ||
    (point >= 0x1E800 && point <= 0x1EFFF);

/// Le sens de [texte] d'apres sa premiere lettre, ou [parDefaut] s'il n'en a
/// aucune.
TextDirection sensDeTexte(String texte, TextDirection parDefaut) {
  final RegExpMatch? premiere = _lettre.firstMatch(texte);
  if (premiere == null) return parDefaut;
  final int point = premiere.group(0)!.runes.first;
  return _deDroiteAGauche(point) ? TextDirection.rtl : TextDirection.ltr;
}

/// Le sens de [texte], contenu ecrit par une personne, a donner a son `Text`
/// (`textDirection:`) ; a defaut de lettre, celui de l'interface.
TextDirection sensDuContenu(BuildContext context, String texte) =>
    sensDeTexte(texte, Directionality.of(context));
