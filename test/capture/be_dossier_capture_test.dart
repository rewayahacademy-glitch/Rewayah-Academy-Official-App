// BE-DOSSIER (directeur, 16/11/2026) : captures du dossier en trois etages sur
// la VRAIE application et le vrai routeur en demonstration d'administration :
// telephone (360), ordinateur (1366), arabe de droite a gauche. Donnees
// fictives. Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/photo_dossier_candidat.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/demo/mode_demonstration.dart';
import 'outil_capture.dart';

class _Photo implements PortPhotoDossier {
  @override
  Future<PhotoDossier> lire(String candidatureId) async => PhotoDossier(
    seau: 'photos_enseignants',
    cle: 'p1/1.jpg',
    figeeLe: DateTime.utc(2026, 11, 7, 9, 30),
  );
}

class _Photos extends PhotosNeutres {
  const _Photos();

  @override
  Future<String> urlSignee(String seau, String cle) async =>
      'https://photos.exemple/$seau/$cle';
}

FauxCandidaturesDirection _port() => FauxCandidaturesDirection(
  capacitesRendues: capacitesGestes,
  details: <DetailCandidature>[
    detailTest(
      paiement: EtatVersement.aVerifier,
      piece: EtatPiece.deposee,
      controles: const <ControleCandidature>[
        ControleCandidature(
          nom: 'paiement_compatible',
          valeur: false,
          cause: 'a_verifier',
        ),
        ControleCandidature(nom: 'accords_signes', valeur: true),
        ControleCandidature(nom: 'cadre_religieux', valeur: true),
        ControleCandidature(nom: 'entretien_conclu', valeur: false),
        ControleCandidature(nom: 'piece_validee', valeur: false),
      ],
    ),
  ],
  contacts: const <String, ContactCandidat>{
    'c1': ContactCandidat(courriel: 'amina.diallo@exemple.org'),
  },
  moyens: const <String, MoyensConfirmes>{
    'SN': MoyensConfirmes(
      virementBancaire: true,
      operateurs: <OperateurPaiement>[
        OperateurPaiement(code: 'orange_money', nom: 'Orange Money'),
      ],
    ),
  },
  historiques: <String, List<EvenementCandidature>>{
    'c1': <EvenementCandidature>[
      evenementTest(
        id: 1,
        type: 'creee',
        auteur: AuteurEvenement.systeme,
        quand: DateTime.utc(2026, 10, 1, 9),
      ),
    ],
  },
);

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

final Uint8List _pixel = base64Decode(
  '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'
  'Gz/6xR/+Axg2PS4pphtiAAAAAElFTkSuQmCC',
);

Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection port, {
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
        portPhotoDossierProvider.overrideWithValue(_Photo()),
        portPhotosProvider.overrideWithValue(const _Photos()),
        imagePieceProvider.overrideWithValue((Uri _) => MemoryImage(_pixel)),
        horlogeFormulairesProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 22, 12),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  unawaited(
    routeur.push<void>(
      Routes.adminPersonnesCandidaturePour('CAND-0000C1'),
      extra: 'c1',
    ),
  );
  await stabiliser(tester);
  await stabiliser(tester);
}

Future<void> _photo(WidgetTester tester, String nom) async {
  debugPrint('PNG ${await capturer(tester, 'BE-DOSSIER/$nom')}');
}

Future<void> _ouvrir(WidgetTester tester, RubriqueDossierCode c) async {
  await tester.ensureVisible(find.byKey(RubriqueDossier.cleEntete(c)));
  await tester.tap(find.byKey(RubriqueDossier.cleEntete(c)));
  await stabiliser(tester);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('BE-DOSSIER : captures', skip: sautSansCapture, () {
    for (final (String nom, Size taille, EdgeInsets zone)
        in <(String, Size, EdgeInsets)>[
          ('telephone', const Size(360, 800), _zoneSure),
          ('ordinateur', const Size(1366, 768), EdgeInsets.zero),
        ]) {
      testWidgets('contenu $nom', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        await _photo(tester, 'dossier_$nom');
        // Ou est le premier geste de decision, en points, dans la fenetre.
        final Finder premier = find
            .descendant(
              of: find.byKey(BarreDecisionDossier.cle),
              matching: find.byType(ActionPrincipale),
            )
            .first;
        final Offset p = tester.getTopLeft(premier);
        debugPrint(
          'POSITION premier geste de decision, $nom : '
          'y=${p.dy.round()} sur ${taille.height.round()} points '
          '(haut du bouton, depuis le haut de la fenetre)',
        );
        await _ouvrir(tester, RubriqueDossierCode.historique);
        // La capture montre l'historique ouvert, pas le haut de la page.
        await tester.ensureVisible(
          find.byKey(
            RubriqueDossier.cleContenu(RubriqueDossierCode.historique),
          ),
        );
        await stabiliser(tester);
        await _photo(tester, 'dossier_historique_$nom');
      });

      testWidgets('photo en grand $nom', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        // Une image se decode hors du temps de test : on la prepare avant.
        await tester.runAsync(
          () => precacheImage(
            MemoryImage(_pixel),
            tester.element(find.byKey(EtageUnDossier.clePhoto)),
          ),
        );
        await tester.tap(find.byKey(EtageUnDossier.clePhoto));
        await stabiliser(tester);
        await _photo(tester, 'photo_en_grand_$nom');
      });
    }

    testWidgets('arabe, de droite a gauche, telephone', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(360, 800), 1, zoneSure: _zoneSure);
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, _port());
      await _photo(tester, 'dossier_arabe_telephone');
    });

    testWidgets('arabe, de droite a gauche, ordinateur', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(1366, 768), 1);
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, _port());
      await _photo(tester, 'dossier_arabe_ordinateur');
    });
  });
}
