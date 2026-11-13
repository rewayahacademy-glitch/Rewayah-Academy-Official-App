// Ce que la salle relaie sur le canal de donnees de la visio et que la barre
// lit, dans la salle comme dans la salle reduite (DYNAMIQUE-CHRONO-2,
// directeur, 12/11/2026, point 15 : « la barre doit etre exploitee au max
// quand la salle est reduite »). Ecrit une fois, lu par `salle_page.dart`,
// `SynchroSalle` et `BarreSeanceEnDirect`.

import 'dart:convert';

import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/tc_realtime/codec_message_pedagogique.dart';
import '../../core/tc_realtime/port_realtime_pedagogique.dart';
import '../../core/tc_realtime/types_message.dart';
import '../../core/video/video_session_provider.dart';

/// SITUATIONS-GRAVES (directeur, 11/11/2026, defaut n° 6) : le sujet du
/// paquet qui relaie la pause de la seance a la classe (canal fiable).
const String sujetPauseSalle = 'tc.salle.pause';

/// La charge du relais de pause : l'etat servi, sans aucune identite.
/// DYNAMIQUE-CHRONO-2 : aussi le motif (la pause de priere) et l'heure
/// annoncee (`proposerA`) ; un ancien poste les ignore.
Map<String, Object?> chargePause(PauseSeance pause) => <String, Object?>{
  'statut': pause.statut.name,
  'duree': pause.dureePrevueMinutes,
  'debut': pause.debutUtc?.toUtc().toIso8601String(),
  'fin': pause.finUtc?.toUtc().toIso8601String(),
  'debutPrevu': pause.debutPrevuUtc?.toUtc().toIso8601String(),
  if (pause.motif != MotifPause.ordinaire) 'motif': pause.motif.name,
  'proposerA': pause.proposerAUtc?.toUtc().toIso8601String(),
};

/// Lit un relais de pause, ou `null` s'il est illisible. Jamais de commande :
/// `peutPiloter` reste faux chez qui le recoit. Un message d'un ancien poste
/// (sans motif) se lit comme une pause ordinaire.
PauseSeance? pauseDepuisCharge(List<int> charge) {
  try {
    final Object? lu = jsonDecode(utf8.decode(charge));
    if (lu is! Map) return null;
    final StatutPause? statut = StatutPause.values
        .where((StatutPause s) => s.name == lu['statut'])
        .firstOrNull;
    final Object? duree = lu['duree'];
    if (statut == null ||
        duree is! int ||
        duree < BornesPause.dureeMin ||
        duree > BornesPause.dureeMax) {
      return null;
    }
    DateTime? instant(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toUtc() : null;
    return PauseSeance(
      statut: statut,
      dureePrevueMinutes: duree,
      debutUtc: instant(lu['debut']),
      finUtc: instant(lu['fin']),
      debutPrevuUtc: instant(lu['debutPrevu']),
      proposerAUtc: instant(lu['proposerA']),
      motif: lu['motif'] == MotifPause.priere.name
          ? MotifPause.priere
          : MotifPause.ordinaire,
    );
  } on Object {
    return null;
  }
}

/// Le rappel discret (30/10/2026) : [message] appelle cet appareil
/// ([profilLocalId]). Le paquet est adresse au seul eleve vise : le recevoir,
/// c'est etre appele ; on ignore le sien et un rappel sans eleve.
bool estRappelPour(MessagePedagogique message, String profilLocalId) =>
    message.type == typeRappelDiscret &&
    message.emetteurProfilId != profilLocalId &&
    academyIdDeCharge(message) != null;

/// Le meme rappel lu directement sur un paquet de la visio (salle reduite,
/// ou aucune synchronisation de la salle ne tourne).
bool paquetRappelPour(
  PaquetDonnees paquet, {
  required String sessionId,
  required String profilLocalId,
}) {
  if (paquet.sujet != sujetProtocolePedagogique || !paquet.fiable) {
    return false;
  }
  final MessagePedagogique? message = messageDepuisOctets(paquet.charge);
  return message != null &&
      message.sessionId == sessionId &&
      estRappelPour(message, profilLocalId);
}
