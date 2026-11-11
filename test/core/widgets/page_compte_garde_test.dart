// PROFILS P1 (pilote du 11/11/2026) : un seul gabarit pour le Compte de tous
// les roles. Deux gardes, en mode tolerance : les listes de `tool/` ne font
// que retrecir.
//
// 1. Aucune page Compte hors `PageCompte`. Une page Compte est le hub du
//    Compte d'un role : `ComptePage`, ou `Compte<Role>Page` (Tuteur, Eleve,
//    Adulte, Enseignant, Administration, Controleur, Comptable), ou
//    `MonEspaceAdultePage` (le Compte de l'eleve adulte). Les pages ouvertes
//    depuis une ligne du Compte (Aide, Securite...), la liste des comptes de
//    l'administration ou un compte rendu n'en sont pas.
// 2. Aucun `Medaillon` dans le Compte : ni directement, ni par
//    `CarteRubriques`, dans lib/features/compte, lib/features/mon_espace_adulte
//    et tout fichier qui compose une `PageCompte`.
//
// Une entree toleree qui ne fauterait plus fait echouer le test : on retire
// sa ligne dans le meme lot.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _tolere(String chemin) =>
    File(chemin)
        .readAsLinesSync()
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty && !l.startsWith('#'))
        .toSet();

List<File> _dart(String dossier) =>
    Directory(dossier)
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => !f.path.endsWith('.g.dart'))
        .toList();

String _chemin(File f) => f.path.replaceAll(r'\', '/');

final RegExp _classePage = RegExp(
  r'^class\s+(Compte(?:Tuteur|Eleve|Adulte|Enseignant|Administration|'
  r'Controleur|Comptable)?Page|MonEspaceAdultePage)\s+extends',
  multiLine: true,
);
final RegExp _medaillon = RegExp(r'\b(Medaillon|CarteRubriques)\b');

/// Les pages Compte qui ne composent pas `PageCompte`, « chemin:Classe ».
Set<String> pagesHorsGabarit() => <String>{
  for (final File f in _dart('lib/features'))
    for (final RegExpMatch m in _classePage.allMatches(f.readAsStringSync()))
      if (!f.readAsStringSync().contains('PageCompte('))
        '${_chemin(f)}:${m.group(1)}',
};

/// Les fichiers du Compte qui montrent un `Medaillon`.
Set<String> fichiersAvecMedaillon() {
  final Set<String> fautes = <String>{};
  for (final File f in <File>[
    ..._dart('lib/features'),
    ..._dart('lib/core/widgets'),
  ]) {
    final String chemin = _chemin(f);
    final String source = f.readAsStringSync();
    final bool duCompte =
        chemin.startsWith('lib/features/compte/') ||
        chemin.startsWith('lib/features/mon_espace_adulte/') ||
        source.contains('PageCompte(') ||
        chemin == 'lib/core/widgets/page_compte.dart' ||
        chemin == 'lib/core/widgets/entete_compte.dart' ||
        chemin == 'lib/core/widgets/groupe_preferences.dart';
    if (duCompte && _medaillon.hasMatch(source)) fautes.add(chemin);
  }
  return fautes;
}

void main() {
  test('aucune page Compte hors PageCompte (sauf tolerance qui retrecit)', () {
    final Set<String> tolere = _tolere('tool/compte_hors_gabarit_tolere.txt');
    final Set<String> fautes = pagesHorsGabarit();
    expect(
      fautes.difference(tolere),
      isEmpty,
      reason:
          'Une page Compte se compose dans PageCompte '
          '(lib/core/widgets/page_compte.dart).',
    );
    expect(
      tolere.difference(fautes),
      isEmpty,
      reason:
          'Ces pages sont branchees ou n existent plus : retirez leur ligne '
          'de tool/compte_hors_gabarit_tolere.txt.',
    );
  });

  test('aucun Medaillon dans le Compte (sauf tolerance qui retrecit)', () {
    final Set<String> tolere = _tolere('tool/compte_medaillon_tolere.txt');
    final Set<String> fautes = fichiersAvecMedaillon();
    expect(
      fautes.difference(tolere),
      isEmpty,
      reason: 'Le Compte n a plus de Medaillon : GroupeReglages et ses icones.',
    );
    expect(
      tolere.difference(fautes),
      isEmpty,
      reason:
          'Ces fichiers n ont plus de Medaillon : retirez leur ligne de '
          'tool/compte_medaillon_tolere.txt.',
    );
  });

  test('le gabarit commun lui-meme passe les deux gardes', () {
    expect(
      fichiersAvecMedaillon().where(
        (String c) => c.startsWith('lib/core/widgets/'),
      ),
      isEmpty,
    );
  });

  test('la garde voit une page Compte hors gabarit', () {
    // Garde de la garde : le motif reconnait bien les hubs du Compte.
    expect(
      _classePage.hasMatch('class CompteEnseignantPage extends Widget {}'),
      isTrue,
    );
    for (final String autre in <String>[
      'class AideComptePage extends Widget {}',
      'class ComptesPage extends Widget {}',
      'class CompteRenduControlePage extends Widget {}',
    ]) {
      expect(_classePage.hasMatch(autre), isFalse, reason: autre);
    }
    expect(_medaillon.hasMatch('child: Medaillon(icone: i),'), isTrue);
  });
}
