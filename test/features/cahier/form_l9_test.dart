// FORM-L9 (recensement FORM-AUTO-1, E1) : la position de reprise du cahier de
// transmission se CHOISIT (sourate puis verset), elle ne se tape plus. Le
// clavier ne revient que si la liste des sourates est illisible. La phrase
// envoyee (`positionReprise`) reste « Sourate N, verset M ».
//
// Les 114 sourates viennent de la migration `0013_corpus_coranique.sql` (la
// donnee du depot), jamais d'une liste recopiee ici.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/features/cahier/selecteur_reprise.dart';

import '../../capture/outil_capture.dart';
import '../../support/annonces.dart';
import '../../support/cahier_sourates.dart';

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  late List<SourateVM> sourates;
  setUpAll(() => sourates = souratesDeLaMigration());

  test('la migration rend 114 sourates et 6236 versets', () {
    expect(sourates, hasLength(114));
    expect(
      sourates.fold<int>(0, (int s, SourateVM v) => s + v.nombreVersets),
      6236,
    );
  });

  test('la phrase envoyee ne change pas', () {
    expect(
      const PositionReprise(sourate: 18, verset: 10).texte,
      t.enseignant.cahier.repriseProposee(sourate: '18', verset: '10'),
    );
  });

  testWidgets('la reprise proposee se lit dans un champ a choisir, sans '
      'clavier', (WidgetTester tester) async {
    await monterCahier(tester, CorpusSourates(sourates));

    final Finder champ = find.byKey(ChampReprise.champKey);
    expect(champ, findsOneWidget);
    expect(tester.widget(champ), isNot(isA<TextField>()));
    // La proposition du brouillon de demonstration : sourate 78, verset 12.
    expect(
      find.text(
        t.enseignant.cahier.repriseProposee(sourate: '78', verset: '12'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('choisir Al-Kahf puis le verset 10 ecrit la reprise', (
    WidgetTester tester,
  ) async {
    await monterCahier(tester, CorpusSourates(sourates));
    await _toucher(tester, find.byKey(ChampReprise.champKey));

    // La sourate proposee est deja retenue, et son verset aussi.
    expect(find.byKey(FeuilleReprise.sourateKey(78)), findsOneWidget);
    expect(find.byKey(FeuilleReprise.versetKey(40)), findsOneWidget);
    expect(find.byKey(FeuilleReprise.versetKey(41)), findsNothing);

    await tester.enterText(find.byKey(FeuilleReprise.rechercheKey), 'kahf');
    await stabiliser(tester);
    await _toucher(tester, find.byKey(FeuilleReprise.sourateKey(18)));
    // Changer de sourate relache le verset : il faut le choisir. Le bouton
    // n'est jamais grise (BOUTONS-GRISES-1) : il le dit, l'annonce et rend
    // le focus au champ du verset.
    final List<String> annonces = ecouterAnnonces(tester);
    await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));
    expect(find.text(t.enseignant.cahier.repriseIncomplete), findsOneWidget);
    expect(annonces, <String>[t.enseignant.cahier.repriseIncomplete]);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'reprise-verset');

    // Une saisie hors bornes : le bouton reste actif, l'appui dit les bornes.
    await tester.enterText(find.byKey(FeuilleReprise.versetSaisieKey), '999');
    await stabiliser(tester);
    await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));
    expect(find.byType(FeuilleReprise), findsOneWidget);
    expect(annonces.last, t.enseignant.cahier.repriseVersetBornes(n: 110));
    expect(find.byKey(FeuilleReprise.versetKey(110)), findsOneWidget);

    await _toucher(tester, find.byKey(FeuilleReprise.versetKey(10)));
    await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));

    expect(find.byType(FeuilleReprise), findsNothing);
    expect(
      find.text(
        t.enseignant.cahier.repriseProposee(sourate: '18', verset: '10'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recherche par numero, et aucune sourate : etat dit', (
    WidgetTester tester,
  ) async {
    await monterCahier(tester, CorpusSourates(sourates));
    await _toucher(tester, find.byKey(ChampReprise.champKey));
    final Finder recherche = find.byKey(FeuilleReprise.rechercheKey);
    await tester.enterText(recherche, '112');
    await stabiliser(tester);
    expect(find.byKey(FeuilleReprise.sourateKey(112)), findsOneWidget);

    await tester.enterText(recherche, 'zzz');
    await stabiliser(tester);
    expect(find.text(t.enseignant.cahier.repriseAucune), findsOneWidget);
  });

  testWidgets('liste illisible : le champ redevient une saisie, et le dit', (
    WidgetTester tester,
  ) async {
    await monterCahier(tester, CorpusSourates(sourates, echoue: true));
    final Finder champ = find.byKey(ChampReprise.champKey);
    expect(tester.widget(champ), isA<TextField>());
    expect(
      find.byKey(const ValueKey<String>('cahier-reprise-sans-liste')),
      findsOneWidget,
    );
  });

  for (final (double, String) c in <(double, String)>[(1, 'x1'), (2, 'x2')]) {
    testWidgets('la recherche de la feuille garde une ligne avec du texte, '
        'texte et loupe alignes ($c)', (WidgetTester tester) async {
      await monterCahier(
        tester,
        CorpusSourates(sourates),
        taille: const Size(320, 2200),
        densite: 2,
        echelleTexte: c.$1,
      );
      await _toucher(tester, find.byKey(ChampReprise.champKey));
      final Finder recherche = find.byKey(FeuilleReprise.rechercheKey);
      final Size vide = tester.getSize(recherche);

      await tester.enterText(recherche, 'kahf');
      await stabiliser(tester);
      final Size plein = tester.getSize(recherche);
      // Une ligne de texte + les marges du champ, pas la hauteur de l'indice.
      final Finder texte = find.descendant(
        of: recherche,
        matching: find.byType(EditableText),
      );
      final double ligne = tester.getSize(texte).height;
      expect(plein.height, lessThanOrEqualTo(ligne + 2 * 16 + 4));
      expect(plein.height, lessThanOrEqualTo(vide.height));

      final double yTexte = tester
          .getCenter(
            find.descendant(of: recherche, matching: find.byType(EditableText)),
          )
          .dy;
      final double yLoupe = tester
          .getCenter(
            find.descendant(of: recherche, matching: find.byType(Icon)),
          )
          .dy;
      expect((yTexte - yLoupe).abs(), lessThanOrEqualTo(2));
    });
  }

  testWidgets('taper un numero de verset le choisit', (
    WidgetTester tester,
  ) async {
    await monterCahier(tester, CorpusSourates(sourates));
    await _toucher(tester, find.byKey(ChampReprise.champKey));
    await tester.enterText(find.byKey(FeuilleReprise.versetSaisieKey), '25');
    await stabiliser(tester);
    await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));
    expect(
      find.text(
        t.enseignant.cahier.repriseProposee(sourate: '78', verset: '25'),
      ),
      findsOneWidget,
    );
  });

  Future<void> ouvrirFeuille(WidgetTester tester) async {
    await monterCahier(tester, CorpusSourates(sourates));
    await _toucher(tester, find.byKey(ChampReprise.champKey));
  }

  String saisie(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(FeuilleReprise.versetSaisieKey))
      .controller!
      .text;

  testWidgets('a l\'ouverture, le champ Verset affiche le verset de la '
      'reprise initiale', (WidgetTester tester) async {
    await ouvrirFeuille(tester);
    expect(saisie(tester), '12');
  });

  for (final String valeur in <String>['0', 'N+1', '']) {
    testWidgets('verset hors bornes ou vide ("$valeur") : rien n\'est '
        'retenu, Retenir est inerte, un message le dit', (
      WidgetTester tester,
    ) async {
      await ouvrirFeuille(tester);
      final int n = sourates
          .firstWhere((SourateVM v) => v.numero == 78)
          .nombreVersets;
      final String texte = valeur == 'N+1' ? '${n + 1}' : valeur;
      await tester.enterText(find.byKey(FeuilleReprise.versetSaisieKey), texte);
      await stabiliser(tester);
      expect(
        find.text(t.enseignant.cahier.repriseVersetBornes(n: n)),
        findsOneWidget,
      );
      // Aucune puce n'est retenue.
      expect(
        tester
            .widgetList<FilterPill>(find.byType(FilterPill))
            .where((FilterPill p) => p.retenue),
        isEmpty,
      );
      // Retenir est inerte : le toucher ne ferme pas la feuille.
      await tester.ensureVisible(find.byKey(FeuilleReprise.retenirKey));
      await tester.tap(find.byKey(FeuilleReprise.retenirKey));
      await stabiliser(tester);
      expect(find.byKey(FeuilleReprise.versetSaisieKey), findsOneWidget);
      expect(
        find.text(
          t.enseignant.cahier.repriseProposee(sourate: '78', verset: '12'),
        ),
        findsOneWidget, // le champ du cahier derriere garde l'ancienne valeur
      );
      // Revenir a une valeur valide leve l'erreur et rend Retenir actif.
      await tester.enterText(find.byKey(FeuilleReprise.versetSaisieKey), '3');
      await stabiliser(tester);
      expect(
        find.text(t.enseignant.cahier.repriseVersetBornes(n: n)),
        findsNothing,
      );
      await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));
      expect(
        find.text(
          t.enseignant.cahier.repriseProposee(sourate: '78', verset: '3'),
        ),
        findsOneWidget,
      );
    });
  }
}
