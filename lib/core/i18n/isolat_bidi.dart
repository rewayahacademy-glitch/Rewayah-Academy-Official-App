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

/// DUREE-INSECABLE-4 : un libelle de l'application (francais) pose dans une
/// interface de [sens] donne. En droite a gauche, il est isole ([isolerSens])
/// pour que sa ponctuation reste a sa place (« Salle ouverte. » et non
/// « .Salle ouverte ») ; de gauche a droite, il est rendu tel quel, son sens
/// etant deja celui de l'interface. Un nom propre d'une autre ecriture passe
/// par [isolerSens] directement, quel que soit le sens.
String isolerDansInterface(String texte, TextDirection sens) =>
    sens == TextDirection.rtl ? isolerSens(texte) : texte;

/// DUREE-INSECABLE-4 : la marque gauche-a-droite (U+200E) qu'une valeur
/// affichee seule porte en tete (`LibellesGroupe.ancreSens`).
const String _ancreDeSens = '‎';

/// Joint [morceaux] par [separateur] en ne gardant l'ancre de sens (U+200E)
/// qu'en TETE de la ligne. Une valeur ancree pour s'afficher seule (« 12
/// jours » dans une cellule) perd son ancre quand elle suit un autre
/// morceau : derriere un mot, elle n'en a plus besoin, et une marque invisible
/// au milieu d'un libelle n'a pas a y etre. Les morceaux vides sont omis.
///
/// Tout composant qui joint des valeurs qu'il ne connait pas (colonnes d'une
/// `DataCollection` repliees en carte) passe par ici plutot que par
/// `.join` ; la garde `test/support/garde_ancres.dart` le verifie.
String enchainer(Iterable<String> morceaux, String separateur) {
  final StringBuffer ligne = StringBuffer();
  for (final String morceau in morceaux) {
    if (morceau.isEmpty) continue;
    if (ligne.isEmpty) {
      ligne.write(morceau);
    } else {
      ligne
        ..write(separateur)
        ..write(sansAncre(morceau));
    }
  }
  return ligne.toString();
}

/// DUREE-INSECABLE-4 (reprise 2) : [texte] sans l'ancre de sens (U+200E)
/// qu'il porte en tete pour s'afficher seul, quand on l'insere derriere un
/// autre mot (« Annulée : 45 min » dans une annonce).
String sansAncre(String texte) => texte.startsWith(_ancreDeSens)
    ? texte.substring(_ancreDeSens.length)
    : texte;
