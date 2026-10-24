import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'echec_observation.dart';
import 'guardian_observation_policy.dart';

/// Pourquoi le serveur refuse une entree en observation.
///
/// Six causes, et elles se disent toutes a l'usager : contrairement a
/// `MotifRefusSalle`, il n'y a rien a proteger ici. Un tuteur a le droit de
/// savoir qu'il a deja utilise sa visite ; le lui cacher lui ferait presser le
/// bouton dix fois.
enum MotifRefusObservation {
  /// L'administration a ferme l'observation pour ce groupe.
  policyDesactivee('policy_desactivee'),

  /// Le nombre de visites autorisees est atteint.
  quotaVisitesAtteint('quota_visites_atteint'),

  /// Le temps total autorise est consomme.
  tempsEpuise('temps_epuise'),

  /// L'appelant n'est le tuteur d'aucun eleve de cette seance.
  lienTuteurAbsent('lien_tuteur_absent'),

  /// La seance n'est pas en cours.
  seanceNonActive('seance_non_active'),

  /// La salle n'est pas ouverte a cette heure.
  horsFenetre('hors_fenetre');

  const MotifRefusObservation(this.valeurSql);

  /// La valeur telle que le serveur la nomme.
  final String valeurSql;

  /// Lit un motif depuis sa valeur SQL. `null` sur une valeur inconnue.
  static MotifRefusObservation? depuisSql(String? valeur) {
    for (final MotifRefusObservation motif in MotifRefusObservation.values) {
      if (motif.valeurSql == valeur) {
        return motif;
      }
    }
    return null;
  }
}

/// Ce qu'il reste a un observateur pour une seance donnee.
///
/// **Verite serveur, jamais un calcul local.** Chaque champ arrive du serveur
/// et n'est jamais recalcule ici : un client qui deduirait `restant` de son
/// propre chronometre deciderait lui-meme de la duree de sa visite, ce que la
/// specification section 11.4 interdit en une phrase -- « le client ne peut pas
/// prolonger sa visite en modifiant un timer ».
@immutable
class BudgetObservation {
  /// Cree un budget.
  const BudgetObservation({
    required this.policyVersion,
    required this.visitesUtilisees,
    required this.visitesMax,
    required this.tempsConsomme,
    required this.tempsTotalMax,
    required this.restant,
    required this.peutEntrer,
    this.motifRefus,
    this.visiteEnCours = false,
  });

  /// Lit le budget rendu par le serveur.
  factory BudgetObservation.depuisJson(Map<String, dynamic> json) =>
      BudgetObservation(
        policyVersion: json['policy_version'] as String? ?? '',
        visitesUtilisees: (json['visites_utilisees'] as num?)?.toInt() ?? 0,
        visitesMax: (json['visites_max'] as num?)?.toInt() ?? 0,
        tempsConsomme: Duration(
          seconds: (json['temps_consomme_secondes'] as num?)?.toInt() ?? 0,
        ),
        tempsTotalMax: Duration(
          seconds: (json['temps_total_max_secondes'] as num?)?.toInt() ?? 0,
        ),
        restant: Duration(
          seconds: (json['restant_secondes'] as num?)?.toInt() ?? 0,
        ),
        peutEntrer: json['peut_entrer'] as bool? ?? false,
        motifRefus: MotifRefusObservation.depuisSql(
          json['motif_refus'] as String?,
        ),
        visiteEnCours: json['visite_en_cours'] as bool? ?? false,
      );

  /// La version de politique sous laquelle ce budget a ete calcule.
  final String policyVersion;

  /// Visites deja consommees pour cette seance.
  final int visitesUtilisees;

  /// Visites autorisees pour cette seance.
  final int visitesMax;

  /// Temps deja consomme.
  final Duration tempsConsomme;

  /// Temps total autorise.
  final Duration tempsTotalMax;

  /// Temps restant, tel que le serveur le mesure.
  final Duration restant;

  /// Vrai quand une entree serait acceptee a l'instant de la lecture.
  final bool peutEntrer;

  /// Pourquoi elle ne le serait pas. `null` quand [peutEntrer] est vrai.
  final MotifRefusObservation? motifRefus;

