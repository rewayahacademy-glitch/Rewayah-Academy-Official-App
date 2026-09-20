import '../i18n/strings.g.dart';
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

/// Un nombre de visites, avec son unite.
///
/// Deux cles plutot qu'un pluriel slang : `fr.i18n.json` n'utilise aucune
/// forme `(plural)` aujourd'hui, et introduire la premiere pendant la phase
/// parallele aurait fait porter a Agent Z un changement de pipeline en plus
/// d'une fusion.
String uniteVisitesObservation(int n) => n > 1
    ? t.tc.observation.reglages.uniteVisites(n: n)
    : t.tc.observation.reglages.uniteVisiteUne(n: n);
