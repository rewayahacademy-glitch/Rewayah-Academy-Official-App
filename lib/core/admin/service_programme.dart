import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` (meme convention que `service_groupes.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le statut d'une version du programme pedagogique.
enum StatutVersionProgramme {
  /// Modifiable : niveaux ajoutables, modifiables, supprimables.
  brouillon('brouillon'),

  /// Figee. Toute evolution academique passe par une nouvelle version.
  publiee('publiee'),

  /// Figee, remplacee par une version publiee plus recente.
  archivee('archivee');

  const StatutVersionProgramme(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. Se replie sur `publiee` : un statut
  /// mal lu ne doit jamais laisser croire qu'une version est modifiable.
  static StatutVersionProgramme depuisSql(String? valeur) => switch (valeur) {
    'brouillon' => StatutVersionProgramme.brouillon,
    'archivee' => StatutVersionProgramme.archivee,
    _ => StatutVersionProgramme.publiee,
  };
}

/// Une version du curriculum Rewayah, vue par l'administration.
///
/// **Versionnee, jamais editee retroactivement** : une fois `publiee`, ses
/// niveaux sont figes en base (migration `0020`). Toute evolution academique
/// cree une nouvelle version brouillon.
@immutable
class VersionProgramme {
  /// Cree une ligne de version.
  const VersionProgramme({
    required this.id,
    required this.statut,
    required this.numeroVersion,
    required this.creeParIdentifiant,
    required this.creeParPrenom,
    required this.creeParNom,
    required this.publieeAt,
    required this.nombreNiveaux,
    required this.createdAt,
  });

  /// Lit une ligne rendue par `programme_versions_admin()`.
  factory VersionProgramme.depuisJson(Map<String, dynamic> json) {
    int entier(String cle) => (json[cle] as num?)?.toInt() ?? 0;

    return VersionProgramme(
      id: json['version_id'] as String,
      statut: StatutVersionProgramme.depuisSql(json['statut'] as String?),
      numeroVersion: entier('numero_version'),
      creeParIdentifiant: json['cree_par_immutable_id'] as String? ?? '',
      creeParPrenom: json['cree_par_prenom'] as String?,
      creeParNom: json['cree_par_nom'] as String?,
      publieeAt: DateTime.tryParse(
        json['publiee_at'] as String? ?? '',
      )?.toLocal(),
      nombreNiveaux: entier('nombre_niveaux'),
      createdAt:
          DateTime.tryParse(
            json['created_at'] as String? ?? '',
          )?.toLocal() ??
          DateTime.now(),
    );
  }

  /// L'identifiant technique de la version.
  final String id;

  /// Le statut courant.
  final StatutVersionProgramme statut;

  /// Le numero de version, croissant.
  final int numeroVersion;

  /// L'identifiant immuable de la personne qui a cree la version.
  final String creeParIdentifiant;

  /// Le prenom de cette personne. Nul quand l'identite est masquee.
  final String? creeParPrenom;

  /// Le nom de cette personne. Nul dans les memes conditions.
  final String? creeParNom;

  /// La date de publication, nulle tant que la version est en brouillon.
  final DateTime? publieeAt;

  /// Le nombre de niveaux que porte cette version.
  final int nombreNiveaux;

  /// La date de creation de la version.
  final DateTime createdAt;

  /// Vrai quand la version peut encore etre modifiee.
  bool get modifiable => statut == StatutVersionProgramme.brouillon;

  /// Ce qui s'affiche pour nommer la personne qui a cree la version.
  String get creeParLibelle {
    final String complet = <String?>[
      creeParPrenom,
      creeParNom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? creeParIdentifiant : complet;
  }
}

/// Un niveau du curriculum, au sein d'une version.
///
/// **Le nom humain seul se montre** : [codeTechnique] reste un identifiant de
/// travail, jamais un titre cote interface (interdiction UX explicite de la
/// mission qui a ouvert ce lot).
@immutable
class NiveauProgramme {
  /// Cree une ligne de niveau.
  const NiveauProgramme({
    required this.id,
    required this.codeTechnique,
    required this.nomHumain,
    required this.cycle,
    required this.ordre,
    required this.description,
  });

  /// Lit une ligne rendue par `programme_niveaux_admin()`.
  factory NiveauProgramme.depuisJson(Map<String, dynamic> json) =>
      NiveauProgramme(
        id: json['niveau_id'] as String,
        codeTechnique: json['code_technique'] as String? ?? '',
        nomHumain: json['nom_humain'] as String? ?? '',
        cycle: json['cycle'] as String? ?? '',
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
        description: json['description'] as String?,
      );

