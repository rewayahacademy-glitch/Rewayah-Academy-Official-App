import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'personnes_modifiees.dart';
import 'service_programme.dart'
    show niveauxProgrammeProvider, versionsProgrammeProvider;

/// PLAN-DE-CLASSE A : l'etape d'une classe ouverte, vue par la direction.
///
/// Lue par `niveau_classe_direction` : le serveur dit ou en est la classe et
/// combien de ses membres n'ont pas encore d'etape. Rien n'est calcule ici.
@immutable
class EtapeClasse {
  /// Cree la lecture.
  const EtapeClasse({
    required this.niveauId,
    required this.etapeNom,
    required this.programmePublie,
    required this.membres,
    required this.membresSansEtape,
  });

  /// Lit la reponse de `niveau_classe_direction`.
  factory EtapeClasse.depuisJson(Map<String, dynamic> json) => EtapeClasse(
    niveauId: json['niveau_id'] as String?,
    etapeNom: json['etape_nom'] as String?,
    programmePublie: json['programme_publie'] as bool? ?? false,
    membres: (json['membres'] as num?)?.toInt() ?? 0,
    membresSansEtape: (json['membres_sans_etape'] as num?)?.toInt() ?? 0,
  );

  /// L'etape de la classe, nulle quand elle n'en a pas.
  final String? niveauId;

  /// Le nom humain de l'etape, nul sans etape.
  final String? etapeNom;

  /// Vrai quand une version du programme est publiee (sinon, rien a donner).
  final bool programmePublie;

  /// Les membres actifs de la classe.
  final int membres;

  /// Les membres actifs qui n'ont pas d'etape.
  final int membresSansEtape;
}

/// Ce qu'a donne un niveau a une classe : combien de membres ont recu leur
/// etape, combien attendent la decision de la direction.
@immutable
class ResultatNiveauClasse {
  /// Cree le compte rendu.
  const ResultatNiveauClasse({
    required this.elevesPlaces,
    required this.elevesEnAttente,
  });

  /// Lit la reponse de `donner_niveau_classe`.
  factory ResultatNiveauClasse.depuisJson(Map<String, dynamic> json) =>
      ResultatNiveauClasse(
        elevesPlaces: (json['eleves_places'] as num?)?.toInt() ?? 0,
        elevesEnAttente: (json['eleves_en_attente'] as num?)?.toInt() ?? 0,
      );

  /// Les membres qui ont recu leur etape.
  final int elevesPlaces;

  /// Les membres qui attendent l'entretien de lecture.
  final int elevesEnAttente;
}

/// Pourquoi un eleve membre d'une classe n'a pas d'etape.
enum RaisonSansEtape {
  /// Aucune version du programme n'est publiee.
  aucunProgramme,

  /// Il declare deja lire : la direction decide son etape.
  attenteEntretien,

  /// Debutant : le rattachement lui donne l'etape 1.
  debutantARattacher,
}

/// Un eleve membre d'une classe ouverte, sans etape.
@immutable
class EleveSansEtape {
  /// Cree la ligne.
  const EleveSansEtape({
    required this.studentId,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.classe,
    required this.raison,
    required this.inscritLe,
  });

  /// Lit une ligne de `eleves_sans_etape`.
  factory EleveSansEtape.depuisJson(Map<String, dynamic> json) =>
      EleveSansEtape(
        studentId: json['student_id'] as String,
        identifiant: json['identifiant'] as String? ?? '',
        prenom: json['prenom'] as String?,
        nom: json['nom'] as String?,
        classe: json['classe'] as String? ?? '',
        raison: switch (json['raison']) {
          'aucun_programme' => RaisonSansEtape.aucunProgramme,
          'attente_entretien' => RaisonSansEtape.attenteEntretien,
          _ => RaisonSansEtape.debutantARattacher,
        },
        inscritLe: DateTime.tryParse(json['inscrit_le'] as String? ?? '')
            ?.toLocal(),
      );

  /// L'identifiant technique.
  final String studentId;

  /// L'identifiant immuable, montre quand l'identite est masquee.
  final String identifiant;

  /// Le prenom, nul quand l'identite est masquee.
  final String? prenom;

  /// Le nom, nul dans les memes conditions.
  final String? nom;

  /// Le nom de la classe.
  final String classe;

  /// Pourquoi il n'a pas d'etape.
  final RaisonSansEtape raison;

  /// Sa date d'inscription, qui borne la date d'entree qu'on peut lui donner.
  final DateTime? inscritLe;

  /// Ce qui s'affiche pour le nommer.
  String get libelle {
    final String complet = <String?>[
      prenom,
      nom,
    ].whereType<String>().join(' ').trim();
    return complet.isEmpty ? identifiant : complet;
  }
}

