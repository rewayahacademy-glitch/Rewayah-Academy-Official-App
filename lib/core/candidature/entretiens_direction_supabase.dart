// V2-a (04/11/2026) : l'adaptateur Supabase des entretiens de la direction,
// sur les RPC de V1-a (`20261108000001_v1a_entretiens.sql`) et V1-a-bis
// (`20261109100000_v1a_bis_super_admin_entretiens.sql`). Le serveur decide de
// tout ; l'adaptateur traduit ses reponses et ses refus.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'candidatures_direction_supabase.dart' show refusDeGesteCandidature;
import 'gestes_candidature.dart';
import 'modeles_candidature_detail.dart';
import 'modeles_entretien_direction.dart';
import 'port_entretiens_direction.dart';

/// La fenetre lue par `mes_entretiens` : le plafond du serveur (90 jours).
const int joursEntretiensLus = 90;

/// Traduit un refus propre a l'entretien en [RefusEntretien]. [absenteEstEntretien]
/// dit si « absente » nomme l'entretien (ajouter, retirer, consigner) ou la
/// candidature (planifier, moteur). Tout autre refus passe au moteur des
/// candidatures. Public pour que le test prouve chaque traduction.
void refusEntretien(
  Map<String, dynamic> brut, {
  bool absenteEstEntretien = false,
}) {
  final Object? erreur = brut['erreur'];
  if (erreur == null) return;
  int entier(String cle) => brut[cle] is num ? (brut[cle] as num).toInt() : 0;
  switch (erreur) {
    case 'fondateurs_insuffisants':
      throw FondateursInsuffisants(
        exiges: entier('exiges'),
        presents: entier('presents'),
      );
    case 'debut_invalide':
      throw const DebutInvalide();
    case 'duree_invalide':
      throw const DureeInvalide();
    case 'participants_requis':
      throw const ParticipantsRequis();
    case 'participants_trop_nombreux':
      throw const ParticipantsTropNombreux();
    case 'participant_non_autorise':
      throw const ParticipantNonAutorise();
    case 'participant_autre_cote':
      throw const ParticipantAutreCote();
    case 'candidat_sans_compte':
      throw const CandidatSansCompte();
    case 'entretien_deja_planifie':
      throw const EntretienDejaPlanifie();
    case 'entretien_consigne':
    case 'entretien_deja_consigne':
      throw const EntretienConsigne();
    case 'dernier_participant':
      throw const DernierParticipant();
    case 'participant_absent':
      throw const ParticipantAbsent();
    case 'compte_rendu_requis':
      throw const CompteRenduRequis();
    case 'absente' when absenteEstEntretien:
      throw const EntretienIntrouvable();
    case 'hors_portee':
      throw const EntretienIntrouvable();
  }
  refusDeGesteCandidature(brut);
}

/// Les entretiens de [candidatureId] dans une reponse de `mes_entretiens`,
/// dans l'ordre du serveur (par debut). Une ligne illisible est ecartee.
List<EntretienCandidature> entretiensDepuisJson(
  Object? reponse,
  String candidatureId,
) => List<EntretienCandidature>.unmodifiable(<EntretienCandidature>[
  if (reponse is List)
    for (final Object? l in reponse)
      if (l is Map && l['candidature_id'] == candidatureId)
        if (_lisible(
              () =>
                  EntretienCandidature.depuisJson(Map<String, dynamic>.from(l)),
            )
            case final EntretienCandidature e)
          e,
]);

/// Les entretiens de la direction sur Supabase.
class EntretiensDirectionSupabase implements PortEntretiensDirection {
  /// Cree l'adaptateur.
  const EntretiensDirectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EntretienCandidature>> entretiens(String candidatureId) async =>
      entretiensDepuisJson(
        await _appel('mes_entretiens', <String, dynamic>{
          'p_jours': joursEntretiensLus,
        }),
        candidatureId,
      );

  @override
  Future<DetailEntretien> lire(String sessionId) async {
    final Map<String, dynamic> corps = _objet(
      await _appel('lire_entretien', <String, dynamic>{'p_session': sessionId}),
    );
    refusEntretien(corps, absenteEstEntretien: true);
    return DetailEntretien.depuisJson(corps);
  }

