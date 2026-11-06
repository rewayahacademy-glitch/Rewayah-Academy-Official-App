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

  test('absentes du manifeste : celles du Coran apres la premiere image, '
      'jamais la police arabe d interface', () async {
    final _Paquet paquet = _Paquet(<Map<String, Object?>>[
      <String, Object?>{'family': 'PlusJakartaSans'},
    ]);
    expect(await chargerPolicesDifferees(paquet: paquet), <String>[
      'UthmanicHafs',
      'UthmanTahaNaskh',
    ]);
    expect(paquet.lus, isNot(contains(policesDifferees[policeArabeInterface])));
  });

  test('la police arabe se charge a la demande, une seule fois', () async {
    oublierPoliceArabe();
    addTearDown(oublierPoliceArabe);
    final _Paquet paquet = _Paquet(<Map<String, Object?>>[
      <String, Object?>{'family': 'PlusJakartaSans'},
    ]);
    expect(await chargerPoliceArabe(paquet: paquet), <String>[
      policeArabeInterface,
    ]);
    expect(await chargerPoliceArabe(paquet: paquet), <String>[
      policeArabeInterface,
    ]);
    expect(
      paquet.lus
          .where((String c) => c == policesDifferees[policeArabeInterface])
          .length,
      1,
    );
    expect(paquet.lus, isNot(contains('assets/fonts/UthmanicHafs-v-3.0.ttf')));
  });

  test(
    'declaree dans le manifeste : la police arabe n est pas rechargee',
    () async {
      oublierPoliceArabe();
      addTearDown(oublierPoliceArabe);
      final _Paquet paquet = _Paquet(<Map<String, Object?>>[
        <String, Object?>{'family': policeArabeInterface},
      ]);
      expect(await chargerPoliceArabe(paquet: paquet), isEmpty);
    },
  );

  test('chaque fichier existe dans le depot', () {
    for (final String chemin in policesDifferees.values) {
      expect(File(chemin).existsSync(), isTrue, reason: chemin);
    }
  });
}
