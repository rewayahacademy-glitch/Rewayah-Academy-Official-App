// REVENUS-VERITE point 5 : l'adaptateur des autres revenus (aide Internet,
// primes, missions). Decodage strict, sans calcul ; parametres envoyes.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/autres_revenus_supabase.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_autres_revenus.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _m(int mineur) => <String, Object?>{
  'mineur': mineur,
  'devise': 'USD',
};

void main() {
  test('lister : lignes, capacite et aide de la politique, lues telles '
      'quelles', () async {
    Map<String, dynamic>? recu;
    final AutresRevenusSupabase port = AutresRevenusSupabase.avecAppel((
      String fonction,
      Map<String, dynamic>? params,
    ) async {
      expect(fonction, 'autres_revenus_lister');
      recu = params;
      return <String, Object?>{
        'mois': '2026-11-01',
        'devise': 'USD',
        'peutAttribuer': true,
        'aideInternetPolitique': _m(1000),
        'lignes': <Object?>[
          <String, Object?>{
            'id': 'a1',
            'nature': 'aide_internet',
            'libelle': 'Aide Internet',
            'montant': _m(1000),
          },
          <String, Object?>{
            'id': 'a2',
            'nature': 'prime',
            'libelle': 'Prime',
            'montant': _m(500),
          },
        ],
      };
    });
    final AutresRevenusMois m = await port.lister('b1', DateTime(2026, 11, 17));
    expect(recu, <String, dynamic>{
      'p_enseignant': 'b1',
      'p_mois': '2026-11-01',
    });
    expect(m.peutAttribuer, isTrue);
    expect(m.aideInternetPolitique, const Montant(1000, 'USD'));
    expect(m.lignes.first.nature, NatureAutreRevenu.aideInternet);
    expect(m.lignes.last.montant, const Montant(500, 'USD'));
  });

  test('attribuer et annuler envoient les bons parametres', () async {
    final List<(String, Map<String, dynamic>?)> appels =
        <(String, Map<String, dynamic>?)>[];
    final AutresRevenusSupabase port = AutresRevenusSupabase.avecAppel((
      String f,
      Map<String, dynamic>? p,
    ) async {
      appels.add((f, p));
      return <String, Object?>{'id': 'a1', 'deja': false};
    });
    await port.attribuer(
      enseignantId: 'b1',
      mois: DateTime(2026, 11),
      nature: NatureAutreRevenu.mission,
      libelle: 'Remplacement du 12',
      montantMineur: 2500,
      cle: 'cle-unique-1',
    );
    await port.annuler('a1');
    expect(appels.first.$1, 'autre_revenu_attribuer');
    expect(appels.first.$2, <String, dynamic>{
      'p_enseignant': 'b1',
      'p_mois': '2026-11-01',
      'p_nature': 'mission',
      'p_libelle': 'Remplacement du 12',
      'p_montant_minor': 2500,
      'p_cle': 'cle-unique-1',
    });
    expect(appels.last.$1, 'autre_revenu_annuler');
    expect(appels.last.$2, <String, dynamic>{'p_id': 'a1'});
  });

  test('nature inconnue : FormatException, jamais une valeur completee', () {
    expect(
      () => AutresRevenusSupabase.ligne(<String, dynamic>{
        'id': 'a1',
        'nature': 'bonus',
        'libelle': 'x',
        'montant': _m(1),
      }),
      throwsFormatException,
    );
  });

  test('fonction absente du serveur : capacite indisponible', () async {
    final AutresRevenusSupabase port = AutresRevenusSupabase.avecAppel(
      (String f, Map<String, dynamic>? p) async =>
          throw const PostgrestException(message: 'x', code: 'PGRST202'),
    );
    await expectLater(
      port.lister('b1', DateTime(2026, 11)),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });
}