  /// L'identifiant technique du niveau.
  final String id;

  /// Le code technique (ex. `F1-PHO-01`). Usage interne seulement.
  final String codeTechnique;

  /// Le nom humain, seul affiche en premier plan (ex. « Fondations de
  /// lecture »).
  final String nomHumain;

  /// Le cycle auquel appartient ce niveau (texte libre : le contenu reel
  /// n'est pas encore importe, voir migration `0020`).
  final String cycle;

  /// L'ordre du niveau au sein de sa version.
  final int ordre;

  /// Une description optionnelle.
  final String? description;
}

/// La gestion du programme pedagogique versionne par l'administration.
abstract interface class ServiceProgramme {
  /// Toutes les versions, la plus recente en premier.
  Future<List<VersionProgramme>> versions();

  /// Les niveaux d'une version, dans leur ordre.
  Future<List<NiveauProgramme>> niveaux(String versionId);

  /// Cree une version brouillon. Si [versionSourceId] est fourni, ses
  /// niveaux sont recopies dans la nouvelle version.
  Future<String> creerVersion({String? versionSourceId});

  /// Ajoute un niveau a une version brouillon.
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  });

  /// Modifie un niveau d'une version brouillon.
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  });

  /// Supprime un niveau d'une version brouillon.
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  });

  /// Publie une version brouillon. Fige tous ses niveaux definitivement.
  Future<void> publierVersion({required String versionId, required String motif});
}

/// L'implementation reelle.
class ServiceProgrammeSupabase implements ServiceProgramme {
  /// Cree le service.
  const ServiceProgrammeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<VersionProgramme>> versions() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'programme_versions_admin',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              VersionProgramme.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'programme_niveaux_admin',
      params: <String, dynamic>{'p_version_id': versionId},
    );
    return reponse
        .map(
          (dynamic ligne) =>
              NiveauProgramme.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<String> creerVersion({String? versionSourceId}) => _client.rpc<String>(
    'creer_version_programme',
    params: <String, dynamic>{'p_source_version_id': versionSourceId},
  );

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) => _client.rpc<String>(
    'ajouter_niveau_programme',
    params: <String, dynamic>{
      'p_version_id': versionId,
      'p_code_technique': codeTechnique,
      'p_nom_humain': nomHumain,
      'p_cycle': cycle,
      'p_ordre': ordre,
      'p_description': description,
    },
  );

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) => _client.rpc<void>(
    'modifier_niveau_programme',
    params: <String, dynamic>{
      'p_niveau_id': niveauId,
      'p_nom_humain': nomHumain,
      'p_cycle': cycle,
      'p_ordre': ordre,
      'p_description': description,
    },
  );

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) => _client.rpc<void>(
    'supprimer_niveau_programme',
    params: <String, dynamic>{'p_niveau_id': niveauId, 'p_motif': motif},
  );

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) => _client.rpc<void>(
    'publier_version_programme',
    params: <String, dynamic>{'p_version_id': versionId, 'p_motif': motif},
  );
}

/// Le service du programme employe par l'application.
final Provider<ServiceProgramme> serviceProgrammeProvider =
    Provider<ServiceProgramme>(
      (Ref ref) => ServiceProgrammeSupabase(Supabase.instance.client),
    );

/// Les versions du programme, pour l'ecran Admin > Pedagogie > Programmes.
final FutureProvider<List<VersionProgramme>> versionsProgrammeProvider =
    FutureProvider<List<VersionProgramme>>(
      (Ref ref) => ref.watch(serviceProgrammeProvider).versions(),
    );

/// Les niveaux d'une version donnee.
final FutureProviderFamily<List<NiveauProgramme>, String>
niveauxProgrammeProvider = FutureProvider.family<List<NiveauProgramme>, String>(
  (Ref ref, String versionId) =>
      ref.watch(serviceProgrammeProvider).niveaux(versionId),
);

/// La version active du programme : la plus recente au statut `publiee`.
///
/// Nul tant qu'aucune version n'a jamais ete publiee. Employe par
/// Diagnostics, Progression et Evaluations pour proposer un niveau reel --
/// jamais un brouillon, jamais une version archivee.
final FutureProvider<VersionProgramme?> versionActiveProgrammeProvider =
    FutureProvider<VersionProgramme?>((Ref ref) async {
      final List<VersionProgramme> versions = await ref.watch(
        versionsProgrammeProvider.future,
      );
      for (final VersionProgramme v in versions) {
        if (v.statut == StatutVersionProgramme.publiee) return v;
      }
      return null;
    });
