import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderFamily;

import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_parcours/libelles_parcours.dart';
import '../salle/position_reprise.dart';

/// La preparation pedagogique de la prochaine seance d'un groupe (CL-4.4).
///
/// Trois elements au plus, ceux de la spec : le support prevu, la position de
/// reprise et l'objectif. Aucune note de cours, aucun « point a renforcer »
/// (rectification 15).
@immutable
class PreparationSeance {
  /// Cree la preparation.
  const PreparationSeance({
    this.supportPrevu,
    this.positionReprise,
    this.objectif,
    this.pageReprise,
  });

  /// Le support prevu, en texte lisible.
  final String? supportPrevu;

  /// La position de reprise dans le support.
  final String? positionReprise;

  /// L'objectif de la seance.
  final String? objectif;

  /// La derniere page du Coran presentee dans la Classe, lue au serveur
  /// (CAHIER-C1) : l'ecran la dit « On reprend page N ». Une valeur, pas un
  /// texte, pour suivre la langue de l'ecran.
  final int? pageReprise;

  /// Vrai quand rien n'est renseigne.
  bool get estVide =>
      _vide(supportPrevu) &&
      _vide(positionReprise) &&
      _vide(objectif) &&
      pageReprise == null;

  static bool _vide(String? v) => v == null || v.trim().isEmpty;
}

/// Ce que l'enseignant sait d'un eleve, pedagogiquement (R15).
///
/// **Aucun champ prive** : ni telephone, ni courriel, ni adresse, ni foyer,
/// ni paiement, ni tuteur, ni geolocalisation, ni appareil. Il n'y a donc rien
/// a oublier de masquer.
@immutable
class ProjectionEleve {
  /// Cree la projection.
  const ProjectionEleve({
    this.pageReprise,
    this.dernierPoint,
    this.cleAvatar,
    this.objectif,
    this.presenceRecente,
    this.lectureEchouee = false,
  });

  /// Vrai quand la lecture du serveur a echoue : la fiche dit « Non
  /// disponible », jamais « Non renseigne », qui ferait passer une panne pour
  /// une absence de donnee.
  final bool lectureEchouee;

  /// L'objectif en cours de l'eleve, en texte neutre (fiche ENS-11, EN-4).
  final String? objectif;

  /// La presence recente, en texte neutre, sans jugement (fiche ENS-11).
  final String? presenceRecente;

  /// La page de reprise, en texte lisible (« Page 24 »).
  final String? pageReprise;

  /// Le dernier point utile, en texte neutre.
  final String? dernierPoint;

  /// La cle de la photo de l'eleve, ou nul : les initiales en repli (E5,
  /// K-44). La photo est visible de son enseignant.
  final String? cleAvatar;
}

/// La preparation de la prochaine seance d'un groupe. CAHIER-C1
/// (06/11/2026) : la position de reprise vient du serveur, la derniere page
/// presentee dans la salle ([pageRepriseClasseProvider]). `null` tant que
/// rien n'est connu (lecture, echec, aucune page) : jamais une page supposee.
/// Le support prevu et l'objectif restent sans source (C2, programme en
/// donnees). La demonstration la surcharge.
final ProviderFamily<PreparationSeance?, String> preparationSeanceProvider =
    Provider.family<PreparationSeance?, String>((Ref ref, String groupeId) {
      final int? page = ref.watch(pageRepriseClasseProvider(groupeId)).value;
      return page == null ? null : PreparationSeance(pageReprise: page);
    });

/// Ce que le serveur rend d'un eleve pour son enseignant
/// (`groupe_roster_enseignant`, migration 0033) : seulement la page de reprise
/// et les intentions du travail en cours. Le niveau et le cycle de cette
/// fonction ne sont pas lus : l'etape vient de `etapes_eleves_classe` (une
/// seule source, arbitrage du pilote du 08/11/2026).
@immutable
class LigneProjectionEleve {
  /// Cree la ligne.
  const LigneProjectionEleve({
    required this.studentId,
    this.pageReprise,
    this.intentions = const <IntentionPedagogique>[],
  });