  /// Vrai quand un intervalle de cet observateur est deja ouvert sur la
  /// seance (cle `visite_en_cours`, migration `0039`, purement informative).
  ///
  /// Faux quand la cle manque : un serveur anterieur a `0039` ne le dit pas,
  /// et l'entree le decidera de toute facon.
  final bool visiteEnCours;

  /// Vrai quand il ne reste plus une seconde.
  bool get epuise => restant <= Duration.zero;
}

/// La politique et le budget d'observation, resolus cote serveur.
///
/// Les deux vont ensemble et se lisent separement : la politique dit la regle
/// du groupe, le budget dit ce qu'il en reste pour **cette** seance. Un ecran
/// qui n'aurait que la politique afficherait « 120 secondes » a un tuteur qui
/// en a deja consomme 118.
abstract interface class PortPolitiqueObservation {
  /// Politique effective, apres resolution academie vers groupe vers
  /// desactivation. Cote serveur.
  Future<GuardianObservationPolicy> politiqueEffective({
    required String groupeId,
  });

  /// Budget restant du tuteur pour CETTE seance. Verite serveur, jamais un
  /// calcul local.
  Future<BudgetObservation> budget({required String sessionId});

  /// Le meme budget, relu a intervalle regulier.
  Stream<BudgetObservation> suivreBudget({required String sessionId});

  /// Ecrit la politique d'un groupe, et rend celle qui s'applique ensuite.
  ///
  /// **Reserve a l'administration** : le serveur exige `app_role() = 'admin'`
  /// ET `app_account_valid()`, et ne croit pas le client sur parole. L'echec
  /// sort en [EchecObservation], jamais en exception nue -- un ecran ne doit
  /// pas avoir a connaitre PostgREST pour dire « ca n'a pas pu s'enregistrer ».
  Future<GuardianObservationPolicy> definirPolitiqueGroupe({
    required String groupeId,
    required GuardianObservationPolicy politique,
  });
}

/// A quelle cadence le budget est relu au serveur pendant une visite.
///
/// **Ce n'est pas la barriere**, c'est le filet. La barriere est le jeton :
/// il est emis pour une duree bornee et le serveur le revoque a l'epuisement
/// du quota. Ce rythme decide seulement de la fraicheur de l'affichage et de
/// la promptitude de la sortie propre cote client.
///
/// Cinq secondes pour un budget par defaut de cent vingt : l'affichage ne
/// derive jamais de plus d'un vingt-quatrieme du budget, et une visite entiere
/// coute vingt-quatre lectures, ce qui reste sans commune mesure avec le flux
/// video qu'elle accompagne. Un flux temps reel serait plus elegant, mais
/// Supabase Realtime n'est branche nulle part dans `lib/` (MAPPING section 9) :
/// l'ouvrir pour ce seul usage serait une infrastructure neuve pour deux
/// minutes de compte a rebours.
const Duration cadenceBudgetObservation = Duration(seconds: 5);

/// L'implementation reelle.
///
/// Les quatre fonctions appelees ici sont posees par les migrations `0033`,
/// `0036` et `0039`, que le bilan C0 du 23/09/2026 et la cartographie du
/// 24/09/2026 disent presentes en production. Sur un deploiement ou l'une
/// manquerait, l'appel rend `MotifEchecObservation.capaciteAbsente`, et
/// l'ecran le dit en clair plutot que d'afficher un budget invente.
class PolitiqueObservationSupabase implements PortPolitiqueObservation {
  /// Cree le service.
  const PolitiqueObservationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<GuardianObservationPolicy> politiqueEffective({
    required String groupeId,
  }) async {
    final Object? reponse = await _appeler(
      'politique_observation_effective',
      <String, dynamic>{'p_groupe_id': groupeId},
    );
    if (reponse is Map<String, dynamic>) {
      return GuardianObservationPolicy.depuisJson(reponse);
    }
    throw const EchecObservation(MotifEchecObservation.reponseIllisible);
  }

  @override
  Future<BudgetObservation> budget({required String sessionId}) async {
    final Object? reponse = await _appeler(
      'budget_observation',
      <String, dynamic>{'p_session_id': sessionId},
    );
    if (reponse is Map<String, dynamic>) {
      return BudgetObservation.depuisJson(reponse);
    }
    throw const EchecObservation(MotifEchecObservation.reponseIllisible);
  }

