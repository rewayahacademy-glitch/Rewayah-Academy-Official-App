import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ou en est une demande de connexion a Praxis (PX-OAUTH 2d), telle que la
/// base le dit (`direction_praxis_oauth_lire`).
enum EtatDemandePraxis {
  /// Attend la decision de la direction.
  enAttente,

  /// Deja accordee ou refusee : elle ne se rouvre pas.
  decidee,

  /// Plus de dix minutes : il faut relancer la connexion depuis le client.
  expiree,

  /// Aucune demande de ce nom (ou illisible).
  inconnue;

  /// Lit `etat`. Une valeur inconnue se traite comme [inconnue] : jamais
  /// « en attente » par defaut.
  static EtatDemandePraxis depuisSql(String? valeur) => switch (valeur) {
    'en_attente' => EtatDemandePraxis.enAttente,
    'decidee' => EtatDemandePraxis.decidee,
    'expiree' => EtatDemandePraxis.expiree,
    _ => EtatDemandePraxis.inconnue,
  };
}

/// Une demande de connexion a Praxis, vue par la direction. Aucun code,
/// aucun secret : le nom du client, l'hote ou il reviendra, l'etat.
@immutable
class DemandeAutorisationPraxis {
  /// Cree une demande.
  const DemandeAutorisationPraxis({
    required this.etat,
    this.client,
    this.hote,
    this.expireLe,
    this.peutAutoriser = false,
  });

  /// Lit la reponse de `direction_praxis_oauth_lire`.
  factory DemandeAutorisationPraxis.depuisJson(Map<String, dynamic> json) =>
      DemandeAutorisationPraxis(
        etat: EtatDemandePraxis.depuisSql(json['etat'] as String?),
        client: json['client'] as String?,
        hote: json['hote'] as String?,
        expireLe: DateTime.tryParse(json['expireLe'] as String? ?? '')
            ?.toLocal(),
        peutAutoriser: json['peutAutoriser'] == true,
      );

  /// Ou en est la demande.
  final EtatDemandePraxis etat;

  /// Le nom que le client s'est donne (texte libre, jamais une preuve).
  final String? client;

  /// L'hote ou la decision renverra la personne (`claude.ai`) : lui seul est
  /// verifie par la base.
  final String? hote;

  /// Le terme de la demande.
  final DateTime? expireLe;

  /// La direction a au moins un cote ouvert a Praxis : sans cela, autoriser
  /// est refuse par la base.
  final bool peutAutoriser;
}

/// Ce que la decision rend : l'adresse de retour vers le client, ou la cause
/// fermee d'un refus de la base.
@immutable
class DecisionAutorisationPraxis {
  /// Cree une decision.
  const DecisionAutorisationPraxis({this.redirection, this.erreur});

  /// Lit la reponse de `direction_praxis_oauth_decider`.
  factory DecisionAutorisationPraxis.depuisJson(Map<String, dynamic> json) =>
      DecisionAutorisationPraxis(
        redirection: json['redirection'] as String?,
        erreur: json['erreur'] as String?,
      );

  /// Ou renvoyer la personne (le client, avec le code ou `access_denied`).
  final String? redirection;

  /// `inconnue`, `deja_decidee`, `expiree` ou `sans_cote`.
  final String? erreur;
}

/// L'etat d'une connexion, tel que la base le calcule (jamais compare ici a
/// l'horloge du poste).
enum EtatConnexionPraxis {
  /// Vivante : le client peut encore se renouveler.
  active,

  /// Coupee par la direction. Definitif.
  revoquee,

  /// Arrivee au terme de ses 90 jours : une nouvelle autorisation est requise.
  expiree;

  /// Lit `etat`. Un etat inconnu se traite comme mort.
  static EtatConnexionPraxis depuisSql(String? valeur) => switch (valeur) {
    'active' => EtatConnexionPraxis.active,
    'revoquee' => EtatConnexionPraxis.revoquee,
    _ => EtatConnexionPraxis.expiree,
  };
}

/// Une connexion d'une application (claude.ai) a Praxis : une ligne par
/// connexion, jamais une par cle d'une heure. Aucun secret.
@immutable
class ConnexionPraxis {
  /// Cree une connexion.
  const ConnexionPraxis({
    required this.id,
    required this.client,
    required this.creeLe,
    required this.expireLe,
    required this.etat,
    this.derniereUtilisationLe,
    this.revoqueeLe,
    this.motifRevocation,
  });

