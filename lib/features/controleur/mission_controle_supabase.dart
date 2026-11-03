// N3, D3 (03/11/2026) : la mission du controleur, lue et commencee au
// serveur.
//
//   ma_mission_controle()            la mission actionnable (ou `{}`), avec ce
//                                    que l'ecran « Controle » affiche
//                                    (migration 20261105800000) ;
//   demarrer_mission_controle(uuid)  la visite commence : mission `en_cours`,
//                                    controleur inscrit dans la seance.
//
// Le serveur decide de tout (seconde etape de connexion, capacite, echeance,
// portee). Le client ne deduit rien d'un role.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/strings.g.dart';
import 'mission_controle.dart';

/// La mission du controleur, par les fonctions du serveur.
class MissionControleSupabase implements PortMissionControle {
  /// Cree l'adaptateur.
  const MissionControleSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<MissionControle?> maMission() async {
    final Object? brut = await _client.rpc<Object?>('ma_mission_controle');
    if (brut is! Map) {
      throw const FormatException('Mission de controle invalide.');
    }
    return missionDepuis(Map<String, dynamic>.from(brut));
  }

  @override
  Future<void> demarrer(String missionId) => _client.rpc<Object?>(
    'demarrer_mission_controle',
    params: <String, dynamic>{'p_mission_id': missionId},
  );
}

/// La mission lue dans la reponse du serveur ; nulle pour `{}`.
MissionControle? missionDepuis(Map<String, dynamic> ligne) {
  if (ligne.isEmpty || ligne['id'] == null) return null;
  final String? seance = ligne['session_id'] as String?;
  final String? classe = ligne['classe'] as String?;
  final String? debut = ligne['debut'] as String?;
  final String? fin = ligne['fin_prevue'] as String?;
  if (seance == null || classe == null || debut == null || fin == null) {
    throw const FormatException('Projection de la mission incomplete.');
  }
  final Object? n = ligne['nombre_eleves'];
  return MissionControle(
    id: ligne['id'] as String,
    seanceId: seance,
    classe: classe,
    enseignant: nomEnseignantMission(
      prenom: ligne['enseignant_prenom'] as String? ?? '',
      titre: ligne['enseignant_titre'] as String?,
    ),
    nombreEleves: n is num ? n.toInt() : 0,
    debut: DateTime.parse(debut).toLocal(),
    finPrevue: DateTime.parse(fin).toLocal(),
    etat: switch (ligne['seance_statut']) {
      'in_progress' => EtatMissionControle.enDirect,
      'planned' || 'preflight' => EtatMissionControle.prevue,
      _ => EtatMissionControle.indisponible,
    },
    commencee: ligne['statut'] == 'en_cours',
  );
}

/// L'enseignant precede de son titre public (« Sayyid Ibrahim »), comme dans
/// les messages ; le prenom seul sans titre connu.
String nomEnseignantMission({required String prenom, String? titre}) =>
    switch (titre) {
      'sayid' || 'sayyid' => '${t.tc.groupe.enseignant.sayyid} $prenom',
      'sayyida' => '${t.tc.groupe.enseignant.sayyida} $prenom',
      _ => prenom,
    };
