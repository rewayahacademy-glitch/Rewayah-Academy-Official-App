import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import 'capacite_indisponible.dart';

/// Comment le titulaire se connecte en production.
enum MethodeConnexion {
  /// Lien a usage unique recu par courriel.
  lienCourriel,

  /// Compte Google.
  google,

  /// Non determinable depuis la session.
  inconnue,
}

/// L'identite du titulaire du compte, en lecture.
@immutable
class IdentiteTitulaire {
  /// Cree l'identite.
  const IdentiteTitulaire({
    required this.prenom,
    required this.nom,
    required this.methodeConnexion,
    this.courriel,
    this.statut,
  });

  /// Prenom (`profiles.first_name`).
  final String prenom;

  /// Nom (`profiles.last_name`).
  final String nom;

  /// Courriel de la session. `null` : non expose.
  final String? courriel;

  /// Methode de connexion.
  final MethodeConnexion methodeConnexion;

  /// Statut du compte. `null` : illisible, jamais « actif » par defaut.
  final AccountStatus? statut;
}

/// L'identite du titulaire (contrat K6, consommateur : Compte).
abstract interface class PortIdentiteTitulaire {
  /// L'identite de la personne connectee.
  Future<IdentiteTitulaire> lire();

  /// Modifie le prenom ou le nom. Aucune ecriture n'existe pour le tuteur
  /// (DB-CPT-01) : l'ecran dit « modifiable par l'academie ».
  Future<void> modifier({String? prenom, String? nom});
}

/// L'identite tant que son adaptateur n'est pas livre.
///
/// **La lecture est branchable sans backend** : `profiles` par soi
/// (`profiles_self_select`) et `auth.currentUser` (courriel, fournisseur).
/// L'adaptateur reel `lib/core/capacites/identite_titulaire_supabase.dart` est
/// ecrit par le **lot E** (`00_OWNERSHIP.md` section 3), qui remplace alors
/// l'implementation du provider ci-dessous. La modification reste
/// indisponible (DB-CPT-01).
class IdentiteTitulaireIndisponible implements PortIdentiteTitulaire {
  /// Cree l'implementation.
  const IdentiteTitulaireIndisponible();

  @override
  Future<IdentiteTitulaire> lire() =>
      Future<IdentiteTitulaire>.error(const CapaciteIndisponible('LOT-E'));

  @override
  Future<void> modifier({String? prenom, String? nom}) =>
      Future<void>.error(const CapaciteIndisponible('DB-CPT-01'));
}

/// L'identite du titulaire employee par l'application.
final Provider<PortIdentiteTitulaire> portIdentiteTitulaireProvider =
    Provider<PortIdentiteTitulaire>(
      (Ref ref) => const IdentiteTitulaireIndisponible(),
    );
