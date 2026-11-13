// HORLOGE-ET-LIEU, partie B (H5 et H6) : ce que la direction lit des villes des
// enseignants. Elle voit la ville d'un enseignant, la verifie, et recoit la
// liste des incoherences entre pays, fuseau et ville. Rien n'est corrige seul.
// Reserve a la direction : le serveur refuse tout autre role (42501).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// La ville d'un enseignant, vue par la direction.
@immutable
class LieuEnseignantDirection {
  /// Cree la ligne.
  const LieuEnseignantDirection({
    required this.profilId,
    required this.ville,
    required this.paysCode,
    required this.verifie,
  });

  /// Lit une ligne de `lieux_enseignants_direction`, ou `null`.
  static LieuEnseignantDirection? lire(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['profil_id'];
    final Object? ville = brut['ville'];
    final Object? pays = brut['pays_code'];
    if (id is! String || ville is! String || pays is! String) return null;
    return LieuEnseignantDirection(
      profilId: id,
      ville: ville,
      paysCode: pays,
      verifie: brut['verifie'] == true,
    );
  }

  /// L'identifiant du profil de l'enseignant.
  final String profilId;

  /// Le nom de la ville.
  final String ville;

  /// Le code ISO du pays.
  final String paysCode;

  /// Vrai quand la direction a verifie la ville.
  final bool verifie;
}

/// Ce qui ne concorde pas.
enum TypeIncoherenceLieu {
  /// Aucune ville choisie.
  sansVille('sans_ville'),

  /// Le fuseau enregistre n'est pas celui de la ville.
  fuseauDifferentVille('fuseau_different_ville'),

  /// Le pays enregistre n'est pas celui de la ville.
  paysDifferentVille('pays_different_ville'),

  /// Le pays et le fuseau enregistres ne vont pas ensemble.
  paysFuseau('pays_fuseau');

  const TypeIncoherenceLieu(this.valeurSql);

  /// La valeur rendue par le serveur.
  final String valeurSql;

  /// Lit un type, ou `null` quand il est inconnu.
  static TypeIncoherenceLieu? depuisSql(String? v) => TypeIncoherenceLieu.values
      .where((TypeIncoherenceLieu x) => x.valeurSql == v)
      .firstOrNull;
}

/// Une incoherence a verifier par la direction.
@immutable
class IncoherenceLieu {
  /// Cree l'incoherence.
  const IncoherenceLieu({
    required this.profilId,
    required this.enseignant,
    required this.type,
  });

  /// Lit une ligne de `incoherences_lieu_direction`, ou `null` quand elle ne
  /// concerne pas un enseignant ou ne se lit pas.
  static IncoherenceLieu? lireEnseignant(Object? brut) {
    if (brut is! Map || brut['role'] != 'teacher') return null;
    final Object? id = brut['profil_id'];
    final TypeIncoherenceLieu? type = TypeIncoherenceLieu.depuisSql(
      brut['type'] as String?,
    );
    if (id is! String || type == null) return null;
    final String nom = <String>[
      if (brut['prenom'] is String) brut['prenom'] as String,
      if (brut['nom'] is String) brut['nom'] as String,
    ].join(' ');
    return IncoherenceLieu(profilId: id, enseignant: nom, type: type);
  }

  /// L'identifiant du profil de l'enseignant.
  final String profilId;

  /// Son nom, tel que la direction le lit.
  final String enseignant;

  /// Ce qui ne concorde pas.
  final TypeIncoherenceLieu type;
}

/// Un changement d'heure a venir, par fuseau des familles et des enseignants.
@immutable
class ChangementHeureAVenir {
  /// Cree la ligne.
  const ChangementHeureAVenir({
    required this.fuseau,
    required this.transition,
    required this.decalageAvant,
    required this.decalageApres,
    required this.familles,
    required this.enseignants,
  });

  /// Lit une ligne de `changements_heure_a_venir_direction`, ou `null`.
  static ChangementHeureAVenir? lire(Object? brut) {
    if (brut is! Map) return null;
    final Object? fuseau = brut['fuseau'];
    final Object? quand = brut['transition_utc'];
    final Object? avant = brut['decalage_avant_secondes'];
    final Object? apres = brut['decalage_apres_secondes'];
    final Object? familles = brut['familles'];
    final Object? enseignants = brut['enseignants'];
    final DateTime? t = quand is String ? DateTime.tryParse(quand) : null;
    if (fuseau is! String ||
        t == null ||
        avant is! int ||
        apres is! int ||
        familles is! int ||
        enseignants is! int) {
      return null;
    }
    return ChangementHeureAVenir(
      fuseau: fuseau,
      transition: t.toUtc(),
      decalageAvant: Duration(seconds: avant),
      decalageApres: Duration(seconds: apres),
      familles: familles,
      enseignants: enseignants,
    );
  }

  /// Le fuseau IANA.
  final String fuseau;

  /// L'instant du changement (UTC).
  final DateTime transition;

  /// Le decalage avec UTC avant le changement.
  final Duration decalageAvant;

  /// Le decalage avec UTC apres le changement.
  final Duration decalageApres;

  /// Combien de familles vivent dans ce fuseau.
  final int familles;

  /// Combien d'enseignants vivent dans ce fuseau.
  final int enseignants;
}

/// « UTC+1 », « UTC+5:30 », « UTC-5 » : un decalage avec UTC.
String libelleDecalageUtc(Duration d) {
  final int minutes = d.inMinutes.abs();
  final String signe = d.isNegative ? '-' : '+';
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return m == 0 ? 'UTC$signe$h' : 'UTC$signe$h:${m.toString().padLeft(2, '0')}';
}

