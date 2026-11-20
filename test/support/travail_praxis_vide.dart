// Le service du travail de Praxis (PRAXIS-VISIBLE) pour les tests qui montent un
// dossier de candidature ou la file sans s'en occuper : rien de range, rien de
// lu, aucun objectif, lecture qui reussit. Sans lui, la carte « L'avis de
// Praxis » du dossier montrerait son etat d'erreur (la vraie source lit
// Supabase, absent sous test). Un test du travail de Praxis fournit le sien.

import 'package:rewayah_academy/core/agent/travail_praxis.dart';

/// Rien a lire.
class TravailPraxisVide implements ServiceTravailPraxis {
  /// Cree le double.
  const TravailPraxisVide();

  @override
  Future<PageRangements> rangements({
    PilePraxis? pile,
    int limite = 200,
    int decalage = 0,
  }) async => const PageRangements(
    lignes: <RangementPraxis>[],
    total: 0,
    parPile: <PilePraxis, int>{},
  );

  @override
  Future<PageImpressions> impressions({
    EtiquettePraxis? etiquette,
    int limite = 200,
    int decalage = 0,
  }) async => const PageImpressions(
    lignes: <ImpressionPraxis>[],
    total: 0,
    parEtiquette: <EtiquettePraxis, int>{},
  );

  @override
  Future<List<ObjectifPraxis>> objectifs({
    bool tous = true,
    int limite = 50,
    int decalage = 0,
  }) async => const <ObjectifPraxis>[];
}
