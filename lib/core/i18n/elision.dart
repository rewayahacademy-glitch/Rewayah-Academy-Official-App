// Elision francaise de « de » (EN-11, E17).
//
// Les noms de Classe transcrits de l'arabe commencent presque tous par
// « Al- » ou « An- » (`enseignant_demo.dart`) : « de Al-Badr » se lit mal, la
// grammaire francaise demande « d'Al-Badr ». Cette fonction ne connait aucun
// nom par coeur : elle regarde seulement les premieres lettres, pour rester
// correcte devant n'importe quel nom, present ou futur.

/// Les sons de voyelle qui appellent « d' » (h muet compris).
const String _voyelles = 'aeiouàâäéèêëïîôöùûüh';

/// Compose « de {nom} » ou « d'{nom} » selon que [nom] commence par un son
/// de voyelle (a, e, i, o, u, leurs formes accentuees, et h).
///
/// « y » suivi d'une voyelle est une consonne (contre-revue FI-VAGUE-CORR) :
/// « de Youssef », « de Yasmine », « de Yahya ». Suivi d'une consonne, il se
/// prononce « i » et elide : « d'Yvette ».
String deDevant(String nom) {
  if (nom.isEmpty) {
    return 'de $nom';
  }
  final String minuscule = nom.toLowerCase();
  final String premiere = minuscule[0];
  final bool voyelle = premiere == 'y'
      ? minuscule.length > 1 && !_voyelles.contains(minuscule[1])
      : _voyelles.contains(premiere);
  return voyelle ? "d'$nom" : 'de $nom';
}
