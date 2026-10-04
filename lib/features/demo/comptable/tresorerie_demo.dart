// La demonstration de la tresorerie (CPT-BR-04, 05). Posee vide par CPT-F ;
// **propriete de la voie CPT-TRES ensuite** (`20_comptable/02_DECOUPAGE.md`,
// liste B). Spec §44 a tenir par CPT-TRES : sept coffres, une Reserve sous
// l'objectif (lue dans `direction_demo.dart`, meme politique), un transfert
// simule, un retrait sans capacite bloque (R-FIN-10). Aucun mouvement reel.

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_tresorerie.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import 'socle_comptable_demo.dart';

/// La tresorerie en demonstration : les sept coffres a zero tant que
/// CPT-TRES-1 ne les a pas remplis.
class TresorerieDemo implements PortTresorerie {
  /// Cree le double.
  const TresorerieDemo();

  @override
  Future<SyntheseTresorerie> resume() async => SocleComptableDemo.syntheseVide;

  @override
  Future<List<SoldeCoffre>> coffres() async => <SoldeCoffre>[
    for (final Coffre c in Coffre.values)
      SoldeCoffre(
        coffre: c,
        montant: SocleComptableDemo.zero,
        partPourMille: 0,
      ),
  ];

  @override
  Future<List<EntreeJournal>> historique(
    FiltreHistoriqueTresorerie filtre,
  ) async => const <EntreeJournal>[];

  @override
  Future<List<LignePrevision>> prevision() async => const <LignePrevision>[];

  @override
  Future<List<MouvementPermis>> mouvementsPermis() async =>
      const <MouvementPermis>[];

  @override
  Future<ResultatMouvement> transferer({
    required Coffre origine,
    required Coffre destination,
    required Montant montant,
    required String cleIdempotence,
  }) =>
      Future<ResultatMouvement>.error(const CapaciteIndisponible('CPT-BR-05'));

  @override
  Future<List<EntreeJournal>> journal(String mouvementId) async =>
      const <EntreeJournal>[];
}

/// Les surcharges de la demonstration de la tresorerie.
List<Override> surchargesDemoTresorerie() => <Override>[
  portTresorerieProvider.overrideWithValue(const TresorerieDemo()),
];
