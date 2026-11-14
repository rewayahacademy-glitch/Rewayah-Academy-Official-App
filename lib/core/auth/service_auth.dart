import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../observabilite/journal_dev.dart';

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
  ///
  /// [jetonControle] : le jeton du controle anti-robot (Turnstile, lot
  /// ANTI-ROBOT du 03/11/2026), passe a Supabase comme `captchaToken` ; nul
  /// quand aucun controle n'est pose (reglage vide).
  Future<void> envoyerLienCourriel(String courriel, {String? jetonControle});

  /// Ouvre une session avec le code a 6 chiffres du courriel de connexion.
  ///
  /// ONBOARDING-BOUCLE (directeur, 14/11/2026) : le lien du courriel s'ouvre
  /// souvent dans un autre navigateur que celui ou la connexion a ete demandee
  /// (appli de messagerie) ; le flux PKCE y echoue (`flow_state_not_found`) et
  /// les reponses du questionnaire, gardees dans l'appareil, n'y sont pas. Le
  /// code se saisit dans le meme navigateur : aucune etape ne passe par un
  /// autre. Jette une `AuthException` si le code est faux ou expire.
  Future<void> verifierCodeCourriel(String courriel, String code);

  /// Ouvre une session avec un courriel et un mot de passe.
  ///
  /// Ce chemin est reserve a la demonstration locale et reste masque quand
  /// `DEMO_AUTH` n'est pas active. La validation du compte et des droits reste
  /// entierement cote Supabase.
  Future<void> connexionMotDePasse(
    String courriel,
    String motDePasse, {
    String? jetonControle,
  });

  /// Ouvre le parcours Google.
  Future<void> connexionGoogle();

  /// Ferme la session **locale** et rend la main aussitot ; le serveur est
  /// prevenu ensuite, au mieux, sans que l'appel ne l'attende (fiche du
  /// 27/10/2026, ligne 16 : sortie en moins de 2 secondes, meme sans reseau).
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
  Future<void> envoyerLienCourriel(String courriel, {String? jetonControle}) =>
      _client.auth.signInWithOtp(
        email: courriel.trim(),
        emailRedirectTo: _retour,
        captchaToken: jetonControle,
      );

  @override
  Future<void> verifierCodeCourriel(String courriel, String code) async {
    await _client.auth.verifyOTP(
      email: courriel.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
  }

  @override
  Future<void> connexionMotDePasse(
    String courriel,
    String motDePasse, {
    String? jetonControle,
  }) async {
    await _client.auth.signInWithPassword(
      email: courriel.trim(),
      password: motDePasse,
      captchaToken: jetonControle,
    );
  }

  @override
  Future<void> connexionGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: _retour);

  @override
  Future<void> deconnexion() async {
    // Locale d'abord : gotrue retire la session et previent ses abonnes
    // (`signedOut`) AVANT son appel au serveur (`_signOut`, portee locale).
    // L'appel n'est pas attendu : un reseau coupe ou lent ne retient jamais
    // la sortie, et le serveur ne revoque que la session de cet appareil.
    final Future<void> serveur = _client.auth.signOut(
      scope: SignOutScope.local,
    );
    unawaited(
      serveur.then<void>(
        (_) {},
        onError: (Object erreur) => journalDev(
          'Deconnexion : serveur non prevenu (${erreur.runtimeType}).',
        ),
      ),
    );
  }
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