/// Une classe ouverte sans etape.
@immutable
class ClasseSansEtape {
  /// Cree la ligne.
  const ClasseSansEtape({
    required this.groupeId,
    required this.nom,
    required this.membres,
  });

  /// Lit une ligne de `eleves_sans_etape`.
  factory ClasseSansEtape.depuisJson(Map<String, dynamic> json) =>
      ClasseSansEtape(
        groupeId: json['groupe_id'] as String,
        nom: json['nom'] as String? ?? '',
        membres: (json['membres'] as num?)?.toInt() ?? 0,
      );

  /// L'identifiant de la classe.
  final String groupeId;

  /// Son nom.
  final String nom;

  /// Ses membres actifs.
  final int membres;
}

/// Qui n'a pas d'etape, et pourquoi : la lecture de la direction.
@immutable
class PlacementsAFaire {
  /// Cree la lecture.
  const PlacementsAFaire({
    required this.programmePublie,
    required this.classes,
    required this.eleves,
  });

  /// Lit la reponse de `eleves_sans_etape`.
  factory PlacementsAFaire.depuisJson(Map<String, dynamic> json) =>
      PlacementsAFaire(
        programmePublie: json['programme_publie'] as bool? ?? false,
        classes: (json['classes_sans_niveau'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (dynamic l) =>
                  ClasseSansEtape.depuisJson(l as Map<String, dynamic>),
            )
            .toList(growable: false),
        eleves: (json['eleves'] as List<dynamic>? ?? <dynamic>[])
            .map(
              (dynamic l) =>
                  EleveSansEtape.depuisJson(l as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  /// Vrai quand une version du programme est publiee.
  final bool programmePublie;

  /// Les classes ouvertes sans etape.
  final List<ClasseSansEtape> classes;

  /// Les eleves membres sans etape.
  final List<EleveSansEtape> eleves;

  /// Les debutants que le rattachement placera.
  int get debutants => eleves
      .where(
        (EleveSansEtape e) => e.raison == RaisonSansEtape.debutantARattacher,
      )
      .length;

  /// Rien a faire : ni classe ni eleve sans etape.
  bool get vide => classes.isEmpty && eleves.isEmpty;
}

/// Ce que le rattachement a place.
@immutable
class ResultatRattachement {
  /// Cree le compte rendu.
  const ResultatRattachement({required this.classes, required this.eleves});

  /// Lit la reponse de `rattacher_eleves_et_classes`.
  factory ResultatRattachement.depuisJson(Map<String, dynamic> json) =>
      ResultatRattachement(
        classes: (json['classes'] as num?)?.toInt() ?? 0,
        eleves: (json['eleves'] as num?)?.toInt() ?? 0,
      );

  /// Les classes qui ont recu l'etape 1.
  final int classes;

  /// Les eleves qui ont recu leur etape.
  final int eleves;
}

/// Pourquoi un brouillon ne se publie pas, dit par le serveur.
enum RaisonBrouillon {
  /// Le brouillon se publie.
  publiable,

  /// Une etape n'a pas ses objectifs ou ses durees.
  incomplet,

  /// Les sommes des etapes ne font pas le niveau.
  incoherent,

  /// Le niveau des bases n'est pas complet.
  sansBases,

  /// Une version deja publiee ou archivee.
  nonBrouillon,

  /// Autre refus du serveur.
  autre,
}

/// L'etat de publication d'un brouillon : le serveur essaie, puis annule.
@immutable
class EtatPublication {
  /// Cree la lecture.
  const EtatPublication({required this.raison, this.detail});

  /// Lit la reponse de `etat_publication_brouillon`.
  factory EtatPublication.depuisJson(Map<String, dynamic> json) =>
      EtatPublication(
        raison: (json['peut_publier'] as bool? ?? false)
            ? RaisonBrouillon.publiable
            : switch (json['raison']) {
                'incomplet' => RaisonBrouillon.incomplet,
                'incoherent' => RaisonBrouillon.incoherent,
                'sans_bases' => RaisonBrouillon.sansBases,
                'non_brouillon' => RaisonBrouillon.nonBrouillon,
                _ => RaisonBrouillon.autre,
              },
        detail: json['detail'] as String?,
      );

  /// La raison, ou `publiable`.
  final RaisonBrouillon raison;

  /// Ce que le serveur precise (le nom de l'etape ou du niveau en cause).
  final String? detail;
}

/// Les gestes de la direction du lot PLAN-DE-CLASSE A. Chaque appel est un
/// geste serveur, reserve a la direction et trace au journal.
abstract interface class ServicePlanClasse {
  /// L'etape de la classe [groupeId] et l'etat de ses membres.
  Future<EtapeClasse?> etapeClasse(String groupeId);

  /// Donne l'etape [niveauId] a une classe ouverte.
  Future<ResultatNiveauClasse> donnerNiveauClasse({
    required String groupeId,
    required String niveauId,
    required String motif,
  });

  /// Dit qu'un eleve a commence son etape le [jour] (passe).
  Future<void> daterEntreeEtape({
    required String studentId,
    required DateTime jour,
    required String motif,
  });

  /// Qui n'a pas d'etape, et pourquoi.
  Future<PlacementsAFaire> placementsAFaire();

  /// Rattache les classes ouvertes et les debutants.
  Future<ResultatRattachement> rattacher();

  /// Pourquoi un brouillon se publie ou non.
  Future<EtatPublication> etatPublication(String versionId);

  /// Cree une version neuve remplie des bases ; rend son identifiant.
  Future<String> repartirDesBases();
}

/// Un jour de calendrier ecrit `AAAA-MM-JJ`, comme le serveur le lit.
String jourPourServeur(DateTime jour) =>
    '${jour.year.toString().padLeft(4, '0')}-'
    '${jour.month.toString().padLeft(2, '0')}-'
    '${jour.day.toString().padLeft(2, '0')}';

/// L'implementation reelle.
class ServicePlanClasseSupabase implements ServicePlanClasse {
  /// Cree le service.
  const ServicePlanClasseSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtapeClasse?> etapeClasse(String groupeId) async {
    final Map<String, dynamic>? reponse = await _client
        .rpc<Map<String, dynamic>?>(
          'niveau_classe_direction',
          params: <String, dynamic>{'p_groupe_id': groupeId},
        );
    return reponse == null ? null : EtapeClasse.depuisJson(reponse);
  }

  @override
  Future<ResultatNiveauClasse> donnerNiveauClasse({
    required String groupeId,
    required String niveauId,
    required String motif,
  }) async => ResultatNiveauClasse.depuisJson(
    await _client.rpc<Map<String, dynamic>>(
      'donner_niveau_classe',
      params: <String, dynamic>{
        'p_groupe_id': groupeId,
        'p_niveau_id': niveauId,
        'p_motif': motif,
      },
    ),
  );

  @override
  Future<void> daterEntreeEtape({
    required String studentId,
    required DateTime jour,
    required String motif,
  }) => _client.rpc<void>(
    'dater_entree_etape',
    params: <String, dynamic>{
      'p_student_id': studentId,
      'p_date': jourPourServeur(jour),
      'p_motif': motif,
    },
  );

  @override
  Future<PlacementsAFaire> placementsAFaire() async =>
      PlacementsAFaire.depuisJson(
        await _client.rpc<Map<String, dynamic>>('eleves_sans_etape'),
      );

  @override
  Future<ResultatRattachement> rattacher() async =>
      ResultatRattachement.depuisJson(
        await _client.rpc<Map<String, dynamic>>('rattacher_eleves_et_classes'),
      );

  @override
  Future<EtatPublication> etatPublication(String versionId) async =>
      EtatPublication.depuisJson(
        await _client.rpc<Map<String, dynamic>>(
          'etat_publication_brouillon',
          params: <String, dynamic>{'p_version_id': versionId},
        ),
      );

  @override
  Future<String> repartirDesBases() =>
      _client.rpc<String>('repartir_des_bases_programme');
}

/// Le service du lot employe par l'application.
final Provider<ServicePlanClasse> servicePlanClasseProvider =
    Provider<ServicePlanClasse>(
      (Ref ref) => ServicePlanClasseSupabase(Supabase.instance.client),
    );

/// L'etape d'une classe, pour sa fiche cote direction.
final FutureProviderFamily<EtapeClasse?, String> etapeClasseProvider =
    FutureProvider.family<EtapeClasse?, String>((Ref ref, String groupeId) {
      ref.watch(personnesModifieesProvider);
      return ref.watch(servicePlanClasseProvider).etapeClasse(groupeId);
    });

/// Qui n'a pas d'etape, pour l'ecran Diagnostics.
final FutureProvider<PlacementsAFaire> placementsAFaireProvider =
    FutureProvider<PlacementsAFaire>((Ref ref) {
      ref.watch(personnesModifieesProvider);
      return ref.watch(servicePlanClasseProvider).placementsAFaire();
    });

/// Pourquoi un brouillon se publie ou non, pour l'ecran Programmes. Relu quand
/// les etapes ou les versions changent : il ne reste jamais sur un ancien avis.
final FutureProviderFamily<EtatPublication, String> etatPublicationProvider =
    FutureProvider.family<EtatPublication, String>((Ref ref, String versionId) {
      ref
        ..watch(niveauxProgrammeProvider(versionId))
        ..watch(versionsProgrammeProvider);
      return ref.watch(servicePlanClasseProvider).etatPublication(versionId);
    });
