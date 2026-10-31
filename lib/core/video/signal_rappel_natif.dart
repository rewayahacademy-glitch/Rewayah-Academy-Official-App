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
