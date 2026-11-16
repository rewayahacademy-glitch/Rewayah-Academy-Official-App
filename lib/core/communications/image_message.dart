// Images et coeurs de la messagerie (lot IMAGES-MESSAGERIE, plan du directeur
// du 16/11/2026) : les modeles du client, d'apres le contrat serveur
// `docs/current/IMAGES-MESSAGERIE.md`.
//
// Le client ne voit jamais une cle R2 : il recoit des adresses signees,
// demandees UNE fois par fil ouvert (miniatures) et une fois par image ouverte
// en grand (image complete).

import 'package:flutter/foundation.dart';

/// L'etat d'une image de message rendu par le serveur (§4.1).
enum EtatImageMessage {
  /// Depot demande, pas encore confirme (visible de son auteur seulement).
  enAttente,

  /// Confirmee : on la voit.
  confirmee,

  /// Retiree (90 jours passes) ou abandonnee : plus aucune adresse.
  supprimee;

  /// Lit l'etat du serveur ; inconnu : retiree (jamais un cadre vide).
  static EtatImageMessage depuis(Object? valeur) => switch (valeur) {
    'en_attente' => EtatImageMessage.enAttente,
    'confirmee' => EtatImageMessage.confirmee,
    _ => EtatImageMessage.supprimee,
  };
}

/// L'image d'un message : de quoi reserver sa place avant son chargement.
@immutable
class ImageMessage {
  /// Cree l'image.
  const ImageMessage({
    required this.id,
    required this.largeur,
    required this.hauteur,
    this.couleurMoyenne,
    this.etat = EtatImageMessage.confirmee,
  });

  /// Lit l'objet `image` du fil (§4.1) ; `null` si absent ou illisible.
  static ImageMessage? depuisJson(Object? json) {
    if (json is! Map) return null;
    final Object? id = json['id'];
    final Object? l = json['largeur'];
    final Object? h = json['hauteur'];
    if (id is! String || l is! int || h is! int || l < 1 || h < 1) return null;
    final Object? couleur = json['couleur_moyenne'];
    return ImageMessage(
      id: id,
      largeur: l,
      hauteur: h,
      couleurMoyenne: couleur is String ? couleur : null,
      etat: EtatImageMessage.depuis(json['etat']),
    );
  }

  /// Identifiant de l'image.
  final String id;

  /// Largeur en pixels, apres compression.
  final int largeur;

  /// Hauteur en pixels, apres compression.
  final int hauteur;

  /// `#rrggbb` : le fond peint pendant le chargement ; `null` : aucun.
  final String? couleurMoyenne;

  /// L'etat de l'image.
  final EtatImageMessage etat;

  /// Largeur / hauteur, connu d'avance : la place est reservee.
  double get rapport => largeur / hauteur;
}

/// Une adresse signee d'une image (miniature ou image complete).
@immutable
class AdresseImage {
  /// Cree l'adresse.
  const AdresseImage({required this.url, required this.expireLe, this.octets});

  /// L'adresse `GET` signee.
  final String url;

  /// Les octets deja en memoire (image que l'on vient d'envoyer, demonstration,
  /// tests) : quand ils sont donnes, rien n'est telecharge.
  final Uint8List? octets;

  /// L'instant d'expiration (de la lecture, plus la duree annoncee).
  final DateTime expireLe;
}

/// Les codes de refus d'un depot d'image (§3.4) : le client se regle sur eux,
/// jamais sur la phrase du serveur.
enum RefusImage {
  /// Corps, taille, dimension ou couleur hors bornes.
  demandeInvalide,

  /// Autre chose que JPEG, PNG, WebP.
  typeRefuse,

  /// Image au-dela de 2 Mo.
  imageTropLourde,

  /// Miniature au-dela de 100 Ko.
  miniatureTropLourde,

  /// Pas partie du fil, lecture seule, ou message d'un autre.
  nonAutorise,

  /// Compte eleve de moins de 18 ans.
  mineurRefuse,

  /// 20 images demandees dans l'heure.
  limiteHoraire,

  /// Ce message a deja son image.
  dejaUneImage,

  /// Depot inconnu, confirme, annule ou trop vieux.
  depotIndisponible,

  /// Les premiers octets ne sont pas ceux du type annonce.
  contenuDifferent,

  /// Confirmation avant l'arrivee des deux fichiers.
  objetIntrouvable,

  /// R2 ou ses secrets indisponibles.
  stockageIndisponible,

