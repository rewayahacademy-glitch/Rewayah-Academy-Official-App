// L'adaptateur Supabase des vignettes (BIBLIOTHEQUE-UNE).
//
// Une carte demande l'URL de sa vignette ; les cartes d'un meme ecran sont
// construites dans la meme image, donc leurs demandes sont REGROUPEES en un
// seul appel a la fonction Edge `bibliotheque-lecture` (action `vignettes`,
// 100 documents au plus). Le serveur ne signe que ce que l'appelant lit. Une
// URL est gardee en memoire moins longtemps qu'elle ne vit (300 s au serveur) ;
// aucune cle de stockage ne transite.

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'vignettes_ressource.dart';

/// Les vignettes lues au serveur.
class VignettesSupabase implements PortVignettes {
  /// Cree l'adaptateur. [maintenant] se remplace dans les tests.
  VignettesSupabase(this._client, {int Function()? maintenant})
    : _maintenant =
          maintenant ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SupabaseClient _client;
  final int Function() _maintenant;

  /// Un lot d'au plus ce nombre de documents (la borne du serveur).
  static const int lotMax = 100;

  /// L'URL vit 300 s au serveur : on la garde 240 s (en millisecondes).
  static const int dureeGardeeMs = 240000;

  final Map<String, ({Uri url, int jusqua})> _gardees =
      <String, ({Uri url, int jusqua})>{};
  final Map<String, Completer<Uri?>> _attente = <String, Completer<Uri?>>{};
  bool _planifie = false;

  @override
  Future<Uri?> urlDe(String resourceId) {
    final ({Uri url, int jusqua})? gardee = _gardees[resourceId];
    if (gardee != null && gardee.jusqua > _maintenant()) {
      return Future<Uri?>.value(gardee.url);
    }
    final Completer<Uri?>? deja = _attente[resourceId];
    if (deja != null) return deja.future;
    final Completer<Uri?> c = Completer<Uri?>();
    _attente[resourceId] = c;
    if (!_planifie) {
      _planifie = true;
      scheduleMicrotask(_envoyer);
    }
    return c.future;
  }

  Future<void> _envoyer() async {
    _planifie = false;
    final List<String> ids = _attente.keys.take(lotMax).toList();
    final Map<String, Completer<Uri?>> lot = <String, Completer<Uri?>>{
      for (final String id in ids) id: _attente.remove(id)!,
    };
    if (_attente.isNotEmpty) {
      _planifie = true;
      scheduleMicrotask(_envoyer);
    }
    Map<String, Uri> urls = const <String, Uri>{};
    try {
      final FunctionResponse reponse = await _client.functions.invoke(
        'bibliotheque-lecture',
        body: <String, Object?>{'action': 'vignettes', 'ids': ids},
      );
      urls = lireUrls(reponse.data);
    } on Object {
      // Une vignette qui ne vient pas est une vignette absente : la couverture
      // par defaut reste, la liste ne tombe pas.
    }
    final int jusqua = _maintenant() + dureeGardeeMs;
    for (final MapEntry<String, Completer<Uri?>> e in lot.entries) {
      final Uri? url = urls[e.key];
      if (url != null) _gardees[e.key] = (url: url, jusqua: jusqua);
      e.value.complete(url);
    }
  }

  /// Les URL d'une reponse `{urls: {id: url}}`. N'accepte que de l'https.
  static Map<String, Uri> lireUrls(Object? brut) {
    if (brut is! Map) return const <String, Uri>{};
    final Object? urls = brut['urls'];
    if (urls is! Map) return const <String, Uri>{};
    final Map<String, Uri> sortie = <String, Uri>{};
    for (final MapEntry<Object?, Object?> e in urls.entries) {
      final Object? cle = e.key;
      final Object? valeur = e.value;
      if (cle is! String || valeur is! String) continue;
      final Uri? uri = Uri.tryParse(valeur);
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
        sortie[cle] = uri;
      }
    }
    return sortie;
  }
}
