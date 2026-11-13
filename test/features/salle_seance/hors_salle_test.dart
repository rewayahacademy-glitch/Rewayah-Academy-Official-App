// HORS-SALLE-1 (directeur, 12/11/2026 au soir) : ce qui se dit hors de
// l'ecran de la salle. La vraie `SallePage`, le vrai controleur de session et
// les deux pieces de `app.dart` (bandeau du son bloque, retour apres une
// absence hors de l'application), sur le faux moteur des tests.

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
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_classe/garde_hors_application.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/garde_fermeture.dart';
import 'package:rewayah_academy/core/video/gestes_salle.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/hors_salle.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../teaching_core/e/faux/faux_classe.dart'
    show FauxAnnonceObservation, FauxAnnonceObservationEnfant;
import '../salle_test.dart' show FauxGestesSalle;

/// L'acces d'un eleve, tel que le serveur le rend.
AccesSalle accesEleveHorsSalle() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'student',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: false,
    peutPublierDonnees: false,
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

/// Le banc : la salle et un ecran de l'eleve, sous les deux pieces.
class BancHorsSalle {
  BancHorsSalle._(this.moteur, this.video, this.routeur);

  final FauxMoteurSalle moteur;
  final FauxServiceVideo video;
  final GoRouter routeur;
}

/// Monte le banc sur la salle. [cadre] entoure l'application (captures).
Future<BancHorsSalle> monterHorsSalle(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  Duration? delai,
  Key? cadre,
}) async {
  addTearDown(GardeFermeture.remettre);
  addTearDown(
    () => tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    ),
  );
  final FauxMoteurSalle moteur = FauxMoteurSalle();
  final FauxServiceVideo video = FauxServiceVideo(
    acces0: accesEleveHorsSalle(),
  );
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.salle,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.salle,
        builder: (BuildContext _, GoRouterState _) =>
            const SallePage(seanceId: 's1'),
      ),
      GoRoute(
        path: Routes.eleve,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Center(child: Text('accueil'))),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  final List<Override> surcharges = <Override>[
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
    serviceVideoProvider.overrideWithValue(video),
    moteurSalleProvider.overrideWithValue(moteur),
    servicePresenceProvider.overrideWithValue(FauxServicePresence()),
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
    if (delai != null) delaiHorsApplicationProvider.overrideWithValue(delai),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadre,
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
              // Comme `app.dart` : les deux pieces au-dessus des routes.
              builder: (BuildContext _, Widget? rendu) => Column(
                children: <Widget>[
                  BandeauSonBloqueHorsSalle(routeur: routeur),
                  RetourHorsApplication(routeur: routeur),
                  Expanded(child: rendu ?? const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  moteur.poser(EtatSalle.connecte);
  await tester.pumpAndSettle();
  return BancHorsSalle._(moteur, video, routeur);
}

/// La page cachee (autre application, autre onglet, ecran verrouille).
void cacherPage(WidgetTester tester) {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
}

/// La page de nouveau visible.
Future<void> montrerPage(WidgetTester tester) async {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

/// L'eleve reduit la salle (retour arriere) : l'appel continue.
Future<void> reduireSalle(WidgetTester tester, BancHorsSalle banc) async {
  banc.routeur.go(Routes.eleve);
  await tester.pumpAndSettle();
}

void main() {
  group('HORS-SALLE-1 : hors de l ecran de la salle', () {
    testWidgets('l eleve quitte l ecran de la salle en restant dans '
        'l application : rien n est coupe, meme longtemps', (
      WidgetTester tester,
    ) async {
      final BancHorsSalle b = await monterHorsSalle(tester);
      final int departs = b.moteur.departs;
      await reduireSalle(tester, b);
      expect(find.byType(SallePage), findsNothing);
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(b.moteur.departs, departs, reason: 'l appel continue');
      expect(b.video.sorties, isEmpty);
    });

    testWidgets('salle reduite, son bloque : le bandeau le dit, « Activer le '
        'son » le relance ; il se tait sur la salle', (
      WidgetTester tester,
    ) async {
      final BancHorsSalle b = await monterHorsSalle(tester);
      b.moteur.bloquerSon(bloque: true);
      await tester.pumpAndSettle();
      // Sur la salle, c'est la salle qui le dit, une fois.
      expect(find.byKey(BandeauSonBloqueHorsSalle.cle), findsNothing);
      expect(find.byKey(SallePage.sonBloqueKey), findsOneWidget);

      await reduireSalle(tester, b);
      expect(find.byKey(BandeauSonBloqueHorsSalle.cle), findsOneWidget);
      expect(find.text(t.salle.sonBloque), findsOneWidget);
      await tester.tap(find.byKey(BandeauSonBloqueHorsSalle.cleActiver));
      await tester.pumpAndSettle();
      expect(b.moteur.activationsSon, 1);
      expect(find.byKey(BandeauSonBloqueHorsSalle.cle), findsNothing);
    });

    testWidgets('salle reduite puis application quittee plus que le delai : '
        'au retour, la salle s ouvre sur l ecran du retour, et y rentrer '
        'repasse par l entree', (WidgetTester tester) async {
      final BancHorsSalle b = await monterHorsSalle(
        tester,
        // Le reglage de la direction passe par le provider (ici 5 s).
        delai: const Duration(seconds: 5),
      );
      await reduireSalle(tester, b);
      cacherPage(tester);
      await tester.pump(const Duration(seconds: 6));
      await montrerPage(tester);
      expect(b.video.sorties, <String>['s1']);
      expect(find.byType(SallePage), findsOneWidget);
      expect(find.text(t.salle.fin.horsApplication.titre), findsOneWidget);
      expect(
        find.text(
          LibellesGroupe.insecable(t.salle.fin.horsApplication.phrase(n: 5)),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(find.byType(SallePage)),
      );
      expect(
        c.read(controleurSessionProvider).etatCourant.sortieHorsApplication,
        isNull,
        reason: 'lu une fois par la salle',
      );

      final int entrees = b.video.demandes.length;
      await tester.tap(find.byKey(ResultatSeance.revenirKey));
      await tester.pumpAndSettle();
      expect(b.video.demandes.length, entrees + 1);
      expect(find.text(t.salle.fin.horsApplication.titre), findsNothing);
    });
  });
}
