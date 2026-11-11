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

  /// Apres la fin prevue, tant que le depassement autorise n'est pas epuise
  /// ([BornesChrono.depassementMax]) : le chrono compte en croissant ce qui
  /// depasse (directeur, 11/11/2026). N'existe pas sans depassement autorise.
  depassement,

  /// Apres la fin prevue et le depassement autorise : la seance est finie
  /// pour le chrono, jamais un temps negatif.
  prevuEcoule,
}

/// Les deux bornes d'une seance dont le chrono a besoin, en UTC.
@immutable
class BornesChrono {
  /// Cree les bornes ; la fin suit le debut.
  BornesChrono({
    required this.debutUtc,
    required this.finPrevueUtc,
    this.depassementMax = Duration.zero,
  }) : assert(
         !finPrevueUtc.isBefore(debutUtc),
         'une seance ne finit pas avant de commencer',
       ),
       assert(!depassementMax.isNegative, 'un depassement ne se retranche pas');

  /// Les bornes d'une [FenetreSeance] (T0 et fin prevue).
  factory BornesChrono.depuisFenetre(FenetreSeance fenetre) => BornesChrono(
    debutUtc: fenetre.debutUtc.toUtc(),
    finPrevueUtc: fenetre.finPrevueUtc.toUtc(),
    depassementMax: fenetre.graceApresFin,
  );

  /// T0 : le debut de la seance.
  final DateTime debutUtc;

  /// La fin prevue.
  final DateTime finPrevueUtc;

  /// Le depassement autorise apres la fin prevue : un reglage de la
  /// direction, servi par le serveur (`grace_after_end_minutes`), jamais une
  /// valeur decidee par l'ecran. Zero : aucun depassement, le chrono s'arrete
  /// a la fin prevue.
  final Duration depassementMax;

  /// La duree prevue de la seance, tiree de ses bornes.
  Duration get duree => finPrevueUtc.difference(debutUtc);

  /// L'instant ou le depassement autorise est epuise.
  DateTime get finDepassementUtc => finPrevueUtc.add(depassementMax);

  @override
  bool operator ==(Object other) =>
      other is BornesChrono &&
      other.debutUtc == debutUtc &&
      other.finPrevueUtc == finPrevueUtc &&
      other.depassementMax == depassementMax;

  @override
  int get hashCode => Object.hash(debutUtc, finPrevueUtc, depassementMax);
}

/// Une pause de la seance, bornee par ses horodatages serveur, en UTC.
///
/// [finUtc] nul : la pause est en cours. LIVE-PAUSE-01 : le temps ecoule du
/// chrono la decompte ; le temps restant prevu, lui, ne la retire pas.
@immutable
class PauseChrono {
  /// Cree la pause.
  PauseChrono({required this.debutUtc, this.finUtc})
    : assert(finUtc == null || !finUtc.isBefore(debutUtc));

  /// Le debut de la pause.
  final DateTime debutUtc;

  /// La fin de la pause, ou `null` si elle dure encore.
  final DateTime? finUtc;

  /// La part de cette pause comprise entre [depuis] et [jusqua].
  Duration partie(DateTime depuis, DateTime jusqua) {
    final DateTime debut = debutUtc.isBefore(depuis) ? depuis : debutUtc;
    final DateTime fin = (finUtc != null && finUtc!.isBefore(jusqua))
        ? finUtc!
        : jusqua;
    return fin.isAfter(debut) ? fin.difference(debut) : Duration.zero;
  }

  @override
  bool operator ==(Object other) =>
      other is PauseChrono &&
      other.debutUtc == debutUtc &&
      other.finUtc == finUtc;

  @override
  int get hashCode => Object.hash(debutUtc, finUtc);
}

/// Le chrono de la seance a un instant donne.
@immutable
class ChronoSeance {
  const ChronoSeance._({
    required this.phase,
    required this.duree,
    required this.ecoule,
    required this.restant,
    this.enPause = false,
    this.pause = Duration.zero,
    this.depasse = Duration.zero,
  });