  /// Secret de confirmation absent ou different.
  confirmationIndisponible,

  /// Panne de la base.
  depotImpossible,

  /// Le stockage a refuse le `PUT` (adresse expiree, signature).
  envoiStockage,

  /// Aucune reponse : la seule cause qui soit la connexion.
  reseau,

  /// Source de plus de 15 Mo, ou image impossible a ramener sous les limites.
  imageTropGrosse,

  /// Fichier illisible comme image.
  imageIllisible;

  /// Le refus que dit le serveur par [code] ; inconnu : [depotImpossible]
  /// (jamais « connexion » pour un refus du serveur).
  static RefusImage depuisCode(Object? code) => switch (code) {
    'demande_invalide' => RefusImage.demandeInvalide,
    'type_refuse' => RefusImage.typeRefuse,
    'image_trop_lourde' => RefusImage.imageTropLourde,
    'miniature_trop_lourde' => RefusImage.miniatureTropLourde,
    'non_autorise' => RefusImage.nonAutorise,
    'mineur_refuse' => RefusImage.mineurRefuse,
    'limite_horaire' => RefusImage.limiteHoraire,
    'deja_une_image' => RefusImage.dejaUneImage,
    'depot_indisponible' => RefusImage.depotIndisponible,
    'contenu_different' => RefusImage.contenuDifferent,
    'objet_introuvable' => RefusImage.objetIntrouvable,
    'stockage_indisponible' => RefusImage.stockageIndisponible,
    'confirmation_indisponible' ||
    'confirmation_mal_reglee' => RefusImage.confirmationIndisponible,
    _ => RefusImage.depotImpossible,
  };

  /// Vrai quand « Reessayer » peut changer l'issue (panne passagere).
  bool get reessayable => switch (this) {
    reseau ||
    envoiStockage ||
    stockageIndisponible ||
    depotImpossible ||
    objetIntrouvable => true,
    _ => false,
  };
}

/// Un depot d'image qui a echoue : [refus] dit pourquoi.
class EchecImage implements Exception {
  /// Cree l'echec.
  const EchecImage(this.refus);

  /// La cause.
  final RefusImage refus;

  @override
  String toString() => 'EchecImage($refus)';
}

/// Une image prete a partir : deja reduite, sans metadonnees, avec sa
/// miniature (voir `compression_image.dart`).
@immutable
class ImagePrete {
  /// Cree l'image prete.
  const ImagePrete({
    required this.octets,
    required this.mime,
    required this.largeur,
    required this.hauteur,
    required this.miniature,
    required this.mimeMiniature,
    this.couleurMoyenne,
  });

  /// L'image compressee.
  final Uint8List octets;

  /// `image/jpeg` ou `image/png`.
  final String mime;

  /// Largeur apres compression.
  final int largeur;

  /// Hauteur apres compression.
  final int hauteur;

  /// La miniature de 320 de cote.
  final Uint8List miniature;

  /// Le type de la miniature.
  final String mimeMiniature;

  /// `#rrggbb`, lue sur la miniature.
  final String? couleurMoyenne;
}

/// La progression d'un envoi d'image, de 0 a 1.
typedef ProgressionImage = void Function(double fraction);

/// L'envoi d'un message avec son image : texte, cle d'idempotence, image prete,
/// progression. Echoue par [EchecImage].
typedef EnvoiImageFil = Future<void> Function(
  String texte,
  String cle,
  ImagePrete image,
  ProgressionImage progression,
);

/// La source des adresses d'images d'un fil, donnee a `FilDiscussion` : les
/// miniatures en UNE demande par fil, l'image complete a l'ouverture seulement.
abstract interface class SourceImagesFil {
  /// Les adresses des miniatures du fil, par identifiant d'image : une seule
  /// demande, gardee jusqu'a l'expiration (1 h). Une image retiree n'a pas
  /// d'entree.
  Future<Map<String, AdresseImage>> miniatures();

  /// L'adresse de l'image complete [imageId] ; `null` si elle est retiree.
  Future<AdresseImage?> image(String imageId);
}

/// Le coeur d'un message apres un geste : son compte et si j'ai le mien.
@immutable
class EtatCoeur {
  /// Cree l'etat.
  const EtatCoeur({required this.coeurs, required this.aimeParMoi});

  /// Le nombre de coeurs donnes.
  final int coeurs;

  /// J'ai donne le mien.
  final bool aimeParMoi;
}
