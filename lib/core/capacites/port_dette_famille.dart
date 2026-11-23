// La dette de la famille (PAIEMENT-FAMILLE-ACCES, D7) : un port de lecture
// seule, a cote des finances du foyer. Le serveur (`ma_dette_famille()`)
// decide ; l'ecran n'ecrit rien et ne calcule rien.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/dette_famille.dart';
import '../session/session_controleur.dart';
import 'capacite_indisponible.dart';

/// La lecture de la dette de la famille.
abstract interface class PortDetteFamille {
  /// Les dettes ouvertes du foyer de la personne connectee.
  Future<DetteFamille> lire();
}

/// Aucune source : l'ecran ne montre rien (jamais une dette inventee).
class DetteFamilleIndisponible implements PortDetteFamille {
  /// Cree l'implementation.
  const DetteFamilleIndisponible();

  @override
  Future<DetteFamille> lire() =>
      Future<DetteFamille>.error(const CapaciteIndisponible('D7'));
}

/// Le port employe par l'application ; la demonstration le surcharge.
final Provider<PortDetteFamille> portDetteFamilleProvider =
    Provider<PortDetteFamille>((Ref _) => const DetteFamilleIndisponible());

/// La dette de la famille, relue a chaque ouverture de l'ecran.
final FutureProvider<DetteFamille> detteFamilleProvider =
    FutureProvider.autoDispose<DetteFamille>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portDetteFamilleProvider).lire();
    });
