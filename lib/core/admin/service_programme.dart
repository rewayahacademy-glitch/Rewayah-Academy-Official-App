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
      publieeAt: DateTime.tryParse(json['publiee_at'] as String? ?? '')
          ?.toLocal(),
      nombreNiveaux: entier('nombre_niveaux'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
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
    this.objectifs = const <String>[],
    this.plage,
    this.durees = const <String, DureeEtape>{},
    this.complet,
  });

  /// Lit une ligne rendue par `programme_contenu_admin()` (CAHIER-C2) ou,
  /// avant elle, par `programme_niveaux_admin()` (sans contenu).
  factory NiveauProgramme.depuisJson(Map<String, dynamic> json) {
    final Object? objectifs = json['objectifs'];
    final Object? durees = json['durees'];
    final Object? plage = json['plage_support'];
    return NiveauProgramme(
      id: json['niveau_id'] as String,
      codeTechnique: json['code_technique'] as String? ?? '',
      nomHumain: json['nom_humain'] as String? ?? '',
      cycle: json['cycle'] as String? ?? '',
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      objectifs: objectifs is List
          ? <String>[
              for (final Object? o in objectifs)
                if (o != null) '$o'.trim(),
            ]
          : const <String>[],
      plage: plage is Map ? PlageSupport.depuisJson(plage) : null,
      durees: durees is Map
          ? <String, DureeEtape>{
              for (final MapEntry<Object?, Object?> e in durees.entries)
                if (DureeEtape.depuisJson(e.value) case final DureeEtape d)
                  '${e.key}': d,
            }
          : const <String, DureeEtape>{},
      complet: json['complet'] as bool?,
    );
  }

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

  /// CAHIER-C2 : les objectifs observables de l'etape (3 a 5 a la
  /// publication), dans l'ordre.
  final List<String> objectifs;

  /// CAHIER-C2 : la plage de support de l'etape, ou `null`.
  final PlageSupport? plage;

  /// CAHIER-C2 : la duree prevue et la date limite, par code de tranche
  /// d'age (`cohortes_age.code`).
  final Map<String, DureeEtape> durees;

  /// CAHIER-C2 : vrai quand le serveur juge l'etape publiable ; `null` quand
  /// la lecture ne le dit pas (serveur d'avant C2).
  final bool? complet;
}

/// Les tranches d'age du programme, dans l'ordre (`cohortes_age`, decisions
/// du 29/09 et du 12/10 : 6-9, 10-13, 14-17, 18+).
const List<String> tranchesProgramme = <String>[
  'enfant_6_9',
  'enfant_10_13',
  'ado_14_17',
  'adulte_18_plus',
];

/// La date limite d'une etape deduite de sa duree prevue : x 1,3, arrondie
/// (regle du directeur du 14/10, `programme-rewayah` §3).
int dateLimiteDeduite(int prevue) => (prevue * 1.3).round();

/// La duree d'une etape pour une tranche d'age, en semaines.
@immutable
class DureeEtape {
  /// Cree la duree.
  const DureeEtape({required this.prevue, required this.limite});

  /// Lit `{prevue, limite}` ; `null` si incomplet.
  static DureeEtape? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? p = brut['prevue'];
    final Object? l = brut['limite'];
    if (p is! num || l is! num) return null;
    return DureeEtape(prevue: p.toInt(), limite: l.toInt());
  }

  /// La duree prevue, en semaines.
  final int prevue;

  /// La date limite, en semaines depuis le debut de l'etape.
  final int limite;

  /// La forme attendue par le serveur.
  Map<String, int> versJson() => <String, int>{
    'prevue': prevue,
    'limite': limite,
  };
}

/// Le support d'une etape.
enum SupportEtape {
  /// Le livre de lecture de Rewayah (pas encore numerote au 05/11).
  livreRewayah('livre_rewayah'),

  /// Le Mushaf (604 pages).
  mushaf('mushaf');

  const SupportEtape(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;
}

/// La plage de support d'une etape : du debut a la fin, pages et lignes
/// facultatives.
@immutable
class PlageSupport {
  /// Cree la plage.
  const PlageSupport({
    required this.support,
    this.pageDebut,
    this.ligneDebut,
    this.pageFin,
    this.ligneFin,
  });

