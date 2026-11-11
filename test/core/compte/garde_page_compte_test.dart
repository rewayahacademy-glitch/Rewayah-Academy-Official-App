// PROFILS P1 (directeur, 11/11/2026) : test de garde du Compte.
// - Toute page Compte d'un role pose le gabarit commun `PageCompte`.
// - Aucun `Medaillon` dans le Compte (lignes sobres, sans medaillon).
// Mode tolerance : les fichiers d'avant P1 sont listes ici. La liste ne fait
// que retrecir : une ligne qui n'est plus en faute doit en etre retiree.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les dossiers du Compte, pour tous les roles.
const List<String> _dossiersCompte = <String>[
  'lib/features/compte/',
  'lib/features/mon_espace_adulte/',
  'lib/features/profil_enseignant/',
];

/// Une page Compte de role : la page racine du Compte ou du Profil.
final RegExp _pageCompte = RegExp(
  r'^class (Compte|CompteTuteur|MonEspaceAdulte|ProfilEnseignant)Page\b',
  multiLine: true,
);

/// Tolerance d'avant P1 : pages Compte qui ne posent pas encore `PageCompte`.
const Set<String> _pagesTolerees = <String>{
  'lib/features/compte/compte_page.dart',
  'lib/features/compte/compte_tuteur_page.dart',
  'lib/features/mon_espace_adulte/mon_espace_adulte_page.dart',
  'lib/features/profil_enseignant/profil_enseignant_page.dart',
};

/// Tolerance d'avant P1 : fichiers du Compte qui emploient un `Medaillon`.
const Set<String> _medaillonsToleres = <String>{
  'lib/features/compte/carte_rubriques.dart',
};

Iterable<File> _fichiersCompte() sync* {
  for (final String dossier in _dossiersCompte) {
    final Directory d = Directory(dossier);
    if (!d.existsSync()) continue;
    for (final FileSystemEntity f in d.listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) yield f;
    }
  }
}

void main() {
  test('toute page Compte pose PageCompte (tolerance qui retrecit)', () {
    final Set<String> fautes = <String>{};
    for (final File f in _fichiersCompte()) {
      final String code = f.readAsStringSync();
      if (_pageCompte.hasMatch(code) && !code.contains('PageCompte(')) {
        fautes.add(f.path.replaceAll(r'\', '/'));
      }
    }
    expect(
      fautes.difference(_pagesTolerees),
      isEmpty,
      reason: 'page Compte sans PageCompte, hors tolerance',
    );
    expect(
      _pagesTolerees.difference(fautes),
      isEmpty,
      reason: 'ligne toleree qui n est plus en faute : la retirer',
    );
  });

  test('aucun Medaillon dans le Compte (tolerance qui retrecit)', () {
    final Set<String> fautes = <String>{};
    for (final File f in _fichiersCompte()) {
      if (f.readAsStringSync().contains('Medaillon(')) {
        fautes.add(f.path.replaceAll(r'\', '/'));
      }
    }
    expect(fautes.difference(_medaillonsToleres), isEmpty);
    expect(_medaillonsToleres.difference(fautes), isEmpty);
  });

  test('le gabarit lui-meme n emploie aucun Medaillon', () {
    for (final FileSystemEntity f in Directory(
      'lib/core/compte',
    ).listSync(recursive: true)) {
      if (f is File) {
        expect(
          f.readAsStringSync().contains('Medaillon'),
          isFalse,
          reason: f.path,
        );
      }
    }
  });
}
