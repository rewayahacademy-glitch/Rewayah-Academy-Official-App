/// BACK-FRONT-REPRISE-1 : la file des reprises de foyer, cote administration.
///
/// Decision du directeur (10/10/2026, Questions F50, K-65) : le titulaire peut
/// refuser tant que l'administration n'a pas decide ; l'administration decide
/// la reprise ; un refus laisse redeposer apres un delai, rendu par le serveur.
/// Le serveur dit quelles demandes sont decidables ([RepriseAdmin.decidable],
/// capacite lue par l'ecran, jamais un role) : Flutter ne calcule ni delai ni
/// droit. La decision part avec une cle d'idempotence.
///
/// Aucun branchement serveur : en production le port est absent
/// ([portReprisesAdminProvider] vaut `null`) et l'ecran dit « disponible au
/// branchement serveur ». Signature proposee en Contrats (C-23) ; l'adaptateur
/// reel s'appuie sur `decider_reprise_foyer` (B-04).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';

/// La dependance serveur de l'ecran (ligne Backend B-04).
const String dependanceReprisesAdmin = 'B-04';

/// Ou en est une demande, vue de l'administration.
enum EtatRepriseAdmin {
  /// Elle attend la decision de l'administration.
  aExaminer,

  /// Le titulaire l'a refusee : l'administration en est informee.
  refuseeParTitulaire,
}

/// Une demande de reprise de foyer.
@immutable
class RepriseAdmin {
  /// Cree la demande. [deposeeLe] et [examenPossibleLe] : heures murales du
  /// fuseau de l'administration, rendues par le serveur.
  const RepriseAdmin({
    required this.id,
    required this.demandeurPrenom,
    required this.demandeurNom,
    required this.foyerNom,
    required this.etat,
    required this.decidable,
    this.deposeeLe,
    this.examenPossibleLe,
  });

  /// L'identifiant de la demande.
  final String id;

  /// Le prenom du second adulte qui demande.
  final String demandeurPrenom;

  /// Son nom.
  final String demandeurNom;

  /// Le foyer concerne, tel que l'administration le designe.
  final String foyerNom;

  /// Son etat.
  final EtatRepriseAdmin etat;

  /// Capacite rendue par le serveur : l'administration peut decider
  /// maintenant (sinon le titulaire garde la main, ou la demande est close).
  final bool decidable;

  /// Le depot.
  final DateTime? deposeeLe;

  /// La date a partir de laquelle l'administration pourra examiner la demande
  /// sans reponse du titulaire, si le serveur la rend.
  final DateTime? examenPossibleLe;
}

/// La reponse du serveur a une decision.
sealed class ResultatDecisionReprise {
  const ResultatDecisionReprise();
}

/// Decision enregistree ; la liste se relit ensuite.
final class RepriseDecidee extends ResultatDecisionReprise {
  /// Cree la reponse.
  const RepriseDecidee();
}

/// La demande n'est plus decidable (le titulaire a refuse entre-temps, ou une
/// autre decision existe) : ce n'est pas une panne, la liste est relue.
final class RepriseDejaTraitee extends ResultatDecisionReprise {
  /// Cree la reponse.
  const RepriseDejaTraitee();
}

/// La connexion a coupe : la decision n'est pas confirmee ; la meme cle rend
/// une nouvelle tentative sure.
final class RepriseDecisionEchecReseau extends ResultatDecisionReprise {
  /// Cree la reponse.
  const RepriseDecisionEchecReseau();
}

/// Le port de l'administration.
abstract interface class PortReprisesAdmin {
  /// Les demandes a traiter ou que le titulaire a refusees, la plus ancienne
  /// d'abord.
  Future<List<RepriseAdmin>> lister();

  /// Decide : [approuver] valide la reprise, sinon la refuse. Idempotent par
  /// [cle].
  Future<ResultatDecisionReprise> decider({
    required String repriseId,
    required bool approuver,
    required String cle,
  });
}

/// Le port : absent avant le branchement serveur.
final Provider<PortReprisesAdmin?> portReprisesAdminProvider =
    Provider<PortReprisesAdmin?>((Ref _) => null);

/// Les demandes. Sans port : [CapaciteIndisponible].
final FutureProvider<List<RepriseAdmin>> reprisesAdminProvider =
    FutureProvider<List<RepriseAdmin>>((Ref ref) {
      final PortReprisesAdmin? port = ref.watch(portReprisesAdminProvider);
      if (port == null) {
        return Future<List<RepriseAdmin>>.error(
          const CapaciteIndisponible(dependanceReprisesAdmin),
        );
      }
      return port.lister();
    }, retry: (int _, Object _) => null);
