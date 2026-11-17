import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/piece_candidature.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/piece_decision.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart'
    show imagePieceProvider;

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
import 'hote_candidature.dart';

// PIECE-SUR-LA-FICHE : captures R3 (fr et ar, 360 px). Ne tourne que sur demande :
//   CAPTURE_R3=1 flutter test test/features/admin_candidature/piece_sur_la_fiche_captures_test.dart
// Les polices du depot sont chargees (sinon le texte serait des carres).

class _Signature implements ServiceValidation {
  @override
  Future<String> apercu(String documentId) async =>
      'https://pieces.exemple/$documentId.jpg?signature=abc';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final List<int> _pixel = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

Future<void> _polices() async {
  final List<Object?> familles = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final Object? entree in familles) {
    final Map<String, Object?> famille = entree! as Map<String, Object?>;
    final FontLoader chargeur = FontLoader(famille['family']! as String);
    for (final Object? f in famille['fonts']! as List<Object?>) {
      chargeur.addFont(
        rootBundle.load((f! as Map<String, Object?>)['asset']! as String),
      );
    }
    await chargeur.load();
  }
}

Future<void> _capturer(WidgetTester tester, String nom) async {
  final RenderRepaintBoundary frontiere = tester.renderObject(
    find.byType(RepaintBoundary).first,
  ) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await frontiere.toImage(pixelRatio: 2);
    final ByteData? octets = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final File f = File('docs/current/captures/E2E/PIECE-SUR-LA-FICHE/$nom.png')
      ..createSync(recursive: true);
    f.writeAsBytesSync(octets!.buffer.asUint8List());
  });
}

Future<void> _monter(WidgetTester tester, {required bool ar}) async {
  await monterCandidature(
    tester,
    port: FauxCandidaturesDirection(
      capacitesRendues: CapacitesCandidatures(
        peutLire: true,
        peutVoirContact: true,
        genreLecteurConnu: true,
        peutDecider: true,
        gestes: <String, bool>{...capacitesGestes.gestes, 'deciderPiece': true},
        listes: capacitesGestes.listes,
      ),
      details: <DetailCandidature>[detailTest()],
    ),
    surcharges: <Override>[
      lirePieceCandidatureProvider.overrideWithValue(
        (String _) async => const PieceCandidature(
          statut: StatutPieceCandidature.enAttente,
          profilId: 'p1',
          documentId: 'doc1',
          genre: GenreFichierPiece.image,
        ),
      ),
      serviceValidationProvider.overrideWithValue(_Signature()),
      deciderPieceProvider.overrideWithValue(
        ({
          required String documentId,
          required bool approuve,
          String? motif,
        }) async {},
      ),
      imagePieceProvider.overrideWithValue(
        (Uri _) => MemoryImage(Uint8List.fromList(_pixel)),
      ),
    ],
    largeur: 360,
    hauteur: 2600,
    direction: ar ? TextDirection.rtl : TextDirection.ltr,
    ouvrirRubriques: false,
  );
  await laisser(tester);
  final Finder piece = find.byKey(DecisionPiece.cleValider);
  await tester.ensureVisible(piece);
  await tester.pump();
}

void main() {
  final bool actif = Platform.environment['CAPTURE_R3'] == '1';
  setUpAll(() async {
    await _polices();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  for (final bool ar in <bool>[false, true]) {
    final String lg = ar ? 'ar' : 'fr';
    testWidgets('capture $lg', (WidgetTester tester) async {
      await LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr);
      await _monter(tester, ar: ar);
      await _capturer(tester, 'piece-valider-$lg-360');
      await tester.tap(find.byKey(DecisionPiece.cleRefuser));
      await laisser(tester);
      await tester.tap(find.byKey(DecisionPiece.cleConfirmerRefus));
      await laisser(tester);
      await _capturer(tester, 'piece-refuser-motif-vide-$lg-360');
    }, skip: !actif);
  }
}
