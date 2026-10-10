import 'package:flutter/foundation.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/status_pill.dart';
import 'vue_suivi_foyer.dart';

// L'Historique du tuteur (lot E, chantier Tuteur V1) : filtres, statuts et
// mises en forme, en fonctions pures. Les deux segments (Seances,
// Observations) et les deux details les partagent : une date, une duree ou
// un statut s'ecrivent d'une seule facon dans tout l'Historique.

/// La periode retenue par le filtre « Periode ».
enum PeriodeHistorique {
  /// Aucune borne.
  toute,

  /// Les sept derniers jours civils.
  septJours,

  /// Les trente derniers jours civils.
  trenteJours,

  /// Les trois derniers mois civils.
  troisMois;

  /// Le premier instant retenu, ou `null` pour [toute].
  ///
  /// En composantes de date, jamais par soustraction d'heures : la nuit du
  /// changement d'heure n'a pas vingt-quatre heures.
  DateTime? debut(DateTime maintenant) => switch (this) {
    PeriodeHistorique.toute => null,
    PeriodeHistorique.septJours => DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day - 7,
    ),
    PeriodeHistorique.trenteJours => DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day - 30,
    ),
    PeriodeHistorique.troisMois => DateTime(
      maintenant.year,
      maintenant.month - 3,
      maintenant.day,
    ),
  };

  /// Vrai quand [instant] entre dans la periode.
  bool contient(DateTime instant, DateTime maintenant) {
    final DateTime? borne = debut(maintenant);
    return borne == null || !instant.isBefore(borne);
  }

  /// Le libelle du menu.
  String get libelle => switch (this) {
    PeriodeHistorique.toute => t.historique.filtres.toutePeriode,
    PeriodeHistorique.septJours => t.historique.filtres.septJours,
    PeriodeHistorique.trenteJours => t.historique.filtres.trenteJours,
    PeriodeHistorique.troisMois => t.historique.filtres.troisMois,
  };
}

/// Ce que l'Historique dit d'une seance passee, **apres** la seance.
///
/// Les etats de presence « en direct » n'ont plus de sens une fois la seance
/// finie (C08 section 4.3) : une coupure, un depart, un calcul non consolide
/// deviennent « En cours de verification » ; **aucune absence n'est deduite
/// d'une deconnexion**. Le sort du cours passe avant l'etat de l'eleve.
enum StatutHistorique {
  /// Present, revenu, ou etat consolide sans absence.
  presence,

  /// Entre apres le seuil de retard.
  retard,

  /// Preuve ambigue : lien coupe, depart, calcul non confirme, inconnu.
  verification,

  /// Jamais entre dans une seance terminee (`absente` du serveur).
  absence,

  /// Absence excusee par l'administration.
  excusee,

  /// Etat corrige a la main.
  corrigee,

  /// Seance annulee.
  annule,

  /// Seance non tenue (enseignant absent, panne) : pas le fait de l'eleve.
  nonTenu;

  /// Le libelle generique (menu « Statut »).
  String get libelle => switch (this) {
    StatutHistorique.presence => t.historique.etat.presence,
    StatutHistorique.retard => t.historique.etat.retardSansDuree,
    StatutHistorique.verification => t.historique.etat.verification,
    StatutHistorique.absence => LignePresence.libelle(EtatPresence.absente),
    StatutHistorique.excusee => LignePresence.libelle(EtatPresence.excusee),
    StatutHistorique.corrigee => LignePresence.libelle(
      EtatPresence.corrigeeManuel,
    ),
    StatutHistorique.annule => t.historique.etat.annule,
    StatutHistorique.nonTenu => t.historique.etat.nonTenu,
  };

