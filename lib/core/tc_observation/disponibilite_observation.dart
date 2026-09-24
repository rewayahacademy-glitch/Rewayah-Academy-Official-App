import 'package:flutter/foundation.dart';

import '../presence/service_presence.dart';
import '../seance_famille/seance_famille.dart';
import 'echec_observation.dart';
import 'guardian_observation_policy.dart';
import 'port_politique_observation.dart';
import 'vue_budget_observation.dart';

/// Pourquoi l'observation d'une seance n'est pas proposee maintenant.
///
/// Chaque motif se dit en clair a la famille (texte du lot Observation, en
/// i18n). Aucun n'est un code technique a l'ecran.
enum MotifIndisponibilite {
  /// Les visites de la seance sont toutes utilisees.
  visitesEpuisees,

  /// Le temps d'observation de la seance est consomme.
  tempsEpuise,

  /// La seance n'a pas encore commence.
  seanceNonCommencee,

  /// La seance est terminee.
  seanceTerminee,

  /// La seance n'a pas lieu : annulee, reportee ou non tenue. Ajout au
  /// contrat K4 : « terminee » serait faux pour une seance qui n'a jamais eu
  /// lieu.
  seanceNonTenue,

  /// Le serveur refuse l'entree a cette heure (`hors_fenetre`,
  /// `seance_non_active`), sans dire si c'est trop tot ou trop tard. Ajout au
  /// contrat K4 : le client ne devine pas lequel des deux.
  horsFenetre,

  /// L'administration a ferme l'observation pour cette classe.
  observationDesactivee,

  /// Aucun enfant du foyer n'est lie a cette seance.
  lienAbsent,

  /// **Reserve** : produit seulement quand le serveur saura le dire
  /// (DB-OBS-05). Jamais deduit d'une presence lue cote client.
  enfantAbsent,

  /// La presence de l'enfant n'est pas confirmee. Indicatif : lu sur
  /// `presence_seance_v`, jamais une garantie.
  presenceEnVerification,

  /// Une visite de cet observateur est deja ouverte (DB-OBS-06).
  visiteDejaOuverte,

  /// L'observation reelle est coupee tant que le serveur ne la garantit pas
  /// (point P3 : interrupteur `OBSERVATION_TUTEUR_REELLE`).
  garantieServeurAbsente,

  /// Le reseau n'a pas repondu. Seul motif qui se reessaye.
  reseau,

  /// La capacite serveur manque, ou le budget n'a pas pu etre lu.
  capaciteAbsente,
}

/// Ce que l'ecran peut proposer pour observer une seance (contrat K4).
sealed class DisponibiliteObservation {
  const DisponibiliteObservation();
}

/// Une visite peut commencer.
final class ObservationPossible extends DisponibiliteObservation {
  /// Cree la disponibilite.
  const ObservationPossible({
    required this.visitesUtilisees,
    required this.visitesMax,
    required this.dureeProchaineVisite,
    required this.policyVersion,
  });

  /// Visites deja consommees par cet observateur sur cette seance.
  final int visitesUtilisees;

  /// Visites autorisees par la politique effective.
  final int visitesMax;

  /// Duree de la prochaine visite : le `restant` du budget serveur, deja
  /// borne par le plafond par visite. Jamais recalculee ici.
  final Duration dureeProchaineVisite;

  /// La version de politique qui s'applique.
  final String policyVersion;

  /// Visites encore disponibles, jamais negatives.
  int get visitesRestantes {
    final int reste = visitesMax - visitesUtilisees;
    return reste < 0 ? 0 : reste;
  }
}

/// Aucune visite ne peut commencer maintenant.
final class ObservationIndisponible extends DisponibiliteObservation {
  /// Cree l'indisponibilite.
  const ObservationIndisponible(this.motif, {this.visitesRestantes});

  /// Pourquoi.
  final MotifIndisponibilite motif;

  /// Visites restantes quand le budget est connu, pour le dire quand meme.
  final int? visitesRestantes;
}

