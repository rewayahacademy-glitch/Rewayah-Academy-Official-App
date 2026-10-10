// DUREE-FOND-1 : contre-epreuves de la garde des ancres A L'EXECUTION
// (`test/support/garde_ancres_execution.dart`, installee pour toute la suite
// par `test/flutter_test_config.dart`).
//
// Chaque forme de code que la garde statique de DUREE-INSECABLE-5 ne voyait
// pas (relectures REVUE_DUREE-INSECABLE-5-R, -R2, -R3) est reecrite ici dans
// un petit ecran : la garde d'execution, celle qui tourne a la fin de chaque
// `testWidgets`, doit echouer sur chacune. Puis l'ecran est demonte, pour que
// la garde de fin de test, elle, passe. Les formes corrigees (sansAncre,
// enchainer, valeur seule, isolat qui commence par la valeur) passent.
//
// Nommage des mutations (relecteur) :
// - H1, H2 : record (libelle, valeur) en liste, destructure dans un for-in,
//   ecrit dans un tampon (H1) ou dans un label Semantics (H2) ;
// - F15 : records nommes en liste, lambda `map` ;
// - G5 : records positionnels en liste, `r.$1`, `r.$2` ;
// - G2 : record dans un for-in non type ;
// - F12 : destructuration d'objet `final Seance(:duree) = s` ;
// - F18 : constructeur positionnel a liste d'initialisation ;
// - F16 : champ statique interpole ;
// - D2 : litteraux adjacents sur deux lignes (forme de `dart format`) ;
// - D3 : litteraux adjacents sur une ligne, titre fixe puis interpolation ;
// - M_this : `${this.colonne.texte(ligne)}`.
// D2 et D3 ne portent pas de nom dans les rapports ; ce sont les deux formes
// de litteraux colles de REVUE_DUREE-INSECABLE-5-R2 (decide par delegation le
// 10/10, etape DUREE-FOND-1).

// Les formes ci-dessous sont ecrites expres comme le relecteur les a
// ecrites, lints compris.
// ignore_for_file: unnecessary_this, unnecessary_string_interpolations, omit_local_variable_types, prefer_adjacent_string_concatenation

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';

import '../support/garde_ancres_execution.dart';

/// Une valeur ancree pour s'afficher seule : `U+200E` puis « 45 min ».
final String _valeur = LibellesGroupe.valeurSeule('45 min');

class _Seance {
  _Seance(String d) : duree = d;

  final String duree;
}

class _K {
  static final String d = LibellesGroupe.valeurSeule('12 jours');
}

class _Colonne {
  const _Colonne({required this.titre, required this.texte});

  final String titre;
  final String Function(int ligne) texte;
}

Widget _hote(Widget enfant) => Directionality(
  textDirection: TextDirection.ltr,
  child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[enfant]),
);

// --- Les mutations, une par ecran -------------------------------------------

class _H1 extends StatelessWidget {
  const _H1();
  @override
  Widget build(BuildContext context) {
    final List<(String, String)> lignes = <(String, String)>[
      ('Durée', _valeur),
    ];
    final StringBuffer b = StringBuffer();
    for (final (String libelle, String valeur) in lignes) {
      b.write('$libelle : $valeur');
    }
    return Text(b.toString());
  }
}

class _H2 extends StatelessWidget {
  const _H2();
  @override
  Widget build(BuildContext context) {
    final List<(String, String)> lignes = <(String, String)>[
      ('Durée', _valeur),
    ];
    return Column(
      children: <Widget>[
        for (final (String libelle, String valeur) in lignes)
          Semantics(
            label: '$libelle : $valeur',
            excludeSemantics: true,
            child: const SizedBox(width: 10, height: 10),
          ),
      ],
    );
  }
}

class _F15 extends StatelessWidget {
  const _F15();
  @override
  Widget build(BuildContext context) {
    final List<({String t, String v})> l = <({String t, String v})>[
      (t: 'Durée', v: _valeur),
    ];
    return Column(children: l.map((r) => Text('${r.t} : ${r.v}')).toList());
  }
}

class _G5 extends StatelessWidget {
  const _G5();
  @override
  Widget build(BuildContext context) {
    final List<(String, String)> l = <(String, String)>[('Durée', _valeur)];
    return Column(
      children: <Widget>[
        for (final (String, String) r in l) Text('${r.$1} : ${r.$2}'),
      ],
    );
  }
}

class _G2 extends StatelessWidget {
  const _G2();
  @override
  Widget build(BuildContext context) {
    final l = [('Durée', _valeur)];
    final List<Widget> enfants = <Widget>[];
    for (final r in l) {
      enfants.add(Text('${r.$1} : ${r.$2}'));
    }
    return Column(children: enfants);
  }
}

class _F12 extends StatelessWidget {
  const _F12();
  @override
  Widget build(BuildContext context) {
    final _Seance s = _Seance(_valeur);
    final _Seance(:duree) = s;
    return Text('Durée : $duree');
  }
}

