/// DASH-ADM-PLANNING : la mise en mots du planning de la direction et des
/// incidents. Fonctions pures : l'ecran ne decide rien, il dit ce que le port
/// rend.
library;

import '../../core/admin/port_planning_direction.dart';
import '../../core/admin/port_remplacements_direction.dart';
import '../../core/domain/enums.dart' show StatutSeance;
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/pastille_etat_seance.dart' show EtatPastilleSeance;
import '../admin_regroupements/regroupements_libelles.dart'
    show libelleHeureMinute;
import '../suivi_foyer/filtres_historique.dart' show dateLongueHistorique;

/// « 18 h » ou « 18 h 30 » : l'heure d'un instant local.
String libelleHeure(DateTime instant) =>
    libelleHeureMinute(instant.hour, instant.minute);

/// « lundi 12 octobre 2026 » : le jour d'un instant local.
String libelleJour(DateTime instant) => dateLongueHistorique(instant);

/// « 18 h à 18 h 45 » : le debut et la fin d'une seance.
String libelleHorairePlanning(SeancePlanning s) => t.admin.planning.horaire(
  debut: libelleHeure(s.debut),
  fin: libelleHeure(s.fin),
);

/// « Semaine du lundi 12 octobre 2026 ».
String libelleSemaine(DateTime lundi) =>
    t.admin.planning.semaine(date: libelleJour(lundi));

/// La ligne qui nomme l'enseignant, ou dit qu'il manque.
String libelleEnseignantPlanning(String? nom) => nom == null || nom.isEmpty
    ? t.admin.planning.sansEnseignant
    : t.admin.planning.avecEnseignant(nom: nom);

/// La ligne qui dit le remplacement d'une seance, ou `null` sans evenement.
String? libelleRemplacementSeance(RemplacementSeanceDirection? r) =>
    switch (r) {
      null => null,
      RemplacementSeanceDirection(
        etat: EtatRemplacementSeance.absenceDeclaree,
      ) =>
        t.admin.planning.remplacement.absenceSansRemplacant,
      RemplacementSeanceDirection(
        :final String? remplacant,
        :final bool horsGenre,
      ) =>
        horsGenre
            ? t.admin.planning.remplacement.remplaceParHorsGenre(
                nom: remplacant ?? '',
              )
            : t.admin.planning.remplacement.remplacePar(nom: remplacant ?? ''),
    };

/// L'etat d'une seance, quand il merite la pastille d'etat de seance
/// (en direct, annulee), sinon `null`.
EtatPastilleSeance? pastilleDe(StatutSeance statut) => switch (statut) {
  StatutSeance.enCours => EtatPastilleSeance.enDirect,
  StatutSeance.annulee ||
  StatutSeance.annuleeTard => EtatPastilleSeance.annulee,
  _ => null,
};

/// Le mot du statut d'une seance du planning.
String libelleStatutPlanning(StatutSeance statut) => switch (statut) {
  StatutSeance.planifiee => t.admin.planning.statutPrevue,
  StatutSeance.preflight => t.admin.planning.statutPreparation,
  StatutSeance.enCours => t.etat.enDirect,
  StatutSeance.terminee => t.admin.planning.statutTerminee,
  StatutSeance.incidentTechnique => t.admin.planning.statutIncident,
  StatutSeance.enseignantAbsent => t.admin.planning.statutEnseignantAbsent,
  StatutSeance.eleveAbsent => t.admin.planning.statutEleveAbsent,
  StatutSeance.annulee || StatutSeance.annuleeTard => t.etat.seanceAnnulee,
};

/// Les seances de la semaine regroupees par jour (minuit local), dans
/// l'ordre des jours puis des heures.
Map<DateTime, List<SeancePlanning>> parJour(List<SeancePlanning> seances) {
  final List<SeancePlanning> triees = <SeancePlanning>[...seances]
    ..sort((SeancePlanning a, SeancePlanning b) => a.debut.compareTo(b.debut));
  final Map<DateTime, List<SeancePlanning>> jours =
      <DateTime, List<SeancePlanning>>{};
  for (final SeancePlanning s in triees) {
    final DateTime jour = DateTime(s.debut.year, s.debut.month, s.debut.day);
    (jours[jour] ??= <SeancePlanning>[]).add(s);
  }
  return jours;
}
