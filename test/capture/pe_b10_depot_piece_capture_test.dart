// PE-B10 : captures de preuve du depot de la piece. Trois etats (en cours,
// echoue par cause), en francais et en arabe (de droite a gauche), 390 x 844
// et 1440 x 900, clair. Jamais sans `CAPTURE_DIR`.

import 'dart:async';
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
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

Future<FauxServiceDossier> _monter(
  WidgetTester tester,
  Size taille,
  TextDirection sens,
) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceDossier dossier = FauxServiceDossier();
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attentePiece,
      direction: sens,
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
        serviceDossierProvider.overrideWithValue(dossier),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        selecteurFichierProvider.overrideWithValue(
          FauxSelecteurFichier(
            PieceAEnvoyer(
              octets: Uint8List.fromList(<int>[
                0x89,
                0x50,
                0x4e,
                0x47,
                0x0d,
                0x0a,
                0x1a,
                0x0a,
                ...List<int>.filled(1016, 0),
              ]),
              nomFichier: 'piece.png',
              type: TypePiece.passeport,
            ),
          ),
        ),
      ],
    ),
  );
  await stabiliser(tester);
  return dossier;
}

Future<void> _choisir(WidgetTester tester) async {
  final Finder passeport = find.text(t.kyc.passeport);
  await tester.ensureVisible(passeport);
  await stabiliser(tester);
  await tester.tap(passeport);
  await stabiliser(tester);
  await tester.tap(find.text(t.kyc.choisirFichier));
  await stabiliser(tester);
}

Future<void> _envoyer(WidgetTester tester) async {
  final Finder envoyer = find.text(t.kyc.envoyer);
  await tester.ensureVisible(envoyer);
  await stabiliser(tester);
  await tester.tap(envoyer);
  await stabiliser(tester);
}

void main() {
  group('Capture : PE-B10', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final (AppLocale langue, TextDirection sens)
        in <(AppLocale, TextDirection)>[
          (AppLocale.fr, TextDirection.ltr),
          (AppLocale.ar, TextDirection.rtl),
        ]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String s =
            '${langue.languageCode}_${taille.width.toInt()}x${taille.height.toInt()}';

        testWidgets('en cours $s', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
          final FauxServiceDossier dossier = await _monter(
            tester,
            taille,
            sens,
          );
          final Completer<void> fin = Completer<void>();
          dossier.depotEnAttente = fin.future;
          await _choisir(tester);
          await _envoyer(tester);
          await tester.ensureVisible(find.byKey(DepotPiecePage.cleEnCours));
          await stabiliser(tester);
          debugPrint('PNG ${await capturerVue(tester, 'pe_b10_en_cours_$s')}');
          fin.complete();
          await stabiliser(tester);
        });

        for (final (String nom, Object erreur) in <(String, Object)>[
          ('indisponible', const StorageException('x', statusCode: '544')),
          ('session', const FunctionException(status: 401)),
        ]) {
          testWidgets('echec $nom $s', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
            final FauxServiceDossier dossier = await _monter(
              tester,
              taille,
              sens,
            );
            dossier.erreurAJeter = erreur;
            await _choisir(tester);
            await _envoyer(tester);
            await tester.ensureVisible(find.byKey(DepotPiecePage.cleEchec));
            await stabiliser(tester);
            debugPrint(
              'PNG ${await capturerVue(tester, 'pe_b10_echec_${nom}_$s')}',
            );
          });
        }
      }
    }
  });
}
