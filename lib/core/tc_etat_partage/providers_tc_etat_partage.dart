import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tc_realtime/providers_tc_realtime.dart';
import 'etat_partage_memoire.dart';
import 'port_etat_partage.dart';
import 'port_etat_partage_persistant.dart';
import 'service_etat_partage.dart';

/// La persistance de l'etat partage.
///
/// **Le defaut est un bouchon en memoire, et il est declare comme tel.** La
/// table `session_shared_content` n'existe pas : la migration est interdite en
/// phase parallele (decision D-12) et la demande SQL est ecrite dans
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_F.md`.
///
/// Consequence honnete tant qu'Agent Z n'a pas applique cette migration : un
/// arrivant tardif **sur un autre appareil** ne recupere rien, puisque le
/// magasin ne survit pas au processus. Le protocole, lui, est complet et
/// prouve ; c'est sa seule dependance manquante.
final Provider<PortEtatPartagePersistant> portEtatPartagePersistantProvider =
    Provider<PortEtatPartagePersistant>((Ref ref) => EtatPartageMemoire());

/// L'etat partage de la classe.
///
/// Consomme par Agent C (mode classe et focus), Agent D (ancrage des outils),
/// Agent E (coque de Classe Live) et Agent Q.
final Provider<PortEtatPartage> portEtatPartageProvider =
    Provider<PortEtatPartage>((Ref ref) {
      final ServiceEtatPartage service = ServiceEtatPartage(
        realtime: ref.watch(portRealtimePedagogiqueProvider),
        persistance: ref.watch(portEtatPartagePersistantProvider),
        etatsTransport: ref.watch(portTransportDonneesProvider).etats(),
      );
      ref.onDispose(() => unawaited(service.liberer()));
      return service;
    });
