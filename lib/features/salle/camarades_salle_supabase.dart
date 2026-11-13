// CAMARADES (directeur, 12/11/2026) : l'adaptateur Supabase des prenoms de
// la Classe de l'eleve connecte.
//
// `camarades_classe_eleve()` (migration 20261124300000, a installer par le
// directeur) rend le prenom des membres actifs de la Classe a TOUT eleve,
// enfant compris. Tant qu'elle n'est pas installee, le serveur repond que la
// fonction n'existe pas : l'adaptateur relit alors l'ancienne
// `participants_classe_eleve_adulte()` (l'eleve adulte seul, rien pour un
// enfant), sans aucune erreur montree. Un refus du serveur (compte qui n'est
// pas eleve) rend une liste vide.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'annuaire_seance.dart' show CamaradeSeance;
import 'camarades_salle.dart';
import 'reprise_support_supabase.dart' show fonctionAbsente;

/// Les prenoms de la Classe lus sur Supabase.
class CamaradesSalleSupabase implements PortCamaradesSalle {
  /// Cree l'adaptateur.
  const CamaradesSalleSupabase(this._client);

  final SupabaseClient _client;

  /// La lecture de ce lot.
  static const String fonction = 'camarades_classe_eleve';

  /// L'ancienne lecture, celle de l'eleve adulte (20261102700000).
  static const String fonctionAdulte = 'participants_classe_eleve_adulte';

  @override
  Future<List<CamaradeSeance>> camarades() async {
    try {
      return camaradesDepuisReponse(await _client.rpc<Object?>(fonction));
    } on PostgrestException catch (erreur) {
      if (erreur.code == '42501') return const <CamaradeSeance>[];
      if (!fonctionAbsente(erreur.code)) rethrow;
    }
    try {
      return camaradesDepuisReponse(await _client.rpc<Object?>(fonctionAdulte));
    } on PostgrestException catch (erreur) {
      if (fonctionAbsente(erreur.code)) return const <CamaradeSeance>[];
      rethrow;
    }
  }
}