  /// Calcule le chrono de [bornes] a [maintenantUtc].
  ///
  /// Le temps ecoule ne depasse jamais la duree et le temps restant n'est
  /// jamais negatif : apres la fin prevue, la phase est
  /// [PhaseChrono.prevuEcoule] et les deux durees valent la duree et zero.
  factory ChronoSeance.a(
    BornesChrono bornes,
    DateTime maintenantUtc, {
    List<PauseChrono> pauses = const <PauseChrono>[],
  }) {
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
      final Duration depasse = maintenant.difference(bornes.finPrevueUtc);
      final bool autorise = depasse < bornes.depassementMax;
      return ChronoSeance._(
        phase: autorise ? PhaseChrono.depassement : PhaseChrono.prevuEcoule,
        duree: duree,
        ecoule: duree,
        restant: Duration.zero,
        // Borne : passe le depassement autorise, le chrono reste sur lui.
        depasse: autorise ? depasse : bornes.depassementMax,
      );
    }
    // Les pauses sortent du temps ecoule (le temps de cours), jamais du temps
    // restant jusqu'a la fin prevue : l'horloge de la fin ne bouge pas.
    Duration enPauseTotal = Duration.zero;
    bool enCours = false;
    for (final PauseChrono p in pauses) {
      enPauseTotal += p.partie(bornes.debutUtc, maintenant);
      if (p.finUtc == null && !p.debutUtc.isAfter(maintenant)) {
        enCours = true;
      }
    }
    final Duration brut = maintenant.difference(bornes.debutUtc);
    final Duration net = brut - enPauseTotal;
    return ChronoSeance._(
      phase: PhaseChrono.enCours,
      duree: duree,
      ecoule: net.isNegative ? Duration.zero : net,
      restant: bornes.finPrevueUtc.difference(maintenant),
      enPause: enCours,
      pause: enPauseTotal,
    );
  }

  /// Ou en est la seance.
  final PhaseChrono phase;

  /// La duree prevue de la seance.
  final Duration duree;

  /// Le temps ecoule depuis T0, entre zero et [duree].
  final Duration ecoule;

  /// Le temps restant jusqu'a `00:00:00`, jamais negatif. Il ne retire pas
  /// les pauses : la fin prevue reste celle de l'horloge.
  final Duration restant;

  /// Une pause est en cours : le temps ecoule est fige.
  final bool enPause;

  /// Le temps de pause deja compte depuis T0.
  final Duration pause;

  /// Le temps passe au-dela de la fin prevue, borne par le depassement
  /// autorise. Zero avant la fin prevue.
  final Duration depasse;

  /// Vrai pendant le depassement autorise : le chrono compte en croissant.
  bool get enDepassement => phase == PhaseChrono.depassement;

  /// Vrai des que la fin prevue est atteinte, depassement compris.
  bool get finPrevueAtteinte =>
      phase == PhaseChrono.depassement || phase == PhaseChrono.prevuEcoule;

  /// Vrai quand le chrono a quelque chose a dire : la seance a commence.
  bool get visible => phase != PhaseChrono.avantDebut;

  /// Vrai quand le chrono n'a plus rien a compter : apres la fin prevue et
  /// le depassement autorise.
  bool get prevuEcoule => phase == PhaseChrono.prevuEcoule;

  /// Les minutes entieres ecoulees (ce que lit un lecteur d'ecran).
  int get minutesEcoulees => ecoule.inMinutes;

  /// Les minutes restantes que lit un lecteur d'ecran, derivees avec les
  /// secondes deja ecoulees de la minute courante : sans pause, elles changent
  /// a la meme seconde que les minutes ecoulees (une seule annonce par
  /// minute), meme quand la duree prevue n'est pas un nombre rond de minutes.
  int get minutesRestantes {
    final int secondes =
        restant.inSeconds + ecoule.inSeconds % Duration.secondsPerMinute;
    return secondes <= 0 ? 0 : (secondes / Duration.secondsPerMinute).ceil();
  }

  @override
  bool operator ==(Object other) =>
      other is ChronoSeance &&
      other.phase == phase &&
      other.duree == duree &&
      other.ecoule == ecoule &&
      other.restant == restant &&
      other.enPause == enPause &&
      other.pause == pause &&
      other.depasse == depasse;

  @override
  int get hashCode =>
      Object.hash(phase, duree, ecoule, restant, enPause, pause, depasse);
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

/// Le chrono tel qu'il se lit d'un coup d'oeil (directeur, 11/11/2026 : « le
/// chrono montre seulement ce qui reste ») : `MM:SS` sous une heure,
/// `H:MM:SS` au-dela. Chiffres latins ; une duree negative vaut zero.
String formaterChronoCourt(Duration duree) {
  final int secondes = duree.isNegative ? 0 : duree.inSeconds;
  final int h = secondes ~/ Duration.secondsPerHour;
  final int m =
      (secondes % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final int s = secondes % Duration.secondsPerMinute;
  String deux(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${deux(m)}:${deux(s)}' : '${deux(m)}:${deux(s)}';
}
