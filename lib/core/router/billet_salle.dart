import 'package:flutter/foundation.dart';

/// Le droit d'entrer dans une salle, valable une fois.
///
/// L'ADR-005 exige qu'aucune route de salle ne soit partageable ni memorisable
/// en favori : l'URL de la salle est ephemere et regeneree a chaque entree.
///
/// Ce billet transite par le champ `extra` de go_router, qui n'est **pas**
/// serialise dans l'URL et ne survit pas a un rechargement de page. Une adresse
/// copiee, collee dans un autre onglet ou rouverte le lendemain arrive donc
/// sans billet, et la redirection renvoie a la racine du role. La proprete de
/// ce comportement ne tient a aucune verification supplementaire : elle tient a
/// la nature du transport choisi.
///
/// La vraie barriere reste serveur : le token LiveKit n'est emis que de
/// T-10 min a T+fin+10 min, apres verification de l'appartenance a
/// `session_participants`.
@immutable
class BilletSalle {
  /// Cree un billet pour une seance.
  const BilletSalle({required this.sessionId, required this.emisA});

  /// La seance visee.
  final String sessionId;

  /// Instant d'emission cote client. Sert uniquement a purger un billet reste
  /// en memoire trop longtemps, jamais a autoriser quoi que ce soit.
  final DateTime emisA;

  /// Duree au-dela de laquelle un billet garde en memoire n'est plus presente.
  static const Duration duree = Duration(minutes: 20);

  /// Vrai quand le billet est encore presentable.
  bool valideA(DateTime maintenant) =>
      maintenant.difference(emisA) < duree && !maintenant.isBefore(emisA);
}