  /// Lit une ligne de `direction_praxis_oauth_connexions`.
  factory ConnexionPraxis.depuisJson(Map<String, dynamic> json) =>
      ConnexionPraxis(
        id: json['id'] as String? ?? '',
        client: json['client'] as String? ?? '',
        creeLe: DateTime.parse(json['creeLe'] as String).toLocal(),
        expireLe: DateTime.parse(json['expireLe'] as String).toLocal(),
        etat: EtatConnexionPraxis.depuisSql(json['etat'] as String?),
        derniereUtilisationLe: DateTime.tryParse(
          json['derniereUtilisationLe'] as String? ?? '',
        )?.toLocal(),
        revoqueeLe: DateTime.tryParse(json['revoqueeLe'] as String? ?? '')
            ?.toLocal(),
        motifRevocation: json['motifRevocation'] as String?,
      );

  /// Identifiant de la connexion.
  final String id;

  /// Le nom que l'application s'est donne (texte libre, jamais une preuve).
  final String client;

  /// Quand la direction l'a autorisee.
  final DateTime creeLe;

  /// Le terme de la connexion (90 jours au plus).
  final DateTime expireLe;

  /// Vivante, coupee ou arrivee a son terme.
  final EtatConnexionPraxis etat;

  /// La derniere fois qu'elle a servi ; `null` si jamais.
  final DateTime? derniereUtilisationLe;

  /// Quand elle a ete coupee.
  final DateTime? revoqueeLe;

  /// Le motif ecrit par la direction.
  final String? motifRevocation;
}

/// L'acces de la direction aux demandes de connexion a Praxis.
abstract interface class ServiceAutorisationPraxis {
  /// Les connexions, les plus recentes d'abord (50 au plus).
  Future<List<ConnexionPraxis>> connexions();

  /// Coupe une connexion et toutes ses cles, avec son motif (double
  /// verification exigee par la base). Rend faux s'il n'y avait rien a couper.
  Future<bool> revoquerConnexion({required String id, required String motif});

  /// Lit une demande.
  Future<DemandeAutorisationPraxis> lire(String demande);

  /// Accorde ou refuse (double verification exigee par la base).
  Future<DecisionAutorisationPraxis> decider(
    String demande, {
    required bool accepter,
  });
}

/// L'implementation Supabase.
class ServiceAutorisationPraxisSupabase implements ServiceAutorisationPraxis {
  /// Cree le service.
  ServiceAutorisationPraxisSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ConnexionPraxis>> connexions() async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_oauth_connexions',
    );
    return (rendu is List<dynamic> ? rendu : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ConnexionPraxis.depuisJson)
        .toList(growable: false);
  }

  @override
  Future<bool> revoquerConnexion({
    required String id,
    required String motif,
  }) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_oauth_revoquer',
      params: <String, dynamic>{'p_id': id, 'p_motif': motif},
    );
    return rendu == true;
  }

  @override
  Future<DemandeAutorisationPraxis> lire(String demande) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_oauth_lire',
      params: <String, dynamic>{'p_demande': demande},
    );
    return DemandeAutorisationPraxis.depuisJson(
      rendu is Map<String, dynamic> ? rendu : <String, dynamic>{},
    );
  }

  @override
  Future<DecisionAutorisationPraxis> decider(
    String demande, {
    required bool accepter,
  }) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_oauth_decider',
      params: <String, dynamic>{'p_demande': demande, 'p_accepter': accepter},
    );
    return DecisionAutorisationPraxis.depuisJson(
      rendu is Map<String, dynamic> ? rendu : <String, dynamic>{},
    );
  }
}

/// Le service de la direction pour les demandes de connexion a Praxis.
final Provider<ServiceAutorisationPraxis> serviceAutorisationPraxisProvider =
    Provider<ServiceAutorisationPraxis>(
      (Ref ref) => ServiceAutorisationPraxisSupabase(Supabase.instance.client),
    );

/// La demande lue pour la page de consentement.
final demandeAutorisationPraxisProvider = FutureProvider.autoDispose
    .family<DemandeAutorisationPraxis, String>(
      (Ref ref, String demande) =>
          ref.watch(serviceAutorisationPraxisProvider).lire(demande),
    );

/// Les connexions lues pour la section Praxis.
final connexionsPraxisProvider =
    FutureProvider.autoDispose<List<ConnexionPraxis>>(
      (Ref ref) => ref.watch(serviceAutorisationPraxisProvider).connexions(),
    );
