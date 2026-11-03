// D1-ter (03/11/2026) : l'adaptateur Supabase des messages de l'academie, sur
// la vue `concern_famille_v` (migration 20261106600000, lecture seule). La RLS
// et le filtre de la vue decident ; l'adaptateur ne fait que lire.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_parcours/student_concern.dart';
import 'port_messages_academie.dart';

/// Les colonnes lues : jamais une colonne de note interne (la vue n'en a pas).
const String colonnesMessagesAcademie =
    'id, categorie, family_summary, transmis_le, transmis_a';

/// Lit les lignes de la vue. Pure, pour les tests ; une ligne illisible
/// (categorie inconnue, message vide, securite d'un enfant) est ecartee,
/// jamais completee.
List<ResumeFamilleSignalement> messagesAcademieDepuisJson(Object? lignes) =>
    <ResumeFamilleSignalement>[
      for (final Object? l in lignes is List ? lignes : const <Object?>[])
        if (l is Map)
          if ((
                CategorieSignalement.depuisSql('${l['categorie']}'),
                (l['family_summary'] as String? ?? '').trim(),
              )
              case (final CategorieSignalement categorie, final String message)
              when message.isNotEmpty && !categorie.estSecuriteEnfant)
            ResumeFamilleSignalement(
              concernId: '${l['id']}',
              categorie: categorie,
              message: message,
              transmisA: CibleTransmission.depuisSql('${l['transmis_a']}'),
              transmisLeUtc: DateTime.tryParse('${l['transmis_le']}')?.toUtc(),
            ),
    ];

/// Les messages de l'academie servis par Supabase.
class MessagesAcademieSupabase implements PortMessagesAcademie {
  /// Cree l'adaptateur.
  const MessagesAcademieSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ResumeFamilleSignalement>> pourEleve(String? eleveId) async {
    final PostgrestFilterBuilder<List<Map<String, dynamic>>> requete = _client
        .from('concern_famille_v')
        .select(colonnesMessagesAcademie);
    final String? id = eleveId;
    return messagesAcademieDepuisJson(
      await (id == null ? requete : requete.eq('student_id', id))
          .order('transmis_le', ascending: false)
          .limit(20),
    );
  }
}
