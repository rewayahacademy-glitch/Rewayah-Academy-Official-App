// AR-SALLE-1 / AR-TC-1 (revue du 09/10) : une donnee (prenom, titre, date,
// compteur venus des donnees, en latin) rendue dans un paragraphe de droite a
// gauche garde son propre sens de lecture.
//
// Sans isolation, « Chapitre 1 (les bonnes manieres) » sort
// « les bonnes) (manieres » et « 3 seances cette semaine » sort
// « seances cette semaine 3 » : l'algorithme bidi range les chiffres et la
// ponctuation de bord du cote du paragraphe arabe. Les libelles (slang)
// isolent deja leurs parametres ; ce module isole la donnee rendue seule.

import 'package:flutter/widgets.dart';

/// Isole chaque ligne de [texte] (U+2068 ... U+2069) : la ligne prend le sens
/// de son premier caractere fort, sans deplacer ses voisines. Une ligne vide
/// reste vide (un isolat ne franchit pas une fin de paragraphe).
String isolerDonnee(String texte) => texte
    .split('\n')
    .map((String ligne) => ligne.isEmpty ? ligne : '\u2068$ligne\u2069')
    .join('\n');

/// [texte] isole quand le contexte lit de droite a gauche, inchange sinon :
/// en francais, la donnee reste le texte exact (lecture, recherche, tests).
String donneeDansLeSens(BuildContext context, String texte) =>
    Directionality.of(context) == TextDirection.rtl
    ? isolerDonnee(texte)
    : texte;
