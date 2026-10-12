// TB-RC (revue TB-R, m21) : l'etat des outils d'une salle appartient a cette
// salle.
//
// L'outil Ecrire (`etatOutilsProvider`), l'historique d'Annuler
// (`historiquePersonnelProvider`) et la marque « non partage »
// (`traitsNonPartagesProvider`) sont des providers de la racine : sans portee,
// une salle neuve s'ouvrirait avec Ecrire arme par la salle d'avant (le
// premier doigt ecrirait) et « Annuler » pourrait rejouer une operation d'une
// autre salle. Cette portee les remplace par des instances neuves, vivantes
// aussi longtemps que la salle. Majeur au branchement de BR-1.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/operations_personnelles.dart';
import 'notes_deposees.dart';

/// Les outils, l'historique d'Annuler et la marque « non partage » d'UNE
/// salle, autour de [child].
class PorteeOutilsSalle extends StatelessWidget {
  /// Cree la portee.
  const PorteeOutilsSalle({required this.child, super.key});

  /// La salle.
  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      etatOutilsProvider.overrideWith(ControleurOutils.new),
      historiquePersonnelProvider.overrideWith(ControleurHistorique.new),
      traitsNonPartagesProvider.overrideWith(TraitsNonPartages.new),
    ],
    child: child,
  );
}
