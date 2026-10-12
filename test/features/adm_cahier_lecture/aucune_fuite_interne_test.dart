// ADM-CAHIER-LECTURE : aucun champ interne de `CahierAdmin` n'atteint
// l'apercu familial ni le detail du tuteur. Deux gardes :
// 1. rendu : le texte interne servi par `lireCahierAdmin` n'apparait dans
//    aucun des deux rendus de la famille ;
// 2. source : le code qui rend la famille ne nomme ni `CahierAdmin`, ni
//    `detailsInternes`, ni `lireCahierAdmin` (un champ interne ajoute a
//    l'apercu fait tomber ce test).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:rewayah_academy/features/admin_groupes/apercu_familial.dart';
import 'package:rewayah_academy/features/suivi_foyer/bloc_compte_rendu.dart';

import '../../fixtures/ped_apres/faux_partage_pedagogique.dart';
import '../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget enfant,
  FauxPartagePedagogique s,
) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Scaffold(body: SingleChildScrollView(child: enfant)),
      surcharges: <Override>[
        portPartagePedagogiqueProvider.overrideWithValue(s),
        sansPersonneConnectee(),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('le double sert bien un texte interne a la direction (garde non '
      'vide)', () async {
    final FauxPartagePedagogique s = FauxPartagePedagogique()
      ..rapports[('s1', 'e1')] = RapportSim();
    final CahierAdmin c = await s.lireCahierAdmin(
      seanceId: 's1',
      eleveId: 'e1',
    );
    expect(c.detailsInternes, isNotEmpty);
  });

  testWidgets('l apercu familial ne montre aucun texte interne du cahier', (
    WidgetTester tester,
  ) async {
    final FauxPartagePedagogique s = FauxPartagePedagogique()
      ..rapports[('s1', 'e1')] = RapportSim();
    final CahierAdmin c = await s.lireCahierAdmin(
      seanceId: 's1',
      eleveId: 'e1',
    );
    await _monter(
      tester,
      const FeuilleApercuFamilial(seanceId: 's1', eleveId: 'e1'),
      s,
    );
    for (final RubriqueInterne r in c.detailsInternes) {
      expect(find.textContaining(r.texte), findsNothing, reason: r.texte);
      expect(find.text(r.libelle), findsNothing, reason: r.libelle);
    }
  });

  testWidgets('le detail du tuteur ne montre aucun texte interne', (
    WidgetTester tester,
  ) async {
    final FauxPartagePedagogique s = FauxPartagePedagogique()
      ..rapports[('s1', 'e1')] = RapportSim();
    final CahierAdmin c = await s.lireCahierAdmin(
      seanceId: 's1',
      eleveId: 'e1',
    );
    await _monter(
      tester,
      const BlocCompteRendu(seanceId: 's1', eleveId: 'e1'),
      s,
    );
    for (final RubriqueInterne r in c.detailsInternes) {
      expect(find.textContaining(r.texte), findsNothing, reason: r.texte);
    }
  });

  test('le code qui rend la famille ne nomme aucun champ interne', () {
    for (final String chemin in <String>[
      'lib/features/admin_groupes/apercu_familial.dart',
      'lib/features/suivi_foyer/bloc_compte_rendu.dart',
    ]) {
      final String code = File(chemin)
          .readAsLinesSync()
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      for (final String interdit in <String>[
        'CahierAdmin',
        'detailsInternes',
        'lireCahierAdmin',
        'RubriqueInterne',
      ]) {
        expect(code, isNot(contains(interdit)), reason: '$chemin : $interdit');
      }
    }
  });
}
