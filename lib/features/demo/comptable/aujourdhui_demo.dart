// La demonstration d'Aujourd'hui du Comptable (CPT-BR-03). Posee vide par
// CPT-F ; **propriete de la voie CPT (CPT-JOUR) ensuite**
// (`20_comptable/02_DECOUPAGE.md`, liste B). Les identites viennent de
// `socle_comptable_demo.dart` ; aucun appel serveur (K-28).

import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/capacites/port_aujourdhui_comptable.dart';
import '../../../core/comptable/modeles_comptable.dart';
import 'socle_comptable_demo.dart';

/// Aujourd'hui en demonstration : vide tant que CPT-JOUR ne l'a pas rempli.
class AujourdhuiComptableDemo implements PortAujourdhuiComptable {
  /// Cree le double.
  const AujourdhuiComptableDemo();

  @override
  Future<AujourdhuiComptable> aujourdhui() async => const AujourdhuiComptable(
    tresorerie: SocleComptableDemo.syntheseVide,
    reserve: SocleComptableDemo.reserveVide,
  );

  @override
  Future<List<EntreeJournal>> journal(String objetId) async =>
      const <EntreeJournal>[];
}

/// Les surcharges de la demonstration d'Aujourd'hui.
List<Override> surchargesDemoAujourdhui() => <Override>[
  portAujourdhuiComptableProvider.overrideWithValue(
    const AujourdhuiComptableDemo(),
  ),
];
