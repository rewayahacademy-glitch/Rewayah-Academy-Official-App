import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/admin/service_comptes.dart';
import 'conformite.dart';
import 'ports.dart';

/// Projection KYC V2 decidee par la base, y compris dispense et photo.
class ConformiteDepuisServeur implements PortConformite {
  const ConformiteDepuisServeur({required this.client, required this.comptes});

  final SupabaseClient Function() client;
  final ServiceComptes Function() comptes;

  @override
  Future<ConformiteCompte> laMienne() async => _depuisJson(
    (await client().rpc('conformite_classe')) as Map<String, dynamic>,
  );

  @override
  Future<Map<String, ConformiteCompte>> pourComptes() async {
    final Map<String, ConformiteCompte> result = <String, ConformiteCompte>{};
    for (final CompteAdmin compte in await comptes().comptes()) {
      final Map<String, dynamic> json = await client().rpc(
        'conformite_classe',
        params: <String, dynamic>{'p_profile_id': compte.profilId},
      ) as Map<String, dynamic>;
      result[compte.profilId] = _depuisJson(json);
    }
    return result;
  }

  @override
  Future<void> definirExigenceKyc({
    required String profilId,
    required bool requise,
    required String motif,
  }) async {
    await client().rpc(
      'definir_exigence_kyc_enseignant',
      params: <String, dynamic>{
        'p_teacher_id': profilId,
        'p_required': requise,
        'p_reason': motif,
      },
    );
  }

  ConformiteCompte _depuisJson(Map<String, dynamic> json) {
    final String requirement = json['kyc_requirement'] as String? ?? 'required';
    final String status = json['kyc_status'] as String? ?? 'not_started';
    final Map<String, dynamic>? waiver = json['waiver'] is Map<String, dynamic>
        ? json['waiver'] as Map<String, dynamic>
        : null;
    return ConformiteCompte(
      exigence: switch (requirement) {
        'optional' => ExigenceKyc.optionnelle,
        'waived' => ExigenceKyc.dispensee,
        _ => ExigenceKyc.requise,
      },
      etat: switch (status) {
        'submitted' => EtatKyc.soumis,
        'verified' => EtatKyc.verifie,
        'correction_required' => EtatKyc.correctionDemandee,
        'rejected' => EtatKyc.refuse,
        _ => EtatKyc.nonCommence,
      },
      contratAccepte: json['teacher_contract_accepted'] == true,
      dispense: waiver == null
          ? null
          : DispenseKyc(
              acteur: waiver['actor'] as String? ?? '',
              date: DateTime.parse(waiver['changed_at'] as String),
              motif: waiver['reason'] as String?,
            ),
      photoIdentificationPresente: json['live_photo_uploaded'] as bool?,
    );
  }
}
