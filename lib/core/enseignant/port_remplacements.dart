/// REMPL-1 : les remplacements communs a tous les enseignants, premier
/// arrive, premier servi.
///
/// Demande du directeur (REMPL-1, 01/10, precisee le 09/10) : un ecran dedie,
/// commun a tous les enseignants ; l'offre arrive en alerte urgente ; le
/// premier qui accepte prend la seance, les autres voient l'offre prise.
///
/// Ce que le serveur porte, et que Flutter ne decide jamais :
///
/// - **la visibilite par genre** (decision du 02/10) : une Classe d'hommes
///   n'est proposee qu'aux enseignants, une Classe de femmes qu'aux
///   enseignantes, une Classe indeterminee a tous. Le flux [suivre] rend des
///   offres **deja filtrees** : l'ecran ne lit aucun genre, ni celui de la
///   Classe, ni `profiles.gender` ;
/// - **l'acceptation atomique** : [PortRemplacements.prendre] rend
///   [ResultatPriseRemplacement.dejaPrise] a toute acceptation qui arrive
///   apres la premiere. Jamais deux remplacants pour une seance ;
/// - **l'etat de chaque offre** pour l'enseignant qui la lit
///   ([EtatOffreCommune]) : l'ecran montre le bouton d'acceptation seulement
///   sur une offre `ouverte` (il lit une capacite, pas un role).
///
/// Aucun branchement serveur ici : en production le port est absent
/// ([portRemplacementsProvider] vaut `null`), le flux est vide et aucune
/// offre n'est inventee (meme convention que `offresRemplacementProvider`
/// avant BR-1). La demonstration le surcharge.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'absence_remplacement.dart';

/// Ou en est une offre, pour l'enseignant qui la lit (rendu par le serveur).
enum EtatOffreCommune {
  /// Personne ne l'a encore prise : l'enseignant peut l'accepter.
  ouverte,

  /// L'enseignant connecte l'a prise : c'est son remplacement.
  priseParMoi,

  /// Un collegue l'a prise avant lui. Son nom n'est pas rendu.
  priseParUnCollegue,
}

/// Une offre de remplacement du tableau commun, avec son etat.
///
/// Reprend [OffreRemplacement] (Classe, debut, fin, nombre d'eleves), sans
/// motif d'absence, sans nom de l'enseignant absent, sans genre.
@immutable
class OffreCommune {
  /// Cree l'offre.
  const OffreCommune({required this.offre, required this.etat});

  /// La seance a assurer.
  final OffreRemplacement offre;

  /// Son etat pour l'enseignant connecte.
  final EtatOffreCommune etat;
}

/// La reponse du serveur a une acceptation.
enum ResultatPriseRemplacement {
  /// L'enseignant est le remplacant confirme.
  acceptee,

  /// Un collegue l'a prise avant : rien n'a change pour l'enseignant.
  dejaPrise,
}

/// Le port du tableau commun des remplacements.
abstract interface class PortRemplacements {
  /// Les offres visibles par l'enseignant connecte, deja filtrees par genre
  /// cote serveur, et mises a jour quand un collegue en prend une.
  Stream<List<OffreCommune>> suivre();

  /// Accepte la seance [seanceId]. Rend [ResultatPriseRemplacement.dejaPrise]
  /// si un collegue l'a prise avant. Leve une exception quand la reponse
  /// n'arrive pas : l'ecran ne suppose alors aucun etat (E7).
  Future<ResultatPriseRemplacement> prendre(String seanceId);
}

/// Le port : absent avant le branchement serveur.
final Provider<PortRemplacements?> portRemplacementsProvider =
    Provider<PortRemplacements?>((Ref _) => null);

/// Les offres du tableau commun. Sans port, aucune offre.
final StreamProvider<List<OffreCommune>> offresCommunesProvider =
    StreamProvider<List<OffreCommune>>((Ref ref) {
      final PortRemplacements? port = ref.watch(portRemplacementsProvider);
      if (port == null) {
        return Stream<List<OffreCommune>>.value(const <OffreCommune>[]);
      }
      return port.suivre();
    });
