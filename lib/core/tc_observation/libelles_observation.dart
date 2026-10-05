import '../i18n/strings.g.dart';
import 'disponibilite_observation.dart';
import 'guardian_session_visit.dart';
import 'port_politique_observation.dart';

/// Le message qui correspond a un refus serveur d'entree en observation.
String libelleRefusObservation(MotifRefusObservation motif) => switch (motif) {
  MotifRefusObservation.policyDesactivee =>
    t.tc.observation.refus.politiqueDesactivee,
  MotifRefusObservation.quotaVisitesAtteint =>
    t.tc.observation.refus.quotaVisites,
  MotifRefusObservation.tempsEpuise => t.tc.observation.refus.tempsEpuise,
  MotifRefusObservation.lienTuteurAbsent => t.tc.observation.refus.lienTuteur,
  MotifRefusObservation.seanceNonActive =>
    t.tc.observation.refus.seanceNonActive,
  MotifRefusObservation.horsFenetre => t.tc.observation.refus.horsFenetre,
};

/// Le message qui correspond a une fin de visite.
String libelleFinVisite(FinDeVisite fin) => switch (fin) {
  FinDeVisite.sortieVolontaire => t.tc.observation.fin.sortieVolontaire,
  FinDeVisite.quotaAtteint => t.tc.observation.fin.quotaAtteint,
  FinDeVisite.seanceTerminee => t.tc.observation.fin.seanceTerminee,
  FinDeVisite.revocationServeur => t.tc.observation.fin.revocationServeur,
  FinDeVisite.deconnexion => t.tc.observation.fin.deconnexion,
};

/// Une duree de visite, lisible : « 2 minutes », « 1 min 30 s »,
/// « 45 secondes ».
///
/// **La valeur vient toujours du serveur** (politique effective ou budget) :
/// cette fonction ne fait que l'ecrire, elle n'en suppose aucune.
String dureeVisiteLisible(Duration duree) {
  final int total = duree.isNegative ? 0 : duree.inSeconds;
  final int minutes = total ~/ 60;
  final int secondes = total % 60;
  final d = t.tc.observation.duree;
  if (minutes == 0) {
    return secondes <= 1 ? d.secondeUne(n: secondes) : d.secondes(n: secondes);
  }
  if (secondes == 0) {
    return minutes == 1 ? d.minuteUne(n: minutes) : d.minutes(n: minutes);
  }
  return d.minutesSecondes(m: minutes, s: secondes);
}

/// La regle d'observation, telle que la politique effective la donne :
/// « 2 visites de 2 minutes ».
String regleVisitesObservation(int visitesMax, Duration dureeParVisite) {
  final String duree = dureeVisiteLisible(dureeParVisite);
  return visitesMax > 1
      ? t.tc.observation.explication.regle(n: visitesMax, duree: duree)
      : t.tc.observation.explication.regleUne(n: visitesMax, duree: duree);
}

/// Les visites restantes pour la seance : « 1/2 visite restante pour cette
/// seance », accord au pluriel, « Aucune visite restante pour cette seance » a
/// zero (decision du directeur du 24/09, `03` section 1 bis-5).
String visitesRestantesLisible({required int restantes, required int max}) {
  final e = t.tc.observation.explication;
  if (restantes <= 0) {
    return e.aucuneRestante;
  }
  return restantes > 1
      ? e.restantes(restantes: restantes, max: max)
      : e.restanteUne(restantes: restantes, max: max);
}

/// Le titre et la phrase d'une indisponibilite, dits a la famille.
///
/// Aucun code technique : chaque motif a sa phrase. [MotifIndisponibilite.reseau]
/// dit que rien n'a commence, parce que c'est vrai a ce stade (la verification
/// prealable ne fait que lire).
({String titre, String phrase}) textesIndisponibilite(
  MotifIndisponibilite motif,
) {
  final d = t.tc.observation.disponibilite;
  return switch (motif) {
    MotifIndisponibilite.visitesEpuisees => (
      titre: d.visitesEpuiseesTitre,
      phrase: d.visitesEpuisees,
    ),
    MotifIndisponibilite.tempsEpuise => (
      titre: d.tempsEpuiseTitre,
      phrase: d.tempsEpuise,
    ),
    MotifIndisponibilite.seanceNonCommencee => (
      titre: d.seanceNonCommenceeTitre,
      phrase: d.seanceNonCommencee,
    ),
    MotifIndisponibilite.seanceTerminee => (
      titre: d.seanceTermineeTitre,
      phrase: d.seanceTerminee,
    ),
    MotifIndisponibilite.seanceNonTenue => (
      titre: d.seanceNonTenueTitre,
      phrase: d.seanceNonTenue,
    ),
    MotifIndisponibilite.horsFenetre => (
      titre: d.horsFenetreTitre,
      phrase: d.horsFenetre,
    ),
    MotifIndisponibilite.observationDesactivee => (
      titre: d.desactiveeTitre,
      phrase: d.desactivee,
    ),
    MotifIndisponibilite.lienAbsent => (
      titre: d.lienAbsentTitre,
      phrase: d.lienAbsent,
    ),
    MotifIndisponibilite.enfantAbsent => (
      titre: d.enfantAbsentTitre,
      phrase: d.enfantAbsent,
    ),
    MotifIndisponibilite.presenceEnVerification => (
      titre: d.presenceTitre,
      phrase: d.presence,
    ),
    MotifIndisponibilite.visiteDejaOuverte => (
      titre: d.visiteOuverteTitre,
      phrase: d.visiteOuverte,
    ),
    MotifIndisponibilite.garantieServeurAbsente => (
      titre: d.fermeeTitre,
      phrase: d.fermee,
    ),
    MotifIndisponibilite.reseau => (titre: d.reseauTitre, phrase: d.reseau),
    MotifIndisponibilite.capaciteAbsente => (
      titre: d.capaciteTitre,
      phrase: d.capacite,
    ),
  };
}

/// Un nombre de visites, avec son unite.
///
/// Deux cles plutot qu'un pluriel slang : `fr.i18n.json` n'utilise aucune
/// forme `(plural)` aujourd'hui, et introduire la premiere pendant la phase
/// parallele aurait fait porter a Agent Z un changement de pipeline en plus
/// d'une fusion.
String uniteVisitesObservation(int n) => n > 1
    ? t.tc.observation.reglages.uniteVisites(n: n)
    : t.tc.observation.reglages.uniteVisiteUne(n: n);
