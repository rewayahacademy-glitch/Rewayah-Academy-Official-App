import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';

/// Ce que l'ecran emetteur sait d'un code qu'il a affiche.
///
/// Le serveur ne signale jamais « un appareil est en train de saisir le
/// code » : il n'y a donc pas d'etat « en cours de saisie » ici, seulement ce
/// que la vue `mes_codes_appairage_v` permet d'observer (C05 section 4).
enum StatutCode {
  /// Le code est toujours valable et n'a pas servi.
  actif,

  /// Un appareil a consomme le code : l'association est faite.
  consomme,

  /// Le code a ete perime par une nouvelle demande (un autre ecran, un
  /// rechargement) : il ne marche plus.
  remplace,

  /// Le delai de validite est passe.
  expire,
}

/// Un code encore valable pour un eleve, tel que la vue l'expose.
///
/// **Jamais le code lui-meme** : la base n'en garde que l'empreinte. On sait
/// seulement qu'il existe et jusqu'a quand il vaut.
@immutable
class CodeVivant {
  /// Cree la description.
  const CodeVivant({required this.expireA});

  /// Le moment ou il cesse d'etre valable.
  final DateTime expireA;
}

/// La lecture du statut d'un code d'appairage (port du lot D).
///
/// Implementation de production : [StatutCodeAppairageSupabase], sur la vue
/// `mes_codes_appairage_v` (`0004_inscription_kyc_appairage.sql`, section 8).
/// Le droit `select` sur cette vue n'est accorde par aucune migration
/// explicite (DB-APP-02) : quand la lecture est refusee, les deux methodes
/// levent [CapaciteIndisponible] et l'ecran le dit, sans jamais supposer un
/// succes.
abstract interface class PortStatutCodeAppairage {
  /// Le code encore valable de [eleveId], s'il en existe un.
  Future<CodeVivant?> codeVivant(String eleveId);

  /// Le statut du code de [eleveId] qui expire a [expireA].
  ///
  /// La RPC de creation ne rend pas l'identifiant du code (DB-APP-02) : le
  /// couple (eleve, expiration) le designe.
  Future<StatutCode> statut({
    required String eleveId,
    required DateTime expireA,
    required DateTime maintenant,
  });
}

/// Une ligne de la vue, reduite a ce que l'ecran emploie.
@immutable
class LigneCodeAppairage {
  /// Cree une ligne.
  const LigneCodeAppairage({required this.expireA, this.consommeA});

  /// Lit une ligne de `mes_codes_appairage_v`.
  ///
  /// Rend `null` pour une ligne illisible : une date inventee ferait passer un
  /// code pour expire ou valable a tort.
  static LigneCodeAppairage? depuisJson(Map<String, dynamic> json) {
    final Object? expire = json['expires_at'];
    final DateTime? expireA = expire is String
        ? DateTime.tryParse(expire)
        : null;
    if (expireA == null) {
      return null;
    }
    final Object? consomme = json['consumed_at'];
    return LigneCodeAppairage(
      expireA: expireA,
      consommeA: consomme is String ? DateTime.tryParse(consomme) : null,
    );
  }

  /// Fin de validite.
  final DateTime expireA;

  /// Moment de la consommation, `null` tant que le code n'a pas servi.
  final DateTime? consommeA;
}

/// Le statut d'un code, deduit des lignes de la vue pour un eleve.
///
/// Pure, pour etre testee sans base : la ligne qui porte la meme expiration
/// que le code affiche est la sienne ; son absence veut dire que le code a
/// ete perime par une nouvelle demande (la vue filtre `deleted_at`).
StatutCode statutDepuisLignes({
  required List<LigneCodeAppairage> lignes,
  required DateTime expireA,
  required DateTime maintenant,
}) {
  LigneCodeAppairage? sienne;
  for (final LigneCodeAppairage ligne in lignes) {
    if (ligne.expireA.isAtSameMomentAs(expireA)) {
      sienne = ligne;
      break;
    }
  }
  if (sienne == null) {
    // Un code expire peut aussi avoir ete remplace : l'expiration l'emporte,
    // c'est ce que le tuteur constate de toute facon.
    return maintenant.isBefore(expireA)
        ? StatutCode.remplace
        : StatutCode.expire;
  }
  if (sienne.consommeA != null) {
    return StatutCode.consomme;
  }
  return maintenant.isBefore(expireA) ? StatutCode.actif : StatutCode.expire;
}

/// L'implementation reelle, sur la vue `mes_codes_appairage_v`.
///
/// Aucun tri demande a la base : l'ecran cherche une ligne par son
/// expiration, l'ordre des lignes n'a aucun effet.
class StatutCodeAppairageSupabase implements PortStatutCodeAppairage {
  /// Cree l'adaptateur. Le client n'est lu qu'a l'appel : un ecran monte
  /// sans Supabase initialise obtient un etat indisponible, pas un plantage.
  const StatutCodeAppairageSupabase(this._client);

  final SupabaseClient Function() _client;

  static const String _dependance = 'DB-APP-02';

  @override
  Future<CodeVivant?> codeVivant(String eleveId) async {
    final List<LigneCodeAppairage> lignes = await _lire(
      (SupabaseClient client) => client
          .from('mes_codes_appairage_v')
          .select('expires_at, consumed_at')
          .eq('student_profile_id', eleveId)
          .isFilter('consumed_at', null)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String()),
    );
    if (lignes.isEmpty) {
      return null;
    }
    return CodeVivant(expireA: lignes.first.expireA.toLocal());
  }

  @override
  Future<StatutCode> statut({
    required String eleveId,
    required DateTime expireA,
    required DateTime maintenant,
  }) async {
    final List<LigneCodeAppairage> lignes = await _lire(
      (SupabaseClient client) => client
          .from('mes_codes_appairage_v')
          .select('expires_at, consumed_at')
          .eq('student_profile_id', eleveId)
          .gte(
            'expires_at',
            expireA
                .subtract(const Duration(seconds: 1))
                .toUtc()
                .toIso8601String(),
          ),
    );
    return statutDepuisLignes(
      lignes: lignes,
      expireA: expireA,
      maintenant: maintenant,
    );
  }

  Future<List<LigneCodeAppairage>> _lire(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      SupabaseClient client,
    )
    requete,
  ) async {
    final SupabaseClient client;
    try {
      client = _client();
      // Supabase non initialise (tests, galerie) : rien a lire, et ce n'est
      // pas une panne a reessayer.
    } on Object {
      throw const CapaciteIndisponible(_dependance);
    }
    final List<Map<String, dynamic>> brutes;
    try {
      brutes = await requete(client);
    } on PostgrestException catch (e) {
      // 42501 : droit refuse. La vue n'a pas de `grant` explicite : c'est
      // exactement la dependance DB-APP-02, pas une panne passagere.
      if (e.code == '42501') {
        throw const CapaciteIndisponible(_dependance);
      }
      rethrow;
    }
    return <LigneCodeAppairage>[
      for (final Map<String, dynamic> brute in brutes)
        ?LigneCodeAppairage.depuisJson(brute),
    ];
  }
}

/// Le port employe par l'application.
final Provider<PortStatutCodeAppairage> portStatutCodeAppairageProvider =
    Provider<PortStatutCodeAppairage>(
      (Ref ref) => StatutCodeAppairageSupabase(() => Supabase.instance.client),
    );
