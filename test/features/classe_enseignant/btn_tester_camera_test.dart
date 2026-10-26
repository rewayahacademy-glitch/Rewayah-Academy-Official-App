// BTN-TESTER-1 (revue du directeur 01/10) remplace par le lot salle 3
// (pilote, 25/10/2026) : « Tester la camera », l'apercu fixe et la liste
// d'equipement sont retires de la preparation (ils ne mesuraient rien). Le
// test verifie leur absence, meme avec un test de camera branche, et que la
// page reste sans debordement avec son seul bouton « Entrer », a 320 et
// 1440 px, texte x1 et x2, en clair et en sombre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/salle/preparation_enseignant.dart';

import '../../support/garde_interface.dart';

const ResultatPreVol _pret = ResultatPreVol(
  microDisponible: true,
  cameraDisponible: true,
  sortieAudioDisponible: true,
  permissionRefusee: false,
);

const ContextePreparation _contexte = ContextePreparation(
  classe: 'Classe An-Nour',
  debut: 'Dans 8 min',
  support: 'Sourate Al-Fatiha',
  reprise: 'Page 24',
  eleves: '6',
);

Future<void> _poser(
  WidgetTester tester, {
  required Size taille,
  required double texte,
  required Brightness luminosite,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, luminosite),
        home: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(texte),
          ),
          child: Scaffold(
            body: PreparationEnseignant(
              resultat: _pret,
              reseau: ReseauPreparation.bonne,
              sortieAudioChoisissable: false,
              contexte: _contexte,
              onEntrer: () {},
              onRetour: () {},
              onReessayer: () {},
              onTesterCamera: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final Size taille in const <Size>[Size(320, 900), Size(1440, 1000)]) {
    for (final double texte in const <double>[1, 2]) {
      for (final Brightness lum in Brightness.values) {
        testWidgets(
          'lot salle 3 : aucun « Tester la camera » ni apercu fixe '
          '(${taille.width.toInt()} px, texte x${texte.toInt()}, ${lum.name})',
          (WidgetTester tester) async {
            await _poser(tester, taille: taille, texte: texte, luminosite: lum);
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const ValueKey<String>('preparation-tester-camera')),
              findsNothing,
            );
            expect(find.text(t.salle.preparation.testerCamera), findsNothing);
            expect(find.text(t.salle.preparation.cameraCoupee), findsNothing);
            // Une seule carte : la fiche de la seance.
            expect(find.byType(AppCard), findsOneWidget);
            final Finder entrer = find.byKey(
              const ValueKey<String>('preparation-entrer'),
            );
            expect(entrer, findsOneWidget);
            expect(tester.widget(entrer), isA<ActionPrincipale>());
            verifierUnSeulBoutonPlein(tester);
          },
        );
      }
    }
  }
}
