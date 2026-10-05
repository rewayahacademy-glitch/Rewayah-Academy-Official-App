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

/// Isole [texte] dans son propre sens de lecture (premier caractere fort),
/// sans changer l'ordre des segments voisins. Un texte vide reste vide.
String isolerSens(String texte) => texte.isEmpty ? texte : '\u2068$texte\u2069';
