// Le port du partage de la carte a partager (CAND-06, « Un proche veut apprendre
// le Coran ? ») : ouvrir le menu de partage de l'appareil avec l'image de la
// carte.
//
// **Aucune dependance serveur.** Rien de ce qui se partage ne vient de la base
// ni n'y retourne : la carte est rendue par Flutter, le lien vient de la
// configuration (`lien_offre.dart`), et le partage est facultatif et sans effet
// sur la candidature (decision du directeur du 22/10/2026) : aucun compteur,
// aucun evenement, aucune ecriture. Le seul point qui varie est l'appareil,
// d'ou un port : sur le web, l'API Web Share du navigateur
// (`partage_appareil_web.dart`) ; ailleurs, aucun partage n'est propose
// (`partage_appareil_memoire.dart`).
//
// « Enregistrer l'image » passe par `PortEnregistrementFichier`
// (`tc_telechargement`) et « Copier le lien » par le presse-papiers de Flutter :
// ils existent deja et ne se recreent pas.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'partage_appareil_memoire.dart'
    if (dart.library.js_interop) 'partage_appareil_web.dart';

/// Ce que l'appareil sait partager.
enum NiveauPartage {
  /// Le menu de partage accepte un fichier : la carte part comme image, avec
  /// sa phrase et son lien.
  image,

  /// Le menu de partage n'accepte que du texte : la phrase et le lien partent,
  /// sans image. L'image reste a enregistrer.
  lien,

  /// Aucun menu de partage : le bouton « Partager » n'est pas rendu.
  aucun,
}

/// Comment s'est terminee l'ouverture du menu de partage.
enum IssuePartage {
  /// Le menu a transmis la carte a l'application choisie.
  partage,

  /// La personne a ferme le menu sans choisir. Ce n'est pas une erreur : aucun
  /// message.
  annule,
}

/// Le menu de partage n'a pas pu s'ouvrir, ou l'appareil l'a refuse (delai
/// ecoule depuis le geste, partage non autorise). L'ecran dit quoi faire a la
/// place : enregistrer l'image ou copier le lien.
final class PartageImpossible implements Exception {
  /// Cree l'erreur.
  const PartageImpossible();

  @override
  String toString() => 'PartageImpossible()';
}

/// Le partage de l'image de la carte par le menu de l'appareil.
abstract interface class PortPartageOffre {
  /// Ce que l'appareil sait partager. Constant pour la duree de vie du port.
  NiveauPartage get niveau;

  /// Ouvre le menu de partage avec [png] (fichier [nomFichier]), [titre],
  /// [texte] et [lien]. L'image est deja rendue : le menu doit s'ouvrir dans le
  /// geste de la personne, sans calcul entre le toucher et l'appel (Safari
  /// refuse le partage sinon).
  ///
  /// Rend [IssuePartage.annule] si la personne ferme le menu ; leve
  /// [PartageImpossible] si l'appareil refuse. Sans partage ([NiveauPartage.aucun])
  /// leve toujours [PartageImpossible].
  Future<IssuePartage> partager({
    required Uint8List png,
    required String nomFichier,
    required String titre,
    required String texte,
    required Uri lien,
  });
}

/// Le port de l'appareil : le menu du navigateur sur le web, rien ailleurs.
final Provider<PortPartageOffre> portPartageOffreProvider =
    Provider<PortPartageOffre>((Ref _) => partageAppareil());
