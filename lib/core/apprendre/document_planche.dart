/// ESPACE-APPRENDRE (lot 5, 12/11/2026) : le modele d'affichage de la planche
/// de documents, a part du catalogue.
///
/// Le catalogue d'aujourd'hui (`LibraryResource`) ne distingue ni les rayons,
/// ni les types audio, video et lien externe, ni les vignettes, ni les
/// descriptions : le lot 3 (BIBLIOTHEQUE-UNE) les ajoute. La planche s'ecrit
/// donc contre ce petit modele, que remplit un adaptateur
/// ([documentsApprendreProvider]). **Un champ absent reste absent** : pas de
/// description inventee, pas de vignette inventee (la couverture par defaut
/// vient du type), pas de prix (aucun mot d'argent dans ce modele).
library;

import 'package:flutter/widgets.dart';

import '../tc_bibliotheque/couverture_ressource.dart';

/// Les types que l'eleve peut filtrer (charte, partie 11 : document, audio,
/// video, lien externe). Le Coran, une image, une lecon sont des documents.
enum TypeDocumentPlanche {
  /// Un document : le Coran, un livre, une page, une lecon, une image.
  document,

  /// Un enregistrement audio.
  audio,

  /// Une video.
  video,

  /// Un lien externe : une petite carte avec sa description.
  lienExterne,
}

/// Les deux rayons de la Bibliotheque (charte, partie 11).
enum RayonPlanche {
  /// En haut : « Documents des cours », fournis par l'academie, sans limite
  /// de nombre. Le Coran en est un.
  documentsDesCours,

  /// En bas : « Pour aller plus loin ». Rien n'y est vendu : on prepare la
  /// place, sans prix.
  pourAllerPlusLoin,
}

/// Ce qui se passe quand on ouvre un document.
@immutable
sealed class OuvertureDocument {
  const OuvertureDocument();
}

/// S'ouvre dans l'application, par une adresse du routeur (la fiche d'un
/// document, le lecteur du Coran).
@immutable
class OuvrirDansLApplication extends OuvertureDocument {
  /// Cree l'ouverture.
  const OuvrirDansLApplication(this.chemin);

  /// L'adresse du routeur.
  final String chemin;
}

/// S'ouvre hors de l'application, apres une confirmation.
@immutable
class OuvrirHorsApplication extends OuvertureDocument {
  /// Cree l'ouverture.
  const OuvrirHorsApplication(this.adresse);

  /// L'adresse du lien, publiee par l'academie.
  final Uri adresse;
}

/// Un document de la planche.
@immutable
class DocumentPlanche {
  /// Cree un document.
  const DocumentPlanche({
    required this.id,
    required this.titre,
    required this.type,
    required this.rayon,
    required this.ouverture,
    this.description,
    this.vignette,
    this.couverture,
  });

  /// Son identifiant, stable (cle des widgets et des tests).
  final String id;

  /// Son titre.
  final String titre;

  /// Sa description, ou `null` : jamais inventee.
  final String? description;

  /// Son type.
  final TypeDocumentPlanche type;

  /// Son rayon.
  final RayonPlanche rayon;

  /// Ce qui se passe quand on l'ouvre.
  final OuvertureDocument ouverture;

  /// La vignette deposee, quand l'appelant sait la charger. Aujourd'hui
  /// personne : le catalogue ne rend pas encore de vignette ni de service
  /// pour la charger. `null` : la vignette par defaut du type.
  final Widget? vignette;

  /// La couverture calculee d'un document, pour la vignette par defaut d'un
  /// livre (le Coran garde la sienne). `null` : la vignette par defaut du type
  /// sans couverture de livre.
  final CouvertureRessource? couverture;
}
