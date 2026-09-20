import 'package:flutter/foundation.dart';

import 'port_politique_observation.dart';

/// Le compte a rebours du budget d'observation, pret a afficher.
///
/// **Fonction pure**, comme `VueSalle.depuis`, `VuePresence.depuis` et
/// `VuePlanning.depuis` : le bornage, l'epuisement et l'horloge qui recule se
/// verifient sans monter d'ecran, sans reseau et sans SDK.
///
/// **C'est un AFFICHAGE, jamais l'application de la limite** (specification
/// 11.4). La borne est serveur : verification du lien tuteur-enfant, de la
/// seance, du groupe, de la politique et du quota avant le jeton, puis
/// revocation a l'epuisement. Ce que cette classe garantit est plus modeste,
/// et c'est exactement ce qu'on peut garantir cote client :
///
/// 1. **Le temps affiche n'excede jamais le temps que le serveur a annonce.**
///    Une horloge locale qu'on ferait reculer -- changement d'heure systeme,
///    veille, bricolage volontaire -- produit un ecoule negatif, ramene a
///    zero, donc au plus la valeur serveur. On ne gagne pas une seconde en
///    reculant sa montre.
/// 2. **Le temps affiche ne descend jamais sous zero.** Un compte a rebours
///    negatif laisserait croire a une dette de temps, la ou il n'y a qu'une
///    visite terminee.
///
/// Ce que cette classe ne garantit pas, et ne peut pas garantir : qu'une visite
/// s'arrete. Seul le serveur l'arrete.
@immutable
class VueBudgetObservation {
  const VueBudgetObservation._({
    required this.restantAffiche,
    required this.restantServeur,
    required this.visitesUtilisees,
    required this.visitesMax,
    required this.policyVersion,
  });

  /// Calcule l'affichage a un instant donne.
  ///
  /// [recuA] est l'instant **local** auquel [budget] est arrive. Il n'est pas
  /// un champ du contrat `BudgetObservation` et n'a rien a y faire : c'est une
  /// mesure du client, et le client ne dit pas au serveur quelle heure il est.
  /// C'est l'appelant qui le releve, une fois, a la reception.
  factory VueBudgetObservation.depuis({
    required BudgetObservation budget,
    required DateTime recuA,
    required DateTime maintenant,
  }) {
    final Duration brut = maintenant.difference(recuA);
    // Une horloge qui recule ne cree pas de temps : l'ecoule est plancherise a
    // zero, donc le restant affiche plafonne a la valeur serveur.
    final Duration ecoule = brut.isNegative ? Duration.zero : brut;
    final Duration restant = budget.restant - ecoule;
    return VueBudgetObservation._(
      restantAffiche: restant.isNegative ? Duration.zero : restant,
      restantServeur: budget.restant,
      visitesUtilisees: budget.visitesUtilisees,
      visitesMax: budget.visitesMax,
      policyVersion: budget.policyVersion,
    );
  }

  /// Ce que le compte a rebours montre.
  final Duration restantAffiche;

  /// Ce que le serveur a annonce a la derniere lecture.
  ///
  /// Garde a cote de [restantAffiche] pour que l'invariant se verifie a l'oeil
  /// autant qu'au test : le premier n'excede jamais le second.
  final Duration restantServeur;

  /// Visites deja consommees pour cette seance.
  final int visitesUtilisees;

  /// Visites autorisees pour cette seance.
  final int visitesMax;

  /// La version de politique sous laquelle ce budget est calcule.
  final String policyVersion;

  /// Vrai quand il ne reste plus une seconde a afficher.
  bool get epuise => restantAffiche <= Duration.zero;

  /// Le restant, arrondi vers le haut a la seconde.
  ///
  /// Vers le haut : afficher « 0 s restantes » pendant les neuf cent
  /// quatre-vingt-dix-neuf derniers millisecondes ferait croire a un compte a
  /// rebours bloque.
  int get secondesRestantes => (restantAffiche.inMilliseconds / 1000).ceil();

  /// Le rang de la visite en cours, a partir de 1.
  int get rangVisite => visitesUtilisees < 1 ? 1 : visitesUtilisees;
}
