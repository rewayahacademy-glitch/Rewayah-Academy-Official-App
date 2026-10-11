import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_invitation_conjoint.dart';
import 'port_reponse_invitation.dart';

/// Adaptateurs des RPC 0053 pour l'invitation entre adultes d'un foyer.
///
/// Les RPC fixent le compte et le foyer depuis la session; l'adaptateur ne
/// transmet donc ni identifiant de profil ni identifiant de foyer.
class InvitationsConjointSupabase
    implements PortInvitationConjoint, PortReponseInvitation {
  /// Cree l'adaptateur avec le client de la session courante.
  const InvitationsConjointSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResultatInvitation> envoyer(InvitationConjoint invitation) async {
    try {
      final Map<String, dynamic> reponse = _map(
        await _client.rpc<dynamic>(
          'inviter_conjoint',
          params: <String, dynamic>{
            'p_email': invitation.courriel.trim(),
            'p_cle': invitation.cle,
          },
        ),
      );
      final Object? queued = reponse['queued'];
      if (queued is! bool) {
        throw const FormatException('Réponse inviter_conjoint invalide.');
      }
      return queued ? const InvitationPartie() : const InvitationRefusee();
    } on PostgrestException {
      // Le contrat masque volontairement la raison d'un refus serveur.
      return const InvitationRefusee();
    }
  }

  @override
  Future<ResultatAnnulation> annuler() async {
    try {
      final Object? reponse = await _client.rpc<dynamic>(
        'annuler_invitation_conjoint',
      );
      if (reponse is! bool) {
        throw const FormatException(
          'Réponse annuler_invitation_conjoint invalide.',
        );
      }
      // `false` signifie qu'aucune invitation active n'a été annulée: le
      // contrat n'autorise pas à afficher un succès dans ce cas.
      return reponse ? const AnnulationFaite() : const AnnulationEchecReseau();
    } on PostgrestException {
      // L'annulation n'est jamais annoncée comme réussie sans accusé serveur.
      return const AnnulationEchecReseau();
    }
  }

  @override
  Future<ResultatReponseInvitation> accepter({required String cle}) =>
      _repondre(decision: 'accepter', cle: cle);

  @override
  Future<ResultatReponseInvitation> refuser({required String cle}) =>
      _repondre(decision: 'refuser', cle: cle);

  Future<ResultatReponseInvitation> _repondre({
    required String decision,
    required String cle,
  }) async {
    final Map<String, dynamic> reponse = _map(
      await _client.rpc<dynamic>(
        'repondre_invitation_conjoint',
        params: <String, dynamic>{'p_decision': decision, 'p_cle': cle},
      ),
    );
    return ReponseRecue(_etat(reponse));
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Réponse RPC invitation invalide.');
  }

  static EtatInvitationRecue _etat(Map<String, dynamic> json) {
    final Object? etat = json['etat'];
    switch (etat) {
      case 'a_repondre':
        final Object? feminin = json['titulaire_feminin'];
        final Object? validationRequise = json['validation_requise'];
        final Object? dureeConservation = json['duree_conservation'];
        if (feminin is! bool ||
            (validationRequise != null && validationRequise is! bool) ||
            (dureeConservation != null && dureeConservation is! String)) {
          throw const FormatException('titulaire_feminin invalide.');
        }
        return InvitationARepondre(
          prenomTitulaire: _texte(json, 'prenom_titulaire'),
          titulaireFeminin: feminin,
          validationRequise: validationRequise as bool? ?? false,
          dureeConservation: dureeConservation as String?,
        );
      case 'acceptee':
        return InvitationAcceptee(
          _texte(json, 'prenom_titulaire'),
          enregistreeLe: _date(json['enregistree_le']),
        );
      case 'en_validation':
        return const InvitationEnValidation();
      case 'refusee':
        return InvitationRefuseeParVous(
          enregistreeLe: _date(json['enregistree_le']),
        );
      case 'non_acceptable':
        return const InvitationNonAcceptable();
      case 'perimee':
        return const InvitationPerimee();
      default:
        throw const FormatException('État RPC invitation inconnu.');
    }
  }

  static String _texte(Map<String, dynamic> json, String cle) {
    final Object? value = json[cle];
    if (value is String) return value;
    throw FormatException('Champ RPC invitation invalide: $cle.');
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Date RPC invitation invalide.');
    }
    final DateTime? date = DateTime.tryParse(value);
    if (date == null) {
      throw const FormatException('Date RPC invitation invalide.');
    }
    return date.toLocal();
  }
}
