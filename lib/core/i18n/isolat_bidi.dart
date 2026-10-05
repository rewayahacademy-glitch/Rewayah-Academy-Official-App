// Isolat bidirectionnel a sens detecte (Unicode UAX #9, FSI U+2068 ...
// PDI U+2069), partage par les ecrans qui melangent les ecritures
// (COUPE-MOTS-2, CTRL-ROSTER-C7-1b).
//
// Un nom ecrit dans un autre sens que l'interface se lit mal sans isolat :
// la ponctuation neutre qui le suit se place du mauvais cote. « Mariam S. »
// dans une interface arabe s'affichait « .Mariam S » ; « عائشة ن. » dans une
// interface francaise portait son point au debut du nom, dans le sens de
// lecture arabe. Dans l'isolat, le texte prend le sens de son premier
// caractere fort et ne change pas l'ordre des segments voisins.
//
// A n'employer qu'a l'affichage : les donnees (rapports, roster) gardent le
// texte nu.

import 'dart:ui' show TextDirection;

/// Isole [texte] dans son propre sens de lecture (premier caractere fort),
/// sans changer l'ordre des segments voisins. Un texte vide reste vide.
String isolerSens(String texte) => texte.isEmpty ? texte : '\u2068$texte\u2069';

/// Le sens du premier caractere fort de [texte] (UAX #9, regle P2) : droite
/// a gauche pour l'hebreu et l'arabe, gauche a droite pour toute autre
/// lettre. Nul quand [texte] n'a aucune lettre (chiffres, ponctuation).
TextDirection? sensDuTexte(String texte) {
  for (final int c in texte.runes) {
    final bool droiteAGauche =
        (c >= 0x0590 && c <= 0x08FF) ||
        (c >= 0xFB1D && c <= 0xFDFF) ||
        (c >= 0xFE70 && c <= 0xFEFF) ||
        (c >= 0x10800 && c <= 0x10FFF) ||
        (c >= 0x1E800 && c <= 0x1EFFF);
    if (droiteAGauche) return TextDirection.rtl;
    if (_lettre.hasMatch(String.fromCharCode(c))) return TextDirection.ltr;
  }
  return null;
}

final RegExp _lettre = RegExp(r'\p{L}', unicode: true);

/// COUPE-MOTS-3b : [texte] isole ([isolerSens]) seulement quand il s'ecrit
/// dans l'autre sens que l'interface [sens]. Une phrase francaise dans
/// l'interface arabe (libelle encore sans traduction, donnee de
/// demonstration) ne s'affiche plus « .l'envoi », « % 60 » ni « · Élève
/// précis » ; un texte deja dans le sens de l'interface reste tel quel.
String isolerSiAutreSens(String texte, TextDirection sens) {
  final TextDirection? propre = sensDuTexte(texte);
  return propre == null || propre == sens ? texte : isolerSens(texte);
}
