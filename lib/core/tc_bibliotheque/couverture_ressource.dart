import 'package:flutter/foundation.dart';

import 'library_resource.dart';

/// Le motif geometrique d'une couverture calculee.
///
/// Quatre motifs, pas un de plus : au dela, deux couvertures voisines
/// cesseraient d'etre distinguables d'un coup d'oeil, ce qui est precisement
/// le defaut que la spec reproche a l'existant.
enum MotifCouverture {
  /// Des lignes obliques.
  lignes,

  /// Des arcs concentriques.
  arcs,

  /// Une grille.
  grille,

  /// Des points.
  points,
}

/// La couverture d'une ressource : celle qui existe, ou celle qui se calcule.
///
/// **Le repli est controle et deterministe**, pas une grille d'icones
/// generiques identiques (spec section 6.1). Trois axes se combinent :
///
/// - la **teinte**, tiree d'un ensemble borne de surfaces du theme ;
/// - le **motif**, l'un des quatre ;
/// - le **monogramme**, tire du titre court.
///
/// Seize combinaisons de teinte et de motif, chacune portant un monogramme
/// different : deux ressources se distinguent donc avant meme qu'on lise leur
/// titre, et la meme ressource a **toujours** la meme couverture, sur tous les
/// appareils et apres chaque redemarrage.
///
/// **Le Coran garde sa teinte.** L'index 0 lui est reserve : le theme porte
/// deja une paire `surfaceQuran` qui n'est employee nulle part ailleurs, et un
/// mushaf qui changerait de couleur d'un catalogue a l'autre perdrait le seul
/// repere que l'eleve a avant de savoir lire le titre.
///
/// **La palette administree existe.** `AppPalette.teintesIdentite` (decision
/// D-18, plan d'integration Teaching Core section 9.2) fournit 32 teintes
/// verifiees, partagees avec celle des groupes -- un seul lot ferme les deux
/// demandes.
@immutable
class CouvertureRessource {
  /// Cree une couverture.
  const CouvertureRessource({
    required this.indexTeinte,
    required this.motif,
    required this.monogramme,
    required this.type,
    this.cleAsset,
  });

  /// La couverture d'une ressource, calculee une fois pour toutes.
  factory CouvertureRessource.pour(LibraryResource ressource) {
    final int graine = empreinte(ressource.id);
    final bool coran = ressource.resourceType == TypeRessource.quran;

    return CouvertureRessource(
      cleAsset: ressource.coverAsset,
      // Le Coran prend l'index reserve ; les autres se repartissent sur les
      // teintes restantes.
      indexTeinte: coran ? 0 : 1 + graine % (nombreTeintes - 1),
      motif: MotifCouverture
          .values[graine ~/ nombreTeintes % MotifCouverture.values.length],
      monogramme: monogrammeDe(ressource),
      type: ressource.resourceType,
    );
  }

  /// Le nombre de teintes disponibles. L'index 0 est reserve au Coran, les
  /// 32 suivantes sont celles d'`AppPalette.teintesIdentite`.
  static const int nombreTeintes = 33;

  /// La cle de la couverture deposee, quand il y en a une.
  final String? cleAsset;

  /// La teinte retenue, dans `0 .. nombreTeintes - 1`.
  final int indexTeinte;

  /// Le motif retenu.
  final MotifCouverture motif;

  /// Le monogramme, une ou deux lettres.
  final String monogramme;

  /// Le type de la ressource, qui choisit l'icone de coin.
  final TypeRessource type;

  /// Vrai quand la couverture est calculee faute d'asset depose.
  bool get calculee => cleAsset == null;

  /// La graine de depart de [empreinte].
  static const int graineEmpreinte = 5381;

  /// L'empreinte stable d'une chaine, sur 32 bits.
  ///
  /// **Pas `String.hashCode`** : celui de Dart n'est pas garanti stable d'une
  /// execution a l'autre ni d'une plateforme a l'autre, et une couverture qui
  /// changerait de couleur au redemarrage ne serait plus un repere.
  ///
  /// **Pas FNV-1a non plus, et la raison est le web.** FNV multiplie par
  /// 16 777 619 : avec une valeur courante de 32 bits, le produit atteint
  /// 2^56, au-dela des 2^53 entiers exacts d'un nombre JavaScript. Le meme
  /// support aurait donc une couverture sur le web et une autre sur mobile.
  /// Le multiplicateur retenu, 33, borne le produit a environ 1,4 x 10^11 :
  /// exact partout.
  static int empreinte(String graine) {
    int h = graineEmpreinte;
    for (final int unite in graine.codeUnits) {
      h = ((h * 33) ^ unite) & 0xffffffff;
    }
    return h;
  }

  /// Le monogramme d'une ressource : une ou deux initiales.
  ///
  /// La cascade de replis est volontairement complete, parce que chacun de ses
  /// crans est un cas reel : un titre court vide, un titre entierement
  /// ponctue, un titre en arabe sans espace. Le dernier cran tire une lettre
  /// de l'identifiant plutot que de rendre un point d'interrogation, pour que
  /// deux ressources sans titre ne portent pas la meme vignette.
  static String monogrammeDe(LibraryResource ressource) {
    for (final String source in <String>[
      ressource.shortTitle,
      ressource.title,
    ]) {
      final String m = _initiales(source);
      if (m.isNotEmpty) return m;
    }
    final String secours = ressource.id.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    return secours.isEmpty
        ? '?'
        : secours.substring(0, secours.length < 2 ? 1 : 2).toUpperCase();
  }

  static String _initiales(String texte) {
    final List<String> mots = texte
        .split(RegExp(r'\s+'))
        .where((String m) => m.trim().isNotEmpty)
        .toList(growable: false);
    final StringBuffer sortie = StringBuffer();
    for (final String mot in mots) {
      if (sortie.length >= 2) break;
      // La premiere lettre du mot, pas son premier caractere : un titre qui
      // commence par un guillemet ne doit pas produire un guillemet.
      final Match? lettre = RegExp(r'\p{L}', unicode: true).firstMatch(mot);
      if (lettre != null) sortie.write(mot.substring(lettre.start, lettre.end));
    }
    return sortie.toString().toUpperCase();
  }
}
