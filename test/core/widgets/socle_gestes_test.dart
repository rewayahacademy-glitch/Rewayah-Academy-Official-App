// PE-SOCLE-GESTES (parcours enseignant, 20/11/2026) : les trois composants
// communs faits une fois dans `lib/core/`.
//
// - PE-D3 : la feuille du bas ne depasse jamais 90 % de la hauteur, sa
//   poignee reste sous la barre d'etat, et la feuille « Plus » des filtres
//   pose chaque filtre en pleine largeur avec « Tout effacer » au pied.
// - PE-D12 : tirer une page vers le bas l'actualise au doigt seulement, aux
//   couleurs de la marque, et sans anneau qui tourne sous « Reduire les
//   effets ».
// - PE-E3 : la barre du bas a la hauteur de la capsule (48 + 4 + 4) et chaque
//   onglet se touche sur toute sa colonne.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart'
    show EffetsReduits;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/fraicheur/relecture_page.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import '../../support/harnais.dart';

void _vue(WidgetTester tester, Size taille, {double haut = 0}) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: haut);
  tester.view.viewPadding = FakeViewPadding(top: haut);
  addTearDown(tester.view.reset);
}

/// Un bouton qui ouvre une feuille de [lignes] lignes.
Widget _ouvreFeuille(int lignes) => Builder(
  builder: (BuildContext context) => Center(
    child: Pressable(
      onPress: () => unawaited(
        AppBottomSheet.ouvrir<void>(
          context,
          titre: 'Feuille',
          libelleFermer: 'Fermer',
          constructeur: (BuildContext _) => Column(
            children: <Widget>[
              for (int i = 0; i < lignes; i++)
                SizedBox(height: 48, child: Text('ligne $i')),
            ],
          ),
        ),
      ),
      libelleSemantique: 'ouvrir',
      child: const SizedBox(width: 48, height: 48),
    ),
  ),
);

/// Une rangee de filtres dont deux sont rangees sous « Plus ».
class _Filtres extends StatefulWidget {
  const _Filtres();

  @override
  State<_Filtres> createState() => _FiltresEtat();
}

class _FiltresEtat extends State<_Filtres> {
  final Set<String> retenus = <String>{'Cinq'};
  String? ville = 'Lyon';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: RangeeFiltres(
      visiblesMax: 2,
      filtres: <Widget>[
        for (final String n in <String>['Un', 'Deux', 'Trois', 'Quatre'])
          FilterPill(
            libelle: n,
            retenue: retenus.contains(n),
            onPress: () => setState(
              () => retenus.contains(n) ? retenus.remove(n) : retenus.add(n),
            ),
          ),
        FilterPill(
          libelle: 'Cinq',
          retenue: retenus.contains('Cinq'),
          onPress: () => setState(
            () => retenus.contains('Cinq')
                ? retenus.remove('Cinq')
                : retenus.add('Cinq'),
          ),
        ),
        MenuFiltre<String>(
          libelle: 'Ville',
          valeur: ville,
          entrees: const <EntreeFiltre<String>>[
            EntreeFiltre<String>(valeur: null, libelle: 'Toutes'),
            EntreeFiltre<String>(valeur: 'Lyon', libelle: 'Lyon'),
          ],
          onChoix: (String? v) => setState(() => ville = v),
        ),
      ],
    ),
  );
}

