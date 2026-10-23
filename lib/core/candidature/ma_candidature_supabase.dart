// L'adaptateur Supabase du candidat (`PortMaCandidature`), sur les RPC du lot
// CAND-L2A1 (`20261022000000_cand_l2a1_moteur_salle_examen.sql`) et de L6 :
// `conditions_remuneration_candidat`, `questionnaire_salle_examen`,
// `enregistrer_reponses_salle_examen`, `envoyer_reponses_salle_examen`,
// `retrait_candidat`, `options_paiement_confirmees`.
//
// Les refus metier arrivent **dans la reponse** (`{"erreur": "..."}`), jamais
// en exception : le serveur les rend pour qu'ils ne laissent aucune ecriture.
// 42501 dit « non autorise » (compte hors du cadre d'une candidature en
// cours). Une panne de reseau devient [HorsLigneCandidature] : ce qui a ete
// envoye est alors non confirme, et l'ecran le dit.
//
// L'etat n'est jamais lu ici : `etat_dossier()` reste la seule source de
// l'etat de la candidature. Les envois rendent le bloc `candidature` relu.
//
// Aucun montant n'est lu : `parElevePresentEtParHeure` et `devise` ne sont pas
// parcourus, meme si le serveur les rendait encore (decision du 22/10/2026).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'modeles_candidature.dart';
import 'port_ma_candidature.dart';

/// Appelle une RPC. [dependanceSiAbsente] nomme ce qui manque quand le serveur
/// ne connait pas encore la fonction (lot serveur non verse) : la lecture est
/// alors une capacite indisponible, pas une panne qu'on reessaie.
Future<Object?> _appel(
  SupabaseClient client,
  String fonction, [
  Map<String, dynamic>? params,
  String? dependanceSiAbsente,
]) async {
  try {
    return await client.rpc<Object?>(fonction, params: params);
  } on PostgrestException catch (e) {
    if (e.code == '42501') {
      throw PermissionInsuffisante(fonction);
    }
    // PGRST202 : fonction absente du cache de schema ; 42883 : fonction
    // inconnue de la base. Le lot serveur n'est pas encore verse.
    if (dependanceSiAbsente != null &&
        (e.code == 'PGRST202' || e.code == '42883')) {
      throw CapaciteIndisponible(dependanceSiAbsente);
    }
    rethrow;
  } on FormatException {
    rethrow;
  } on Exception {
    throw const HorsLigneCandidature();
  }
}

/// Le candidat servi par Supabase.
class MaCandidatureSupabase implements PortMaCandidature {
  /// Cree l'adaptateur sur le client de l'application.
  const MaCandidatureSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ConditionsRemuneration> conditionsRemuneration() async {
    final Map<String, dynamic> brut = _objet(
      await _appel(
        _client,
        'conditions_remuneration_candidat',
        null,
        dependanceConditionsRemuneration,
      ),
    );
    if (brut['disponible'] != true) {
      throw const CapaciteIndisponible(dependanceConditionsRemuneration);
    }
    return ConditionsRemuneration.depuisJson(brut);
  }

  @override
  Future<Questionnaire> questionnaire() async {
    final Map<String, dynamic> brut = _objet(
      await _appel(
        _client,
        'questionnaire_salle_examen',
        null,
        dependanceCandidature,
      ),
    );
    if (brut['disponible'] != true) {
      throw const CapaciteIndisponible(dependanceCandidature);
    }
    return Questionnaire.depuisJson(brut);
  }

  @override
  Future<MoyensConfirmes> moyensConfirmes(String paysVersement) async {
    final Map<String, dynamic> brut = _objet(
      await _appel(_client, 'options_paiement_confirmees', <String, dynamic>{
        'p_pays': paysVersement,
      }, dependanceCandidature),
    );
    final Object? lignes = brut['lignes'];
    bool virement = false;
    final Map<String, OperateurPaiement> parCode =
        <String, OperateurPaiement>{};
    if (lignes is List) {
      for (final Object? ligne in lignes) {
        if (ligne is! Map) {
          continue;
        }
        if (ligne['methode'] == 'virement_bancaire') {
          virement = true;
        } else if (ligne['methode'] == 'mobile_money' &&
            ligne['operateur'] is String) {
          // Seuls les operateurs de monnaie mobile se declarent ; le virement
          // bancaire se declare par la question du compte bancaire.
          final String code = ligne['operateur'] as String;
          final Object? nom = ligne['operateurNom'];
          parCode.putIfAbsent(
            code,
            () => OperateurPaiement(
              code: code,
              nom: nom is String && nom.trim().isNotEmpty ? nom.trim() : code,
            ),
          );
        }
      }
    }
    return MoyensConfirmes(
      virementBancaire: virement,
      operateurs: List<OperateurPaiement>.unmodifiable(parCode.values),
    );
  }

