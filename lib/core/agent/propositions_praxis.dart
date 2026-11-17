// PX-2 (niveau B) : les propositions que Praxis PREPARE et que la direction
// valide ou ecarte (`direction_praxis_propositions`, `direction_praxis_valider`,
// `direction_praxis_ecarter`). Praxis n'execute jamais un geste : valider appelle
// la porte publique du geste, sous l'identite de la personne qui valide, et le
// moteur decide comme pour un geste fait a la main.
//
// Une lecture qui echoue ne rend jamais « aucune proposition » : l'appelant voit
// l'erreur. Le SERVEUR garde les cotes de la direction qui lit (hors_portee).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Les gestes que Praxis peut preparer (liste fermee, comme le serveur).
enum GestePrepare {
  /// Demander un complement au candidat.
  demanderComplement('demander_complement'),

  /// Planifier un entretien.
  planifierEntretien('planifier_entretien'),

  /// Admettre en salle de verification.
  admettreVerifications('admettre_verifications');

  const GestePrepare(this.sql);

  /// Le nom du geste cote serveur.
  final String sql;

  /// Le geste du nom serveur, ou `null` : un geste inconnu n'est pas invente.
  static GestePrepare? depuisSql(Object? brut) {
    for (final GestePrepare g in GestePrepare.values) {
      if (g.sql == brut) return g;
    }
    return null;
  }
}

/// Une proposition ouverte.
@immutable
class PropositionPraxis {
  /// Cree la proposition.
  const PropositionPraxis({
    required this.id,
    required this.geste,
    required this.reference,
    required this.nom,
    required this.versionProposee,
    required this.versionActuelle,
    required this.parametres,
    required this.texte,
    required this.expireLe,
  });

  /// Lit une ligne rendue par le serveur, ou `null` quand elle est illisible.
  static PropositionPraxis? depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return null;
    final Object? id = brut['id'];
    final GestePrepare? geste = GestePrepare.depuisSql(brut['geste']);
    final Object? reference = brut['reference'];
    final DateTime? expire = brut['expireLe'] is String
        ? DateTime.tryParse(brut['expireLe'] as String)?.toUtc()
        : null;
    if (id is! String ||
        geste == null ||
        reference is! String ||
        expire == null) {
      return null;
    }
    return PropositionPraxis(
      id: id,
      geste: geste,
      reference: reference,
      nom: brut['nom'] is String ? brut['nom'] as String : '',
      versionProposee: (brut['versionProposee'] as num?)?.toInt() ?? 0,
      versionActuelle: (brut['versionActuelle'] as num?)?.toInt() ?? 0,
      parametres: brut['parametres'] is Map<String, dynamic>
          ? brut['parametres'] as Map<String, dynamic>
          : const <String, dynamic>{},
      texte: brut['texte'] is String ? brut['texte'] as String : '',
      expireLe: expire,
    );
  }

  /// L'identifiant de la proposition.
  final String id;

  /// Le geste prepare.
  final GestePrepare geste;

  /// La reference du dossier (`CAND-...`).
  final String reference;

  /// Le nom du candidat, tel que la direction le lit deja.
  final String nom;

  /// La version du dossier que Praxis a vue.
  final int versionProposee;

  /// La version du dossier maintenant.
  final int versionActuelle;

  /// Les parametres ecrits par Praxis (elements, motif, debut, duree).
  final Map<String, dynamic> parametres;

  /// Le texte ecrit par Praxis pour la personne qui valide, mot pour mot.
  final String texte;

  /// Quand la proposition expire.
  final DateTime expireLe;

  /// Le dossier a change depuis la proposition : le moteur la refuserait.
  bool get perimee => versionActuelle != versionProposee;

  /// Les elements demandes (`demander_complement`).
  List<String> get elements => <String>[
    if (parametres['elements'] is List)
      for (final Object? e in parametres['elements'] as List)
        if (e is String) e,
  ];

  /// Le motif ecrit pour le candidat (`demander_complement`), mot pour mot.
  String? get motif =>
      parametres['motif'] is String ? parametres['motif'] as String : null;

  /// Le debut propose (`planifier_entretien`).
  DateTime? get debut => parametres['debut'] is String
      ? DateTime.tryParse(parametres['debut'] as String)?.toUtc()
      : null;

  /// La duree proposee, en minutes (`planifier_entretien`).
  int? get dureeMinutes => (parametres['duree_minutes'] as num?)?.toInt();
}

