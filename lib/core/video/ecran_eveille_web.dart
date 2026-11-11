import 'dart:async';
import 'dart:js_interop';

import 'ecran_eveille.dart';

/// `navigator.wakeLock`, absent des navigateurs qui ne connaissent pas l'API.
@JS('navigator.wakeLock')
external _WakeLock? get _wakeLock;

@JS('document')
external _Document get _document;

extension type _WakeLock._(JSObject _) implements JSObject {
  external JSPromise<_Sentinelle> request(String type);
}

extension type _Sentinelle._(JSObject _) implements JSObject {
  external bool get released;
  external JSPromise<JSAny?> release();
}

extension type _Document._(JSObject _) implements JSObject {
  external String get visibilityState;
  external void addEventListener(String type, JSFunction ecouteur);
  external void removeEventListener(String type, JSFunction ecouteur);
}

/// Dans un navigateur : l'API Screen Wake Lock et `visibilitychange`.
VerrouEcranNavigateur? verrouEcranDeLaPlateforme() => _VerrouWeb();

class _VerrouWeb implements VerrouEcranNavigateur {
  late final StreamController<void> _visibilite =
      StreamController<void>.broadcast(
        onListen: () =>
            _document.addEventListener('visibilitychange', _ecouteur),
        onCancel: () =>
            _document.removeEventListener('visibilitychange', _ecouteur),
      );

  late final JSFunction _ecouteur = ((JSAny? _) {
    if (!_visibilite.isClosed) _visibilite.add(null);
  }).toJS;

  @override
  bool get disponible {
    try {
      return _wakeLock != null;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get visible => _document.visibilityState == 'visible';

  @override
  Stream<void> get changementsDeVisibilite => _visibilite.stream;

  @override
  Future<Object> demander() async {
    final _WakeLock? api = _wakeLock;
    if (api == null) {
      throw StateError('Screen Wake Lock absente');
    }
    final _Sentinelle sentinelle = await api.request('screen').toDart;
    return _Jeton(sentinelle);
  }

  @override
  bool estRelache(Object verrou) => (verrou as _Jeton).sentinelle.released;

  @override
  Future<void> relacher(Object verrou) async {
    await (verrou as _Jeton).sentinelle.release().toDart;
  }
}

/// Le verrou tenu, enveloppe dans un objet Dart : un `Object` ne se convertit
/// pas sans risque en type d'interoperabilite JavaScript.
class _Jeton {
  const _Jeton(this.sentinelle);

  final _Sentinelle sentinelle;
}
