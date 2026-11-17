// Le service des propositions de Praxis (PX-2) pour les tests qui montent un
// dossier de candidature sans s'en occuper : aucune proposition, lecture qui
// reussit. Sans lui, le bloc du dossier montrerait son etat d'erreur (la vraie
// source lit Supabase, absent sous test). Un test des propositions fournit le
// sien ; un test qui veut l'etat d'erreur lui fait lever une exception.

import 'package:rewayah_academy/core/agent/propositions_praxis.dart';

/// Aucune proposition.
class PropositionsPraxisVides implements ServicePropositionsPraxis {
  /// Cree le double.
  const PropositionsPraxisVides();

  @override
  Future<List<PropositionPraxis>> ouvertes() async =>
      const <PropositionPraxis>[];

  @override
  Future<ResultatProposition> valider({
    required String id,
    required int version,
    required String cle,
    List<String>? participants,
  }) async =>
      const ResultatProposition(fait: false, erreur: 'proposition_inconnue');

  @override
  Future<ResultatProposition> ecarter({
    required String id,
    required String cle,
    String? motif,
  }) async =>
      const ResultatProposition(fait: false, erreur: 'proposition_inconnue');
}