  /// Le ton de la pastille. Jamais l'alerte pour ce qui n'est pas le fait de
  /// l'eleve ; le neutre pour ce qu'on ne sait pas encore.
  TonEtat get ton => switch (this) {
    StatutHistorique.presence => TonEtat.succes,
    StatutHistorique.retard => TonEtat.avertissement,
    StatutHistorique.absence => TonEtat.alerte,
    StatutHistorique.nonTenu => TonEtat.avertissement,
    StatutHistorique.verification ||
    StatutHistorique.excusee ||
    StatutHistorique.corrigee ||
    StatutHistorique.annule => TonEtat.neutre,
  };
}

/// Le statut d'une ligne d'historique.
StatutHistorique statutDe(LigneSuivi ligne) {
  switch (ligne.sort) {
    case SortDuCours.annule:
      return StatutHistorique.annule;
    case SortDuCours.nonTenu:
      return StatutHistorique.nonTenu;
    case SortDuCours.tenu:
      break;
  }
  return switch (ligne.presence.etat) {
    EtatPresence.presente ||
    EtatPresence.reconnectee ||
    EtatPresence.finalisee => StatutHistorique.presence,
    EtatPresence.enRetard => StatutHistorique.retard,
    EtatPresence.absente => StatutHistorique.absence,
    EtatPresence.excusee => StatutHistorique.excusee,
    EtatPresence.corrigeeManuel => StatutHistorique.corrigee,
    EtatPresence.deconnectee ||
    EtatPresence.enReconnexion ||
    EtatPresence.sortie ||
    EtatPresence.confirmationEnAttente ||
    EtatPresence.planifiee ||
    EtatPresence.enAttente ||
    EtatPresence.enConnexion ||
    EtatPresence.inconnu => StatutHistorique.verification,
  };
}

/// Le libelle de la pastille d'une ligne : le retard porte ses minutes quand
/// elles sont connues.
String libelleStatut(LigneSuivi ligne) {
  final StatutHistorique statut = statutDe(ligne);
  if (statut == StatutHistorique.retard) {
    final Duration? retard = ligne.presence.ecoule;
    if (retard != null && retard.inMinutes > 0) {
      return LibellesGroupe.insecable(
        t.historique.etat.retard(minutes: retard.inMinutes),
      );
    }
  }
  return statut.libelle;
}

/// Le statut d'un groupe de visites : tant qu'une visite n'a pas de sortie,
/// le groupe dit « Sortie non enregistree », jamais « Terminee ».
enum StatutObservation {
  /// Toutes les visites ont une sortie ecrite par le serveur.
  terminee,

  /// Au moins une visite sans sortie (fermeture serveur absente, DB-OBS-03).
  sortieNonEnregistree;

  /// Le libelle de la pastille et du menu.
  String get libelle => switch (this) {
    StatutObservation.terminee => t.historique.observations.terminee,
    StatutObservation.sortieNonEnregistree =>
      t.historique.observations.nonRefermee,
  };

  /// Le ton : succes quand c'est fini, neutre sinon (on ne sait pas).
  TonEtat get ton => switch (this) {
    StatutObservation.terminee => TonEtat.succes,
    StatutObservation.sortieNonEnregistree => TonEtat.neutre,
  };
}

/// Le statut d'un groupe de visites.
StatutObservation statutObservationDe(ObservationsSeance observations) =>
    observations.visites.any((GuardianSessionVisit v) => v.enCours)
    ? StatutObservation.sortieNonEnregistree
    : StatutObservation.terminee;

/// La premiere entree d'un groupe de visites, en heure de l'appareil.
DateTime premiereEntree(ObservationsSeance observations) => observations.visites
    .map((GuardianSessionVisit v) => v.enteredAtUtc)
    .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b)
    .toLocal();

/// Les filtres de l'Historique : classe, periode, statut. [S] est le type de
/// statut du segment ([StatutHistorique] ou [StatutObservation]).
@immutable
class FiltresHistorique<S> {
  /// Cree des filtres.
  const FiltresHistorique({
    this.classeId,
    this.periode = PeriodeHistorique.toute,
    this.statut,
  });

  /// La classe retenue, ou toutes.
  final String? classeId;

