// DEFIL-FEUILLE (03/11/2026, PLAN-LOTS §10, DECISION-DEFILEMENT regles 1 a
// 3) : une surface modale dont le contenu ne tient pas prend toute la
// hauteur que lui laisse l'ecran et porte la seule barre de defilement ; le
// titre defile avec le corps ; seule une barre fine reste en haut (poignee,
// croix « Fermer »). Une surface courte reste a la hauteur de son contenu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';

import '../support/harnais.dart';

const String _titre = 'Ajouter un élève';

Widget _contenu(int lignes) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    for (var i = 0; i < lignes; i++)
      SizedBox(height: 72, child: Text('Carte $i')),
  ],
);

Future<void> _ouvrir(
  WidgetTester tester, {
  required Size vue,
  required int lignes,
  String? libelleFermer,
  bool actions = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = vue;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Builder(
        builder: (BuildContext context) => Center(
          child: TextButton(
            onPressed: () => AppBottomSheet.ouvrir<void>(
              context,
              titre: _titre,
              libelleFermer: libelleFermer,
              actions: actions
                  ? (BuildContext _) =>
                        const SizedBox(height: 48, child: Text('Action collee'))
                  : null,
              constructeur: (BuildContext _) => _contenu(lignes),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
      surcharges: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

/// Les zones qui defilent verticalement dans la surface.
Iterable<Scrollable> _defilements(WidgetTester tester) => tester
    .widgetList<Scrollable>(
      find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.byType(Scrollable),
      ),
    )
    .where((Scrollable s) => s.axisDirection == AxisDirection.down);

Rect _surface(WidgetTester tester) =>
    tester.getRect(find.byType(AppBottomSheet));

bool _dansLeDefilement(WidgetTester tester, Finder f) => find
    .ancestor(of: f, matching: find.byType(Scrollable))
    .evaluate()
    .isNotEmpty;

void main() {
  for (final (String nom, Size vue) in <(String, Size)>[
    ('telephone 390', const Size(390, 844)),
    ('bureau 1440', const Size(1440, 900)),
  ]) {
    group(nom, () {
      testWidgets(
        'un contenu court : la surface a sa hauteur, rien ne change',
        (WidgetTester tester) async {
          await _ouvrir(tester, vue: vue, lignes: 2);
          expect(tester.takeException(), isNull);
          expect(_surface(tester).height, lessThan(vue.height / 2));
          expect(_defilements(tester), hasLength(1));
          // Rien a faire defiler.
          final ScrollableState etat = tester.state<ScrollableState>(
            find.descendant(
              of: find.byType(AppBottomSheet),
              matching: find.byType(Scrollable),
            ),
          );
          expect(etat.position.maxScrollExtent, 0);
        },
      );

      testWidgets(
        'un contenu long : toute la hauteur, une seule barre, le titre defile',
        (WidgetTester tester) async {
          await _ouvrir(tester, vue: vue, lignes: 30, actions: true);
          expect(tester.takeException(), isNull);
          final Rect surface = _surface(tester);
          // Toute la hauteur que laisse l'ecran : au bureau, la fenetre moins
          // les marges du gabarit ; au telephone, l'ecran entier.
          final double marges = nom.startsWith('bureau')
              ? 2 * AppSpacing.xxxl
              : 0;
          expect(surface.height, closeTo(vue.height - marges, 1));
          // Une seule zone qui defile : celle de la surface.
          expect(_defilements(tester), hasLength(1));
          // Le titre est dans le defilement, la zone d'actions collee hors de
          // lui.
          expect(_dansLeDefilement(tester, find.text(_titre)), isTrue);
          expect(
            _dansLeDefilement(tester, find.text('Action collee')),
            isFalse,
          );
          // Defiler : le titre part, les cartes du bas arrivent.
          await tester.drag(find.text('Carte 3'), const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(find.text(_titre).hitTestable(), findsNothing);
          expect(find.text('Carte 29').hitTestable(), findsOneWidget);
          expect(find.text('Action collee').hitTestable(), findsOneWidget);
        },
      );

      testWidgets(
        'la croix « Fermer » : a cote du titre si tout tient, dans la barre fine sinon',
        (WidgetTester tester) async {
          await _ouvrir(tester, vue: vue, lignes: 2, libelleFermer: 'Fermer');
          expect(
            _dansLeDefilement(tester, find.byKey(AppBottomSheet.cleFermer)),
            isTrue,
          );
          await tester.tap(find.byKey(AppBottomSheet.cleFermer));
          await tester.pumpAndSettle();
          expect(find.byType(AppBottomSheet), findsNothing);

          await tester.tap(find.text('Ouvrir'));
          await tester.pumpAndSettle();
          expect(find.byType(AppBottomSheet), findsOneWidget);
        },
      );

      testWidgets('un contenu long avec la croix : elle reste visible', (
        WidgetTester tester,
      ) async {
        await _ouvrir(tester, vue: vue, lignes: 30, libelleFermer: 'Fermer');
        expect(tester.takeException(), isNull);
        expect(
          _dansLeDefilement(tester, find.byKey(AppBottomSheet.cleFermer)),
          isFalse,
        );
        await tester.drag(find.text('Carte 3'), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(
          find.byKey(AppBottomSheet.cleFermer).hitTestable(),
          findsOneWidget,
        );
        // La croix ne cache aucune ligne : le defilement commence dessous.
        final Rect croix = tester.getRect(find.byKey(AppBottomSheet.cleFermer));
        final Rect zone = tester.getRect(
          find.descendant(
            of: find.byType(AppBottomSheet),
            matching: find.byType(Scrollable),
          ),
        );
        expect(zone.top, greaterThanOrEqualTo(croix.bottom));
        expect(_defilements(tester), hasLength(1));
      });
    });
  }
}
