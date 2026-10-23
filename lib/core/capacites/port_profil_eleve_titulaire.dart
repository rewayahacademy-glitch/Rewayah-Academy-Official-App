import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Le profil eleve du titulaire lui-meme (« Moi uniquement », « Creer mon
/// profil eleve », « Ouvrir mon espace eleve ») (contrat K6).
abstract interface class PortProfilEleveTitulaire {
  /// Vrai quand le titulaire a son propre profil eleve.
  Future<bool> existe();

  /// Cree le profil eleve du titulaire.
  Future<void> creer();

  /// Bascule vers l'espace eleve du titulaire.
  Future<void> ouvrirEspaceEleve();
}

/// Le profil eleve du titulaire tant que le serveur ne sait pas le creer
/// (DB-FOY-01 : `creer_mon_profil_eleve()`, capacite projetee, bascule de
/// session). **Jamais un profil fictif, jamais le conseil de s'ajouter comme
/// « enfant »** (cela creerait un second compte mineur). [existe] ne rend pas
/// « faux » : il ne sait pas. Aucun adaptateur prevu.
class ProfilEleveTitulaireIndisponible implements PortProfilEleveTitulaire {
  /// Cree l'implementation.
  const ProfilEleveTitulaireIndisponible();

  @override
  Future<bool> existe() =>
      Future<bool>.error(const CapaciteIndisponible('DB-FOY-01'));

  @override
  Future<void> creer() =>
      Future<void>.error(const CapaciteIndisponible('DB-FOY-01'));

  @override
  Future<void> ouvrirEspaceEleve() =>
      Future<void>.error(const CapaciteIndisponible('DB-FOY-01'));
}

/// Le profil eleve du titulaire employe par l'application.
final Provider<PortProfilEleveTitulaire> portProfilEleveTitulaireProvider =
    Provider<PortProfilEleveTitulaire>(
      (Ref ref) => const ProfilEleveTitulaireIndisponible(),
    );
