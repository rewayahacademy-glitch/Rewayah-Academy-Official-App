import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../fichiers/conversion_heic.dart';
import '../fichiers/formats_admis.dart';
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
///
/// COMPLEMENT-ET-FORMATS (directeur, 14/11/2026) : la piece choisie passe par
/// la regle unique des formats (`preparerFichier`, `SorteFichier.piece`) :
/// une photo HEIC est convertie en JPEG sur l'appareil, tout autre format que
/// JPEG ou PNG est refuse tout de suite ([FichierRefuse]), avant tout envoi.
/// Le PDF n'est plus propose : la direction ne sait pas l'afficher.
class SelecteurFichierNatif implements SelecteurFichier {
  /// Cree le selecteur.
  const SelecteurFichierNatif({this.convertir = convertirHeicNatif});

  /// La conversion d'une photo HEIC en JPEG sur l'appareil.
  final ConvertisseurHeic convertir;

  /// Ce que la boite de choix propose : les formats que la direction sait
  /// afficher (JPEG, PNG). Le HEIC n'y est pas : sur iPhone, le systeme
  /// convertit alors la photo en JPEG lui-meme.
  static final List<String> extensionsAcceptees = extensionsProposees(
    SorteFichier.piece,
  );

  @override
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type) async {
    final PlatformFile? fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensionsAcceptees,
    );
    if (fichier == null) {
      return null;
    }
    return preparerPiece(await fichier.readAsBytes(), type, convertir);
  }
}

/// Prepare une piece choisie : format lu dans les octets, HEIC converti,
/// nom de fichier deduit du format. Leve [FichierRefuse].
Future<PieceAEnvoyer> preparerPiece(
  Uint8List octets,
  TypePiece type,
  ConvertisseurHeic convertir,
) async {
  final FichierPret pret = await preparerFichier(
    octets,
    sorte: SorteFichier.piece,
    convertir: convertir,
  );
  return PieceAEnvoyer(
    octets: pret.octets,
    nomFichier: pret.nomFichier('piece'),
    type: type,
  );
}

/// Le selecteur employe par l'application.
final Provider<SelecteurFichier> selecteurFichierProvider =
    Provider<SelecteurFichier>((Ref ref) => const SelecteurFichierNatif());
