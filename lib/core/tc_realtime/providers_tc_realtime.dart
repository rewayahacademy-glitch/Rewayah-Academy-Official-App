import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'port_realtime_pedagogique.dart';
import 'port_transport_donnees.dart';
import 'service_realtime_pedagogique.dart';
import 'transport_indisponible.dart';

/// Le transport de donnees de la salle courante.
///
/// **Le defaut est l'absence de salle**, et c'est la situation la plus
/// frequente du produit : le Groupe, la Bibliotheque et l'Accueil n'ont aucun
/// canal de donnees. [TransportIndisponible] dit non de facon nommee plutot que
/// de rester muet.
///
/// **C'est le seul point que la Classe Live doit surcharger.** A l'entree en
/// salle, Agent E remplace ce provider par un `AdaptateurTransportLiveKit`
/// construit sur le `AccesSalle` que `ServiceVideo.acces()` vient d'emettre et
/// sur `moteurSalleProvider` -- jamais sur une seconde `Room`. Tout le reste du
/// lot F suit sans changer une ligne.
///
/// Il n'est pas construit ici parce que le lot F n'a pas de quoi le construire :
/// l'acces est emis par le backend au moment de l'entree, et le lot F ne
/// demande pas de jeton. Un provider qui irait le chercher lui-meme ouvrirait
/// une seconde porte d'entree en salle.
final Provider<PortTransportDonnees> portTransportDonneesProvider =
    Provider<PortTransportDonnees>((Ref ref) => const TransportIndisponible());

/// Le protocole pedagogique de la seance courante.
///
/// Consomme par Agent D (`DiffusionOutils`), par Agent E (rappel discret, eleve
/// actif) et par Agent Q. Il suit le transport : surcharger
/// [portTransportDonneesProvider] suffit a le brancher.
final Provider<PortRealtimePedagogique> portRealtimePedagogiqueProvider =
    Provider<PortRealtimePedagogique>(
      (Ref ref) =>
          ServiceRealtimePedagogique(ref.watch(portTransportDonneesProvider)),
    );
