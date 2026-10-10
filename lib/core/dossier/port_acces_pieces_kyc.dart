/// BACK-FRONT-KYC-DIR-1 : qui peut ouvrir quelle piece d'identite, et pourquoi.
///
/// Regle du directeur (10/10/2026, Questions KYC-ADMIN-GENRE, Journal distant
/// ligne 134) :
/// - un admin ne lit que les pieces du MEME genre que le candidat ;
/// - un admin sans genre ne lit rien (refus, jamais d'ouverture par defaut) ;
/// - exception de demarrage : le super admin lit les deux genres, chaque
///   ouverture hors de son genre est journalisee cote serveur, et l'ecran le
///   dit ; la direction peut couper l'exception (reglage serveur) ;
/// - le controleur ne lit jamais rien de KYC.
///
/// Le client ne lit ni ne compare jamais un genre (`port_revue_dossiers.dart`) :
/// le serveur rend le VERDICT. Ce port ne decide rien, il dit pourquoi, pour
/// que chaque refus ait son message. L'ouverture reste celle du port de revue
/// (`demanderVuePiece`, lien court, sans cache ni journal cote client) ; le
/// serveur refuse de toute facon un acces non autorise (policy Storage et RPC).
///
/// Aucun branchement serveur ici : en production le port est absent
/// ([portAccesPiecesKycProvider] vaut `null`), l'ecran de revue reste tel qu'il
/// est. Signature proposee en Contrats (C-21).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Pourquoi une ouverture est refusee. Texte de l'application, jamais un
/// message du serveur.
enum RefusPieceKyc {
  /// L'admin n'est pas du genre du candidat.
  genreDifferent,

  /// L'admin n'a pas de genre renseigne : rien ne s'ouvre.
  adminSansGenre,

  /// Ce profil (controleur, enseignant, parent...) ne lit jamais de piece.
  profilNonAutorise,
}

/// Le verdict du serveur pour un dossier.
sealed class AccesPieceKyc {
  const AccesPieceKyc();
}

/// Meme genre : ouverture ordinaire.
class AccesMemeGenre extends AccesPieceKyc {
  /// Cree le verdict.
  const AccesMemeGenre();
}

/// Hors du genre de l'admin, permis par l'exception super admin : l'ouverture
/// est journalisee par le serveur et l'ecran le dit.
class AccesExceptionSuperAdmin extends AccesPieceKyc {
  /// Cree le verdict.
  const AccesExceptionSuperAdmin();
}

/// Ouverture refusee, avec sa raison.
class AccesRefuse extends AccesPieceKyc {
  /// Cree le verdict.
  const AccesRefuse(this.raison);

  /// Pourquoi.
  final RefusPieceKyc raison;
}

/// Le port des droits d'ouverture des pieces, pour la personne connectee.
abstract interface class PortAccesPiecesKyc {
  /// Le verdict pour [dossierId].
  Future<AccesPieceKyc> pour(String dossierId);

  /// Vrai quand l'exception super admin est active POUR LA PERSONNE connectee
  /// (reglage serveur actif ET personne super admin) : le statut le montre.
  Future<bool> exceptionActive();
}

/// Le port : absent avant le branchement serveur.
final Provider<PortAccesPiecesKyc?> portAccesPiecesKycProvider =
    Provider<PortAccesPiecesKyc?>((Ref _) => null);

/// Le verdict d'un dossier ; `null` sans port (rien n'est annonce).
final FutureProviderFamily<AccesPieceKyc?, String> accesPieceKycProvider =
    FutureProvider.family<AccesPieceKyc?, String>((Ref ref, String id) async {
      final PortAccesPiecesKyc? port = ref.watch(portAccesPiecesKycProvider);
      return port?.pour(id);
    });

/// L'exception super admin est-elle active ; faux sans port.
final FutureProvider<bool> exceptionKycActiveProvider = FutureProvider<bool>((
  Ref ref,
) async {
  final PortAccesPiecesKyc? port = ref.watch(portAccesPiecesKycProvider);
  return port == null ? false : port.exceptionActive();
});
