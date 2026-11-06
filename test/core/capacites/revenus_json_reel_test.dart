// Pilote, 06/11/2026 (regression « Revenus estimes » en production : la
// fonction ne rendait plus base, plafond ni siegesEligibles, l'application
// les lisait encore). Ce test decode le JSON REEL des fonctions, capture sur
// un Postgres nu (main rejoue, migrations du lot appliquees) avec les fixtures
// de supabase/tests/scenarios_revenus_verite.sql (etat 20261110200000, celui
// de la production) et scenarios_autres_revenus.sql (etat 20261110210000) :
// test/fixtures/revenus/*.json, cles exactes, sans rien retoucher.
//
// Il prouve que l'application lit les deux etats du serveur (avant et apres
// 20261110210000) et ne depend d'aucune cle retiree.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/autres_revenus_supabase.dart';
import 'package:rewayah_academy/core/capacites/obligations_payables_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_autres_revenus.dart';
import 'package:rewayah_academy/core/capacites/port_revenus_enseignant.dart';
import 'package:rewayah_academy/core/capacites/revenus_enseignant_supabase.dart';

Map<String, dynamic> _lire(String nom) =>
    jsonDecode(File('test/fixtures/revenus/$nom.json').readAsStringSync())
        as Map<String, dynamic>;

/// Toutes les cles d'un JSON, a toute profondeur.
Set<String> _cles(Object? j) => <String>{
  if (j is Map<String, dynamic>)
    for (final MapEntry<String, dynamic> e in j.entries) ...<String>{
      e.key,
      ..._cles(e.value),
    },
  if (j is List<dynamic>)
    for (final Object? x in j) ..._cles(x),
};

const Set<String> _retirees = <String>{'base', 'plafond', 'siegesEligibles'};

void main() {
  group('mes_revenus_enseignant, JSON reel', () {
    for (final String etat in <String>['200000', '210000']) {
      final String nom = etat == '210000'
          ? 'mes_revenus_enseignant'
          : 'mes_revenus_enseignant_$etat';
      test('etat $etat : decode, aucune cle retiree, montants du serveur', () {
        final Map<String, dynamic> j = _lire(nom);
        expect(_cles(j).intersection(_retirees), isEmpty);
        final RevenusEnseignant r = RevenusEnseignantSupabase.decoderRevenus(j);
        expect(
          r.totalEstime.mineur,
          (j['totalEstime'] as Map<String, dynamic>)['mineur'],
        );
        expect(r.classes, hasLength((j['classes'] as List<dynamic>).length));
        expect(r.seances, hasLength((j['seances'] as List<dynamic>).length));
        expect(r.seances, isNotEmpty);
        expect(r.versement, isNotNull);
        if (etat == '200000') {
          expect(r.autres, isEmpty);
          expect(r.totalAutres, isNull);
        } else {
          expect(r.autres.map((AutreRevenu a) => a.nature), <NatureAutreRevenu>[
            NatureAutreRevenu.aideInternet,
            NatureAutreRevenu.mission,
          ]);
          expect(r.totalAutres?.mineur, 3500);
          expect(r.allocationInternet?.mineur, 1000);
        }
      });
    }
  });

  group('releve_paie_mensuel, JSON reel', () {
    test('etat 200000 : une obligation, montant du serveur', () {
      final Map<String, dynamic> j = _lire('releve_paie_mensuel_200000');
      final obligations = ObligationsPayablesSupabase.decoderReleve(j);
      expect(obligations, hasLength(1));
      expect(obligations.single.montant.mineur, 314);
    });
    test('etat 210000 : montant = seances + autres, enseignante sans seance '
        'presente', () {
      final Map<String, dynamic> j = _lire('releve_paie_mensuel');
      final obligations = ObligationsPayablesSupabase.decoderReleve(j);
      expect(
        <String, int>{
          for (final o in obligations)
            o.beneficiaire.id.substring(o.beneficiaire.id.length - 2):
                o.montant.mineur,
        },
        <String, int>{'b1': 3814, 'b2': 700},
      );
    });
  });

  group('releve_paie_seances, JSON reel', () {
    test('etat 200000 : une ligne par seance, total du serveur', () {
      final Map<String, dynamic> j = _lire('releve_paie_seances_200000');
      final o = ObligationsPayablesSupabase.decoderDetail(j);
      expect(o.lignes, hasLength((j['seances'] as List<dynamic>).length));
      expect(o.montant.mineur, 314);
    });
    test('etat 210000 : seances puis autres revenus, total du serveur', () {
      final Map<String, dynamic> j = _lire('releve_paie_seances');
      final o = ObligationsPayablesSupabase.decoderDetail(j);
      expect(
        o.lignes,
        hasLength(
          (j['seances'] as List<dynamic>).length +
              (j['autres'] as List<dynamic>).length,
        ),
      );
      expect(o.montant.mineur, 3814);
      expect(o.lignes.last.libelle, 'Remplacement du 12');
    });
  });

  test('autres_revenus_lister, JSON reel (210000)', () {
    final AutresRevenusMois m = AutresRevenusSupabase.decoder(
      _lire('autres_revenus_lister'),
    );
    expect(m.peutAttribuer, isTrue);
    expect(m.aideInternetPolitique, isNull);
    expect(m.lignes.map((AutreRevenu a) => a.montant.mineur), <int>[
      1000,
      2500,
    ]);
  });
}
