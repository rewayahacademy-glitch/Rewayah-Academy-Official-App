// PERSONNES-UNE-PAGE (b) : quand les mots de quatre sections ne tiennent pas
// sur un telephone, des sections qui portent TOUTES une icone la montrent
// seule (le nom reste lu et en infobulle), au lieu d'un menu sans icone. Sans
// icone, rien ne change : le menu, comme avant.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';

import '../../support/harnais.dart';

const List<String> _noms = <String>[
  'Élèves (412)',
  'Familles (187)',
  'Enseignants (608)',
  'Direction et équipe (3)',
];
// La police de test dessine des carres : des mots de six signes tiennent a
// 390 (la preuve avec les vraies polices et les vrais mots est dans
// `test/features/admin_personnes/personnes_onglets_telephone_test.dart`).
const List<String> _courts = <String>['Élèves', 'Foyers', 'Classe', 'Équipe'];
const List<AppIcon> _icones = <AppIcon>[
  AppIcons.eleves,
  AppIcons.foyer,
  AppIcons.pedagogie,
  AppIcons.direction,
];

Future<List<int>> _monter(
  WidgetTester tester, {
  required bool icones,
  int nombre = 4,
  bool uneSansIcone = false,
  bool courts = false,
  double largeur = 390,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largeur, 844);
  addTearDown(tester.view.reset);
  final List<int> choix = <int>[];
  await tester.pumpWidget(
    hote(
      Material(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelecteurSection<int>(
            libelle: 'Personnes affichées',
            valeur: 0,
            onChange: choix.add,
            sections: <Segment<int>>[
              for (int i = 0; i < nombre; i++)
                Segment<int>(
                  valeur: i,
                  libelle: _noms[i % _noms.length],
                  libelleCourt: courts ? _courts[i % _courts.length] : null,
                  icone: icones && !(uneSansIcone && i == 1)
                      ? _icones[i % _icones.length]
                      : null,
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return choix;
}

void main() {
  testWidgets('quatre sections a icone, mots trop longs : les icones seules, '
      'pas de menu ; le nom reste lu', (WidgetTester tester) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    final List<int> choix = await _monter(tester, icones: true);

    expect(find.byType(MenuFiltre<int>), findsNothing);
    expect(find.byType(ControleSegmente<int>), findsOneWidget);
    expect(find.byType(Icon), findsNWidgets(4));
    // Aucun mot affiche, tous lus.
    expect(find.text('Enseignants (608)'), findsNothing);
    for (final String nom in _noms) {
      expect(find.bySemanticsLabel(nom), findsOneWidget);
    }
    await tester.tap(find.byType(Icon).at(2));
    await tester.pumpAndSettle();
    expect(choix, <int>[2]);
    expect(tester.takeException(), isNull);
    poignee.dispose();
  });

  testWidgets('avec des mots courts qui tiennent : l\'icone ET le mot court, '
      'le libelle entier reste lu', (WidgetTester tester) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    final List<int> choix = await _monter(tester, icones: true, courts: true);

    expect(find.byType(MenuFiltre<int>), findsNothing);
    expect(find.byType(Icon), findsNWidgets(4));
    for (final String mot in _courts) {
      expect(find.text(mot), findsOneWidget);
    }
    for (final String nom in _noms) {
      expect(find.bySemanticsLabel(nom), findsOneWidget);
    }
    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();
    expect(choix, <int>[3]);
    expect(tester.takeException(), isNull);
    poignee.dispose();
  });

  testWidgets('mots courts trop larges pour l\'ecran : les icones seules', (
    WidgetTester tester,
  ) async {
    await _monter(tester, icones: true, courts: true, largeur: 280);
    expect(find.byType(Icon), findsNWidgets(4));
    expect(find.text('Classe'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans icone : rien ne change, le menu', (
    WidgetTester tester,
  ) async {
    await _monter(tester, icones: false);
    expect(find.byType(MenuFiltre<int>), findsOneWidget);
    expect(find.byType(ControleSegmente<int>), findsNothing);
  });

  testWidgets('une seule section sans icone : le menu, comme avant', (
    WidgetTester tester,
  ) async {
    await _monter(tester, icones: true, uneSansIcone: true);
    expect(find.byType(MenuFiltre<int>), findsOneWidget);
  });

  testWidgets('cinq sections a icone : le menu, comme avant (ONGLETS-1)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, icones: true, nombre: 5);
    expect(find.byType(MenuFiltre<int>), findsOneWidget);
  });
}
