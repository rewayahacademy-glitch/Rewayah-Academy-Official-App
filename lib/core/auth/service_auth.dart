import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que l'application sait faire de l'authentification.
///
/// Une interface plutot qu'un appel direct a Supabase, pour la meme raison que
/// [SourceSession] : les ecrans et leurs tests doivent tourner sans reseau.
///
/// En production, le parcours reste limite au lien a usage unique et a Google.
/// Une compilation locale peut activer le parcours courriel/mot de passe via
/// `DEMO_AUTH`; la validation du compte et des droits reste cote Supabase.
abstract interface class ServiceAuth {
  /// Envoie un lien de connexion a usage unique.
  Future<void> envoyerLienCourriel(String courriel);

  /// Ouvre une session avec un courriel et un mot de passe.
  ///
  /// Ce chemin est reserve a la demonstration locale et reste masque quand
  /// `DEMO_AUTH` n'est pas active. La validation du compte et des droits reste
  /// entierement cote Supabase.
  Future<void> connexionMotDePasse(String courriel, String motDePasse);

  /// Ouvre le parcours Google.
  Future<void> connexionGoogle();

  /// Ferme la session.
  Future<void> deconnexion();
}

/// L'implementation reelle.
class ServiceAuthSupabase implements ServiceAuth {
  /// Cree le service a partir d'un client Supabase.
  const ServiceAuthSupabase(this._client);

  final SupabaseClient _client;

  /// L'adresse ou le fournisseur doit ramener l'usager.
  ///
  /// **Sur le web, c'est l'origine servie, pas le reglage du serveur.** Sans
  /// elle, Supabase retombe sur son propre « Site URL » : une valeur reglee une
  /// fois dans un tableau de bord, invisible depuis le depot, et qui renvoie
  /// tout le monde au meme endroit quel que soit le domaine d'ou l'on est
  /// parti -- une preproduction comprise. Sur mobile, il n'y a pas d'origine :
  /// le schema d'application reste celui que le paquet declare, donc `null`.
  String? get _retour => kIsWeb ? Uri.base.origin : null;

  @override
  Future<void> envoyerLienCourriel(String courriel) => _client.auth
      .signInWithOtp(email: courriel.trim(), emailRedirectTo: _retour);

  @override
  Future<void> connexionMotDePasse(String courriel, String motDePasse) async {
    await _client.auth.signInWithPassword(
      email: courriel.trim(),
      password: motDePasse,
    );
  }

  @override
  Future<void> connexionGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: _retour);

  @override
  Future<void> deconnexion() => _client.auth.signOut();
}

/// Le service d'authentification employe par l'application.
final Provider<ServiceAuth> serviceAuthProvider = Provider<ServiceAuth>(
  (Ref ref) => ServiceAuthSupabase(Supabase.instance.client),
);

/// Une adresse electronique plausible.
///
/// Volontairement permissif : une expression trop stricte refuse des adresses
/// valides, et le seul verdict qui compte est celui du serveur de courriel, qui
/// repondra en envoyant le lien ou en ne l'envoyant pas.
bool courrielPlausible(String valeur) {
  final String v = valeur.trim();
  if (v.length < 5 || v.contains(' ')) {
    return false;
  }
  final int arobase = v.indexOf('@');
  if (arobase <= 0 || arobase != v.lastIndexOf('@')) {
    return false;
  }
  final String domaine = v.substring(arobase + 1);
  return domaine.contains('.') &&
      !domaine.startsWith('.') &&
      !domaine.endsWith('.');
}
