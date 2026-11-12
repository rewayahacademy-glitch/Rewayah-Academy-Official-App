// Captures de recette ENTREE-ROBUSTE (directeur, 12/11/2026, point 11 et
// captures du soir) : captures de TEST, la vraie `SallePage` montee sur le
// faux moteur et le faux service des tests (aucun LiveKit, aucun serveur).
// (a) le meme compte deja dans la salle sur un autre appareil (impasse, clair
// et sombre ; la presence du serveur y est posee « sortie », comme sur la
// capture du directeur) ; (b) le son recu bloque par le navigateur et
// « Activer le son » ; (c) la camera qui ne s'allume pas, sans la phrase
// technique du navigateur ; (d) l'ecran entre deux essais automatiques.
// 390 de large. Saute sans CAPTURE_DIR. Nommage : entree_robuste_<cas>_390_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart'
    show groupesEnseignantProvider, seancesEnseignantProvider;
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/gestes_salle.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../features/salle_test.dart' show FauxGestesSalle;
import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart'
    show FauxAnnonceObservation, FauxAnnonceObservationEnfant;
import 'outil_capture.dart';

AccesSalle _acces({bool camera = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'student',
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: camera,
    peutPublierDonnees: false,
    peutRecevoir: true,
    invisible: false,
    peutModerer: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

/// La presence que le serveur rend pour l'eleve lui-meme : « sortie », comme
/// sur la capture du directeur du 12/11 au soir.
FauxServicePresence _presenceSortie() => FauxServicePresence(
  lignes: <PresenceParticipant>[
    PresenceParticipant(
      profilId: 'p1',
      role: 'student',
      prenom: 'Yasmine',
      identifiantImmuable: 'ID-p1',
      etat: EtatPresence.sortie,
      consolide: false,
      entreLe: DateTime.now().subtract(const Duration(minutes: 8)),
      debutSeance: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ],
);

List<Override> _surcharges(
  FauxMoteurSalle moteur, {
  bool camera = false,
  FauxServicePresence? presence,
}) => <Override>[
  portGestesSalleProvider.overrideWithValue(FauxGestesSalle()),
  signalRappelProvider.overrideWithValue(() {}),
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.student,
        profileId: 'p1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideo(acces0: _acces(camera: camera)),
  ),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(presence ?? FauxServicePresence()),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(),
  ),
  portAnnonceObservationProvider.overrideWithValue(FauxAnnonceObservation()),
  groupesEnseignantProvider.overrideWith(
    (Ref _) async => const <GroupeEnseignant>[],
  ),
  seancesEnseignantProvider.overrideWith(
    (Ref _) async => const <SeanceEnseignant>[],
  ),
];

Future<void> _monter(
  WidgetTester tester,
  List<Override> surcharges,
  ThemeMode mode,
) async {
  fixerVueCapture(tester, const Size(390, 844), 3);
  final GoRouter routeur = GoRouter(
    initialLocation: '/salle',
    routes: <RouteBase>[
      GoRoute(
        path: '/salle',
        builder: (BuildContext _, GoRouterState _) =>
            const SallePage(seanceId: 's1'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext contexte) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(contexte).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Capture : ENTREE-ROBUSTE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(neutraliserStockageAppareil);

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final String nom = 'entree_robuste_ouverte_ailleurs_390_${mode.name}';
      testWidgets(nom, (WidgetTester tester) async {
        final FauxMoteurSalle moteur = FauxMoteurSalle()
          ..erreursDesEssais.add(const EntreeOuverteAilleurs());
        await _monter(
          tester,
          _surcharges(moteur, presence: _presenceSortie()),
          mode,
        );
        await stabiliser(tester);
        await stabiliser(tester);
        expect(find.text(t.salle.ouverteAilleurs), findsOneWidget);
        expect(find.text(t.commun.reessayer), findsOneWidget);
        // « Votre presence : a quitte le cours » ne contredit plus le
        // message : l'etat de presence n'est pas affiche dans cette impasse.
        expect(find.text(t.presence.mienne), findsNothing);
        expect(moteur.essaisFaits, 1);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }

    testWidgets('entree_robuste_son_bloque_390_light', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monter(tester, _surcharges(moteur), ThemeMode.light);
      await stabiliser(tester);
      await stabiliser(tester);
      moteur.bloquerSon(bloque: true);
      await stabiliser(tester);
      expect(find.text(t.salle.sonBloque), findsOneWidget);
      expect(find.text(t.salle.activerSon), findsOneWidget);
      debugPrint(
        'PNG ${await capturer(tester, 'entree_robuste_son_bloque_390_light')}',
      );
    });

    testWidgets('entree_robuste_camera_390_light', (WidgetTester tester) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle()
        ..erreurCamera = StateError(
          'Unable to getUserMedia: NotReadableError: Could not start video '
          'source',
        );
      await _monter(tester, _surcharges(moteur, camera: true), ThemeMode.light);
      await stabiliser(tester);
      await stabiliser(tester);
      await tester.tap(find.bySemanticsLabel(RegExp(t.salle.ouvrirCamera)));
      await stabiliser(tester);
      expect(find.text(t.salle.cameraEchec), findsOneWidget);
      expect(find.text(t.salle.cameraEchecOccupee), findsOneWidget);
      expect(find.textContaining('NotReadableError'), findsNothing);
      debugPrint(
        'PNG ${await capturer(tester, 'entree_robuste_camera_390_light')}',
      );
    });

    testWidgets('entree_robuste_entre_deux_essais_390_light', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle()
        ..erreursDesEssais.add(StateError('coupure'));
      await _monter(tester, _surcharges(moteur), ThemeMode.light);
      // Une seconde : le premier essai a manque, le deuxieme part a 2 s.
      await stabiliser(tester);
      expect(moteur.essaisFaits, 1);
      expect(find.text(t.commun.reessayer), findsNothing);
      debugPrint(
        'PNG ${await capturer(tester, 'entree_robuste_entre_deux_essais_390_light')}',
      );
      // Le deuxieme essai aboutit : aucune minuterie ne reste en suspens.
      await tester.pump(const Duration(seconds: 2));
      await stabiliser(tester);
      expect(moteur.essaisFaits, 2);
    });
  });
}
