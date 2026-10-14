import 'package:flutter/foundation.dart';

/// Journal de developpement, muet hors mode debug (revue P2-11, M1).
///
/// Les messages passes ici portent souvent le texte d'une exception, parfois
/// une reponse serveur ou une saisie : ils ne doivent pas atteindre la console
/// d'un appareil en profil ou en production. `debugPrint` seul ecrit dans
/// tous les modes ; cette fonction n'ecrit que sous [kDebugMode], et rien
/// ailleurs. Aucun comportement fonctionnel n'en depend.
void journalDev(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
