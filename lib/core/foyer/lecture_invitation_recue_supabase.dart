import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_lecture_invitation_recue.dart';
import 'port_reponse_invitation.dart';

/// Adaptateur de la RPC `mon_invitation_en_cours()` (migration 0053).
class LectureInvitationRecueSupabase implements PortLectureInvitationRecue {
  /// Utilise la session Supabase courante; aucun identifiant n'est transmis.
  const LectureInvitationRecueSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtatInvitationRecue> lireInvitationEnCours() async {
    final Object? reponse = await _client.rpc<Object?>(
      'mon_invitation_en_cours',
    );
    return etatDepuisReponse(reponse);
  }

  /// Décode le même contrat JSON que `repondre_invitation_conjoint()`.
  static EtatInvitationRecue etatDepuisReponse(Object? value) {
    final Map<String, dynamic> json = _map(value);
    final Object? etat = json['etat'];
    switch (etat) {
      case 'a_repondre':
        final Object? feminin = json['titulaire_feminin'];
        final Object? validationRequise = json['validation_requise'];
        final Object? dureeConservation = json['duree_conservation'];
        if (feminin is! bool ||
            (validationRequise != null && validationRequise is! bool) ||
            (dureeConservation != null && dureeConservation is! String)) {
          throw const FormatException('Projection invitation invalide.');
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

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Réponse RPC invitation invalide.');
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
