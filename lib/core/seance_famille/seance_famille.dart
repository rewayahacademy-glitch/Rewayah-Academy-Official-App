import 'package:flutter/foundation.dart';

import '../domain/enums.dart';
import '../tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../tc_horloge/session_clock_vm.dart';

/// L'etat affichable d'une seance pour une famille.
///
/// **Le statut serveur prime sur l'horloge** : une seance annulee ne montre
/// jamais de compte a rebours, meme si l'heure dit qu'elle devrait commencer.
/// **Sans horloge serveur, aucun etat d'ouverture n'est affirme** :
/// [horaireIncertain] remplace « Salle ouverte » et « En direct ».
enum EtatSeanceFamille {
  /// Avant l'ouverture de la salle.
  aVenir,

  /// Salle ouverte, avant le debut (fenetre rendue par `join_opens_at_utc`).
  salleOuverte,

  /// Du debut a la fin prevue.
  enDirect,

  /// Apres la fin prevue, seance encore ouverte : **jamais de compte a
  /// rebours**, et jamais le libelle « Cours en cours ».
  prolongee,

  /// Seance tenue et close.
  terminee,

  /// Annulee.
  annulee,

  /// Annulee tardivement.
  annuleeTardive,

  /// Non tenue : enseignant absent, eleve absent, incident technique.
  nonTenue,

  /// **Reserve** : jamais produit tant que le serveur ne rend pas de report
  /// trace (dependance DB-CRS-05). Un changement d'enseignant ou d'heure ne se
  /// deduit pas cote client.
  reportee,

  /// Aucune horloge serveur pour cette seance (seance hors groupe, refus,
  /// panne, capacite absente) : l'heure affichee est celle de l'appareil,
  /// libellee comme telle, et aucun etat d'ouverture n'est affirme.
  horaireIncertain,
}

/// L'enseignant d'une occurrence, tel que la famille le voit.
@immutable
class EnseignantSeance {
  /// Cree l'enseignant d'une seance.
  const EnseignantSeance({required this.prenom, this.titre, this.clePhoto});

  /// Prenom, jamais le nom de famille (ADR-008).
  final String prenom;

  /// Sayyid ou Sayyida. `null` : aucun titre affiche, **jamais devine**.
  final TitreEnseignant? titre;

  /// Cle de stockage de la photo, jamais une URL signee. `null` : initiales.
  final String? clePhoto;

  @override
  bool operator ==(Object other) =>
      other is EnseignantSeance &&
      other.prenom == prenom &&
      other.titre == titre &&
      other.clePhoto == clePhoto;

  @override
  int get hashCode => Object.hash(prenom, titre, clePhoto);
}

/// Une seance vue par la famille, pour **un** eleve.
///
/// `mes_seances_v` rend une ligne par couple (seance, eleve) : deux enfants
/// d'un meme foyer dans une meme seance font deux `SeanceFamille`, chacune
/// avec son [eleveId]. Tous les instants sont en UTC.
@immutable
class SeanceFamille {
  /// Cree une seance.
  const SeanceFamille({
    required this.seanceId,
    required this.eleveId,
    required this.debutUtc,
    required this.finPrevueUtc,
    required this.enseignant,
    this.groupeId,
    this.statutServeur,
    this.fenetre,
    this.heureFoyer,
    this.heureGroupe,
    this.minutesInterruption = 0,
  });

  /// Identifiant de la seance.
  final String seanceId;

  /// L'eleve concerne.
  final String eleveId;

  /// La classe de la seance. `null` : inconnue, `mes_seances_v` ne porte pas
  /// `groupe_id` (dependance DB-CRS-13), ou seance hors groupe.
  final String? groupeId;

  /// Debut prevu, en UTC.
  final DateTime debutUtc;

  /// Fin prevue, en UTC.
  final DateTime finPrevueUtc;

  /// `mes_seances_v.status`. **Prime sur l'horloge**, qui ne le connait pas.
  /// `null` quand il est illisible.
  final StatutSeance? statutServeur;

  /// La fenetre rendue par `horloge_seance()` (`join_opens_at_utc`). `null`
  /// sans horloge serveur : l'etat est alors [EtatSeanceFamille.horaireIncertain].
  final FenetreSeance? fenetre;

