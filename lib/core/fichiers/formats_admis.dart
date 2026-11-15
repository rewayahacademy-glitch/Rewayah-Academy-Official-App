// COMPLEMENT-ET-FORMATS (directeur, 14/11/2026) : « certains dossiers ne
// s'affichent pas […] Pourquoi permettre à l'user de l'envoyer si c'est pour le
// refuser des jours après ? […] je veux savoir les formats admis et comment
// empêcher les gens de déposer sauf au format demandé ».
//
// Une seule regle, ici, pour tout fichier qu'une personne depose (piece
// d'identite, photo de profil, photo de candidature) : la liste fermee des
// formats que la direction sait AFFICHER dans le dossier, sur ordinateur,
// dans Chrome. Prevenir au depot plutot que refuser des jours apres :
//
//   - le format se lit dans les premiers octets du fichier, jamais dans son
//     nom (une photo d'iPhone nommee `.jpg` peut etre un HEIC) ;
//   - une photo HEIC est convertie en JPEG sur l'appareil avant l'envoi
//     (`conversion_heic.dart`), et non refusee ; si l'appareil ne sait pas la
//     convertir, la phrase dit quoi faire ;
//   - tout autre format est refuse tout de suite, avec la phrase qui dit quoi
//     faire (K-59) ;
//   - la meme liste et la meme taille sont posees sur les seaux du serveur
//     (migration 20261126800000), pour qu'aucun autre chemin ne les contourne.
//
// Le PDF n'est plus admis pour une piece : la visionneuse de la direction ne
// l'affiche pas (`RevueDossiersDepuisValidation.typesImage`), et une piece
// qui ne s'affiche pas ne peut pas etre validee.
library;

import 'dart:typed_data';

/// Un format de fichier, lu dans ses premiers octets.
enum FormatFichier {
  /// JPEG (`FF D8 FF`).
  jpeg('jpg', 'image/jpeg'),

  /// PNG (signature de 8 octets).
  png('png', 'image/png'),

  /// WebP (`RIFF....WEBP`).
  webp('webp', 'image/webp'),

  /// HEIC ou HEIF, la photo par defaut des iPhone (`....ftypheic`).
  heic('heic', 'image/heic'),

  /// PDF (`%PDF`).
  pdf('pdf', 'application/pdf'),

  /// Tout le reste.
  inconnu('bin', 'application/octet-stream');

  const FormatFichier(this.extension, this.typeMime);

  /// L'extension du fichier envoye, sans point.
  final String extension;

  /// Le type annonce au seau de stockage.
  final String typeMime;
}

/// Marques HEIF a l'offset 8 d'une boite `ftyp` : celles du controle du
/// serveur (`_shared/r2/contenu_piece.ts`), plus les variantes de sequence,
/// pour qu'aucune photo HEIC ne passe pour un format inconnu : elle est
/// convertie, jamais envoyee telle quelle.
const Set<String> _marquesHeif = <String>{
  'heic',
  'heix',
  'heim',
  'heis',
  'hevc',
  'hevx',
  'heif',
  'mif1',
  'msf1',
};

bool _commencePar(Uint8List octets, List<int> attendu, [int decalage = 0]) {
  if (octets.length < decalage + attendu.length) return false;
  for (int i = 0; i < attendu.length; i++) {
    if (octets[decalage + i] != attendu[i]) return false;
  }
  return true;
}

String _ascii(Uint8List octets, int debut, int fin) =>
    octets.length < fin ? '' : String.fromCharCodes(octets.sublist(debut, fin));

/// Le format de [octets], lu dans ses premiers octets. Fonction pure.
FormatFichier formatDepuisOctets(Uint8List octets) {
  if (_commencePar(octets, const <int>[0xff, 0xd8, 0xff])) {
    return FormatFichier.jpeg;
  }
  if (_commencePar(octets, const <int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
  ])) {
    return FormatFichier.png;
  }
  if (_ascii(octets, 0, 4) == 'RIFF' && _ascii(octets, 8, 12) == 'WEBP') {
    return FormatFichier.webp;
  }
  if (_ascii(octets, 4, 8) == 'ftyp' &&
      _marquesHeif.contains(_ascii(octets, 8, 12))) {
    return FormatFichier.heic;
  }
  if (_commencePar(octets, const <int>[0x25, 0x50, 0x44, 0x46])) {
    return FormatFichier.pdf;
  }
  return FormatFichier.inconnu;
}

/// Ce qu'une sorte de fichier admet : la liste fermee et la taille maximale.
/// Les memes valeurs sont posees sur le seau du serveur (migration
/// 20261126800000) ; un test les compare.
enum SorteFichier {
  /// La piece d'identite (seau `kyc`) : JPEG ou PNG, 8 Mo au plus. Le WebP
  /// n'y est pas : le controle du contenu du serveur (`kyc-confirme`) ne le
  /// connait pas.
  piece(<FormatFichier>{FormatFichier.jpeg, FormatFichier.png}, 8, 3000),

