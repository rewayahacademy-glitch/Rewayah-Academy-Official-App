// Captures de la coque admin (SANS-BARRE-FIXE, decision (i) du pilote, 07/11) :
// la tuile des dossiers de l'accueil direction a 320x640 et 1440x900, avant et
// apres le correctif de tuiles_compteur.dart. PHASE=avant ou apres nomme les
// fichiers.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Donnees : demonstration admin, aucune personne reelle.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_tableau/tuiles_compteur.dart';

import '../support/demo/dossiers_demo.dart';
import '../support/demo/mode_demonstration.dart';
import '../support/demo/repere_demonstration.dart';
import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

Future<void> _stab(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Capture : tuile des dossiers, coque admin', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final Size taille in <Size>[
      const Size(320, 640),
      const Size(1440, 900),
    ]) {
      testWidgets('${taille.width.toInt()}', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1);
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: surchargesDemoAdmin(
              environnement: 'staging',
              etat: EtatRevueDemo.initial(
                superAdmin: true,
                politiqueGenre: true,
              ),
            ),
            child: TranslationProvider(
              child: RepaintBoundary(
                key: cadreCapture,
                child: RewayahApp(
                  builder: (BuildContext context, Widget? child) =>
                      RepereDemonstration(child: child),
                ),
              ),
            ),
          ),
        );
        await _stab(tester);
        ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
            .read<GoRouter>(routeurProvider)
            .go(Routes.admin);
        await _stab(tester);
        final String l = '${taille.width.toInt()}x${taille.height.toInt()}';
        debugPrint('PNG ${await capturer(tester, 'bento_${_phase}_$l')}');
        await tester.ensureVisible(find.byType(TuileCompteur).first);
        await _stab(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'bento_${_phase}_${l}_tuile')}',
        );
      });
    }
  });
}
