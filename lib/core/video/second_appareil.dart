// SALLE-SECOND-APPAREIL (directeur, 23/11/2026 : « Il faut penser toujours a
// communiquer avec les gens ») : un profil, un appareil a la fois dans une
// seance, sans coupure brusque. Un second appareil demande la permission du
// premier ; le premier accepte (il sort proprement) ou refuse.
//
// Tout se decide en base (`salle_passage`, `salle_battement`,
// `salle_repondre_passage`, `salle_etat_passage`, `salle_annuler_passage`,
// migration 20261203200000) : le client ne fait que relayer et dire.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une demande qu'un autre appareil du meme profil adresse a celui-ci.
@immutable
class DemandePassage {
  /// Cree la demande.
  const DemandePassage({required this.id, required this.libelle});

  /// L'identifiant de la demande.
  final String id;

  /// L'etiquette de l'autre appareil (« Chrome · Android »).
  final String libelle;

  @override
  bool operator ==(Object other) =>
      other is DemandePassage && other.id == id && other.libelle == libelle;

  @override
  int get hashCode => Object.hash(id, libelle);
}

/// Ce que rend un battement : une demande a traiter, ou l'ordre de ceder la
/// place (l'autre appareil a ete accepte).
@immutable
class BattementSalle {
  /// Cree la reponse.
  const BattementSalle({this.demande, this.cede = false});

  /// Une demande en attente, ou `null`.
  final DemandePassage? demande;

  /// Vrai : cet appareil ne tient plus la place ; il doit sortir proprement.
  final bool cede;

  /// Lit la reponse du serveur ; une forme inattendue ne dit rien (pas de
  /// demande, pas d'ordre : jamais une coupure inventee).
  static BattementSalle depuisJson(Object? brut) {
    if (brut is! Map) return const BattementSalle();
    final Object? d = brut['demande'];
    DemandePassage? demande;
    if (d is Map && d['id'] is String) {
      demande = DemandePassage(
        id: d['id'] as String,
        libelle: d['libelle'] is String ? d['libelle'] as String : '',
      );
    }
    return BattementSalle(demande: demande, cede: brut['cede'] == true);
  }
}

/// L'etat d'une demande, vu du second appareil.
enum EtatPassage {
  /// Le premier appareil n'a pas encore repondu.
  enAttente,

  /// Le premier appareil a accepte : le jeton peut etre redemande.
  accepte,

  /// Le premier appareil s'est tu depuis trop longtemps : la place est libre.
  libre,

  /// Le premier appareil a refuse.
  refuse,

  /// Le premier appareil, vivant, n'a pas repondu a temps.
  sansReponse,

  /// La demande a ete annulee.
  annule,

  /// Etat inconnu de cette version : on continue d'attendre.
  inconnu;

  /// Lit l'etat du serveur.
  static EtatPassage depuisSql(Object? valeur) => switch (valeur) {
    'en_attente' => enAttente,
    'accepte' => accepte,
    'libre' => libre,
    'refuse' => refuse,
    'sans_reponse' => sansReponse,
    'annule' || 'servi' => annule,
    _ => inconnu,
  };
}

/// Les cinq gestes entre deux appareils.
abstract interface class PortSecondAppareil {
  /// Le battement du premier appareil : il garde la place et lit les demandes.
  Future<BattementSalle> battement({
    required String seanceId,
    required String profilId,
    required String appareilId,
    required String libelle,
  });

  /// Le premier appareil accepte ou refuse la demande [demandeId].
  Future<void> repondre(String demandeId, {required bool accepter});

  /// Le second appareil lit l'etat de SA demande.
  Future<EtatPassage> etat(String demandeId);

  /// Le second appareil renonce.
  Future<void> annuler(String demandeId);
}

/// L'implementation reelle, sur les RPC de la migration 20261203200000.
class SecondAppareilSupabase implements PortSecondAppareil {
  /// Cree l'adaptateur.
  const SecondAppareilSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<BattementSalle> battement({
    required String seanceId,
    required String profilId,
    required String appareilId,
    required String libelle,
  }) async => BattementSalle.depuisJson(
    await _client.rpc<Object?>(
      'salle_battement',
      params: <String, dynamic>{
        'p_session': seanceId,
        'p_profil': profilId,
        'p_appareil': appareilId,
        'p_libelle': libelle,
      },
    ),
  );

  @override
  Future<void> repondre(String demandeId, {required bool accepter}) =>
      _client.rpc<Object?>(
        'salle_repondre_passage',
        params: <String, dynamic>{
          'p_demande': demandeId,
          'p_accepter': accepter,
        },
      );

  @override
  Future<EtatPassage> etat(String demandeId) async {
    final Object? brut = await _client.rpc<Object?>(
      'salle_etat_passage',
      params: <String, dynamic>{'p_demande': demandeId},
    );
    return EtatPassage.depuisSql(brut is Map ? brut['etat'] : null);
  }

  @override
  Future<void> annuler(String demandeId) => _client.rpc<Object?>(
    'salle_annuler_passage',
    params: <String, dynamic>{'p_demande': demandeId},
  );
}

/// Le port employe par l'application.
final Provider<PortSecondAppareil> portSecondAppareilProvider =
    Provider<PortSecondAppareil>(
      (Ref ref) => SecondAppareilSupabase(Supabase.instance.client),
    );

/// Ou en est le second appareil qui demande a entrer.
enum PhasePassage {
  /// Rien a dire.
  aucune,

  /// La demande est partie ; on attend le premier appareil.
  attente,

  /// La connexion est coupee pendant l'attente : la demande reste posee.
  horsLigne,

  /// L'entree vient d'aboutir parce que l'autre appareil ne repondait plus.
  ancienSilencieux,
}

/// L'etat dit a l'ecran pendant qu'un second appareil attend.
@immutable
class PassageSalle {
  /// Cree l'etat.
  const PassageSalle({
    this.phase = PhasePassage.aucune,
    this.libelleAutre = '',
  });

  /// La phase.
  final PhasePassage phase;

  /// L'etiquette de l'autre appareil, quand le serveur la donne.
  final String libelleAutre;

  @override
  bool operator ==(Object other) =>
      other is PassageSalle &&
      other.phase == phase &&
      other.libelleAutre == libelleAutre;

  @override
  int get hashCode => Object.hash(phase, libelleAutre);
}

/// Le pont entre le service de jeton (qui attend) et l'ecran (qui le dit, et
/// qui peut annuler).
class PilotePassage extends Notifier<PassageSalle> {
  bool _annulation = false;

  @override
  PassageSalle build() => const PassageSalle();

  /// La phase en cours.
  PhasePassage get phase => state.phase;

  /// Vrai quand la personne a touche « Annuler ».
  bool get annulationDemandee => _annulation;

  /// Le service dit ou en est l'attente.
  void publier(PassageSalle etat) => state = etat;

  /// Une nouvelle attente commence : l'annulation precedente est oubliee.
  void commencer() => _annulation = false;

  /// La personne renonce.
  void annuler() => _annulation = true;

  /// L'ecran a montre la note, ou l'attente est finie.
  void effacer() => state = const PassageSalle();
}

/// L'etat de l'attente, a lire par l'ecran de la salle.
final NotifierProvider<PilotePassage, PassageSalle> passageSalleProvider =
    NotifierProvider<PilotePassage, PassageSalle>(PilotePassage.new);
