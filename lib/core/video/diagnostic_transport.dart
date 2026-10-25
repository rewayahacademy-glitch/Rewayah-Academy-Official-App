// Lot salle 3, audit reseau du 25/10/2026 (decision du pilote, point d) : le
// diagnostic du transport de la salle. A la connexion, puis a chaque
// changement de qualite du lien : la paire de candidats choisie (hote,
// reflexif, relais ; UDP ou TCP), le temps d'aller-retour et les pertes, lus
// dans les statistiques WebRTC des deux transports. Toutes les 10 s : les
// statistiques des pistes que le SDK publie deja (gigue, pertes, aller-retour,
// limite de qualite). Envoye en miettes « salle.transport » a la supervision
// et au journal de developpement ; **aucune identite**, aucun identifiant de
// personne : seul le nom opaque de la salle accompagne les mesures. Rien de
// visible en salle.
//
// LIMITE : sur Flutter web, les statistiques passent par dart_webrtc 1.8.2 ;
// leur lecture n'est pas prouvee ici (tests sur des rapports simules), et un
// navigateur peut ne pas rendre tous les champs. Un champ absent reste
// simplement absent de la miette.

import 'dart:async';

import 'package:livekit_client/livekit_client.dart' as lk;

import '../observabilite/journal_dev.dart';
import '../observabilite/supervision.dart';

/// Un rapport de statistiques WebRTC, tel que `getStats` le rend : son
/// identifiant, son type (`candidate-pair`, `local-candidate`, ...) et ses
/// valeurs.
typedef RapportStats = ({
  String id,
  String type,
  Map<Object?, Object?> valeurs,
});

/// La categorie des miettes du transport.
const String categorieTransport = 'salle.transport';

/// Resume la paire de candidats choisie et les pertes d'un jeu de rapports.
///
/// La paire choisie : celle que nomme le rapport `transport`
/// (`selectedCandidatePairId`), sinon une `candidate-pair` marquee `selected`,
/// sinon une paire nominee et reussie. Les pertes : la somme des
/// `packetsLost` des rapports `inbound-rtp` et `remote-inbound-rtp`.
Map<String, Object?> resumerTransport(List<RapportStats> rapports) {
  final Map<String, RapportStats> parId = <String, RapportStats>{
    for (final RapportStats r in rapports) r.id: r,
  };
  String? paireId;
  for (final RapportStats r in rapports) {
    if (r.type == 'transport' &&
        r.valeurs['selectedCandidatePairId'] is String) {
      paireId = r.valeurs['selectedCandidatePairId']! as String;
    }
  }
  if (paireId == null) {
    for (final RapportStats r in rapports) {
      if (r.type == 'candidate-pair' && r.valeurs['selected'] == true) {
        paireId = r.id;
      }
    }
  }
  if (paireId == null) {
    for (final RapportStats r in rapports) {
      if (r.type == 'candidate-pair' &&
          r.valeurs['nominated'] == true &&
          r.valeurs['state'] == 'succeeded') {
        paireId = r.id;
      }
    }
  }
  final RapportStats? paire = paireId == null ? null : parId[paireId];
  final Object? localId = paire?.valeurs['localCandidateId'];
  final RapportStats? local = localId is String ? parId[localId] : null;
  num pertes = 0;
  bool pertesLues = false;
  for (final RapportStats r in rapports) {
    final Object? perdus = r.valeurs['packetsLost'];
    if ((r.type == 'inbound-rtp' || r.type == 'remote-inbound-rtp') &&
        perdus is num) {
      pertes += perdus;
      pertesLues = true;
    }
  }
  return <String, Object?>{
    'candidat': local?.valeurs['candidateType'],
    'protocole': local?.valeurs['protocol'],
    'protocoleRelais': local?.valeurs['relayProtocol'],
    'allerRetour': paire?.valeurs['currentRoundTripTime'],
    if (pertesLues) 'paquetsPerdus': pertes,
  }..removeWhere((String _, Object? v) => v == null);
}

/// Le diagnostic d'une entree en salle : il suit les pistes, echantillonne
/// leurs statistiques toutes les [intervalle], et lit les transports a la
/// demande. [arreter] a la sortie.
class DiagnosticTransport {
  /// Cree le diagnostic de la salle [salleOpaque] (le nom de salle du jeton,
  /// opaque : jamais l'identite d'une personne).
  DiagnosticTransport({
    required this.salleOpaque,
    this.intervalle = const Duration(seconds: 10),
  }) {
    _minuterie = Timer.periodic(intervalle, (Timer _) => _echantillonner());
  }

  /// Le nom opaque de la salle.
  final String salleOpaque;

  /// La periode d'echantillonnage des statistiques des pistes.
  final Duration intervalle;

  Timer? _minuterie;
  final List<lk.EventsListener<lk.TrackEvent>> _ecouteurs =
      <lk.EventsListener<lk.TrackEvent>>[];

  /// Les dernieres mesures par genre de piste (`audioEnvoi`, `videoRecue`,
  /// ...), remplacees a chaque evenement du SDK, envoyees a l'echantillon.
  final Map<String, Map<String, Object?>> _dernieres =
      <String, Map<String, Object?>>{};

