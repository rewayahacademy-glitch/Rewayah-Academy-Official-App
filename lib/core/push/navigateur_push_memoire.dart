import 'port_push.dart';

/// Hors web : le navigateur ne recoit pas de push.
class NavigateurPushSysteme implements NavigateurPush {
  /// Cree le navigateur.
  const NavigateurPushSysteme();

  @override
  Future<EtatAppareilPush> etat() async => EtatAppareilPush.nonPrisEnCharge;

  @override
  Future<String?> adresse() async => null;

  @override
  Future<AbonnementNavigateur> activer(String clePublique) async =>
      throw const ActivationRefusee(RefusActivation.nonPrisEnCharge);

  @override
  Future<String?> desactiver() async => null;

  @override
  Future<bool> besoinGeste() async => false;

  @override
  String get appareil => 'Application';
}