  @override
  Stream<BudgetObservation> suivreBudget({required String sessionId}) {
    // Une minuterie annulable, et non une boucle `async*` qui attend : le
    // defaut a deja ete mesure sur la presence (`service_presence.dart`), ou un
    // `Future.delayed` continuait de courir apres la sortie de salle.
    final StreamController<BudgetObservation> sortie =
        StreamController<BudgetObservation>();
    Timer? minuterie;

    Future<void> lire() async {
      try {
        final BudgetObservation lu = await budget(sessionId: sessionId);
        if (!sortie.isClosed) {
          sortie.add(lu);
        }
      } on EchecObservation catch (e) {
        // L'erreur est propagee, pas avalee : c'est ce flux qui doit fermer la
        // visite quand le quota tombe a zero. Un flux muet laisserait le
        // compte a rebours local seul maitre du temps, exactement ce que la
        // specification section 11.4 refuse.
        if (!sortie.isClosed) {
          sortie.addError(e);
        }
      }
    }

    sortie
      ..onListen = () {
        minuterie = Timer.periodic(
          cadenceBudgetObservation,
          (Timer _) => unawaited(lire()),
        );
        unawaited(lire());
      }
      ..onCancel = () {
        minuterie?.cancel();
        return sortie.close();
      };
    return sortie.stream;
  }

  @override
  Future<GuardianObservationPolicy> definirPolitiqueGroupe({
    required String groupeId,
    required GuardianObservationPolicy politique,
  }) async {
    final Object? reponse = await _appeler(
      'definir_politique_observation_groupe',
      <String, dynamic>{
        'p_groupe_id': groupeId,
        'p_source': politique.source.valeurSql,
        'p_max_visites': politique.maxVisitsPerSession,
        'p_max_secondes': politique.maxTotalObservationTime.inSeconds,
        // Le cinquieme parametre existe depuis la migration
        // `0036_observation_defauts_academie_et_plafond_visite_groupe.sql`,
        // appliquee en production le 21/09/2026. PostgREST resout une RPC par
        // le NOM de ses arguments : sur une base anterieure a `0036`, cet
        // appel a cinq arguments reviendrait en `PGRST202`, que
        // `motifDeErreurPostgrest` traduit en
        // `MotifEchecObservation.capaciteAbsente`, et l'ecran le dirait en
        // clair au lieu de faire croire a un enregistrement.
        'p_max_secondes_par_visite': politique.maxParVisite?.inSeconds,
      },
    );
    if (reponse is Map<String, dynamic>) {
      return GuardianObservationPolicy.depuisJson(reponse);
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

/// Traduit un refus PostgREST sans inventer une cause qu'il n'a pas donnee.
///
/// `42883` est le code PostgreSQL d'une fonction inconnue et `PGRST202` celui
/// d'une fonction absente du cache de schema : les deux disent la meme chose --
/// la capacite serveur n'est pas installee sur ce deploiement.
///
/// `23505` est la violation d'unicite que `guardian_visit_ouvert_uidx` leve
/// quand une visite de cet observateur est deja ouverte : ce n'est pas une
/// panne reseau, et « Reessayer » echouerait a l'identique (DB-OBS-06).
MotifEchecObservation motifDeErreurPostgrest(PostgrestException erreur) =>
    switch (erreur.code) {
      '42883' || 'PGRST202' => MotifEchecObservation.capaciteAbsente,
      '23505' => MotifEchecObservation.visiteDejaOuverte,
      _ => MotifEchecObservation.reseau,
    };

/// Le service de politique d'observation employe par l'application.
final Provider<PortPolitiqueObservation> portPolitiqueObservationProvider =
    Provider<PortPolitiqueObservation>(
      (Ref ref) => PolitiqueObservationSupabase(Supabase.instance.client),
    );

/// La politique effective d'un groupe.
final FutureProviderFamily<GuardianObservationPolicy, String>
politiqueObservationProvider =
    FutureProvider.family<GuardianObservationPolicy, String>(
      (Ref ref, String groupeId) => ref
          .watch(portPolitiqueObservationProvider)
          .politiqueEffective(groupeId: groupeId),
    );

/// Le budget d'observation d'une seance, lu une fois.
final FutureProviderFamily<BudgetObservation, String>
budgetObservationProvider = FutureProvider.family<BudgetObservation, String>(
  (Ref ref, String sessionId) =>
      ref.watch(portPolitiqueObservationProvider).budget(sessionId: sessionId),
);
