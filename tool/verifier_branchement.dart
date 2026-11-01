// Verificateur du branchement (decision du directeur du 01/11/2026,
// docs/current/DECISION-BRANCHEMENT-2026-11-01.md, regle R1).
//
// Un fichier de lib/ que l'application n'atteint pas depuis lib/main.dart est
// du code sans ecran. Ce script part de lib/main.dart, suit les directives
// import, export et part (imports conditionnels compris : chaque branche
// `if (...) '...'` compte comme atteinte), et liste les fichiers .dart de lib/
// jamais atteints, outils de developpement mis a part (voir
// `outilsDeveloppement`). Il compare cette liste a tool/branchement_tolere.txt.
//
// Il echoue (code 1) quand :
//   * un fichier non atteint n'est pas dans la liste toleree (code nouveau
//     sans ecran, ou module debranche) ;
//   * une ligne de la liste toleree designe un fichier desormais atteint ou
//     disparu : la liste ne fait que retrecir, la ligne doit en etre retiree
//     dans la meme PR ;
//   * une ligne toleree n'a pas d'issue datee (regle R2) ;
//   * le fichier de tolerance a plus de lignes qu'au premier releve
//     (plafond ecrit en tete du fichier).
//
// Dart pur, aucune dependance (pubspec.yaml appartient au directeur).
//
// Lancement : dart run tool/verifier_branchement.dart
//             dart run tool/verifier_branchement.dart --lister   (relevé brut)

import 'dart:io';

const String nomPaquet = 'rewayah_academy';
const String racine = 'lib/main.dart';
const String fichierTolere = 'tool/branchement_tolere.txt';

/// Outils de developpement, absents de l'application de production : la
/// demonstration (`Env.demoCompilee`, constante fausse en production) et la
/// galerie (`Env.galerieActive`, forcee a faux). Leurs fichiers ne sont ni
/// suivis ni listes : un module atteint SEULEMENT par eux n'a pas d'ecran en
/// production et sort donc comme non atteint.
const List<String> outilsDeveloppement = <String>[
  'lib/features/demo/',
  'lib/features/_dev/',
];

bool estOutil(String chemin) => outilsDeveloppement.any(chemin.startsWith);

/// Les directives import / export / part d'un fichier, `part of` exclu.
final RegExp directive = RegExp(
  r'^\s*(import|export|part)\b(?!\s+of\b)([^;]*);',
  multiLine: true,
);

/// Un litteral de chaine simple, apostrophes ou guillemets.
final RegExp litteral = RegExp(r'''(?:'([^']*)'|"([^"]*)")''');

/// Une ligne de tolerance : `chemin | issue | date`.
///
/// L'issue est « branché à l'étape X » ou « supprimé le JJ/MM » ; la date est
/// celle de l'echeance, au format JJ/MM/AAAA. Aucune autre forme n'est admise.
final RegExp ligneTolere = RegExp(
  r'''^(lib/\S+\.dart)\s*\|\s*((?:branché à l[’']étape|supprimé le)\s+[^|]+?)\s*\|\s*(\d{2}/\d{2}/\d{4})\s*$''',
);

/// Le plafond ecrit en tete : `# plafond: N`.
final RegExp lignePlafond = RegExp(r'^#\s*plafond\s*:\s*(\d+)\s*$');

String retirerCommentaires(String source) {
  // Commentaires de bloc puis de ligne. Les directives ne contiennent pas de
  // `//` dans leurs chaines (chemins de fichiers), on peut donc couper large.
  final sansBlocs = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return sansBlocs.replaceAll(RegExp(r'//[^\n]*'), '');
}

/// Le chemin, relatif a la racine du depot, vise par [cible] depuis [depuis].
/// Null si la cible est hors de lib/ (dart:, autre paquet).
String? resoudre(String depuis, String cible) {
  if (cible.startsWith('dart:')) return null;
  if (cible.startsWith('package:')) {
    const prefixe = 'package:$nomPaquet/';
    if (!cible.startsWith(prefixe)) return null;
    return normaliser('lib/${cible.substring(prefixe.length)}');
  }
  final dossier =
      depuis.contains('/') ? depuis.substring(0, depuis.lastIndexOf('/')) : '.';
  return normaliser('$dossier/$cible');
}

String normaliser(String chemin) {
  final morceaux = <String>[];
  for (final m in chemin.split('/')) {
    if (m.isEmpty || m == '.') continue;
    if (m == '..') {
      if (morceaux.isNotEmpty) morceaux.removeLast();
      continue;
    }
    morceaux.add(m);
  }
  return morceaux.join('/');
}

