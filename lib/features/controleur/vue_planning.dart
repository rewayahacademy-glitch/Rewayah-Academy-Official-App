import 'package:flutter/foundation.dart';

import '../../core/controle/service_controle.dart';
import '../../core/domain/enums.dart';
import '../../core/planning/service_planning.dart';

/// Ce qu'une ligne du planning global dit de sa seance.
///
/// Trois etats, et non les neuf de `StatutSeance` : le controle qualite ne
/// consulte pas une machine a etats, il repond a une question, celle de
/// `02-regles-ux.md` pour cet ecran -- « qu'est-ce qui necessite une
/// verification ? ». Ce qui a lieu maintenant, ce qui a mal tourne, ce qui
/// arrive ensuite : dans cet ordre.
enum EtatLignePlanning {
  /// Elle a lieu en ce moment. **La seule ou l'on entre.**
  enCours,

  /// Elle n'a pas encore commence.
  aVenir,

  /// Elle n'a pas eu lieu comme prevu : absence, panne technique, annulation,
  /// ou fenetre passee sans cloture.
  incident,
}

/// Le filtre d'etat, tel que la barre de pilules le pose.
///
/// Quatre valeurs et non trois : « tous » est un etat du filtre, pas l'absence
/// de filtre -- c'est lui qui est retenu au premier affichage.
enum FiltrePlanning {
  /// Aucun filtre.
  tous,

  /// Ce qui se passe maintenant.
  enCours,

  /// Ce qui arrive.
  aVenir,

  /// Ce qui a mal tourne.
  incident;

  /// Vrai quand [etat] passe ce filtre.
  bool retient(EtatLignePlanning etat) => switch (this) {
    FiltrePlanning.tous => true,
    FiltrePlanning.enCours => etat == EtatLignePlanning.enCours,
    FiltrePlanning.aVenir => etat == EtatLignePlanning.aVenir,
    FiltrePlanning.incident => etat == EtatLignePlanning.incident,
  };
}

/// Une ligne du planning global.
@immutable
class LignePlanning {
  /// Cree une ligne.
  const LignePlanning({required this.seance, required this.etat});

  /// La seance, telle que `mes_seances_v` l'expose.
  final Seance seance;

  /// Ce que la ligne dit de sa seance.
  final EtatLignePlanning etat;

  /// Vrai quand la ligne porte un bouton d'entree invisible.
  ///
  /// Un incident n'est pas observable : il n'y a rien a observer d'un cours que
  /// l'enseignant n'a pas donne. La base, elle, accepterait -- elle ne refuse
  /// que les seances closes, exactement comme `autoriser_jeton_video()`.
  /// L'ecran est donc plus strict que la porte, comme `ENS-02` l'est deja avec
  /// son seuil de dix minutes : ne pas proposer un geste sans objet.
  bool get observable => etat == EtatLignePlanning.enCours;
}

/// Un enseignant du planning, et le nombre de ses seances.
///
/// Prenom et identifiant immuable, jamais le nom de famille (ADR-008) : un
/// planning de controle n'est pas un annuaire du personnel.
@immutable
class FacetteEnseignant {
  /// Cree une facette.
  const FacetteEnseignant({
    required this.id,
    required this.prenom,
    required this.identifiant,
    required this.nombre,
  });

  /// L'identifiant de profil, celui que le filtre compare.
  final String id;

  /// Le prenom affiche.
  final String prenom;

  /// L'identifiant immuable, qui distingue deux Karim.
  final String identifiant;

  /// Combien de seances lui reviennent, filtres non appliques.
  final int nombre;
}

/// Le planning global, pret a afficher.
///
/// **Fonction pure**, comme `VueSalle.depuis` et `VuePresence.depuis` : l'ordre
/// des lignes, les trois etats, les facettes d'enseignant et la troncature se
/// verifient sans monter d'ecran, sans reseau et sans base.
@immutable
class VuePlanning {
  /// Cree une vue.
  const VuePlanning({
    required this.lignes,
    required this.enseignants,
    required this.total,
    required this.nombreEnCours,
    required this.nombreAVenir,
    required this.nombreIncident,
    required this.tronquee,
  });

  /// Les lignes retenues par les filtres, dans l'ordre d'affichage.
  final List<LignePlanning> lignes;

  /// Les enseignants presents dans la lecture, par prenom.
  final List<FacetteEnseignant> enseignants;

  /// Le nombre de seances lues, avant tout filtre.
  final int total;

  /// Combien de seances ont lieu en ce moment, avant tout filtre.
  final int nombreEnCours;

  /// Combien arrivent, avant tout filtre.
  final int nombreAVenir;

  /// Combien ont mal tourne, avant tout filtre.
  final int nombreIncident;

  /// Vrai quand la lecture a bute sur son plafond : il existe des seances de
  /// plus, et l'ecran doit le dire plutot que de laisser croire a une liste
  /// complete.
  final bool tronquee;

