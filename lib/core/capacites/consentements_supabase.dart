import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../dossier/service_dossier.dart';
import '../dossier/versions_contrat.dart';
import '../profil/service_acceptations.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'port_consentements.dart';

/// L'adaptateur reel du contrat K6 [PortConsentements] (lot A).
///
/// - [signees] lit `contract_acceptances` par [ServiceAcceptations] (policy
///   `contract_acceptances_self_read`, tri `accepted_at` decroissant explicite).
/// - [aRenouveler] se deduit de cette lecture et de rien d'autre : une version
///   absente des lignes lues est a signer. **Aucune acceptation n'est
///   presumee**, et un echec de lecture remonte en erreur au lieu de rendre une
///   liste vide. Le serveur, lui, n'exige pas encore la version (DB-ADM-03).
/// - [accepter] passe par le mecanisme existant,
///   `ServiceDossier.accepterContrat` (insertion de soi, ligne immuable).
class ConsentementsSupabase implements PortConsentements {
  /// Cree l'adaptateur.
  const ConsentementsSupabase({
    required this.acceptations,
    required this.dossier,
    required this.profilId,
  });

  /// La lecture des acceptations.
  final ServiceAcceptations acceptations;

  /// Le mecanisme d'ecriture existant.
  final ServiceDossier dossier;

  /// Le titulaire connecte, lu dans la session.
  final String? profilId;

  @override
  Future<List<Acceptation>> signees() async {
    final String? profil = profilId;
    if (profil == null) {
      throw StateError('aucune session');
    }
    return acceptations.acceptations(profil);
  }

  @override
  Future<List<ConsentementRequis>> aRenouveler() async =>
      consentementsARenouveler(await signees());

  @override
  Future<void> accepter({
    required SorteContrat sorte,
    required String version,
  }) => dossier.accepterContrat(sorte, version);
}

/// Les textes du tuteur a signer, deduits des acceptations lues.
///
/// Seules les conditions du tuteur ont une nouvelle version (paragraphe des
/// visites d'observation) : c'est la seule qu'on puisse avoir a resigner apres
/// l'entree.
List<ConsentementRequis> consentementsARenouveler(List<Acceptation> lues) {
  final String version = VersionsContrat.pour(SorteContrat.conditionsTuteur);
  final bool signee = lues.any(
    (Acceptation a) =>
        a.sorte == SorteContrat.conditionsTuteur && a.version == version,
  );
  return <ConsentementRequis>[
    if (!signee)
      ConsentementRequis(
        sorte: SorteContrat.conditionsTuteur,
        version: version,
        obligatoire: true,
      ),
  ];
}

/// L'acceptation de la version avec observation, ou `null` si elle n'est pas
/// signee.
Acceptation? acceptationObservation(List<Acceptation> lues) {
  final String version = VersionsContrat.pour(SorteContrat.conditionsTuteur);
  for (final Acceptation a in lues) {
    if (a.sorte == SorteContrat.conditionsTuteur && a.version == version) {
      return a;
    }
  }
  return null;
}

/// Les consentements du lot A.
///
/// `portConsentementsProvider` (fichier du coordinateur) rend encore
/// l'implementation indisponible : la demande A-3 (`demandes/A.md`) lui
/// demande de pointer sur cet adaptateur. D'ici la, les ecrans du lot A lisent
/// ce provider.
final Provider<PortConsentements> consentementsLotAProvider =
    Provider<PortConsentements>(
      (Ref ref) => ConsentementsSupabase(
        acceptations: ref.watch(serviceAcceptationsProvider),
        dossier: ref.watch(serviceDossierProvider),
        profilId: ref.watch(
          sessionProvider.select((SessionState s) => s.profileId),
        ),
      ),
    );

/// Les acceptations du titulaire connecte, relues a chaque invalidation.
final FutureProvider<List<Acceptation>> accordsTitulaireProvider =
    FutureProvider<List<Acceptation>>(
      (Ref ref) => ref.watch(consentementsLotAProvider).signees(),
    );
