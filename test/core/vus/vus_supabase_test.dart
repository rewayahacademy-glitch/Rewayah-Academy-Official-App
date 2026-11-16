// VU-UNE-FOIS : l'adaptateur appelle `lire_vus` et `marquer_vu`, et une
// fonction absente du serveur se dit indisponible.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/vus/vus_compte.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('lit les cles vues et marque une cle', () async {
    final List<String> appels = <String>[];
    final VusSupabase port = VusSupabase.avecAppel((
      String fonction,
      Map<String, dynamic>? params,
    ) async {
      appels.add('$fonction ${params ?? <String, dynamic>{}}');
      return fonction == 'lire_vus'
          ? <Object?>['bandeau.deux_cotes', '', 3]
          : true;
    });
    expect(await port.lire(), <String>{'bandeau.deux_cotes'});
    await port.marquer(ClesVu.deuxCotes);
    expect(appels, <String>[
      'lire_vus {}',
      'marquer_vu {p_cle: bandeau.deux_cotes}',
    ]);
  });

  test('une reponse qui n\'est pas une liste est refusee', () async {
    final VusSupabase port = VusSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async => 'oui',
    );
    await expectLater(port.lire(), throwsFormatException);
  });

  test('migration absente : capacite indisponible', () async {
    final VusSupabase port = VusSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async =>
          throw const PostgrestException(message: 'absente', code: 'PGRST202'),
    );
    await expectLater(port.lire(), throwsA(isA<CapaciteIndisponible>()));
    await expectLater(
      port.marquer(ClesVu.deuxCotes),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  test('la cle du bandeau respecte le format du serveur', () {
    expect(
      RegExp(r'^[a-z][a-z0-9_.-]{2,59}$').hasMatch(ClesVu.deuxCotes),
      isTrue,
    );
  });
}
