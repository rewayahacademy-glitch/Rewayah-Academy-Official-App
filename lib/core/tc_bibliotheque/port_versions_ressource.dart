import 'resource_version.dart';

/// L'historique versionne d'une ressource (CONTRACTS section 5).
///
/// Lecture seule : la publication d'une version est une action
/// d'administration, elle n'appartient pas a la Bibliotheque. Le patron
/// d'ecriture existe deja et a son propre ecran
/// (`lib/core/admin/service_programme.dart`, `ADM-13`).
abstract class PortVersionsRessource {
  /// La version publiee courante, ou `null` quand aucune ne l'est.
  Future<ResourceVersion?> versionCourante(String resourceId);

  /// Une version precise, ou `null`.
  Future<ResourceVersion?> parId(String versionId);

  /// Toutes les versions d'une ressource, la plus recente en premier.
  Future<List<ResourceVersion>> historique(String resourceId);
}
