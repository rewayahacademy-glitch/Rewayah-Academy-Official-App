// Le sens d'ecriture d'une chaine, lu dans la chaine elle-meme.
//
// DOCK-X2-1 (complement de la fiche, defaut bidi anterieur) : une phrase
// francaise posee dans une interface de droite a gauche (traduction arabe
// absente, la chaine retombe sur le francais) recevait le sens de l'arbre ;
// son point final, neutre, passait alors en tete (« .controle possible »).
// Comme MUSHAF-DIR-1, la phrase garde le sens de SA langue : celui de son
// premier caractere fort.

import 'package:flutter/widgets.dart'
    show BuildContext, Directionality, TextAlign, TextDirection;

/// Le sens de [texte] : droite a gauche si son premier caractere fort est
/// arabe ou hebreu, gauche a droite s'il est latin (ou tout autre alphabet
/// de gauche a droite), [parDefaut] s'il n'a aucun caractere fort.
TextDirection sensDuTexte(
  String texte, {
  TextDirection parDefaut = TextDirection.ltr,
}) {
  for (final int c in texte.runes) {
    if (_droiteAGauche(c)) return TextDirection.rtl;
    if (_fortGaucheADroite(c)) return TextDirection.ltr;
  }
  return parDefaut;
}

/// Hebreu, arabe, syriaque, thaana, n'ko, samaritain, mandeen, supplement et
/// formes de presentation arabes.
bool _droiteAGauche(int c) =>
    (c >= 0x0590 && c <= 0x08FF) ||
    (c >= 0xFB1D && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF);

/// Une lettre de gauche a droite : latin (avec ses accents), grec, cyrillique
/// et au-dela. Chiffres, ponctuation et espaces sont neutres ou faibles.
bool _fortGaucheADroite(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0xC0 && c <= 0x024F && c != 0xD7 && c != 0xF7) ||
    (c >= 0x0370 && c <= 0x058F);

/// Le debut de la ligne au sens de l'INTERFACE (gauche en francais, droite
/// en arabe), quel que soit le sens propre du texte : une phrase francaise
/// d'une interface de droite a gauche reste calee a droite, pres de son
/// point d'enregistrement, tout en gardant son point final a la fin.
TextAlign alignementDebut(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? TextAlign.right
    : TextAlign.left;
