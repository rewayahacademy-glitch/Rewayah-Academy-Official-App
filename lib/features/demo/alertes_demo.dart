// Demonstration admin (ALERTE-1) : des alertes fictives, jamais en
// production (garde de `mode_demonstration.dart`), aucun appel serveur.

import 'dart:async';

import '../../core/alertes/alerte.dart';
import '../../core/alertes/port_alertes.dart';
import '../../core/router/routes.dart';

/// Les alertes de la demonstration, a quelques minutes de [maintenant].
///
/// L'alerte urgente n'est PAS la plus recente : la plus recente est une
/// information. L'ordre affiche prouve donc le tri par gravite d'abord.
List<Alerte> alertesDemo(DateTime maintenant) => <Alerte>[
  Alerte(
    id: 'demo-alerte-programme',
    gravite: GraviteAlerte.info,
    titre: 'Programme de la classe Al-Badr mis à jour',
    creeeLe: maintenant.subtract(const Duration(minutes: 5)),
    destination: Routes.adminPedagogieProgrammes,
  ),
  Alerte(
    id: 'demo-alerte-remplacement',
    gravite: GraviteAlerte.important,
    titre: 'Remplacement à confirmer pour la classe Al-Falaq',
    creeeLe: maintenant.subtract(const Duration(minutes: 40)),
    destination: Routes.adminOperationsGroupes,
  ),
  Alerte(
    id: 'demo-alerte-sans-enseignant',
    gravite: GraviteAlerte.urgent,
    titre: 'Classe An-Nour sans enseignant, séance dans 20 minutes',
    creeeLe: maintenant.subtract(const Duration(minutes: 25)),
    destination: Routes.adminOperationsGroupes,
  ),
  Alerte(
    id: 'demo-alerte-paiement',
    gravite: GraviteAlerte.important,
    titre: 'Paiement échu pour la famille Diallo',
    creeeLe: maintenant.subtract(const Duration(hours: 3)),
    destination: Routes.adminPersonnesComptesEchus,
  ),
];

/// L'alerte urgente qui « arrive » pendant la demonstration.
Alerte alerteArriveeDemo(DateTime maintenant) => Alerte(
  id: 'demo-alerte-incident',
  gravite: GraviteAlerte.urgent,
  titre: 'Incident signalé pendant la séance de la classe Al-Badr',
  creeeLe: maintenant,
);

/// La source des alertes de la demonstration admin.
///
/// Emet tout de suite [alertesDemo] ; avec [arrivee], emet ensuite la meme
/// liste augmentee d'une alerte urgente, comme le ferait le temps reel
/// (DASH-BR-04) : le bandeau, la cloche et le Centre de commande se mettent a
/// jour sans recharger.
class AlertesDemo implements PortAlertes {
  /// Cree la source.
  const AlertesDemo({this.arrivee, this.horloge = DateTime.now});

  /// Le delai avant l'arrivee d'une alerte urgente, ou `null` pour aucune.
  final Duration? arrivee;

  /// L'instant courant.
  final DateTime Function() horloge;

  @override
  Stream<List<Alerte>> suivre() {
    Timer? minuterie;
    late final StreamController<List<Alerte>> flux;
    flux = StreamController<List<Alerte>>(
      onListen: () {
        final List<Alerte> depart = alertesDemo(horloge());
        flux.add(depart);
        final Duration? delai = arrivee;
        if (delai != null) {
          minuterie = Timer(
            delai,
            () => flux.add(<Alerte>[...depart, alerteArriveeDemo(horloge())]),
          );
        }
      },
      // Quitter la demonstration annule l'arrivee : aucune minuterie ne
      // survit a l'ecran. La fermeture n'est pas attendue : rendre
      // `flux.close()` ferait attendre l'annulation sur la fin du flux, qui
      // attend l'annulation.
      onCancel: () {
        minuterie?.cancel();
        unawaited(flux.close());
      },
    );
    return flux.stream;
  }
}
