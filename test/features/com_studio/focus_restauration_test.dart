// COM-STU-3 : le restaurateur du Focus (`FocusStateRestorer`, spec section
// 20) et la regle du champ minimal (`MinimalComposer`, section 10.4), seuls.
//
// Capture avant le Focus, restauration a la sortie : positions et panneaux
// d'apres l'entree, texte saisi d'apres la sortie (aucune perte), sans
// animation ; une source retiree n'est pas restauree ; un Focus abandonne
// (autre canal) ne restaure rien.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/com_studio/focus/bascule_focus.dart';
import 'package:rewayah_academy/features/com_studio/focus/composer_minimal.dart';
import 'package:rewayah_academy/features/com_studio/focus/restauration_focus.dart';

/// Une source qui note ce qu'on lui rend.
class _SourceNotee implements SourceEtatFocus {
  _SourceNotee(this.valeur);

  Object? valeur;
  final List<(Object?, Object?)> rendus = <(Object?, Object?)>[];

  @override
  Object? capturer() => valeur;

  @override
  void restaurer({required Object? entree, required Object? sortie}) =>
      rendus.add((entree, sortie));
}

void main() {
  group('RestaurateurEtatFocus', () {
    test('retient a l entree, rend entree et sortie a chaque source', () {
      final RestaurateurEtatFocus r = RestaurateurEtatFocus();
      final _SourceNotee a = _SourceNotee(1);
      final _SourceNotee b = _SourceNotee('x');
      r
        ..inscrire('a', a)
        ..inscrire('b', b)
        ..retenir();
      expect(r.entree?['a'], 1);
      a.valeur = 2;
      b.valeur = 'y';
      r.restaurer(r.capturer());
      expect(a.rendus.single, (1, 2));
      expect(b.rendus.single, ('x', 'y'));
      expect(r.entree, isNull);
    });

    test('sans capture d entree, ou apres oubli, rien n est restaure', () {
      final RestaurateurEtatFocus r = RestaurateurEtatFocus();
      final _SourceNotee a = _SourceNotee(1);
      r
        ..inscrire('a', a)
        ..restaurer(r.capturer());
      expect(a.rendus, isEmpty);
      r
        ..retenir()
        ..oublier()
        ..restaurer(r.capturer());
      expect(a.rendus, isEmpty);
    });

    test('une source retiree n est plus restauree ; retirer une autre '
        'source sous la meme cle ne retire rien', () {
      final RestaurateurEtatFocus r = RestaurateurEtatFocus();
      final _SourceNotee a = _SourceNotee(1);
      final _SourceNotee intruse = _SourceNotee(9);
      r
        ..inscrire('a', a)
        ..retenir()
        ..retirer('a', intruse);
      expect(r.cles, contains('a'));
      r.retirer('a', a);
      expect(r.cles, isEmpty);
      r.restaurer(InstantaneFocus.vide);
      expect(a.rendus, isEmpty);
    });
  });

  group('SourceChamp : aucune perte de texte', () {
    test('le texte ecrit en Focus reste, jamais remplace par l ancien', () {
      final TextEditingController champ = TextEditingController(text: 'a');
      addTearDown(champ.dispose);
      final SourceChamp s = SourceChamp(() => champ);
      final Object? entree = s.capturer();
      champ.text = 'a puis b';
      final Object? sortie = s.capturer();
      s.restaurer(entree: entree, sortie: sortie);
      expect(champ.text, 'a puis b');
    });

    test('un champ recree vide recoit le dernier texte et sa selection', () {
      final TextEditingController ancien = TextEditingController(
        text: 'Brouillon long',
      )..selection = const TextSelection.collapsed(offset: 4);
      final TextEditingController neuf = TextEditingController();
      addTearDown(ancien.dispose);
      addTearDown(neuf.dispose);
      TextEditingController courant = ancien;
      final SourceChamp s = SourceChamp(() => courant);
      final Object? sortie = s.capturer();
      courant = neuf;
      s.restaurer(entree: null, sortie: sortie);
      expect(neuf.text, 'Brouillon long');
      expect(neuf.selection, const TextSelection.collapsed(offset: 4));
    });

    test('meme texte : la selection revient', () {
      final TextEditingController champ = TextEditingController(text: 'Bonjour')
        ..selection = const TextSelection.collapsed(offset: 3);
      addTearDown(champ.dispose);
      final SourceChamp s = SourceChamp(() => champ);
      final Object? sortie = s.capturer();
      champ.selection = const TextSelection.collapsed(offset: 7);
      s.restaurer(entree: null, sortie: sortie);
      expect(champ.selection, const TextSelection.collapsed(offset: 3));
    });

    test('sans champ (lecture seule), rien n est capture ni restaure', () {
      final SourceChamp s = SourceChamp(() => null);
      expect(s.capturer(), isNull);
      s.restaurer(entree: null, sortie: null);
    });
  });

  group('SourceValeur', () {
    test('remet la valeur d entree si elle a change, et seulement alors', () {
      bool ouvert = true;
      int ecritures = 0;
      final SourceValeur<bool> s = SourceValeur<bool>(
        lire: () => ouvert,
        ecrire: (bool v) {
          ecritures++;
          ouvert = v;
        },
      );
      final Object? entree = s.capturer();
      s.restaurer(entree: entree, sortie: null);
      expect(ecritures, 0);
      ouvert = false;
      s.restaurer(entree: entree, sortie: null);
      expect(ouvert, isTrue);
      expect(ecritures, 1);
    });

    test('une valeur nulle capturee est restauree aussi', () {
      String? recherche;
      final SourceValeur<String?> s = SourceValeur<String?>(
        lire: () => recherche,
        ecrire: (String? v) => recherche = v,
      );
      final Object? entree = s.capturer();
      recherche = 'planning';
      s.restaurer(entree: entree, sortie: null);
      expect(recherche, isNull);
    });
  });

  group('SourceDefilement', () {
    testWidgets('remet la position sans animation ; au bas du fil, revient '
        'au bas meme si le fil a change', (WidgetTester tester) async {
      final ScrollController defilement = ScrollController();
      addTearDown(defilement.dispose);
      double hauteur = 40;
      late StateSetter reconstruire;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext _, StateSetter setState) {
              reconstruire = setState;
              return ListView(
                controller: defilement,
                children: <Widget>[
                  for (int i = 0; i < 50; i++) SizedBox(height: hauteur),
                ],
              );
            },
          ),
        ),
      );
      final SourceDefilement s = SourceDefilement(() => defilement.position);
      defilement.jumpTo(300);
      final Object? milieu = s.capturer();
      expect(milieu, const PositionLecture(pixels: 300, enBas: false));
      // La disposition change (largeur), la position est rognee.
      reconstruire(() => hauteur = 20);
      await tester.pump();
      defilement.jumpTo(defilement.position.maxScrollExtent);
      reconstruire(() => hauteur = 40);
      await tester.pump();
      s.restaurer(entree: milieu, sortie: null);
      expect(defilement.position.pixels, 300);
      expect(tester.hasRunningAnimations, isFalse);

      defilement.jumpTo(defilement.position.maxScrollExtent);
      final Object? bas = s.capturer();
      expect((bas! as PositionLecture).enBas, isTrue);
      reconstruire(() => hauteur = 60);
      await tester.pump();
      s.restaurer(entree: bas, sortie: null);
      expect(defilement.position.pixels, defilement.position.maxScrollExtent);
    });

    test('un fil pas encore mesure ne capture rien', () {
      final SourceDefilement s = SourceDefilement(() => null);
      expect(s.capturer(), isNull);
      s.restaurer(
        entree: const PositionLecture(pixels: 10, enBas: false),
        sortie: null,
      );
    });
  });

  group('EtatFocusStudio', () {
    testWidgets('entrer, quitter avec ou sans restauration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final EtatFocusStudio etat = EtatFocusStudio();
      addTearDown(etat.dispose);
      final _SourceNotee source = _SourceNotee('avant');
      etat.restaurateur.inscrire('s', source);
      int changements = 0;
      etat.addListener(() => changements++);

      etat.entrer();
      expect(etat.actif, isTrue);
      etat.entrer();
      expect(changements, 1);
      source.valeur = 'pendant';
      etat.quitter();
      expect(etat.actif, isFalse);
      // La restauration attend l'image suivante (la disposition revenue).
      expect(source.rendus, isEmpty);
      await tester.pump();
      expect(source.rendus.single, ('avant', 'pendant'));

      etat
        ..entrer()
        ..quitter(restaurer: false);
      await tester.pump();
      expect(source.rendus, hasLength(1));

      etat.entrer();
      etat.quitterPlusTard();
      expect(etat.actif, isTrue);
      await tester.pump();
      expect(etat.actif, isFalse);
      expect(source.rendus, hasLength(1));
    });
  });

  group('ComposerMinimal (MinimalComposer)', () {
    const Widget pieces = Text('pieces');
    const Widget joindre = Text('joindre');
    const Widget vocal = Text('vocal');

    test('sans emplacement, rien n est pose, en Focus ou non', () {
      const ComposerMinimal c = ComposerMinimal();
      expect(c.emplacementPieceJointe(focus: false), isNull);
      expect(c.emplacementPieceJointe(focus: true), isNull);
      expect(c.emplacementVocal(focus: true), isNull);
    });

    test('en Focus : les pieces deja jointes et le vocal restent, l entree '
        '« Joindre » s efface', () {
      const ComposerMinimal c = ComposerMinimal(
        piecesEnPreparation: pieces,
        entreeJoindre: joindre,
        vocal: vocal,
      );
      expect(c.emplacementPieceJointe(focus: true), same(pieces));
      expect(c.emplacementVocal(focus: true), same(vocal));
      expect(c.emplacementPieceJointe(focus: false), isA<Column>());
      const ComposerMinimal seul = ComposerMinimal(entreeJoindre: joindre);
      expect(seul.emplacementPieceJointe(focus: false), same(joindre));
      expect(seul.emplacementPieceJointe(focus: true), isNull);
    });
  });
}
