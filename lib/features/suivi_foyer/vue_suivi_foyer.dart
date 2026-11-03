import 'package:flutter/foundation.dart';

import '../../core/domain/enums.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/suivi/service_suivi.dart';

/// Ce qu'une ligne de suivi raconte du cours, **avant** de raconter quoi que ce
/// soit de l'enfant.
///
/// **Le sort du cours prime sur l'etat de la personne, et c'est la decision de
/// ce lot.** `etat_presence()` ne lit que les evenements de salle : un cours
/// annule, un cours ou l'enseignant ne s'est pas presente, un cours interrompu
/// par une panne n'ont produit aucun evenement, et la fonction en deduit donc
/// ce qu'elle doit en deduire -- « absente ». Affiche tel quel au tuteur, cela
/// dirait « votre enfant etait absent » d'un cours que l'academie n'a pas
/// donne. La donnee n'est pas fausse ; la phrase, elle, le serait.
enum SortDuCours {
  /// Le cours n'aura pas lieu, ou n'a pas eu lieu : annule, tot ou tard.
  annule,

  /// Le cours etait prevu et n'a pas ete donne : enseignant absent, ou panne.
  /// **Ce n'est pas le fait de l'enfant**, et sa presence ne se lit donc pas.
  nonTenu,

  /// Le cours a suivi son cours. C'est ici, et seulement ici, que l'etat de
  /// presence de l'enfant s'affiche.
  tenu,
}

/// Un enfant du foyer, tel que la barre de filtres le pose.
///
/// Les facettes se derivent **de la lecture**, comme celles de `CTR-01` : un
/// enfant qui n'a aucun cours dans la fenetre lue n'a pas de pilule, parce
/// qu'une pilule qui ne mene qu'a une liste vide est une impasse construite a
/// la main. L'ecran qui repond a « cet enfant n'a aucun cours » est `TUT-01`,
/// avec sa phase « en recherche d'un enseignant ».
@immutable
class FacetteEnfant {
  /// Cree une facette.
  const FacetteEnfant({
    required this.id,
    required this.prenom,
    required this.nombre,
  });

  /// L'identifiant de profil, celui que le filtre compare.
  final String id;

  /// Le prenom affiche.
  final String prenom;

  /// Combien de cours lui reviennent, filtre non applique.
  final int nombre;
}

/// Un cours dans l'historique du foyer.
@immutable
class LigneSuivi {
  /// Cree une ligne.
  const LigneSuivi({
    required this.seance,
    required this.sort,
    required this.presence,
  });

  /// Le cours, tel que `mes_seances_v` l'expose.
  final Seance seance;

  /// Ce que la ligne dit du cours lui-meme.
  final SortDuCours sort;

  /// L'etat de l'enfant sur ce cours.
  ///
  /// Toujours calcule, meme quand [sort] n'est pas [SortDuCours.tenu] : la vue
  /// ne decide pas de l'affichage, elle porte les deux faits et laisse l'ecran
  /// choisir celui qu'il montre. C'est ce qui permet de tester la regle sans
  /// monter d'ecran.
  final VuePresence presence;

  /// Vrai quand l'etat de l'enfant a sa place sur cette ligne.
  bool get montrePresence => sort == SortDuCours.tenu;
}

/// Le suivi du foyer, pret a afficher.
///
/// **Fonction pure**, comme `VuePlanning.depuis`, `VueSalle.depuis` et
/// `VuePresence.depuis` : l'ordre des lignes, le sort de chaque cours, le
/// rapprochement d'une presence a son cours et les facettes par enfant se
/// verifient sans monter d'ecran, sans reseau et sans base.
@immutable
class VueSuiviFoyer {
  /// Cree une vue.
  const VueSuiviFoyer({
    required this.lignes,
    required this.enfants,
    required this.total,
    required this.tronquee,
  });

  /// Les lignes retenues par le filtre, dans l'ordre d'affichage.
  final List<LigneSuivi> lignes;

  /// Les enfants presents dans la lecture, par prenom.
  final List<FacetteEnfant> enfants;

  /// Le nombre de cours lus, avant tout filtre.
  final int total;

  /// Vrai quand la lecture a bute sur son plafond.
  final bool tronquee;

  /// Vrai quand aucune ligne ne passe le filtre alors que la lecture n'etait
  /// pas vide : une impasse dont on sort, et non un foyer sans cours, qui est
  /// simplement un foyer qui attend le sien (`02-regles-ux.md` section 6).
  bool get impasseDeFiltre => lignes.isEmpty && total > 0;

