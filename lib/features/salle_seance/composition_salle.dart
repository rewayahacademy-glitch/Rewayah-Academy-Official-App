// TB-5 (UI-02, UI-03 ; plan V2 §6, §18.3, §19.4) : la composition de la
// salle de l'enseignant, en logique pure.
//
// Participants a gauche, surface au centre, panneau pedagogique (Commandes,
// Supports, Bibliotheque) a droite seulement s'il est ouvert. Les colonnes se
// decident sur la largeur utile divisee par le facteur de texte
// (UX_REVIEW_CL-4 n. 20) : en dessous du seuil, le panneau devient
// temporaire (volet ou feuille par-dessus la surface), jamais une colonne
// qui comprime le texte. Le focus local replie les deux cotes. Rien n'est
// diffuse : ce sont des etats locaux d'interface (§18.1).

import 'package:flutter/foundation.dart';

import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import 'panneau_seance.dart';
import 'vue_seance.dart';

/// Ou se pose un panneau de la salle.
enum PlacePanneau {
  /// Pas de panneau de ce cote.
  aucune,

  /// Colonne a cote de la surface, sans la recouvrir.
  colonne,

  /// Volet ou feuille par-dessus la surface (largeur insuffisante).
  temporaire,
}

/// Les panneaux du cote droit : le panneau pedagogique et la Bibliotheque.
bool estPanneauDroit(PanneauOuvert panneau) =>
    panneau == PanneauOuvert.supports ||
    panneau == PanneauOuvert.ressources ||
    panneau == PanneauOuvert.commandes;

/// La composition de la salle de l'enseignant a une largeur donnee.
@immutable
class CompositionSalle {
  const CompositionSalle({required this.gauche, required this.droite});

  /// La largeur utile, divisee par le facteur de texte, a partir de laquelle
  /// une colonne se pose a cote de la surface (UX_REVIEW_CL-4 n. 20).
  static const double seuilColonne = AppGabarit.seuilEtendu;

  /// Ce que coute une colonne a la surface : sa largeur et son ecart.
  static const double coutColonne = largeurColonneSeance + AppSpacing.md;

  /// Les Participants (panneau Eleves, et le contexte deplie de la capsule).
  final PlacePanneau gauche;

  /// Le panneau pedagogique ouvert (Commandes, Supports, Bibliotheque).
  final PlacePanneau droite;

  /// La colonne des Participants tient-elle a cette largeur ? Jamais au
  /// telephone (un seul panneau secondaire, feuille du bas).
  static bool gaucheTient({
    required double largeur,
    required double facteurTexte,
    required bool telephone,
  }) => !telephone && largeur / facteurTexte >= seuilColonne;

  /// La composition, de l'etat local et de la largeur.
  ///
  /// - [panneau] : le panneau ouvert par l'enseignant (etat de la page) ;
  /// - [participantsReplies] : il a replie la colonne des Participants ;
  /// - [agrandi] : le focus local (Commandes > Focus) ;
  /// - [contexteOuvert] : le contexte deplie depuis la capsule, qui s'ouvre
  ///   dans le panneau des Participants (TB-3), meme en focus (§18.3 : « un
  ///   clic sur l'avatar ouvre le contexte sans ouvrir les outils ») ;
  /// - [participantsDisponibles] : la salle de l'enseignant a des Participants.
  static CompositionSalle pour({
    required double largeur,
    required double facteurTexte,
    required bool telephone,
    required PanneauOuvert panneau,
    required bool participantsReplies,
    required bool agrandi,
    required bool contexteOuvert,
    required bool participantsDisponibles,
  }) {
    final bool tient = gaucheTient(
      largeur: largeur,
      facteurTexte: facteurTexte,
      telephone: telephone,
    );
    final bool veutGauche =
        contexteOuvert ||
        (participantsDisponibles &&
            (panneau == PanneauOuvert.eleves ||
                (tient && !agrandi && !participantsReplies)));
    final PlacePanneau gauche = !veutGauche
        ? PlacePanneau.aucune
        : tient
        ? PlacePanneau.colonne
        : PlacePanneau.temporaire;
    final PlacePanneau droite;
    if (!estPanneauDroit(panneau)) {
      droite = PlacePanneau.aucune;
    } else if (telephone) {
      droite = PlacePanneau.temporaire;
    } else {
      // La surface garde au moins le seuil apres la colonne de gauche.
      final double besoin =
          seuilColonne + (gauche == PlacePanneau.colonne ? coutColonne : 0);
      droite = largeur / facteurTexte >= besoin
          ? PlacePanneau.colonne
          : PlacePanneau.temporaire;
    }
    return CompositionSalle(gauche: gauche, droite: droite);
  }

  /// Un panneau temporaire recouvre la surface : le bouton « Eleves » et le
  /// declencheur se retirent (le panneau les remplace, images CLV-07-08).
  bool get recouvre =>
      gauche == PlacePanneau.temporaire || droite == PlacePanneau.temporaire;

  @override
  bool operator ==(Object other) =>
      other is CompositionSalle &&
      other.gauche == gauche &&
      other.droite == droite;

  @override
  int get hashCode => Object.hash(gauche, droite);

  @override
  String toString() => 'CompositionSalle(gauche: $gauche, droite: $droite)';
}

/// Quitter le focus (UX-16, §18.1) : le panneau droit a rouvrir, ou a
/// fermer, pour retrouver la composition d'avant le focus.
///
/// Decide par delegation le 09/10 (K-65) : la composition d'avant ne revient
/// que si elle tient en colonnes a la largeur actuelle ; sinon on revient a
/// la surface, sans rouvrir de panneau temporaire par-dessus (les panneaux
/// restent a la demande, « panneaux temporaires sinon »).
///
/// Rend le panneau a basculer (le rappel de la page bascule : ouvrir l'un
/// ferme l'autre), ou `null` si rien ne change.
PanneauOuvert? panneauABasculerEnSortie({
  required PanneauOuvert avantFocus,
  required PanneauOuvert actuel,
  required bool droiteTient,
}) {
  final PanneauOuvert cible = droiteTient && estPanneauDroit(avantFocus)
      ? avantFocus
      : PanneauOuvert.aucun;
  final PanneauOuvert courant = estPanneauDroit(actuel)
      ? actuel
      : PanneauOuvert.aucun;
  if (cible == courant) return null;
  return cible != PanneauOuvert.aucun ? cible : courant;
}
