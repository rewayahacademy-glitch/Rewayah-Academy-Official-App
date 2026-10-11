/// LIVE-CHRONO-01 : le chrono interne de la salle, une fonction pure.
///
/// Il ne sert qu'a connaitre la duree de la seance : le temps ecoule depuis
/// T0 et le temps restant jusqu'a `00:00:00`. **Jamais une preuve de
/// presence** : il compte une seance, pas une personne ; entrer tot ou tard ne
/// le change pas, et aucun ecran ne le presente comme une presence.
///
/// Aucun compteur qui derive : [ChronoSeance.a] recalcule tout, a chaque appel,
/// depuis les deux horodatages UTC de la seance et l'instant qu'on lui donne.
/// Un ecran qui revient d'arriere-plan ou d'une reconnexion rappelle la
/// fonction et retrouve le bon temps, quelle qu'ait ete la duree de l'absence.
library;

import 'package:flutter/foundation.dart';

import 'fenetre_seance.dart';

/// Ou en est la seance, du point de vue du chrono.
enum PhaseChrono {
  /// Avant T0 : le chrono n'affirme rien.
  avantDebut,

  /// De T0 a la fin prevue : temps ecoule et temps restant.
  enCours,

  /// Apres la fin prevue : « Temps prevu ecoule », jamais un temps negatif.
  prevuEcoule,
}

/// Les deux bornes d'une seance dont le chrono a besoin, en UTC.
@immutable
class BornesChrono {
  /// Cree les bornes ; la fin suit le debut.
  BornesChrono({required this.debutUtc, required this.finPrevueUtc})
    : assert(
        !finPrevueUtc.isBefore(debutUtc),
        'une seance ne finit pas avant de commencer',
      );

  /// Les bornes d'une [FenetreSeance] (T0 et fin prevue).
  factory BornesChrono.depuisFenetre(FenetreSeance fenetre) => BornesChrono(
    debutUtc: fenetre.debutUtc.toUtc(),
    finPrevueUtc: fenetre.finPrevueUtc.toUtc(),
  );

  /// T0 : le debut de la seance.
  final DateTime debutUtc;

  /// La fin prevue.
  final DateTime finPrevueUtc;

  /// La duree prevue de la seance, tiree de ses bornes.
  Duration get duree => finPrevueUtc.difference(debutUtc);

  @override
  bool operator ==(Object other) =>
      other is BornesChrono &&
      other.debutUtc == debutUtc &&
      other.finPrevueUtc == finPrevueUtc;

  @override
  int get hashCode => Object.hash(debutUtc, finPrevueUtc);
}

/// Le chrono de la seance a un instant donne.
@immutable
class ChronoSeance {
  const ChronoSeance._({
    required this.phase,
    required this.duree,
    required this.ecoule,
    required this.restant,
  });

  /// Calcule le chrono de [bornes] a [maintenantUtc].
  ///
  /// Le temps ecoule ne depasse jamais la duree et le temps restant n'est
  /// jamais negatif : apres la fin prevue, la phase est
  /// [PhaseChrono.prevuEcoule] et les deux durees valent la duree et zero.
  factory ChronoSeance.a(BornesChrono bornes, DateTime maintenantUtc) {
    final DateTime maintenant = maintenantUtc.toUtc();
    final Duration duree = bornes.duree;
    if (maintenant.isBefore(bornes.debutUtc)) {
      return ChronoSeance._(
        phase: PhaseChrono.avantDebut,
        duree: duree,
        ecoule: Duration.zero,
        restant: duree,
      );
    }
    if (!maintenant.isBefore(bornes.finPrevueUtc)) {
      return ChronoSeance._(
        phase: PhaseChrono.prevuEcoule,
        duree: duree,
        ecoule: duree,
        restant: Duration.zero,
      );
    }
    return ChronoSeance._(
      phase: PhaseChrono.enCours,
      duree: duree,
      ecoule: maintenant.difference(bornes.debutUtc),
      restant: bornes.finPrevueUtc.difference(maintenant),
    );
  }

  /// Ou en est la seance.
  final PhaseChrono phase;

  /// La duree prevue de la seance.
  final Duration duree;

  /// Le temps ecoule depuis T0, entre zero et [duree].
  final Duration ecoule;

  /// Le temps restant jusqu'a `00:00:00`, jamais negatif.
  final Duration restant;

  /// Vrai quand le chrono a quelque chose a dire : la seance a commence.
  bool get visible => phase != PhaseChrono.avantDebut;

  /// Vrai apres la fin prevue.
  bool get prevuEcoule => phase == PhaseChrono.prevuEcoule;

  /// Les minutes entieres ecoulees (ce que lit un lecteur d'ecran).
  int get minutesEcoulees => ecoule.inMinutes;

  /// Les minutes restantes que lit un lecteur d'ecran, derivees des minutes
  /// ecoulees : les deux nombres changent au meme instant (une seule annonce
  /// par minute), meme quand la duree prevue n'est pas un nombre rond de
  /// minutes.
  int get minutesRestantes {
    final int secondes =
        duree.inSeconds - minutesEcoulees * Duration.secondsPerMinute;
    return secondes <= 0 ? 0 : (secondes / Duration.secondsPerMinute).ceil();
  }

  @override
  bool operator ==(Object other) =>
      other is ChronoSeance &&
      other.phase == phase &&
      other.duree == duree &&
      other.ecoule == ecoule &&
      other.restant == restant;

  @override
  int get hashCode => Object.hash(phase, duree, ecoule, restant);
}

/// `HH:MM:SS`, chiffres latins, deux chiffres par champ. Une duree negative
/// est ramenee a zero : le format ne sait pas dire un temps negatif.
String formaterChrono(Duration duree) {
  final int secondes = duree.isNegative ? 0 : duree.inSeconds;
  final int h = secondes ~/ Duration.secondsPerHour;
  final int m =
      (secondes % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final int s = secondes % Duration.secondsPerMinute;
  String deux(int n) => n.toString().padLeft(2, '0');
  return '${deux(h)}:${deux(m)}:${deux(s)}';
}
