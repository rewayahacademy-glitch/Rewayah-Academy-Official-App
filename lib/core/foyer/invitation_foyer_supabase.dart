import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'invitation_conjoint.dart';
import 'port_lecture_invitation_recue.dart';
import 'port_reponse_invitation.dart';

class InvitationConjointSupabase implements PortInvitationConjoint {
  const InvitationConjointSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResultatInvitation> envoyer(InvitationConjoint invitation) async {
    try {
      final Map<String, dynamic> response =
          await _client.rpc<Map<String, dynamic>>(
        'inviter_conjoint',
        params: <String, dynamic>{
          'p_email': invitation.courriel.trim(),
          'p_cle': invitation.cle,
        },
      );
      if (response['queued'] == true &&
          response['invitation_id'] is String) {
        return const InvitationPartie();
      }
      return const InvitationRefusee();
    } on PostgrestException {
      return const InvitationRefusee();
    } on Object {
      return const InvitationEchecReseau();
    }
  }

  @override
  Future<ResultatAnnulation> annuler() async {
    try {
      final bool? response =
          await _client.rpc<bool?>('annuler_invitation_conjoint');
      if (response == null) {
        throw const FormatException('Réponse d’annulation invalide');
      }
      // false signifie qu'il n'y avait déjà plus d'invitation active : l'état
      // serveur demandé est atteint et la page peut relire le foyer.
      return const AnnulationFaite();
    } on Object {
      return const AnnulationEchecReseau();
    }
  }
}

class ReponseInvitationSupabase implements PortReponseInvitation {
  const ReponseInvitationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResultatReponseInvitation> accepter({required String cle}) =>
      _repondre('accepter', cle);

  @override
  Future<ResultatReponseInvitation> refuser({required String cle}) =>
      _repondre('refuser', cle);

  Future<ResultatReponseInvitation> _repondre(String decision, String cle) async {
    try {
      final Map<String, dynamic> response =
          await _client.rpc<Map<String, dynamic>>(
        'repondre_invitation_conjoint',
        params: <String, dynamic>{'p_decision': decision, 'p_cle': cle},
      );
      return ReponseRecue(_etatInvitation(response));
    } on PostgrestException {
      return const ReponseRecue(InvitationNonAcceptable());
    } on Object {
      return const ReponseEchecReseau();
    }
  }
}

class LectureInvitationRecueSupabase implements PortLectureInvitationRecue {
  const LectureInvitationRecueSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtatInvitationRecue> lireInvitationEnCours() async {
    final Map<String, dynamic> response =
        await _client.rpc<Map<String, dynamic>>('mon_invitation_en_cours');
    return _etatInvitation(response);
  }
}

EtatInvitationRecue _etatInvitation(Map<String, dynamic> value) {
  final String? state = value['etat'] as String?;
  final DateTime? registeredAt =
      DateTime.tryParse(value['enregistree_le']?.toString() ?? '')?.toUtc();

  return switch (state) {
    'a_repondre' => InvitationARepondre(
        prenomTitulaire: _requiredString(value, 'prenom_titulaire'),
        titulaireFeminin: value['titulaire_feminin'] as bool? ?? false,
        validationRequise: value['validation_requise'] as bool? ?? false,
        dureeConservation: value['duree_conservation'] as String?,
      ),
    'acceptee' => InvitationAcceptee(
        value['prenom_titulaire'] as String? ?? '',
        enregistreeLe: registeredAt,
      ),
    'attente_validation_admin' => const InvitationEnValidation(),
    'refusee' => InvitationRefuseeParVous(enregistreeLe: registeredAt),
    'non_acceptable' => const InvitationNonAcceptable(),
    'perimee' => const InvitationPerimee(),
    _ => throw const FormatException('État d’invitation Supabase invalide'),
  };
}

String _requiredString(Map<String, dynamic> value, String key) {
  final Object? raw = value[key];
  if (raw is String && raw.trim().isNotEmpty) return raw;
  throw FormatException('Champ $key absent de l’invitation Supabase');
}

final Provider<PortInvitationConjoint> portInvitationConjointProvider =
    Provider<PortInvitationConjoint>(
  (Ref ref) => InvitationConjointSupabase(Supabase.instance.client),
);

final Provider<PortReponseInvitation> portReponseInvitationProvider =
    Provider<PortReponseInvitation>(
  (Ref ref) => ReponseInvitationSupabase(Supabase.instance.client),
);

final Provider<PortLectureInvitationRecue> portLectureInvitationRecueProvider =
    Provider<PortLectureInvitationRecue>(
  (Ref ref) => LectureInvitationRecueSupabase(Supabase.instance.client),
);

final FutureProvider<EtatInvitationRecue> invitationRecueProvider =
    FutureProvider<EtatInvitationRecue>(
  (Ref ref) =>
      ref.watch(portLectureInvitationRecueProvider).lireInvitationEnCours(),
);
