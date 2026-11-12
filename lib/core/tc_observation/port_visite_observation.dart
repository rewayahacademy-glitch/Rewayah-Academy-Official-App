import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'echec_observation.dart';
import 'guardian_session_visit.dart';
import 'port_politique_observation.dart';

/// Ce que la demande d'entree a produit.
///
/// **Un refus n'est pas une erreur.** [autorise] faux avec un [motifRefus]
/// renseigne est une reponse complete et normale du serveur : la porte a ete
/// interrogee, elle a repondu non. Une panne, elle, leve `EchecObservation`.
@immutable
class ResultatEntreeObservation {
  /// Cree un resultat.
  const ResultatEntreeObservation({
    required this.autorise,
    this.motifRefus,
    this.visite,
    this.budget,
  });

  /// Lit la reponse du serveur.
  factory ResultatEntreeObservation.depuisJson(Map<String, dynamic> json) {
    final Object? visite = json['visite'];
    final Object? budget = json['budget'];
    return ResultatEntreeObservation(
      autorise: json['autorise'] as bool? ?? false,
      motifRefus: MotifRefusObservation.depuisSql(
        json['motif_refus'] as String?,
      ),
      visite: visite is Map<String, dynamic>
          ? GuardianSessionVisit.depuisJson(visite)
          : null,
      budget: budget is Map<String, dynamic>
          ? BudgetObservation.depuisJson(budget)
          : null,
    );
  }

  /// Vrai quand l'entree est accordee.
  final bool autorise;

  /// Pourquoi elle ne l'est pas.
  final MotifRefusObservation? motifRefus;

  /// L'intervalle ouvert par le serveur.
  final GuardianSessionVisit? visite;

  /// Ce qui reste apres cette entree.
  final BudgetObservation? budget;
}

/// L'ouverture et la fermeture d'un intervalle d'observation.
///
/// **L'ordre est porteur de la garantie.** Le serveur verifie le lien
/// tuteur-enfant, la seance active, le groupe, la politique et le quota
/// **avant** d'ouvrir l'intervalle, et l'intervalle est ouvert **avant** que le
/// jeton video ne soit demande. Une entree qui obtiendrait d'abord un jeton
/// puis verifierait son quota aurait deja laisse entrer.
abstract interface class PortVisiteObservation {
  /// Demande d'entree. Le serveur verifie lien, seance, groupe, politique et
  /// quota AVANT le token.
  Future<ResultatEntreeObservation> entrer({
    required String sessionId,
    required RoleObservateur role,
  });

  /// Sortie volontaire. Annonce au serveur, qui ferme l'intervalle.
  Future<void> sortir({required String sessionId});

  /// Les visites d'une seance, pour l'audit.
  Future<List<GuardianSessionVisit>> visites({required String sessionId});
}

/// L'implementation reelle.
///
/// Les trois fonctions appelees ici (`entrer_observation`,
/// `sortir_observation`, `visites_observation`) sont posees par `0033`, `0037`
/// et `0039`, dites presentes en production depuis le 21/09/2026. Elles
/// etendent `rejoindre_observation()` et `assister_seance()` (migration
/// `0012`) plutot que d'ouvrir une troisieme porte : deux portes qui
/// refuseraient des seances differentes finiraient par se contredire, et
/// l'en-tete de `0012` le dit deja.
class VisiteObservationSupabase implements PortVisiteObservation {
  /// Cree le service.
  const VisiteObservationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<ResultatEntreeObservation> entrer({
    required String sessionId,
    required RoleObservateur role,
  }) async {
    final Object? reponse = await _appeler(
      'entrer_observation',
      <String, dynamic>{
        'p_session_id': sessionId,
        // Le role est transmis parce qu'un administrateur choisit son mode
        // AVANT d'entrer. Il n'est pas cru sur parole : le serveur verifie que
        // l'appelant a le droit de tenir ce role, exactement comme
        // `autoriser_jeton_video()` lit le role dans `session_participants` au
        // lieu de le recevoir en parametre.
        'p_role': role.valeurSql,
      },
    );
    if (reponse is Map<String, dynamic>) {
      return ResultatEntreeObservation.depuisJson(reponse);
    }
    throw const EchecObservation(MotifEchecObservation.reponseIllisible);
  }

  @override
  Future<void> sortir({required String sessionId}) async {
    // **L'echec n'est pas avale**, contrairement a `ServiceVideo.annoncerSortie`
    // qui le fait volontairement. La difference est nommee dans le contrat :
    // avaler un echec est acceptable pour une trace, inacceptable quand c'est
    // ce geste qui doit fermer un quota. L'appelant doit pouvoir dire que la
    // sortie n'a pas ete confirmee. **Aucun code serveur ne referme un
    // intervalle abandonne** (dependance DB-OBS-03) : sans cet appel, la
    // visite reste ouverte et brule la suivante.
    await _appeler('sortir_observation', <String, dynamic>{
      'p_session_id': sessionId,
    });
  }

  @override
  Future<List<GuardianSessionVisit>> visites({required String sessionId}) async {
    final Object? reponse = await _appeler(
      'visites_observation',
      <String, dynamic>{'p_session_id': sessionId},
    );
    if (reponse is List<dynamic>) {
      return <GuardianSessionVisit>[
        for (final Object? ligne in reponse)
          if (ligne is Map<String, dynamic>)
            GuardianSessionVisit.depuisJson(ligne),
      ];
    }
    throw const EchecObservation(MotifEchecObservation.reponseIllisible);
  }

  Future<Object?> _appeler(String fonction, Map<String, dynamic> params) async {
    try {
      return await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      throw EchecObservation(motifDeErreurPostgrest(e));
    } on Object {
      throw const EchecObservation(MotifEchecObservation.reseau);
    }
  }
}

/// Le service de visite d'observation employe par l'application.
final Provider<PortVisiteObservation> portVisiteObservationProvider =
    Provider<PortVisiteObservation>(
      (Ref ref) => VisiteObservationSupabase(Supabase.instance.client),
    );