  /// La periode retenue.
  final PeriodeHistorique periode;

  /// Le statut retenu, ou tous.
  final S? statut;

  /// Vrai quand au moins un filtre est pose.
  bool get actifs =>
      classeId != null || periode != PeriodeHistorique.toute || statut != null;

  /// Les memes filtres avec une classe (ou toutes, `null`).
  FiltresHistorique<S> avecClasse(String? classe) =>
      FiltresHistorique<S>(classeId: classe, periode: periode, statut: statut);

  /// Les memes filtres avec une periode.
  FiltresHistorique<S> avecPeriode(PeriodeHistorique valeur) =>
      FiltresHistorique<S>(classeId: classeId, periode: valeur, statut: statut);

  /// Les memes filtres avec un statut (ou tous, `null`).
  FiltresHistorique<S> avecStatut(S? valeur) => FiltresHistorique<S>(
    classeId: classeId,
    periode: periode,
    statut: valeur,
  );
}

/// Les seances passees de l'eleve retenu, du plus recent au plus ancien.
///
/// « Passee » : la fin prevue est derriere nous. Une seance a venir ou en
/// cours appartient a l'Accueil, pas a l'Historique.
List<LigneSuivi> seancesPassees({
  required List<Seance> seances,
  required List<PresenceParticipant>? presences,
  required DateTime maintenant,
  required String? eleveId,
}) => VueSuiviFoyer.depuis(
  seances: seances,
  presences: presences,
  maintenant: maintenant,
  enfantId: eleveId,
).lignes.where((LigneSuivi l) => !l.seance.fin.isAfter(maintenant)).toList();

/// Le nombre de seances passees par eleve (sous-libelle du selecteur).
Map<String, int> seancesPasseesParEleve(
  List<Seance> seances,
  DateTime maintenant,
) {
  final Map<String, int> compte = <String, int>{};
  for (final Seance s in seances) {
    if (!s.fin.isAfter(maintenant)) {
      compte[s.eleveId] = (compte[s.eleveId] ?? 0) + 1;
    }
  }
  return compte;
}

/// « Aucune seance », « 1 seance », « 12 seances ».
String nombreSeances(int n) => switch (n) {
  0 => t.historique.selecteur.aucune,
  1 => t.historique.selecteur.une,
  _ => t.historique.selecteur.plusieurs(n: n),
};

/// Applique les filtres aux seances. [classeDe] rend la classe d'une seance
/// (`null` si inconnue).
List<LigneSuivi> filtrerSeances(
  List<LigneSuivi> lignes,
  FiltresHistorique<StatutHistorique> filtres, {
  required String? Function(String seanceId) classeDe,
  required DateTime maintenant,
}) => <LigneSuivi>[
  for (final LigneSuivi l in lignes)
    if ((filtres.classeId == null ||
            classeDe(l.seance.id) == filtres.classeId) &&
        filtres.periode.contient(l.seance.debut, maintenant) &&
        (filtres.statut == null || statutDe(l) == filtres.statut))
      l,
];

/// Applique les filtres aux observations.
List<ObservationsSeance> filtrerObservations(
  List<ObservationsSeance> groupes,
  FiltresHistorique<StatutObservation> filtres, {
  required DateTime maintenant,
}) => <ObservationsSeance>[
  for (final ObservationsSeance o in groupes)
    if ((filtres.classeId == null || o.groupeId == filtres.classeId) &&
        filtres.periode.contient(premiereEntree(o), maintenant) &&
        (filtres.statut == null || statutObservationDe(o) == filtres.statut))
      o,
];

// --- Mises en forme ---------------------------------------------------------

String _deux(int n) => n.toString().padLeft(2, '0');

/// L'heure d'un instant local : « 18:05 ».
String heureMinute(DateTime instant) =>
    '${_deux(instant.hour)}:${_deux(instant.minute)}';

/// « 23 sept. 2026 ».
String dateCourte(DateTime instant) => t.historique.dateCourte(
  jour: instant.day,
  mois: t.historique.moisCourts[instant.month - 1],
  annee: instant.year,
);

