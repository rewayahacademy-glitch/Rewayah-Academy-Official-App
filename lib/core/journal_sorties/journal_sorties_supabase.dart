// HORS-SALLE-2 : l'adaptateur Supabase du journal des sorties, sur les cinq
// fonctions de `20261124200000_journal_sorties.sql` (accords_sorties,
// accepter_accord_sorties, retirer_accord_sorties, noter_sortie_app,
// sorties_seance) et sur `regles_academie()` pour les reglages publics.
//
// Le client est lu a chaque appel (jamais a la construction) : un test ou une
// demonstration sans Supabase ne casse rien, l'appel echoue et se replie.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';
import 'port_journal_sorties.dart';

/// Vrai quand l'erreur dit que la fonction n'existe pas sur ce serveur
/// (PostgREST `PGRST202`, Postgres `42883`) : serveur d'avant le lot.
bool fonctionAbsente(Object e) =>
    e is PostgrestException && (e.code == 'PGRST202' || e.code == '42883');

/// Vrai quand le serveur refuse ce compte (`42501`).
bool refusServeur(Object e) => e is PostgrestException && e.code == '42501';

/// Le journal des sorties, lu et ecrit par les fonctions du serveur.
class JournalSortiesSupabase implements PortJournalSorties {
  /// Cree l'adaptateur.
  const JournalSortiesSupabase(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<bool> noterSortie({
    required String seanceId,
    required int secondes,
    required bool sortieSalle,
    String? eleveId,
  }) async {
    try {
      final Object? brut = await _client().rpc<Object?>(
        'noter_sortie_app',
        params: <String, dynamic>{
          'p_session_id': seanceId,
          'p_secondes': secondes,
          'p_sortie_salle': sortieSalle,
          'p_eleve': ?eleveId,
        },
      );
      return brut is Map && brut['note'] == true;
    } on Object catch (e) {
      // Jamais visible chez l'eleve : une trace de developpement seulement.
      journalDev('sortie de l application non notee : $e');
      return false;
    }
  }

  @override
  Future<List<SortieApp>> sortiesSeance(String seanceId) async {
    try {
      final List<dynamic> lignes = await _client().rpc<List<dynamic>>(
        'sorties_seance',
        params: <String, dynamic>{'p_session_id': seanceId},
      );
      return <SortieApp>[
        for (final Object? l in lignes)
          if (l is Map<String, dynamic>) SortieApp.depuisJson(l),
      ];
    } on Object catch (e) {
      journalDev('journal des sorties illisible : $e');
      return const <SortieApp>[];
    }
  }

  Future<EtatAccordsSorties> _etat(
    String fonction,
    Map<String, dynamic> parametres,
  ) async {
    final Object? brut = await _client().rpc<Object?>(
      fonction,
      params: parametres,
    );
    if (brut is! Map) {
      throw FormatException('Reponse de $fonction invalide.');
    }
    final Map<String, dynamic> json = Map<String, dynamic>.from(brut);
    switch (json['erreur']) {
      case 'version_perimee':
        throw const AccordSortiesRefuse(MotifRefusAccord.versionPerimee);
      case 'journal_eteint' || 'texte_indisponible':
        throw const AccordSortiesRefuse(MotifRefusAccord.journalEteint);
    }
    return EtatAccordsSorties.depuisJson(json);
  }

  @override
  Future<EtatAccordsSorties?> accords() async {
    try {
      return await _etat('accords_sorties', const <String, dynamic>{});
    } on Object catch (e) {
      if (fonctionAbsente(e) || refusServeur(e)) return null;
      rethrow;
    }
  }

  @override
  Future<EtatAccordsSorties> accepter({
    required String eleveId,
    required String version,
  }) => _etat('accepter_accord_sorties', <String, dynamic>{
    'p_eleve': eleveId,
    'p_version': version,
  });

  @override
  Future<EtatAccordsSorties> retirer(String eleveId) =>
      _etat('retirer_accord_sorties', <String, dynamic>{'p_eleve': eleveId});

  @override
  Future<ReglagesSorties?> reglages() async {
    try {
      return ReglagesSorties.depuisRegles(
        await _client().rpc<Object?>('regles_academie'),
      );
    } on Object catch (e) {
      journalDev('reglages du journal des sorties illisibles : $e');
      return null;
    }
  }
}
