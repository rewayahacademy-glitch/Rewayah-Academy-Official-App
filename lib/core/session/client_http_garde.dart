import 'dart:async';

import 'package:http/http.dart' as http;

/// Le client HTTP de Supabase, qui reconnait une session finie cote serveur.
///
/// Production du 01/11/2026, 18:09 UTC : apres une session coupee (un autre
/// compte ouvert dans le meme navigateur), chaque requete recevait 401, et
/// l'application reessayait sans fin derriere « La connexion prend plus de
/// temps que prevu », sans aucune issue. Ce client lit les seules reponses
/// 401 de la base (`/rest/v1/`) : quand le serveur refuse le JETON (codes
/// PGRST301 a PGRST303, ou « JWT » expire ou invalide), il appelle
/// [surJetonRefuse] une fois par [intervalle], qui redemande un jeton puis,
/// a defaut, termine la session : l'application revient a « Se connecter ».
/// Rien d'autre n'est lu ni modifie ; toute autre reponse passe telle quelle.
class ClientHttpGarde extends http.BaseClient {
  /// Enveloppe [_interne].
  ClientHttpGarde(
    this._interne, {
    required this.surJetonRefuse,
    this.intervalle = const Duration(seconds: 20),
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now;

  final http.Client _interne;

  /// Appelee quand le serveur refuse le jeton.
  final Future<void> Function() surJetonRefuse;

  /// Au plus un appel a [surJetonRefuse] par intervalle.
  final Duration intervalle;

  final DateTime Function() _maintenant;
  DateTime? _dernier;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest requete) async {
    final http.StreamedResponse reponse = await _interne.send(requete);
    if (reponse.statusCode != 401 || !requete.url.path.contains('/rest/v1/')) {
      return reponse;
    }
    // Une 401 est courte : on la lit, puis on la rend intacte.
    final List<int> corps = await reponse.stream.toBytes();
    final String texte = String.fromCharCodes(corps).toLowerCase();
    if (estJetonRefuse(texte)) _signaler();
    return http.StreamedResponse(
      Stream<List<int>>.value(corps),
      reponse.statusCode,
      contentLength: corps.length,
      request: reponse.request,
      headers: reponse.headers,
      isRedirect: reponse.isRedirect,
      persistentConnection: reponse.persistentConnection,
      reasonPhrase: reponse.reasonPhrase,
    );
  }

  void _signaler() {
    final DateTime t = _maintenant();
    final DateTime? avant = _dernier;
    if (avant != null && t.difference(avant) < intervalle) return;
    _dernier = t;
    unawaited(surJetonRefuse());
  }

  @override
  void close() => _interne.close();
}

/// Vrai quand le corps d'une 401 de PostgREST dit que le JETON est refuse.
bool estJetonRefuse(String corpsEnMinuscules) =>
    corpsEnMinuscules.contains('pgrst301') ||
    corpsEnMinuscules.contains('pgrst302') ||
    corpsEnMinuscules.contains('pgrst303') ||
    (corpsEnMinuscules.contains('jwt') &&
        (corpsEnMinuscules.contains('expired') ||
            corpsEnMinuscules.contains('invalid')));