/// « 4 oct. » dans l'annee de [maintenant], « 4 oct. 2025 » sinon : la
/// colonne de date d'une ligne tient sur une ligne a texte x1 (COM-RC tour
/// 4, N-10).
String dateCompacte(DateTime instant, DateTime maintenant) =>
    instant.year == maintenant.year
    ? t.historique.dateCourteSansAnnee(
        jour: instant.day,
        mois: t.historique.moisCourts[instant.month - 1],
      )
    : dateCourte(instant);

/// « mercredi 23 septembre 2026 ».
String dateLongueHistorique(DateTime instant) => t.historique.dateLongue(
  jourSemaine: t.commun.dates.jours[instant.weekday - 1].toLowerCase(),
  jour: instant.day,
  mois: t.commun.dates.mois[instant.month - 1],
  annee: instant.year,
);

/// « lundi 21 sept. 2026 » : le sous-titre des details, sur une ligne.
String dateMoyenne(DateTime instant) =>
    '${t.commun.dates.jours[instant.weekday - 1].toLowerCase()} '
    '${dateCourte(instant)}';

/// « 18:00 - 19:00 ».
String plageHoraire(DateTime debut, DateTime fin) =>
    t.historique.plage(debut: heureMinute(debut), fin: heureMinute(fin));

/// Une duree lisible : « 48 s », « 2 min », « 1 min 42 s », « 1 h », « 1 h 05 ».
/// Insecable (DUREE-INSECABLE-1) : jamais scindee sur deux lignes.
String dureeLisible(Duration duree) =>
    LibellesGroupe.insecable(_dureeSecable(duree));

/// La meme duree affichee seule, comme valeur (« Duree prevue / 45 min ») :
/// ancree pour garder son ordre en interface de droite a gauche
/// (DUREE-INSECABLE-2, [LibellesGroupe.ancreSens]). Dans une phrase,
/// [dureeLisible] suffit.
String dureeSeule(Duration duree) =>
    LibellesGroupe.ancreSens(dureeLisible(duree));

String _dureeSecable(Duration duree) {
  final int secondes = duree.inSeconds < 0 ? 0 : duree.inSeconds;
  if (secondes < 60) {
    return LibellesGroupe.insecable(t.historique.duree.secondes(s: secondes));
  }
  if (secondes < 3600) {
    final int m = secondes ~/ 60;
    final int s = secondes % 60;
    return s == 0
        ? LibellesGroupe.insecable(t.historique.duree.minutes(m: m))
        : LibellesGroupe.insecable(
            t.historique.duree.minutesSecondes(m: m, s: s),
          );
  }
  final int h = secondes ~/ 3600;
  final int m = (secondes % 3600) ~/ 60;
  return m == 0
      ? LibellesGroupe.insecable(t.historique.duree.heures(h: h))
      : LibellesGroupe.insecable(
          t.historique.duree.heuresMinutes(h: h, m: _deux(m)),
        );
}

/// Le decalage de l'heure affichee sur UTC : « +02:00 », « -05:30 ».
String decalageUtc(DateTime instantLocal) {
  final Duration d = instantLocal.timeZoneOffset;
  final String signe = d.isNegative ? '-' : '+';
  final int minutes = d.inMinutes.abs();
  return '$signe${_deux(minutes ~/ 60)}:${_deux(minutes % 60)}';
}

/// « 2 visites · 3 min 42 s », ou « 1 visite · Duree non confirmee ».
String resumeVisites(ObservationsSeance observations) {
  final String nombre = observations.nombreVisites == 1
      ? t.historique.observations.visiteUne
      : t.historique.observations.visites(n: observations.nombreVisites);
  final Duration? total = observations.dureeTotaleConfirmee;
  return '$nombre · ${total == null ? t.historique.observations.dureeNonConfirmee : dureeLisible(total)}';
}
