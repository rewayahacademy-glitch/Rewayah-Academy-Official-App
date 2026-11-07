// CAND-L1B : la piece d'identite d'un candidat se depose apres l'envoi de sa
// candidature (Salle de verification et d'entretien ou apres), jamais avant. Le
// serveur la refuse avant (403, code 42501 sur kyc_documents). L'ecran s'aligne :
// avant l'envoi il ne propose pas le depot, il dit quand la piece viendra ; si
// le serveur refuse quand meme, il dit la vraie cause et donne une issue, jamais
// « Reessayez dans un instant » (K-59).
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/echec_depot.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/harnais.dart';

const Key _phrase = Key('piece-pas-encore');
const Key _retour = Key('piece-retour-dossier');

/// Un enseignant dont la candidature est a [etape] ; `null` : aucune candidature
/// (un enseignant d'avant la candidature, ou migre).
EtatDossier _etat(EtapeCandidature? etape) => EtatDossier(
  profilExiste: true,
  role: AppRole.teacher,
  statutCompte: AccountStatus.pendingKyc,
  candidature: etape == null
      ? CandidatureDossier.aucune
      : CandidatureDossier(
          existe: true,
          etape: etape,
          etat: etape == EtapeCandidature.prequalification
              ? EtatCandidature.aCompleter
              : EtatCandidature.entretienAPlanifier,
        ),
);

/// 1 024 octets qui commencent comme un PNG (la signature de ses huit octets).
Uint8List _entetePng(int taille) => Uint8List.fromList(<int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
  ...List<int>.filled(taille < 8 ? 0 : taille - 8, 0),
]);

PieceAEnvoyer _piece() => PieceAEnvoyer(
  octets: _entetePng(1024),
  nomFichier: 'piece.PNG',
  type: TypePiece.carteIdentite,
);

Future<FauxServiceDossier> _monter(
  WidgetTester tester,
  EtatDossier etat, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  ThemeMode themeMode = ThemeMode.light,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceDossier dossier = FauxServiceDossier()..etatRendu = etat;
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attentePiece,
      echelle: echelle,
      themeMode: themeMode,
      direction: direction,
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
        selecteurFichierProvider.overrideWithValue(
          FauxSelecteurFichier(_piece()),
        ),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
        baseLocaleEnMemoire(),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return dossier;
}

void _aucunFormulaire() {
  expect(find.text(t.kyc.carteIdentite), findsNothing);
  expect(find.text(t.kyc.choisirFichier), findsNothing);
  expect(find.text(t.kyc.envoyer), findsNothing);
}

