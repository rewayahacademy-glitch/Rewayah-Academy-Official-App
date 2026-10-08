import 'dart:js_interop';

import '../observabilite/journal_dev.dart';
import 'preferences_locales.dart';

@JS('localStorage')
external _StockageWeb? get _stockageWeb;

/// Le `localStorage` du navigateur, reduit aux deux appels utiles.
extension type _StockageWeb._(JSObject _) implements JSObject {
  external String? getItem(String clef);
  external void setItem(String clef, String valeur);
}

/// Le `localStorage` du navigateur : durable pour cet appareil et ce site,
/// **non sensible** (jamais un jeton ni un code, qui passent par le coffre
/// securise).
///
/// Une navigation privee ou des donnees de site bloquees peuvent lever une
/// exception a chaque acces : la valeur reste alors en memoire pour la
/// session, et l'ecran se comporte comme a la premiere visite.
class StockagePreferencesNavigateur implements StockagePreferences {
  /// Cree le stockage.
  StockagePreferencesNavigateur();

  final Map<String, String> _secours = <String, String>{};

  @override
  Future<String?> lire(String clef) async {
    try {
      return _stockageWeb?.getItem(clef) ?? _secours[clef];
    } on Object catch (erreur) {
      journalDev('Stockage du navigateur illisible : $erreur');
      return _secours[clef];
    }
  }

  @override
  Future<void> ecrire(String clef, String valeur) async {
    _secours[clef] = valeur;
    try {
      _stockageWeb?.setItem(clef, valeur);
    } on Object catch (erreur) {
      journalDev('Stockage du navigateur non ecrit : $erreur');
    }
  }
}
