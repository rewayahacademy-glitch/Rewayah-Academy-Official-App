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
/// offre n'est inventee. La demonstration le surcharge. C'est la seule source
/// des offres (REMPL-1b) : l'Alerte utile de la Journee la lit aussi.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controleur.dart';
import 'absence_remplacement.dart';

/// Ou en est une offre, pour l'enseignant qui la lit (rendu par le serveur).
enum EtatOffreCommune {
  /// Personne ne l'a encore prise : l'enseignant peut l'accepter.
  ouverte,

  /// L'enseignant connecte l'a prise : c'est son remplacement.
  priseParMoi,

  /// Un collegue l'a prise avant lui. Son nom n'est pas rendu.
  priseParUnCollegue,

  /// A3 (31/10/2026) : le titulaire n'est pas encore dans la salle ; un
  /// remplacement se prepare. L'enseignant peut se declarer pret.
  preparation,

  /// L'enseignant connecte s'est declare pret le premier : si le titulaire
  /// n'entre pas a temps, la seance lui est confiee.
  pretParMoi,

  /// Un collegue s'est declare pret avant lui.
  pretParUnCollegue,
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

/// REMPLACEMENT-TEMPS-REEL (07/11/2026) : l'acceptation est recue, la
/// fenetre de priorite court (DECISION-REMPLACEMENT-2026-11-07.md). Le
/// serveur tranche a [fin] ; [enTete] dit si l'enseignant est, a cet
/// instant, le mieux place.
@immutable
class AttenteRemplacement {
  /// Cree l'attente.
  const AttenteRemplacement({required this.fin, required this.enTete});

  /// La fin de la fenetre, heure du serveur.
  final DateTime fin;

  /// Vrai si l'enseignant est en tete a cet instant.
  final bool enTete;
}

/// La reponse du serveur a une acceptation.
enum ResultatPriseRemplacement {
  /// L'enseignant est le remplacant confirme.
  acceptee,

  /// Un collegue l'a prise avant : rien n'a change pour l'enseignant.
  dejaPrise,

  /// Refus du serveur : l'enseignant a un cours a cette heure
  /// (`RemplacantOccupe`).
  occupe,

  /// Refus du serveur : l'enseignant ne peut pas prendre ce cours, le sien
  /// par exemple (`RemplacantIncompatible`).
  incompatible,
}

/// Le port du tableau commun des remplacements.
abstract interface class PortRemplacements {
  /// Les offres visibles par l'enseignant connecte (toute l'equipe depuis le
  /// 07/11/2026 : le genre n'est plus qu'une preference du serveur), mises a
  /// jour quand un collegue en prend une.
  Stream<List<OffreCommune>> suivre();

  /// Accepte la seance [seanceId]. Rend [ResultatPriseRemplacement.dejaPrise]
  /// si un autre enseignant l'obtient. Pendant la fenetre de priorite, rend
  /// compte de l'attente par [enAttente], puis rend le choix du serveur. Leve
  /// une exception quand la reponse n'arrive pas : l'ecran ne suppose alors
  /// aucun etat (E7).
  Future<ResultatPriseRemplacement> prendre(
    String seanceId, {
    void Function(AttenteRemplacement attente)? enAttente,
  });
}

/// La reponse du serveur a « Je suis pret » (A3, 31/10/2026).
enum ResultatPret {
  /// L'enseignant est retenu : le premier pret, c'est lui.
  retenu,

  /// Un collegue s'est declare pret juste avant.
  dejaRetenu,

  /// La preparation est close : le titulaire est arrive, ou l'offre est
  /// deja ouverte a tous.
  fermee,
}

/// Se declarer pret pendant la pre-alerte (A3). Un port a part, pour que les
/// ports du tableau commun deja ecrits restent valables.
abstract interface class PortPretRemplacement {
  /// Se declare pret pour la seance [seanceId]. HARMONISATION-A (08/11/2026)
  /// : le serveur retient le mieux place (genre, puis langue), a egalite le
  /// premier arrive, comme pour l'absence. Pendant la fenetre de priorite,
  /// rend compte de l'attente par [enAttente], puis rend le choix du
  /// serveur. Leve une exception quand la reponse n'arrive pas.
  Future<ResultatPret> seDeclarerPret(
    String seanceId, {
    void Function(AttenteRemplacement attente)? enAttente,
  });
}

/// Le port « Je suis pret » : absent tant que `main.dart` ne le pose pas ;
/// sans lui, aucun bouton.
final Provider<PortPretRemplacement?> portPretRemplacementProvider =
    Provider<PortPretRemplacement?>((Ref _) => null);

/// Le port : absent avant le branchement serveur.
final Provider<PortRemplacements?> portRemplacementsProvider =
    Provider<PortRemplacements?>((Ref _) => null);

/// Les offres du tableau commun. Sans port, aucune offre.
///
/// R9 (30/10/2026) : liee a la personne connectee. A la deconnexion le flux
/// est refait, l'ancien abonnement (relecture toutes les 30 s) est coupe, et
/// sans personne aucune offre n'est lue (`offres_remplacement` en 401).
final StreamProvider<List<OffreCommune>> offresCommunesProvider =
    StreamProvider<List<OffreCommune>>((Ref ref) {
      final String? personne = surveillerPersonneConnectee(ref);
      final PortRemplacements? port = ref.watch(portRemplacementsProvider);
      if (personne == null || port == null) {
        return Stream<List<OffreCommune>>.value(const <OffreCommune>[]);
      }
      return port.suivre();
    });
