// PIECE-DANS-DOSSIER (16/11/2026) : la rubrique « Piece d'identite » d'un
// candidat de la Salle d'examen, 360, francais et arabe : pastille « a voir »,
// vignette de la piece deposee, phrase sur la decision. Donnees fictives. Saute
// sans CAPTURE_DIR.

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/piece_candidature.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart'
    show imagePieceProvider;

import '../features/admin_candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/monter_recrutement.dart' show laisser;
import 'outil_capture.dart';

class _Signature implements ServiceValidation {
  _Signature(this.extension);

  final String extension;

  @override
  Future<String> apercu(String documentId) async =>
      'https://pieces.exemple/$documentId.$extension?signature=abc';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Un faux document d'identite : un rectangle de papier, sans donnee reelle.
Future<ImageProvider<Object>> _faussePiece() async {
  final PictureRecorder enregistreur = PictureRecorder();
  final Canvas toile = Canvas(enregistreur);
  toile.drawRect(
    const Rect.fromLTWH(0, 0, 340, 214),
    Paint()..color = const Color(0xFFEDE7F6),
  );
  toile.drawCircle(
    const Offset(70, 100),
    40,
    Paint()..color = const Color(0xFFB39DDB),
  );
  for (int i = 0; i < 4; i++) {
    toile.drawRect(
      Rect.fromLTWH(140, 50.0 + i * 32, 170, 14),
      Paint()..color = const Color(0xFFD1C4E9),
    );
  }
  final image = await enregistreur.endRecording().toImage(340, 214);
  final ByteData? octets = await image.toByteData(format: ImageByteFormat.png);
  return MemoryImage(octets!.buffer.asUint8List());
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PIECE-DANS-DOSSIER : captures', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue, String extension)
        in <(String, AppLocale, String)>[
          ('fr', AppLocale.fr, 'jpg'),
          ('ar', AppLocale.ar, 'jpg'),
          ('fr_pdf', AppLocale.fr, 'pdf'),
          ('ar_pdf', AppLocale.ar, 'pdf'),
        ]) {
      testWidgets('360 $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        late ImageProvider<Object> piece;
        await tester.runAsync(() async => piece = await _faussePiece());
        await monterCandidature(
          tester,
          port: FauxCandidaturesDirection(
            capacitesRendues: capacitesGestes,
            details: <DetailCandidature>[
              detailTest(
                controles: const <ControleCandidature>[
                  ControleCandidature(nom: 'piece_validee', valeur: false),
                ],
              ),
            ],
          ),
          surcharges: <Override>[
            lirePieceCandidatureProvider.overrideWithValue(
              (String _) async => const PieceCandidature(
                statut: StatutPieceCandidature.enAttente,
                profilId: 'p1',
                documentId: 'doc1',
              ),
            ),
            serviceValidationProvider.overrideWithValue(_Signature(extension)),
            imagePieceProvider.overrideWithValue((Uri _) => piece),
          ],
          largeur: 360,
          hauteur: 800,
          direction: langue == AppLocale.ar ? TextDirection.rtl : null,
          ouvrirRubriques: false,
        );
        await laisser(tester);
        await tester.ensureVisible(
          find.byKey(RubriqueDossier.cleDe(RubriqueDossierCode.piece)),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await laisser(tester);
        await capturerVue(tester, 'PIECE-DANS-DOSSIER/piece_${nom}_360');
      });
    }
  });
}
