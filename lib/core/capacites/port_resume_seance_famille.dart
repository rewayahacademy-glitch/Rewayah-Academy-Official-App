import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Le resume d'une seance destine a la famille d'un eleve (contrat K6).
abstract interface class PortResumeSeanceFamille {
  /// Le resume de [seanceId] pour [eleveId]. `null` : aucun resume redige.
  Future<String?> resume({required String seanceId, required String eleveId});
}

/// Le resume tant qu'aucune projection serveur n'existe (DB-CRS-12).
///
/// **Jamais `lesson_reports`** : ce cahier porte les decisions de tous les
/// eleves du groupe et une note interne (DB-TRV-02). La section est absente du
/// detail de seance, sans etat vide trompeur. Aucun adaptateur prevu.
class ResumeSeanceFamilleIndisponible implements PortResumeSeanceFamille {
  /// Cree l'implementation.
  const ResumeSeanceFamilleIndisponible();

  @override
  Future<String?> resume({required String seanceId, required String eleveId}) =>
      Future<String?>.error(const CapaciteIndisponible('DB-CRS-12'));
}

/// Le resume de seance employe par l'application.
final Provider<PortResumeSeanceFamille> portResumeSeanceFamilleProvider =
    Provider<PortResumeSeanceFamille>(
      (Ref ref) => const ResumeSeanceFamilleIndisponible(),
    );
