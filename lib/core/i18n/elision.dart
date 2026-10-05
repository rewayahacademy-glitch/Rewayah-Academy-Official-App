// Elision francaise de « de » et « que » (EN-11, E17, LIB-OBJ-1, FI-R4-08).
//
// Les noms de Classe transcrits de l'arabe commencent presque tous par
// « Al- » ou « An- » (`enseignant_demo.dart`) : « de Al-Badr » se lit mal, la
// grammaire francaise demande « d'Al-Badr ». De meme devant un prenom :
// « Accès d'Aïcha », « Ce qu'Aya doit atteindre ». Ces fonctions ne
// connaissent aucun nom par coeur : elles regardent seulement les premieres
// lettres, pour rester correctes devant n'importe quel nom, present ou futur.
//
// Decision « fi-elision » du 05/10 (par delegation du directeur) : la regle
// vaut dans toute l'application. Un libelle qui met « de » devant un nom
// porte un parametre `{deNom}` (`{dePrenom}`, `{deClasse}`...) que l'appelant
// remplit avec [deDevant] ; de meme `{queNom}` avec [queDevant]. Les autres
// langues n'ont pas cette preposition dans le parametre : hors du francais,
// les deux fonctions rendent le nom tel quel, et la traduction place le nom
// la ou sa grammaire le demande.

import 'strings.g.dart';

/// Les sons de voyelle qui appellent l'elision (h muet compris).
const String _voyelles = 'aeiouàâäéèêëïîôöùûüh';

/// Compose « de {nom} » ou « d'{nom} » selon que [nom] commence par un son
/// de voyelle (a, e, i, o, u, leurs formes accentuees, et h).
///
/// « y » suivi d'une voyelle est une consonne (contre-revue FI-VAGUE-CORR) :
/// « de Youssef », « de Yasmine », « de Yahya ». Suivi d'une consonne, il se
/// prononce « i » et elide : « d'Yvette ».
///
/// Hors du francais, rend [nom] seul (voir l'en-tete du fichier).
String deDevant(String nom) => _elide('de', 'd', nom);

/// Compose « que {nom} » ou « qu'{nom} » (LIB-OBJ-1 : « Ce qu'Aya doit
/// atteindre »), selon la meme regle que [deDevant].
String queDevant(String nom) => _elide('que', 'qu', nom);

/// Vrai quand [nom] commence par un son de voyelle, au sens de [deDevant].
bool commenceParVoyelle(String nom) {
  if (nom.isEmpty) {
    return false;
  }
  final String minuscule = nom.toLowerCase();
  final String premiere = minuscule[0];
  return premiere == 'y'
      ? minuscule.length > 1 && !_voyelles.contains(minuscule[1])
      : _voyelles.contains(premiere);
}

String _elide(String mot, String elide, String nom) {
  if (LocaleSettings.currentLocale != AppLocale.fr) {
    return nom;
  }
  return commenceParVoyelle(nom) ? "$elide'$nom" : '$mot $nom';
}
