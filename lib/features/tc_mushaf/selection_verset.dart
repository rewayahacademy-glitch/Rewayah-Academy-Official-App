import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/content_range.dart';
import '../../core/tc_coran/port_navigation_coran.dart';

/// Le verset que l'enseignant a designe, sur cet appareil.
///
/// **Etat d'interface, jamais un etat partage.** La selection ne voyage pas :
/// c'est ce qu'on en fait -- Focus, un jour Marquer -- qui devient une revision
/// de `SharedContentState`. Elle est nulle hors classe et pour qui ne pilote
/// pas : c'est [PorteeSelectionVerset] qui decide si un tap selectionne.
final NotifierProvider<ControleurSelectionVerset, ContentRange?>
selectionVersetProvider =
    NotifierProvider<ControleurSelectionVerset, ContentRange?>(
      ControleurSelectionVerset.new,
    );

/// Le controleur de la selection.
class ControleurSelectionVerset extends Notifier<ContentRange?> {
  @override
  ContentRange? build() => null;

  /// Designe un verset ; le meme verset une seconde fois le deselectionne.
  void basculer(VersetCoran verset) {
    final ContentRange plage = plageDuVerset(verset);
    state = state == plage ? null : plage;
  }

  /// Retire la selection.
  void effacer() => state = null;
}

/// La plage d'un seul verset, dans le vocabulaire de la Bibliotheque.
ContentRange plageDuVerset(VersetCoran verset) {
  final ContentPosition p = ContentPosition.ayah(
    resourceId: identifiantRessourceCoran,
    sourate: verset.sourateNumero,
    ayah: verset.numero,
  );
  return ContentRange(resourceId: identifiantRessourceCoran, debut: p, fin: p);
}

/// Vrai quand [plage] designe exactement ce verset.
bool versetSelectionne(ContentRange? plage, VersetCoran verset) =>
    plage != null &&
    plage.contient(
      ContentPosition.ayah(
        resourceId: identifiantRessourceCoran,
        sourate: verset.sourateNumero,
        ayah: verset.numero,
      ),
    );

/// La portee dans laquelle un tap sur un verset le selectionne.
///
/// **Absente, un tap ne fait rien de plus qu'avant.** Le lecteur hors classe,
/// l'eleve qui suit : aucun reconnaisseur n'est attache, aucun lavis n'est
/// peint. Seule la Classe Live la pose, et seulement pour qui peut piloter le
/// support. C'est ainsi que le renderer d'Agent C reste inchange dans son
/// comportement par defaut.
class PorteeSelectionVerset extends InheritedWidget {
  /// Pose la portee.
  const PorteeSelectionVerset({required super.child, super.key});

  /// Vrai quand un ancetre a pose la portee.
  static bool activeDans(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PorteeSelectionVerset>() !=
      null;

  @override
  bool updateShouldNotify(PorteeSelectionVerset oldWidget) => false;
}
