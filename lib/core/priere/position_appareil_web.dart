import 'dart:async';
import 'dart:js_interop';

import 'position_appareil_modele.dart';

export 'position_appareil_modele.dart';

@JS('navigator.geolocation')
external _Geolocalisation? get _geolocalisation;

/// `navigator.geolocation`, reduit au seul appel utile.
extension type _Geolocalisation._(JSObject _) implements JSObject {
  external void getCurrentPosition(
    JSFunction succes,
    JSFunction echec,
    JSObject options,
  );
}

/// La position rendue par le navigateur.
extension type _Position._(JSObject _) implements JSObject {
  external _Coordonnees get coords;
}

/// Ses coordonnees.
extension type _Coordonnees._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
}

@JS('Intl.DateTimeFormat')
external _Format _creerFormat();

/// `Intl.DateTimeFormat()`, reduit a son fuseau.
extension type _Format._(JSObject _) implements JSObject {
  external _Options resolvedOptions();
}

/// Les options resolues du format.
extension type _Options._(JSObject _) implements JSObject {
  external String get timeZone;
}

/// Lit la position de l'appareil (une demande d'autorisation au navigateur) et
/// son fuseau IANA. Toute impossibilite (refus, delai, pas de geolocalisation)
/// devient [PositionNonPartagee].
Future<PositionAppareil> lirePositionAppareil() {
  final _Geolocalisation? geo = _geolocalisation;
  if (geo == null) {
    return Future<PositionAppareil>.error(const PositionNonPartagee());
  }
  final Completer<PositionAppareil> fin = Completer<PositionAppareil>();
  try {
    geo.getCurrentPosition(
      ((JSObject brute) {
        try {
          final _Position p = brute as _Position;
          final String fuseau = _creerFormat().resolvedOptions().timeZone;
          if (!fin.isCompleted) {
            fin.complete(
              PositionAppareil(
                latitude: p.coords.latitude,
                longitude: p.coords.longitude,
                fuseau: fuseau,
              ),
            );
          }
        } on Object {
          if (!fin.isCompleted) fin.completeError(const PositionNonPartagee());
        }
      }).toJS,
      ((JSObject _) {
        if (!fin.isCompleted) fin.completeError(const PositionNonPartagee());
      }).toJS,
      <String, Object>{
        'enableHighAccuracy': false,
        'timeout': 15000,
        'maximumAge': 600000,
      }.jsify()! as JSObject,
    );
  } on Object {
    if (!fin.isCompleted) fin.completeError(const PositionNonPartagee());
  }
  return fin.future;
}
