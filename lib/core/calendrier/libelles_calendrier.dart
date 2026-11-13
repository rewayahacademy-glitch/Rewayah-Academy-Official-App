// CALENDRIER-ET-PAUSES (12/11/2026) : les libelles communs a la direction et a
// la famille, par `commun.dates` et `calendrier` / `pause` (slang). Aucun nom
// de mois ecrit ici.

import '../i18n/strings.g.dart';
import '../offres/tranche_age.dart';
import '../tc_groupe/libelles_tc_groupe.dart';
import 'port_calendrier.dart';

/// « 21 décembre 2026 ».
String jourEnMots(DateTime jour) =>
    '${jour.day} ${t.commun.dates.mois[jour.month - 1].toLowerCase()} '
    '${jour.year}';

/// « décembre 2026 ».
String moisEnMots(DateTime jour) =>
    '${t.commun.dates.mois[jour.month - 1].toLowerCase()} ${jour.year}';

/// Le mois d'un parametre de notification `AAAA-MM`, en mots ; `null` si
/// illisible.
String? moisDepuisCle(Object? cle) {
  if (cle is! String) return null;
  final DateTime? d = DateTime.tryParse('$cle-01');
  return d == null ? null : moisEnMots(d);
}

/// « Du 3 au 22 décembre 2026 » ; « Le 3 décembre 2026 » pour un seul jour.
String periodeEnMots(DateTime du, DateTime au) => du == au
    ? t.calendrier.dates.unJour(jour: jourEnMots(du))
    : t.calendrier.dates.periode(du: jourEnMots(du), au: jourEnMots(au));

/// Le genre d'une date.
String libelleType(TypeEvenement type) => switch (type) {
  TypeEvenement.fermeture => t.calendrier.dates.type.fermeture,
  TypeEvenement.rencontre => t.calendrier.dates.type.rencontre,
  TypeEvenement.evaluation => t.calendrier.dates.type.evaluation,
  TypeEvenement.autre => t.calendrier.dates.type.autre,
};

/// La categorie d'une fermeture.
String libelleCategorie(CategorieFermeture categorie) => switch (categorie) {
  CategorieFermeture.ramadan => t.calendrier.dates.categorie.ramadan,
  CategorieFermeture.aidAlAdha => t.calendrier.dates.categorie.aidAlAdha,
  CategorieFermeture.autre => t.calendrier.dates.categorie.autre,
};

/// A qui s'adresse la date : l'ecole, la tranche (son nom humain) ou la classe
/// (son nom).
String libelleCible(EvenementCalendrier e) => switch (e.portee) {
  PorteeEvenement.ecole => t.calendrier.dates.portee.ecole,
  PorteeEvenement.tranche =>
    e.cohorte == null
        ? t.calendrier.dates.portee.tranche
        : libelleTranche(e.cohorte!),
  PorteeEvenement.classe =>
    (e.groupeLibelle ?? '').isEmpty
        ? t.calendrier.dates.portee.classe
        : e.groupeLibelle!,
};

/// Le refus du calendrier, en mots simples (K-59 : ce qui manque et quoi faire).
String messageRefusCalendrier(MotifRefusCalendrier motif) {
  final r = t.calendrier.dates.refus;
  return switch (motif) {
    MotifRefusCalendrier.fermetureTropLongue => r.fermetureTropLongue,
    MotifRefusCalendrier.fermetureCommencee => r.fermetureCommencee,
    MotifRefusCalendrier.datesInvalides => r.datesInvalides,
    MotifRefusCalendrier.porteeInvalide => r.porteeInvalide,
    MotifRefusCalendrier.evenementInvalide => r.evenementInvalide,
    MotifRefusCalendrier.introuvable => r.introuvable,
    MotifRefusCalendrier.nonAutorise => r.nonAutorise,
    MotifRefusCalendrier.inconnu => r.inconnu,
  };
}

/// Le refus d'une decision de la direction sur une pause.
String messageRefusDecisionPause(MotifRefusPause motif, {int? moisMax}) {
  final r = t.calendrier.pauses.refus;
  return switch (motif) {
    MotifRefusPause.motifRequis => r.motifRequis,
    MotifRefusPause.dejaDecidee => r.dejaDecidee,
    MotifRefusPause.debutPasse => r.debutPasse,
    MotifRefusPause.datesInvalides => r.datesInvalides,
    MotifRefusPause.exceptionTropLongue =>
      moisMax == null ? r.datesInvalides : r.exceptionTropLongue(mois: moisMax),
    MotifRefusPause.nonTerminable => r.nonTerminable,
    MotifRefusPause.eleveIntrouvable => r.eleveIntrouvable,
    MotifRefusPause.nonAutorise => r.nonAutorise,
    _ => r.inconnu,
  };
}

/// Le refus d'une demande de la famille ; [preavisJours] est celui de la regle
/// lue sur le serveur.
String messageRefusDemandePause(MotifRefusPause motif, {int? preavisJours}) {
  final r = t.pause.refus;
  return switch (motif) {
    MotifRefusPause.preavis =>
      preavisJours == null
          ? r.inconnu
          : LibellesGroupe.insecable(r.preavis(jours: preavisJours)),
    MotifRefusPause.dejaDemandee => r.dejaDemandee,
    MotifRefusPause.moisInvalide => r.moisInvalide,
    MotifRefusPause.nonAnnulable => r.nonAnnulable,
    MotifRefusPause.nonAutorise => r.nonAutorise,
    _ => r.inconnu,
  };
}

/// Le mot d'un etat de pause.
String libelleStatutPause(StatutPause statut, {required bool famille}) {
  if (famille) {
    final s = t.pause.statut;
    return switch (statut) {
      StatutPause.demandee => s.demandee,
      StatutPause.acceptee => s.acceptee,
      StatutPause.refusee => s.refusee,
      StatutPause.annulee => s.annulee,
    };
  }
  final s = t.calendrier.pauses.statut;
  return switch (statut) {
    StatutPause.demandee => s.demandee,
    StatutPause.acceptee => s.acceptee,
    StatutPause.refusee => s.refusee,
    StatutPause.annulee => s.annulee,
  };
}
