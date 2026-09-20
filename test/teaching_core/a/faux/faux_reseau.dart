import 'package:rewayah_academy/core/reseau/service_reseau.dart';

/// Un etat de reseau fige.
///
/// Aucun test ne peut couper le reseau de la machine qui l'execute : sans ce
/// faux, le comportement hors ligne de « Mes groupes » ne serait pas mesurable.
///
/// Il vit dans `test/teaching_core/a/faux/` et non dans `test/support/` : ce
/// dernier est un fichier unique partage, deja modifie par un autre chantier
/// (decision `D-06`).
class FauxServiceReseau implements ServiceReseau {
  /// Cree un faux reseau.
  const FauxServiceReseau({this.horsLigneMaintenant = false});

  /// Ce que le flux annoncera.
  final bool horsLigneMaintenant;

  @override
  Stream<bool> horsLigne() => Stream<bool>.value(horsLigneMaintenant);
}
