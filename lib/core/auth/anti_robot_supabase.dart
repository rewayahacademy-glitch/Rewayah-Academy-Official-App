// ANTI-ROBOT (03/11/2026) : la cle PUBLIQUE du widget Turnstile, lue sans
// compte par `public.turnstile_cle_site()` (migration 20261109000000).

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'anti_robot.dart';

/// La cle publique servie par Supabase.
///
/// PE-A5 (20/11/2026) : le client Supabase n'envoie AUCUNE requete quand la
/// session gardee dans le navigateur est expiree et ne se renouvelle pas
/// (`SupabaseClient._getAccessToken`, supabase 2.16.1 : « aborting api
/// request ») ; c'est le cas d'une personne deconnectee par le serveur qui
/// arrive sur la connexion. La lecture echouait donc sans meme partir, la cle
/// valait « aucun controle » et le lien partait sans jeton (refuse). La cle
/// etant publique et la fonction ouverte a `anon`, elle se relit alors sans
/// session, avec la seule cle publique du projet.
class CleTurnstileSupabase implements PortCleTurnstile {
  /// Cree l'adaptateur ; [clientHttp], [url] et [clePublique] servent aux
  /// tests (par defaut : un client neuf, la configuration compilee).
  CleTurnstileSupabase(
    this._client, {
    http.Client? clientHttp,
    String? url,
    String? clePublique,
  }) : _http = clientHttp,
       _url = url ?? Env.supabaseUrl,
       _clePublique = clePublique ?? Env.supabaseAnonKey;

  final SupabaseClient _client;
  final http.Client? _http;
  final String _url;
  final String _clePublique;

  @override
  Future<String?> lire() async {
    try {
      final Object? brut = await _client.rpc<Object?>('turnstile_cle_site');
      return brut is String ? brut : null;
    } on Object {
      return _lireSansSession();
    }
  }

  /// La meme fonction, appelee sans jeton de session : seule la cle publique
  /// du projet (`apikey`) accompagne la demande.
  Future<String?> _lireSansSession() async {
    final http.Client client = _http ?? http.Client();
    try {
      final http.Response reponse = await client.post(
        Uri.parse('$_url/rest/v1/rpc/turnstile_cle_site'),
        headers: <String, String>{
          'apikey': _clePublique,
          'Content-Type': 'application/json',
        },
        body: '{}',
      );
      if (reponse.statusCode != 200) {
        throw StateError('turnstile_cle_site : ${reponse.statusCode}');
      }
      final Object? brut = jsonDecode(reponse.body);
      return brut is String ? brut : null;
    } finally {
      if (_http == null) client.close();
    }
  }
}
