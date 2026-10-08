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
// remplit avec [deDevant] ; de meme `{queNom}` avec [queDevant].
//
// Une seule regle (revue croisee de LIB-DIR-1, decidee par delegation le
// 08/10) : voyelle, accentuee ou non, et « y » prononce « i ». Jamais devant
// h : les prenoms transcrits de l'arabe ont un h aspire (« de Hamza »,
// « de Hana »), comme le faisaient deja les dossiers (textes_dossier.dart).
//
// Langue : l'arabe ne traduit qu'une partie des cles (98 sur plus de 4000),
// les autres s'affichent en francais (`fallback_strategy: base_locale`). Le
// texte francais de repli garde donc « de » / « d' ». Seul un appelant dont
// la cle EST traduite dans la langue active doit recevoir le nom seul : il
// passe [cle], et la fonction regarde si la langue active la traduit.

import 'strings.g.dart';

/// Les voyelles qui appellent l'elision (h exclu, voir l'en-tete).
const String _voyelles = 'aeiouàâäéèêëïîôöùûü';

/// Compose « de {nom} » ou « d'{nom} » selon que [nom] commence par un son
/// de voyelle (a, e, i, o, u, leurs formes accentuees ; « y » devant une
/// consonne). Jamais devant h.
///
/// « y » suivi d'une voyelle est une consonne (contre-revue FI-VAGUE-CORR) :
/// « de Youssef », « de Yasmine », « de Yahya ». Suivi d'une consonne, il se
/// prononce « i » et elide : « d'Yvette ».
///
/// [cle] : la cle du libelle, a passer quand elle a une traduction hors du
/// francais. Si la langue active la traduit, le nom est rendu seul (la
/// traduction place le nom ou sa grammaire le demande) ; sinon le texte
/// affiche est le repli francais, et l'elision francaise s'applique.
String deDevant(String nom, {String? cle}) => _elide('de', 'd', nom, cle);

/// Compose « que {nom} » ou « qu'{nom} » (LIB-OBJ-1 : « Ce qu'Aya doit
/// atteindre »), selon la meme regle que [deDevant].
String queDevant(String nom, {String? cle}) => _elide('que', 'qu', nom, cle);

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

/// Vrai quand la langue active n'est pas le francais et traduit [cle]
/// elle-meme (sans repli sur le francais).
bool _traduiteHorsFrancais(String? cle) =>
    cle != null &&
    LocaleSettings.currentLocale != AppLocale.fr &&
    t.$meta.getTranslation(cle) != null;

String _elide(String mot, String elide, String nom, String? cle) {
  if (_traduiteHorsFrancais(cle)) {
    return nom;
  }
  return commenceParVoyelle(nom) ? "$elide'$nom" : '$mot $nom';
}
