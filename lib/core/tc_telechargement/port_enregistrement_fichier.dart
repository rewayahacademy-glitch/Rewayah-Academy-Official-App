import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'download_asset.dart';

/// « Enregistrer une copie » / « Telecharger en PDF » (spec section 6.5).
///
/// **Toujours par le selecteur de fichiers du systeme.** Jamais un chemin
/// `/sdcard` bricole : c'est une interdiction explicite de la spec, et c'est
/// aussi la seule voie qui respecte le bac a sable d'iOS, le Storage Access
/// Framework d'Android et le telechargement navigateur sur le web.
abstract class PortEnregistrementFichier {
  /// Enregistre [octets] sous le nom propose. Rend le chemin ou l'URI retenu,
  /// ou `null` **quand la personne renonce** -- une annulation n'est pas une
  /// erreur et ne produit aucun message.
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  });
}

/// L'enregistrement reel, par la boite de dialogue du systeme.
///
/// `file_picker 12.2.0` est **deja** une dependance du projet et expose
/// `saveFile()` : la regle de la spec section 6.5 se satisfait sans ajouter
/// `share_plus` ni `path_provider` (decision D-11). Meme forme que
/// `SelecteurFichierNatif`, qui est le patron de ce fichier.
class EnregistrementFichierSysteme implements PortEnregistrementFichier {
  /// Cree l'enregistreur.
  const EnregistrementFichierSysteme();

  @override
  Future<String?> enregistrerCopie({
    required List<int> octets,
    required String nomFichierPropose,
    required String typeMime,
  }) async {
    final Uri? destination = await FilePicker.saveFile(
      fileName: nomFichierPropose,
      bytes: Uint8List.fromList(octets),
      mimeType: typeMime,
    );
    // Selon la plateforme, le schema est `file`, `content`, `blob` ou `data` :
    // on rend la chaine telle quelle, et on n'en deduit jamais un chemin.
    return destination?.toString();
  }
}

/// Le nom de fichier propose a la personne.
///
/// Dans sa langue et avec ses accents : c'est un nom que quelqu'un relira dans
/// son gestionnaire de fichiers. Seuls les caracteres qu'un systeme de
/// fichiers refuse sont remplaces, et la longueur est bornee pour ne pas
/// depasser les limites de nom des plateformes.
String nomFichierPropose(String titre, FormatArtefact format) {
  final String base = titre
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final String sur = base.isEmpty ? 'ressource' : base;
  final String borne = sur.length <= 80 ? sur : sur.substring(0, 80).trim();
  return '$borne.${format.extension}';
}

/// L'enregistrement de fichier employe par l'application.
final Provider<PortEnregistrementFichier> portEnregistrementFichierProvider =
    Provider<PortEnregistrementFichier>(
      (Ref ref) => const EnregistrementFichierSysteme(),
    );
