// verifier_jetons, règle `famille-absente` (PR 265) : la police arabe
// d'interface peut manquer à `flutter.fonts` seulement si son asset est
// déclaré ET si `polices_differees.dart` la charge ; sinon la violation reste.

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verifier_jetons.dart';

const String _asset = 'assets/fonts/NotoSansArabic-Variable.ttf';

/// Les autres familles autorisées, toujours déclarées dans `flutter.fonts`.
const List<String> _autres = <String>[
  '    - family: UthmanTahaNaskh',
  '    - family: UthmanicHafs',
  '    - family: PlusJakartaSans',
  '    - family: DMSans',
  '    - family: Phosphor',
  '    - family: PhosphorFill',
];

const String _chargeur = '''
const Map<String, String> policesDifferees = <String, String>{
  'NotoSansArabic': 'assets/fonts/NotoSansArabic-Variable.ttf',
  'UthmanicHafs': 'assets/fonts/UthmanicHafs-v-3.0.ttf',
};
''';

List<String> _regles(List<Violation> v) => <String>[
  for (final Violation x in v) '${x.regle} ${x.extrait}',
];

void main() {
  test('famille déclarée dans flutter.fonts : aucune violation', () {
    final List<Violation> v = violationsFamillesAbsentes(
      lignesPubspec: <String>[..._autres, '    - family: NotoSansArabic'],
      sourcePolicesDifferees: null,
    );
    expect(v, isEmpty);
  });

  test('chargement différé correct (asset déclaré et chargé) : aucune '
      'violation', () {
    final List<Violation> v = violationsFamillesAbsentes(
      lignesPubspec: <String>[..._autres, '    - $_asset'],
      sourcePolicesDifferees: _chargeur,
    );
    expect(v, isEmpty);
  });

  test('chargement différé sans asset déclaré : la violation reste', () {
    final List<Violation> v = violationsFamillesAbsentes(
      lignesPubspec: <String>[..._autres],
      sourcePolicesDifferees: _chargeur,
    );
    expect(_regles(v), <String>[
      'famille-absente NotoSansArabic autorisee mais non declaree',
    ]);
  });

  test('asset déclaré mais famille non chargée par polices_differees : la '
      'violation reste', () {
    final List<Violation> v = violationsFamillesAbsentes(
      lignesPubspec: <String>[..._autres, '    - $_asset'],
      sourcePolicesDifferees: _chargeur.replaceAll(
        "  'NotoSansArabic': '$_asset',\n",
        '',
      ),
    );
    expect(_regles(v), hasLength(1));
  });

  test('asset déclaré mais fichier de chargement absent : la violation '
      'reste', () {
    final List<Violation> v = violationsFamillesAbsentes(
      lignesPubspec: <String>[..._autres, '    - $_asset'],
      sourcePolicesDifferees: null,
    );
    expect(_regles(v), hasLength(1));
  });

  test('asset seulement cité en commentaire : la violation reste', () {
    final List<Violation> v = violationsFamillesAbsentes(
      lignesPubspec: <String>[..._autres, '    # - $_asset'],
      sourcePolicesDifferees: _chargeur,
    );
    expect(_regles(v), hasLength(1));
  });

  test('une autre famille absente reste une violation même avec le '
      'chargement différé', () {
    final List<Violation> v = violationsFamillesAbsentes(
      lignesPubspec: <String>[
        ..._autres.where((String l) => !l.contains('DMSans')),
        '    - $_asset',
      ],
      sourcePolicesDifferees: _chargeur,
    );
    expect(_regles(v), <String>[
      'famille-absente DMSans autorisee mais non declaree',
    ]);
  });
}
