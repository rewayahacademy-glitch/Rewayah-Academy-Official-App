// Constat de la salle, defaut R-1 (11/11/2026) : les barres de reseau etaient
// toujours pleines (valeur 3 par defaut, jamais ecrite). Elles disent
// maintenant la qualite que le serveur de visio mesure ; inconnue, aucune
// barre n'est montree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vignette_video.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../support/demo/seance_demo.dart';

Future<void> _poser(WidgetTester tester, int barres) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
    home: Material(
      child: Center(child: SignalVideo(barres: barres)),
    ),
  ),
);

/// Les couleurs des trois barres, de la plus petite a la plus grande.
List<Color?> _couleurs(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(SignalVideo),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((DecoratedBox b) => (b.decoration as BoxDecoration).color)
    .toList();

void main() {
  test('la qualite mesuree donne les barres ; inconnue, aucune', () {
    expect(DepuisSalle.barresDuLien(QualiteLien.excellente), 3);
    expect(DepuisSalle.barresDuLien(QualiteLien.bonne), 2);
    expect(DepuisSalle.barresDuLien(QualiteLien.mediocre), 1);
    expect(DepuisSalle.barresDuLien(QualiteLien.perdue), 0);
    expect(DepuisSalle.barresDuLien(QualiteLien.inconnue), isNull);
  });

  test(
    'sans mesure, l enseignant ne voit aucune barre (jamais un faux signal)',
    () {
      final VueSeance vue = DonneesSeanceDemo.vue(
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
      );
      expect(vue.voitSignalVideo, isTrue, reason: 'la demonstration donne 3');
      // Une vue sans mesure : construite sans barres.
      const VueSeance sans = VueSeance(
        role: RoleSeance.enseignant,
        nomClasse: 'Classe',
        nomEnseignant: 'Omar',
        initialesEnseignant: 'O',
        connexion: ConnexionSeance.enLigne,
      );
      expect(sans.signalEnseignant, isNull);
      expect(sans.voitSignalVideo, isFalse);
    },
  );

  testWidgets('lien mediocre : une seule barre, en teinte d attention', (
    WidgetTester tester,
  ) async {
    await _poser(tester, 1);
    final AppPalette palette = AppPalette.of(
      tester.element(find.byType(SignalVideo)),
    );
    final Color? attention = palette.pointsStatut.attention.pastille().color;
    final Color? neutre = palette.pointsStatut.neutre.pastille().color;
    expect(_couleurs(tester), <Color?>[attention, neutre, neutre]);
  });

  testWidgets('lien excellent : trois barres pleines ; perdu : aucune', (
    WidgetTester tester,
  ) async {
    await _poser(tester, 3);
    final AppPalette palette = AppPalette.of(
      tester.element(find.byType(SignalVideo)),
    );
    final Color? succes = palette.pointsStatut.succes.pastille().color;
    final Color? neutre = palette.pointsStatut.neutre.pastille().color;
    expect(_couleurs(tester), <Color?>[succes, succes, succes]);
    await _poser(tester, 0);
    expect(_couleurs(tester), <Color?>[neutre, neutre, neutre]);
  });
}