class _F18 extends StatelessWidget {
  const _F18();
  @override
  Widget build(BuildContext context) {
    final _Seance s = _Seance(_valeur);
    return Text('Durée : ${s.duree}');
  }
}

class _F16 extends StatelessWidget {
  const _F16();
  @override
  Widget build(BuildContext context) => Text('Depuis : ${_K.d}');
}

class _D2 extends StatelessWidget {
  const _D2({required this.colonne});
  final _Colonne colonne;
  @override
  Widget build(BuildContext context) {
    const int ligne = 0;
    return Semantics(
      label:
          '${colonne.titre} : '
          '${colonne.texte(ligne)}',
      excludeSemantics: true,
      child: Text(colonne.texte(ligne)),
    );
  }
}

class _D3 extends StatelessWidget {
  const _D3({required this.colonne});
  final _Colonne colonne;
  @override
  Widget build(BuildContext context) {
    const int ligne = 0;
    return Semantics(
      label:
          'Valeur : '
          '${colonne.texte(ligne)}',
      excludeSemantics: true,
      child: Text(colonne.texte(ligne)),
    );
  }
}

class _MThis extends StatelessWidget {
  const _MThis({required this.colonne});
  final _Colonne colonne;
  @override
  Widget build(BuildContext context) {
    const int ligne = 0;
    return Semantics(
      label: '${this.colonne.titre} : ${this.colonne.texte(ligne)}',
      excludeSemantics: true,
      child: Text(this.colonne.texte(ligne)),
    );
  }
}

final _Colonne _colonne = _Colonne(
  titre: 'Depuis',
  texte: (int _) => LibellesGroupe.valeurSeule('12 jours'),
);

/// Pose [ecran], verifie que la garde d'execution echoue, puis demonte
/// l'ecran pour que la garde de fin de test passe.
Future<List<AncreRendue>> _doitEchouer(
  WidgetTester tester,
  Widget ecran,
) async {
  await tester.pumpWidget(_hote(ecran));
  final List<AncreRendue> fautes = ancresRendues();
  expect(
    verifierAncresRendues,
    throwsA(isA<TestFailure>()),
    reason: 'la garde d execution doit refuser cet ecran',
  );
  await tester.pumpWidget(const SizedBox.shrink());
  return fautes;
}

