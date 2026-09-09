import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que l'application sait faire de l'authentification.
///
/// Une interface plutot qu'un appel direct a Supabase, pour la meme raison que
/// [SourceSession] : les ecrans et leurs tests doivent tourner sans reseau.
///
/// **Aucun mot de passe.** Ni ici, ni ailleurs dans le produit : un lien recu
/// par courriel, ou Google. Un mot de passe qu'on ne demande jamais est un mot
/// de passe qu'on ne peut ni perdre, ni voler, ni reutiliser ailleurs.
abstract interface class ServiceAuth {
  /// Envoie un lien de connexion a usage unique.
  Future<void> envoyerLienCourriel(String courriel);

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

  @override
  Future<void> envoyerLienCourriel(String courriel) =>
      _client.auth.signInWithOtp(email: courriel.trim());

  @override
  Future<void> connexionGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google);

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
