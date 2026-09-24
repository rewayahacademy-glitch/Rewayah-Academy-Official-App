import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// La nature d'un canal d'aide.
enum NatureCanalSupport {
  /// Une adresse de courriel.
  courriel,

  /// Un lien vers une page d'aide.
  lien,
}

/// Le canal par lequel une famille joint l'academie.
@immutable
class CanalSupport {
  /// Cree un canal.
  const CanalSupport({required this.nature, required this.adresse});

  /// Courriel ou lien.
  final NatureCanalSupport nature;

  /// L'adresse, telle que l'academie la fournit.
  final String adresse;
}

/// Le canal d'aide (contrat K6).
abstract interface class PortSupport {
  /// Le canal d'aide. `null` : aucun canal publie.
  Future<CanalSupport?> canal();
}

/// Le canal d'aide tant qu'aucun n'est decide (DB-CPT-07 : decision du
/// directeur, et au besoin un paquet d'ouverture de lien). Aucun adaptateur
/// prevu.
class SupportIndisponible implements PortSupport {
  /// Cree l'implementation.
  const SupportIndisponible();

  @override
  Future<CanalSupport?> canal() =>
      Future<CanalSupport?>.error(const CapaciteIndisponible('DB-CPT-07'));
}

/// Le canal d'aide employe par l'application.
final Provider<PortSupport> portSupportProvider = Provider<PortSupport>(
  (Ref ref) => const SupportIndisponible(),
);
