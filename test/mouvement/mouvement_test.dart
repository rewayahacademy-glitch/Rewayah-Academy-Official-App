import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/mouvement/apparition_douce.dart';
import 'package:rewayah_academy/core/mouvement/bascule_etat.dart';
import 'package:rewayah_academy/core/mouvement/mouvement.dart';
import 'package:rewayah_academy/core/mouvement/transitions.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';

Widget _cadre(Widget enfant, {bool reduit = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduit),
    child: Scaffold(body: enfant),
  ),
);

void main() {
  group('Mouvement', () {
    test('chaque duree lit son jeton AppMouvement', () {
      expect(Mouvement.court, AppMouvement.micro);
      expect(Mouvement.moyen, AppMouvement.navigation);
      expect(Mouvement.long, AppMouvement.navigation);
      expect(Mouvement.maximum, AppMouvement.plafond);
      expect(Mouvement.entree, AppMouvement.entree);
      expect(Mouvement.sortie, AppMouvement.sortie);
    });

    test('aucune duree de Mouvement ne depasse le plafond', () {
      for (final Duration d in <Duration>[
        Mouvement.court,
        Mouvement.moyen,
        Mouvement.long,
      ]) {
        expect(d, lessThanOrEqualTo(Mouvement.maximum));
      }
      expect(Mouvement.echelon.inMilliseconds, inInclusiveRange(30, 40));
      // Le dernier element echelonne finit sous la borne haute + echelons.
      expect(Mouvement.maxEchelonnes, 8);
    });

    testWidgets('duree() vaut zero quand les animations sont reduites', (
      WidgetTester tester,
    ) async {
      late Duration normale;
      late Duration reduite;
      await tester.pumpWidget(
        _cadre(
          Builder(
            builder: (BuildContext c) {
              normale = Mouvement.duree(c, Mouvement.moyen);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        _cadre(
          Builder(
            builder: (BuildContext c) {
              reduite = Mouvement.duree(c, Mouvement.moyen);
              return const SizedBox();
            },
          ),
          reduit: true,
        ),
      );
      expect(normale, Mouvement.moyen);
      expect(reduite, Duration.zero);
    });
  });

  group('ApparitionDouce', () {
    testWidgets('part transparente puis se pose, une seule fois', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(const ApparitionDouce(child: Text('bonjour'))),
      );
      Opacity opacite() => tester.widget<Opacity>(
        find.ancestor(of: find.text('bonjour'), matching: find.byType(Opacity)),
      );
      expect(opacite().opacity, 0);
      await tester.pumpAndSettle();
      expect(opacite().opacity, 1);
      // Une reconstruction ne relance pas l'animation.
      await tester.pumpWidget(
        _cadre(const ApparitionDouce(child: Text('bonjour'))),
      );
      expect(opacite().opacity, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('neutralisee si disableAnimations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(const ApparitionDouce(child: Text('bonjour')), reduit: true),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        find.ancestor(of: find.text('bonjour'), matching: find.byType(Opacity)),
        findsNothing,
      );
    });
  });

  group('ListeEchelonnee', () {
    testWidgets('anime seulement les 8 premiers elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(
          SingleChildScrollView(
            child: ListeEchelonnee(
              children: <Widget>[for (int i = 0; i < 12; i++) Text('e$i')],
            ),
          ),
        ),
      );
      expect(find.byType(ApparitionDouce), findsNWidgets(8));
      await tester.pumpAndSettle();
      expect(find.text('e11'), findsOneWidget);
    });

    testWidgets('aucune animation si disableAnimations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(
          ListeEchelonnee(
            children: <Widget>[for (int i = 0; i < 3; i++) Text('e$i')],
          ),
          reduit: true,
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('BasculeEtat', () {
    testWidgets('fondu court entre chargement et contenu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(const BasculeEtat(etat: 'chargement', child: Text('...'))),
      );
      await tester.pumpWidget(
        _cadre(const BasculeEtat(etat: 'contenu', child: Text('pret'))),
      );
      expect(find.text('...'), findsOneWidget);
      expect(find.text('pret'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('...'), findsNothing);
      expect(find.text('pret'), findsOneWidget);
    });

    testWidgets('bascule immediate si disableAnimations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(
          const BasculeEtat(etat: 'chargement', child: Text('...')),
          reduit: true,
        ),
      );
      await tester.pumpWidget(
        _cadre(
          const BasculeEtat(etat: 'erreur', child: Text('oups')),
          reduit: true,
        ),
      );
      await tester.pump();
      expect(find.text('...'), findsNothing);
      expect(find.text('oups'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('FonduOnglet', () {
    testWidgets('fondu au changement d onglet, termine par pumpAndSettle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(const FonduOnglet(index: 0, child: Text('a'))),
      );
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(
        _cadre(const FonduOnglet(index: 1, child: Text('a'))),
      );
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('aucun fondu si disableAnimations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _cadre(const FonduOnglet(index: 0, child: Text('a')), reduit: true),
      );
      await tester.pumpWidget(
        _cadre(const FonduOnglet(index: 1, child: Text('a')), reduit: true),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
