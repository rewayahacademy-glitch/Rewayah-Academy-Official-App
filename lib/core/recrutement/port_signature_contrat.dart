/// RECRUT-ECRANS : la signature probante du contrat (contrats C-15 et C-16 de
/// la feuille de liaison, 10/10/2026).
///
/// La version, l'empreinte et le texte viennent du serveur
/// ([ContratCourant]) : l'application ne porte plus de constante de version
/// pour cet ecran. L'empreinte [ContratCourant.sha256] ne sert qu'a un
/// controle d'affichage (le texte montre doit hasher a l'empreinte annoncee,
/// sinon la signature n'est pas proposee) ; aucune empreinte de reference
/// n'est calculee cote Flutter. L'horodatage d'une [Signature] est celui du
/// serveur, jamais celui de l'appareil.
///
/// Aucun branchement serveur ici : le port vaut `null` en production.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import '../domain/enums.dart';

/// Le contrat en vigueur pour une sorte.
@immutable
class ContratCourant {
  /// Cree le contrat courant.
  const ContratCourant({
    required this.kind,
    required this.version,
    required this.texte,
    required this.sha256,
  });

  /// La sorte de contrat.
  final SorteContrat kind;

  /// La version courante.
  final String version;

  /// Le texte valide, servi tel quel.
  final String texte;

  /// L'empreinte annoncee du texte.
  final String sha256;
}

/// Une signature enregistree.
@immutable
class Signature {
  /// Cree une signature.
  const Signature({
    required this.kind,
    required this.version,
    required this.sha256,
    required this.nomSaisi,
    required this.signeLe,
  });

  /// La sorte signee.
  final SorteContrat kind;

  /// La version signee.
  final String version;

  /// L'empreinte du texte signe.
  final String sha256;

  /// Le nom tape par le signataire.
  final String nomSaisi;

  /// Horodatage serveur.
  final DateTime signeLe;
}

/// Les refus de la signature.
sealed class ErreurSignature implements Exception {
  const ErreurSignature();
}

/// Le texte a change pendant la lecture : recharger [versionCourante].
final class VersionPerimee extends ErreurSignature {
  /// Cree l'erreur.
  const VersionPerimee(this.versionCourante);

  /// La version a relire.
  final String versionCourante;
}

/// Le nom est vide (apres trim).
final class NomVide extends ErreurSignature {
  /// Cree l'erreur.
  const NomVide();
}

/// Le nom depasse la longueur admise.
final class NomTropLong extends ErreurSignature {
  /// Cree l'erreur.
  const NomTropLong();
}

/// Aucune session.
final class NonConnecte extends ErreurSignature {
  /// Cree l'erreur.
  const NonConnecte();
}

/// Aucune reponse : hors ligne.
final class HorsLigneSignature extends ErreurSignature {
  /// Cree l'erreur.
  const HorsLigneSignature();
}

/// Le serveur n'a aucun contrat courant pour cette sorte.
final class ContratIntrouvable extends ErreurSignature {
  /// Cree l'erreur.
  const ContratIntrouvable();
}

/// Le port.
abstract interface class PortSignatureContrat {
  /// Le contrat courant.
  Future<ContratCourant> contratCourant(SorteContrat kind);

  /// Signe. Idempotent : une signature existante pour (profil, kind, version)
  /// est renvoyee sans erreur.
  Future<Signature> signerContrat(
    SorteContrat kind,
    String version,
    String nomSaisi,
  );

  /// La derniere signature, `null` si jamais signe.
  Future<Signature?> maSignature(SorteContrat kind);

  /// URL signee de courte duree vers la copie signee.
  Future<String> copieSigneeUrl(SorteContrat kind);
}

/// L'identifiant de la dependance serveur, pour la trace et les tests.
const String dependanceSignatureContrat = 'RECRUT-SIGNATURE';

/// Le port : absent avant le branchement serveur.
final Provider<PortSignatureContrat?> portSignatureContratProvider =
    Provider<PortSignatureContrat?>((Ref _) => null);

PortSignatureContrat _port(Ref ref) {
  final PortSignatureContrat? port = ref.watch(portSignatureContratProvider);
  if (port == null) {
    throw const CapaciteIndisponible(dependanceSignatureContrat);
  }
  return port;
}

/// Le contrat courant de l'enseignant.
final FutureProvider<ContratCourant> contratEnseignantCourantProvider =
    FutureProvider<ContratCourant>(
      (Ref ref) => _port(ref).contratCourant(SorteContrat.contratEnseignant),
      retry: (int _, Object _) => null,
    );

/// La signature de l'enseignant, `null` si jamais signe.
final FutureProvider<Signature?> maSignatureEnseignantProvider =
    FutureProvider<Signature?>(
      (Ref ref) => _port(ref).maSignature(SorteContrat.contratEnseignant),
      retry: (int _, Object _) => null,
    );
