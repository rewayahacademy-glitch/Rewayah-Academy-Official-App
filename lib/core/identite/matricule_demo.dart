import 'port_matricule.dart';

/// Matricules de demonstration, en memoire (aucun serveur).
class MatriculeDemo implements PortMatricule {
  /// Cree le double ; [parProfil] associe un identifiant de profil a son
  /// matricule.
  const MatriculeDemo([this.parProfil = const <String, Matricule>{}]);

  /// Les matricules connus, par identifiant de profil.
  final Map<String, Matricule> parProfil;

  @override
  Future<Matricule?> matriculeDe(String profileId) async =>
      parProfil[profileId];
}
