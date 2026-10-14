// La langue de l'application au demarrage, lue sur l'appareil sans jamais
// faire tomber l'application.
//
// CLAVIER-ENTREE-1 (relecture PUB-1b) : Chromium sans `LANG` annonce la
// langue « en-US@posix ». Le moteur Web de Flutter la passe a `Intl.Locale`,
// qui la refuse (`RangeError: Incorrect locale information provided`), et
// `LocaleSettings.useDeviceLocale()` remontait l'erreur jusqu'a `main` :
// l'application s'arretait avant le premier ecran. Toute langue systeme
// inconnue, vide ou mal formee retombe desormais sur le francais, la langue
// de base (`slang.yaml`, `base_locale: fr`).
//
// La meme normalisation est faite cote navigateur, avant le moteur, par
// `web/index.html` : c'est elle qui empeche le moteur de lever ; celle-ci est
// la seconde barriere (toutes plateformes) et la seule qui se teste.

import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show WidgetsBinding;

import 'strings.g.dart';

/// La sous-etiquette de langue de [etiquette], en minuscules, ou nul si elle
/// n'en porte aucune de lisible.
///
/// Accepte les formes BCP 47 (`fr-FR`, `ar-Arab-EG`) et POSIX
/// (`fr_FR.UTF-8`, `en_US@posix`) : le codage (`.UTF-8`) et le modificateur
/// (`@posix`) sont retires, `_` vaut `-`. Une langue est faite de deux ou
/// trois lettres latines ; `C`, `POSIX`, une chaine vide ou de symboles ne
/// nomment aucune langue.
String? langueDeLEtiquette(String etiquette) {
  String brute = etiquette.trim();
  final int modificateur = brute.indexOf('@');
  if (modificateur >= 0) brute = brute.substring(0, modificateur);
  final int codage = brute.indexOf('.');
  if (codage >= 0) brute = brute.substring(0, codage);
  final String langue = brute.replaceAll('_', '-').split('-').first;
  if (!RegExp(r'^[A-Za-z]{2,3}$').hasMatch(langue)) return null;
  final String minuscule = langue.toLowerCase();
  // « und » (indetermine) a la forme d'un code sans en etre un.
  return minuscule == 'und' ? null : minuscule;
}

/// La langue de l'application pour les etiquettes systeme [etiquettes], dans
/// l'ordre de preference de l'appareil.
///
/// La premiere etiquette dont la langue est traduite l'emporte ; si aucune ne
/// l'est (langue inconnue ou mal formee), le francais.
AppLocale langueDepuisEtiquettes(Iterable<String> etiquettes) {
  for (final String etiquette in etiquettes) {
    final String? langue = langueDeLEtiquette(etiquette);
    if (langue == null) continue;
    for (final AppLocale connue in AppLocale.values) {
      if (connue.languageCode == langue) return connue;
    }
  }
  return AppLocale.fr;
}

/// Les langues de l'appareil, ou une liste vide si leur lecture echoue.
List<String> etiquettesDeLAppareil({List<Locale> Function()? lire}) {
  try {
    final List<Locale> langues =
        (lire ?? () => WidgetsBinding.instance.platformDispatcher.locales)();
    return <String>[
      for (final Locale langue in langues) langue.toLanguageTag(),
    ];
    // Une langue que le moteur ne sait pas lire leve une erreur de nature
    // variable selon la plateforme (RangeError, ArgumentError) : toutes
    // ramenent a la langue de base.
  } on Object {
    return const <String>[];
  }
}

/// Fixe la langue de l'application d'apres l'appareil, sans jamais lever.
///
/// Remplace `LocaleSettings.useDeviceLocale()` au demarrage. [lire] remplace
/// la lecture des langues de l'appareil (tests).
Future<AppLocale> appliquerLangueDeLAppareil({
  List<Locale> Function()? lire,
}) async {
  final AppLocale langue = langueDepuisEtiquettes(
    etiquettesDeLAppareil(lire: lire),
  );
  await LocaleSettings.setLocale(langue);
  return langue;
}
