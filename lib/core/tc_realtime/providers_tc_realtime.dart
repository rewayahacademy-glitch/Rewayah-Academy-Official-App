import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controleur.dart';
import '../tc_classe/session_persistante.dart';
import '../video/livekit_session_provider.dart';
import '../video/video_session_provider.dart';
import 'adaptateur_transport_livekit.dart';
import 'port_realtime_pedagogique.dart';
import 'port_transport_donnees.dart';
import 'service_realtime_pedagogique.dart';
import 'transport_indisponible.dart';

/// Le transport de donnees de la salle courante.
///
/// **Il suit la session persistante, et elle seule.** Hors salle -- le Groupe,
/// la Bibliotheque, l'Accueil -- [TransportIndisponible] dit non de facon
/// nommee. Des que `ControleurSessionPersistante` a obtenu un `AccesSalle`,
/// le transport devient l'adaptateur pose sur `moteurSalleProvider` -- jamais
/// sur une seconde `Room`. C'est le point de surcharge que le lot F avait
/// reserve a la Classe Live ; il est tenu ici, une fois, plutot que dans un
/// `ProviderScope` imbrique que chaque ecran de salle devrait reposer.
///
/// L'identite locale est lue **a l'usage et sous garde** : un conteneur de
/// test sans backend n'a pas de `sessionProvider` utilisable, et une salle de
/// test doit quand meme pouvoir transporter. Sans identite, les capacites
/// signees du jeton continuent de decider ; seul le champ d'emetteur des
/// messages est vide.
final Provider<PortTransportDonnees> portTransportDonneesProvider =
    Provider<PortTransportDonnees>((Ref ref) {
      final AccesSalle? acces = ref.watch(
        etatSessionProvider.select(
          (AsyncValue<EtatSessionPersistante> e) => e.value?.acces,
        ),
      );
      if (acces == null) {
        return const TransportIndisponible();
      }
      String profil = '';
      try {
        profil = ref.read(sessionProvider).profileId ?? '';
      } on Object {
        // Sans session lisible, l'emetteur reste anonyme : le droit d'emettre
        // est de toute facon celui du jeton signe.
      }
      final AdaptateurTransportLiveKit transport = AdaptateurTransportLiveKit(
        moteur: ref.watch(moteurSalleProvider),
        acces: acces,
        profilLocalId: profil,
      );
      ref.onDispose(() => unawaited(transport.liberer()));
      return transport;
    });

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
