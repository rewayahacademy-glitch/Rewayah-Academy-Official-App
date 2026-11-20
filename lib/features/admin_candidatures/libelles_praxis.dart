// PRAXIS-VISIBLE : les mots du travail de Praxis, en un seul endroit, pour la
// carte du dossier, la page « Le travail de Praxis » et la marque d'une ligne
// de la file. Une valeur du serveur a un mot et un ton ; aucun ecran n'en
// recompose un.
library;

import '../../core/agent/travail_praxis.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/widgets/status_pill.dart';

/// Le mot d'une pile.
String libellePile(PilePraxis pile) {
  final p = t.admin.praxis.travail.piles;
  return switch (pile) {
    PilePraxis.pretADecider => p.pretADecider,
    PilePraxis.incomplet => p.incomplet,
    PilePraxis.sansNouvelles => p.sansNouvelles,
    PilePraxis.aRegarder => p.aRegarder,
  };
}

/// Le ton d'une pile : « Pret a decider » est la seule bonne nouvelle, « A
/// regarder » demande l'oeil de la direction ; le reste est neutre.
TonEtat tonPile(PilePraxis pile) => switch (pile) {
  PilePraxis.pretADecider => TonEtat.succes,
  PilePraxis.aRegarder => TonEtat.avertissement,
  PilePraxis.incomplet || PilePraxis.sansNouvelles => TonEtat.neutre,
};

/// Le mot d'une etiquette.
String libelleEtiquette(EtiquettePraxis etiquette) {
  final e = t.admin.praxis.travail.etiquettes;
  return switch (etiquette) {
    EtiquettePraxis.pepite => e.pepite,
    EtiquettePraxis.solide => e.solide,
    EtiquettePraxis.aCreuser => e.aCreuser,
    EtiquettePraxis.reserve => e.reserve,
  };
}

/// Le ton d'une etiquette. Une reserve n'est jamais rouge : c'est un avis,
/// pas une alerte.
TonEtat tonEtiquette(EtiquettePraxis etiquette) => switch (etiquette) {
  EtiquettePraxis.pepite => TonEtat.succes,
  EtiquettePraxis.solide => TonEtat.accent,
  EtiquettePraxis.aCreuser => TonEtat.neutre,
  EtiquettePraxis.reserve => TonEtat.avertissement,
};

/// Le mot d'une confiance.
String libelleConfiance(ConfiancePraxis c) {
  final m = t.admin.praxis.avis.confiances;
  return switch (c) {
    ConfiancePraxis.faible => m.faible,
    ConfiancePraxis.moyenne => m.moyenne,
    ConfiancePraxis.forte => m.forte,
  };
}

/// Le mot d'un critere.
String libelleCritere(CriterePraxis c) {
  final m = t.admin.praxis.avis.critere;
  return switch (c) {
    CriterePraxis.maitrise => m.maitrise,
    CriterePraxis.pedagogie => m.pedagogie,
    CriterePraxis.vision => m.vision,
    CriterePraxis.comportement => m.comportement,
    CriterePraxis.disponibilite => m.disponibilite,
  };
}

/// Le mot d'un effet du contexte.
String libelleEffet(EffetContexte e) {
  final m = t.admin.praxis.avis.effets;
  return switch (e) {
    EffetContexte.atout => m.atout,
    EffetContexte.risque => m.risque,
    EffetContexte.aVerifier => m.aVerifier,
  };
}

/// Le ton d'un effet du contexte.
TonEtat tonEffet(EffetContexte e) => switch (e) {
  EffetContexte.atout => TonEtat.succes,
  EffetContexte.risque => TonEtat.avertissement,
  EffetContexte.aVerifier => TonEtat.neutre,
};

String _deux(int n) => n.toString().padLeft(2, '0');

/// Le jour d'un instant, a l'heure du profil (« 20/11 »).
String jourPraxis(DateTime instant) {
  final DateTime d = chezMoi(instant);
  return '${_deux(d.day)}/${_deux(d.month)}';
}

/// Le jour d'une date du serveur, sans heure (« 20/11 »).
String datePraxis(DateTime date) => '${_deux(date.day)}/${_deux(date.month)}';

/// L'heure d'un instant, a l'heure du profil.
String heurePraxis(DateTime instant) => heureChezMoi(instant);
