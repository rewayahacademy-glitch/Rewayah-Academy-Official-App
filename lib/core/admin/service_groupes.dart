import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` (meme convention que `service_attribution.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../offres/affectation_refusee.dart';
import '../planning/service_planning.dart';
import 'creation_classe_refusee.dart';

/// Le public d'un groupe : fixe le seuil par defaut (5 enfants, 6 adultes).
enum TypePublicGroupe {
  /// Groupe d'enfants, seuil par defaut 5.
  enfant('enfant'),

  /// Groupe d'adultes, seuil par defaut 6.
  adulte('adulte');

  const TypePublicGroupe(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL. Se replie sur `enfant`, le seuil le
  /// plus bas : un type mal lu ne doit jamais laisser passer plus de monde
  /// que prevu.
  static TypePublicGroupe depuisSql(String? valeur) =>
      valeur == 'adulte' ? TypePublicGroupe.adulte : TypePublicGroupe.enfant;
}

/// Un groupe pedagogique, vu par l'administration.
///
/// **Le noyau du produit** : un enseignant, jusqu'a [seuilMax] eleves, un
/// [creneau] hebdomadaire partage -- c'est dans ce groupe que la visio se
/// tiendra (migration `0017`).
@immutable
class GroupeAdmin {
  /// Cree une ligne de groupe.
  const GroupeAdmin({
    required this.id,
    required this.libelle,
    required this.type,
    required this.seuilMax,
    required this.teacherId,
    required this.teacherIdentifiant,
    required this.teacherPrenom,
    required this.teacherNom,
    required this.creneau,
    required this.nombreMembres,
    required this.actif,
    this.teacherPays,
  });

  /// Lit une ligne rendue par `groupes_admin()`.
  factory GroupeAdmin.depuisJson(Map<String, dynamic> json) {
    int entier(String cle) => (json[cle] as num?)?.toInt() ?? 0;

    return GroupeAdmin(
      id: json['groupe_id'] as String,
      libelle: json['libelle'] as String? ?? '',
      type: TypePublicGroupe.depuisSql(json['type_public'] as String?),
      seuilMax: entier('seuil_max'),
      teacherId: json['teacher_id'] as String,
      teacherIdentifiant: json['teacher_immutable_id'] as String? ?? '',
      teacherPrenom: json['teacher_prenom'] as String?,
      teacherNom: json['teacher_nom'] as String?,
      creneau: Creneau(
        jour: entier('weekday'),
        heure: entier('hour_local'),
        fuseau: 'Europe/Paris',
      ),
      nombreMembres: entier('nombre_membres'),
      actif: json['actif'] as bool? ?? false,
      // ENS-PAYS-1 : lu des que `groupes_admin()` le rend (BR-1), nul avant.
      teacherPays: json['teacher_country'] as String?,
    );
  }

  /// L'identifiant technique du groupe.
  final String id;

  /// Le nom du groupe.
  final String libelle;

  /// Le public du groupe.
  final TypePublicGroupe type;

  /// Le nombre maximal de membres actifs.
  final int seuilMax;

  /// L'identifiant technique de l'enseignant.
  final String teacherId;

  /// L'identifiant immuable de l'enseignant.
  final String teacherIdentifiant;

  /// Le prenom de l'enseignant. Nul quand l'identite est masquee.
  final String? teacherPrenom;

  /// Le nom de l'enseignant. Nul dans les memes conditions.
  final String? teacherNom;

  /// Le pays declare par l'enseignant (ENS-PAYS-1). Nul quand il ne l'est pas,
  /// quand l'identite est masquee, ou tant que le serveur ne le rend pas.
  final String? teacherPays;

  /// Le creneau hebdomadaire partage par tous les membres.
  final Creneau creneau;

  /// Le nombre de membres actifs.
  final int nombreMembres;

  /// Faux quand le groupe est cloture.
  final bool actif;

  /// Ce qui s'affiche pour nommer l'enseignant.
  String get teacherLibelle {
    final String complet = <String?>[
      teacherPrenom,
      teacherNom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? teacherIdentifiant : complet;
  }
}

/// Un eleve membre d'un groupe, vu par l'administration.
@immutable
class MembreGroupe {
  /// Cree une ligne de membre.
  const MembreGroupe({
    required this.studentId,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.rejointLe,
  });

  /// Lit une ligne rendue par `groupe_detail()`.
  factory MembreGroupe.depuisJson(Map<String, dynamic> json) => MembreGroupe(
    studentId: json['student_id'] as String,
    identifiant: json['student_immutable_id'] as String? ?? '',
    prenom: json['student_prenom'] as String?,
    nom: json['student_nom'] as String?,
    rejointLe:
        DateTime.tryParse(json['joined_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  /// L'identifiant technique de l'eleve.
  final String studentId;

  /// L'identifiant immuable de l'eleve.
  final String identifiant;

  /// Le prenom. Nul quand l'identite est masquee.
  final String? prenom;

  /// Le nom. Nul dans les memes conditions.
  final String? nom;

  /// La date d'entree dans le groupe.
  final DateTime rejointLe;

  /// Ce qui s'affiche pour nommer l'eleve.
  String get libelle {
    final String complet = <String?>[
      prenom,
      nom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? identifiant : complet;
  }
}

/// La gestion des groupes pedagogiques par l'administration.
abstract interface class ServiceGroupes {
  /// Tous les groupes, actifs d'abord.
  Future<List<GroupeAdmin>> groupes();

  /// Les membres actifs d'un groupe.
  Future<List<MembreGroupe>> membres(String groupeId);

  /// Cree un groupe. `seuilMax` nul reprend le defaut du type (5 enfants,
  /// 6 adultes).
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required String libelle,
    required Creneau creneau,
    int? seuilMax,
  });

  /// Modifie le libelle, le seuil et le creneau d'un groupe. Deplacer une
  /// classe qui a son enseignant peut etre refuse : [AffectationRefusee].
  Future<void> modifier({
    required String groupeId,
    required String libelle,
    required int seuilMax,
    required Creneau creneau,
  });

  /// Ajoute un eleve a un groupe. Refuse si l'eleve a deja un groupe actif,
  /// ou si le groupe est au plafond.
  Future<void> ajouterEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  });