  /// Lit une ligne de `groupe_roster_enseignant` ; `null` si elle est
  /// illisible. Une intention inconnue est ecartee, jamais remplacee.
  static LigneProjectionEleve? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['student_id'];
    if (id is! String || id.isEmpty) return null;
    final Object? page = brut['resume_page'];
    final Object? buts = brut['active_goals'];
    return LigneProjectionEleve(
      studentId: id,
      pageReprise: page is num && page > 0 ? page.toInt() : null,
      intentions: buts is List
          ? <IntentionPedagogique>[
              for (final Object? b in buts)
                if (IntentionPedagogique.depuisSql(b is String ? b : null)
                    case final IntentionPedagogique i)
                  i,
            ]
          : const <IntentionPedagogique>[],
    );
  }

  /// L'eleve (`profiles.id`).
  final String studentId;

  /// La derniere page du Coran ou l'eleve s'est arrete, ou nul.
  final int? pageReprise;

  /// Les intentions du travail donne encore a faire, trois au plus, dans
  /// l'ordre du serveur.
  final List<IntentionPedagogique> intentions;
}

/// Les lignes pedagogiques des eleves d'une Classe, cote serveur.
abstract interface class PortProjectionsEleves {
  /// Les lignes des eleves actifs de la Classe [groupeId], par `studentId`.
  /// Le serveur ne rend rien a qui n'est pas l'enseignant titulaire (un
  /// remplacant, par exemple) : la carte reste vide, sans erreur.
  Future<Map<String, LigneProjectionEleve>> projectionsDeLaClasse(
    String groupeId,
  );
}

/// Le port sans serveur : rien a lire.
class PortProjectionsSansServeur implements PortProjectionsEleves {
  /// Cree le port.
  const PortProjectionsSansServeur();

  @override
  Future<Map<String, LigneProjectionEleve>> projectionsDeLaClasse(
    String groupeId,
  ) async => const <String, LigneProjectionEleve>{};
}

/// Le port employe ; `lib/main.dart` pose l'adaptateur Supabase.
final Provider<PortProjectionsEleves> portProjectionsElevesProvider =
    Provider<PortProjectionsEleves>(
      (Ref _) => const PortProjectionsSansServeur(),
    );

/// La lecture serveur des lignes des eleves d'une Classe.
final FutureProviderFamily<Map<String, LigneProjectionEleve>, String>
projectionsServeurProvider =
    FutureProvider.family<Map<String, LigneProjectionEleve>, String>(
      (Ref ref, String groupeId) => ref
          .watch(portProjectionsElevesProvider)
          .projectionsDeLaClasse(groupeId),
    );

/// Vrai quand la lecture des lignes des eleves de la Classe a echoue.
final ProviderFamily<bool, String> projectionsEnEchecProvider =
    Provider.family<bool, String>(
      (Ref ref, String groupeId) =>
          ref.watch(projectionsServeurProvider(groupeId)).hasError,
    );

/// La projection d'une ligne serveur : « Page 24 », et les intentions du
/// travail en cours, sans doublon, jointes par le separateur commun. Aucun
/// mot nouveau. Rien d'invente : un champ sans valeur reste nul.
ProjectionEleve projectionDepuisLigne(LigneProjectionEleve ligne) {
  final List<String> intentions = <String>[
    for (final IntentionPedagogique i in ligne.intentions.toSet())
      libelleIntentionParcours(i),
  ];
  return ProjectionEleve(
    pageReprise: ligne.pageReprise == null
        ? null
        : t.tc.classe.fiche.page(page: ligne.pageReprise!),
    objectif: intentions.isEmpty
        ? null
        : intentions.join(LibellesGroupe.separateur),
  );
}

/// Les projections pedagogiques des eleves d'un groupe, par `studentId`,
/// tirees de [projectionsServeurProvider]. Vide pendant la lecture, en echec
/// (voir [projectionsEnEchecProvider]) ou sans serveur ; la demonstration la
/// surcharge.
final ProviderFamily<Map<String, ProjectionEleve>, String>
projectionElevesProvider =
    Provider.family<Map<String, ProjectionEleve>, String>((
      Ref ref,
      String groupeId,
    ) {
      final Map<String, LigneProjectionEleve>? lignes = ref
          .watch(projectionsServeurProvider(groupeId))
          .value;
      if (lignes == null) return const <String, ProjectionEleve>{};
      return <String, ProjectionEleve>{
        for (final MapEntry<String, LigneProjectionEleve> e in lignes.entries)
          e.key: projectionDepuisLigne(e.value),
      };
    });
