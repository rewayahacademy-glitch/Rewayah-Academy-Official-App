/// Capacite serveur minimale du titulaire apprenant.
abstract interface class PortProfilEleveTitulaireServeur {
  /// Indique si la fiche liée au compte du titulaire existe.
  Future<bool> existe();

  /// Crée la fiche de manière idempotente. Les refus serveur remontent à l'appelant.
  Future<void> creer();
}
