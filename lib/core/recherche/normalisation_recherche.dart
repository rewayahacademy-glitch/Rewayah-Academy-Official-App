import '../tc_bibliotheque/recherche_catalogue.dart';

/// La forme de comparaison d'un texte de recherche : la meme pour le titre
/// cherche et pour la requete.
///
/// Elle ne s'applique qu'a la **representation de recherche**, jamais au texte
/// affiche et jamais au texte coranique canonique (spec §6.4) : minuscules,
/// sans accent francais (`RechercheCatalogue.normaliser`), translitteration
/// savante repliee (« Al-Fātiḥa » trouve « al-fatiha »), traits d'union lus
/// comme des espaces, apostrophes retirees, arabe sans voyelles breves ni
/// allongement, formes de l'alif et du ya reunies.
String normaliserPourRecherche(String texte) {
  final StringBuffer sortie = StringBuffer();
  for (final int unite in RechercheCatalogue.normaliser(texte).runes) {
    if (_aSupprimer.contains(unite)) continue;
    if (unite == 0x2D || unite == 0x5F) {
      sortie.write(' ');
      continue;
    }
    sortie.write(
      _tableLatine[unite] ?? _tableArabe[unite] ?? String.fromCharCode(unite),
    );
  }
  return sortie.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Vrai quand chaque terme de [requete] se trouve dans [titre], les deux
/// ayant ete normalises par [normaliserPourRecherche].
bool correspondTousLesTermes(String titre, String requete) {
  if (requete.isEmpty) return false;
  for (final String terme in requete.split(' ')) {
    if (terme.isNotEmpty && !titre.contains(terme)) return false;
  }
  return true;
}

/// Les signes retires : apostrophes et marques de translitteration, voyelles
/// breves et signes de l'arabe (fatha a sukun, alif suscrit), allongement.
const Set<int> _aSupprimer = <int>{
  0x27, // apostrophe
  0x2019, // apostrophe typographique
  0x2BF, // ʿ
  0x2BE, // ʾ
  0x64B,
  0x64C,
  0x64D,
  0x64E,
  0x64F,
  0x650,
  0x651,
  0x652,
  0x653,
  0x654,
  0x655,
  0x670,
  0x640, // tatweel
};

const Map<int, String> _tableLatine = <int, String>{
  0x101: 'a', // ā
  0x12B: 'i', // ī
  0x16B: 'u', // ū
  0x1E25: 'h', // ḥ
  0x1E63: 's', // ṣ
  0x1E0D: 'd', // ḍ
  0x1E6D: 't', // ṭ
  0x1E93: 'z', // ẓ
  0x1E33: 'k', // ḳ
};

const Map<int, String> _tableArabe = <int, String>{
  0x623: 'ا', // alif hamza dessus
  0x625: 'ا', // alif hamza dessous
  0x622: 'ا', // alif madda
  0x649: 'ي', // alif maqsura vers ya
};