  /// Suit les statistiques que le SDK publie pour [piste].
  void suivrePiste(lk.Track piste) {
    final lk.EventsListener<lk.TrackEvent> ecouteur = piste.createListener();
    _ecouteurs.add(ecouteur);
    ecouteur
      ..on<lk.AudioSenderStatsEvent>(
        (lk.AudioSenderStatsEvent e) =>
            _dernieres['audioEnvoi'] = <String, Object?>{
              'gigue': e.stats.jitter,
              'paquetsPerdus': e.stats.packetsLost,
              'allerRetour': e.stats.roundTripTime,
            },
      )
      ..on<lk.VideoSenderStatsEvent>((lk.VideoSenderStatsEvent e) {
        // Une valeur par couche (simulcast) : la plus limitee l'emporte.
        for (final s in e.stats.values) {
          _dernieres['videoEnvoi'] = <String, Object?>{
            'paquetsPerdus': s.packetsLost,
            'allerRetour': s.roundTripTime,
            'limite': s.qualityLimitationReason,
          };
        }
      })
      ..on<lk.AudioReceiverStatsEvent>(
        (lk.AudioReceiverStatsEvent e) =>
            _dernieres['audioRecu'] = <String, Object?>{
              'gigue': e.stats.jitter,
              'paquetsPerdus': e.stats.packetsLost,
            },
      )
      ..on<lk.VideoReceiverStatsEvent>(
        (lk.VideoReceiverStatsEvent e) =>
            _dernieres['videoRecue'] = <String, Object?>{
              'gigue': e.stats.jitter,
              'paquetsPerdus': e.stats.packetsLost,
            },
      );
  }

  void _echantillonner() {
    if (_dernieres.isEmpty) return;
    signalerTransport('pistes', <String, Object?>{
      'salle': salleOpaque,
      for (final MapEntry<String, Map<String, Object?>> e in _dernieres.entries)
        for (final MapEntry<String, Object?> m in e.value.entries)
          if (m.value != null) '${e.key}.${m.key}': m.value,
    });
    _dernieres.clear();
  }

  /// Lit les statistiques des deux transports de [salle] et envoie la paire
  /// de candidats choisie, a la connexion ou quand la qualite change
  /// ([motif]). Une lecture impossible est journalisee, jamais levee.
  Future<void> lireTransports(lk.Room salle, String motif) async {
    // Lu par les pistes (emetteur, recepteur) : leurs statistiques portent
    // aussi la paire de candidats et le transport. Le type des rapports vient
    // de `flutter_webrtc`, dependance indirecte : il n'est pas nomme
    // (`pubspec.yaml` n'est pas a modifier), l'inference le porte.
    lk.Track? envoi;
    for (final lk.TrackPublication<lk.Track> p
        in salle.localParticipant?.trackPublications.values ??
            const <lk.TrackPublication<lk.Track>>[]) {
      envoi ??= p.track;
    }
    lk.Track? reception;
    for (final lk.RemoteParticipant distant
        in salle.remoteParticipants.values) {
      for (final lk.TrackPublication<lk.Track> p
          in distant.trackPublications.values) {
        reception ??= p.track;
      }
    }
    final emetteur = envoi?.sender;
    final recepteur = reception?.receiver;
    final List<(String, Future<List<RapportStats>> Function())> lecteurs =
        <(String, Future<List<RapportStats>> Function())>[
          if (emetteur != null)
            (
              'envoi',
              () async => <RapportStats>[
                for (final r in await emetteur.getStats())
                  (
                    id: r.id,
                    type: r.type,
                    valeurs: Map<Object?, Object?>.from(r.values),
                  ),
              ],
            ),
          if (recepteur != null)
            (
              'reception',
              () async => <RapportStats>[
                for (final r in await recepteur.getStats())
                  (
                    id: r.id,
                    type: r.type,
                    valeurs: Map<Object?, Object?>.from(r.values),
                  ),
              ],
            ),
        ];
    for (final (String nom, Future<List<RapportStats>> Function() lire)
        in lecteurs) {
      try {
        final Map<String, Object?> resume = resumerTransport(await lire());
        signalerTransport('transport', <String, Object?>{
          'salle': salleOpaque,
          'motif': motif,
          'sens': nom,
          ...resume,
        });
      } on Object catch (e) {
        journalDev('salle.transport : statistiques $nom illisibles : $e');
      }
    }
  }

  /// Arrete l'echantillonnage et les ecouteurs (sortie de la salle).
  Future<void> arreter() async {
    _minuterie?.cancel();
    _minuterie = null;
    for (final lk.EventsListener<lk.TrackEvent> e in _ecouteurs) {
      await e.dispose();
    }
    _ecouteurs.clear();
    _dernieres.clear();
  }
}

/// Envoie une mesure du transport : au journal de developpement (debug), et en
/// miette « salle.transport » a la supervision. [donnees] ne porte jamais
/// d'identite.
void signalerTransport(String evenement, Map<String, Object?> donnees) {
  journalDev('$categorieTransport $evenement $donnees');
  Supervision.miette(
    categorie: categorieTransport,
    message: evenement,
    donnees: donnees,
  );
}
