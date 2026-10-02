// BTN-TESTER-1 (revue du directeur 01/10, K-54, K-56) : « Tester la camera »
// occupe toute la largeur de sa carte, en bas de la carte, contenu centre.
// Le test mesure la geometrie rendue, a 320 et 1440 px, texte x1 et x2, en
// clair et en sombre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/features/salle/preparation_enseignant.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';

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
          '« Tester la camera » prend la largeur de sa carte, en bas, centre '
          '(${taille.width.toInt()} px, texte x${texte.toInt()}, ${lum.name})',
          (WidgetTester tester) async {
            await _poser(tester, taille: taille, texte: texte, luminosite: lum);

            final Finder bouton = find.byKey(
              const ValueKey<String>('preparation-tester-camera'),
            );
            expect(bouton, findsOneWidget);
            expect(tester.widget(bouton), isA<ActionPrincipale>());
            await tester.ensureVisible(bouton);
            await tester.pump();

            final Finder carte = find
                .ancestor(of: bouton, matching: find.byType(AppCard))
                .first;
            final Rect c = tester.getRect(carte);
            final Rect b = tester.getRect(bouton);

            // La marge de la carte, lue a gauche, est celle de droite et du
            // bas : le bouton remplit la carte en largeur et ferme sa colonne.
            final double margeDebut = b.left - c.left;
            final double margeFin = c.right - b.right;
            final double margeBas = c.bottom - b.bottom;
            expect(
              (margeDebut - margeFin).abs(),
              lessThanOrEqualTo(toleranceGarde),
              reason: 'bouton pas sur toute la largeur : $b dans $c',
            );
            expect(
              (margeBas - margeDebut).abs(),
              lessThanOrEqualTo(toleranceGarde),
              reason: 'bouton pas en bas de la carte : $b dans $c',
            );
            expect(
              b.width,
              greaterThan(c.width * 0.6),
              reason: 'le bouton ne remplit pas sa carte : $b dans $c',
            );
            verifierBoutonCentre(
              tester,
              bouton,
              t.salle.preparation.testerCamera,
            );
          },
        );
      }
    }
  }
}
