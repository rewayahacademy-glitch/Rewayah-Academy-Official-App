import 'shared_content_state.dart';

/// L'acces a l'etat partage d'une seance (CONTRACTS section 9).
///
/// **Contrat produit par Agent F.** Consomme par C (mode classe et focus), D
/// (ancrage des outils), E (coque de Classe Live) et Q.
///
/// La separation entre [suivre] et [restaurer] est le coeur du lot : le flux
/// sert la seance en cours, la restauration sert celui qui arrive ou qui
/// revient. **Un arrivant tardif ne rejoue jamais le flux** -- il lit l'etat
/// courant, une fois, et repart de la.
abstract class PortEtatPartage {
  /// L'etat courant, ou `null` si aucune presentation n'est en cours.
  Future<SharedContentState?> etatCourant(String sessionId);

  /// Le flux des revisions.
  Stream<SharedContentState> suivre(String sessionId);

  /// Publie une revision.
  Future<void> publier(SharedContentState etat);

  /// Restauration apres reconnexion ou arrivee tardive.
  ///
  /// **Lit le backend, jamais l'historique realtime.** LiveKit n'est pas une
  /// base de donnees : aucun serveur ne conserve les paquets de donnees d'une
  /// seance, et le socle le dit deja en clair
  /// (`LiveKitSessionProvider._republierContenu`).
  Future<SharedContentState?> restaurer(String sessionId);
}
