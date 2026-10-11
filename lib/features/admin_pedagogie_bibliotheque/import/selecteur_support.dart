/// CAP29-C : d'ou vient le fichier d'un support.
///
/// Une interface, parce qu'aucun test ne peut ouvrir une boite de dialogue
/// native. Le selecteur reel utilise `file_picker` (deja une dependance de
/// l'application) et ne propose que les formats que le type de support
/// accepte : pas d'EPUB, pas d'audio (spec CAP-29 §3.4).
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin/modeles_bibliotheque_admin.dart';

/// Un fichier choisi : son contenu part par le canal du port, le nom ne sert
/// qu'a l'affichage.
class FichierChoisi {
  /// Cree le fichier.
  const FichierChoisi({
    required this.nom,
    required this.octets,
    required this.mime,
  });

  /// Le nom, pour l'affichage.
  final String nom;

  /// Le contenu.
  final Uint8List octets;

  /// Le type MIME annonce, deduit de l'extension.
  final String mime;

  /// Le descriptif envoye au port.
  FichierADeposer get descriptif =>
      FichierADeposer(nom: nom, octets: octets.length, mime: mime);
}

/// Ce que l'on accepte pour un type de support : extensions et MIME.
class FormatsAcceptes {
  /// Cree la liste.
  const FormatsAcceptes(this.extensions, this.mimes);

  /// Les extensions (sans point).
  final List<String> extensions;

  /// Le MIME de chaque extension.
  final Map<String, String> mimes;

  /// Aucun fichier (Coran : source canonique, jamais un fichier depose).
  static const FormatsAcceptes aucun = FormatsAcceptes(<String>[], {});

  /// Les formats d'un type de support.
  static FormatsAcceptes de(TypeRessource type) => switch (type) {
    TypeRessource.pdf => const FormatsAcceptes(
      <String>['pdf'],
      {'pdf': 'application/pdf'},
    ),
    TypeRessource.image => const FormatsAcceptes(
      <String>['png', 'jpg', 'jpeg', 'webp'],
      {
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'webp': 'image/webp',
      },
    ),
    TypeRessource.texteStructure || TypeRessource.lecon =>
      const FormatsAcceptes(<String>['json'], {'json': 'application/json'}),
    TypeRessource.quran => aucun,
  };
}

/// Le selecteur de fichier d'un support.
abstract interface class SelecteurFichierSupport {
  /// Demande un fichier de [type]. `null` quand la personne renonce.
  Future<FichierChoisi?> choisir(TypeRessource type);
}

/// Le selecteur reel, par la boite de dialogue du systeme.
class SelecteurFichierSupportNatif implements SelecteurFichierSupport {
  /// Cree le selecteur.
  const SelecteurFichierSupportNatif();

  @override
  Future<FichierChoisi?> choisir(TypeRessource type) async {
    final FormatsAcceptes formats = FormatsAcceptes.de(type);
    if (formats.extensions.isEmpty) return null;
    final PlatformFile? fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: formats.extensions,
    );
    if (fichier == null) return null;
    final String extension = fichier.name.contains('.')
        ? fichier.name.split('.').last.toLowerCase()
        : '';
    return FichierChoisi(
      nom: fichier.name,
      octets: await fichier.readAsBytes(),
      mime: formats.mimes[extension] ?? 'application/octet-stream',
    );
  }
}

/// Le selecteur employe par l'application.
final Provider<SelecteurFichierSupport> selecteurFichierSupportProvider =
    Provider<SelecteurFichierSupport>(
      (Ref _) => const SelecteurFichierSupportNatif(),
    );