void main() {
  group('avant l\'envoi de la candidature', () {
    testWidgets('la phrase dit quand la piece viendra, sans formulaire', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _etat(EtapeCandidature.prequalification));

      expect(find.byKey(_phrase), findsOneWidget);
      expect(find.text(t.kyc.pasEncore), findsOneWidget);
      _aucunFormulaire();
      // Une issue : le dossier.
      expect(find.byKey(_retour), findsOneWidget);
      await tester.tap(find.byKey(_retour));
      await tester.pumpAndSettle();
      expect(find.text('portail'), findsOneWidget);
    });

    for (final (String nom, Size taille, double echelle, ThemeMode mode) cas
        in <(String, Size, double, ThemeMode)>[
          ('320 px, texte x2', const Size(320, 640), 2, ThemeMode.light),
          ('390 px', const Size(390, 844), 1, ThemeMode.light),
          ('1440 px, sombre', const Size(1440, 900), 1, ThemeMode.dark),
        ]) {
      testWidgets('la phrase tient et l\'issue s\'atteint : ${cas.$1}', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          _etat(EtapeCandidature.prequalification),
          taille: cas.$2,
          echelle: cas.$3,
          themeMode: cas.$4,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(t.kyc.pasEncore), findsOneWidget);
        expect(find.byKey(_retour), findsOneWidget);
        // L'issue est dans l'ecran : pas sous la ligne de flottaison.
        final Rect issue = tester.getRect(find.byKey(_retour));
        expect(issue.bottom, lessThanOrEqualTo(cas.$2.height));
        expect(issue.left, greaterThanOrEqualTo(0));
        expect(issue.right, lessThanOrEqualTo(cas.$2.width));
      });
    }

    testWidgets('en arabe, la phrase et l\'issue sont arabes et tiennent', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
      await _monter(
        tester,
        _etat(EtapeCandidature.prequalification),
        direction: TextDirection.rtl,
        echelle: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(t.kyc.pasEncore), findsOneWidget);
      expect(t.kyc.pasEncore, contains('وثيقة هويتك'));
      expect(t.kyc.pasEncore, isNot(contains('Votre')));
      expect(find.byKey(_retour), findsOneWidget);
    });
  });

  group('la regle du serveur ne change rien ailleurs', () {
    testWidgets('en Salle de verification, le formulaire de la piece reste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _etat(EtapeCandidature.verifications));
      expect(find.byKey(_phrase), findsNothing);
      expect(find.text(t.kyc.carteIdentite), findsOneWidget);
    });

    testWidgets('un enseignant sans candidature depose sa piece comme avant', (
      WidgetTester tester,
    ) async {
      await _monter(tester, _etat(null));
      expect(find.byKey(_phrase), findsNothing);
      expect(find.text(t.kyc.carteIdentite), findsOneWidget);
    });
  });

  group('le serveur refuse quand meme (403, CAND-L1B)', () {
    testWidgets('la cause est dite, avec une issue, sans « Reessayez »', (
      WidgetTester tester,
    ) async {
      // La page est atteinte alors que l'etat lu est deja « en verification » ;
      // le serveur, lui, a un etat plus ancien et refuse.
      final FauxServiceDossier dossier = await _monter(
        tester,
        _etat(EtapeCandidature.verifications),
      );
      dossier.erreurAJeter = const PostgrestException(
        message: 'refus',
        code: '42501',
        details:
            'CAND-L1B : la piece d\'un compte candidat se depose en Salle '
            'de verification et d\'entretien (candidature en cours) ou apres',
      );

      await tester.tap(find.text(t.kyc.carteIdentite));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.envoyer));
      await tester.pumpAndSettle();

      expect(find.text(t.kyc.pasEncoreRefus), findsOneWidget);
      expect(find.text(t.kyc.erreur), findsNothing);
      expect(find.byKey(_retour), findsOneWidget);
      await tester.tap(find.byKey(_retour));
      await tester.pumpAndSettle();
      expect(find.text('portail'), findsOneWidget);
    });

    testWidgets('un autre refus 42501 garde la phrase generale', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = await _monter(
        tester,
        _etat(EtapeCandidature.verifications),
      );
      dossier.erreurAJeter = const PostgrestException(
        message: 'refus',
        code: '42501',
        details: 'autre regle',
      );
      await tester.tap(find.text(t.kyc.carteIdentite));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.envoyer));
      await tester.pumpAndSettle();

      expect(find.text(t.kyc.erreur), findsOneWidget);
      expect(find.byKey(_retour), findsNothing);
    });
  });

  group('causeEchecDepot', () {
    test('CAND-L1B est « pas encore », pas une panne', () {
      expect(
        causeEchecDepot(
          const PostgrestException(
            message: 'x',
            code: '42501',
            details: 'CAND-L1B : ...',
          ),
        ),
        CauseEchecDepot.pasEncore,
      );
    });

    test('un 42501 sans CAND-L1B reste « autre »', () {
      expect(
        causeEchecDepot(
          const PostgrestException(message: 'x', code: '42501', details: 'y'),
        ),
        CauseEchecDepot.autre,
      );
    });
  });

  group('CandidatureDossier.pieceApresEnvoi', () {
    test('vrai en Salle d\'examen seulement, candidature en cours', () {
      expect(
        _etat(EtapeCandidature.prequalification).candidature.pieceApresEnvoi,
        isTrue,
      );
      expect(
        _etat(EtapeCandidature.verifications).candidature.pieceApresEnvoi,
        isFalse,
      );
      expect(
        _etat(EtapeCandidature.confirmee).candidature.pieceApresEnvoi,
        isFalse,
      );
      expect(_etat(null).candidature.pieceApresEnvoi, isFalse);
    });
  });
}
