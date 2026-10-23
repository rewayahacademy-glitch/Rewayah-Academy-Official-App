/// IMM-ACCUEIL-FRONT : d'ou vient le fichier CSV de l'import.
///
/// Une interface, parce qu'aucun test ne peut ouvrir une boite de dialogue
/// native. Le selecteur reel utilise `file_picker` (deja une dependance de
/// l'application) et rend le texte du fichier, ou `null` quand la personne
/// renonce. Un export de tableur en francais est parfois en Windows-1252 : le
/// texte est lu en UTF-8 puis, a defaut, en Latin-1.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un fichier choisi : son nom (affichage) et son texte.
class CsvChoisi {
  /// Cree le fichier.
  const CsvChoisi({required this.nom, required this.texte});

  /// Le nom du fichier.
  final String nom;

  /// Son contenu, decode.
  final String texte;
}

/// Le selecteur.
abstract interface class SelecteurCsv {
  /// Demande un fichier CSV. `null` quand la personne renonce ; une exception
  /// quand le fichier ne peut pas etre lu.
  Future<CsvChoisi?> choisir();
}

/// Le selecteur reel, par la boite de dialogue du systeme.
class SelecteurCsvNatif implements SelecteurCsv {
  /// Cree le selecteur.
  const SelecteurCsvNatif();

  @override
  Future<CsvChoisi?> choisir() async {
    final PlatformFile? fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'txt'],
    );
    if (fichier == null) return null;
    final Uint8List octets = await fichier.readAsBytes();
    return CsvChoisi(nom: fichier.name, texte: decoderCsv(octets));
  }
}

/// Decode [octets] : UTF-8 (BOM compris, l'analyseur le retire), sinon Latin-1.
String decoderCsv(List<int> octets) {
  try {
    return utf8.decode(octets);
  } on FormatException {
    return latin1.decode(octets);
  }
}

/// Le selecteur employe par l'application.
final Provider<SelecteurCsv> selecteurCsvProvider = Provider<SelecteurCsv>(
  (Ref _) => const SelecteurCsvNatif(),
);
