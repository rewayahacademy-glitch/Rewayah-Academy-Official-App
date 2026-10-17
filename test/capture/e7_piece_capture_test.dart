// Lot E7 : captures de preuve de la piece d'identite, avant et apres
// (variable `PHASE`, par defaut `apres`). Ecran a l'ouverture, puis type
// choisi, 390 x 844 et 1440 x 900, clair. Jamais sans `CAPTURE_DIR`.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

Future<void> _monter(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attentePiece,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attentePiece,
          builder: (BuildContext _, GoRouterState _) => const DepotPiecePage(),
        ),
        GoRoute(
          path: Routes.attente,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('portail')),
        ),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        selecteurFichierProvider.overrideWithValue(
          FauxSelecteurFichier(
            PieceAEnvoyer(
              octets: Uint8List(1024),
              nomFichier: 'piece.webp',
              type: TypePiece.passeport,
            ),
          ),
        ),
      ],
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture : lot E7', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      final String s = '${taille.width.toInt()}x${taille.height.toInt()}';

      testWidgets('piece $s', (WidgetTester tester) async {
        await _monter(tester, taille);
        debugPrint(
          'PNG ${await capturerVue(tester, '${_phase}_piece_ouverture_$s')}',
        );
        final Finder passeport = find.text(t.kyc.passeport);
        await tester.ensureVisible(passeport);
        await stabiliser(tester);
        await tester.tap(passeport);
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, '${_phase}_piece_type_$s')}',
        );
        await tester.tap(find.text(t.kyc.choisirFichier));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, '${_phase}_piece_photo_$s')}',
        );
      });
    }
  });
}
