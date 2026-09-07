import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import 'service_dossier.dart';

/// D'ou vient le fichier d'une piece d'identite.
///
/// Une interface, parce qu'aucun test ne peut ouvrir une boite de dialogue
/// native, et parce que le lecteur varie par plateforme alors que le reste du
/// parcours de depot n'en depend pas.
abstract interface class SelecteurFichier {
  /// Demande un fichier a l'utilisateur. `null` quand il renonce.
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type);
}

/// Le selecteur reel, par la boite de dialogue du systeme.
class SelecteurFichierNatif implements SelecteurFichier {
  /// Cree le selecteur.
  const SelecteurFichierNatif();

  /// Ce qu'une piece d'identite peut etre. Volontairement court : une photo ou
  /// un PDF. Elargir la liste elargirait la surface a analyser cote serveur.
  static const List<String> extensionsAcceptees = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'pdf',
  ];

  @override
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type) async {
    final PlatformFile? fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensionsAcceptees,
    );
    if (fichier == null) {
      return null;
    }

    final Uint8List octets = await fichier.readAsBytes();
    return PieceAEnvoyer(octets: octets, nomFichier: fichier.name, type: type);
  }
}

/// Le selecteur employe par l'application.
final Provider<SelecteurFichier> selecteurFichierProvider =
    Provider<SelecteurFichier>((Ref ref) => const SelecteurFichierNatif());
