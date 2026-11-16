// IMAGES-MESSAGERIE : le choix d'une photo, par le selecteur du systeme
// (`file_picker`, deja employe par le projet ; au telephone, il propose aussi
// l'appareil photo selon la plateforme). Aucune dependance de plus.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Choisit une photo : ses octets, ou `null` si la personne renonce.
typedef ChoixImage = Future<Uint8List?> Function();

/// Le selecteur du systeme, restreint aux images.
Future<Uint8List?> choisirImageSysteme() async {
  final PlatformFile? fichier = await FilePicker.pickFile(type: FileType.image);
  if (fichier == null) return null;
  return fichier.readAsBytes();
}
