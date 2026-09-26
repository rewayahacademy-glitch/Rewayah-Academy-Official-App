// Port de la politique de revue des pieces (AD-4, contrat 17.5,
// `get_kyc_review_policy` / `set_kyc_review_policy`). La capacite Super Admin
// est lue ici (`peutModifier`), jamais deduite d'`app_role` (Q40).
//
// Erreurs metier reutilisees : `ErreurRevueDossier` avec `interdit`, `perime`
// ou `indisponibleTemporairement`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// La politique en vigueur.
@immutable
class PolitiqueRevueKyc {
  const PolitiqueRevueKyc({
    required this.genreRelecteurApplique,
    required this.version,
    required this.modifieeLeUtc,
    required this.peutModifier,
  });

  /// Vrai : un relecteur ne voit que les pieces de son genre.
  final bool genreRelecteurApplique;
  final int version;
  final DateTime modifieeLeUtc;

  /// Capacite Super Admin du lecteur courant.
  final bool peutModifier;
}

/// Lecture et mutation de la politique.
abstract interface class PortPolitiqueRevueKyc {
  Future<PolitiqueRevueKyc> lire();

  Future<PolitiqueRevueKyc> modifier({
    required bool genreRelecteurApplique,
    required int versionAttendue,
  });
}

/// L'implementation par defaut : rien ne sert encore ce contrat.
class PolitiqueRevueKycIndisponible implements PortPolitiqueRevueKyc {
  const PolitiqueRevueKycIndisponible();

  @override
  Future<PolitiqueRevueKyc> lire() =>
      Future<PolitiqueRevueKyc>.error(const CapaciteIndisponible('AD-BR-16'));

  @override
  Future<PolitiqueRevueKyc> modifier({
    required bool genreRelecteurApplique,
    required int versionAttendue,
  }) => Future<PolitiqueRevueKyc>.error(const CapaciteIndisponible('AD-BR-17'));
}

/// Le port employe par l'application. Indisponible par defaut (K-09).
final Provider<PortPolitiqueRevueKyc> portPolitiqueRevueKycProvider =
    Provider<PortPolitiqueRevueKyc>(
      (Ref ref) => const PolitiqueRevueKycIndisponible(),
    );
