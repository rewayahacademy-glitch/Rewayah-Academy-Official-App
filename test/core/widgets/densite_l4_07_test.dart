// L4-07 : la densite par les composants. Quatre mesures, sur des hotes
// minimaux (fenetre fixee par `tester.view.physicalSize`) :
//  1. la rangee de filtres montre trois puces au plus, puis « Plus » ;
//  2. le champ de recherche se borne a `AppPage.largeurFormulaire` ;
//  3. un bouton sans `pleineLargeur` explicite est pleine largeur sur
//     telephone seulement, et une carte porte une largeur maximale ;
//  4. la tete d'une page defilante defile sous 800 de haut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/champ_recherche.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import '../../support/harnais.dart';

void _fenetre(WidgetTester tester, double l, double h) {
  tester.view.physicalSize = Size(l, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _monter(
  WidgetTester tester,
  Widget corps, {
  double largeur = 1046,
  double hauteur = 800,
  double echelle = 1,
  TextDirection? sens,
}) async {
  _fenetre(tester, largeur + 32, hauteur);
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(alignment: AlignmentDirectional.topStart, child: corps),
        ),
      ),
    ),
  );
  if (echelle != 1 || sens != null) {
    await tester.pumpWidget(
      hote(
        Builder(
          builder: (BuildContext c) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: Directionality(
              textDirection: sens ?? TextDirection.ltr,
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: corps,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  await tester.pumpAndSettle();
}

List<Widget> _puces(int n, {Set<int> retenues = const <int>{}}) => <Widget>[
  for (int i = 0; i < n; i++)
    FilterPill(
      key: ValueKey<String>('puce-$i'),
      libelle: 'Filtre $i',
      retenue: retenues.contains(i),
      onPress: () {},
    ),
];

/// Les puces posees dans la rangee : celles qu'on peut toucher. Une puce
/// rangee sous « Plus » reste dans l'arbre, ni peinte ni touchable.
List<String> _visibles(WidgetTester tester, int n) => <String>[
  for (int i = 0; i < n; i++)
    if (find
        .byKey(ValueKey<String>('puce-$i'))
        .hitTestable()
        .evaluate()
        .isNotEmpty)
      'puce-$i',
];

void main() {
  group('critere 1 : filtres, trois puces puis Plus', () {
    testWidgets('onze puces dans 1014 px : trois puces et Plus', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(width: 1014, child: RangeeFiltres(filtres: _puces(11))),
      );
      expect(_visibles(tester, 11), <String>['puce-0', 'puce-1', 'puce-2']);
      expect(find.text('Plus').hitTestable(), findsOneWidget);
      // Une seule rangee, 48 de haut, aucune barre de defilement.
      final Finder rangee = find.byType(RangeeFiltres);
      expect(tester.getSize(rangee).height, 48);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        0,
      );
    });

    testWidgets('Plus dit combien de filtres caches sont retenus', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(
          width: 1014,
          child: RangeeFiltres(filtres: _puces(11, retenues: <int>{4, 7, 1})),
        ),
      );
      expect(find.text('Plus, 2').hitTestable(), findsOneWidget);
      expect(find.text('Plus, 3').hitTestable(), findsNothing);
    });

    testWidgets('Plus ouvre les autres filtres dans une feuille', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(width: 1014, child: RangeeFiltres(filtres: _puces(6))),
      );
      await tester.tap(find.text('Plus'));
      await tester.pumpAndSettle();
      expect(find.text('Autres filtres'), findsOneWidget);
      // Les trois filtres caches sont dans la feuille, a une taille lisible.
      for (final int i in <int>[3, 4, 5]) {
        final Iterable<Element> noeuds = find.text('Filtre $i').evaluate();
        expect(
          noeuds.any(
            (Element e) => (e.renderObject! as RenderBox).size.width > 0,
          ),
          isTrue,
          reason: 'Filtre $i dans la feuille',
        );
      }
    });

    testWidgets('moins de trois puces qui tiennent : aucun Plus', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(width: 1014, child: RangeeFiltres(filtres: _puces(3))),
      );
      expect(_visibles(tester, 3).length, 3);
      // Les variantes de « Plus » existent, masquees : aucune ne se touche.
      expect(find.text('Plus').hitTestable(), findsNothing);
    });

    testWidgets('a 358 px, la rangee en montre autant qu\'il en tient', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(width: 358, child: RangeeFiltres(filtres: _puces(11))),
        largeur: 358,
      );
      final List<String> v = _visibles(tester, 11);
      expect(v.length, inInclusiveRange(1, 3));
      expect(find.text('Plus').hitTestable(), findsOneWidget);
      // Aucun debordement horizontal : tout tient dans 358.
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        0,
      );
    });

    testWidgets('en arabe, la rangee commence a droite', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(width: 1014, child: RangeeFiltres(filtres: _puces(6))),
        sens: TextDirection.rtl,
      );
      final Rect p0 = tester.getRect(
        find.byKey(const ValueKey<String>('puce-0')),
      );
      final Rect p1 = tester.getRect(
        find.byKey(const ValueKey<String>('puce-1')),
      );
      expect(p0.right, greaterThan(p1.right));
      expect(_visibles(tester, 6), <String>['puce-0', 'puce-1', 'puce-2']);
    });

    testWidgets('texte x2 a 358 px : une puce au moins, rien de coupe', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(width: 358, child: RangeeFiltres(filtres: _puces(11))),
        largeur: 358,
        echelle: 2,
      );
      expect(tester.takeException(), isNull);
      expect(_visibles(tester, 11), isNotEmpty);
      expect(find.byType(Scrollable), findsOneWidget);
      // Chaque libelle montre tient sur sa puce.
      for (final String id in _visibles(tester, 11)) {
        final Finder puce = find.byKey(ValueKey<String>(id));
        final Rect pr = tester.getRect(puce);
        final Rect tr = tester.getRect(
          find.descendant(of: puce, matching: find.byType(Text)).first,
        );
        expect(tr.left, greaterThanOrEqualTo(pr.left - 0.5));
        expect(tr.right, lessThanOrEqualTo(pr.right + 0.5));
      }
    });
  });

  group('critere 2 : recherche bornee', () {
    testWidgets('dans 1046 px, le champ fait 640 et commence au debut', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(
          width: 1046,
          child: ChampRecherche(
            controleur: TextEditingController(),
            libelle: 'Rechercher',
            aide: 'Nom',
          ),
        ),
      );
      final Rect r = tester.getRect(find.byType(TextField));
      expect(r.width, AppPage.largeurFormulaire);
      expect(r.left, 16);
    });

    testWidgets('dans 358 px, le champ garde toute la largeur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(
          width: 358,
          child: ChampRecherche(
            controleur: TextEditingController(),
            libelle: 'Rechercher',
            aide: 'Nom',
          ),
        ),
        largeur: 358,
      );
      expect(tester.getSize(find.byType(TextField)).width, 358);
    });
  });

  group('critere 4 : boutons et cartes a la largeur du contenu', () {
    testWidgets('sans pleineLargeur, le bouton suit son contenu sur bureau', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(
          width: 1046,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              libelle: 'Ajouter un profil',
              onPress: () {},
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ActionPrincipale)).width,
        lessThan(400),
      );
    });

    testWidgets('sans pleineLargeur, le bouton est pleine largeur sur mobile', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(
          width: 358,
          child: ActionPrincipale(libelle: 'Ajouter un profil', onPress: () {}),
        ),
        largeur: 358,
      );
      expect(tester.getSize(find.byType(ActionPrincipale)).width, 358);
    });

    testWidgets('pleineLargeur explicite est respectee sur bureau', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        SizedBox(
          width: 1046,
          child: ActionPrincipale(
            libelle: 'Ajouter un profil',
            pleineLargeur: true,
            onPress: () {},
          ),
        ),
      );
      expect(tester.getSize(find.byType(ActionPrincipale)).width, 1046);
    });

    testWidgets(
      'une carte a largeur maximale pose ses actions a leur largeur',
      (WidgetTester tester) async {
        await _monter(
          tester,
          SizedBox(
            width: 1046,
            child: AppCard(
              largeurMax: AppPage.largeurFormulaire,
              actions: LienFleche(
                key: const ValueKey<String>('voir'),
                libelle: 'Voir',
                alignerEnFin: true,
                onPress: () {},
              ),
              child: const Text('Contenu'),
            ),
          ),
        );
        final Finder surface = find.byType(AnimatedContainer);
        expect(
          tester.getSize(surface).width,
          lessThanOrEqualTo(AppPage.largeurFormulaire),
        );
        final Rect lien = tester.getRect(
          find.byKey(const ValueKey<String>('voir')),
        );
        expect(lien.width, lessThanOrEqualTo(300));
        // Alignee en fin de carte.
        final Rect carte = tester.getRect(surface);
        expect(carte.right - lien.right, lessThan(AppSpacing.xxl + 2));
      },
    );
  });

  group('critere 3 : la tete defile sous 800 px de haut', () {
    Widget page(String titre) => PageShell(
      titre: titre,
      child: const SizedBox(
        height: 2400,
        child: Align(alignment: Alignment.topCenter, child: Text('corps')),
      ),
    );

    testWidgets('a 1366 x 650, le titre sort apres 300 px de defilement', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, 1366, 650);
      await tester.pumpWidget(
        hote(
          page('Accueil'),
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Accueil')).top, greaterThan(0));
      await tester.drag(find.text('corps'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Accueil')).bottom, lessThan(0));
    });

    testWidgets('a 1440 x 900, la tete reste fixe', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, 1440, 900);
      await tester.pumpWidget(
        hote(
          page('Accueil'),
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final double avant = tester.getRect(find.text('Accueil')).top;
      await tester.drag(find.text('corps'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Accueil')).top, avant);
    });

    test('l\'en-tete compact s\'active sous 800 px de haut', () {
      expect(EnteteCompact.hauteurSeuil, 800);
    });
  });
}
