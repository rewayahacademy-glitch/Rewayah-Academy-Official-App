// Lot ouverture rapide (29/10/2026) : les polices arabes et du Coran ne se
// chargent a la demande que si le manifeste des polices ne les declare pas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/polices_differees.dart';

class _Paquet extends CachingAssetBundle {
  _Paquet(this.manifeste);

  final List<Map<String, Object?>> manifeste;
  final List<String> lus = <String>[];

  @override
  Future<ByteData> load(String key) async {
    lus.add(key);
    if (key == 'FontManifest.json') {
      final Uint8List octets = utf8.encode(jsonEncode(manifeste));
      return ByteData.sublistView(octets);
    }
    return ByteData.sublistView(File(key).readAsBytesSync());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('declarees dans le manifeste : rien n est charge', () async {
    final _Paquet paquet = _Paquet(<Map<String, Object?>>[
      for (final String famille in policesDifferees.keys)
        <String, Object?>{'family': famille},
    ]);
    expect(await chargerPolicesDifferees(paquet: paquet), isEmpty);
    expect(paquet.lus, <String>['FontManifest.json']);
  });

  test('absentes du manifeste : chargees depuis leurs fichiers', () async {
    final _Paquet paquet = _Paquet(<Map<String, Object?>>[
      <String, Object?>{'family': 'PlusJakartaSans'},
    ]);
    expect(
      await chargerPolicesDifferees(paquet: paquet),
      policesDifferees.keys.toList(),
    );
    expect(paquet.lus, containsAll(policesDifferees.values));
  });

  test('chaque fichier existe dans le depot', () {
    for (final String chemin in policesDifferees.values) {
      expect(File(chemin).existsSync(), isTrue, reason: chemin);
    }
  });
}