  /// Construit la vue a partir de ce que la base a rendu.
  ///
  /// [presences] vaut `null` quand la lecture de la presence a echoue : toutes
  /// les lignes portent alors l'inconnu, **jamais l'absence** (invariant J3).
  /// L'historique reste lisible -- dates et enseignants viennent de l'autre
  /// lecture, qui a peut-etre reussi.
  static VueSuiviFoyer depuis({
    required List<Seance> seances,
    required List<PresenceParticipant>? presences,
    required DateTime maintenant,
    String? enfantId,
    int plafond = plafondSuiviFoyer,
  }) {
    // Une seule table de correspondance pour toute la liste : sans elle,
    // retrouver la presence d'un cours parmi deux cents lignes se paierait a
    // chaque ligne rendue, et un ecran qui defile rend ses lignes plusieurs
    // fois.
    final Map<String, PresenceParticipant> parCours =
        <String, PresenceParticipant>{};
    for (final PresenceParticipant ligne
        in presences ?? const <PresenceParticipant>[]) {
      parCours['${ligne.seanceId}|${ligne.profilId}'] = ligne;
    }

    final List<LigneSuivi> toutes = <LigneSuivi>[
      for (final Seance seance in seances)
        LigneSuivi(
          seance: seance,
          sort: sortDe(seance),
          presence: VuePresence.depuis(
            ligne: parCours['${seance.id}|${seance.eleveId}'],
            maintenant: maintenant,
          ),
        ),
    ]..sort(_ordre);

    final Map<String, FacetteEnfant> facettes = <String, FacetteEnfant>{};
    for (final LigneSuivi ligne in toutes) {
      final String id = ligne.seance.eleveId;
      facettes[id] = FacetteEnfant(
        id: id,
        prenom: ligne.seance.elevePrenom,
        nombre: (facettes[id]?.nombre ?? 0) + 1,
      );
    }

    final List<FacetteEnfant> tries = facettes.values.toList()
      ..sort((FacetteEnfant a, FacetteEnfant b) {
        final int parPrenom = a.prenom.compareTo(b.prenom);
        // L'identifiant departage : deux enfants d'un meme foyer peuvent
        // partager un prenom, et une liste qui changerait d'ordre d'une lecture
        // a l'autre est illisible.
        return parPrenom != 0 ? parPrenom : a.id.compareTo(b.id);
      });

    return VueSuiviFoyer(
      lignes: <LigneSuivi>[
        for (final LigneSuivi ligne in toutes)
          if (enfantId == null || ligne.seance.eleveId == enfantId) ligne,
      ],
      enfants: tries,
      total: toutes.length,
      // `>=` et non `==` : une lecture qui rendrait plus que le plafond est
      // tronquee elle aussi, et le pied de liste doit le dire quand meme.
      tronquee: seances.length >= plafond,
    );
  }

  /// Ce que le statut d'une seance dit de son sort.
  ///
  /// **Un statut illisible vaut `tenu`**, et non « non tenu » : `depuisSql`
  /// rend `null` quand la base emet une valeur que cette version ne connait
  /// pas, et se replier sur « le cours n'a pas eu lieu » inventerait un
  /// incident a partir d'une simple ignorance. L'etat de presence, lui, sait
  /// deja dire qu'il ne sait pas.
  @visibleForTesting
  static SortDuCours sortDe(Seance seance) {
    final StatutSeance? statut = seance.statut;
    if (statut?.estAnnulee ?? false) {
      return SortDuCours.annule;
    }
    if (statut == StatutSeance.enseignantAbsent ||
        statut == StatutSeance.incidentTechnique) {
      return SortDuCours.nonTenu;
    }
    return SortDuCours.tenu;
  }

  /// Le plus recent d'abord, et **rien d'autre**.
  ///
  /// L'ordre ne depend jamais de l'etat : un tri qui ferait remonter les
  /// absences mettrait les lignes en mouvement d'une lecture a l'autre, et un
  /// parent qui revient sur l'ecran ne retrouverait pas ce qu'il y avait laisse.
  /// Le cours a venir le plus proche se trouve donc en tete par construction,
  /// sans bloc dedie.
  static int _ordre(LigneSuivi a, LigneSuivi b) {
    final int parDebut = b.seance.debut.compareTo(a.seance.debut);
    // L'identifiant departage deux cours de la meme heure -- une fratrie en a
    // tres exactement autant que d'enfants.
    return parDebut != 0 ? parDebut : a.seance.id.compareTo(b.seance.id);
  }
}
