import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../planning/service_planning.dart';

/// Un eleve sans enseignant, tel que `eleves_en_attente_v` l'expose.
///
/// Une ligne par creneau compatible : le meme eleve peut apparaitre plusieurs
/// fois, une fois par heure qu'il propose et que l'enseignant peut tenir.
@immutable
class EleveEnAttente {
  /// Cree une ligne du feed.
  const EleveEnAttente({
    required this.eleveId,
    required this.prenom,
    required this.identifiantImmuable,
    required this.creneau,
    required this.depuis,
    required this.mode,
    this.niveau,
  });

  /// Lit une ligne de la vue.
  factory EleveEnAttente.depuisJson(Map<String, dynamic> json) =>
      EleveEnAttente(
        eleveId: json['student_id'] as String,
        prenom: json['first_name'] as String? ?? '',
        identifiantImmuable: json['immutable_id'] as String? ?? '',
        creneau: Creneau.depuisJson(json),
        depuis:
            DateTime.tryParse(json['depuis'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        mode: InterfaceMode.depuisSql(json['interface_mode'] as String?),
        niveau: json['level'] as String?,
      );

  /// Identifiant du profil eleve.
  final String eleveId;

  /// Prenom.
  final String prenom;

  /// Identifiant immuable, seule autre donnee d'identite visible (ADR-008).
  final String identifiantImmuable;

  /// Le creneau propose, compatible avec ceux de l'enseignant qui regarde.
  final Creneau creneau;

  /// Depuis quand ce foyer attend. C'est la cle du tri, jamais le nom.
  final DateTime depuis;

  /// Mode d'interface de l'eleve.
  final InterfaceMode mode;

  /// Niveau declare, quand il existe.
  final String? niveau;

  /// Le nombre de jours d'attente a un instant donne.
  int joursDAttente(DateTime maintenant) =>
      maintenant.difference(depuis).inDays;
}

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

/// Le matching, cote enseignant, et les demandes des quatre parties.
abstract interface class ServiceMatching {
  /// Les eleves sans enseignant dont un creneau croise les miens.
  ///
  /// Le croisement se fait **par instant** et non par heure locale : la famille
  /// pose en heure de Paris, l'enseignant lit en heure de Conakry.
  Future<List<EleveEnAttente>> elevesEnAttente();

  /// Prend un eleve. Ce qui se prend est un eleve, pas un creneau : la relation
  /// dure, et ne se rompt que par une demande (ADR-017).
  ///
  /// Le plafond, l'unicite de l'enseignant et la concurrence sont tranches en
  /// base : deux enseignants qui tapent au meme instant ne peuvent pas passer
  /// tous les deux.
  Future<void> prendre({required String eleveId, required Creneau creneau});

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
  Future<List<EleveEnAttente>> elevesEnAttente() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('eleves_en_attente_v')
        .select()
        // Anciennete d'abord : sans ce tri, un eleve peut rester invisible en
        // bas de liste indefiniment, ce qui viderait le matching de son interet.
        .order('depuis');
    return lignes.map(EleveEnAttente.depuisJson).toList();
  }

  @override
  Future<void> prendre({
    required String eleveId,
    required Creneau creneau,
  }) => _client.rpc<void>(
    'prendre_eleve',
    params: <String, dynamic>{
      'p_student_profile_id': eleveId,
      'p_weekday': creneau.jour,
      'p_hour': creneau.heure,
    },
  );

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

/// Le feed de `ENS-06`.
final FutureProvider<List<EleveEnAttente>> elevesEnAttenteProvider =
    FutureProvider<List<EleveEnAttente>>(
      (Ref ref) => ref.watch(serviceMatchingProvider).elevesEnAttente(),
    );
