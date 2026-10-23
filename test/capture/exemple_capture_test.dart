// Exemple d'emploi de l'outil de capture (voir LISEZ-MOI.md du meme dossier).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/ecran_resultat.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import 'outil_capture.dart';

/// Une maquette a comparer, facultative (chemin d'un PNG).
final String? _maquette = Platform.environment['CAPTURE_MAQUETTE'];

/// La largeur logique de la maquette : 390 (telephone) par defaut, 1440 pour
/// un bureau.
final double _largeurLogique =
    double.tryParse(Platform.environment['CAPTURE_LARGEUR_LOGIQUE'] ?? '') ??
    390;

/// L'ecran de l'exemple : un ecran resultat, tel qu'une page le poserait.
Widget _ecran() => const Scaffold(
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: EcranResultat(
        icone: AppIcons.succes,
        titre: 'Appareil connecté',
        phrase: 'Le profil peut maintenant se connecter sur cet appareil.',
        encart: 'Vous pourrez retirer cet appareil depuis le Foyer.',
        ton: TonEtat.succes,
        libelleAction: 'Revenir au foyer',
        onAction: _rien,
        libelleSecondaire: 'Connecter un autre appareil',
        onSecondaire: _rien,
      ),
    ),
  ),
);

void _rien() {}

void main() {
  group('Capture : exemple, ecran resultat', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      final double corps = largeurSonde('PlusJakartaSans');
      final double titre = largeurSonde('DMSans');
      final double inconnue = largeurSonde('FamilleInexistante');
      debugPrint('SONDE : corps=$corps titre=$titre inconnue=$inconnue');
      expect(corps, lessThan(inconnue * 0.6));
      expect(titre, lessThan(inconnue * 0.6));
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('390x844 @3, ${mode.name}', (WidgetTester tester) async {
        fixerVueCapture(
          tester,
          const Size(390, 844),
          3,
          zoneSure: const EdgeInsets.only(top: 47, bottom: 34),
        );
        await tester.pumpWidget(hoteCapture(_ecran(), themeMode: mode));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'exemple_resultat_390x844@3_${mode.name}')}',
        );
      });
    }

    testWidgets('390x844 @3, texte a 200 %', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(hoteCapture(_ecran(), echelleTexte: 2));
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'exemple_resultat_390x844@3_texte200')}',
      );
    });

    testWidgets(
      'maquette | capture, cote a cote (CAPTURE_MAQUETTE)',
      skip: _maquette == null,
      (WidgetTester tester) async {
        final String maquette = _maquette!;
        late final int largeurPx;
        late final int hauteurPx;
        await tester.runAsync(() async {
          final ui.Codec codec = await ui.instantiateImageCodec(
            await File(maquette).readAsBytes(),
          );
          final ui.Image image = (await codec.getNextFrame()).image;
          largeurPx = image.width;
          hauteurPx = image.height;
          image.dispose();
        });
        fixerVueMaquette(
          tester,
          largeurPx: largeurPx,
          hauteurPx: hauteurPx,
          largeurLogique: _largeurLogique,
        );
        await tester.pumpWidget(hoteCapture(_ecran()));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerEtComparer(tester, 'exemple_resultat_contre_maquette', maquette)}',
        );
      },
    );
  });
}
