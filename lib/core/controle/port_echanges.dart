import 'modele_echanges.dart';

/// Accès aux fils d'échange du contrôleur.
abstract interface class PortEchanges {
  /// Fils du contrôleur, du plus récent au plus ancien.
  Future<List<FilEchange>> fils();

  /// Fil canonique d'une mission, créé par le serveur s'il n'existe pas.
  Future<FilEchange> filDeMission(String missionId);

  /// Envoie un message et échoue si le serveur ne l'a pas confirmé.
  Future<void> envoyer(String filId, String texte);
}
