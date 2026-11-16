// IMAGES-MESSAGERIE : ce qu'un fil recoit pour les images et les coeurs, tire
// du port des Messages metier. Un seul assemblage, pour tous les ecrans qui
// posent un `FilContextuel`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/age_eleve.dart';
import 'port_messages_metier.dart';

/// Les adresses d'images d'un fil, lues par le port : les miniatures en UNE
/// demande par fil, l'image complete a l'ouverture.
class SourceImagesPort implements SourceImagesFil {
  /// Cree la source du fil [filId].
  const SourceImagesPort(this._port, this.filId);

  final PortMessagesMetier _port;

  /// Le fil.
  final String filId;

  @override
  Future<Map<String, AdresseImage>> miniatures() => _port.urlsMiniatures(filId);

  @override
  Future<AdresseImage?> image(String imageId) => _port.urlImage(filId, imageId);
}

/// Les trois branchements d'un fil : adresses, coeurs, envoi d'une image.
class ImagesDuFil {
  /// Assemble les branchements du fil [filId].
  ImagesDuFil(PortMessagesMetier port, this.filId, {required this.peutJoindre})
    : _port = port,
      source = SourceImagesPort(port, filId);

  final PortMessagesMetier _port;

  /// Le fil.
  final String filId;

  /// Faux pour un compte eleve de moins de 18 ans : l'icone n'est pas rendue
  /// (le serveur refuse de toute facon, `mineur_refuse`).
  final bool peutJoindre;

  /// Les adresses des images du fil.
  final SourceImagesFil source;

  /// Pose ou retire mon coeur.
  Future<EtatCoeur> aimer(String messageId, bool aime) =>
      aime ? _port.aimer(messageId) : _port.nePlusAimer(messageId);

  /// Abandonne un depot d'image qui n'ira pas au bout (« Supprimer »), ou
  /// `null` si le compte ne peut pas joindre d'image.
  Future<void> Function(String imageId)? get annuler =>
      !peutJoindre ? null : _port.annulerImage;

  /// L'envoi d'un message avec image, ou `null` si le compte ne peut pas.
  EnvoiImageFil? get envoyer => !peutJoindre
      ? null
      : (
          String texte,
          String cle,
          ImagePrete image,
          ProgressionImage progression,
        ) => _port.envoyerImage(
          filId,
          texte,
          cle,
          image,
          progression: progression,
        );
}

/// Les images et coeurs du fil [filId], pour le compte connecte.
ImagesDuFil imagesDuFil(WidgetRef ref, String filId) => ImagesDuFil(
  ref.read(portMessagesMetierProvider),
  filId,
  peutJoindre: ref.watch(portAgeEleveProvider).ageDeLEleve() != AgeEleve.mineur,
);
