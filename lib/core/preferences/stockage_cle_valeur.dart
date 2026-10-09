// PUB-1 (reprise apres revue adverse) : la logique du stockage de navigateur,
// separee de la liaison `dart:js_interop` pour etre testee hors navigateur.
//
// `stockage_navigateur_web.dart` ne fait que brancher le `localStorage` sur
// [AccesCleValeur] ; tout le reste (secours en memoire, pannes absorbees) vit
// ici et tourne dans les tests de la machine virtuelle Dart.

import '../observabilite/journal_dev.dart';
import 'preferences_locales.dart';

/// Un stockage cle/valeur synchrone, comme le `localStorage` du navigateur.
///
/// Chaque appel peut lever une exception (navigation privee, donnees de site
/// bloquees) : [StockagePreferencesCleValeur] l'absorbe.
abstract interface class AccesCleValeur {
  /// La valeur de [clef], ou `null` si elle n'a jamais ete ecrite.
  String? lire(String clef);

  /// Ecrit [valeur] sous [clef].
  void ecrire(String clef, String valeur);
}

/// Des preferences d'affichage durables pour cet appareil, posees sur un
/// [AccesCleValeur] : **non sensibles** (jamais un jeton ni un code, qui
/// passent par le coffre securise).
///
/// Si l'acces echoue, ou s'il n'existe pas (`null`), la valeur reste en
/// memoire pour la session : l'ecran se comporte alors comme a la premiere
/// visite au prochain lancement, sans jamais bloquer l'entree.
class StockagePreferencesCleValeur implements StockagePreferences {
  /// Cree le stockage sur [acces].
  StockagePreferencesCleValeur(this._acces);

  final AccesCleValeur? _acces;
  final Map<String, String> _secours = <String, String>{};

  @override
  Future<String?> lire(String clef) async {
    try {
      return _acces?.lire(clef) ?? _secours[clef];
    } on Object catch (erreur) {
      journalDev('Stockage du navigateur illisible : $erreur');
      return _secours[clef];
    }
  }

  @override
  Future<void> ecrire(String clef, String valeur) async {
    _secours[clef] = valeur;
    try {
      _acces?.ecrire(clef, valeur);
    } on Object catch (erreur) {
      journalDev('Stockage du navigateur non ecrit : $erreur');
    }
  }
}
