import 'dart:js_interop';

@JS('localStorage')
external _Stockage get _stockage;

/// `window.localStorage`, reduit aux trois appels utiles.
extension type _Stockage._(JSObject _) implements JSObject {
  external String? getItem(String clef);
  external void setItem(String clef, String valeur);
  external void removeItem(String clef);
}

/// Lit [clef], ou `null` (stockage refuse par le navigateur compris).
String? lireMemoireAppareil(String clef) {
  try {
    return _stockage.getItem(clef);
  } on Object {
    return null;
  }
}

/// Ecrit [valeur] sous [clef] ; un stockage plein ou refuse ne casse rien.
void ecrireMemoireAppareil(String clef, String valeur) {
  try {
    _stockage.setItem(clef, valeur);
  } on Object {
    return;
  }
}

/// Efface [clef].
void effacerMemoireAppareil(String clef) {
  try {
    _stockage.removeItem(clef);
  } on Object {
    return;
  }
}