  /// L'heure dans le fuseau du foyer, **rendue par le serveur**. `null` sans
  /// horloge : l'ecran affiche alors l'heure de l'appareil, libellee « heure
  /// de cet appareil ».
  final HorlogeAffichee? heureFoyer;

  /// L'heure dans le fuseau de la classe, `null` quand elle est identique a
  /// [heureFoyer] ou inconnue. Affichee en second seulement.
  final HorlogeAffichee? heureGroupe;

  /// L'enseignant de l'occurrence.
  final EnseignantSeance enseignant;

  /// Minutes d'interruption consignees, prieres comprises (ADR-017).
  final int minutesInterruption;

  /// La duree prevue.
  Duration get dureePrevue => finPrevueUtc.difference(debutUtc);
}

/// L'etat affichable de [seance] a l'instant serveur donne.
///
/// **Pure, sans horloge d'appareil.** [maintenantServeurUtc] vient de
/// `maintenant_serveur()` ; `null` dit qu'aucune horloge serveur n'est
/// disponible, et l'etat devient [EtatSeanceFamille.horaireIncertain] des que
/// le statut serveur ne tranche pas a lui seul.
///
/// [seanceOuverteServeur] est l'ouverture declaree par le serveur quand il la
/// rend ; a defaut, un statut `in_progress` vaut ouverture, et sinon la grace
/// rendue par la fenetre tranche.
EtatSeanceFamille etatSeanceFamille(
  SeanceFamille seance, {
  required DateTime? maintenantServeurUtc,
  bool? seanceOuverteServeur,
}) {
  final StatutSeance? statut = seance.statutServeur;
  switch (statut) {
    case StatutSeance.annulee:
      return EtatSeanceFamille.annulee;
    case StatutSeance.annuleeTard:
      return EtatSeanceFamille.annuleeTardive;
    case StatutSeance.enseignantAbsent ||
        StatutSeance.eleveAbsent ||
        StatutSeance.incidentTechnique:
      return EtatSeanceFamille.nonTenue;
    case StatutSeance.terminee:
      return EtatSeanceFamille.terminee;
    case StatutSeance.planifiee ||
        StatutSeance.preflight ||
        StatutSeance.enCours ||
        null:
      break;
  }

  final FenetreSeance? fenetre = seance.fenetre;
  final DateTime? maintenant = maintenantServeurUtc?.toUtc();
  if (fenetre == null || maintenant == null) {
    return EtatSeanceFamille.horaireIncertain;
  }

  final bool enCoursSelonServeur = statut == StatutSeance.enCours;
  final PhaseSeance phase = fenetre.phaseA(
    maintenant,
    seanceOuverte: seanceOuverteServeur ?? (enCoursSelonServeur ? true : null),
  );
  return switch (phase) {
    // Une seance que le serveur declare commencee a une salle ouverte, meme
    // si l'enseignant l'a ouverte avant la fenetre.
    PhaseSeance.avantFenetre =>
      enCoursSelonServeur
          ? EtatSeanceFamille.salleOuverte
          : EtatSeanceFamille.aVenir,
    PhaseSeance.salleOuverte ||
    PhaseSeance.attenteAvantT0 => EtatSeanceFamille.salleOuverte,
    PhaseSeance.enCours => EtatSeanceFamille.enDirect,
    PhaseSeance.prolongee => EtatSeanceFamille.prolongee,
    PhaseSeance.terminee => EtatSeanceFamille.terminee,
  };
}

/// Le temps avant le debut, pour « Cours dans 3 h 28 ».
///
/// Rendu seulement quand la seance est a venir ou sa salle ouverte ; `null`
/// sinon (en direct, prolongee, close, annulee, non tenue, horaire incertain).
/// **Jamais negatif.** Pure, sans horloge d'appareil.
Duration? restantAvant(
  SeanceFamille seance, {
  required DateTime? maintenantServeurUtc,
}) {
  final DateTime? maintenant = maintenantServeurUtc?.toUtc();
  if (maintenant == null) {
    return null;
  }
  final EtatSeanceFamille etat = etatSeanceFamille(
    seance,
    maintenantServeurUtc: maintenant,
  );
  if (etat != EtatSeanceFamille.aVenir &&
      etat != EtatSeanceFamille.salleOuverte) {
    return null;
  }
  final Duration reste = seance.debutUtc.difference(maintenant);
  return reste.isNegative ? Duration.zero : reste;
}
