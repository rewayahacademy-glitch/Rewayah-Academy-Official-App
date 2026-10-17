import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Non-regression des deux garde-fous (audit final, lot L3-07) : la suite
/// rougit quand `verifier_jetons` ou `verifier_revue` rougit, meme sans CI.
///
/// Les outils ne s'adaptent pas au code. Les ecarts connus sont nommes ici,
/// un par un, avec leur decision en attente ; en ajouter un exige une decision
/// datee du directeur.

/// Ecarts de `verifier_jetons` en attente de la question A-13 (jetons
/// d'echelon et de courbe accentuee a creer ou non). Rien d'autre n'est permis.
const List<String> _attenteA13 = <String>[
  'lib/core/mouvement/mouvement.dart:33  [duree-litterale]',
  'lib/core/mouvement/mouvement.dart:49  [courbe-litterale]',
];

/// Regles de `verifier_revue` qui ne sont pas encore a zero au-dessus du
/// socle, et pourquoi. Elles sortent du controle de ce test, pas de l'outil.
const Map<String, String> _reglesEnAttente = <String, String>{
  'libelle-sans-source':
      'socle ecrit sous Windows avec le corpus du directeur : 1146 cles sans '
      'source retrouvable ici (a trancher par le directeur)',
  'affirmation-reseau':
      '4 messages de photo d\'eleve et d\'enseignant, '
      'fichier i18n confie au lot L3-05',
  'bouton-grise-conditionnel':
      '2 ecrans de recrutement a rendre sans bouton '
      'grise (hors lot L3-07)',
};

const List<String> _reglesRevue = <String>[
  'bouton-grise',
  'cartes-collees',
  'bouton-recompose',
  'plein-multiple',
  'libelle-ambigu',
  'mot-interne',
  'erreur-sans-action',
  'nav-recomposee',
  'etat-seance-pastille',
  'selecteur-theme-recompose',
  'avatar-recompose',
  'avatar-taille',
  'onglets-defilants',
  'wrap-filtres',
];

Future<ProcessResult> _lancer(List<String> arguments) =>
    Process.run('dart', <String>['run', ...arguments]);

void main() {
  test('verifier_jetons : aucune violation hors les ecarts A-13', () async {
    final ProcessResult r = await _lancer(<String>[
      'tool/verifier_jetons.dart',
    ]);
    final List<String> lignes = '${r.stdout}'
        .split('\n')
        .where((String l) => RegExp(r'^\s+\S+:\d+\s+\[').hasMatch(l))
        .map((String l) => l.trim())
        .toList();
    final List<String> inattendues = lignes
        .where((String l) => !_attenteA13.any(l.startsWith))
        .toList();
    expect(
      inattendues,
      isEmpty,
      reason: 'verifier_jetons rend des violations nouvelles :\n${r.stdout}',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('verifier_revue : zero au-dessus du socle, regles a jour', () async {
    expect(_reglesEnAttente.keys, everyElement(isNotEmpty));
    final ProcessResult r = await _lancer(<String>[
      'tool/verifier_revue.dart',
      '--regle=${_reglesRevue.join(',')}',
      '--detail',
    ]);
    expect(
      r.exitCode,
      0,
      reason: 'verifier_revue est au-dessus du socle :\n${r.stdout}',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
