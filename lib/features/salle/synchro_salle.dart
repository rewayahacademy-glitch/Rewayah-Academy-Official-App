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

import '../../core/observabilite/journal_dev.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/reception_outils.dart';
import '../../core/tc_realtime/adaptateur_transport_livekit.dart';
import '../../core/tc_realtime/service_realtime_pedagogique.dart';
import '../../core/video/video_session_provider.dart';

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
      peutDiffuser: acces.capacites.peutPublierDonnees,
    );
  }

  SynchroSalle._({
    required this.sessionId,
    required this.depot,
    required this._transport,
    required this._diffusion,
    required this._reception,
    required this._peutDiffuser,
  });

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
    await _reception.liberer();
    await _transport.liberer();
  }
}
