// PX-BD-0 : les LOTS que Praxis prepare en mode chat et que la direction
// confirme en lui disant un code (`direction_praxis_confirmations`,
// `direction_praxis_confirmation_annuler`).
//
// Le code est la preuve du « oui » : le serveur ne le rend qu'a une direction
// connectee en double verification, jamais a Praxis. Cet ecran est le SEUL
// endroit ou il se lit. Une lecture qui echoue ne rend jamais « aucun lot »
// (une erreur reste une erreur).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un lot prepare, en attente de son code.
@immutable
class LotPraxis {
  /// Cree le lot.
  const LotPraxis({
    required this.id,
    required this.acte,
    required this.nb,
    required this.resume,
    required this.code,
    required this.expireLe,
  });

  /// Lit une ligne rendue par le serveur, ou `null` quand elle est illisible.
  /// Un code qui n'a pas six chiffres rend `null` : on ne montre jamais un
  /// code douteux.
  static LotPraxis? depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return null;
    final Object? id = brut['id'];
    final Object? acte = brut['acte'];
    final Object? code = brut['code'];
    final DateTime? expire = brut['expireLe'] is String
        ? DateTime.tryParse(brut['expireLe'] as String)?.toUtc()
        : null;
    if (id is! String ||
        acte is! String ||
        code is! String ||
        !RegExp(r'^[0-9]{6}$').hasMatch(code) ||
        expire == null) {
      return null;
    }
    return LotPraxis(
      id: id,
      acte: acte,
      nb: (brut['nb'] as num?)?.toInt() ?? 0,
      resume: <String>[
        if (brut['resume'] is List)
          for (final Object? l in brut['resume'] as List)
            if (l is String) l,
      ],
      code: code,
      expireLe: expire,
    );
  }

  /// L'identifiant du lot.
  final String id;

  /// Le nom technique de l'acte (jamais montre tel quel a la direction).
  final String acte;

  /// Le nombre de lignes du lot.
  final int nb;

  /// Le resume en clair de chaque ligne, ecrit par l'adaptateur de l'acte.
  final List<String> resume;

  /// Le code a six chiffres a dire a Praxis.
  final String code;

  /// Quand le lot expire (cinq minutes apres sa preparation).
  final DateTime expireLe;

  /// Le code en deux groupes de trois chiffres, pour se lire a voix haute.
  String get codeLisible => '${code.substring(0, 3)} ${code.substring(3)}';
}

/// L'acces de la direction aux lots a confirmer.
abstract interface class ServiceLotsPraxis {
  /// Les lots en attente de la direction qui a emis la cle. Marque leur code
  /// « affiche » cote serveur : la double verification est exigee par la base.
  Future<List<LotPraxis>> enAttente();

  /// Annule un lot (double verification exigee par la base). Rend faux s'il
  /// n'y avait rien a annuler.
  Future<bool> annuler(String id);
}

/// L'implementation Supabase.
class ServiceLotsPraxisSupabase implements ServiceLotsPraxis {
  /// Cree le service.
  ServiceLotsPraxisSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<LotPraxis>> enAttente() async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_confirmations',
    );
    if (rendu is! List) {
      throw StateError('lots illisibles');
    }
    return <LotPraxis>[for (final Object? l in rendu) ?LotPraxis.depuisJson(l)];
  }

  @override
  Future<bool> annuler(String id) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_confirmation_annuler',
      params: <String, dynamic>{'p_id': id},
    );
    return rendu is Map<String, dynamic> && rendu['annule'] == true;
  }
}

/// Le service des lots.
final Provider<ServiceLotsPraxis> serviceLotsPraxisProvider =
    Provider<ServiceLotsPraxis>(
      (Ref ref) => ServiceLotsPraxisSupabase(Supabase.instance.client),
    );
