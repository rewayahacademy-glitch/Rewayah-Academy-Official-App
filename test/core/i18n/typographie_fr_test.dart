// COUPE-MOTS-4 (4) : typographie francaise de `assets/i18n/fr.i18n.json`.
//
// Avant « ? ! : ; », et a l'interieur des guillemets « », l'espace est
// insecable (U+00A0, la regle du depot, comme les durees de
// DUREE-INSECABLE-1) : une ponctuation haute ne part jamais seule a la
// ligne (« Pourquoi ce changement / ? », feuille de reglages de l'enfant).
// Garde sur TOUT le fichier : un libelle ajoute avec une espace ordinaire
// fait echouer ce test en le nommant.
// Contre-epreuve : sur l'ancien fichier (5a52ff30), ce test echoue (275
// libelles nommes).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toutes les valeurs texte de [noeud], avec leur cle complete.
Iterable<MapEntry<String, String>> _valeurs(
  Object? noeud, [
  String prefixe = '',
]) sync* {
  if (noeud is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> e in noeud.entries) {
      yield* _valeurs(e.value, prefixe.isEmpty ? e.key : '$prefixe.${e.key}');
    }
  } else if (noeud is List<dynamic>) {
    for (final (int i, Object? v) in noeud.indexed) {
      yield* _valeurs(v, '$prefixe.$i');
    }
  } else if (noeud is String) {
    yield MapEntry<String, String>(prefixe, noeud);
  }
}

/// Une espace SECABLE (tout blanc sauf U+00A0, U+2007, U+202F) devant une
/// ponctuation haute ou un guillemet fermant, ou apres un guillemet ouvrant.
final RegExp _espaceSecable = RegExp(r'[^\S   ][?!:;»]|«[^\S   ]');

/// La regle du depot : l'espace insecable ordinaire (U+00A0) et non l'espace
/// fine (U+202F), que toutes les polices ne dessinent pas.
final RegExp _espaceFine = RegExp(r' [?!:;»]|« ');

void main() {
  final Map<String, dynamic> fr = jsonDecode(
    File('assets/i18n/fr.i18n.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final List<MapEntry<String, String>> valeurs = _valeurs(fr).toList();

  test('le fichier francais porte des libelles a verifier', () {
    expect(valeurs.length, greaterThan(1000));
    // La garde mesure bien quelque chose : des ponctuations hautes existent.
    expect(
      valeurs.where((MapEntry<String, String> e) => e.value.contains('?')),
      isNotEmpty,
    );
  });

  test('aucune espace secable avant « ? ! : ; » ni dans « »', () {
    expect(<String>[
      for (final MapEntry<String, String> e in valeurs)
        if (_espaceSecable.hasMatch(e.value)) '${e.key} : ${e.value}',
    ], isEmpty);
  });

  test('l espace insecable est U+00A0, la regle du depot', () {
    expect(<String>[
      for (final MapEntry<String, String> e in valeurs)
        if (_espaceFine.hasMatch(e.value)) '${e.key} : ${e.value}',
    ], isEmpty);
  });

  test('« Pourquoi ce changement ? » lie son point d interrogation', () {
    final Map<String, dynamic> tuteur = fr['tuteur'] as Map<String, dynamic>;
    final Map<String, dynamic> reglages =
        tuteur['reglages'] as Map<String, dynamic>;
    expect(reglages['demandeMotif'], 'Pourquoi ce changement ?');
  });
}
