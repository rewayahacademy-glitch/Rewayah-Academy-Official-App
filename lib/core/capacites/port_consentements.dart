import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../profil/service_acceptations.dart';
import 'capacite_indisponible.dart';
import 'consentements_supabase.dart';

/// Un consentement a (re)signer, tel que le serveur le demandera.
@immutable
class ConsentementRequis {
  /// Cree la demande.
  const ConsentementRequis({
    required this.sorte,
    required this.version,
    required this.obligatoire,
  });

  /// La sorte de texte.
  final SorteContrat sorte;

  /// La version a signer.
  final String version;

  /// Vrai quand le refus ferme un usage.
  final bool obligatoire;
}

/// Les consentements du titulaire (contrat K6, consommateurs : Admission,
/// Compte, Observation).
abstract interface class PortConsentements {
  /// Les textes signes, du plus recent au plus ancien.
  Future<List<Acceptation>> signees();

  /// Les textes a signer ou a resigner. **Aucun compte n'est considere comme
  /// ayant accepte un texte qu'il n'a pas signe.**
  Future<List<ConsentementRequis>> aRenouveler();

  /// Signe une version. Une version signee ne se reecrit jamais.
  Future<void> accepter({required SorteContrat sorte, required String version});
}

/// Les consentements tant que leur adaptateur n'est pas livre.
///
/// - [signees] est **branchable sans backend** (`ServiceAcceptations`, policy
///   `contract_acceptances_self_read`) : l'adaptateur reel
///   `lib/core/capacites/consentements_supabase.dart` est ecrit par le **lot
///   A** (`00_OWNERSHIP.md` section 3), qui remplace alors l'implementation du
///   provider ci-dessous.
/// - [aRenouveler] attend une source serveur (DB-ADM-03) : `etat_dossier()`
///   ignore la version, sauf celle du code de conduite de l'enseignant
///   (`code_conduite_signe`, voir l'en-tete de `VersionsContrat`).
/// - [accepter] est possible par insertion de soi (`contract_acceptances`),
///   mais **seulement apres validation par le directeur du texte de la
///   nouvelle version** (point P2, DB-ADM-02) : d'ici la, rien n'est
///   enregistre et rien n'est pretendu.
class ConsentementsIndisponibles implements PortConsentements {
  /// Cree l'implementation.
  const ConsentementsIndisponibles();

  @override
  Future<List<Acceptation>> signees() =>
      Future<List<Acceptation>>.error(const CapaciteIndisponible('LOT-A'));

  @override
  Future<List<ConsentementRequis>> aRenouveler() =>
      Future<List<ConsentementRequis>>.error(
        const CapaciteIndisponible('DB-ADM-03'),
      );

  @override
  Future<void> accepter({
    required SorteContrat sorte,
    required String version,
  }) => Future<void>.error(const CapaciteIndisponible('DB-ADM-02'));
}

/// Les consentements employes par l'application : l'adaptateur reel du lot A
/// ([consentementsLotAProvider], demande A-3). [ConsentementsIndisponibles]
/// reste la reponse honnete d'un contexte sans adaptateur.
final Provider<PortConsentements> portConsentementsProvider =
    Provider<PortConsentements>(
      (Ref ref) => ref.watch(consentementsLotAProvider),
    );
