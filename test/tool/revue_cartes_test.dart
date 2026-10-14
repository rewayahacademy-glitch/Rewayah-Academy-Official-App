import 'package:flutter_test/flutter_test.dart';

import '../../tool/revue_cartes.dart';

/// Le detecteur de cartes collees (K-55) : ce qu'il voit, ce qu'il laisse
/// passer, et l'etat du depot (aucun cas).
List<String> _cas(String source, {Set<String>? cartes}) => <String>[
  for (final CasCollage c in cartesColleesDans(
    'x.dart',
    source,
    cartes: cartes ?? cartesDerivees(<String>[source]),
  ))
    c.extrait,
];

void main() {
  group('voit les cartes collees', () {
    test('deux cartes qui se suivent', () {
      expect(
        _cas('''
Column(children: <Widget>[
  AppCard(child: Text('a')),
  AppCard(child: Text('b')),
])'''),
        <String>['AppCard n°1 (collees)'],
      );
    });

    test('un espace inferieur a 16', () {
      expect(
        _cas('''
Column(children: <Widget>[
  AppCard(child: Text('a')),
  Ecart.vSm,
  AppCard(child: Text('b')),
  const SizedBox(height: AppSpacing.md),
  StatTile(valeur: 1, libelle: 'x'),
])'''),
        <String>['AppCard n°1 (ecart 8)', 'StatTile n°1 (ecart 12)'],
      );
    });

    test('un spacing de parent inferieur a 16', () {
      expect(
        _cas('''
Column(spacing: AppSpacing.sm, children: <Widget>[
  AppCard(child: Text('a')),
  AppCard(child: Text('b')),
])'''),
        <String>['AppCard n°1 (ecart 8)'],
      );
    });

    test('une boucle de cartes, avec ou sans Padding trop mince', () {
      expect(
        _cas('''
Column(children: <Widget>[
  for (final x in xs) AppCard(child: Text(x)),
])'''),
        <String>['AppCard n°1 (collees)'],
      );
      expect(
        _cas('''
Column(children: <Widget>[
  for (final x in xs)
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(child: Text(x)),
    ),
])'''),
        <String>['AppCard n°1 (ecart 8)'],
      );
      expect(
        _cas('''
Column(children: <Widget>[
  ...xs.map((x) => AppCard(child: Text(x))),
])'''),
        <String>['AppCard n°1 (collees)'],
      );
    });

    test('une branche else, une variable, une methode, un widget derive', () {
      expect(
        _cas('''
Column(children: <Widget>[
  if (vide) Text('rien') else for (final x in xs) AppCard(child: Text(x)),
])'''),
        <String>['AppCard n°1 (collees)'],
      );
      expect(
        _cas(
          '''
final Widget carte = AppCard(child: Text('a'));
Widget _autre() => AppCard(child: Text('b'));
Widget build(BuildContext c) => Column(children: <Widget>[carte, _autre()]);''',
        ),
        <String>['_autre n°1 (collees)'],
      );
      expect(
        _cas('''
class _Ligne extends StatelessWidget {
  Widget build(BuildContext context) => SettingRow(title: 'a');
}
Widget f() => Column(children: <Widget>[_Ligne(), _Ligne()]);'''),
        <String>['_Ligne n°1 (collees)'],
      );
    });

    test('une liste nommee posee dans children', () {
      expect(
        _cas('''
final lignes = <Widget>[
  AppCard(child: Text('a')),
  Ecart.vXs,
  AppCard(child: Text('b')),
];
Widget f() => Column(children: lignes);'''),
        <String>['AppCard n°1 (ecart 4)'],
      );
    });

    test('un ListView.builder de cartes, et un separateur trop mince', () {
      expect(
        _cas('''
ListView.builder(
  itemCount: 3,
  itemBuilder: (BuildContext c, int i) => AppCard(child: Text('x')),
)'''),
        <String>['AppCard n°1 (collees)'],
      );
      expect(
        _cas('''
ListView.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) => Ecart.vXs,
  itemBuilder: (BuildContext c, int i) => AppCard(child: Text('x')),
)'''),
        <String>['AppCard n°1 (ecart 4)'],
      );
    });

    test('des boites peintes a la main qui se touchent', () {
      expect(
        _cas('''
Column(children: <Widget>[
  DecoratedBox(
    decoration: BoxDecoration(color: c, borderRadius: r),
    child: Text('a'),
  ),
  DecoratedBox(
    decoration: BoxDecoration(color: c, borderRadius: r),
    child: Text('b'),
  ),
])'''),
        <String>['DecoratedBox n°1 (collees)'],
      );
    });
  });

  group('laisse passer ce qui est separe', () {
    test('Ecart.vLg, un spacing de 16, PileCartes, un titre entre deux', () {
      expect(
        _cas('''
Column(children: <Widget>[
  AppCard(child: Text('a')),
  Ecart.vLg,
  AppCard(child: Text('b')),
  Text('titre'),
  AppCard(child: Text('c')),
])'''),
        isEmpty,
      );
      expect(
        _cas('''
Column(spacing: AppSpacing.lg, children: <Widget>[
  AppCard(child: Text('a')),
  AppCard(child: Text('b')),
])'''),
        isEmpty,
      );
      expect(
        _cas('''
PileCartes(children: <Widget>[
  AppCard(child: Text('a')),
  AppCard(child: Text('b')),
])'''),
        isEmpty,
      );
    });

    test('une boucle dont chaque tour se termine par un espace de 16', () {
      expect(
        _cas('''
Column(children: <Widget>[
  for (final x in xs) ...<Widget>[AppCard(child: Text(x)), Ecart.vLg],
])'''),
        isEmpty,
      );
    });

    test('une pastille de choix (AppCard a marge reduite) a 8', () {
      expect(
        _cas('''
Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: <Widget>[
  for (final c in cs) AppCard(marge: AppSpacing.sm, child: Text(c)),
])'''),
        isEmpty,
      );
    });

    test('une carte groupee et un groupe de lignes sont une seule carte', () {
      expect(
        _cas('''
Column(children: <Widget>[
  CarteLignes(lignes: <Widget>[SettingRow(title: 'a'), SettingRow(title: 'b')]),
  Ecart.vLg,
  CarteGroupee(sections: <Widget>[Text('a'), Text('b')]),
])'''),
        isEmpty,
      );
    });

    test('des commentaires et des textes ne sont pas du code', () {
      expect(sansCommentaires('a // AppCard(\r\nb'), 'a \nb');
    });
  });

  group('angles morts corriges (CARTES-ECART-1, relecture)', () {
    test('un separateur de 12 entre deux AppCard est un defaut', () {
      expect(
        _cas('''
SliverList.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) => Ecart.vMd,
  itemBuilder: (BuildContext c, int i) => AppCard(child: Text('x')),
)'''),
        <String>['AppCard n°1 (ecart 12)'],
      );
    });

    test('un separateur de 8 entre deux cartes derivees est un defaut', () {
      const String derivee = '''
class CarteRessource extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppCard(child: Text('x'));
}
''';
      expect(
        _cas('''
$derivee
SliverList.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) => Ecart.vSm,
  itemBuilder: (BuildContext c, int i) => CarteRessource(),
)'''),
        <String>['CarteRessource n°1 (ecart 8)'],
      );
    });

    test('un separateur de 16 ou une pastille de choix a 8 passent', () {
      expect(
        _cas('''
ListView.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) => Ecart.vLg,
  itemBuilder: (BuildContext c, int i) => AppCard(child: Text('x')),
)'''),
        isEmpty,
      );
      expect(
        _cas('''
ListView.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) => Ecart.vSm,
  itemBuilder: (BuildContext c, int i) =>
      AppCard(marge: AppSpacing.sm, child: Text('x')),
)'''),
        isEmpty,
      );
    });

    test('une carte enveloppee dans ElementEchelonne est reconnue', () {
      expect(
        _cas('''
Column(children: <Widget>[
  for (int i = 0; i < n; i++) ...<Widget>[
    if (i > 0) Ecart.vMd,
    ElementEchelonne(index: i, child: AppCard(child: Text('x'))),
  ],
])'''),
        <String>['AppCard n°1 (ecart 12)'],
      );
    });

    test('un build qui prepare des variables avant le return est derive', () {
      const String derivee = '''
class CarteClasseOuverte extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = 1;
    final b = 2;
    final c = 'un texte assez long pour depasser les sept cents caracteres, ' * 1;
    // ................................................................................
    // ................................................................................
    // ................................................................................
    // ................................................................................
    // ................................................................................
    // ................................................................................
    // ................................................................................
    // ................................................................................
    // ................................................................................
    return AppCard(child: Text('x'));
  }
}
''';
      expect(cartesDerivees(<String>[derivee]), contains('CarteClasseOuverte'));
    });

    test('un padding du bas de 8 sous une carte suivie d\'un if', () {
      expect(
        _cas('''
Column(children: <Widget>[
  for (final c in cs) ...<Widget>[
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(child: Text('x')),
    ),
    if (c.choisi) Text('confirmation'),
  ],
])'''),
        <String>['AppCard n°1 (ecart 8)'],
      );
    });

    test('une rangee de cartes separee de 12 par un ternaire dans child', () {
      expect(
        _cas('''
Row(children: <Widget>[
  for (int j = 0; j < 2; j++) ...<Widget>[
    if (j > 0) Ecart.hMd,
    Expanded(
      child: j < rangee.length
          ? AppCard(child: Text('x'))
          : const SizedBox.shrink(),
    ),
  ],
])'''),
        <String>['AppCard n°1 (ecart 12)'],
      );
    });

    test(
      'un separateur conditionnel est mesure par sa branche la plus mince',
      () {
        expect(
          _cas('''
ListView.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) =>
      serre ? Ecart.vXs : Ecart.vSm,
  itemBuilder: (BuildContext c, int i) => AppCard(child: Text('x')),
)'''),
          <String>['AppCard n°1 (ecart 4)'],
        );
      },
    );

    test('un itemBuilder a plusieurs return est lu en entier', () {
      expect(
        _cas('''
ListView.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) => Ecart.vSm,
  itemBuilder: (BuildContext c, int i) {
    if (i == 0) {
      return Text('tete');
    }
    return AppCard(child: Text('x'));
  },
)'''),
        <String>['AppCard n°1 (ecart 8)'],
      );
    });

    test('une boite peinte par le helper de palette, nommee carte', () {
      const String derivee = '''
class _CarteEleve extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Text('x'),
    );
  }
}
''';
      expect(
        _cas('''
$derivee
ListView.separated(
  itemCount: 3,
  separatorBuilder: (BuildContext _, int _) => Ecart.vSm,
  itemBuilder: (BuildContext c, int i) => _CarteEleve(),
)'''),
        <String>['_CarteEleve n°1 (ecart 8)'],
      );
    });
  });

  test('le depot ne contient aucune carte collee', () {
    final List<String> cas = <String>[
      for (final CasCollage c in tousLesCas())
        '${c.chemin}:${c.ligne} ${c.extrait}',
    ];

    expect(cas, isEmpty, reason: 'K-55 : cartes collees\n${cas.join('\n')}');
  });
}
