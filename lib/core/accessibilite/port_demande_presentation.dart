import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MA-8 : la demande de presentation standard d'un eleve mineur a son tuteur
// (decision du directeur du 27/09, S7 = b). Le tuteur recoit et accepte la
// demande cote serveur (BR-1, ligne MA-BR) ; sa page d'acceptation est MA-9.
//
// Aucun serveur ici : la demonstration et les tests posent un port neutre
// simule. Un echec ne dit jamais que la demande « n'a pas ete envoyee » : il
// dit seulement que l'envoi n'a pas ete confirme (D5).

/// Le port de la demande de presentation standard.
abstract interface class PortDemandePresentation {
  /// Envoie la demande au tuteur. Une erreur signifie « envoi non confirme ».
  Future<void> demanderPresentationStandard();
}

/// Le port neutre de la demonstration : aucune donnee ne quitte l'appareil.
class PortDemandePresentationDemo implements PortDemandePresentation {
  /// Cree le port ; [echoue] simule un envoi non confirme.
  const PortDemandePresentationDemo({this.echoue = false});

  /// Vrai pour simuler un envoi non confirme.
  final bool echoue;

  @override
  Future<void> demanderPresentationStandard() => echoue
      ? Future<void>.error(StateError('envoi non confirme (demonstration)'))
      : Future<void>.value();
}


/// Envoi réel MA-8; le serveur notifie le tuteur principal du foyer.
class DemandePresentationSupabase implements PortDemandePresentation {
  const DemandePresentationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<void> demanderPresentationStandard() async {
    await _client.rpc<void>('demander_presentation_standard');
  }
}

/// Port utilisé par l'application; surchargeable dans les tests/démonstrations.
final Provider<PortDemandePresentation> portDemandePresentationProvider =
    Provider<PortDemandePresentation>(
  (Ref ref) => DemandePresentationSupabase(Supabase.instance.client),
);