  /// Vrai quand aucune ligne ne passe les filtres alors que la lecture n'etait
  /// pas vide : une impasse de filtre, dont on peut sortir, et non un planning
  /// vide, qui est une bonne nouvelle (`02-regles-ux.md` section 6).
  bool get impasseDeFiltre => lignes.isEmpty && total > 0;

  /// Construit la vue a partir de ce que la base a rendu.
  static VuePlanning depuis({
    required List<Seance> seances,
    required DateTime maintenant,
    String? enseignantId,
    FiltrePlanning filtre = FiltrePlanning.tous,
    int plafond = plafondPlanningGlobal,
  }) {
    final List<LignePlanning> toutes = <LignePlanning>[
      for (final Seance seance in seances)
        LignePlanning(seance: seance, etat: etatDe(seance, maintenant)),
    ]..sort(_ordre);

    final Map<String, FacetteEnseignant> facettes =
        <String, FacetteEnseignant>{};
    int enCours = 0;
    int aVenir = 0;
    int incident = 0;
    for (final LignePlanning ligne in toutes) {
      switch (ligne.etat) {
        case EtatLignePlanning.enCours:
          enCours++;
        case EtatLignePlanning.aVenir:
          aVenir++;
        case EtatLignePlanning.incident:
          incident++;
      }
      final String id = ligne.seance.enseignantId;
      final FacetteEnseignant? connue = facettes[id];
      facettes[id] = FacetteEnseignant(
        id: id,
        prenom: ligne.seance.enseignantPrenom,
        identifiant: ligne.seance.enseignantIdentifiant,
        nombre: (connue?.nombre ?? 0) + 1,
      );
    }

    final List<FacetteEnseignant> tries = facettes.values.toList()
      ..sort((FacetteEnseignant a, FacetteEnseignant b) {
        final int parPrenom = a.prenom.compareTo(b.prenom);
        return parPrenom != 0
            ? parPrenom
            : a.identifiant.compareTo(b.identifiant);
      });

    return VuePlanning(
      lignes: <LignePlanning>[
        for (final LignePlanning ligne in toutes)
          if ((enseignantId == null ||
                  ligne.seance.enseignantId == enseignantId) &&
              filtre.retient(ligne.etat))
            ligne,
      ],
      enseignants: tries,
      total: toutes.length,
      nombreEnCours: enCours,
      nombreAVenir: aVenir,
      nombreIncident: incident,
      // `>=` et non `==` : une lecture qui rendrait plus que le plafond est
      // tronquee elle aussi, et le pied de page doit le dire quand meme.
      tronquee: seances.length >= plafond,
    );
  }

  /// L'etat d'une seance a un instant donne.
  ///
  /// **Il ne se lit pas dans `status`**, et c'est la decision de ce lot : rien
  /// dans le produit ne fait passer une seance a `in_progress` -- le webhook
  /// LiveKit ecrit des evenements, pas un statut. Un ecran qui attendrait
  /// `in_progress` pour dire « en cours » n'afficherait jamais un seul cours en
  /// direct. Le statut sert donc a ce qu'il sait : dire qu'une seance a mal
  /// tourne.
  @visibleForTesting
  static EtatLignePlanning etatDe(Seance seance, DateTime maintenant) {
    final StatutSeance? statut = seance.statut;
    if (statut == StatutSeance.enseignantAbsent ||
        statut == StatutSeance.eleveAbsent ||
        statut == StatutSeance.incidentTechnique ||
        (statut?.estAnnulee ?? false)) {
      return EtatLignePlanning.incident;
    }
    if (maintenant.isBefore(seance.debut)) {
      return EtatLignePlanning.aVenir;
    }
    if (!maintenant.isAfter(seance.fin.add(graceApresFin))) {
      return EtatLignePlanning.enCours;
    }
    // Passe la fenetre sans avoir ete close, ni terminee, ni annulee : personne
    // n'a ferme ce cours. C'est exactement ce qui necessite une verification.
    return EtatLignePlanning.incident;
  }

  /// Ce qui se passe maintenant, puis ce qui a mal tourne, puis ce qui arrive.
  static int _ordre(LignePlanning a, LignePlanning b) {
    final int parEtat = _rang(a.etat).compareTo(_rang(b.etat));
    if (parEtat != 0) {
      return parEtat;
    }
    final int parDebut = a.seance.debut.compareTo(b.seance.debut);
    // L'identifiant departage : sans lui, deux seances de la meme heure
    // pourraient changer de place d'une lecture a l'autre, et une liste qui
    // bouge toute seule est illisible.
    return parDebut != 0 ? parDebut : a.seance.id.compareTo(b.seance.id);
  }

  static int _rang(EtatLignePlanning etat) => switch (etat) {
    EtatLignePlanning.enCours => 0,
    EtatLignePlanning.incident => 1,
    EtatLignePlanning.aVenir => 2,
  };
}
