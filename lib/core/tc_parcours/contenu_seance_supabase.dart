// La source du contenu de seance servie par Supabase, pour le travail a venir
// (« Avant le prochain cours ») : la reprise de groupe par la RPC
// `derniere_position_groupe` (migration 0033), bornee par le serveur a
// l'enseignant, a la direction et aux membres de la classe.
//
// Les deux lectures par seance (position de reprise, plages travaillees) ne
// servent pas au travail a venir et n'ont pas de RPC dediee : elles disent
// « inconnu », jamais une position inventee.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import '../tc_etat_partage/codec_etat_partage.dart';
import '../tc_outils/assignations_supabase.dart';
import 'port_travail_a_venir.dart';
import 'source_contenu_seance.dart';

/// La reprise de groupe lue sur Supabase.
class ContenuSeanceSupabase implements SourceContenuSeance {
  /// Cree la source sur le client de l'application.
  const ContenuSeanceSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ContentPosition?> positionDeReprise(String sessionId) async => null;

  @override
  Future<List<ContentRange>> rangesTravailles(String sessionId) async =>
      const <ContentRange>[];

  @override
  Future<ContentPosition?> repriseDeGroupe(String groupeId) async {
    final Object? brut = await _client.rpc<Object?>(
      'derniere_position_groupe',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    return brut is Map
        ? positionDepuisJson(Map<String, dynamic>.from(brut))
        : null;
  }
}

/// Le travail a venir de l'application : `assignations_a_venir` (plafond de
/// trois garanti par le serveur) et la reprise de groupe.
PortTravailAVenir travailAVenirSupabase(SupabaseClient client) =>
    TravailAVenir(AssignationsSupabase(client), ContenuSeanceSupabase(client));
