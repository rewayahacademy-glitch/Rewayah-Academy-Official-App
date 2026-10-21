import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';

/// L'etat d'un jeton d'observation, tel que la base le calcule.
///
/// **Calcule en base, jamais ici** : un ecran qui comparerait `expire_le` a
/// l'horloge du poste afficherait « actif » sur un jeton mort pour la base des
/// que les deux horloges divergeraient.
enum EtatJeton {
  /// Vivant : il ouvre encore des sessions.
  actif,

  /// Revoque a la main. Definitif.
  revoque,

  /// Arrive a son terme.
  expire;

  /// Lit la valeur rendue par `jetons_agent_actifs()`.
  static EtatJeton depuisSql(String? valeur) => switch (valeur) {
    'actif' => EtatJeton.actif,
    'revoque' => EtatJeton.revoque,
    // Un etat inconnu se traite comme mort : on ne laisse jamais passer par
    // defaut ce qu'on n'a pas su lire.
    _ => EtatJeton.expire,
  };
}

/// Un jeton d'observation, vu par l'administration.
///
/// Le secret n'y figure pas : il n'existe qu'une fois, dans la reponse de
/// l'emission. Ce qu'on garde est le prefixe, assez pour reconnaitre une ligne,
/// trop peu pour rejouer quoi que ce soit.
@immutable
class JetonAgent {
  /// Cree un jeton.
  const JetonAgent({
    required this.id,
    required this.libelle,
    required this.prefixe,
    required this.parcours,
    required this.observeIdentifiant,
    required this.observePrenom,
    required this.identiteMasquee,
    required this.expireLe,
    required this.creeLe,
    required this.remises,
    required this.etat,
    this.revoqueLe,
    this.derniereRemiseLe,
  });

  /// Lit une ligne de `jetons_agent_actifs()`.
  factory JetonAgent.depuisJson(Map<String, dynamic> json) => JetonAgent(
    id: json['id'] as String? ?? '',
    libelle: json['libelle'] as String? ?? '',
    prefixe: json['prefixe'] as String? ?? '',
    parcours: AppRole.depuisSql(json['parcours'] as String?),
    observeIdentifiant: json['observe_identifiant'] as String? ?? '',
    observePrenom: json['observe_prenom'] as String? ?? '',
    identiteMasquee: json['identite_masquee'] as bool? ?? true,
    expireLe: DateTime.parse(json['expire_le'] as String).toLocal(),
    creeLe: DateTime.parse(json['cree_le'] as String).toLocal(),
    revoqueLe: DateTime.tryParse(json['revoque_le'] as String? ?? '')
        ?.toLocal(),
    derniereRemiseLe: DateTime.tryParse(
      json['derniere_remise_le'] as String? ?? '',
    )?.toLocal(),
    remises: (json['remises'] as num?)?.toInt() ?? 0,
    etat: EtatJeton.depuisSql(json['etat'] as String?),
  );

  /// Identifiant de la ligne.
  final String id;

  /// Ce que l'operateur a ecrit en emettant. Obligatoire : un jeton anonyme est
  /// un jeton que personne n'ose revoquer.
  final String libelle;

  /// Les douze premiers caracteres du secret.
  final String prefixe;

  /// Le parcours observe, fige a l'emission.
  final AppRole? parcours;

  /// L'identifiant immuable de la personne observee.
  final String observeIdentifiant;

  /// Son prenom. L'administration le voit : c'est elle qui choisit qui est
  /// observe, elle ne peut pas le faire sur un identifiant seul.
  final String observePrenom;

  /// Comment designer la personne observee a l'ecran.
  ///
  /// Vide, [observePrenom] laisserait « (IDENT) » : une parenthese ouverte sur
  /// rien. La migration `0016` le vide en mode observation.
  String get observeLibelle => observePrenom.isEmpty
      ? observeIdentifiant
      : '$observePrenom ($observeIdentifiant)';

  /// Vrai quand l'agent lira des identifiants a la place des prenoms.
  final bool identiteMasquee;

  /// Terme du jeton.
  final DateTime expireLe;

  /// Emission.
  final DateTime creeLe;

  /// Revocation, quand elle a eu lieu.
  final DateTime? revoqueLe;

  /// Derniere ouverture de session.
  final DateTime? derniereRemiseLe;

  /// Nombre d'ouvertures de session.
  final int remises;

  /// Actif, revoque ou expire.
  final EtatJeton etat;

  /// Vrai quand ce jeton n'a jamais servi. Un jeton emis et jamais remis est le
  /// signe le plus courant d'un lien qui n'est pas arrive a destination.
  bool get jamaisServi => remises == 0;
}

/// Une personne observable, proposee par l'ecran d'emission.
@immutable
class PersonneObservable {
  /// Cree une personne observable.
  const PersonneObservable({
    required this.id,
    required this.identifiant,
    required this.prenom,
    required this.nom,
    required this.role,
  });

