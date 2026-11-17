// L'inscription d'un associe invite (suite de BE-2a-2) : la personne a recu un
// code de la direction, se connecte avec l'adresse invitee, verifie le code puis
// cree son compte (`verifier_invitation_associe`, `inscrire_associe_invite`).
// Le serveur decide de tout : le code est lie a l'adresse de la session, a usage
// unique, et le profil cree n'a aucun droit. Le port ne fait que transmettre.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L'issue de la verification d'un code d'associe.
sealed class ResultatCodeAssocie {
  const ResultatCodeAssocie();
}

/// Le code est valable jusqu'a [expireLe].
class CodeAssocieValide extends ResultatCodeAssocie {
  /// Cree le resultat.
  const CodeAssocieValide(this.expireLe);

  /// La fin de validite du code, quand le serveur la donne.
  final DateTime? expireLe;
}

/// Le code ne correspond a aucune invitation pour cette adresse.
class CodeAssocieInconnu extends ResultatCodeAssocie {
  /// Cree le resultat.
  const CodeAssocieInconnu();
}

/// Le code a deja servi.
class CodeAssocieDejaUtilise extends ResultatCodeAssocie {
  /// Cree le resultat.
  const CodeAssocieDejaUtilise();
}

/// Le code a expire.
class CodeAssocieExpire extends ResultatCodeAssocie {
  /// Cree le resultat.
  const CodeAssocieExpire();
}

/// L'issue de la creation du compte.
enum ResultatInscriptionAssocie {
  /// Le compte est cree : le code est consomme.
  consommee,

  /// Le code ne correspond a aucune invitation pour cette adresse.
  inconnue,

  /// Le code a deja servi.
  dejaUtilisee,

  /// Le code a expire.
  expiree,
}

/// Pourquoi le serveur a refuse sans rendre d'issue nommee.
enum CauseRefusInscriptionAssocie {
  /// Cette session a deja un profil, ou n'a pas d'adresse : l'inscription d'un
  /// associe n'est pas possible depuis elle.
  sessionRefusee,

  /// Un champ manque ou est refuse (prenom, nom, genre).
  champsRefuses,
}

/// Un refus du serveur qui n'est pas une issue du code.
class RefusInscriptionAssocie implements Exception {
  /// Cree le refus.
  const RefusInscriptionAssocie(this.cause);

  /// La cause.
  final CauseRefusInscriptionAssocie cause;

  @override
  String toString() => 'RefusInscriptionAssocie(${cause.name})';
}

/// Le reseau a manque : rien n'est confirme.
class HorsLigneInscriptionAssocie implements Exception {
  /// Cree l'erreur.
  const HorsLigneInscriptionAssocie();

  @override
  String toString() => 'HorsLigneInscriptionAssocie()';
}

/// Le port de l'inscription d'un associe invite.
abstract interface class PortInscriptionAssocie {
  /// Verifie [code] pour l'adresse de la session ; ne consomme rien.
  Future<ResultatCodeAssocie> verifier(String code);

  /// Cree le compte `associe` : [genre] vaut `male` ou `female` (requis).
  Future<ResultatInscriptionAssocie> inscrire({
    required String code,
    required String prenom,
    required String nom,
    required String genre,
  });
}

/// La dependance annoncee quand le port n'est pas branche.
const String dependanceInscriptionAssocie = 'BE-2a-2-INSCRIPTION';

/// Le port ; `null` tant que l'adaptateur n'est pas branche (indisponible).
final Provider<PortInscriptionAssocie?> portInscriptionAssocieProvider =
    Provider<PortInscriptionAssocie?>((Ref _) => null);

/// Lit la reponse de `verifier_invitation_associe`.
ResultatCodeAssocie resultatCodeAssocieJson(Object? brut) {
  if (brut is! Map) throw const FormatException('Objet attendu.');
  return switch (brut['resultat']) {
    'valide' => CodeAssocieValide(
      brut['expire_le'] is String
          ? DateTime.tryParse(brut['expire_le'] as String)?.toUtc()
          : null,
    ),
    'inconnue' => const CodeAssocieInconnu(),
    'deja_utilisee' => const CodeAssocieDejaUtilise(),
    'expiree' => const CodeAssocieExpire(),
    _ => throw const FormatException('Resultat de verification inconnu.'),
  };
}

/// Lit la reponse de `inscrire_associe_invite`.
ResultatInscriptionAssocie resultatInscriptionAssocieJson(Object? brut) {
  if (brut is! Map) throw const FormatException('Objet attendu.');
  return switch (brut['resultat']) {
    'consommee' => ResultatInscriptionAssocie.consommee,
    'inconnue' => ResultatInscriptionAssocie.inconnue,
    'deja_utilisee' => ResultatInscriptionAssocie.dejaUtilisee,
    'expiree' => ResultatInscriptionAssocie.expiree,
    _ => throw const FormatException('Resultat d inscription inconnu.'),
  };
}
