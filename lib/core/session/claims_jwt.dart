import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Lecture des revendications injectees dans le jeton d'acces.
///
/// Le hook `public.custom_access_token_hook` de la migration 0001 pose
/// `app_metadata.role` et `app_metadata.household_id` dans le JWT. C'est la
/// meme source que celle que lisent les policies RLS par `auth.jwt()`, donc la
/// seule source correcte cote client : `User.appMetadata` de gotrue reflete
/// l'enregistrement du serveur d'authentification, pas les claims du hook.
///
/// **Aucune verification de signature ici, et c'est voulu.** Un client ne peut
/// pas se prouver quoi que ce soit a lui-meme : la signature est verifiee par
/// PostgREST a chaque requete. Ce que l'on lit ici ne sert qu'a orienter la
/// navigation, jamais a autoriser un acces. La barriere reste la RLS.
@immutable
class ClaimsJwt {
  const ClaimsJwt._({this.role, this.householdId, this.sujet});

  /// Aucune revendication : jeton absent ou illisible.
  const ClaimsJwt.vide() : this._();

  /// Le role, tel qu'ecrit par le hook.
  final String? role;

  /// L'identifiant du foyer, tel qu'ecrit par le hook.
  final String? householdId;

  /// Le `sub` du jeton, c'est-a-dire l'identite sous laquelle la base repondra.
  ///
  /// Pour une session humaine, c'est le compte connecte, et `Session.user.id`
  /// dit la meme chose. Pour une session d'observation (ADR-025), c'est **la
  /// personne observee** : il n'y a alors aucun `Session` gotrue d'ou le tirer,
  /// et c'est le seul endroit ou cette identite se lit.
  final String? sujet;

  /// Decode la charge utile d'un jeton d'acces.
  ///
  /// Retourne [ClaimsJwt.vide] sur tout jeton mal forme : un jeton illisible
  /// ne doit pas faire tomber l'application, il doit simplement ne rien
  /// accorder.
  factory ClaimsJwt.depuisJeton(String? jetonAcces) {
    if (jetonAcces == null || jetonAcces.isEmpty) {
      return const ClaimsJwt.vide();
    }

    final List<String> segments = jetonAcces.split('.');
    if (segments.length != 3) {
      return const ClaimsJwt.vide();
    }

    try {
      final String charge = utf8.decode(
        base64Url.decode(base64Url.normalize(segments[1])),
      );
      final Object? decode = jsonDecode(charge);
      if (decode is! Map<String, dynamic>) {
        return const ClaimsJwt.vide();
      }

      final Object? metadonnees = decode['app_metadata'];
      if (metadonnees is! Map<String, dynamic>) {
        return const ClaimsJwt.vide();
      }

      return ClaimsJwt._(
        role: metadonnees['role'] as String?,
        householdId: metadonnees['household_id'] as String?,
        sujet: decode['sub'] as String?,
      );
    } on FormatException {
      return const ClaimsJwt.vide();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ClaimsJwt &&
      other.role == role &&
      other.householdId == householdId &&
      other.sujet == sujet;

  @override
  int get hashCode => Object.hash(role, householdId, sujet);
}
