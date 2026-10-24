// S1 (24/10/2026, plan de nuit du pilote) : la synchronisation reelle de la
// salle. Ce que l'enseignant ecrit sur la page arrive chez chaque eleve.
//
// Rien de neuf, tout est raccorde : le transport est
// [AdaptateurTransportLiveKit] (canal de donnees du seul moteur de la salle),
// le protocole [ServiceRealtimePedagogique], l'emission [DiffusionOutils],
// la reception [ReceptionOutils], le depot [AnnotationsMemoire] que la surface
// relit deja (`notesDeposeesProvider`). Aucune table : les traits vivent le
// temps de la seance, sur chaque appareil.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset;

import '../../core/observabilite/journal_dev.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/reception_outils.dart';
import '../../core/tc_realtime/adaptateur_transport_livekit.dart';
import '../../core/tc_realtime/port_realtime_pedagogique.dart';
import '../../core/tc_realtime/service_realtime_pedagogique.dart';
import '../../core/video/video_session_provider.dart';

/// S1 : le type du message du pointeur de l'enseignant (point normalise de
/// la page, canal ephemere). `EvenementPointeur` porte une position dans le
/// texte, pas un point de la page : il reste tel quel.
const String typePointeurSalle = 'tc.salle.pointeur';

/// Les pieces de la synchronisation d'une seance, creees a l'entree dans la
/// salle et liberees a la sortie.
class SynchroSalle {
  /// Raccorde la salle [sessionId] au moteur, pour le profil [profilLocalId].
  factory SynchroSalle({
    required VideoSessionProvider moteur,
    required AccesSalle acces,
    required String sessionId,
    required String profilLocalId,
  }) {
    final AdaptateurTransportLiveKit transport = AdaptateurTransportLiveKit(
      moteur: moteur,
      acces: acces,
      profilLocalId: profilLocalId,
    );
    final ServiceRealtimePedagogique realtime = ServiceRealtimePedagogique(
      transport,
    );
    final AnnotationsMemoire depot = AnnotationsMemoire(profilLocalId);
    return SynchroSalle._(
      sessionId: sessionId,
      transport: transport,
      depot: depot,
      diffusion: DiffusionOutils(
        realtime,
        sessionId: sessionId,
        emetteurProfilId: profilLocalId,
      ),
      reception: ReceptionOutils(
        realtime,
        sessionId: sessionId,
        profilLocalId: profilLocalId,
        depot: depot,
      ),
      realtime: realtime,
      profilLocalId: profilLocalId,
      peutDiffuser: acces.capacites.peutPublierDonnees,
    );
  }

  SynchroSalle._({
    required this.sessionId,
    required this.depot,
    required this._transport,
    required this._diffusion,
    required this._reception,
    required this._realtime,
    required this.profilLocalId,
    required this._peutDiffuser,
  }) {
    _abonnementPointeur = _realtime
        .messagesEphemeres(sessionId)
        .listen(_recevoirPointeur, onError: (Object _) {});
  }

  /// Le profil de cet appareil.
  final String profilLocalId;

  final ServiceRealtimePedagogique _realtime;
  late final StreamSubscription<MessagePedagogique> _abonnementPointeur;

  /// Le pointeur de l'enseignant tel que la classe le recoit (point
  /// normalise de la page), `null` quand il se leve.
  final ValueNotifier<Offset?> pointeurDistant = ValueNotifier<Offset?>(null);

  void _recevoirPointeur(MessagePedagogique message) {
    if (message.type != typePointeurSalle ||
        message.emetteurProfilId == profilLocalId) {
      return;
    }
    final num? x = message.charge['x'] as num?;
    final num? y = message.charge['y'] as num?;
    pointeurDistant.value = x == null || y == null
        ? null
        : Offset(x.toDouble().clamp(0, 1), y.toDouble().clamp(0, 1));
  }

  /// Le rappel de `diffusionPointeurProvider` : le point part a la classe
  /// sur le canal ephemere (perte acceptee, jamais conserve).
  void Function(Offset?)? get diffuserPointeur => _peutDiffuser
      ? (Offset? point) => unawaited(
          _realtime
              .emettre(
                MessagePedagogique(
                  type: typePointeurSalle,
                  sessionId: sessionId,
                  emetteurProfilId: profilLocalId,
                  charge: point == null
                      ? const <String, dynamic>{}
                      : <String, dynamic>{'x': point.dx, 'y': point.dy},
                  emisLeUtc: DateTime.now().toUtc(),
                ),
                canal: CanalFiabilite.ephemere,
              )
              .catchError(
                (Object e) => journalDev('pointeur non diffuse : $e'),
              ),
        )
      : null;

  /// La seance synchronisee.
  final String sessionId;

  /// Le depot local de la seance, que la surface relit.
  final AnnotationsMemoire depot;

  final AdaptateurTransportLiveKit _transport;
  final DiffusionOutils _diffusion;
  final ReceptionOutils _reception;
  final bool _peutDiffuser;

  /// Le rappel de `diffusionEcritureProvider` : l'evenement part a la classe
  /// (enseignant, jeton `can_publish_data`) ; un echec se journalise, le trait
  /// reste chez son auteur et la surface le marque non partage (TB-11b).
  void Function(EvenementOutil)? get diffuser => _peutDiffuser
      ? (EvenementOutil evenement) => unawaited(
          _diffusion
              .emettre(evenement)
              .catchError(
                (Object e) => journalDev('ecriture non diffusee : $e'),
              ),
        )
      : null;

  /// Libere la reception et le transport.
  @mustCallSuper
  Future<void> liberer() async {
    await _abonnementPointeur.cancel();
    pointeurDistant.dispose();
    await _reception.liberer();
    await _transport.liberer();
  }
}