  /// Retire un eleve d'un groupe.
  Future<void> retirerEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  });

  /// Cloture un groupe : tous ses membres actifs sont retires.
  Future<void> cloturer({required String groupeId, required String motif});
}

/// L'implementation reelle.
class ServiceGroupesSupabase implements ServiceGroupes {
  /// Cree le service.
  const ServiceGroupesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GroupeAdmin>> groupes() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'groupes_admin',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              GroupeAdmin.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<List<MembreGroupe>> membres(String groupeId) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'groupe_detail',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    return reponse
        .map(
          (dynamic ligne) =>
              MembreGroupe.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  /// Un refus du serveur (CAND-Q15 : piece d'identite, acces, genre,
  /// plafond, collisions) arrive en [CreationClasseRefusee], jamais avec le
  /// texte SQL.
  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required String libelle,
    required Creneau creneau,
    int? seuilMax,
  }) => traduireRefusCreationClasse<String>(
    () => _client.rpc<String>(
      'creer_groupe',
      params: <String, dynamic>{
        'p_teacher_profile_id': teacherId,
        'p_type_public': type.valeurSql,
        'p_libelle': libelle,
        'p_weekday': creneau.jour,
        'p_hour_local': creneau.heure,
        'p_seuil_max': seuilMax,
        // L3-06 : signature gardee (8 arguments). Fuseau et couleur ne sont
        // pas saisis dans cet ecran : null, le serveur retient Europe/Paris
        // et aucune couleur.
        'p_timezone_iana': null,
        'p_couleur_jeton': null,
      },
    ),
  );

  /// CLASSES-DUREE (23/10/2026) : changer le jour ou l'heure d'une classe qui a
  /// son enseignant repasse le predicat d'affectation cote serveur. Son refus
  /// (couverture par les disponibilites, collisions, plafond d'heures, compte,
  /// genre) arrive en [AffectationRefusee], le meme type que la confirmation
  /// d'un enseignant, jamais avec le texte SQL. Les autres erreurs (droit,
  /// seuil trop bas, reseau) passent telles quelles.
  @override
  Future<void> modifier({
    required String groupeId,
    required String libelle,
    required int seuilMax,
    required Creneau creneau,
  }) async {
    try {
      await _client.rpc<void>(
        'modifier_groupe',
        params: <String, dynamic>{
          'p_groupe_id': groupeId,
          'p_libelle': libelle,
          'p_seuil_max': seuilMax,
          'p_weekday': creneau.jour,
          'p_hour_local': creneau.heure,
          // L3-06 : signature gardee (7 arguments). null laisse fuseau et
          // couleur inchanges cote serveur.
          'p_timezone_iana': null,
          'p_couleur_jeton': null,
        },
      );
    } on PostgrestException catch (e) {
      final MotifRefusAffectation? motif = motifRefusDeplacementClasse(
        code: e.code,
        message: e.message,
      );
      if (motif == null) rethrow;
      throw AffectationRefusee.depuis(motif, e.details);
    }
  }

  @override
  Future<void> ajouterEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) => _client.rpc<void>(
    'ajouter_eleve_groupe',
    params: <String, dynamic>{
      'p_groupe_id': groupeId,
      'p_student_profile_id': studentId,
      'p_motif': motif,
    },
  );

  @override
  Future<void> retirerEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) => _client.rpc<void>(
    'retirer_eleve_groupe',
    params: <String, dynamic>{
      'p_groupe_id': groupeId,
      'p_student_profile_id': studentId,
      'p_motif': motif,
    },
  );

  @override
  Future<void> cloturer({required String groupeId, required String motif}) =>
      _client.rpc<void>(
        'cloturer_groupe',
        params: <String, dynamic>{'p_groupe_id': groupeId, 'p_motif': motif},
      );
}

/// Le service des groupes employe par l'application.
final Provider<ServiceGroupes> serviceGroupesProvider =
    Provider<ServiceGroupes>(
      (Ref ref) => ServiceGroupesSupabase(Supabase.instance.client),
    );

/// Les groupes pedagogiques, pour l'ecran Admin > Operations > Groupes.
final FutureProvider<List<GroupeAdmin>> groupesProvider =
    FutureProvider<List<GroupeAdmin>>(
      (Ref ref) => ref.watch(serviceGroupesProvider).groupes(),
    );

/// Les membres d'un groupe donne.
final FutureProviderFamily<List<MembreGroupe>, String> membresGroupeProvider =
    FutureProvider.family<List<MembreGroupe>, String>(
      (Ref ref, String groupeId) =>
          ref.watch(serviceGroupesProvider).membres(groupeId),
    );