/// Ce que rend une validation ou un ecart : fait, ou refuse avec le code et la
/// reponse brute du serveur (le moteur dit ses refus).
@immutable
class ResultatProposition {
  /// Cree le resultat.
  const ResultatProposition({required this.fait, this.erreur, this.brut});

  /// Le geste est fait (ou l'ecart pris).
  final bool fait;

  /// Le code du refus, quand il y en a un.
  final String? erreur;

  /// La reponse brute, pour que l'ecran dise le refus du moteur en mots.
  final Map<String, dynamic>? brut;
}

/// L'acces de la direction aux propositions de Praxis.
abstract interface class ServicePropositionsPraxis {
  /// Les propositions ouvertes, celles des cotes de la direction qui lit.
  Future<List<PropositionPraxis>> ouvertes();

  /// Valide : execute le geste par la porte publique, sous l'identite de la
  /// direction (double verification exigee par la base). [participants] : pour
  /// `planifier_entretien`, choisis par la direction.
  Future<ResultatProposition> valider({
    required String id,
    required int version,
    required String cle,
    List<String>? participants,
  });

  /// Ecarte, avec un motif facultatif (300 signes au plus).
  Future<ResultatProposition> ecarter({
    required String id,
    required String cle,
    String? motif,
  });
}

/// L'implementation Supabase.
class ServicePropositionsPraxisSupabase implements ServicePropositionsPraxis {
  /// Cree le service.
  ServicePropositionsPraxisSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PropositionPraxis>> ouvertes() async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_propositions',
      params: <String, dynamic>{'p_filtre': 'ouvertes'},
    );
    if (rendu is! List) return const <PropositionPraxis>[];
    return <PropositionPraxis>[
      for (final Object? l in rendu) ?PropositionPraxis.depuisJson(l),
    ];
  }

  ResultatProposition _lire(Object? rendu) {
    if (rendu is! Map<String, dynamic>) {
      return const ResultatProposition(fait: false, erreur: 'illisible');
    }
    final Object? erreur = rendu['erreur'];
    if (erreur is String) {
      return ResultatProposition(fait: false, erreur: erreur, brut: rendu);
    }
    return ResultatProposition(fait: rendu['ok'] == true, brut: rendu);
  }

  @override
  Future<ResultatProposition> valider({
    required String id,
    required int version,
    required String cle,
    List<String>? participants,
  }) async => _lire(
    await _client.rpc<Object?>(
      'direction_praxis_valider',
      params: <String, dynamic>{
        'p_proposition': id,
        'p_version': version,
        'p_cle': cle,
        'p_participants': participants,
      },
    ),
  );

  @override
  Future<ResultatProposition> ecarter({
    required String id,
    required String cle,
    String? motif,
  }) async => _lire(
    await _client.rpc<Object?>(
      'direction_praxis_ecarter',
      params: <String, dynamic>{
        'p_proposition': id,
        'p_motif': motif,
        'p_cle': cle,
      },
    ),
  );
}

/// Le service des propositions.
final Provider<ServicePropositionsPraxis> servicePropositionsPraxisProvider =
    Provider<ServicePropositionsPraxis>(
      (Ref ref) => ServicePropositionsPraxisSupabase(Supabase.instance.client),
    );

/// Les propositions ouvertes. Une lecture qui echoue reste une ERREUR (jamais
/// une liste vide) ; pas de nouvel essai automatique.
final FutureProvider<List<PropositionPraxis>> propositionsPraxisProvider =
    FutureProvider.autoDispose<List<PropositionPraxis>>(
      (Ref ref) => ref.watch(servicePropositionsPraxisProvider).ouvertes(),
      retry: (int retryCount, Object error) => null,
    );
