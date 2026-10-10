// FINITIONS-CORR2-1, point (4) : « groupe devient classe » (00, contradictions
// resolues ; classes stables). La page d'administration des Classes, son
// titre visible et la navigation qui y mene disent « Classes » ; aucun
// libelle visible de l'administration ne dit « groupe ». Les routes et les
// identifiants (`adminOperationsGroupes`, `admin.groupes.*`) ne changent pas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';

/// Toutes les valeurs de texte sous [noeud], avec leur cle en points.
Iterable<MapEntry<String, String>> _textes(
  Object? noeud,
  String prefixe,
) sync* {
  if (noeud is String) {
    yield MapEntry<String, String>(prefixe, noeud);
  } else if (noeud is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> e in noeud.entries) {
      yield* _textes(e.value, prefixe.isEmpty ? e.key : '$prefixe.${e.key}');
    }
  }
}

final RegExp _motGroupe = RegExp(r'\bgroupes?\b', caseSensitive: false);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('le titre visible de la page est « Classes »', () {
    expect(t.admin.groupes.titre, 'Classes');
  });

  test('la sous-navigation Operations nomme la page « Classes »', () {
    final List<({String libelle, String chemin})> onglets = ongletsOperations();
    final ({String libelle, String chemin}) classes = onglets.firstWhere(
      (({String libelle, String chemin}) o) =>
          o.chemin == Routes.adminOperationsGroupes,
    );
    expect(classes.libelle, 'Classes');
    for (final ({String libelle, String chemin}) o in onglets) {
      expect(_motGroupe.hasMatch(o.libelle), isFalse, reason: o.libelle);
    }
  });

  test('aucun libelle visible de l administration ne dit « groupe »', () {
    for (final String langue in <String>['fr', 'ar']) {
      final Map<String, dynamic> racine = jsonDecode(
        File('assets/i18n/$langue.i18n.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final List<String> fautifs = <String>[
        for (final MapEntry<String, String> e in _textes(
          racine['admin'],
          'admin',
        ))
          // Une reference « @:cle » n'est pas un texte visible.
          if (!e.value.startsWith('@:') && _motGroupe.hasMatch(e.value))
            '${e.key} = ${e.value}',
      ];
      expect(fautifs, isEmpty, reason: langue);
    }
  });
}
