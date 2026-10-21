import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs dans ce depot : le type d'une famille de providers
// n'est pas exporte par l'entree principale de Riverpod 3, il vit dans
// `misc.dart` (meme convention que `service_planning.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modeles_enseignant.dart';

/// Ce que le role Enseignant lit et ecrit.
///
/// **Le contrat partage du lot « role Enseignant ».** Ecrit par l'Agent Z,
/// consomme par les agents A a E, modifie par personne d'autre
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/TEACHER_FILE_OWNERSHIP.md`).
///
/// Il ne remplace pas `ServicePlanning`, qui suffit deja pour les
/// disponibilites, le fuseau et les affectations, ni `ServicePresence`, ni
/// `ServiceCoran`. Il comble exactement ce qui manquait : lire ses seances
/// **groupees par seance**, lire ses propres groupes, et rendre un cahier de
/// transmission.
abstract interface class ServiceEnseignant {
  /// Les seances de l'enseignant, une entree par seance.
  ///
  /// Distinct de `ServicePlanning.seances()`, qui passe par `mes_seances_v` et
  /// rend une ligne par eleve : pour un cours de groupe, la meme seance y
  /// revient autant de fois qu'elle compte d'eleves.
  Future<List<SeanceEnseignant>> seances();

  /// Les eleves attendus a une seance.
  ///
  /// Prenom et identifiant immuable seulement. Le masquage d'observation est
  /// applique par la base, jamais par l'ecran.
  Future<List<MembreSeance>> rosterDeSeance(String seanceId);

  /// Les groupes actifs de l'enseignant.
  Future<List<GroupeEnseignant>> groupes();

  /// Les membres actifs d'un de ses groupes.
  Future<List<MembreSeance>> membresDuGroupe(String groupeId);

  /// Les seances terminees dont le cahier manque, la plus ancienne d'abord.
  Future<List<CahierEnRetard>> cahiersEnRetard();

  /// Tout ce que le systeme sait deja d'une seance. `null` quand la seance est
  /// introuvable.
  Future<BrouillonCahier?> brouillon(String seanceId);

  /// Depose un cahier de transmission.
  ///
  /// [cleIdempotence] est generee **une seule fois, a la redaction**, par
  /// `FileRapports.enregistrer`, et jamais regeneree au rejeu : c'est ce qui
  /// permet a la contrainte d'unicite C9 de refuser un doublon en base. Un
  /// rejeu sous la meme cle n'est donc pas une erreur, c'est une confirmation,
  /// et l'implementation le traite comme un succes.
  Future<void> deposerCahier({
    required String cleIdempotence,
    required Map<String, dynamic> contenu,
    required String seanceId,
  });
}

/// L'implementation reelle.
class ServiceEnseignantSupabase implements ServiceEnseignant {
  /// Cree le service.
  const ServiceEnseignantSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SeanceEnseignant>> seances() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('mes_seances_enseignant_v')
        .select()
        .order('started_at');
    return lignes.map(SeanceEnseignant.depuisJson).toList(growable: false);
  }

  @override
  Future<List<MembreSeance>> rosterDeSeance(String seanceId) async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('teacher_roster_v')
        .select()
        .eq('session_id', seanceId)
        .order('first_name');
    return lignes.map(MembreSeance.depuisRoster).toList(growable: false);
  }

  @override
  Future<List<GroupeEnseignant>> groupes() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from('mes_groupes_v')
        .select()
        .order('weekday')
        .order('hour_local');
    return lignes.map(GroupeEnseignant.depuisJson).toList(growable: false);
  }

  @override
  Future<List<MembreSeance>> membresDuGroupe(String groupeId) async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'mon_groupe_detail',
      params: <String, dynamic>{'p_groupe_id': groupeId},
    );
    return reponse
        .map(
          (dynamic ligne) =>
              MembreSeance.depuisGroupe(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<List<CahierEnRetard>> cahiersEnRetard() async {
    final List<dynamic> reponse = await _client.rpc<List<dynamic>>(
      'mes_rapports_en_attente',
    );
    return reponse
        .map(
          (dynamic ligne) =>
              CahierEnRetard.depuisJson(ligne as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<BrouillonCahier?> brouillon(String seanceId) async {
    final Object? reponse = await _client.rpc<Object?>(
      'brouillon_cahier',
      params: <String, dynamic>{'p_session_id': seanceId},
    );
    if (reponse is! Map<String, dynamic>) {
      return null;
    }
    return BrouillonCahier.depuisJson(reponse);
  }

  @override
  Future<void> deposerCahier({
    required String cleIdempotence,
    required Map<String, dynamic> contenu,
    required String seanceId,
  }) async {
    final String? auteur = _client.auth.currentUser?.id;
    if (auteur == null) {
      // Une session absente n'est pas une erreur reseau : on ne met pas ce
      // cahier en file, on le refuse tout de suite.
      throw StateError('cahier sans session');
    }

    try {
      await _client.from('lesson_reports').insert(<String, dynamic>{
        'session_id': seanceId,
        'idempotency_key': cleIdempotence,
        'content': contenu,
        'author_profile_id': auteur,
      });
    } on PostgrestException catch (erreur) {
      // 23505 : la contrainte d'unicite C9 a refuse un doublon. Le cahier est
      // donc **deja arrive** : le rejeu a fait son travail, et la file peut
      // retirer sa ligne. Le traiter comme un echec ferait boucler la file a
      // l'infini sur un cahier deja enregistre.
      if (erreur.code != '23505') {
        rethrow;
      }
    }
  }
}

/// Le service du role Enseignant employe par l'application.
final Provider<ServiceEnseignant> serviceEnseignantProvider =
    Provider<ServiceEnseignant>(
      (Ref ref) => ServiceEnseignantSupabase(Supabase.instance.client),
    );

/// Les seances de l'enseignant connecte, une entree par seance.
final FutureProvider<List<SeanceEnseignant>> seancesEnseignantProvider =
    FutureProvider<List<SeanceEnseignant>>(
      (Ref ref) => ref.watch(serviceEnseignantProvider).seances(),
    );

/// Les eleves attendus a une seance donnee.
final FutureProviderFamily<List<MembreSeance>, String> rosterSeanceProvider =
    FutureProvider.family<List<MembreSeance>, String>(
      (Ref ref, String seanceId) =>
          ref.watch(serviceEnseignantProvider).rosterDeSeance(seanceId),
    );

/// Les groupes actifs de l'enseignant connecte.
final FutureProvider<List<GroupeEnseignant>> groupesEnseignantProvider =
    FutureProvider<List<GroupeEnseignant>>(
      (Ref ref) => ref.watch(serviceEnseignantProvider).groupes(),
    );

/// Les membres d'un de ses groupes.
///
/// Volontairement distinct de `membresGroupeProvider`
/// (`core/admin/service_groupes.dart`), qui passe par `groupe_detail()` :
/// celle-la est reservee a l'administration et rend un nom de famille.
final FutureProviderFamily<List<MembreSeance>, String>
membresGroupeEnseignantProvider =
    FutureProvider.family<List<MembreSeance>, String>(
      (Ref ref, String groupeId) =>
          ref.watch(serviceEnseignantProvider).membresDuGroupe(groupeId),
    );

/// Les cahiers en retard de l'enseignant connecte.
final FutureProvider<List<CahierEnRetard>> cahiersEnRetardProvider =
    FutureProvider<List<CahierEnRetard>>(
      (Ref ref) => ref.watch(serviceEnseignantProvider).cahiersEnRetard(),
    );

/// Le brouillon prerempli du cahier d'une seance.
final FutureProviderFamily<BrouillonCahier?, String> brouillonCahierProvider =
    FutureProvider.family<BrouillonCahier?, String>(
      (Ref ref, String seanceId) =>
          ref.watch(serviceEnseignantProvider).brouillon(seanceId),
    );
