// DEFIL-FEUILLE (03/11/2026, PLAN-LOTS §10, DECISION-DEFILEMENT regles 1 a
// 3) : une surface modale dont le contenu ne tient pas prend toute la
// hauteur que lui laisse l'ecran et porte la seule barre de defilement ; le
// titre defile avec le corps ; seule une barre fine reste en haut (poignee,
// croix « Fermer »). Une surface courte reste a la hauteur de son contenu.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          // Toute la hauteur de l'ecran : au telephone, la feuille entiere ;
          // au bureau, la boite devient la fenetre (DEFIL-FEUILLE-bis,
          // DECISION-DEFILEMENT regle 1 : rien ne defile dans une boite posee
          // au milieu de l'ecran).
          expect(surface.height, closeTo(vue.height, 1));
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

  group('bureau 1440, DEFIL-FEUILLE-bis', () {
    testWidgets('une boite sans croix trop haute devient la fenetre : une '
        'seule barre, au bord, le contenu dans la largeur de lecture', (
      WidgetTester tester,
    ) async {
      const Size vue = Size(1440, 900);
      await _ouvrir(tester, vue: vue, lignes: 30);
      expect(tester.takeException(), isNull);
      final Rect surface = _surface(tester);
      expect(surface.width, closeTo(vue.width, 1));
      expect(surface.height, closeTo(vue.height, 1));
      expect(_defilements(tester), hasLength(1));
      // La barre de defilement est celle de la fenetre : la zone qui defile
      // va d'un bord a l'autre.
      final Rect zone = tester.getRect(
        find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      expect(zone.width, closeTo(vue.width, 1));
      // Le contenu garde la largeur d'une boite, au milieu.
      final Rect carte = tester.getRect(find.text('Carte 0'));
      expect(carte.width, lessThanOrEqualTo(AppPage.largeurDialogue));
      expect(_dansLeDefilement(tester, find.text(_titre)), isTrue);
      await tester.drag(find.text('Carte 3'), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text(_titre).hitTestable(), findsNothing);
      expect(find.text('Carte 29').hitTestable(), findsOneWidget);
      // Sans voile autour, la croix « Fermer » est toujours la, hors du
      // defilement, et ferme.
      expect(
        find.byKey(AppBottomSheet.cleFermer).hitTestable(),
        findsOneWidget,
      );
      expect(
        _dansLeDefilement(tester, find.byKey(AppBottomSheet.cleFermer)),
        isFalse,
      );
      await tester.tap(find.byKey(AppBottomSheet.cleFermer));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomSheet), findsNothing);
      // Echap ferme aussi.
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomSheet), findsNothing);
    });

    testWidgets('une boite courte reste une boite au milieu, a sa hauteur', (
      WidgetTester tester,
    ) async {
      const Size vue = Size(1440, 900);
      await _ouvrir(tester, vue: vue, lignes: 2);
      final Rect surface = _surface(tester);
      expect(surface.width, lessThanOrEqualTo(AppPage.largeurDialogue));
      expect(surface.height, lessThan(vue.height / 2));
    });
  });

  testWidgets('bureau : la saisie survit au passage a la fenetre entiere', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              onPressed: () => AppBottomSheet.ouvrir<void>(
                context,
                titre: _titre,
                constructeur: (BuildContext _) => const _CorpsQuiGrandit(),
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
    expect(_surface(tester).height, lessThan(450));
    await tester.enterText(find.byType(TextField), 'Texte en cours');
    await tester.tap(find.text('Grandir'));
    await tester.pumpAndSettle();
    // Le contenu deborde : la boite est devenue la fenetre...
    expect(_surface(tester).height, closeTo(900, 1));
    // ... et rien de ce qui etait saisi ou affiche n'est perdu.
    expect(find.text('Texte en cours'), findsOneWidget);
    expect(find.text('Ligne 29'), findsOneWidget);
  });
}

/// Un corps qui grandit d'un coup (un message, une liste qui s'ouvre).
class _CorpsQuiGrandit extends StatefulWidget {
  const _CorpsQuiGrandit();

  @override
  State<_CorpsQuiGrandit> createState() => _CorpsQuiGranditEtat();
}

class _CorpsQuiGranditEtat extends State<_CorpsQuiGrandit> {
  bool _grand = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const TextField(),
      TextButton(
        onPressed: () => setState(() => _grand = true),
        child: const Text('Grandir'),
      ),
      if (_grand)
        for (var i = 0; i < 30; i++)
          SizedBox(height: 72, child: Text('Ligne $i')),
    ],
  );
}
