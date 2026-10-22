import 'dart:typed_data';

import 'port_partage_offre.dart';

/// Hors navigateur : aucun menu de partage. Le bouton « Partager » n'est pas
/// rendu ; l'image s'enregistre et le lien se copie.
///
/// (Un menu natif demanderait un paquet que le projet n'a pas : `share_plus`
/// n'est pas une dependance.)
class PartageNonPropose implements PortPartageOffre {
  /// Cree le port.
  const PartageNonPropose();

  @override
  NiveauPartage get niveau => NiveauPartage.aucun;

  @override
  Future<IssuePartage> partager({
    required Uint8List png,
    required String nomFichier,
    required String titre,
    required String texte,
    required Uri lien,
  }) => Future<IssuePartage>.error(const PartageImpossible());
}

/// Le port de cette plateforme.
PortPartageOffre partageAppareil() => const PartageNonPropose();
