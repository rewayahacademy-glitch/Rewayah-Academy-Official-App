import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';

/// Une demande, telle que `matching_requests` la porte.
@immutable
class Demande {
  /// Cree une demande.
  const Demande({
    required this.id,
    required this.sorte,
    required this.sujetId,
    required this.motif,
    required this.creeeLe,
    this.sujetPrenom = '',
    this.sujetIdentifiant = '',
    this.roleDemandeur,
    this.cleRegle,
    this.valeurDemandee,
  });

  /// Lit une ligne rendue par `demandes_en_attente()`.
  factory Demande.depuisJson(Map<String, dynamic> json) {
    final Object? valeur = json['rule_value'];
    return Demande(
      id: json['id'] as String,
      sorte: SorteDemande.depuisSql(json['kind'] as String?),
      sujetId: json['subject_profile_id'] as String? ?? '',
      sujetPrenom: json['subject_first_name'] as String? ?? '',
      sujetIdentifiant: json['subject_immutable_id'] as String? ?? '',
      motif: json['reason'] as String? ?? '',
      roleDemandeur: AppRole.depuisSql(json['requester_role'] as String?),
      cleRegle: CleRegle.depuisSql(json['rule_key'] as String?),
      valeurDemandee: valeur is num ? valeur.toInt() : null,
      creeeLe:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Identifiant de la demande.
  final String id;

  /// Ce qui est demande. `null` si la base en expose une sorte inconnue.
  final SorteDemande? sorte;

  /// Le profil concerne : l'eleve, ou l'enseignant pour un plafond.
  final String sujetId;

  /// Prenom du profil concerne.
  final String sujetPrenom;

  /// Identifiant immuable du profil concerne.
  final String sujetIdentifiant;

  /// Comment nommer le profil concerne a l'ecran.
  ///
  /// **Se replie sur l'identifiant immuable quand le prenom est masque.** En
  /// mode observation, `demandes_en_attente()` rend `subject_first_name` nul
  /// depuis la migration `0016` : sans ce repli, la fiche afficherait un titre
  /// vide, et les phrases construites autour du prenom (« Reaffectation
  /// demandee pour … ») se termineraient dans le vide.
  String get sujetLibelle =>
      sujetPrenom.isEmpty ? sujetIdentifiant : sujetPrenom;

  /// Vrai quand le prenom du profil concerne est lisible.
  bool get sujetPrenomConnu => sujetPrenom.isNotEmpty;

  /// Le motif, obligatoire : une demande sans motif ne se tranche pas.
  final String motif;

  /// En quelle qualite la demande a ete faite.
  final AppRole? roleDemandeur;

  /// La regle visee, pour une demande de regle ou de plafond.
  final CleRegle? cleRegle;

  /// La valeur demandee, quand il y en a une.
  final int? valeurDemandee;

  /// Quand elle a ete faite. C'est la cle du tri de la file.
  final DateTime creeeLe;
}

/// Les demandes des quatre parties (file `ADM-06`).
///
/// L3-02 (A-06) : le matching individuel (prendre un eleve, `eleves_en_attente_v`)
/// est retire. Ce port ne porte plus que `demander`, le nom du fichier reste
/// pour ne pas toucher cinquante imports ; le renommer est un lot a part.
abstract interface class ServiceMatching {
  /// Depose une demande. Elle atteint la file de `ADM-06`.
  Future<void> demander({
    required SorteDemande sorte,
    required String sujetId,
    required String motif,
    CleRegle? cle,
    int? valeur,
  });
}

/// L'implementation reelle.
class ServiceMatchingSupabase implements ServiceMatching {
  /// Cree le service.
  const ServiceMatchingSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<void> demander({
    required SorteDemande sorte,
    required String sujetId,
    required String motif,
    CleRegle? cle,
    int? valeur,
  }) => _client.rpc<void>(
    'demander',
    params: <String, dynamic>{
      'p_kind': sorte.valeurSql,
      'p_subject_profile_id': sujetId,
      'p_motif': motif,
      'p_rule_key': cle?.valeurSql,
      'p_rule_value': valeur,
    },
  );
}

/// Le service de matching employe par l'application.
final Provider<ServiceMatching> serviceMatchingProvider =
    Provider<ServiceMatching>(
      (Ref ref) => ServiceMatchingSupabase(Supabase.instance.client),
    );
