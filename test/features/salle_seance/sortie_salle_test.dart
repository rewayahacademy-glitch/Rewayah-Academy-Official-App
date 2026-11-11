// SORTIE-SALLE (directeur, 11/11/2026) : deux gestes distincts et nommes,
// « Reduire la salle » (la seance continue) et « Quitter la seance » (on
// sort de l'appel) ; la consequence dite avant le choix (K-58) ; un seul
// bouton plein (K-56) ; la garde de fermeture de l'onglet.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/video/garde_fermeture.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/seance_demo.dart';
import '../../support/garde_interface.dart' show verifierUnSeulBoutonPlein;

final Finder _reduireDock = find.byKey(DockSeance.cleReduire);

Future<void> _monterDock(
  WidgetTester tester, {
  required Size taille,
  required RoleSeance role,
  bool nommee = false,
  bool rond = false,
  VoidCallback? reduire,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  final VueSeance vue = DonneesSeanceDemo.vue(role, EtatDemoSalle.repos);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: DockSeance(
            vue: vue,
            nommee: nommee,
            rond: rond,
            actions: ActionsSeance(
              onRetour: reduire,
              onQuitter: () {},
              onMicro: () {},
              onCamera: () {},
            ),
          ),
        ),
      ),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

/// Ouvre la question de sortie et rend ce que la personne a choisi.
Future<List<String>> _ouvrirQuestion(
  WidgetTester tester, {
  required Size taille,
  required bool cahier,
  required bool avecReduire,
  ThemeMode mode = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  final List<String> faits = <String>[];
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              key: const ValueKey<String>('ouvrir'),
              onPressed: () => unawaited(
                confirmerQuitterSeance(
                  context,
                  () => faits.add('quitter'),
                  cahier: cahier,
                  reduire: avecReduire ? () => faits.add('reduire') : null,
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
      themeMode: mode,
    ),
  );
  await tester.tap(find.byKey(const ValueKey<String>('ouvrir')));
  await stabiliser(tester);
  return faits;
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('SORTIE-SALLE : la commande « Reduire la salle »', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('ordinateur 1440, barre nommee (${mode.name}) : la tuile '
          '« Reduire » avant Quitter, un appui reduit', (
        WidgetTester tester,
      ) async {
        int reduit = 0;
        await _monterDock(
          tester,
          taille: const Size(1440, 400),
          role: RoleSeance.enseignant,
          nommee: true,
          reduire: () => reduit++,
          mode: mode,
        );
        expect(_reduireDock, findsOneWidget);
        expect(find.text(t.salle.sortie.reduireNom), findsOneWidget);
        expect(
          find.bySemanticsLabel(t.salle.sortie.reduireSemantique),
          findsOneWidget,
        );
        // Les deux gestes cote a cote : Reduire juste avant Quitter.
        final double xReduire = tester.getCenter(_reduireDock).dx;
        final double xQuitter = tester.getCenter(find.text(t.salle.quitter)).dx;
        expect(xReduire, lessThan(xQuitter));
        await tester.tap(_reduireDock);
        expect(reduit, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sans appel tenu hors de l ecran, aucune commande Reduire', (
      WidgetTester tester,
    ) async {
      await _monterDock(
        tester,
        taille: const Size(1440, 400),
        role: RoleSeance.enseignant,
        nommee: true,
      );
      expect(_reduireDock, findsNothing);
    });

    testWidgets('telephone 320 : la pilule micro, camera, quitter ne grossit '
        'pas (enseignant et eleve)', (WidgetTester tester) async {
      await _monterDock(
        tester,
        taille: const Size(320, 640),
        role: RoleSeance.enseignant,
        rond: true,
        reduire: () {},
      );
      expect(_reduireDock, findsNothing);
      await _monterDock(
        tester,
        taille: const Size(320, 640),
        role: RoleSeance.eleve,
        reduire: () {},
      );
      expect(_reduireDock, findsNothing);
    });

    testWidgets('eleve 1440 : la pilule porte « Reduire la salle » en '
        'infobulle', (WidgetTester tester) async {
      await _monterDock(
        tester,
        taille: const Size(1440, 400),
        role: RoleSeance.eleve,
        reduire: () {},
      );
      expect(_reduireDock, findsOneWidget);
    });
  });

  testWidgets('Interface guidee 1440 : un seul geste de sortie, jamais '
      'Reduire', (WidgetTester tester) async {
    await _monterDock(
      tester,
      taille: const Size(1440, 400),
      role: RoleSeance.guidee,
      reduire: () {},
    );
    expect(_reduireDock, findsNothing);
  });

  group('SORTIE-SALLE : la question de sortie dit la consequence', () {
    for (final (String l, Size taille) in <(String, Size)>[
      ('320', const Size(320, 700)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('celui qui conduit, $l ${mode.name} : Reduire (seul plein, '
            'recommande), Quitter, Rester ; Reduire ne quitte pas', (
          WidgetTester tester,
        ) async {
          final List<String> faits = await _ouvrirQuestion(
            tester,
            taille: taille,
            cahier: true,
            avecReduire: true,
            mode: mode,
          );
          expect(find.text(t.salle.sortie.question), findsWidgets);
          expect(find.text(t.salle.sortie.conduiteReduire), findsOneWidget);
          expect(find.text(t.salle.sortie.reduire), findsOneWidget);
          expect(find.text(t.salle.seance.quitterCahier), findsOneWidget);
          expect(find.text(t.salle.seance.rester), findsOneWidget);
          verifierUnSeulBoutonPlein(tester);
          await tester.tap(
            find.byKey(const ValueKey<String>('sortie-reduire')),
          );
          await stabiliser(tester);
          expect(faits, <String>['reduire']);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('celui qui conduit : Quitter quitte, Rester ne fait rien', (
      WidgetTester tester,
    ) async {
      List<String> faits = await _ouvrirQuestion(
        tester,
        taille: const Size(390, 800),
        cahier: true,
        avecReduire: true,
      );
      await tester.tap(find.byKey(const ValueKey<String>('sortie-quitter')));
      await stabiliser(tester);
      expect(faits, <String>['quitter']);

      faits = await _ouvrirQuestion(
        tester,
        taille: const Size(390, 800),
        cahier: true,
        avecReduire: true,
      );
      await tester.tap(find.byKey(const ValueKey<String>('sortie-rester')));
      await stabiliser(tester);
      expect(faits, isEmpty);
    });

    testWidgets('celui qui conduit, sans appel tenu : jamais un Reduire qui '
        'ne pourrait pas aboutir ; ses eleves restent sans lui, dit', (
      WidgetTester tester,
    ) async {
      final List<String> faits = await _ouvrirQuestion(
        tester,
        taille: const Size(390, 800),
        cahier: true,
        avecReduire: false,
      );
      expect(find.text(t.salle.sortie.reduire), findsNothing);
      expect(find.text(t.salle.sortie.conduite), findsOneWidget);
      await tester.tap(find.text(t.salle.seance.quitterCahier));
      await stabiliser(tester);
      expect(faits, <String>['quitter']);
    });

    testWidgets('eleve : « Vous pouvez revenir tant que la seance est '
        'ouverte », et Reduire propose', (WidgetTester tester) async {
      await _ouvrirQuestion(
        tester,
        taille: const Size(390, 800),
        cahier: false,
        avecReduire: true,
      );
      expect(find.text(t.salle.sortie.eleveReduire), findsOneWidget);
      expect(find.text(t.salle.seance.sortir), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('SORTIE-SALLE : garde de fermeture de l onglet', () {
    tearDown(GardeFermeture.remettre);

    test('armee tant que le flux dit « appel en cours »', () async {
      final StreamController<bool> flux = StreamController<bool>.broadcast();
      addTearDown(flux.close);
      GardeFermeture.suivre(flux.stream, initial: false);
      expect(GardeFermeture.armee, isFalse);
      flux.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(GardeFermeture.armee, isTrue);
      flux.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(GardeFermeture.armee, isFalse);
    });

    test('l etat initial compte : un appel deja tenu arme la garde', () {
      GardeFermeture.suivre(const Stream<bool>.empty(), initial: true);
      expect(GardeFermeture.armee, isTrue);
    });
  });
}
