/// Ce qui a empeche une lecture ou une ecriture d'observation.
///
/// **A ne pas confondre avec `MotifRefusObservation`**, qui dit pourquoi le
/// serveur a **refuse** une visite parfaitement comprise. Celle-ci dit que la
/// question n'a pas pu etre posee : la fonction n'existe pas encore sur ce
/// deploiement, le reseau est tombe, ou la reponse est illisible. Les deux ne
/// s'affichent pas de la meme facon : un refus s'explique a l'usager, une panne
/// se reessaye.
enum MotifEchecObservation {
  /// La capacite serveur n'est pas en place sur ce deploiement.
  ///
  /// Une fonction inconnue (`42883`, `PGRST202`) : `politique_observation_effective`,
  /// `budget_observation`, `entrer_observation` ou `sortir_observation`
  /// absente de la base interrogee. Elles sont posees par `0033` a `0039` et
  /// dites presentes en production depuis le 21/09/2026.
  capaciteAbsente,

  /// Le reseau ou le backend n'a pas repondu.
  reseau,

  /// La reponse est arrivee mais ne porte rien d'exploitable.
  reponseIllisible,

  /// Une visite de cet observateur est deja ouverte sur cette seance.
  ///
  /// L'index unique `guardian_visit_ouvert_uidx` refuse un second intervalle
  /// ouvert (erreur `23505`), typiquement apres un rechargement de page
  /// pendant une visite. Ce n'est pas une panne : reessayer echouerait a
  /// l'identique, et le temps continue de courir cote serveur (DB-OBS-06).
  visiteDejaOuverte,
}

/// L'echec d'une operation d'observation.
class EchecObservation implements Exception {
  /// Cree un echec.
  const EchecObservation(this.motif);

  /// Ce qui a echoue.
  final MotifEchecObservation motif;

  /// Vrai quand reessayer a un sens.
  ///
  /// Une capacite absente ne se reessaye pas : elle s'installe. Proposer un
  /// bouton « Reessayer » qui echouera a l'identique use la confiance, comme
  /// le dit deja `CauseImpasse.seReessaye` pour la salle.
  bool get seReessaye => motif == MotifEchecObservation.reseau;

  @override
  String toString() => 'EchecObservation(${motif.name})';
}