  /// Lit une ligne de `personnes_observables()`.
  factory PersonneObservable.depuisJson(Map<String, dynamic> json) =>
      PersonneObservable(
        id: json['id'] as String? ?? '',
        identifiant: json['immutable_id'] as String? ?? '',
        prenom: json['first_name'] as String? ?? '',
        nom: json['last_name'] as String? ?? '',
        role: AppRole.depuisSql(json['role'] as String?),
      );

  /// Identifiant du profil.
  final String id;

  /// Identifiant immuable.
  final String identifiant;

  /// Prenom.
  final String prenom;

  /// Nom de famille.
  final String nom;

  /// Role, qui sera le parcours du jeton.
  final AppRole? role;

  /// Ce qui s'affiche dans la liste.
  ///
  /// L'identifiant seul quand l'identite est masquee : sans ce repli la
  /// pilule afficherait « (IDENT) », parenthese ouverte sur rien.
  String get libelle {
    final String complet = '$prenom $nom'.trim();
    return complet.isEmpty ? identifiant : '$complet ($identifiant)';
  }

  /// Le nom seul, ou l'identifiant quand l'identite est masquee : le
  /// selecteur de personne affiche l'identifiant sur sa propre ligne.
  String get libelleNom {
    final String complet = '$prenom $nom'.trim();
    return complet.isEmpty ? identifiant : complet;
  }
}

/// Ce que l'emission rend, une seule fois.
@immutable
class JetonEmis {
  /// Cree le resultat d'une emission.
  const JetonEmis({
    required this.secret,
    required this.id,
    required this.expireLe,
  });

  /// Le secret en clair. **Il ne repassera jamais** : ni la base ni cet ecran
  /// ne peuvent le retrouver.
  final String secret;

  /// L'identifiant de la ligne creee.
  final String id;

  /// Le terme du jeton.
  final DateTime expireLe;
}

/// L'acces d'administration aux jetons d'observation (ADR-025).
abstract interface class ServiceAgent {
  /// Les jetons, actifs d'abord.
  Future<List<JetonAgent>> lister();

  /// Les personnes qu'un jeton peut observer.
  Future<List<PersonneObservable>> personnes();

  /// Emet un jeton. Rend le secret une seule fois.
  Future<JetonEmis> emettre({
    required String libelle,
    required String profilObserve,
    required int dureeHeures,
    required bool identiteMasquee,
  });

  /// Revoque un jeton. Rend faux s'il n'y avait rien a revoquer.
  Future<bool> revoquer(String id);
}

/// L'implementation Supabase.
class ServiceAgentSupabase implements ServiceAgent {
  /// Cree le service.
  ServiceAgentSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<JetonAgent>> lister() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'jetons_agent_actifs',
    );
    return lignes
        .whereType<Map<String, dynamic>>()
        .map(JetonAgent.depuisJson)
        .toList(growable: false);
  }

  @override
  Future<List<PersonneObservable>> personnes() async {
    // **Une fonction, et non la table.** Cet ecran lisait `profiles` en
    // direct : aucun appel de fonction, donc aucun endroit ou appliquer le
    // masquage des identites, et une liste de prenoms en clair sous une
    // banniere qui promettait le contraire (migration `0016`). Le tri reste
    // fait en base : deux rendus successifs ne doivent pas proposer deux
    // ordres.
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'personnes_observables',
    );

    return lignes
        .whereType<Map<String, dynamic>>()
        .map(PersonneObservable.depuisJson)
        .toList(growable: false);
  }

  @override
  Future<JetonEmis> emettre({
    required String libelle,
    required String profilObserve,
    required int dureeHeures,
    required bool identiteMasquee,
  }) async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'creer_jeton_agent',
      params: <String, dynamic>{
        'p_libelle': libelle,
        'p_profil_observe': profilObserve,
        'p_duree_heures': dureeHeures,
        'p_identite_masquee': identiteMasquee,
      },
    );

    final Map<String, dynamic> ligne = lignes
        .whereType<Map<String, dynamic>>()
        .first;

    return JetonEmis(
      secret: ligne['jeton'] as String? ?? '',
      id: ligne['jeton_id'] as String? ?? '',
      expireLe: DateTime.parse(ligne['expire_le'] as String).toLocal(),
    );
  }

  @override
  Future<bool> revoquer(String id) async {
    final Object? rendu = await _client.rpc<Object?>(
      'revoquer_jeton_agent',
      params: <String, dynamic>{'p_id': id},
    );
    return rendu == true;
  }
}

/// Le service d'administration des jetons d'observation.
final Provider<ServiceAgent> serviceAgentProvider = Provider<ServiceAgent>(
  (Ref ref) => ServiceAgentSupabase(Supabase.instance.client),
);
