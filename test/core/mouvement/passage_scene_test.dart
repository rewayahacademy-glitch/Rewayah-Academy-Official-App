// RUBAN-ORDINATEUR (MODES-AFFICHAGE §5) : le passage d'un mode de la scene
// a l'autre. Depart, arrivee, interrompu a mi-course (la grille revient de sa
// place, sans etre reconstruite), deux pages jamais superposees, rien au
// montage, mouvement reduit (un fondu seul).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/mouvement/passage_scene.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';

/// Un contenu qui compte ses montages (la grille ne doit pas etre remontee).
class _Compte extends StatefulWidget {
  const _Compte(this.nom);

  final String nom;
  static final Map<String, int> montages = <String, int>{};

  @override
  State<_Compte> createState() => _EtatCompte();
}

class _EtatCompte extends State<_Compte> {
  @override
  void initState() {
    super.initState();
    _Compte.montages.update(widget.nom, (int n) => n + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: Text(widget.nom, key: ValueKey<String>(widget.nom)),
  );
}

Future<void> _poser(WidgetTester tester, String mode, {bool reduit = false}) =>
    tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduit),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: PassageScene(
                mode: mode,
                grille: mode == 'classe',
                child: _Compte(mode),
              ),
            ),
          ),
        ),
      ),
    );

double _opacite(WidgetTester tester, String nom) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(ValueKey<String>(nom)),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

/// La plus petite echelle posee au-dessus du contenu, ou `null` sans
/// aucune echelle (mouvement reduit).
double? _echelle(WidgetTester tester, String nom) {
  double? plusPetite;
  for (final Element e
      in find
          .ancestor(
            of: find.byKey(ValueKey<String>(nom)),
            matching: find.byType(Transform),
          )
          .evaluate()) {
    final double echelle = (e.widget as Transform).transform.storage[0];
    if (echelle != 1) {
      plusPetite = plusPetite == null
          ? echelle
          : (echelle < plusPetite ? echelle : plusPetite);
    }
  }
  return plusPetite;
}

void main() {
  setUp(_Compte.montages.clear);

  testWidgets('rien au montage : la grille est la, entiere, sans mouvement', (
    WidgetTester tester,
  ) async {
    await _poser(tester, 'classe');
    expect(tester.hasRunningAnimations, isFalse);
    expect(_opacite(tester, 'classe'), 1);
  });

  testWidgets('Classe vers Document : la grille retrecit et s efface vers le '
      'ruban pendant que la page arrive en fondu ; a la fin, la page seule', (
    WidgetTester tester,
  ) async {
    await _poser(tester, 'classe');
    final Rect place = tester.getRect(find.byType(PassageScene));
    await _poser(tester, 'document');
    await tester.pump();
    await tester.pump(AppMouvement.deplacementEntreeOrdinateur ~/ 2);
    // A mi-course : les deux, dans la meme place.
    expect(find.text('classe'), findsOneWidget);
    expect(find.text('document'), findsOneWidget);
    expect(tester.getRect(find.byType(PassageScene)), place);
    final double grille = _opacite(tester, 'classe');
    final double page = _opacite(tester, 'document');
    expect(grille, inExclusiveRange(0, 1));
    expect(page, inExclusiveRange(0, 1));
    expect(
      _echelle(tester, 'classe'),
      inExclusiveRange(PassageScene.echelleRuban, 1),
    );
    // La grille qui part ne se touche plus.
    final IgnorePointer garde = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.text('classe'),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(garde.ignoring, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('classe'), findsNothing);
    expect(_opacite(tester, 'document'), 1);
    // Duree : 240 ms au plus (aucune animation sans fin).
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('interrompu a mi-course : la grille revient de sa place, sans '
      'etre reconstruite, plus vite qu a l aller', (WidgetTester tester) async {
    await _poser(tester, 'classe');
    await _poser(tester, 'document');
    await tester.pump();
    await tester.pump(AppMouvement.deplacementEntreeOrdinateur ~/ 2);
    final double avant = _opacite(tester, 'classe');
    await _poser(tester, 'classe');
    await tester.pump();
    // Elle repart d'ou elle etait, sans saut.
    expect(_opacite(tester, 'classe'), closeTo(avant, 0.1));
    await tester.pump(AppMouvement.deplacementSortieOrdinateur);
    await tester.pump();
    expect(_opacite(tester, 'classe'), 1);
    await tester.pumpAndSettle();
    expect(find.text('document'), findsNothing);
    expect(_Compte.montages['classe'], 1);
  });

  testWidgets('Document vers Tableau : jamais deux pages l une sur l autre', (
    WidgetTester tester,
  ) async {
    await _poser(tester, 'document');
    await _poser(tester, 'tableau');
    await tester.pump();
    expect(find.text('document'), findsNothing);
    expect(find.text('tableau'), findsOneWidget);
    await tester.pump(AppMouvement.fonduEntree ~/ 2);
    expect(_opacite(tester, 'tableau'), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_opacite(tester, 'tableau'), 1);
  });

  testWidgets('mouvement reduit : un fondu seul, sans echelle ni glissement', (
    WidgetTester tester,
  ) async {
    await _poser(tester, 'classe', reduit: true);
    await _poser(tester, 'document', reduit: true);
    await tester.pump();
    await tester.pump(AppMouvement.fonduSortie ~/ 2);
    expect(_echelle(tester, 'classe'), isNull);
    expect(_opacite(tester, 'classe'), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.text('classe'), findsNothing);
  });
}
