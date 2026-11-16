// IMAGES-MESSAGERIE : le choix d'une photo par `image_picker` (decision du
// directeur relayee par le pilote le 16/11/2026) : la galerie, ou l'appareil
// photo. Au telephone (Android, iOS), la personne a deux choix, « Prendre une
// photo » et « Choisir dans la galerie » ; ailleurs, le selecteur de fichiers
// du systeme.

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// D'ou vient la photo.
enum SourceImage {
  /// La galerie, ou le selecteur de fichiers.
  galerie,

  /// L'appareil photo.
  camera,
}

/// Choisit une photo : ses octets, ou `null` si la personne renonce.
typedef ChoixImage = Future<Uint8List?> Function(SourceImage source);

/// Vrai quand l'appareil propose deux choix (appareil photo et galerie) :
/// Android et iOS hors navigateur.
bool get appareilPhotoProposeParDefaut =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// `image_picker`, restreint aux images.
Future<Uint8List?> choisirImageSysteme(SourceImage source) async {
  final XFile? fichier = await ImagePicker().pickImage(
    source: source == SourceImage.camera
        ? ImageSource.camera
        : ImageSource.gallery,
  );
  if (fichier == null) return null;
  return fichier.readAsBytes();
}
