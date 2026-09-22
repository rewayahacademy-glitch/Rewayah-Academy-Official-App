import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un enseignant que le serveur a juge admissible pour un groupe precis.
@immutable
class EnseignantAdmissible {
  const EnseignantAdmissible({
    required this.id,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.groupesActifs,
    required this.maxPrimaryGroups,
  });

  factory EnseignantAdmissible.depuisJson(Map<String, dynamic> json) =>
      EnseignantAdmissible(
        id: json['teacher_id'] as String,
        identifiant: json['teacher_immutable_id'] as String? ?? '',
        prenom: json['teacher_prenom'] as String?,
        nom: json['teacher_nom'] as String?,
        groupesActifs: (json['groupes_actifs'] as num?)?.toInt() ?? 0,
        maxPrimaryGroups: (json['max_primary_groups'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String identifiant;
  final String? prenom;
  final String? nom;
  final int groupesActifs;
  final int maxPrimaryGroups;

  String get libelle => <String?>[
    prenom,
    nom,
  ].whereType<String>().join(' ').trim().ifEmpty(identifiant);
}

@immutable
class OffreHoraireAdmin {
  const OffreHoraireAdmin({
    required this.id,
    required this.typePublic,
    required this.langueCode,
    required this.langueNom,
    required this.jours,
    required this.heureLocale,
    required this.dureeMinutes,
    required this.rythme,
    required this.etat,
    required this.candidats,
  });

  factory OffreHoraireAdmin.depuisJson(Map<String, dynamic> json) =>
      OffreHoraireAdmin(
        id: json['offre_id'] as String,
        typePublic: json['type_public'] as String? ?? '',
        langueCode: json['langue_code'] as String? ?? '',
        langueNom: json['langue_nom'] as String? ?? '',
        jours: (json['jours'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<num>()
            .map((num jour) => jour.toInt())
            .toList(growable: false),
        heureLocale: (json['heure_locale'] as num?)?.toInt() ?? 0,
        dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 0,
        rythme: json['rythme'] as String? ?? '',
        etat: json['etat'] as String? ?? '',
        candidats: (json['candidats'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String typePublic;
  final String langueCode;
  final String langueNom;
  final List<int> jours;
  final int heureLocale;
  final int dureeMinutes;
  final String rythme;
  final String etat;
  final int candidats;
}

@immutable
class IntentionPoolAdmin {
  const IntentionPoolAdmin({
    required this.id,
    required this.eleveId,
    required this.eleveIdentifiant,
    required this.elevePrenom,
    required this.langueCode,
    required this.cohorte,
    required this.diagnosticStatut,
    required this.niveauId,
    required this.etat,
  });

  factory IntentionPoolAdmin.depuisJson(Map<String, dynamic> json) =>
      IntentionPoolAdmin(
        id: json['intention_id'] as String,
        eleveId: json['eleve_id'] as String,
        eleveIdentifiant: json['eleve_immutable_id'] as String? ?? '',
        elevePrenom: json['eleve_prenom'] as String?,
        langueCode: json['langue_code'] as String? ?? '',
        cohorte: json['cohorte'] as String? ?? '',
        diagnosticStatut: json['diagnostic_statut'] as String? ?? '',
        niveauId: json['niveau_id'] as String?,
        etat: json['etat'] as String? ?? '',
      );

  final String id;
  final String eleveId;
  final String eleveIdentifiant;
  final String? elevePrenom;
  final String langueCode;
  final String cohorte;
  final String diagnosticStatut;
  final String? niveauId;
  final String etat;

  String get eleveLibelle =>
      (elevePrenom == null || elevePrenom!.trim().isEmpty)
          ? eleveIdentifiant
          : elevePrenom!;
}

/// Porte les mutations de formation Core24. Les droits sont verifies par les
/// RPC, jamais par l'ecran Admin.
abstract interface class ServiceClassesAdmin {
  Future<List<OffreHoraireAdmin>> offres();

  Future<String> creerOffre({
    required String typePublic,
    required String langueCode,
    required String fuseauIana,
    required List<int> jours,
    required int heureLocale,
    required int dureeMinutes,
  });

  Future<void> publierOffre(String offreId);

  Future<void> retirerOffre({required String offreId, required String motif});

  Future<Map<String, dynamic>> dispatcherOffre(String offreId);

  Future<List<IntentionPoolAdmin>> pool({String? offreId});

  Future<List<EnseignantAdmissible>> enseignantsAdmissibles(String groupeId);

  Future<void> affecterTitulaire({
    required String groupeId,
    required String teacherId,
    required String motif,
  });

  Future<void> transitionner({required String groupeId, required String etat});
}

class ServiceClassesAdminSupabase implements ServiceClassesAdmin {
  const ServiceClassesAdminSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<OffreHoraireAdmin>> offres() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'offres_horaires_admin',
    );
    return lignes
        .map(
          (dynamic ligne) => OffreHoraireAdmin.depuisJson(
            ligne as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> creerOffre({
    required String typePublic,
    required String langueCode,
    required String fuseauIana,
    required List<int> jours,
    required int heureLocale,
    required int dureeMinutes,
  }) => _client.rpc<String>(
    'creer_offre_horaire_admin',
    params: <String, dynamic>{
      'p_type_public': typePublic,
      'p_langue_code': langueCode,
      'p_fuseau_iana': fuseauIana,
      'p_jours': jours,
      'p_heure_locale': heureLocale,
      'p_duree_minutes': dureeMinutes,
    },
  );

  @override
  Future<void> publierOffre(String offreId) => _client.rpc<void>(
    'publier_offre_horaire_admin',
    params: <String, dynamic>{'p_offre_id': offreId},
  );

  @override
  Future<void> retirerOffre({required String offreId, required String motif}) =>
      _client.rpc<void>(
        'retirer_offre_horaire_admin',
        params: <String, dynamic>{'p_offre_id': offreId, 'p_motif': motif},
      );

  @override
  Future<Map<String, dynamic>> dispatcherOffre(String offreId) async {
    final dynamic reponse = await _client.rpc<dynamic>(
      'dispatcher_offre_horaire',
      params: <String, dynamic>{'p_offre_id': offreId},
    );
    return Map<String, dynamic>.from(reponse as Map);
  }

  @override
  Future<List<IntentionPoolAdmin>> pool({String? offreId}) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'intentions_pool_admin',
      params: <String, dynamic>{'p_offre_id': offreId},
    );
    return lignes
        .map(
          (dynamic ligne) => IntentionPoolAdmin.depuisJson(
            ligne as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<EnseignantAdmissible>> enseignantsAdmissibles(
    String groupeId,
  ) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'enseignants_admissibles_groupe',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    return lignes
        .map(
          (dynamic ligne) =>
              EnseignantAdmissible.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<void> affecterTitulaire({
    required String groupeId,
    required String teacherId,
    required String motif,
  }) async {
    await _client.rpc<void>(
      'affecter_titulaire_groupe',
      params: <String, dynamic>{
        'p_groupe_id': groupeId,
        'p_teacher_id': teacherId,
        'p_motif': motif,
      },
    );
  }

  @override
  Future<void> transitionner({
    required String groupeId,
    required String etat,
  }) async {
    await _client.rpc<void>(
      'transitionner_groupe_classes',
      params: <String, dynamic>{'p_groupe_id': groupeId, 'p_etat': etat},
    );
  }
}

final Provider<ServiceClassesAdmin> serviceClassesAdminProvider =
    Provider<ServiceClassesAdmin>(
      (Ref ref) => ServiceClassesAdminSupabase(Supabase.instance.client),
    );

final FutureProviderFamily<List<EnseignantAdmissible>, String>
enseignantsAdmissiblesProvider =
    FutureProvider.family<List<EnseignantAdmissible>, String>(
      (Ref ref, String groupeId) => ref
          .watch(serviceClassesAdminProvider)
          .enseignantsAdmissibles(groupeId),
    );

final FutureProvider<List<OffreHoraireAdmin>> offresHoraireAdminProvider =
    FutureProvider<List<OffreHoraireAdmin>>(
      (Ref ref) => ref.watch(serviceClassesAdminProvider).offres(),
    );

final FutureProvider<List<IntentionPoolAdmin>> intentionsPoolAdminProvider =
    FutureProvider<List<IntentionPoolAdmin>>(
      (Ref ref) => ref.watch(serviceClassesAdminProvider).pool(),
    );

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
