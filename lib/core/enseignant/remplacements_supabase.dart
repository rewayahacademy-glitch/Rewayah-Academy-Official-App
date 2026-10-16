// Les adaptateurs Supabase de l'absence sur une seance et de la reponse a une
// offre de remplacement (B-09), sur les RPC `declarer_absence_seance` et
// `prendre_remplacement` (migration 20261011185954).
//
// Le serveur decide de tout : le titulaire, la compatibilite du remplacant
// (genre, KYC, compte actif), la prise atomique. L'etat rendu est celui de
// sa reponse, jamais calcule ici (E6, E7).
//
// Le tableau commun des offres (`PortRemplacements.suivre`) n'a pas encore de
// RPC de lecture : il reste absent.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'absence_remplacement.dart';

const String _espaceCles = '6f1d2c84-93a7-5b0e-8c41-2e7a9d5b3f60';

/// La cle d'idempotence d'une action sur une seance : la meme seance et la
/// meme action donnent toujours la meme cle, d'un essai a l'autre.
String cleRemplacement(String action, String seanceId) =>
    const Uuid().v5(_espaceCles, '$action:$seanceId');

/// L'etat d'absence lu dans la reponse du serveur ; `null` s'il est inconnu.
EtatAbsence? etatAbsenceServeur(Object? reponse) {
  if (reponse is! Map) return null;
  return switch (reponse['etat']) {
    'absence_declaree' => EtatAbsence.enregistree,
    'remplacement_pris' ||
    'remplacement_designe_admin' => EtatAbsence.remplacantConfirme,
    _ => null,
  };
}

/// La declaration d'absence servie par Supabase.
class DeclarationAbsenceSupabase implements DeclarationAbsence {
  /// Cree l'adaptateur sur le client de l'application.
  const DeclarationAbsenceSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtatAbsence?> declarer(String seanceId) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'declarer_absence_seance',
        params: <String, dynamic>{
          'p_session_id': seanceId,
          'p_cle_idempotence': cleRemplacement('absence', seanceId),
        },
      );
      return etatAbsenceServeur(reponse);
    } on PostgrestException {
      // Refus (pas le titulaire, seance passee, absence deja declaree) : la
      // demande n'a pas abouti, l'ecran ne suppose aucun etat.
      return null;
    }
  }
}

/// La reponse a une offre de remplacement servie par Supabase.
class ReponseRemplacementSupabase implements ReponseRemplacement {
  /// Cree l'adaptateur sur le client de l'application.
  const ReponseRemplacementSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> assurer(OffreRemplacement offre) async {
    try {
      final Object? reponse = await _client.rpc<Object?>(
        'prendre_remplacement',
        params: <String, dynamic>{
          'p_session_id': offre.seanceId,
          'p_cle_idempotence': cleRemplacement('prise', offre.seanceId),
        },
      );
      // Seul `acceptee` confirme le remplacant ; `dejaPrise` ne change rien.
      return reponse is Map && reponse['etat'] == 'acceptee';
    } on PostgrestException {
      return false;
    }
  }
}
