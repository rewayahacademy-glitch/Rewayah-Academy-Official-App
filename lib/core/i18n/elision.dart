// Elision francaise de « de » (EN-11, E17).
//
// Les noms de Classe transcrits de l'arabe commencent presque tous par
// « Al- » ou « An- » (`enseignant_demo.dart`) : « de Al-Badr » se lit mal, la
// grammaire francaise demande « d'Al-Badr ». Cette fonction ne connait aucun
// nom par coeur : elle regarde seulement la premiere lettre, pour rester
// correcte devant n'importe quel nom, present ou futur.

/// Compose « de {nom} » ou « d'{nom} » selon que [nom] commence par un son
/// de voyelle (a, e, i, o, u, y, leurs formes accentuees, et h).
String deDevant(String nom) {
  if (nom.isEmpty) {
    return 'de $nom';
  }
  const String voyelles = 'aeiouyàâäéèêëïîôöùûüh';
  final String premiere = nom[0].toLowerCase();
  return voyelles.contains(premiere) ? "d'$nom" : 'de $nom';
}
