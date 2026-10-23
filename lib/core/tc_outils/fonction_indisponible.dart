/// Une fonction de la salle dont le serveur n'existe pas encore.
///
/// SALLE-ROBUSTE : les ports `PortAnnotations`, `PortAssignations`,
/// `PortFeedback`, `PortSignalement` et `PortPostCours` n'ont pas encore
/// d'adaptateur serveur. Leur provider rendait une `UnimplementedError`, que
/// rien n'attrapait. Il rend maintenant une implementation « indisponible »
/// qui se reconnait ([PortIndisponible]) et dont les ecritures levent
/// [FonctionIndisponible], une erreur typee que l'ecran sait dire.
library;

/// Marque une implementation d'un port qui n'est pas branchee a un serveur.
///
/// Un ecran la lit pour ne pas proposer une action qui ne peut pas aboutir
/// (`port is PortIndisponible`), sans connaitre la classe concrete.
abstract interface class PortIndisponible {}

/// L'echec d'une fonction dont le port n'est pas branche.
///
/// Ce n'est ni un echec reseau ni une erreur de l'utilisateur : rien n'a ete
/// perdu, la fonction n'existe pas encore. L'ecran la dit calmement, sans
/// proposer de recommencer.
class FonctionIndisponible implements Exception {
  /// Cree l'echec, pour la fonction nommee (nom technique, pour les traces).
  const FonctionIndisponible(this.fonction);

  /// La fonction demandee (`annotations`, `assignations`, `post-cours`...).
  final String fonction;

  @override
  String toString() => 'FonctionIndisponible($fonction)';
}
