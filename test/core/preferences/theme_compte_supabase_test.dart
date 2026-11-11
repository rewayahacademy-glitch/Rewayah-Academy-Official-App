// PREFERENCES-PAR-COMPTE : l'adaptateur du theme du compte appelle les deux
// RPC de la migration 20261123200000, et une fonction absente du serveur se
// dit indisponible.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/preferences/theme_compte_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('lit et regle le theme par les deux RPC', () async {
    final List<String> appels = <String>[];
    final ThemeCompteSupabase port = ThemeCompteSupabase.avecAppel((
      String fonction,
      Map<String, dynamic>? params,
    ) async {
      appels.add('$fonction ${params ?? <String, dynamic>{}}');
      return fonction == 'ma_preference_theme' ? 'sombre' : null;
    });
    expect(await port.lire(), 'sombre');
    await port.regler('clair');
    expect(appels, <String>[
      'ma_preference_theme {}',
      'ma_preference_theme_regler {p_theme: clair}',
    ]);
  });

  test('une reponse vide est refusee', () async {
    final ThemeCompteSupabase port = ThemeCompteSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async => null,
    );
    await expectLater(port.lire(), throwsFormatException);
  });

  test('migration absente : capacite indisponible', () async {
    final ThemeCompteSupabase port = ThemeCompteSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) async =>
          throw const PostgrestException(message: 'absente', code: 'PGRST202'),
    );
    await expectLater(port.lire(), throwsA(isA<CapaciteIndisponible>()));
  });
}
