// COUPE-MOTS-3 (revue BLOC-BIB-1b-R, observation 3) : une taille de fichier
// ne se lit jamais « 8,1 / Mo » sur deux lignes. Le nombre et son unite sont
// lies par une espace insecable (U+00A0), comme une duree
// (DUREE-INSECABLE-1) : le moteur de texte passe a la ligne avant le nombre,
// jamais entre le nombre et l'unite.

/// L'espace insecable qui lie un nombre a son unite de taille.
const String espaceInsecableTaille = '\u00A0';

/// Les unites de taille de fichier reconnues, en francais (o, Ko, Mo, Go,
/// To) et en anglais (KB, MB, GB, TB), suivies d'une limite de mot.
final RegExp _nombreEtUnite = RegExp(
  r'(\d)[ \u202F]+(o|Ko|Mo|Go|To|KB|MB|GB|TB)(?![\p{L}\p{N}])',
  unicode: true,
);

/// Le point de formatage partage d'une taille de fichier : [nombre] (deja
/// ecrit dans la langue, « 8,1 ») et [unite] (« Mo ») lies par une espace
/// insecable.
String tailleFichier(String nombre, String unite) =>
    '$nombre$espaceInsecableTaille$unite';

/// [texte] dont chaque taille de fichier (« 8,1 Mo », « 640 Ko ») lie son
/// nombre a son unite par une espace insecable. Sert a l'affichage d'un
/// libelle venu des donnees (titre court d'une ressource) : le texte reste
/// le meme, seule la coupure de ligne change.
String lierTaillesFichier(String texte) => texte.replaceAllMapped(
  _nombreEtUnite,
  (Match m) => '${m[1]}$espaceInsecableTaille${m[2]}',
);
