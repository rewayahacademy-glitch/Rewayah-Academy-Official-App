import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_locales.dart';
import 'capacite_indisponible.dart';

/// La persistance des preferences locales entre deux lancements (contrat K6).
abstract interface class PortPreferencesPersistantes {
  /// Les preferences enregistrees sur cet appareil. `null` : aucune.
  Future<PreferencesLocales?> charger();

  /// Enregistre les preferences sur cet appareil.
  Future<void> enregistrer(PreferencesLocales preferences);
}

/// La persistance tant qu'aucun stockage local n'est choisi (DB-CPT-09,
/// dependance **frontend** : aucun paquet de preferences dans `pubspec.yaml`).
///
/// Les preferences vivent en memoire (`preferencesLocalesProvider`) ; l'ecran
/// dit « sur cet appareil, jusqu'a la fermeture ». L'adaptateur reel est ecrit
/// par le **coordinateur** une fois le stockage choisi.
class PreferencesPersistantesIndisponibles
    implements PortPreferencesPersistantes {
  /// Cree l'implementation.
  const PreferencesPersistantesIndisponibles();

  @override
  Future<PreferencesLocales?> charger() => Future<PreferencesLocales?>.error(
    const CapaciteIndisponible('DB-CPT-09'),
  );

  @override
  Future<void> enregistrer(PreferencesLocales preferences) =>
      Future<void>.error(const CapaciteIndisponible('DB-CPT-09'));
}

/// La persistance des preferences employee par l'application.
final Provider<PortPreferencesPersistantes>
portPreferencesPersistantesProvider = Provider<PortPreferencesPersistantes>(
  (Ref ref) => const PreferencesPersistantesIndisponibles(),
);
