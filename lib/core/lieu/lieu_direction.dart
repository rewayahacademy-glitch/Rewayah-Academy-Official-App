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

/// L'acces direction aux villes des enseignants.
abstract interface class PortLieuDirection {
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
