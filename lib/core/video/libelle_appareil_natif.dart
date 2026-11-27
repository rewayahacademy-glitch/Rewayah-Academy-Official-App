import 'package:flutter/foundation.dart';

/// Hors navigateur : pas d'agent utilisateur.
String agentUtilisateur() => '';

/// Le systeme de l'application, en un mot.
String systemeNatif() => switch (defaultTargetPlatform) {
  TargetPlatform.android => 'Android',
  TargetPlatform.iOS => 'iOS',
  TargetPlatform.macOS => 'macOS',
  TargetPlatform.windows => 'Windows',
  TargetPlatform.linux => 'Linux',
  TargetPlatform.fuchsia => '',
};
