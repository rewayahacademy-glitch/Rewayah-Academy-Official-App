// L'en-tete de la salle : ce que chaque role voit, sans debordement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bascule_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

void _rien() {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
);

Future<void> _poser(
  WidgetTester tester,
  RoleSeance role,
  EtatDemoSalle etat,
  Size taille,
) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(
            role == RoleSeance.guidee
                ? InterfaceMode.enfant
                : InterfaceMode.standard,
            Brightness.light,
          ),
          home: Material(
            child: Align(
              alignment: Alignment.topCenter,
              child: ChromeSeance(
                vue: DonneesSeanceDemo.vue(role, etat),
                actions: _actions,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // MaterialApp anime le passage d'un theme a l'autre : on attend la fin de
  // l'animation, sinon un second rendu lirait encore les mesures du premier.
  await tester.pump(const Duration(seconds: 1));
}

const List<Size> _tailles = <Size>[
  Size(390, 844),
  Size(640, 1000),
  Size(1440, 900),
];

void main() {
  for (final RoleSeance role in RoleSeance.values) {
    for (final EtatDemoSalle etat in <EtatDemoSalle>[
      EtatDemoSalle.repos,
      EtatDemoSalle.visite,
    ]) {
      for (final Size taille in _tailles) {
        testWidgets('$role $etat ${taille.width} : sans debordement', (
          WidgetTester tester,
        ) async {
          await _poser(tester, role, etat, taille);
          expect(tester.takeException(), isNull);
          expect(
            find.text(DonneesSeanceDemo.vue(role, etat).titre),
            findsOneWidget,
          );
          expect(find.text('En ligne'), findsOneWidget);
          expect(find.textContaining('Foyer'), findsNothing);
          if (etat == EtatDemoSalle.repos) {
            expect(find.byType(PermanentNotice), findsOneWidget);
          } else {
            expect(find.byType(PermanentNotice), findsNothing);
            expect(find.byType(PointEnregistrement), findsOneWidget);
          }
        });
      }
    }
  }

  testWidgets('eleve, visite : « Votre parent », jamais « Tuteur de »', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      RoleSeance.eleve,
      EtatDemoSalle.visite,
      const Size(1440, 900),
    );
    expect(find.text('Votre parent observe la séance.'), findsOneWidget);
    expect(find.textContaining('Tuteur de'), findsNothing);
    expect(find.text('Mariam'), findsOneWidget);
    expect(find.byType(BasculeTheme), findsOneWidget);
  });

  testWidgets('guidee desktop : ni theme, ni reglages, avatar sans menu', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      RoleSeance.guidee,
      EtatDemoSalle.visite,
      const Size(1440, 900),
    );
    expect(find.byType(BasculeTheme), findsNothing);
    expect(find.bySemanticsLabel(t.salle.seance.reglages), findsNothing);
    expect(find.text('Ton parent observe la séance.'), findsOneWidget);
    expect(find.text('Mariam'), findsOneWidget);
  });

  for (final Size taille in _tailles) {
    testWidgets('guidee ${taille.width} : titre et notice a l\'echelle des '
        'images, alignes comme pour l\'eleve', (WidgetTester tester) async {
      double tailleDe(Finder f) =>
          tester.widget<Text>(f).style?.fontSize ??
          DefaultTextStyle.of(tester.element(f)).style.fontSize!;

      await _poser(tester, RoleSeance.eleve, EtatDemoSalle.visite, taille);
      final Rect titreEleve = tester.getRect(find.text('Séance en direct'));
      final double corpsEleve = tailleDe(find.text('Séance en direct'));

      await _poser(tester, RoleSeance.guidee, EtatDemoSalle.visite, taille);
      final Finder titre = find.text('Ma séance');
      final Finder notice = find.text('Ton parent observe la séance.');
      final Finder pastille = find.text('En ligne');
      expect(tailleDe(titre), corpsEleve);
      expect(tailleDe(notice), lessThanOrEqualTo(tailleDe(pastille)));
      // Meme retrait que l'eleve standard.
      expect(tester.getRect(titre).left, titreEleve.left);
      if (taille.width < 1200) {
        // Le chevron est sur la ligne du titre.
        final Rect chevron = tester.getRect(
          find.bySemanticsLabel(t.salle.seance.retour),
        );
        expect(
          (chevron.center.dy - tester.getRect(titre).center.dy).abs(),
          lessThan(2),
        );
      }
    });
  }

  testWidgets('telephone : « En ligne » a 16 du bord, comme le chevron', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      RoleSeance.eleve,
      EtatDemoSalle.repos,
      const Size(390, 844),
    );
    final Rect pastille = tester.getRect(find.bySemanticsLabel('En ligne'));
    expect(pastille.right, 390 - 16);
    expect(
      tester.getRect(find.bySemanticsLabel(t.salle.seance.retour)).left,
      16,
    );
  });

  testWidgets('cloche : point non lu pour l\'eleve et l\'enseignant, '
      'pas de cloche en guidee', (WidgetTester tester) async {
    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.eleve,
      RoleSeance.enseignant,
    ]) {
      await _poser(tester, role, EtatDemoSalle.repos, const Size(1440, 900));
      final ClocheNotifications cloche = tester.widget(
        find.byType(ClocheNotifications),
      );
      expect(cloche.nonLues, greaterThan(0));
    }
    await _poser(
      tester,
      RoleSeance.guidee,
      EtatDemoSalle.repos,
      const Size(1440, 900),
    );
    expect(find.byType(ClocheNotifications), findsNothing);
  });

  testWidgets('enseignant : compte SA, notice tuteur, jamais parent', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      RoleSeance.enseignant,
      EtatDemoSalle.visite,
      const Size(1440, 900),
    );
    expect(find.text('Sayyida Amina'), findsOneWidget);
    expect(find.text('SA'), findsOneWidget);
    expect(find.text('Mariam'), findsNothing);
    expect(find.text('Tuteur de Mariam observe.'), findsOneWidget);
    expect(find.textContaining('parent'), findsNothing);
  });

  testWidgets('telephone : rien a droite hormis « En ligne »', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      RoleSeance.enseignant,
      EtatDemoSalle.visite,
      const Size(390, 844),
    );
    expect(find.byType(BasculeTheme), findsNothing);
    expect(find.text('Sayyida Amina'), findsNothing);
  });

  testWidgets('fin : aucune mention', (WidgetTester tester) async {
    await _poser(
      tester,
      RoleSeance.eleve,
      EtatDemoSalle.fin,
      const Size(1440, 900),
    );
    expect(find.byType(PermanentNotice), findsNothing);
    expect(find.byType(PointEnregistrement), findsNothing);
  });
}
