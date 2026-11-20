import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../fichiers/compression_image.dart';
import '../fichiers/compression_image_autre.dart'
    if (dart.library.js_interop) '../fichiers/compression_image_web.dart'
    as natif;
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
  const SelecteurFichierNatif({
    this.convertir = convertirHeicNatif,
    this.reduire = natif.reduire,
  });

  /// La conversion d'une photo HEIC en JPEG sur l'appareil.
  final ConvertisseurHeic convertir;

  /// La reduction d'une photo trop lourde, sur l'appareil (PE-B10).
  final Reducteur reduire;

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
    return preparerPiece(
      await fichier.readAsBytes(),
      type,
      convertir,
      reduire: reduire,
    );
  }
}

/// PE-B10 : la plus grosse source qu'on tente de reduire sur l'appareil.
/// Au-dela, le decodage risque d'epuiser la memoire d'un telephone modeste :
/// la phrase de la taille dit de reprendre la photo.
const int sourcePieceMaxOctets = 30 * 1024 * 1024;

/// PE-B10 : les essais de reduction d'une piece trop lourde, du plus fidele au
/// plus leger. Bornes de lisibilite : jamais moins de 2400 points sur le plus
/// grand cote, jamais une qualite JPEG sous 0,8. Une piece d'identite reste
/// lisible a ces bornes (une carte photographiee en entier y garde plus de
/// 10 points par millimetre) ; si elle ne tient pas sous la taille maximale a
/// ces bornes, elle est refusee avec la phrase de la taille, jamais degradee.
const List<(int, double)> essaisReductionPiece = <(int, double)>[
  (4000, 0.9),
  (3200, 0.85),
  (2400, 0.8),
];

/// Prepare une piece choisie : format lu dans les octets, HEIC converti,
/// nom de fichier deduit du format. Leve [FichierRefuse].
///
/// PE-B10 : une photo JPEG ou PNG plus lourde que la taille maximale n'est
/// plus refusee d'emblee : elle est reduite sur l'appareil, aux bornes de
/// [essaisReductionPiece]. Une photo qui passe deja est envoyee telle quelle,
/// sans aucune reduction.
Future<PieceAEnvoyer> preparerPiece(
  Uint8List octets,
  TypePiece type,
  ConvertisseurHeic convertir, {
  Reducteur reduire = natif.reduire,
}) async {
  FichierPret pret;
  try {
    pret = await preparerFichier(
      octets,
      sorte: SorteFichier.piece,
      convertir: convertir,
    );
  } on FichierRefuse catch (refus) {
    if (refus.cause != CauseRefusFichier.tropLourd ||
        octets.lengthInBytes > sourcePieceMaxOctets) {
      rethrow;
    }
    // Relecture du 20/11 (M4) : une photo HEIC deja convertie en JPEG mais
    // encore trop lourde se reduit a partir du JPEG converti (le navigateur
    // ne sait pas toujours lire le HEIC).
    Uint8List source = octets;
    if (formatDepuisOctets(octets) == FormatFichier.heic) {
      Uint8List? jpeg;
      try {
        jpeg = await convertir(
          octets,
          coteMax: SorteFichier.piece.coteMaxConversion,
        );
      } on Object {
        jpeg = null;
      }
      if (jpeg == null || formatDepuisOctets(jpeg) != FormatFichier.jpeg) {
        rethrow;
      }
      source = jpeg;
    }
    final Uint8List? reduite = await reduirePiece(source, reduire);
    if (reduite == null) rethrow;
    pret = FichierPret(octets: reduite, format: FormatFichier.jpeg);
  }
  return PieceAEnvoyer(
    octets: pret.octets,
    nomFichier: pret.nomFichier('piece'),
    type: type,
  );
}

/// Reduit une piece trop lourde en JPEG sous la taille maximale, aux bornes
/// de [essaisReductionPiece] ; `null` si elle n'y tient pas ou si l'appareil
/// ne sait pas la lire.
Future<Uint8List?> reduirePiece(Uint8List source, Reducteur reduire) async {
  for (final (int cote, double qualite) in essaisReductionPiece) {
    final ReductionImage? r;
    try {
      r = await reduire(
        source,
        coteMax: cote,
        qualite: qualite,
        couleur: false,
      );
    } on Object {
      return null;
    }
    if (r == null) return null;
    if (formatDepuisOctets(r.octets) != FormatFichier.jpeg) return null;
    if (r.octets.lengthInBytes <= SorteFichier.piece.tailleMaxOctets) {
      return r.octets;
    }
  }
  return null;
}

/// Le selecteur employe par l'application.
final Provider<SelecteurFichier> selecteurFichierProvider =
    Provider<SelecteurFichier>((Ref ref) => const SelecteurFichierNatif());
