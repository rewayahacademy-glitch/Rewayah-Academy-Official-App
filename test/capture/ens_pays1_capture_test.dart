// Captures de recette ENS-PAYS-1 : le pays de l'enseignant sur sa carte,
// pour chaque role (tuteur, eleve enfant, eleve adulte, Mode Accessibilite,
// controleur, administration), a 390 et 1440 clair et sombre, et 320 texte
// x2. Vrais ecrans, donnees de demonstration ou faux services.
//
// La police d'emoji de la machine (Noto Color Emoji, celle de Flutter Web et
// d'Android) est chargee : c'est le rendu d'un appareil qui sait dessiner le
// drapeau. Le rendu sans drapeau (Chrome ou Edge sous Windows) est capture a
// part par `ens_pays1_sans_drapeau_capture_test.dart`.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// enspays1_<role>_<ecran>_<largeur>_<mode>.png.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/ens_pays1/support_ens_pays1.dart';
import 'outil_capture.dart';

const String _policeEmoji = '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 1, '390'),
  (Size(1440, 900), 1, '1440'),
  (Size(320, 700), 2, '320x2'),
];

void main() {
  group('Capture : ENS-PAYS-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      if (File(_policeEmoji).existsSync()) {
        final FontLoader emoji = FontLoader('Noto Color Emoji')
          ..addFont(
            Future<ByteData>.value(
              ByteData.sublistView(File(_policeEmoji).readAsBytesSync()),
            ),
          );
        await emoji.load();
      }
    });

    for (final EcranPays e in ecransPays()) {
      for (final (Size taille, double echelle, String nom) in _cadres) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          // 320 x2 : clair seulement (la mise en page ne change pas de theme).
          if (echelle > 1 && mode == ThemeMode.dark) continue;
          final String fichier = 'enspays1_${e.nom}_${nom}_${mode.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(hotePays(e, theme: mode, echelle: echelle));
            await stabiliser(tester);
            if (e.toucher != null) {
              await tester.tap(find.text(e.toucher!).first);
              await stabiliser(tester);
            }
            tester.takeException();
            debugPrint('PNG ${await capturer(tester, fichier)}');
          });
        }
      }
    }
  });
}
