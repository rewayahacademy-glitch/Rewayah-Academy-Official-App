// MA-8 : la demande de presentation standard d'un eleve mineur a son tuteur
// (decision du directeur du 27/09, S7 = b). Le tuteur recoit et accepte la
// demande cote serveur (BR-1, ligne MA-BR) ; sa page d'acceptation est MA-9.
//
// Aucun serveur ici : la demonstration (`features/demo/doubles_demo.dart`)
// et les tests posent un port neutre simule. Un echec ne dit jamais que la demande « n'a pas ete envoyee » : il
// dit seulement que l'envoi n'a pas ete confirme (D5).

/// Le port de la demande de presentation standard.
abstract interface class PortDemandePresentation {
  /// Envoie la demande au tuteur. Une erreur signifie « envoi non confirme ».
  Future<void> demanderPresentationStandard();
}
