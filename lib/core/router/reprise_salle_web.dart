import 'dart:js_interop';

/// `window.sessionStorage` : propre a l'onglet, efface a sa fermeture,
/// jamais partage avec un autre onglet (ADR-005 tenu).
@JS('sessionStorage')
external _Stockage? get _stockage;

extension type _Stockage._(JSObject _) implements JSObject {
  external String? getItem(String cle);
  external void setItem(String cle, String valeur);
  external void removeItem(String cle);
}

/// Lit la valeur gardee pour [cle] dans l'onglet, ou `null`.
String? lireDansOnglet(String cle) {
  try {
    return _stockage?.getItem(cle);
  } catch (_) {
    return null;
  }
}

/// Garde [valeur] pour [cle] dans l'onglet ; `null` l'efface.
void ecrireDansOnglet(String cle, String? valeur) {
  try {
    final _Stockage? stockage = _stockage;
    if (stockage == null) return;
    if (valeur == null) {
      stockage.removeItem(cle);
    } else {
      stockage.setItem(cle, valeur);
    }
  } catch (_) {
    // Navigation privee, stockage bloque : la reprise n'a simplement pas
    // lieu, l'accueil propose « Rejoindre ».
  }
}
