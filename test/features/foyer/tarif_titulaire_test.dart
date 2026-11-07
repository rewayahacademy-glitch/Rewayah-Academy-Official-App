// PROFIL-TITULAIRE (pilote, 07/11/2026) : le profil eleve du titulaire est
// recharge au tarif ADULTE, 65 $ par mois.
//
// Le tarif est calcule par le serveur (`private.fac_tarif_profil` : une fiche
// 'autonomous', celle que `creer_profil_eleve_titulaire` cree, prend
// `tarif_adulte_mineur`) et prouve sur une base reelle par
// `supabase/tests/scenarios_profil_titulaire_foyer.sql`. Ce test-ci attache
// cette preuve a la source unique des prix (DECISION-TARIFS-2026-10-18,
// `docs/current/tarifs-2026-10-18.json`) : si l'un des deux change sans
// l'autre, il rougit.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, dynamic> tarifs = jsonDecode(
    File('docs/current/tarifs-2026-10-18.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, dynamic> formules =
      tarifs['formules'] as Map<String, dynamic>;
  final int adulte =
      (formules['adulte'] as Map<String, dynamic>)['prix_mensuel_mineur']
          as int;
  final int enfant =
      (formules['enfant'] as Map<String, dynamic>)['prix_mensuel_mineur']
          as int;
  final String scenario = File(
    'supabase/tests/scenarios_profil_titulaire_foyer.sql',
  ).readAsStringSync();
  final String creation = File(
    'supabase/migrations/0052_profil_eleve_titulaire.sql',
  ).readAsStringSync();

  test('la source des prix : 65 \$ adulte, 55 \$ enfant, en USD', () {
    expect(tarifs['devise'], 'USD');
    expect(adulte, 6500);
    expect(enfant, 5500);
  });

  test('le profil eleve du titulaire est une fiche adulte autonome', () {
    // 0052 : student_type 'autonomous', cohorte 'adulte_18_plus'.
    expect(
      creation,
      contains(
        "(v_user, v_user, 'autonomous', 'standard', 'forbidden', "
        "'adulte_18_plus')",
      ),
    );
  });

  test('le scenario SQL exige le tarif adulte de la source pour le '
      'titulaire, jamais le tarif enfant', () {
    expect(
      scenario,
      contains("(f -> 'montant' ->> 'mineur')::bigint = $adulte"),
    );
    expect(scenario, contains('recharge : le titulaire au tarif adulte'));
    expect(scenario, contains('recharge : jamais le tarif enfant'));
    expect(
      scenario,
      contains("(f -> 'montant' ->> 'mineur')::bigint = $enfant"),
    );
  });
}