void main() {
  test('la suite tourne sous le binding de la garde', () {
    expect(TestWidgetsFlutterBinding.instance, isA<BindingGardeAncres>());
    expect(
      BindingGardeAncres.verificationDeFin,
      same(verifierAncresRendues),
      reason: 'le crochet de fin doit lancer la vraie garde',
    );
  });

  // Preuve permanente du crochet de fin (relecture de DUREE-FOND-1) : un
  // ecran fautif reste monte a la fin du corps d'un testWidgets ; le crochet
  // de BindingGardeAncres.runTest, remplace le temps de ce seul test par un
  // temoin, est appele APRES le corps, ecran encore monte, et la vraie garde
  // lancee a cet instant leve une TestFailure (qui fait echouer le test). Le
  // temoin rend la main sans lever, pour que ce test-ci passe ; le test qui
  // suit lit ce qu'il a vu. Contre-epreuve : sans l'appel du crochet dans
  // runTest, le second test echoue.
  group('crochet de fin de testWidgets', () {
    bool corpsTermine = false;
    bool appele = false;
    bool appeleApresCorps = false;
    List<AncreRendue> vues = <AncreRendue>[];
    Object? levee;

    testWidgets('ecran fautif laisse monte a la fin du corps', (
      WidgetTester tester,
    ) async {
      BindingGardeAncres.verificationDeFin = () {
        BindingGardeAncres.verificationDeFin = verifierAncresRendues;
        appele = true;
        appeleApresCorps = corpsTermine;
        vues = ancresRendues();
        try {
          verifierAncresRendues();
        } on TestFailure catch (e) {
          levee = e;
        }
      };
      addTearDown(
        () => BindingGardeAncres.verificationDeFin = verifierAncresRendues,
      );
      await tester.pumpWidget(_hote(Text('Duree : $_valeur')));
      corpsTermine = true;
    });

    test('le crochet a tourne apres le corps et la garde a leve', () {
      expect(appele, isTrue, reason: 'runTest n a pas appele le crochet');
      expect(appeleApresCorps, isTrue);
      // Texte rendu et libelle semantique du meme Text.
      expect(vues, isNotEmpty);
      expect(
        vues.map((AncreRendue v) => v.texte),
        everyElement('Duree : $_valeur'),
      );
      expect(levee, isA<TestFailure>());
      expect(BindingGardeAncres.verificationDeFin, same(verifierAncresRendues));
    });
  });

  group('position de l ancre', () {
    test('en tete, seule ou derriere des controles de sens : permis', () {
      expect(ancreHorsTete('\u200E45\u00A0min'), -1);
      expect(ancreHorsTete('\u2068\u200E45\u00A0min\u2069'), -1);
      expect(ancreHorsTete('\u200F\u200Eabc'), -1);
      expect(ancreHorsTete('Durée : 45\u00A0min'), -1);
      expect(ancreHorsTete(''), -1);
      // Marque droite a gauche devant une virgule arabe (traductions
      // arabes, COM-RC tour 7 lot L) : permise.
      expect(ancreHorsTete('Samira\u200F\u060C 0:12'), -1);
    });
    test('au milieu ou en fin : refuse', () {
      expect(ancreHorsTete('Durée : \u200E45\u00A0min'), 8);
      expect(ancreHorsTete('abc\u200F'), 3);
      expect(ancreHorsTete('Duree \u200F45'), 6);
      expect(ancreHorsTete('\u2068Durée\u2069 \u200E45'), 8);
    });
  });

  group('mutations du relecteur, la garde d execution echoue', () {
    final Map<String, Widget> mutations = <String, Widget>{
      'H1': const _H1(),
      'H2': const _H2(),
      'F15': const _F15(),
      'G5': const _G5(),
      'G2': const _G2(),
      'F12': const _F12(),
      'F18': const _F18(),
      'F16': const _F16(),
      'D2': _D2(colonne: _colonne),
      'D3': _D3(colonne: _colonne),
      'M_this': _MThis(colonne: _colonne),
    };
    for (final MapEntry<String, Widget> m in mutations.entries) {
      testWidgets(m.key, (WidgetTester tester) async {
        final List<AncreRendue> fautes = await _doitEchouer(tester, m.value);
        expect(fautes, isNotEmpty, reason: m.key);
        // La faute est bien une ancre derriere « : » (et non en tete).
        expect(
          fautes.every((AncreRendue f) => f.position > 0),
          isTrue,
          reason: m.key,
        );
      });
    }
  });

  group('formes corrigees ou permises, la garde passe', () {
    testWidgets('valeur seule, ancree en tete', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(Text(_valeur)));
      expect(ancresRendues(), isEmpty);
    });

    testWidgets('valeur seule dans un isolat', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(Text(isolerSens(_valeur))));
      expect(ancresRendues(), isEmpty);
    });

    testWidgets('libelle avec sansAncre', (WidgetTester tester) async {
      await tester.pumpWidget(
        _hote(
          Semantics(
            label: '${_colonne.titre} : ${sansAncre(_colonne.texte(0))}',
            excludeSemantics: true,
            child: Text(_colonne.texte(0)),
          ),
        ),
      );
      expect(ancresRendues(), isEmpty);
    });

    testWidgets('ligne jointe par enchainer', (WidgetTester tester) async {
      await tester.pumpWidget(
        _hote(Text(enchainer(<String>[_valeur, _valeur], ' · '))),
      );
      expect(ancresRendues(), isEmpty);
    });

    testWidgets('fusion semantique de deux chaines ancrees en tete', (
      WidgetTester tester,
    ) async {
      // MergeSemantics joint deux chaines par un retour a la ligne ; chacune
      // garde son ancre de tete : la garde lit les configurations propres.
      await tester.pumpWidget(
        _hote(
          MergeSemantics(
            child: Column(
              children: <Widget>[const Text('Depuis'), Text(_valeur)],
            ),
          ),
        ),
      );
      expect(ancresRendues(), isEmpty);
    });
  });

  group('chaque canal est lu', () {
    final String fautive = 'Durée : $_valeur';
    final Map<String, Widget> canaux = <String, Widget>{
      'Text': Text(fautive),
      'Text.rich, ancre dans un span qui suit': Text.rich(
        TextSpan(
          text: 'Durée : ',
          children: <InlineSpan>[TextSpan(text: _valeur)],
        ),
      ),
      'TextSpan.semanticsLabel': Text.rich(
        TextSpan(text: 'Durée', semanticsLabel: fautive),
      ),
      'Text.semanticsLabel': Text('Durée', semanticsLabel: fautive),
      'Semantics.value': Semantics(
        value: fautive,
        child: const SizedBox(width: 4, height: 4),
      ),
      'Semantics.hint': Semantics(
        hint: fautive,
        child: const SizedBox(width: 4, height: 4),
      ),
      'Semantics.tooltip': Semantics(
        tooltip: fautive,
        child: const SizedBox(width: 4, height: 4),
      ),
      'EditableText': _Saisie(texte: fautive),
    };
    for (final MapEntry<String, Widget> c in canaux.entries) {
      testWidgets(c.key, (WidgetTester tester) async {
        final List<AncreRendue> fautes = await _doitEchouer(tester, c.value);
        expect(fautes, isNotEmpty, reason: c.key);
      });
    }
  });
}

class _Saisie extends StatefulWidget {
  const _Saisie({required this.texte});
  final String texte;
  @override
  State<_Saisie> createState() => _SaisieState();
}

class _SaisieState extends State<_Saisie> {
  late final TextEditingController _c = TextEditingController(
    text: widget.texte,
  );
  final FocusNode _f = FocusNode();

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: EditableText(
      controller: _c,
      focusNode: _f,
      style: const TextStyle(fontSize: 14),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF000000),
    ),
  );
}
