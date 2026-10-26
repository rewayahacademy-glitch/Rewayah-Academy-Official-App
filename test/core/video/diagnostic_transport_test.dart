import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/diagnostic_transport.dart';

/// Lot salle 3 (audit reseau du 25/10/2026) : le resume du transport lu dans
/// les rapports WebRTC, sans aucune identite.
void main() {
  test('relais TURN en TCP : candidat, protocoles, aller-retour, pertes', () {
    final Map<String, Object?> resume = resumerTransport(<RapportStats>[
      (
        id: 'T1',
        type: 'transport',
        valeurs: <Object?, Object?>{'selectedCandidatePairId': 'P1'},
      ),
      (
        id: 'P1',
        type: 'candidate-pair',
        valeurs: <Object?, Object?>{
          'localCandidateId': 'L1',
          'currentRoundTripTime': 0.412,
        },
      ),
      (
        id: 'L1',
        type: 'local-candidate',
        valeurs: <Object?, Object?>{
          'candidateType': 'relay',
          'protocol': 'udp',
          'relayProtocol': 'tcp',
          'address': '192.0.2.7',
        },
      ),
      (
        id: 'R1',
        type: 'inbound-rtp',
        valeurs: <Object?, Object?>{'packetsLost': 12},
      ),
      (
        id: 'R2',
        type: 'remote-inbound-rtp',
        valeurs: <Object?, Object?>{'packetsLost': 3},
      ),
    ]);
    expect(resume, <String, Object?>{
      'candidat': 'relay',
      'protocole': 'udp',
      'protocoleRelais': 'tcp',
      'allerRetour': 0.412,
      'paquetsPerdus': 15,
    });
    // Jamais une adresse ni une identite dans la miette.
    expect(resume.values, isNot(contains('192.0.2.7')));
  });

  test('sans rapport transport : la paire marquee selected, puis nominee', () {
    final Map<String, Object?> parSelected = resumerTransport(<RapportStats>[
      (
        id: 'P2',
        type: 'candidate-pair',
        valeurs: <Object?, Object?>{'selected': true, 'localCandidateId': 'L2'},
      ),
      (
        id: 'L2',
        type: 'local-candidate',
        valeurs: <Object?, Object?>{'candidateType': 'host', 'protocol': 'udp'},
      ),
    ]);
    expect(parSelected['candidat'], 'host');

    final Map<String, Object?> parNomination = resumerTransport(<RapportStats>[
      (
        id: 'P3',
        type: 'candidate-pair',
        valeurs: <Object?, Object?>{
          'nominated': true,
          'state': 'succeeded',
          'localCandidateId': 'L3',
        },
      ),
      (
        id: 'L3',
        type: 'local-candidate',
        valeurs: <Object?, Object?>{
          'candidateType': 'srflx',
          'protocol': 'tcp',
        },
      ),
    ]);
    expect(parNomination['candidat'], 'srflx');
    expect(parNomination['protocole'], 'tcp');
    expect(parNomination.containsKey('paquetsPerdus'), isFalse);
  });

  test('rien de lisible : un resume vide, jamais une erreur', () {
    expect(resumerTransport(const <RapportStats>[]), isEmpty);
  });
}
