// ALERTE-1 : une alerte de la direction et son ordre de lecture.
//
// Decision du 05/10/2026, deleguee par le directeur (« c'est a toi de choisir
// le meilleur choix... respecter a la lettre toutes les specs ») : trois
// niveaux de gravite, et un seul ordre, la gravite puis la date
// (`docs/current/DASH_STRATEGIE.md`, section 3.9).

import 'package:flutter/foundation.dart';

import '../router/chemin_retour.dart';

/// La gravite d'une alerte, de la plus grave a la moins grave.
///
/// L'ordre de declaration EST l'ordre de lecture : [trierAlertes] s'appuie
/// sur `index`. Le directeur peut corriger la liste a tout moment.
enum GraviteAlerte {
  /// Exige une action humaine immediate pour une seance en cours ou
  /// imminente, ou touche la securite d'un eleve (classe sans enseignant,
  /// incident de seance, signalement).
  urgent,

  /// A traiter dans la journee (paiement echu, remplacement a confirmer).
  important,

  /// Tout le reste.
  info,
}

/// Une alerte telle que le serveur la rend : deja redigee, jamais composee
/// par l'application.
@immutable
class Alerte {
  /// Cree une alerte. [destination] est validee a la construction : un
  /// chemin externe ou mal forme devient `null`, jamais un lien suivi.
  Alerte({
    required this.id,
    required this.gravite,
    required this.titre,
    required this.creeeLe,
    String? destination,
  }) : destination = cheminRetourValide(destination);

  /// Identifiant stable.
  final String id;

  /// Sa gravite.
  final GraviteAlerte gravite;

  /// Ce qui se passe, en une phrase.
  final String titre;

  /// L'horodatage SERVEUR de sa creation : il ordonne les alertes d'une meme
  /// gravite et servira a mesurer le delai jusqu'a l'affichage (DASH-BR-06).
  final DateTime creeeLe;

  /// La page ou elle se traite, ou `null`.
  final String? destination;

  /// Vrai pour une alerte urgente.
  bool get urgente => gravite == GraviteAlerte.urgent;
}

/// Les alertes dans l'ordre de lecture : la gravite d'abord (urgent,
/// important, info), puis la plus recente d'abord ; a egalite, l'identifiant,
/// pour qu'un meme jeu rende toujours le meme ordre.
///
/// Le serveur trie deja (DASH-BR-03) ; l'ecran retrie quand meme, car une
/// alerte arrivee en temps reel s'ajoute en queue du flux.
List<Alerte> trierAlertes(Iterable<Alerte> alertes) =>
    alertes.toList()..sort((Alerte a, Alerte b) {
      final int gravite = a.gravite.index.compareTo(b.gravite.index);
      if (gravite != 0) {
        return gravite;
      }
      final int date = b.creeeLe.compareTo(a.creeeLe);
      return date != 0 ? date : a.id.compareTo(b.id);
    });
