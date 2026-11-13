import 'package:flutter/widgets.dart';

import '../theme/app_typography.dart';

/// Vrai quand [texte] contient au moins une lettre ou un signe de l'écriture
/// arabe (blocs arabe, supplément, étendu A, formes de présentation A et B).
bool contientArabe(String texte) {
  for (final int c in texte.runes) {
    if ((c >= 0x0600 && c <= 0x06FF) ||
        (c >= 0x0750 && c <= 0x077F) ||
        (c >= 0x08A0 && c <= 0x08FF) ||
        (c >= 0xFB50 && c <= 0xFDFF) ||
        (c >= 0xFE70 && c <= 0xFEFF)) {
      return true;
    }
  }
  return false;
}

/// Le style d'un texte de CONTENU (le titre, la description, une lettre ou un
/// mot d'un document) : si le texte contient de l'arabe, il se rend dans la
/// police du Coran (`AppFontFamily.arabeMushaf`, directeur, 13/11/2026), les
/// glyphes qu'elle ne porte pas (lettres latines, chiffres) retombant sur les
/// polices du document puis de l'interface. Sans arabe, le style est rendu tel
/// quel. **L'arabe d'interface (menus, boutons, libellés) ne passe jamais
/// ici** : il garde sa police.
TextStyle? styleContenuArabe(String texte, TextStyle? base) =>
    contientArabe(texte) ? AppTypography.arabeContenu(base) : base;

/// Vrai quand la première lettre « forte » de [texte] est arabe : le texte se
/// lit alors de droite à gauche (un point final à gauche, jamais à droite).
bool commenceParArabe(String texte) {
  for (final int c in texte.runes) {
    if (contientArabe(String.fromCharCode(c))) return true;
    final String lettre = String.fromCharCode(c);
    if (lettre.toLowerCase() != lettre.toUpperCase()) return false;
  }
  return false;
}

/// Pose [enfant] en sens droite-gauche quand [texte] est un contenu arabe,
/// même dans une interface française ; sinon rend [enfant] tel quel.
Widget dirigerContenuArabe(String texte, Widget enfant) =>
    commenceParArabe(texte)
    ? Directionality(textDirection: TextDirection.rtl, child: enfant)
    : enfant;
