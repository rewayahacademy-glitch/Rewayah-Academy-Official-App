// Une source qui refuse la lecture ou l'action a la personne connectee
// (spec §49 : « permission insuffisante », distincte d'un echec reseau et
// d'une capacite absente). Le serveur decide ; l'ecran le dit en mots, sans
// « Reessayer » : recommencer ne change rien.

/// La personne connectee n'a pas la permission de lire ou d'agir.
class PermissionInsuffisante implements Exception {
  /// Cree l'exception. [action] est la capacite refusee (trace et tests,
  /// jamais affichee).
  const PermissionInsuffisante(this.action);

  /// La capacite refusee.
  final String action;

  @override
  String toString() => 'PermissionInsuffisante($action)';
}
