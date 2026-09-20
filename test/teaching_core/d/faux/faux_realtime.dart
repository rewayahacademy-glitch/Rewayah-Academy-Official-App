import 'dart:async';

import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';

/// Un transport pedagogique qui note ce qu'on lui confie.
///
/// Il ne simule ni LiveKit ni un reseau : le lot D n'a rien a prouver sur le
/// transport, il a a prouver **ce qu'il emet et sur quel canal**.
class FauxRealtime implements PortRealtimePedagogique {
  /// Les messages emis a toute la seance, dans l'ordre.
  final List<({MessagePedagogique message, CanalFiabilite canal})> emis =
      <({MessagePedagogique message, CanalFiabilite canal})>[];

  /// Les messages adresses a un seul participant.
  final List<({MessagePedagogique message, String destinataire})> cibles =
      <({MessagePedagogique message, String destinataire})>[];

  /// Les types emis, dans l'ordre. Raccourci de lecture des tests.
  List<String> get types => <String>[
    for (final ({MessagePedagogique message, CanalFiabilite canal}) envoi
        in emis)
      envoi.message.type,
  ];

  /// Les canaux employes, dans l'ordre.
  List<CanalFiabilite> get canaux => <CanalFiabilite>[
    for (final ({MessagePedagogique message, CanalFiabilite canal}) envoi
        in emis)
      envoi.canal,
  ];

  @override
  Stream<MessagePedagogique> messagesFiables(String sessionId) =>
      const Stream<MessagePedagogique>.empty();

  @override
  Stream<MessagePedagogique> messagesEphemeres(String sessionId) =>
      const Stream<MessagePedagogique>.empty();

  @override
  Future<void> emettre(
    MessagePedagogique message, {
    required CanalFiabilite canal,
  }) async => emis.add((message: message, canal: canal));

  @override
  Future<void> emettreCible(
    MessagePedagogique message, {
    required String destinataireProfilId,
    required CanalFiabilite canal,
  }) async => cibles.add((message: message, destinataire: destinataireProfilId));

  @override
  Future<CapacitesPedagogiques> capacites(String sessionId) async =>
      const CapacitesPedagogiques(
        peutPiloterSupport: true,
        peutAnnoter: true,
        peutEmettreNudge: true,
        estObservateurSilencieux: false,
      );
}