  @override
  Future<ResultatBrouillon> enregistrerBrouillon({
    required String versionQuestionnaire,
    required Map<String, Object?> reponses,
    required int versionBrouillon,
    required String cleIdempotence,
  }) async {
    final Map<String, dynamic> brut = _objet(
      await _appel(
        _client,
        'enregistrer_reponses_salle_examen',
        <String, dynamic>{
          'p_questionnaire_version': versionQuestionnaire,
          'p_reponses': reponses,
          'p_version_attendue': versionBrouillon,
          'p_cle_idempotence': cleIdempotence,
        },
      ),
    );
    _refus(brut);
    final Object? version = brut['versionBrouillon'];
    if (version is! int) {
      throw const FormatException('Version de brouillon absente.');
    }
    return ResultatBrouillon(
      versionBrouillon: version,
      complet: brut['complet'] == true,
      manquants: <String>[
        if (brut['manquants'] is List)
          for (final Object? m in brut['manquants'] as List)
            if (m is String) m,
      ],
    );
  }

  @override
  Future<CandidatureDossier> envoyerReponses({
    required String versionQuestionnaire,
    required Map<String, Object?> reponses,
    required bool accordRemuneration,
    required String versionConditions,
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    final Map<String, dynamic> brut = _objet(
      await _appel(_client, 'envoyer_reponses_salle_examen', <String, dynamic>{
        'p_questionnaire_version': versionQuestionnaire,
        'p_reponses': reponses,
        'p_accord_remuneration': accordRemuneration,
        'p_version_conditions': versionConditions,
        'p_version_attendue': versionAttendue,
        'p_cle_idempotence': cleIdempotence,
      }),
    );
    _refus(brut);
    return _candidatureRelue(brut);
  }

  @override
  Future<CandidatureDossier> retirer({
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    final Map<String, dynamic> brut = _objet(
      await _appel(_client, 'retrait_candidat', <String, dynamic>{
        'p_version_attendue': versionAttendue,
        'p_cle_idempotence': cleIdempotence,
      }),
    );
    _refus(brut);
    return _candidatureRelue(brut);
  }
}

/// Le bloc `candidature` relu au serveur ; une reponse sans lui n'est pas un
/// succes (jamais de faux succes).
CandidatureDossier _candidatureRelue(Map<String, dynamic> brut) {
  final CandidatureDossier relue = CandidatureDossier.depuisJson(
    brut['candidature'],
  );
  if (!relue.existe) {
    throw const FormatException('Candidature relue absente.');
  }
  return relue;
}

/// Traduit un refus rendu par le serveur en exception typee.
void _refus(Map<String, dynamic> brut) {
  final Object? erreur = brut['erreur'];
  if (erreur == null) {
    return;
  }
  List<String> champs() => <String>[
    if (brut['champs'] is List)
      for (final Object? c in brut['champs'] as List)
        if (c is String) c,
  ];
  // La cause nommee d'un champ refuse (`motifs`), quand le serveur en donne
  // une ; la cle n'est rendue que si une cause est nommee.
  Map<String, String> motifs() => <String, String>{
    if (brut['motifs'] is Map)
      for (final MapEntry<Object?, Object?> e
          in (brut['motifs'] as Map<Object?, Object?>).entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
  };
  switch (erreur) {
    case 'conflit_candidature':
      throw ConflitCandidature(_entier(brut['versionCourante']));
    case 'conflit_brouillon':
      throw ConflitBrouillon(_entier(brut['versionCourante']));
    case 'transition_interdite':
      throw TransitionInterdite(
        enPause: brut['enPause'] == true || brut['raison'] == 'pause',
      );
    case 'questionnaire_perime':
      throw QuestionnairePerime(brut['versionCourante'] as String?);
    case 'reponses_invalides':
      throw ReponsesInvalides(champs(), motifs: motifs());
    case 'reponses_incompletes':
      throw ReponsesIncompletes(champs());
    case 'accord_remuneration_requis':
      throw const AccordRemunerationRequis();
    case 'conditions_indisponibles':
      throw const CapaciteIndisponible(dependanceConditionsRemuneration);
    case 'conditions_perimees':
      throw ConditionsPerimees(brut['versionCourante'] as String?);
    case 'engagement_non_accepte':
      throw EngagementNonAccepte(
        versionRequise: brut['versionRequise'] as String?,
        publie: brut['publie'] == true,
      );
    case 'absente':
      throw const CandidatureAbsente();
    case 'hors_portee':
      throw const PermissionInsuffisante('candidature');
    default:
      throw FormatException('Refus inconnu : $erreur');
  }
}

int? _entier(Object? v) => v is int ? v : null;

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) {
    throw const FormatException('Objet attendu.');
  }
  return Map<String, dynamic>.from(v);
}
