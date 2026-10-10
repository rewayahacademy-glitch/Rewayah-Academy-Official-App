// MA-TUTOIEMENT-1 (decision A4 = a) : le registre suit l'age de l'eleve
// devant l'ecran, jamais la presentation (MA1, deux axes). Un mineur est
// tutoye ; un adulte, ou un age que l'application ne connait pas, est
// vouvoye.
//
// L'age reel vient du serveur a BR-1. D'ici la, le port est neutre (K-09) :
// il dit « inconnu », sans aucun appel (K-28). La demonstration connait
// l'age de ses eleves et le passe directement aux ecrans.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// L'age de l'eleve, tel que l'application le connait.
enum AgeEleve {
  /// Eleve mineur : tutoye.
  mineur,

  /// Eleve adulte : vouvoye.
  adulte,

  /// Age non connu (avant BR-1) : vouvoye par defaut.
  inconnu;

  /// Vrai seulement pour un mineur connu.
  bool get tutoiement => this == AgeEleve.mineur;
}

/// Lit l'age de l'eleve connecte.
abstract interface class PortAgeEleve {
  /// L'age de l'eleve connecte.
  AgeEleve ageDeLEleve();
}

/// Lit la tranche signée par le hook Supabase. Le claim sert uniquement à
/// l'interface/tutoiement; les permissions restent décidées côté serveur.
class AgeEleveSupabase implements PortAgeEleve {
  const AgeEleveSupabase(this._client);

  final SupabaseClient _client;

  @override
  AgeEleve ageDeLEleve() {
    final String? token = _client.auth.currentSession?.accessToken;
    if (token == null) return AgeEleve.inconnu;
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return AgeEleve.inconnu;
      final String payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return AgeEleve.inconnu;
      return switch (decoded['tranche_age']) {
        'enfant' => AgeEleve.mineur,
        'adulte' => AgeEleve.adulte,
        _ => AgeEleve.inconnu,
      };
    } on FormatException {
      return AgeEleve.inconnu;
    } on TypeError {
      return AgeEleve.inconnu;
    }
  }
}

/// Le port neutre (K-09) : l'age n'est pas connu avant BR-1.
class AgeEleveInconnu implements PortAgeEleve {
  /// Cree le port neutre.
  const AgeEleveInconnu();

  @override
  AgeEleve ageDeLEleve() => AgeEleve.inconnu;
}

/// Le port employe par l'application : neutre tant que BR-1 ne l'a pas
/// cable.
final Provider<PortAgeEleve> portAgeEleveProvider = Provider<PortAgeEleve>(
  (Ref ref) => AgeEleveSupabase(Supabase.instance.client),
);
