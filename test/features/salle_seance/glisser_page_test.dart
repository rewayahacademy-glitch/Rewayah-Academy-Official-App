// Constat de la salle, defaut S-1 (11/11/2026) : au telephone, l'enseignant
// tourne la page au doigt. Le sens du geste est celui du support (mushaf :
// la page suivante vient en glissant vers la droite), pas celui de
// l'interface ; un outil retenu, ou l'absence de rappel, retire le geste.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/features/salle_seance/glisser_page.dart';

Future<ProviderContainer> _poser(
  WidgetTester tester, {
  VoidCallback? onPrecedente,
  VoidCallback? onSuivante,
  bool droiteAGauche = true,
  TextDirection interface = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ProviderContainer conteneur = ProviderContainer();
  addTearDown(conteneur.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: conteneur,
      child: MaterialApp(
        home: Directionality(
          textDirection: interface,
          child: GlisserPage(
            onPrecedente: onPrecedente,
            onSuivante: onSuivante,
            droiteAGauche: droiteAGauche,
            child: const ColoredBox(
              color: Colors.white,
              child: SizedBox.expand(key: ValueKey<String>('page')),
            ),
          ),
        ),
      ),
    ),
  );
  return conteneur;
}

Future<void> _glisser(WidgetTester tester, double dx) async {
  await tester.drag(find.byKey(const ValueKey<String>('page')), Offset(dx, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mushaf : glisser vers la droite amene la page suivante', (
    WidgetTester tester,
  ) async {
    int suivante = 0;
    int precedente = 0;
    await _poser(
      tester,
      onSuivante: () => suivante++,
      onPrecedente: () => precedente++,
    );
    await _glisser(tester, 200);
    expect((suivante, precedente), (1, 0));
    await _glisser(tester, -200);
    expect((suivante, precedente), (1, 1));
  });

  testWidgets('le sens est celui du support, pas celui de l interface', (
    WidgetTester tester,
  ) async {
    int suivante = 0;
    // Interface en arabe, support qui se lit de droite a gauche : meme geste.
    await _poser(
      tester,
      onSuivante: () => suivante++,
      onPrecedente: () {},
      interface: TextDirection.rtl,
    );
    await _glisser(tester, 200);
    expect(suivante, 1);
  });

  testWidgets('support de gauche a droite : le geste s inverse', (
    WidgetTester tester,
  ) async {
    int suivante = 0;
    await _poser(
      tester,
      onSuivante: () => suivante++,
      onPrecedente: () {},
      droiteAGauche: false,
    );
    await _glisser(tester, 200);
    expect(suivante, 0);
    await _glisser(tester, -200);
    expect(suivante, 1);
  });

  testWidgets('un petit geste lent ne tourne rien', (
    WidgetTester tester,
  ) async {
    int suivante = 0;
    await _poser(tester, onSuivante: () => suivante++, onPrecedente: () {});
    // Lent (timedDrag) et court : sous le seuil de distance et sans elan.
    await tester.timedDrag(
      find.byKey(const ValueKey<String>('page')),
      const Offset(30, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(suivante, 0);
  });

  testWidgets('a la fin du support : rien de ce cote, l autre marche encore', (
    WidgetTester tester,
  ) async {
    int precedente = 0;
    await _poser(tester, onPrecedente: () => precedente++);
    await _glisser(tester, 200); // vers la suivante : il n'y en a pas
    expect(precedente, 0);
    await _glisser(tester, -200);
    expect(precedente, 1);
  });

  testWidgets('sans aucun rappel (eleve) : le geste n existe pas', (
    WidgetTester tester,
  ) async {
    await _poser(tester);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets(
    'un outil retenu (Pointeur, ecriture) : le doigt ne tourne plus',
    (WidgetTester tester) async {
      int suivante = 0;
      final ProviderContainer c = await _poser(
        tester,
        onSuivante: () => suivante++,
        onPrecedente: () {},
      );
      c.read(etatOutilsProvider.notifier).choisirOutil(OutilDock.pointeur);
      await tester.pump();
      expect(find.byType(GestureDetector), findsNothing);
      await _glisser(tester, 200);
      expect(suivante, 0);
    },
  );
}
