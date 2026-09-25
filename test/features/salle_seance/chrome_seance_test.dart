// L'en-tete de la salle : ce que chaque role voit, sans debordement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bascule_theme.dart';
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
  await tester.pump();
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
