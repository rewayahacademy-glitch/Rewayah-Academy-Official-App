import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../appairage/code_local.dart';

/// Les secrets locaux de l'appareil.
///
/// Deux sortes de valeurs, et aucune ne remonte jamais au reseau depuis ici :
///
/// - Le **jeton d'appareil**, emis par le serveur a l'appairage (ADR-010). Il y
///   en a un **par profil**, pas un par appareil : une tablette partagee entre
///   deux enfants du meme foyer porte deux jetons, et changer de profil revient
///   a demander une session avec l'autre.
/// - L'**empreinte du code eleve**. Le code lui-meme ne quitte pas l'appareil :
///   on ne conserve donc pas le code, seulement de quoi verifier localement
///   qu'une saisie correspond.
///
/// Le stockage passe par le coffre du systeme, jamais par des preferences en
/// clair : sur un appareil partage entre plusieurs enfants du foyer, un fichier
/// lisible reviendrait a ne rien proteger.
abstract interface class StockageSecurise {
  /// Lit le jeton d'appareil d'un profil.
  Future<String?> jetonAppareil(String profilId);

  /// Ecrit le jeton d'appareil d'un profil, recu a l'appairage.
  Future<void> enregistrerJetonAppareil(String profilId, String jeton);

  /// Efface le jeton d'un profil, sur revocation par le tuteur.
  Future<void> oublierAppareil(String profilId);

  /// Lit l'empreinte du code d'un profil.
  Future<String?> empreintePin(String profilId);

  /// Ecrit l'empreinte du code d'un profil.
  ///
  /// L'appelant fournit une empreinte, jamais le code en clair. Cette interface
  /// ne calcule pas l'empreinte elle-meme, pour qu'aucun chemin de code ne
  /// puisse lui passer un code brut par inadvertance.
  Future<void> enregistrerEmpreintePin(String profilId, String empreinte);

  /// Efface l'empreinte du code d'un profil.
  Future<void> effacerEmpreintePin(String profilId);

  /// L'empreinte de cet appareil, stable et locale.
  ///
  /// Elle sert a distinguer deux appareils d'un meme profil, pas a authentifier
  /// : elle vient du client, donc elle est forgeable. C'est le jeton, emis par
  /// le serveur, qui fait foi.
  Future<String> empreinteAppareil();
}

/// Le coffre du systeme.
class StockageSecuriseCoffre implements StockageSecurise {
  /// Cree le stockage.
  const StockageSecuriseCoffre([FlutterSecureStorage? coffre])
    : _coffre = coffre ?? const FlutterSecureStorage();

  final FlutterSecureStorage _coffre;

  static const String _prefixeJeton = 'jeton_appareil_';
  static const String _prefixeEmpreintePin = 'empreinte_pin_';
  static const String _cleEmpreinteAppareil = 'empreinte_appareil';

  @override
  Future<String?> jetonAppareil(String profilId) =>
      _coffre.read(key: '$_prefixeJeton$profilId');

  @override
  Future<void> enregistrerJetonAppareil(String profilId, String jeton) =>
      _coffre.write(key: '$_prefixeJeton$profilId', value: jeton);

  @override
  Future<void> oublierAppareil(String profilId) async {
    await _coffre.delete(key: '$_prefixeJeton$profilId');
    await _coffre.delete(key: '$_prefixeEmpreintePin$profilId');
  }

  @override
  Future<String?> empreintePin(String profilId) =>
      _coffre.read(key: '$_prefixeEmpreintePin$profilId');

  @override
  Future<void> enregistrerEmpreintePin(String profilId, String empreinte) =>
      _coffre.write(key: '$_prefixeEmpreintePin$profilId', value: empreinte);

  @override
  Future<void> effacerEmpreintePin(String profilId) =>
      _coffre.delete(key: '$_prefixeEmpreintePin$profilId');

  @override
  Future<String> empreinteAppareil() async {
    final String? existante = await _coffre.read(key: _cleEmpreinteAppareil);
    if (existante != null && existante.isNotEmpty) {
      return existante;
    }
    final String nouvelle = jetonAleatoire();
    await _coffre.write(key: _cleEmpreinteAppareil, value: nouvelle);
    return nouvelle;
  }
}

/// Le coffre employe par l'application.
final Provider<StockageSecurise> stockageSecuriseProvider =
    Provider<StockageSecurise>((Ref ref) => const StockageSecuriseCoffre());
