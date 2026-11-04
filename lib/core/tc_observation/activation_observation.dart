import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

/// Vrai quand l'observation par le tuteur est ouverte cote client (contrat
/// K4).
///
/// **Toujours vrai depuis le lot O1 (02/11/2026)** hors demonstration : c'est
/// le serveur qui ouvre ou ferme (politique, quota, seance, acces paye) et qui
/// coupe la visite a la duree de la politique ([Env.observationTuteurReelleActive]).
/// Un ecran ne lit jamais `Env` directement, pour que les tests et la
/// demonstration puissent monter les deux cotes sans compilation dediee.
/// Faux (demonstration), le tuteur n'appelle aucune porte d'observation du
/// serveur : « Assister » n'est pas rendu et `/tc/observation` dit « pas
/// encore disponible ». L'administration et le controle qualite ne sont pas
/// concernes.
final Provider<bool> observationTuteurReelleProvider = Provider<bool>(
  (Ref ref) => Env.observationTuteurReelleActive,
);