void main() {
  group('PE-D3 : la feuille du bas', () {
    testWidgets('un contenu long ne prend jamais plus de 90 % de l ecran', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844), haut: 47);
      await tester.pumpWidget(hote(_ouvreFeuille(60)));
      await tester.tap(find.bySemanticsLabel('ouvrir'));
      await tester.pumpAndSettle();

      final Rect feuille = tester.getRect(find.byType(AppBottomSheet));
      expect(feuille.height, lessThanOrEqualTo(844 * 0.9 + 0.5));
      // La page voilee reste visible au-dessus : la poignee n'est jamais
      // sous la barre d'etat.
      expect(feuille.top, greaterThanOrEqualTo(844 * 0.1 - 0.5));
      expect(feuille.top, greaterThan(47));
      // La croix reste en haut, hors du defilement, toujours atteignable.
      expect(find.byKey(AppBottomSheet.cleFermer), findsOneWidget);
      expect(
        tester.getRect(find.byKey(AppBottomSheet.cleFermer)).top,
        lessThan(feuille.top + 80),
      );
      // Le titre et le corps defilent d'un seul tenant (une seule barre).
      final Finder defilements = find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.byType(Scrollable),
      );
      expect(defilements, findsOneWidget);
    });

    testWidgets('un contenu court garde la hauteur de son contenu', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844), haut: 47);
      await tester.pumpWidget(hote(_ouvreFeuille(2)));
      await tester.tap(find.bySemanticsLabel('ouvrir'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(AppBottomSheet)).height,
        lessThan(844 * 0.5),
      );
    });

    test('la hauteur maximale est 90 % de l ecran', () {
      expect(AppBottomSheet.hauteurMaxFeuille(1000), 900);
    });

    testWidgets('la feuille des filtres : pleine largeur et Tout effacer', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      await tester.pumpWidget(hote(const Scaffold(body: _Filtres())));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('rangee-filtres-plus-2')),
      );
      await tester.pumpAndSettle();

      final Rect feuille = tester.getRect(find.byType(AppBottomSheet));
      Finder dansFeuille(String texte) => find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.widgetWithText(FilterPill, texte),
      );
      final Rect trois = tester.getRect(dansFeuille('Trois'));
      final Rect quatre = tester.getRect(dansFeuille('Quatre'));
      // Un filtre par ligne, sur toute la largeur utile de la feuille.
      expect(trois.width, greaterThan(feuille.width - 2 * 24 - 1));
      expect(quatre.top, greaterThan(trois.bottom));
      expect(trois.width, quatre.width);

      // « Tout effacer » au pied relache la puce et le menu ranges dessous.
      expect(find.byKey(RangeeFiltres.cleEffacerFeuille), findsOneWidget);
      await tester.tap(find.byKey(RangeeFiltres.cleEffacerFeuille));
      await tester.pumpAndSettle();
      final _FiltresEtat etat = tester.state(find.byType(_Filtres));
      expect(etat.retenus, isEmpty);
      expect(etat.ville, isNull);
      // Plus rien a effacer : le bouton n'est plus rendu.
      expect(find.byKey(RangeeFiltres.cleEffacerFeuille), findsNothing);
    });

    test('une puce composee qui ne sait pas se relacher : pas d effacer', () {
      expect(RangeeFiltres.effacables(<Widget>[const _PuceComposee()]), isNull);
      expect(RangeeFiltres.effacables(const <Widget>[]), isNull);
    });
  });

  group('PE-D12 : tirer pour actualiser', () {
    late int relectures;
    late Completer<void> fin;

    Widget page({bool reduits = false}) => RelecturePage(
      relire: () {
        relectures++;
        return fin.future;
      },
      relireAuRetour: () {},
      child: EffetsReduits(
        actifs: reduits,
        child: const PageShell(
          titre: 'Accueil',
          child: SizedBox(height: 80, child: Text('contenu')),
        ),
      ),
    );

    setUp(() {
      relectures = 0;
    });

    testWidgets('au doigt : relit, anneau a l encre d accent de la marque', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      // Cree dans la zone du test : sa fin se solde dans le temps simule.
      fin = Completer<void>();
      await tester.pumpWidget(hote(page()));
      await tester.pumpAndSettle();
      final RefreshIndicator indicateur = tester.widget(
        find.byType(RefreshIndicator),
      );
      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(PageShell)),
      );
      expect(indicateur.color, palette.inkAccent.asBorderSide().color);
      expect(indicateur.backgroundColor, palette.surfaceRaised.background);

      await tester.fling(find.text('contenu'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(relectures, 1);
      // L'attente se voit tant que la relecture n'est pas finie.
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      fin.complete();
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('a la souris ou au pave tactile : rien ne se passe', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      // Cree dans la zone du test : sa fin se solde dans le temps simule.
      fin = Completer<void>();
      await tester.pumpWidget(hote(page()));
      await tester.pumpAndSettle();
      for (final PointerDeviceKind appareil in <PointerDeviceKind>[
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      ]) {
        final TestGesture geste = await tester.startGesture(
          tester.getCenter(find.text('contenu')),
          kind: appareil,
        );
        for (int i = 0; i < 10; i++) {
          await geste.moveBy(const Offset(0, 40));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await geste.up();
        await tester.pumpAndSettle();
      }
      expect(relectures, 0);
      expect(
        TirerPourActualiser.appareilTactile(PointerDeviceKind.touch),
        isTrue,
      );
      expect(
        TirerPourActualiser.appareilTactile(PointerDeviceKind.mouse),
        isFalse,
      );
    });

    testWidgets(
      'Reduire les effets : aucun anneau qui tourne, un anneau fixe',
      (WidgetTester tester) async {
        _vue(tester, const Size(390, 844));
        // Cree dans la zone du test : sa fin se solde dans le temps simule.
        fin = Completer<void>();
        await tester.pumpWidget(hote(page(reduits: true)));
        await tester.pumpAndSettle();
        await tester.fling(find.text('contenu'), const Offset(0, 400), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(relectures, 1);
        expect(find.byType(RefreshProgressIndicator), findsNothing);
        expect(find.byKey(TirerPourActualiser.anneauFixeKey), findsOneWidget);
        final CircularProgressIndicator anneau = tester.widget(
          find.descendant(
            of: find.byKey(TirerPourActualiser.anneauFixeKey),
            matching: find.byType(CircularProgressIndicator),
          ),
        );
        expect(anneau.value, isNotNull, reason: 'une valeur : aucune rotation');
        fin.complete();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.byKey(TirerPourActualiser.anneauFixeKey), findsNothing);
      },
    );

    testWidgets('l attente reste visible au moins le temps d etre vue', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(390, 844));
      // Cree dans la zone du test : sa fin se solde dans le temps simule.
      fin = Completer<void>();
      fin.complete();
      await tester.pumpWidget(hote(page(reduits: true)));
      await tester.pumpAndSettle();
      await tester.fling(find.text('contenu'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // La relecture a rendu la main tout de suite ; l'anneau reste.
      expect(find.byKey(TirerPourActualiser.anneauFixeKey), findsOneWidget);
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(TirerPourActualiser.anneauFixeKey), findsNothing);
    });
  });

  group('PE-E3 : la barre du bas', () {
    const List<Destination> destinations = <Destination>[
      Destination(libelle: 'Accueil', icone: AppIcons.accueil, chemin: '/a'),
      Destination(libelle: 'Suivi', icone: AppIcons.suivi, chemin: '/b'),
      Destination(libelle: 'Réglages', icone: AppIcons.reglages, chemin: '/c'),
    ];

    testWidgets('la pilule a la hauteur de la capsule, chaque colonne se '
        'touche entiere', (WidgetTester tester) async {
      _vue(tester, const Size(390, 844));
      final List<String> allees = <String>[];
      await tester.pumpWidget(
        hote(
          NavShell(
            destinations: destinations,
            indexActif: 0,
            onAller: allees.add,
            child: const PageShell(child: SizedBox(height: 40)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        NavShell.hauteurBarre,
        AppTouchTarget.standard + 2 * AppSpacing.xs,
      );

      final Finder onglets = find.descendant(
        of: find.byKey(NavShell.barreBasseKey),
        matching: find.byType(Pressable),
      );
      expect(onglets, findsNWidgets(3));
      final List<Rect> zones = <Rect>[
        for (int i = 0; i < 3; i++) tester.getRect(onglets.at(i)),
      ];
      for (final Rect z in zones) {
        // La colonne tactile a toute la hauteur de la pilule (56), plus que
        // la cible de 48.
        expect(z.height, closeTo(NavShell.hauteurBarre, 0.5));
        expect(z.width, greaterThanOrEqualTo(AppTouchTarget.standard));
      }
      // Aucun vide entre deux colonnes.
      final List<Rect> tries = zones.toList()
        ..sort((Rect a, Rect b) => a.left.compareTo(b.left));
      for (int i = 1; i < tries.length; i++) {
        expect(tries[i].left, closeTo(tries[i - 1].right, 0.5));
      }
      // Toucher le coin d'une colonne, loin de son icone, ouvre l'onglet.
      final Rect suivi = tester.getRect(
        find.ancestor(
          of: find.byIcon(AppIcons.suivi.repos),
          matching: find.byType(Pressable),
        ),
      );
      await tester.tapAt(suivi.topLeft + const Offset(2, 2));
      await tester.pump();
      expect(allees, <String>['/b']);
    });
  });

  test(
    'BARRE-UNE-SOURCE : une seule regle pour la barre de l eleve adulte',
    () {
      expect(
        SessionState.barreEleveAdultePour(AppRole.student, eleveAutonome: true),
        isTrue,
      );
      expect(
        SessionState.barreEleveAdultePour(
          AppRole.student,
          eleveAutonome: false,
        ),
        isFalse,
      );
      expect(
        SessionState.barreEleveAdultePour(
          AppRole.guardian,
          eleveAutonome: true,
        ),
        isFalse,
      );
    },
  );
}

/// Une puce composee qui se dit retenue sans geste connu pour la relacher.
class _PuceComposee extends StatelessWidget implements PuceFiltre {
  const _PuceComposee();

  @override
  bool get retenue => true;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