/// Ce que la famille peut faire maintenant, a partir de ce que le serveur
/// rend.
///
/// **Pure.** [activationReelle] vient de `Env.observationTuteurReelleActive` :
/// faux, rien ne s'ouvre (motif [MotifIndisponibilite.garantieServeurAbsente]).
/// [budget] est `budget_observation()` (lecture sans effet, aucun intervalle
/// ouvert) ; `null` : le budget n'a pas ete lu, rien n'est propose.
/// [politique] est facultative (elle exige le `groupe_id` de la seance) : sa
/// fermeture prime quand elle est connue. [presenceEnfant] est indicative.
/// [etatSeance] (contrat K2) ecarte une seance a venir, close ou qui n'a pas
/// lieu ; un horaire incertain ne bloque rien, le serveur decide a l'entree.
///
/// Ordre des raisons : activation, seance, budget lisible, politique, visite
/// deja ouverte, refus du budget, presence. La premiere qui s'applique est
/// rendue.
DisponibiliteObservation disponibiliteObservation({
  required BudgetObservation? budget,
  required GuardianObservationPolicy? politique,
  required EtatPresence? presenceEnfant,
  required bool activationReelle,
  EtatSeanceFamille? etatSeance,
}) {
  final int? restantes = budget == null ? null : _visitesRestantes(budget);

  if (!activationReelle) {
    return ObservationIndisponible(
      MotifIndisponibilite.garantieServeurAbsente,
      visitesRestantes: restantes,
    );
  }

  final MotifIndisponibilite? parSeance = switch (etatSeance) {
    EtatSeanceFamille.aVenir => MotifIndisponibilite.seanceNonCommencee,
    EtatSeanceFamille.terminee => MotifIndisponibilite.seanceTerminee,
    EtatSeanceFamille.annulee ||
    EtatSeanceFamille.annuleeTardive ||
    EtatSeanceFamille.nonTenue ||
    EtatSeanceFamille.reportee => MotifIndisponibilite.seanceNonTenue,
    EtatSeanceFamille.salleOuverte ||
    EtatSeanceFamille.enDirect ||
    EtatSeanceFamille.prolongee ||
    EtatSeanceFamille.horaireIncertain ||
    null => null,
  };
  if (parSeance != null) {
    return ObservationIndisponible(parSeance, visitesRestantes: restantes);
  }

  if (budget == null) {
    return const ObservationIndisponible(MotifIndisponibilite.capaciteAbsente);
  }
  if (politique != null && !politique.observationPossible) {
    return ObservationIndisponible(
      MotifIndisponibilite.observationDesactivee,
      visitesRestantes: restantes,
    );
  }
  if (budget.visiteEnCours) {
    return ObservationIndisponible(
      MotifIndisponibilite.visiteDejaOuverte,
      visitesRestantes: restantes,
    );
  }
  if (!budget.peutEntrer) {
    return ObservationIndisponible(
      motifDepuisRefus(budget.motifRefus),
      visitesRestantes: restantes,
    );
  }
  if (!_presenceConfirmee(presenceEnfant)) {
    return ObservationIndisponible(
      MotifIndisponibilite.presenceEnVerification,
      visitesRestantes: restantes,
    );
  }
  return ObservationPossible(
    visitesUtilisees: budget.visitesUtilisees,
    visitesMax: budget.visitesMax,
    dureeProchaineVisite: budget.restant,
    policyVersion: budget.policyVersion,
  );
}

int _visitesRestantes(BudgetObservation budget) {
  final int reste = budget.visitesMax - budget.visitesUtilisees;
  return reste < 0 ? 0 : reste;
}

/// Vrai quand la presence lue dit l'enfant dans la salle. Tout le reste,
/// inconnu compris, est « en verification », jamais « absent ».
bool _presenceConfirmee(EtatPresence? presence) => switch (presence) {
  EtatPresence.presente ||
  EtatPresence.enRetard ||
  EtatPresence.reconnectee => true,
  _ => false,
};

/// Le motif d'indisponibilite d'un refus serveur (budget ou entree).
///
/// Un motif inconnu (`null`) ne se devine pas : [MotifIndisponibilite.capaciteAbsente].
MotifIndisponibilite motifDepuisRefus(MotifRefusObservation? refus) =>
    switch (refus) {
      MotifRefusObservation.policyDesactivee =>
        MotifIndisponibilite.observationDesactivee,
      MotifRefusObservation.quotaVisitesAtteint =>
        MotifIndisponibilite.visitesEpuisees,
      MotifRefusObservation.tempsEpuise => MotifIndisponibilite.tempsEpuise,
      MotifRefusObservation.lienTuteurAbsent => MotifIndisponibilite.lienAbsent,
      MotifRefusObservation.seanceNonActive ||
      MotifRefusObservation.horsFenetre => MotifIndisponibilite.horsFenetre,
      null => MotifIndisponibilite.capaciteAbsente,
    };

/// Le motif d'indisponibilite d'un echec de lecture ou d'entree.
MotifIndisponibilite motifDepuisEchec(EchecObservation echec) =>
    switch (echec.motif) {
      MotifEchecObservation.reseau => MotifIndisponibilite.reseau,
      MotifEchecObservation.visiteDejaOuverte =>
        MotifIndisponibilite.visiteDejaOuverte,
      MotifEchecObservation.capaciteAbsente ||
      MotifEchecObservation.reponseIllisible =>
        MotifIndisponibilite.capaciteAbsente,
    };

/// Le compteur « Visite 1/2 · 01:42 » d'une visite en cours.
///
/// Le rang est `visitesUtilisees` (la visite en cours est deja comptee par le
/// serveur, `0039`) ; le temps est le dernier restant serveur, decompte
/// localement sans jamais etre allonge (`VueBudgetObservation`).
@immutable
class CompteurVisite {
  /// Cree un compteur.
  const CompteurVisite({
    required this.rang,
    required this.total,
    required this.restant,
    required this.confirmeParServeur,
  });

  /// Le compteur d'une vue de budget, a l'affichage.
  ///
  /// [confirmeParServeur] faux quand la derniere relecture du budget a echoue :
  /// l'ecran dit alors « Temps restant non confirme ».
  factory CompteurVisite.depuis(
    VueBudgetObservation vue, {
    required bool confirmeParServeur,
  }) => CompteurVisite(
    rang: vue.rangVisite,
    total: vue.visitesMax,
    restant: vue.restantAffiche,
    confirmeParServeur: confirmeParServeur,
  );

  /// Rang de la visite en cours, a partir de 1.
  final int rang;

  /// Visites autorisees sur la seance.
  final int total;

  /// Temps restant affiche, jamais negatif.
  final Duration restant;

  /// Faux : « Temps restant non confirme ».
  final bool confirmeParServeur;
}
