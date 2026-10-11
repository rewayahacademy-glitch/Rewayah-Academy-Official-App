import 'modele_rapport_controle.dart';

/// Lecture des rapports de contrôle et ajout d'un complément.
abstract interface class PortHistorique {
  /// Rapports du contrôleur, du plus récent au plus ancien.
  Future<List<RapportControle>> rapports();

  /// Ajoute un complément sans réécrire le rapport transmis.
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  });
}
