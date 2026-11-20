// PIECE-DANS-DOSSIER (directeur, 16/11/2026) : la piece d'identite d'un candidat
// de la Salle d'examen se voit dans sa rubrique, sans impasse.
//
// Ce que le test prouve : la piece deposee hors de la file « Fichiers a
// valider » (ou la revue sur place ne la retrouve pas) s'affiche en vignette ;
// un toucher l'ouvre en grand ; aucun lien vers la liste de tous les fichiers ;
// la pastille dit la verite (a voir si deposee, bonne si validee, manquante
// seulement sans piece) ; Valider et Refuser ne sont pas rendus (une phrase dit
// ou la piece se decide).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/piece_candidature.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/fichiers/ouvrir_onglet.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/piece_decision.dart';
import 'package:rewayah_academy/features/admin_candidature/piece_vignette.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart'
    show imagePieceProvider;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart' show laisser;
import 'hote_candidature.dart';

class _Signature implements ServiceValidation {
  _Signature({this.extension = 'jpg'});

  final String extension;
  final List<String> demandes = <String>[];

  @override
  Future<String> apercu(String documentId) async {
    demandes.add(documentId);
    return 'https://pieces.exemple/$documentId.$extension?signature=abc';
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
  String extension = 'jpg',
  List<Uri>? ouverts,
  bool imageIllisible = false,
  EtatPiece? etatDuDossier,
  List<ControleCandidature>? controles,
  Future<void> Function({
    required String documentId,
    required bool approuve,
    String? motif,
  })?
  decider,
  CapacitesCandidatures? capacites,
}) async {
  final _Signature signature = _Signature(extension: extension);
  final DetailCandidature detail = detailTest(
    piece: etatDuDossier,
    controles: controles,
  );
  await monterCandidature(
    tester,
    port: FauxCandidaturesDirection(
      capacitesRendues: capacites ?? capacitesGestes,
      details: <DetailCandidature>[detail],
    ),
    surcharges: <Override>[
      lirePieceCandidatureProvider.overrideWithValue((String _) async => piece),
      serviceValidationProvider.overrideWithValue(signature),
      if (decider != null) deciderPieceProvider.overrideWithValue(decider),
      if (ouverts != null)
        ouvreurOngletProvider.overrideWithValue((Uri u) async {
          ouverts.add(u);
          return true;
        }),
      imagePieceProvider.overrideWithValue(
        (Uri _) => MemoryImage(
          // Des octets qui ne sont pas une image : l'ecran ne l'affiche pas.
          imageIllisible
              ? Uint8List.fromList(<int>[1, 2, 3])
              : Uint8List.fromList(_pixel),
        ),
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

/// La direction : la capacite serveur `gestes.deciderPiece` est vraie.
final CapacitesCandidatures _direction = CapacitesCandidatures(
  peutLire: true,
  peutVoirContact: true,
  genreLecteurConnu: true,
  peutDecider: true,
  gestes: <String, bool>{...capacitesGestes.gestes, 'deciderPiece': true},
  listes: capacitesGestes.listes,
);

/// Un porteur de mission : il decide de gestes (dont `validerPiece`), jamais de
/// la piece : la cle `deciderPiece` est absente.
final CapacitesCandidatures _porteurDeMission = CapacitesCandidatures(
  peutLire: true,
  peutVoirContact: true,
  genreLecteurConnu: true,
  peutDecider: true,
  gestes: <String, bool>{...capacitesGestes.gestes, 'validerPiece': true},
  listes: capacitesGestes.listes,
);

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
    genre: GenreFichierPiece.image,
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

    testWidgets(
      'une image : l\'icone « Image » est cliquable et ouvre en grand',
      (WidgetTester tester) async {
        await _monter(tester, deposee);
        expect(find.byKey(PieceVignette.cleIcone), findsOneWidget);
        expect(
          find.text(t.admin.candidatures.detail.pieceImage),
          findsOneWidget,
        );
        await tester.ensureVisible(find.byKey(PieceVignette.cleIcone));
        await laisser(tester, fois: 2);
        await tester.tap(
          find.byKey(PieceVignette.cleIcone),
          warnIfMissed: false,
        );
        await laisser(tester);
        expect(find.byKey(EtageUnDossier.clePhotoEnGrand), findsOneWidget);
      },
    );

    testWidgets('un PDF : l\'icone « PDF » s\'affiche et un toucher l\'ouvre', (
      WidgetTester tester,
    ) async {
      final List<Uri> ouverts = <Uri>[];
      await _monter(
        tester,
        const PieceCandidature(
          statut: StatutPieceCandidature.enAttente,
          profilId: 'p1',
          documentId: 'doc1',
          genre: GenreFichierPiece.pdf,
        ),
        extension: 'sansext',
        ouverts: ouverts,
      );
      expect(find.byKey(PieceVignette.cleImage), findsNothing);
      expect(find.byKey(PieceVignette.cleIcone), findsOneWidget);
      expect(find.text(t.admin.candidatures.detail.piecePdf), findsOneWidget);
      expect(find.text(t.admin.candidatures.detail.pieceImage), findsNothing);
      await tester.ensureVisible(find.byKey(PieceVignette.cleIcone));
      await laisser(tester, fois: 2);
      await tester.tap(find.byKey(PieceVignette.cleIcone), warnIfMissed: false);
      await laisser(tester);
      expect(ouverts, hasLength(1));
      expect(ouverts.single.path, endsWith('doc1.sansext'));
    });

    testWidgets(
      'une image que l\'ecran n\'affiche pas : icone cliquable, jamais '
      'un simple « non lisible »',
      (WidgetTester tester) async {
        final List<Uri> ouverts = <Uri>[];
        await _monter(tester, deposee, ouverts: ouverts, imageIllisible: true);
        await laisser(tester);
        expect(find.byKey(PieceVignette.cleIconeIllisible), findsOneWidget);
        expect(find.byKey(PieceVignette.cleEchec), findsOneWidget);
        await tester.ensureVisible(find.byKey(PieceVignette.cleIconeIllisible));
        await laisser(tester, fois: 2);
        await tester.tap(
          find.byKey(PieceVignette.cleIconeIllisible),
          warnIfMissed: false,
        );
        await laisser(tester);
        expect(ouverts, hasLength(1));
      },
    );

    test('le genre vient du serveur, jamais de l\'adresse', () {
      GenreFichierPiece? genre(Object? v) => PieceCandidature.depuisJson(
        <String, Object?>{'statut': 'pending', 'genreFichier': v},
      )!.genre;
      expect(genre('pdf'), GenreFichierPiece.pdf);
      expect(genre('image'), GenreFichierPiece.image);
      expect(genre(null), isNull);
      expect(genre('video'), isNull);
      expect(
        PieceCandidature.depuisJson(<String, Object?>{
          'statut': 'pending',
          'typeContenu': 'image/heic',
        })!.typeContenu,
        'image/heic',
      );
    });

    testWidgets('type inconnu : tuile « Fichier », ouverte telle quelle', (
      WidgetTester tester,
    ) async {
      final List<Uri> ouverts = <Uri>[];
      await _monter(
        tester,
        const PieceCandidature(
          statut: StatutPieceCandidature.enAttente,
          profilId: 'p1',
          documentId: 'doc1',
        ),
        ouverts: ouverts,
      );
      expect(find.byKey(PieceVignette.cleImage), findsNothing);
      expect(find.byKey(PieceVignette.cleFichier), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.detail.pieceFichier),
        findsOneWidget,
      );
      expect(find.text(t.admin.candidatures.detail.pieceImage), findsNothing);
      expect(find.text(t.admin.candidatures.detail.piecePdf), findsNothing);
      await tester.ensureVisible(find.byKey(PieceVignette.cleFichier));
      await laisser(tester, fois: 2);
      await tester.tap(
        find.byKey(PieceVignette.cleFichier),
        warnIfMissed: false,
      );
      await laisser(tester);
      expect(ouverts, hasLength(1));
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

    testWidgets('sans la porte branchee, ni Valider ni Refuser', (
      WidgetTester tester,
    ) async {
      await _monter(tester, deposee, capacites: _direction);
      expect(find.byKey(DecisionPiece.cleValider), findsNothing);
      expect(find.byKey(DecisionPiece.cleRefuser), findsNothing);
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

  group('PIECE-SUR-LA-FICHE : decider la piece sur la fiche', () {
    final r = t.admin.candidatures.detail;

    testWidgets(
      'porteur de mission : aucun bouton (pas de capacite deciderPiece)',
      (WidgetTester tester) async {
        await _monter(
          tester,
          deposee,
          capacites: _porteurDeMission,
          decider: ({
            required String documentId,
            required bool approuve,
            String? motif,
          }) async {},
        );
        expect(find.byKey(PieceVignette.cle), findsOneWidget);
        expect(find.byKey(DecisionPiece.cleValider), findsNothing);
        expect(find.byKey(DecisionPiece.cleRefuser), findsNothing);
      },
    );

    testWidgets('direction : Valider et Refuser sont rendus', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        deposee,
        capacites: _direction,
        decider: ({
          required String documentId,
          required bool approuve,
          String? motif,
        }) async {},
      );
      expect(find.byKey(DecisionPiece.cleValider), findsOneWidget);
      expect(find.byKey(DecisionPiece.cleRefuser), findsOneWidget);
    });

    testWidgets('capacite sans branchement de la porte : aucun bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, deposee, capacites: _direction);
      expect(find.byKey(DecisionPiece.cleValider), findsNothing);
    });

    testWidgets('Valider appelle la porte avec le document', (
      WidgetTester tester,
    ) async {
      final List<(String, bool, String?)> appels = <(String, bool, String?)>[];
      await _monter(
        tester,
        deposee,
        capacites: _direction,
        decider: ({
          required String documentId,
          required bool approuve,
          String? motif,
        }) async => appels.add((documentId, approuve, motif)),
      );
      expect(find.byKey(DecisionPiece.cleValider), findsOneWidget);
      await tester.ensureVisible(find.byKey(DecisionPiece.cleValider));
      await tester.tap(find.byKey(DecisionPiece.cleValider));
      await laisser(tester);
      expect(appels, <(String, bool, String?)>[('doc1', true, null)]);
    });

    testWidgets('Refuser exige un motif, puis l\'envoie', (
      WidgetTester tester,
    ) async {
      final List<(String, bool, String?)> appels = <(String, bool, String?)>[];
      await _monter(
        tester,
        deposee,
        capacites: _direction,
        decider: ({
          required String documentId,
          required bool approuve,
          String? motif,
        }) async => appels.add((documentId, approuve, motif)),
      );
      await tester.ensureVisible(find.byKey(DecisionPiece.cleRefuser));
      await tester.tap(find.byKey(DecisionPiece.cleRefuser));
      await laisser(tester);
      await tester.ensureVisible(find.byKey(DecisionPiece.cleConfirmerRefus));
      await tester.tap(find.byKey(DecisionPiece.cleConfirmerRefus));
      await laisser(tester);
      expect(appels, isEmpty);
      expect(find.text(t.dossiers.refus.erreurVide), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(DecisionPiece.cleMotif),
          matching: find.byType(EditableText),
        ),
        'Photo floue',
      );
      await tester.ensureVisible(find.byKey(DecisionPiece.cleConfirmerRefus));
      await tester.tap(find.byKey(DecisionPiece.cleConfirmerRefus));
      await laisser(tester);
      expect(appels, <(String, bool, String?)>[('doc1', false, 'Photo floue')]);
    });

    testWidgets('un refus du serveur dit sa raison, jamais « connexion »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        deposee,
        capacites: _direction,
        decider:
            ({
              required String documentId,
              required bool approuve,
              String? motif,
            }) async =>
                throw const PostgrestException(message: 'dossier déjà décidé'),
      );
      await tester.ensureVisible(find.byKey(DecisionPiece.cleValider));
      await tester.tap(find.byKey(DecisionPiece.cleValider));
      await laisser(tester);
      expect(find.text(r.pieceDejaDecidee), findsOneWidget);
      expect(find.textContaining('connexion'), findsNothing);
    });

    testWidgets('une raison inconnue du serveur est citee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        deposee,
        capacites: _direction,
        decider:
            ({
              required String documentId,
              required bool approuve,
              String? motif,
            }) async =>
                throw const PostgrestException(message: 'raison inattendue'),
      );
      await tester.ensureVisible(find.byKey(DecisionPiece.cleValider));
      await tester.tap(find.byKey(DecisionPiece.cleValider));
      await laisser(tester);
      expect(find.textContaining('raison inattendue'), findsOneWidget);
    });

    // PE-D12 (bouton fige) : une reponse qui ne vient jamais ne laisse pas le
    // bouton en attente au-dela du delai maximal ; la phrase dit que le
    // resultat n'est pas confirme et qu'il faut verifier.
    testWidgets('sans reponse du serveur, le bouton se libere apres le delai', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        deposee,
        capacites: _direction,
        decider: ({
          required String documentId,
          required bool approuve,
          String? motif,
        }) => Completer<void>().future,
      );
      await tester.ensureVisible(find.byKey(DecisionPiece.cleValider));
      await tester.tap(find.byKey(DecisionPiece.cleValider));
      await tester.pump();
      bool enCours() => tester
          .widget<ActionPrincipale>(find.byKey(DecisionPiece.cleValider))
          .enCours;
      expect(enCours(), isTrue);
      await tester.pump(AppDelais.requeteMax - const Duration(seconds: 1));
      expect(enCours(), isTrue);
      await tester.pump(const Duration(seconds: 2));
      await laisser(tester);
      expect(enCours(), isFalse);
      expect(find.text(r.pieceNonConfirmee), findsOneWidget);
    });
  });
}
