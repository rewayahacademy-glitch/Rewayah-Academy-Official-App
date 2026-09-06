import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Les secrets locaux de l'appareil.
///
/// Deux valeurs seulement, et aucune ne remonte jamais au reseau depuis ici :
///
/// - Le **jeton d'appareil**, qui identifie un appareil appaire (ADR-010, deux
///   appareils au maximum, un seul en seance).
/// - L'**empreinte du code eleve**. Le code lui-meme ne quitte pas l'appareil
///   (ADR-005) : on ne conserve donc pas le code, seulement de quoi verifier
///   localement qu'une saisie correspond.
///
/// Le stockage passe par le coffre du systeme, jamais par des preferences en
/// clair : sur un appareil partage entre plusieurs enfants du foyer, un fichier
/// lisible reviendrait a ne rien proteger.
class StockageSecurise {
  /// Cree le stockage.
  const StockageSecurise([FlutterSecureStorage? coffre])
    : _coffre = coffre ?? const FlutterSecureStorage();

  final FlutterSecureStorage _coffre;

  static const String _cleJetonAppareil = 'jeton_appareil';
  static const String _prefixeEmpreintePin = 'empreinte_pin_';

  /// Lit le jeton de cet appareil.
  Future<String?> jetonAppareil() => _coffre.read(key: _cleJetonAppareil);

  /// Ecrit le jeton de cet appareil, recu a l'appairage.
  Future<void> enregistrerJetonAppareil(String jeton) =>
      _coffre.write(key: _cleJetonAppareil, value: jeton);

  /// Efface le jeton, sur revocation par le tuteur.
  Future<void> revoquerAppareil() => _coffre.delete(key: _cleJetonAppareil);

  /// Lit l'empreinte du code d'un profil.
  Future<String?> empreintePin(String profilId) =>
      _coffre.read(key: '$_prefixeEmpreintePin$profilId');

  /// Ecrit l'empreinte du code d'un profil.
  ///
  /// L'appelant fournit une empreinte, jamais le code en clair. Cette classe ne
  /// calcule pas l'empreinte elle-meme, pour qu'aucun chemin de code ne puisse
  /// lui passer un code brut par inadvertance.
  Future<void> enregistrerEmpreintePin(String profilId, String empreinte) =>
      _coffre.write(key: '$_prefixeEmpreintePin$profilId', value: empreinte);

  /// Efface l'empreinte du code d'un profil.
  Future<void> effacerEmpreintePin(String profilId) =>
      _coffre.delete(key: '$_prefixeEmpreintePin$profilId');
}
