// CAND-L1B : captures de l'ecran de la piece avant l'envoi de la candidature
// (la phrase et le retour au dossier) et du refus du serveur dit par sa cause,
// en francais et en arabe, 390 x 844 et 1440 x 900, clair. Donnees de test
// seulement. Jamais sans `CAPTURE_DIR`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

EtatDossier _etat(EtapeCandidature etape) => EtatDossier(
  profilExiste: true,
  role: AppRole.teacher,
  statutCompte: AccountStatus.pendingKyc,
  candidature: CandidatureDossier(
    existe: true,
    etape: etape,
    etat: etape == EtapeCandidature.prequalification
        ? EtatCandidature.aCompleter
        : EtatCandidature.entretienAPlanifier,
  ),
);

Future<FauxServiceDossier> _monter(
  WidgetTester tester,
  Size taille,
  EtatDossier etat, {
  required bool arabe,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceDossier dossier = FauxServiceDossier()..etatRendu = etat;
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attentePiece,
      direction: arabe ? TextDirection.rtl : null,
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
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
        selecteurFichierProvider.overrideWithValue(
          FauxSelecteurFichier(
            PieceAEnvoyer(
              octets: Uint8List.fromList(<int>[
                0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
                ...List<int>.filled(1016, 0),
              ]),
              nomFichier: 'piece.png',
              type: TypePiece.carteIdentite,
            ),
          ),
        ),
        baseLocaleEnMemoire(),
      ],
    ),
  );
  await stabiliser(tester);
  return dossier;
}

void main() {
  group('Capture : piece avant l\'envoi (CAND-L1B)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final bool arabe in <bool>[false, true]) {
      final String langue = arabe ? 'ar' : 'fr';
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String s = '${taille.width.toInt()}x${taille.height.toInt()}';

        testWidgets('avant l\'envoi, $langue $s', (WidgetTester tester) async {
          await tester.runAsync(
            () => LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
          );
          addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
          await _monter(
            tester,
            taille,
            _etat(EtapeCandidature.prequalification),
            arabe: arabe,
          );
          debugPrint(
            'PNG ${await capturerVue(tester, 'avant_envoi_${langue}_$s')}',
          );
        });
      }

      testWidgets('refus du serveur, $langue 390x844', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(
          () => LocaleSettings.setLocale(arabe ? AppLocale.ar : AppLocale.fr),
        );
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        final FauxServiceDossier dossier = await _monter(
          tester,
          const Size(390, 844),
          _etat(EtapeCandidature.verifications),
          arabe: arabe,
        );
        dossier.erreurAJeter = const PostgrestException(
          message: 'refus',
          code: '42501',
          details:
              'CAND-L1B : la piece d\'un compte candidat se depose en Salle '
              'de verification et d\'entretien (candidature en cours) ou apres',
        );
        await tester.tap(find.text(t.kyc.carteIdentite));
        await stabiliser(tester);
        await tester.tap(find.text(t.kyc.choisirFichier));
        await stabiliser(tester);
        await tester.tap(find.text(t.kyc.envoyer));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturerVue(tester, 'refus_${langue}_390x844')}',
        );
      });
    }
  });
}
