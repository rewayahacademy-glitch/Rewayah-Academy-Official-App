import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';

void main() {
  group('Une capacite indisponible se nomme sans s afficher', () {
    test('la dependance voyage avec l exception', () {
      const CapaciteIndisponible manque = CapaciteIndisponible('DB-CPT-03');

      expect(manque.dependance, 'DB-CPT-03');
      expect(manque, isA<Exception>());
      expect(manque.toString(), contains('DB-CPT-03'));
    });
  });

  group('Les seuils de temps de l interface', () {
    test('on dit que c est long avant de dire que c est perdu', () {
      expect(AppDelais.chargementProlonge, greaterThan(Duration.zero));
      expect(AppDelais.requeteMax, greaterThan(AppDelais.chargementProlonge));
    });
  });
}
