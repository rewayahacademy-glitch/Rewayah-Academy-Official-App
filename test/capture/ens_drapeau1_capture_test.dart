// Captures de recette ENS-DRAPEAU-1 (decision Q-5 du directeur, 05/10/2026) :
// le drapeau du pays de l'enseignant est une image embarquee (flag-icons,
// MIT), la meme sur toutes les plateformes. Trois cartes representatives
// (tuteur : catalogue « Choisir une classe » ; controleur : mission ;
// administration : Comptes), a 390, 1440 et 320 texte x2, clair et sombre,
// **plateforme Windows simulee** : celle ou les drapeaux emoji ne
// s'affichaient pas.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// ensdrapeau1_<ecran>_<largeur>_<mode>.png.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';

import '../features/ens_pays1/support_ens_pays1.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 1, '390'),
  (Size(1440, 900), 1, '1440'),
  (Size(320, 700), 2, '320x2'),
];

const Set<String> _cartes = <String>{
  'tuteur_catalogue',
  'controleur_mission',
  'admin_comptes',
};

void main() {
  group('Capture : ENS-DRAPEAU-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final EcranPays e in ecransPays().where(
      (EcranPays e) => _cartes.contains(e.nom),
    )) {
      for (final (Size cadre, double echelle, String nom) in _cadres) {
        final Size taille = echelle > 1 ? Size(320, e.hauteur320) : cadre;
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          final String fichier = 'ensdrapeau1_${e.nom}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            debugDefaultTargetPlatformOverride = TargetPlatform.windows;
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(hotePays(e, theme: mode, echelle: echelle));
            await stabiliser(tester);
            if (e.toucher != null) {
              await tester.tap(find.text(e.toucher!).first);
              await stabiliser(tester);
            }
            await montrerPays(tester);
            await chargerDrapeaux(tester);
            tester.takeException();
            expect(
              rectangleVisibleDuPays(tester, taille),
              isNotNull,
              reason: '$fichier : ligne du pays hors de la vue',
            );
            expect(
              find.byKey(PaysEnseignant.drapeauKey),
              findsWidgets,
              reason: '$fichier : drapeau absent',
            );
            debugPrint('PNG ${await capturer(tester, fichier)}');
            debugDefaultTargetPlatformOverride = null;
          });
        }
      }
    }
  });
}