  @override
  Future<List<PersonnelEntretien>> personnel(String candidatureId) async {
    final Object? brut = await _appel(
      'personnel_pour_entretien',
      <String, dynamic>{'p_candidature': candidatureId},
    );
    return List<PersonnelEntretien>.unmodifiable(<PersonnelEntretien>[
      if (brut is List)
        for (final Object? l in brut)
          if (l is Map)
            if (_lisible(
                  () => PersonnelEntretien.depuisJson(
                    Map<String, dynamic>.from(l),
                  ),
                )
                case final PersonnelEntretien p)
              p,
    ]);
  }

  @override
  Future<ResultatGeste> planifier({
    required String candidatureId,
    required DateTime debut,
    required int dureeMinutes,
    required List<String> participants,
    required int versionAttendue,
    required String cleIdempotence,
  }) => _geste(
    'planifier_entretien',
    parametresPlanifier(
      candidatureId: candidatureId,
      debut: debut,
      dureeMinutes: dureeMinutes,
      participants: participants,
      versionAttendue: versionAttendue,
      cleIdempotence: cleIdempotence,
    ),
  );

  @override
  Future<void> ajouter(String sessionId, String profilId) =>
      _participant('ajouter_participant_entretien', sessionId, profilId);

  @override
  Future<void> retirer(String sessionId, String profilId) =>
      _participant('retirer_participant_entretien', sessionId, profilId);

  @override
  Future<ResultatGeste> consigner({
    required String sessionId,
    required IssueEntretien issue,
    required String? motif,
    required int versionAttendue,
    required String cleIdempotence,
  }) => _geste('consigner_entretien', <String, dynamic>{
    'p_session': sessionId,
    'p_issue': issue.valeurSql,
    'p_motif': motif,
    'p_version_attendue': versionAttendue,
    'p_cle_idempotence': cleIdempotence,
  }, absenteEstEntretien: true);

  Future<void> _participant(
    String fonction,
    String sessionId,
    String profilId,
  ) async {
    final Map<String, dynamic> corps = _objet(
      await _appel(fonction, <String, dynamic>{
        'p_session': sessionId,
        'p_profil': profilId,
      }),
    );
    refusEntretien(corps, absenteEstEntretien: true);
  }

  Future<ResultatGeste> _geste(
    String fonction,
    Map<String, dynamic> params, {
    bool absenteEstEntretien = false,
  }) async {
    final Object? brut;
    try {
      brut = await _appel(fonction, params);
    } on PermissionInsuffisante {
      rethrow;
    } on CapaciteIndisponible {
      rethrow;
    } on PostgrestException catch (e) {
      // La seance d'entretien est au nom de la direction qui planifie : la
      // contrainte d'exclusion des seances refuse un creneau qui chevauche une
      // autre de ses seances. Un refus nomme, rien n'a ete ecrit.
      if (e.code == '23P01') throw const CreneauOccupe();
      rethrow;
    } on Exception {
      // Pas de reponse : le geste est non confirme ; la meme cle le rejoue.
      throw const GesteNonConfirme();
    }
    final Map<String, dynamic> corps = _objet(brut);
    refusEntretien(corps, absenteEstEntretien: absenteEstEntretien);
    return ResultatGeste.depuisJson(corps);
  }

  Future<Object?> _appel(String fonction, Map<String, dynamic> params) async {
    try {
      return await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      // Fonction absente du schema : le lot serveur n'est pas verse.
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceEntretiens);
      }
      rethrow;
    }
  }
}

/// Les parametres de `planifier_entretien`. Public pour que le test prouve la
/// forme envoyee : le debut en UTC, la version attendue et la cle
/// d'idempotence partent avec le geste.
Map<String, dynamic> parametresPlanifier({
  required String candidatureId,
  required DateTime debut,
  required int dureeMinutes,
  required List<String> participants,
  required int versionAttendue,
  required String cleIdempotence,
}) => <String, dynamic>{
  'p_candidature': candidatureId,
  'p_debut': debut.toUtc().toIso8601String(),
  'p_duree_minutes': dureeMinutes,
  'p_participants': participants,
  'p_version_attendue': versionAttendue,
  'p_cle_idempotence': cleIdempotence,
};

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}

T? _lisible<T>(T Function() lire) {
  try {
    return lire();
  } on FormatException {
    return null;
  }
}