  /// Lit la plage ; un support inconnu se replie sur le livre.
  factory PlageSupport.depuisJson(Map<Object?, Object?> json) {
    int? entier(String cle) => (json[cle] as num?)?.toInt();
    return PlageSupport(
      support: json['support'] == 'mushaf'
          ? SupportEtape.mushaf
          : SupportEtape.livreRewayah,
      pageDebut: entier('page_debut'),
      ligneDebut: entier('ligne_debut'),
      pageFin: entier('page_fin'),
      ligneFin: entier('ligne_fin'),
    );
  }

  /// Le support.
  final SupportEtape support;

  /// La premiere page, ou `null`.
  final int? pageDebut;

  /// La premiere ligne, ou `null`.
  final int? ligneDebut;

  /// La derniere page, ou `null`.
  final int? pageFin;

  /// La derniere ligne, ou `null`.
  final int? ligneFin;

  /// La forme attendue par le serveur.
  Map<String, Object> versJson() => <String, Object>{
    'support': support.valeurSql,
    'page_debut': ?pageDebut,
    'ligne_debut': ?ligneDebut,
    'page_fin': ?pageFin,
    'ligne_fin': ?ligneFin,
  };
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
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  });
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
    final Map<String, dynamic> params = <String, dynamic>{
      'p_version_id': versionId,
    };
    List<dynamic> reponse;
    try {
      // CAHIER-C2 : la lecture avec le contenu de chaque etape.
      reponse = await _client.rpc<List<dynamic>>(
        'programme_contenu_admin',
        params: params,
      );
    } on PostgrestException catch (e) {
      // Fonction absente (migration C2 pas encore installee) : la lecture
      // d'avant, sans contenu, plutot qu'un ecran en erreur.
      if (e.code != 'PGRST202') rethrow;
      reponse = await _client.rpc<List<dynamic>>(
        'programme_niveaux_admin',
        params: params,
      );
    }
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

/// CAHIER-C2 (06/11/2026) : le contenu des etapes d'une version brouillon.
///
/// Interface a part de [ServiceProgramme] pour ne rien imposer a ses
/// implementations existantes (demonstration, tests).
abstract interface class ServiceContenuProgramme {
  /// Ecrit les objectifs, la plage de support et les durees d'une etape
  /// d'une version brouillon (`modifier_contenu_niveau`).
  Future<void> modifierContenu({
    required String niveauId,
    required List<String> objectifs,
    required PlageSupport? plage,
    required Map<String, DureeEtape> durees,
  });

  /// Insere dans un brouillon vide la proposition des quatre etapes des
  /// bases (`preremplir_bases_programme`), a relire avant publication.
  Future<void> preremplirBases(String versionId);
}

/// L'implementation reelle du contenu des etapes.
class ServiceContenuProgrammeSupabase implements ServiceContenuProgramme {
  /// Cree le service.
  const ServiceContenuProgrammeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<void> modifierContenu({
    required String niveauId,
    required List<String> objectifs,
    required PlageSupport? plage,
    required Map<String, DureeEtape> durees,
  }) => _client.rpc<void>(
    'modifier_contenu_niveau',
    params: <String, dynamic>{
      'p_niveau_id': niveauId,
      'p_objectifs': objectifs,
      'p_plage_support': plage?.versJson(),
      'p_durees': <String, Object>{
        for (final MapEntry<String, DureeEtape> e in durees.entries)
          e.key: e.value.versJson(),
      },
    },
  );

  @override
  Future<void> preremplirBases(String versionId) => _client.rpc<void>(
    'preremplir_bases_programme',
    params: <String, dynamic>{'p_version_id': versionId},
  );
}

/// Le service du contenu des etapes employe par l'application.
final Provider<ServiceContenuProgramme> serviceContenuProgrammeProvider =
    Provider<ServiceContenuProgramme>(
      (Ref ref) => ServiceContenuProgrammeSupabase(Supabase.instance.client),
    );

/// Le service du programme employe par l'application.
final Provider<ServiceProgramme> serviceProgrammeProvider =
    Provider<ServiceProgramme>(
      (Ref ref) => ServiceProgrammeSupabase(Supabase.instance.client),
    );

/// Les versions du programme, pour l'ecran Admin > Pedagogie > Programmes.
final FutureProvider<List<VersionProgramme>>
versionsProgrammeProvider = FutureProvider<List<VersionProgramme>>(
  (Ref ref) => ref.watch(serviceProgrammeProvider).versions(),
  // Pas de nouvelle tentative automatique : `versionActiveProgrammeProvider`
  // attend ce futur, et le retry par defaut le tenait en squelette ~40 s.
  retry: (int _, Object _) => null,
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
    }, retry: (int _, Object _) => null);
