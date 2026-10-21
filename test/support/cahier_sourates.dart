// FORM-L9 : un cahier de transmission de demonstration avec la liste des
// sourates telle que la migration `0013_corpus_coranique.sql` l'insere (la
// donnee du depot, jamais une liste recopiee).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart'
    show portCorpusCoranProvider;
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../capture/outil_capture.dart';
import 'harnais.dart';

/// Les sourates telles que la migration `0013` les insere.
List<SourateVM> souratesDeLaMigration() {
  final String sql = File('supabase/migrations/0013_corpus_coranique.sql')
      .readAsStringSync();
  final RegExp ligne = RegExp(
    r"^\s*\((\d+), '((?:[^']|'')+)', '((?:[^']|'')+)', '(mecque|medine)', "
    r'(\d+)\)',
    multiLine: true,
  );
  return <SourateVM>[
    for (final RegExpMatch m in ligne.allMatches(sql))
      SourateVM(
        numero: int.parse(m.group(1)!),
        nomArabe: m.group(2)!.replaceAll("''", "'"),
        nomTranslittere: m.group(3)!.replaceAll("''", "'"),
        mecquoise: m.group(4) == 'mecque',
        nombreVersets: int.parse(m.group(5)!),
      ),
  ];
}

/// Un corpus qui ne rend que la liste des sourates (ou echoue).
class CorpusSourates implements PortCorpusCoran {
  /// Cree le corpus.
  CorpusSourates(this.liste, {this.echoue = false});

  /// Les sourates rendues.
  final List<SourateVM> liste;

  /// Vrai pour simuler une lecture impossible.
  final bool echoue;

  @override
  Future<List<SourateVM>> sourates() async {
    if (echoue) throw const EchecCorpusCoran('lecture impossible');
    return liste;
  }

  @override
  Future<PageCorpus?> page(int numeroPage) async => null;

  @override
  Future<PageCorpus?> pageDeAyah({
    required int sourate,
    required int ayah,
  }) async => null;

  @override
  Future<int?> pageDeDebutDeSourate(int sourate) async => null;

  @override
  Future<int?> pageDeDebutDeJuz(int juz) async => null;

  @override
  Future<List<ResultatRechercheCoran>> rechercher(String requete) async =>
      const <ResultatRechercheCoran>[];
}

/// Monte le cahier de demonstration avec un corpus de sourates.
Future<void> monterCahier(
  WidgetTester tester,
  PortCorpusCoran corpus, {
  Size taille = const Size(390, 2200),
  double densite = 1,
  ThemeMode mode = ThemeMode.light,
  double echelleTexte = 1,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(
    hoteCapture(
      themeMode: mode,
      echelleTexte: echelleTexte,
      const CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: EtatDemoEnseignant.nominal,
      ),
      surcharges: <Override>[
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
        portCorpusCoranProvider.overrideWithValue(corpus),
      ],
    ),
  );
  await stabiliser(tester);
}