  /// Une photo de personne (seaux `photos_enseignants` et `avatars`) : JPEG,
  /// PNG ou WebP, 4 Mo au plus.
  photo(
    <FormatFichier>{FormatFichier.jpeg, FormatFichier.png, FormatFichier.webp},
    4,
    2048,
  );

  const SorteFichier(this.admis, this.tailleMaxMo, this.coteMaxConversion);

  /// Les formats admis, dans l'ordre ou ils se disent.
  final Set<FormatFichier> admis;

  /// La taille maximale, en mega-octets (Mio).
  final int tailleMaxMo;

  /// Le plus grand cote, en pixels, d'une photo HEIC convertie en JPEG.
  final int coteMaxConversion;

  /// La taille maximale, en octets.
  int get tailleMaxOctets => tailleMaxMo * 1024 * 1024;

  /// Les types MIME admis, tels que le seau du serveur les liste.
  List<String> get typesMime => <String>[
    for (final FormatFichier f in admis) f.typeMime,
  ];
}

/// Pourquoi un fichier est refuse au depot.
enum CauseRefusFichier {
  /// Le format n'est pas dans la liste (PDF pour une photo, document...).
  format,

  /// Une photo HEIC que cet appareil ne sait pas convertir en JPEG.
  heicNonConverti,

  /// Le fichier depasse la taille maximale.
  tropLourd,
}

/// Le refus d'un fichier, au moment ou il est choisi : avant tout envoi.
class FichierRefuse implements Exception {
  /// Cree le refus.
  const FichierRefuse(this.cause, this.sorte, {this.format});

  /// La cause.
  final CauseRefusFichier cause;

  /// La sorte de fichier demandee.
  final SorteFichier sorte;

  /// Le format lu, quand il est connu.
  final FormatFichier? format;

  @override
  String toString() => 'FichierRefuse(${cause.name}, ${sorte.name})';
}

/// Un fichier pret a partir : un format admis, l'extension et le type qui en
/// decoulent.
class FichierPret {
  /// Cree le fichier.
  const FichierPret({
    required this.octets,
    required this.format,
    this.converti = false,
  });

  /// Le contenu.
  final Uint8List octets;

  /// Le format, lu dans les octets (toujours admis).
  final FormatFichier format;

  /// Vrai quand une photo HEIC a ete convertie en JPEG sur l'appareil.
  final bool converti;

  /// Le nom du fichier envoye : seule l'extension compte pour le serveur.
  String nomFichier(String base) => '$base.${format.extension}';
}

/// Convertit une photo HEIC en JPEG, sur l'appareil, en ramenant son plus
/// grand cote a [coteMax] pixels ; `null` quand l'appareil ne sait pas.
typedef ConvertisseurHeic = Future<Uint8List?> Function(
  Uint8List heic, {
  required int coteMax,
});

/// Prepare [octets] pour [sorte] : lit le format, convertit une photo HEIC en
/// JPEG, refuse tout autre format hors liste, puis verifie la taille.
///
/// Leve [FichierRefuse] avec la cause ; ne fait aucun envoi.
Future<FichierPret> preparerFichier(
  Uint8List octets, {
  required SorteFichier sorte,
  required ConvertisseurHeic convertir,
}) async {
  FormatFichier format = formatDepuisOctets(octets);
  Uint8List contenu = octets;
  bool converti = false;
  if (format == FormatFichier.heic) {
    Uint8List? jpeg;
    try {
      jpeg = await convertir(octets, coteMax: sorte.coteMaxConversion);
    } on Object {
      jpeg = null;
    }
    if (jpeg == null || formatDepuisOctets(jpeg) != FormatFichier.jpeg) {
      throw FichierRefuse(
        CauseRefusFichier.heicNonConverti,
        sorte,
        format: FormatFichier.heic,
      );
    }
    contenu = jpeg;
    format = FormatFichier.jpeg;
    converti = true;
  }
  if (!sorte.admis.contains(format)) {
    throw FichierRefuse(CauseRefusFichier.format, sorte, format: format);
  }
  if (contenu.lengthInBytes > sorte.tailleMaxOctets) {
    throw FichierRefuse(CauseRefusFichier.tropLourd, sorte, format: format);
  }
  return FichierPret(octets: contenu, format: format, converti: converti);
}

/// Les extensions proposees par la boite de choix du systeme. Le HEIC n'y est
/// pas : sur iPhone, une liste sans HEIC fait convertir la photo en JPEG par
/// le systeme lui-meme ; un HEIC qui arrive quand meme est converti ici.
List<String> extensionsProposees(SorteFichier sorte) => <String>[
  for (final FormatFichier f in sorte.admis)
    ...switch (f) {
      FormatFichier.jpeg => <String>['jpg', 'jpeg'],
      _ => <String>[f.extension],
    },
];
