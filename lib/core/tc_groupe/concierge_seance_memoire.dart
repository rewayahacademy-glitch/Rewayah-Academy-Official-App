import 'concierge_seance.dart';

/// Un concierge en memoire : il rend ce qu'on lui donne et retient chaque
/// appel. Sert aux tests et au mode Playground, ou il ne rend aucune seance.
class ConciergeMemoire implements PortConcierge {
  /// Cree le concierge. [seances] : la seance rendue par Classe (absente :
  /// `null`). [refus] : le refus leve pour toute Classe. [panne] : l'erreur
  /// levee pour toute Classe.
  ConciergeMemoire({
    Map<String, String> seances = const <String, String>{},
    this.refus,
    this.panne,
  }) : _seances = seances;

  final Map<String, String> _seances;

  /// Le refus leve a chaque appel, s'il est pose.
  final MotifRefusConcierge? refus;

  /// L'erreur levee a chaque appel, si elle est posee.
  final Object? panne;

  /// Les Classes demandees, dans l'ordre.
  final List<String> appels = <String>[];

  @override
  Future<String?> seanceARejoindre(String groupeId) async {
    appels.add(groupeId);
    final Object? erreur = panne;
    if (erreur != null) throw erreur;
    final MotifRefusConcierge? motif = refus;
    if (motif != null) throw RefusConcierge(motif);
    return _seances[groupeId];
  }
}
