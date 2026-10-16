import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/selecteur_support.dart';

void main() {
  test('le descriptif d upload porte le SHA-256 des octets choisis', () {
    final FichierChoisi fichier = FichierChoisi(
      nom: 'manuel.pdf',
      octets: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2d]),
      mime: 'application/pdf',
    );

    expect(
      fichier.descriptif.sha256,
      sha256.convert(fichier.octets).toString(),
    );
    expect(fichier.descriptif.octets, fichier.octets.length);
  });
}
