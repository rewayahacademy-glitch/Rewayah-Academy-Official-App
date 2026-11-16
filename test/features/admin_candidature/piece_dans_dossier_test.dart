// PIECE-DANS-DOSSIER (directeur, 16/11/2026) : la piece d'identite d'un candidat
// de la Salle d'examen se voit dans sa rubrique, sans impasse.
//
// Ce que le test prouve : la piece deposee hors de la file « Fichiers a
// valider » (ou la revue sur place ne la retrouve pas) s'affiche en vignette ;
// un toucher l'ouvre en grand ; aucun lien vers la liste de tous les fichiers ;
// la pastille dit la verite (a voir si deposee, bonne si validee, manquante
// seulement sans piece) ; Valider et Refuser ne sont pas rendus (une phrase dit
// ou la piece se decide).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/piece_candidature.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/piece_vignette.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart'
    show imagePieceProvider;

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
import 'hote_candidature.dart';

class _Signature implements ServiceValidation {
  final List<String> demandes = <String>[];

  @override
  Future<String> apercu(String documentId) async {
    demandes.add(documentId);
    return 'https://pieces.exemple/$documentId.jpg';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Un pixel PNG valide : l'image se decode.
final List<int> _pixel = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

Future<_Signature> _monter(
  WidgetTester tester,
  PieceCandidature? piece, {
  EtatPiece? etatDuDossier,
  List<ControleCandidature>? controles,
}) async {
  final _Signature signature = _Signature();
  final DetailCandidature detail = detailTest(
    piece: etatDuDossier,
    controles: controles,
  );
  await monterCandidature(
    tester,
    port: FauxCandidaturesDirection(
      capacitesRendues: capacitesGestes,
      details: <DetailCandidature>[detail],
    ),
    surcharges: <Override>[
      lirePieceCandidatureProvider.overrideWithValue((String _) async => piece),
      serviceValidationProvider.overrideWithValue(signature),
      imagePieceProvider.overrideWithValue(
        (Uri _) => MemoryImage(Uint8List.fromList(_pixel)),
      ),
    ],
    ouvrirRubriques: false,
  );
  await laisser(tester);
  return signature;
}

String _pastille(WidgetTester tester) => (tester.widget(
  find.byKey(RubriqueDossier.clePastille(RubriqueDossierCode.piece)),
) as StatusPill).libelle;

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  final p = t.recrutement.dossier3.pastille;
  const PieceCandidature deposee = PieceCandidature(
    statut: StatutPieceCandidature.enAttente,
    profilId: 'p1',
    documentId: 'doc1',
  );

  group('la piece deposee, hors de la file', () {
    testWidgets('elle s\'affiche en vignette, signee par son document', (
      WidgetTester tester,
    ) async {
      final _Signature signature = await _monter(tester, deposee);
      expect(find.byKey(PieceVignette.cle), findsOneWidget);
      expect(find.byKey(PieceVignette.cleImage), findsOneWidget);
      expect(signature.demandes, <String>['doc1']);
    });

    testWidgets('un toucher l\'ouvre en grand, sans bouton « voir en grand »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, deposee);
      expect(find.byKey(EtageUnDossier.clePhotoEnGrand), findsNothing);
      await tester.ensureVisible(find.byKey(PieceVignette.cleImage));
      await laisser(tester, fois: 2);
      await tester.tap(find.byKey(PieceVignette.cleImage), warnIfMissed: false);
      await laisser(tester);
      expect(find.byKey(EtageUnDossier.clePhotoEnGrand), findsOneWidget);
    });

    testWidgets('aucun lien vers la liste de tous les fichiers', (
      WidgetTester tester,
    ) async {
      await _monter(tester, deposee);
      expect(
        find.text(t.admin.candidatures.detail.ouvrirDossier),
        findsNothing,
      );
    });

    testWidgets('Valider et Refuser ne sont pas rendus : une phrase dit où', (
      WidgetTester tester,
    ) async {
      await _monter(tester, deposee);
      expect(find.byKey(PieceVignette.cleDecision), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.detail.pieceDecisionPlusTard),
        findsOneWidget,
      );
    });

    testWidgets('« Demander une nouvelle pièce » reste en lien secondaire', (
      WidgetTester tester,
    ) async {
      await _monter(tester, deposee);
      expect(
        find.byKey(const ValueKey<String>('rubrique-demander-piece_identite')),
        findsOneWidget,
      );
    });
  });

  group('la pastille dit la verite', () {
    testWidgets('deposee et pas validee : « a voir », jamais « manquante »', (
      WidgetTester tester,
    ) async {
      // Le dossier ne porte pas l'etat de la piece et son controle est faux :
      // l'ancienne pastille disait « manquante » alors que la ligne disait
      // « deposee ».
      await _monter(
        tester,
        deposee,
        controles: const <ControleCandidature>[
          ControleCandidature(nom: 'piece_validee', valeur: false),
        ],
      );
      expect(_pastille(tester), p.aVoir);
      expect(_pastille(tester), isNot(p.manque));
    });

    testWidgets('validee : « bon »', (WidgetTester tester) async {
      await _monter(
        tester,
        const PieceCandidature(
          statut: StatutPieceCandidature.validee,
          profilId: 'p1',
          documentId: 'doc1',
        ),
        controles: const <ControleCandidature>[
          ControleCandidature(nom: 'piece_validee', valeur: false),
        ],
      );
      expect(_pastille(tester), p.bon);
    });

    testWidgets('aucune piece deposee : « manquante »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const PieceCandidature(
          statut: StatutPieceCandidature.aDeposer,
          profilId: 'p1',
        ),
      );
      expect(_pastille(tester), p.manque);
    });

    testWidgets(
      'etat inconnu et controle faux : pas de pastille « manquante »',
      (WidgetTester tester) async {
        await _monter(
          tester,
          null,
          controles: const <ControleCandidature>[
            ControleCandidature(nom: 'piece_validee', valeur: false),
          ],
        );
        expect(
          find.byKey(RubriqueDossier.clePastille(RubriqueDossierCode.piece)),
          findsNothing,
        );
      },
    );
  });
}
