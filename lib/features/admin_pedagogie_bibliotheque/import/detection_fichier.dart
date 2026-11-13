/// DEPOT-SIMPLE (13/11/2026) : ce que l'application deduit seule d'un fichier.
///
/// La personne choisit un fichier, et rien d'autre : le type (PDF, audio,
/// image) se lit dans le contenu lui-meme (sa signature), jamais dans
/// l'extension seule ; le nom propose vient du nom du fichier ; la langue, du
/// nom. Les memes signatures que le serveur (`detecterMimeReel`, fonction
/// Edge), qui reverifie tout : ici, on evite seulement un aller-retour et on
/// donne la vraie phrase tout de suite.
library;

import 'dart:typed_data';

import '../../../core/tc_bibliotheque/contenu_arabe.dart';
import '../../../core/tc_bibliotheque/library_resource.dart';

/// Pourquoi un fichier n'est pas pris.
enum RefusFichier {
  /// Le fichier est vide.
  vide,

  /// Une video : elle s'ajoute par son lien (son poids depasse le depot).
  video,

  /// Ni PDF, ni audio, ni image reconnus.
  inconnu,

  /// Trop lourd pour son type.
  tropLourd,
}

/// Ce que l'application a lu dans le fichier.
sealed class LectureFichier {
  const LectureFichier();
}

/// Le fichier est reconnu.
final class FichierReconnu extends LectureFichier {
  /// Cree la lecture.
  const FichierReconnu({required this.type, required this.mime});

  /// Le type du document.
  final TypeRessource type;

  /// Le type MIME reel, celui que le serveur retrouvera.
  final String mime;
}

/// Le fichier n'est pas pris.
final class FichierRefuse extends LectureFichier {
  /// Cree le refus. [limiteMio] : le plafond, pour un fichier trop lourd.
  const FichierRefuse(this.raison, {this.limiteMio});

  /// La raison.
  final RefusFichier raison;

  /// Le plafond en Mio (fichier trop lourd seulement).
  final int? limiteMio;
}

const int _mio = 1024 * 1024;

/// Le plafond d'un type MIME, en Mio : les memes que le serveur
/// (`TAILLES_UPLOAD_BIBLIOTHEQUE`).
int plafondMio(String mime) {
  if (mime.startsWith('image/')) return 10;
  if (mime == 'application/pdf') return 50;
  return 100;
}

bool _commence(Uint8List o, List<int> signature, [int debut = 0]) {
  if (o.length < debut + signature.length) return false;
  for (int i = 0; i < signature.length; i++) {
    if (o[debut + i] != signature[i]) return false;
  }
  return true;
}

String _ascii(Uint8List o, int debut, int fin) =>
    o.length < fin ? '' : String.fromCharCodes(o.sublist(debut, fin));

/// Lit le type d'un fichier dans son contenu. [nom] ne sert qu'a departager un
/// conteneur MP4, qui porte de l'audio (m4a) comme de la video.
LectureFichier lireFichier(Uint8List octets, {String nom = ''}) {
  if (octets.isEmpty) return const FichierRefuse(RefusFichier.vide);
  final String extension = nom.contains('.')
      ? nom.split('.').last.toLowerCase()
      : '';
  String? mime;
  if (_commence(octets, const <int>[0x25, 0x50, 0x44, 0x46, 0x2d])) {
    mime = 'application/pdf';
  } else if (_commence(octets, const <int>[
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
  ])) {
    mime = 'image/png';
  } else if (_commence(octets, const <int>[0xff, 0xd8, 0xff])) {
    mime = 'image/jpeg';
  } else if (_ascii(octets, 0, 4) == 'RIFF') {
    final String forme = _ascii(octets, 8, 12);
    if (forme == 'WEBP') mime = 'image/webp';
    if (forme == 'AVI ') return const FichierRefuse(RefusFichier.video);
  } else if (_ascii(octets, 0, 4) == 'OggS') {
    mime = 'audio/ogg';
  } else if (_ascii(octets, 4, 8) == 'ftyp') {
    // Un conteneur MP4 : audio si sa marque ou son extension le dit, sinon
    // c'est une video.
    final String marque = _ascii(octets, 8, 12);
    final bool audio =
        marque == 'M4A ' ||
        marque == 'M4B ' ||
        extension == 'm4a' ||
        extension == 'm4b';
    if (!audio) return const FichierRefuse(RefusFichier.video);
    mime = 'audio/mp4';
  } else if (_commence(octets, const <int>[0x1a, 0x45, 0xdf, 0xa3])) {
    // Matroska ou WebM.
    return const FichierRefuse(RefusFichier.video);
  } else if (_ascii(octets, 0, 3) == 'ID3' ||
      (octets.length >= 2 && octets[0] == 0xff && (octets[1] & 0xe0) == 0xe0)) {
    mime = 'audio/mpeg';
  }
  if (mime == null) return const FichierRefuse(RefusFichier.inconnu);
  final int limite = plafondMio(mime);
  if (octets.length > limite * _mio) {
    return FichierRefuse(RefusFichier.tropLourd, limiteMio: limite);
  }
  return FichierReconnu(
    mime: mime,
    type: mime == 'application/pdf'
        ? TypeRessource.pdf
        : mime.startsWith('image/')
        ? TypeRessource.image
        : TypeRessource.audio,
  );
}

final RegExp _suffixeCopie = RegExp(r'(-\d{1,2}| \(\d{1,2}\))$');

/// Le nom propose pour le document : le nom du fichier sans son extension ni
/// le suffixe qu'un navigateur ajoute a une copie (« -1 », « (2) »). La
/// personne peut le changer.
String nomPropose(String nomFichier) {
  String nom = nomFichier.trim();
  final int point = nom.lastIndexOf('.');
  if (point > 0 && nom.length - point <= 6) nom = nom.substring(0, point);
  nom = nom.replaceAll('_', ' ').trim();
  final String sansSuffixe = nom.replaceFirst(_suffixeCopie, '').trim();
  if (sansSuffixe.isNotEmpty) nom = sansSuffixe;
  return nom.length > 200 ? nom.substring(0, 200) : nom;
}

/// La langue deduite du nom : l'arabe si le nom est ecrit en arabe, sinon la
/// langue de l'interface.
String langueDeduite(String nom, String langueInterface) =>
    contientArabe(nom) ? 'ar' : langueInterface;

/// Vrai pour l'adresse d'une video en ligne connue : le document est alors une
/// video par lien, sinon un lien externe.
bool lienDeVideo(String adresse) {
  final Uri? u = Uri.tryParse(adresse.trim());
  if (u == null) return false;
  final String hote = u.host.toLowerCase();
  return const <String>[
    'youtube.com',
    'youtu.be',
    'vimeo.com',
  ].any((String h) => hote == h || hote.endsWith('.$h'));
}
