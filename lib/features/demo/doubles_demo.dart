// NETTOYAGE-1 (11/11/2026) : les doubles qui ne servent qu'a la
// demonstration, sortis du code de production. Rien ici n'est atteint par
// l'application reelle.

import '../../core/accessibilite/port_demande_presentation.dart';
import '../admin_finance/vue_globale_finance.dart';
import '../revenus_enseignant/revenus_enseignant_page.dart';

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

/// Le mois choisi d'une demonstration, sous son conteneur imbrique : sans
/// session a surveiller (la session de l'application n'y est pas lue).
class MoisRevenusDemo extends MoisRevenus {
  @override
  DateTime? build() => null;
}

/// Le mois choisi d'une demonstration, sous son conteneur imbrique : sans
/// session a surveiller (la session de l'application n'y est pas lue).
class MoisVueGlobaleDemo extends MoisVueGlobale {
  @override
  DateTime? build() => null;
}
