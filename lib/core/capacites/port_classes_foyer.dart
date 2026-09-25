import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_groupe/group_summary_vm.dart';
import 'capacite_indisponible.dart';
import 'classes_foyer_supabase.dart';

/// Une classe du foyer, vue pour un eleve precis.
@immutable
class ClasseFoyer {
  /// Cree la classe d'un eleve.
  const ClasseFoyer({required this.eleveId, required this.classe});

  /// L'eleve du foyer inscrit dans cette classe.
  final String eleveId;

  /// La classe, telle que l'Espace Groupe la lit.
  final GroupSummaryVM classe;
}

/// Les classes du foyer, par eleve (contrat K6, consommateurs : Accueil,
/// Classe, Historique).
abstract interface class PortClassesFoyer {
  /// Les classes courantes d'un eleve.
  Future<List<ClasseFoyer>> classesDe(String eleveId);

  /// Une classe precise pour un eleve, `null` si l'eleve n'y est pas (ou
  /// plus) inscrit.
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  });
}

/// Les classes du foyer tant qu'aucune source reelle n'est branchee.
///
/// **La source existe mais n'est pas sur cette base** (DB-TRV-07) : la lecture
/// de `mes_groupes_famille_v` (`GroupesSupabase`) n'existe que dans le commit
/// `33503fe`, repris en phase 0a. L'adaptateur reel
/// `lib/core/capacites/classes_foyer_supabase.dart` est ecrit par le **lot C**
/// (`00_OWNERSHIP.md` section 3) : jointure de `groupe_membres` (RLS foyer,
/// `0019`) et de `mes_groupes_famille_v`, classes courantes seulement (les
/// classes quittees attendent DB-CRS-01). Le lot C remplace alors
/// l'implementation du provider ci-dessous ; jamais le double de
/// demonstration des groupes.
class ClassesFoyerIndisponible implements PortClassesFoyer {
  /// Cree l'implementation.
  const ClassesFoyerIndisponible();

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) =>
      Future<List<ClasseFoyer>>.error(const CapaciteIndisponible('DB-TRV-07'));

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) => Future<ClasseFoyer?>.error(const CapaciteIndisponible('DB-TRV-07'));
}

/// Les classes du foyer employees par l'application : l'adaptateur reel
/// (lectures sous RLS, `0019`), branche par le coordinateur le 25/09 (revue C,
/// M2 ; demandes C-1, C-12). [ClassesFoyerIndisponible] reste le double des
/// tests qui veulent l'etat « pas encore relie ».
final Provider<PortClassesFoyer> portClassesFoyerProvider =
    Provider<PortClassesFoyer>(
      (Ref ref) => ClassesFoyerSupabase(Supabase.instance.client),
    );