/// L'acces direction aux villes des enseignants.
abstract interface class PortLieuDirection {
  /// Les changements d'heure des [jours] prochains jours, par fuseau.
  Future<List<ChangementHeureAVenir>> changementsHeure({int jours = 60});

  /// Les villes des enseignants qui en ont choisi une.
  Future<List<LieuEnseignantDirection>> lieux();

  /// Les incoherences qui concernent un enseignant.
  Future<List<IncoherenceLieu>> incoherences();

  /// Marque la ville d'un enseignant comme verifiee.
  Future<void> verifier(String profilId);
}

/// Sans serveur (PLAYGROUND, test) : rien a montrer.
class LieuDirectionAbsent implements PortLieuDirection {
  /// Cree le port vide.
  const LieuDirectionAbsent();

  @override
  Future<List<ChangementHeureAVenir>> changementsHeure({
    int jours = 60,
  }) async => const <ChangementHeureAVenir>[];

  @override
  Future<List<LieuEnseignantDirection>> lieux() async =>
      const <LieuEnseignantDirection>[];

  @override
  Future<List<IncoherenceLieu>> incoherences() async =>
      const <IncoherenceLieu>[];

  @override
  Future<void> verifier(String profilId) async {}
}

/// L'adaptateur de `lieux_enseignants_direction`,
/// `incoherences_lieu_direction` et `verifier_lieu_enseignant`.
class LieuDirectionSupabase implements PortLieuDirection {
  /// Cree l'adaptateur.
  const LieuDirectionSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ChangementHeureAVenir>> changementsHeure({int jours = 60}) async {
    try {
      final Object? brut = await _client.rpc<Object?>(
        'changements_heure_a_venir_direction',
        params: <String, dynamic>{'p_jours': jours},
      );
      return <ChangementHeureAVenir>[
        if (brut is List<dynamic>)
          for (final dynamic l in brut) ?ChangementHeureAVenir.lire(l),
      ];
    } on PostgrestException catch (e) {
      if (_absente(e)) return const <ChangementHeureAVenir>[];
      rethrow;
    }
  }

  // PGRST202 et 42883 : fonction pas encore installee ; 42501 : pas la
  // direction. Dans les deux cas, rien a montrer, jamais une erreur de page.
  static bool _absente(PostgrestException e) =>
      e.code == 'PGRST202' || e.code == '42883' || e.code == '42501';

  @override
  Future<List<LieuEnseignantDirection>> lieux() async {
    try {
      final Object? brut = await _client.rpc<Object?>(
        'lieux_enseignants_direction',
      );
      return <LieuEnseignantDirection>[
        if (brut is List<dynamic>)
          for (final dynamic l in brut) ?LieuEnseignantDirection.lire(l),
      ];
    } on PostgrestException catch (e) {
      if (_absente(e)) return const <LieuEnseignantDirection>[];
      rethrow;
    }
  }

  @override
  Future<List<IncoherenceLieu>> incoherences() async {
    try {
      final Object? brut = await _client.rpc<Object?>(
        'incoherences_lieu_direction',
      );
      return <IncoherenceLieu>[
        if (brut is List<dynamic>)
          for (final dynamic l in brut) ?IncoherenceLieu.lireEnseignant(l),
      ];
    } on PostgrestException catch (e) {
      if (_absente(e)) return const <IncoherenceLieu>[];
      rethrow;
    }
  }

  @override
  Future<void> verifier(String profilId) async {
    await _client.rpc<Object?>(
      'verifier_lieu_enseignant',
      params: <String, dynamic>{'p_profil': profilId},
    );
  }
}

/// Le port employe par l'application.
final Provider<PortLieuDirection> portLieuDirectionProvider =
    Provider<PortLieuDirection>((Ref ref) {
      if (Env.playgroundActif) return const LieuDirectionAbsent();
      try {
        return LieuDirectionSupabase(Supabase.instance.client);
      } on Object {
        return const LieuDirectionAbsent();
      }
    });

/// Les villes des enseignants, par identifiant de profil.
final FutureProvider<Map<String, LieuEnseignantDirection>>
lieuxEnseignantsProvider = FutureProvider<Map<String, LieuEnseignantDirection>>(
  (Ref ref) async {
    final List<LieuEnseignantDirection> l = await ref
        .watch(portLieuDirectionProvider)
        .lieux();
    return <String, LieuEnseignantDirection>{
      for (final LieuEnseignantDirection x in l) x.profilId: x,
    };
  },
  retry: (int _, Object _) => null,
);

/// Les incoherences qui concernent un enseignant.
final FutureProvider<List<IncoherenceLieu>> incoherencesLieuProvider =
    FutureProvider<List<IncoherenceLieu>>(
      (Ref ref) => ref.watch(portLieuDirectionProvider).incoherences(),
      retry: (int _, Object _) => null,
    );

/// Le nombre de jours que l'ecran de la direction regarde en avant.
const int joursChangementsHeure = 60;

/// Les changements d'heure a venir des familles et des enseignants.
final FutureProvider<List<ChangementHeureAVenir>> changementsHeureProvider =
    FutureProvider<List<ChangementHeureAVenir>>(
      (Ref ref) => ref
          .watch(portLieuDirectionProvider)
          .changementsHeure(jours: joursChangementsHeure),
      retry: (int _, Object _) => null,
    );
