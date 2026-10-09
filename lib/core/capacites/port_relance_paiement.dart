// « Relancer » un beneficiaire (spec §27 ; CPT-BR-11). Pose par CPT-F avec
// son interface complete ; **propriete de la voie CPT-BEN** jusqu'a CPT-COM,
// qui le remplace par le `PortMessagesMetier` de Communications V1
// (`filPourObjet('profilPaiement', beneficiaireId)`) puis le supprime : un
// seul port (`20_comptable/02_DECOUPAGE.md`, liste B et D).
//
// Aucune messagerie Finance (R-FIN-21) : la relance ouvre ou utilise le fil
// metier contextuel, objet « Profil de paiement », message modele §27.3
// prerempli. Le contractuel externe n'a pas de fil : « Renvoyer
// l'invitation » (CPT-BR-08).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Le type d'objet du fil metier de la relance, tel que COM-BR-01 le nomme.
const String typeObjetProfilPaiement = 'profilPaiement';

/// Une relance preparee : l'identifiant du fil et le message modele rendu
/// par la source (§27.3), **jamais « envoyee »** tant que le fil reel n'est
/// pas branche (CPT-COM).
@immutable
class RelancePreparee {
  /// Cree la relance.
  const RelancePreparee({
    required this.filId,
    required this.beneficiaireId,
    required this.messageModele,
    this.route,
  });

  /// L'identifiant du fil metier.
  final String filId;

  /// Le beneficiaire.
  final String beneficiaireId;

  /// Le message modele prerempli, rendu par la source.
  final String messageModele;

  /// La route du fil dans l'application, quand elle existe (CPT-COM).
  final String? route;
}

/// La relance (CPT-BR-11).
abstract interface class PortRelancePaiement {
  /// Prepare ou ouvre le fil « Profil de paiement » du beneficiaire.
  Future<RelancePreparee> relancer(String beneficiaireId);
}

/// **Aucune source serveur a ce jour** (CPT-BR-11).
class RelancePaiementIndisponible implements PortRelancePaiement {
  /// Cree l'implementation.
  const RelancePaiementIndisponible();

  @override
  Future<RelancePreparee> relancer(String beneficiaireId) =>
      Future<RelancePreparee>.error(const CapaciteIndisponible('CPT-BR-11'));
}

/// Le port ; la demonstration le surcharge (`beneficiaires_demo.dart`).
final Provider<PortRelancePaiement> portRelancePaiementProvider =
    Provider<PortRelancePaiement>(
      (Ref _) => const RelancePaiementIndisponible(),
    );
