import 'dart:async';

import 'package:flutter/services.dart';

import '../observabilite/journal_dev.dart';

/// Hors navigateur : vibration et son systeme, sans jamais lever.
void signalerRappel() {
  unawaited(
    HapticFeedback.vibrate().catchError(
      (Object e) => journalDev('vibration du rappel impossible : $e'),
    ),
  );
  unawaited(
    SystemSound.play(SystemSoundType.alert)
        .catchError((Object e) => journalDev('son du rappel impossible : $e')),
  );
}

/// CHRONO-ETAT (11/11/2026) : le signal du chrono de qui conduit la seance.
/// Hors navigateur : le son d'alerte du systeme, sans vibration.
void signalerChrono() {
  unawaited(
    SystemSound.play(SystemSoundType.alert)
        .catchError((Object e) => journalDev('son du chrono impossible : $e')),
  );
}
