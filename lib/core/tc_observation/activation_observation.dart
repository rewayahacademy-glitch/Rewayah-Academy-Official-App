import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

/// Vrai quand l'observation reelle par le tuteur est ouverte sur cette
/// compilation (point P3 du chantier Tuteur V1, contrat K4).
///
/// **Seule entree des ecrans vers l'interrupteur** `OBSERVATION_TUTEUR_REELLE`
/// ([Env.observationTuteurReelleActive]) : un ecran ne lit jamais `Env`
/// directement, pour que les tests puissent monter les deux cotes de
/// l'interrupteur sans compilation dediee. Faux, le tuteur n'appelle aucune
/// porte d'observation du serveur : « Assister » n'est pas rendu et
/// `/tc/observation` dit « pas encore disponible ». L'administration et le
/// controle qualite ne sont pas concernes.
final Provider<bool> observationTuteurReelleProvider = Provider<bool>(
  (Ref ref) => Env.observationTuteurReelleActive,
);