Set<String> atteints() {
  final vus = <String>{};
  final aFaire = <String>[racine];
  while (aFaire.isNotEmpty) {
    final courant = aFaire.removeLast();
    if (estOutil(courant) || !vus.add(courant)) continue;
    final fichier = File(courant);
    if (!fichier.existsSync()) continue; // fichier genere absent : ignore
    final source = retirerCommentaires(fichier.readAsStringSync());
    for (final d in directive.allMatches(source)) {
      for (final l in litteral.allMatches(d.group(2)!)) {
        final cible = l.group(1) ?? l.group(2)!;
        if (!cible.endsWith('.dart')) continue;
        final chemin = resoudre(courant, cible);
        if (chemin != null && chemin.startsWith('lib/')) aFaire.add(chemin);
      }
    }
  }
  return vus;
}

List<String> fichiersLib() {
  final liste = <String>[];
  for (final e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) {
      final chemin = normaliser(e.path.replaceAll(r'\', '/'));
      if (!estOutil(chemin)) liste.add(chemin);
    }
  }
  liste.sort();
  return liste;
}

void main(List<String> arguments) {
  if (!File(racine).existsSync()) {
    stderr.writeln('verifier_branchement : lancer depuis la racine du depot.');
    exit(2);
  }
  final vus = atteints();
  final nonAtteints = fichiersLib().where((f) => !vus.contains(f)).toList();

  if (arguments.contains('--lister')) {
    nonAtteints.forEach(stdout.writeln);
    stdout.writeln(
      '${nonAtteints.length} fichiers de lib/ non atteints depuis $racine.',
    );
    return;
  }

  final erreurs = <String>[];
  final tolere = <String>{};
  int? plafond;
  final fichier = File(fichierTolere);
  if (!fichier.existsSync()) {
    erreurs.add('$fichierTolere absent.');
  } else {
    var numero = 0;
    var lignes = 0;
    for (final brute in fichier.readAsLinesSync()) {
      numero++;
      final ligne = brute.trim();
      final p = lignePlafond.firstMatch(ligne);
      if (p != null) {
        plafond = int.parse(p.group(1)!);
        continue;
      }
      if (ligne.isEmpty || ligne.startsWith('#')) continue;
      lignes++;
      final m = ligneTolere.firstMatch(ligne);
      if (m == null) {
        erreurs.add(
          '$fichierTolere:$numero  ligne sans issue datée (R2) : $ligne',
        );
        continue;
      }
      if (!tolere.add(m.group(1)!)) {
        erreurs.add('$fichierTolere:$numero  ligne en double : ${m.group(1)}');
      }
    }
    if (plafond == null) {
      erreurs.add('$fichierTolere : la ligne « # plafond: N » manque.');
    } else if (lignes > plafond) {
      erreurs.add(
          '$fichierTolere : $lignes lignes pour un plafond de $plafond ; '
          'la liste ne peut que rétrécir (baisser le plafond quand on retire une ligne).');
    }
  }

  for (final f in nonAtteints) {
    if (!tolere.contains(f)) {
      erreurs
          .add('$f  non atteint depuis $racine et absent de $fichierTolere : '
              'brancher ce fichier à un écran, ou le retirer.');
    }
  }
  // La liste ne fait que retrecir, par rapport a celle de main : une ligne
  // absente de main (ajoutee, ou retiree puis remise) fait echouer. Sans git
  // ou sans origin/main (copie isolee), ce controle est dit et saute.
  final reference = Process.runSync(
    'git',
    <String>['show', 'origin/main:$fichierTolere'],
    runInShell: false,
  );
  if (reference.exitCode == 0) {
    final deMain = <String>{};
    for (final brute in (reference.stdout as String).split('\n')) {
      final m = ligneTolere.firstMatch(brute.trim());
      if (m != null) deMain.add(m.group(1)!);
    }
    for (final t in tolere) {
      if (!deMain.contains(t)) {
        erreurs.add('$t  toléré ici mais pas sur main : la liste ne peut que '
            'rétrécir (R1).');
      }
    }
  } else {
    stdout.writeln('Branchement : origin/main:$fichierTolere introuvable, '
        'comparaison avec main sautée (premier relevé, ou copie sans git).');
  }

  final restants = nonAtteints.toSet();
  for (final t in tolere) {
    if (!restants.contains(t)) {
      erreurs.add(
          '$t  est atteint ou n’existe plus : retirer sa ligne de $fichierTolere '
          'et baisser le plafond.');
    }
  }

  if (erreurs.isEmpty) {
    stdout.writeln('Branchement : ${nonAtteints.length} fichiers non atteints, '
        'tous tolérés avec une issue datée. Aucun nouveau.');
    return;
  }
  erreurs.forEach(stderr.writeln);
  stderr.writeln('${erreurs.length} manquement(s) au branchement (R1, R2).');
  exit(1);
}
