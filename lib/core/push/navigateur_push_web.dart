import 'dart:convert';
import 'dart:js_interop';

import 'port_push.dart';

@JS('rewayahPush')
external _PontPush? get _pont;

/// `window.rewayahPush` (`web/push_client.js`).
extension type _PontPush._(JSObject _) implements JSObject {
  external JSPromise<JSString> etat();
  external JSPromise<JSString> adresse();
  external JSPromise<JSString> activer(JSString cle);
  external JSPromise<JSString> desactiver();
  external JSPromise<JSString> besoinGeste();
  external JSString appareil();
}

/// Le Web Push du navigateur, par `web/push_client.js`. Sans ce fichier (page
/// servie sans lui), le navigateur est traite comme sans push.
class NavigateurPushSysteme implements NavigateurPush {
  /// Cree le navigateur.
  const NavigateurPushSysteme();

  @override
  Future<EtatAppareilPush> etat() async {
    final _PontPush? p = _pont;
    if (p == null) return EtatAppareilPush.nonPrisEnCharge;
    return switch ((await p.etat().toDart).toDart) {
      'ios_ecran_accueil' => EtatAppareilPush.iosEcranAccueil,
      'refuse' => EtatAppareilPush.refuse,
      'inactif' => EtatAppareilPush.inactif,
      'actif' => EtatAppareilPush.actif,
      _ => EtatAppareilPush.nonPrisEnCharge,
    };
  }

  @override
  Future<String?> adresse() async {
    final _PontPush? p = _pont;
    if (p == null) return null;
    final String a = (await p.adresse().toDart).toDart;
    return a.isEmpty ? null : a;
  }

  @override
  Future<AbonnementNavigateur> activer(String clePublique) async {
    final _PontPush? p = _pont;
    if (p == null) {
      throw const ActivationRefusee(RefusActivation.nonPrisEnCharge);
    }
    // Premier appel, sans attente avant : la demande suit le geste.
    final String brut = (await p.activer(clePublique.toJS).toDart).toDart;
    final Object? j = jsonDecode(brut);
    if (j is Map<String, dynamic>) {
      final Object? endpoint = j['endpoint'];
      final Object? p256dh = j['p256dh'];
      final Object? auth = j['auth'];
      if (endpoint is String && p256dh is String && auth is String) {
        return AbonnementNavigateur(
          endpoint: endpoint,
          p256dh: p256dh,
          auth: auth,
        );
      }
      throw ActivationRefusee(switch (j['erreur']) {
        'refuse' => RefusActivation.refuse,
        'ignore' => RefusActivation.ignore,
        'non_pris_en_charge' => RefusActivation.nonPrisEnCharge,
        _ => RefusActivation.echec,
      });
    }
    throw const ActivationRefusee(RefusActivation.echec);
  }

  @override
  Future<String?> desactiver() async {
    final _PontPush? p = _pont;
    if (p == null) return null;
    final String a = (await p.desactiver().toDart).toDart;
    return a.isEmpty ? null : a;
  }

  @override
  Future<bool> besoinGeste() async {
    final _PontPush? p = _pont;
    if (p == null) return true;
    return (await p.besoinGeste().toDart).toDart == 'oui';
  }

  @override
  String get appareil => _pont?.appareil().toDart ?? 'Navigateur';
}
