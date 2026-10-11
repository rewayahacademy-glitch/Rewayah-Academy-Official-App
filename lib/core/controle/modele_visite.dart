import 'package:flutter/foundation.dart';

/// Faits automatiques d'une visite, relevés par le système.
@immutable
class FaitsVisite {
  const FaitsVisite({
    required this.debutPrevu,
    required this.finPrevue,
    required this.debutReel,
    required this.participantsAttendus,
    required this.participantsPresents,
    required this.reconnexions,
    this.finReelle,
  });

  final DateTime debutPrevu;
  final DateTime finPrevue;
  final DateTime debutReel;
  final DateTime? finReelle;
  final int participantsAttendus;
  final int participantsPresents;
  final int reconnexions;

  int get minutesDeRetard {
    final int m = debutReel.difference(debutPrevu).inMinutes;
    return m > 0 ? m : 0;
  }
}

/// Choix du contrôleur lors de la clôture du compte rendu.
enum ChoixCompteRendu { rienASignaler, ajouterObservation, pointImportant }
