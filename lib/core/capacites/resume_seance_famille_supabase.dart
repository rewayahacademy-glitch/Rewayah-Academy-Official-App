import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_resume_seance_famille.dart';

/// Lecture du seul texte explicitement publié pour l'élève et la séance.
class ResumeSeanceFamilleSupabase implements PortResumeSeanceFamille {
  const ResumeSeanceFamilleSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> resume({
    required String seanceId,
    required String eleveId,
  }) {
    return _client.rpc<String?>(
      'resume_seance_famille',
      params: <String, dynamic>{
        'p_session_id': seanceId,
        'p_student_id': eleveId,
      },
    );
  }
}
