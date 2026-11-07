// FINANCE-ENSEIGNANT (06/11/2026) : l'adaptateur des versements de paie notes
// (migration 20261110710000).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_versements_paie.dart';
import 'package:rewayah_academy/core/capacites/versements_paie_supabase.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final Map<String, Object?> ligneDirection = <String, Object?>{
    'id': 'v1',
    'enseignant': 'e1',
    'prenom': 'Mamadou',
    'nom': 'Diallo',
    'montant': <String, Object?>{'mineur': 2587, 'devise': 'USD'},
    'verseLe': '2026-11-03',
    'mois': '2026-10-01',
    'moyen': 'mobile_money',
    'reference': 'OM-2026-11-0042',
    'note': 'paie d octobre',
    'saisiLe': '2026-11-03T10:00:00Z',
    'annuleLe': null,
    'annuleMotif': null,
  };

  test('noter envoie les valeurs saisies, sans calcul', () async {
    late String fonction;
    late Map<String, dynamic> params;
    final VersementsPaieSupabase port = VersementsPaieSupabase.avecAppel((
      String f,
      Map<String, dynamic>? p,
    ) async {
      fonction = f;
      params = p!;
      return ligneDirection;
    });
    final VersementPaie v = await port.noter(
      VersementANoter(
        enseignantId: 'e1',
        montant: const Montant(2587, 'USD'),
        verseLe: DateTime(2026, 11, 3),
        mois: DateTime(2026, 10),
        moyen: MoyenVersement.mobileMoney,
        cle: 'c1',
        reference: 'OM-2026-11-0042',
      ),
    );
    expect(fonction, 'versement_paie_noter');
    expect(params['p_montant_minor'], 2587);
    expect(params['p_devise'], 'USD');
    expect(params['p_verse_le'], '2026-11-03');
    expect(params['p_mois'], '2026-10-01');
    expect(params['p_moyen'], 'mobile_money');
    expect(params['p_cle'], 'c1');
    expect(v.enseignantNom, 'Mamadou Diallo');
    expect(v.annule, isFalse);
    expect(v.montant.mineur, 2587);
  });

  test('l\'enseignant lit ses versements, annule compris', () async {
    final VersementsPaieSupabase port = VersementsPaieSupabase.avecAppel(
      (String f, Map<String, dynamic>? p) async => <Object?>[
        <String, Object?>{
          'id': 'v1',
          'montant': <String, Object?>{'mineur': 250000, 'devise': 'GNF'},
          'verseLe': '2026-11-03',
          'mois': '2026-10-01',
          'moyen': 'virement_bancaire',
          'reference': null,
          'annule': true,
        },
      ],
    );
    final List<VersementPaie> l = await port.mesVersements();
    expect(l.single.annule, isTrue);
    expect(l.single.moyen, MoyenVersement.virementBancaire);
    expect(l.single.note, isNull);
  });

  test('fonction absente : capacite indisponible', () async {
    final VersementsPaieSupabase port = VersementsPaieSupabase.avecAppel(
      (String f, Map<String, dynamic>? p) async =>
          throw const PostgrestException(message: 'absente', code: 'PGRST202'),
    );
    await expectLater(
      port.versementsDirection(),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  test('refus du serveur : remonte tel quel', () async {
    final VersementsPaieSupabase port = VersementsPaieSupabase.avecAppel(
      (String f, Map<String, dynamic>? p) async =>
          throw const PostgrestException(message: 'refus', code: '42501'),
    );
    await expectLater(
      port.annuler(versementId: 'v1', motif: 'erreur'),
      throwsA(isA<PostgrestException>()),
    );
  });
}
