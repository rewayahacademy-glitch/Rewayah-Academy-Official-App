// MA-APRES-1 : le montage commun de la VRAIE salle d'une eleve en Mode
// Accessibilite, puis « Quitter le cours » (test de comportement et
// captures). Horloge fixe : la Classe de demonstration « a venir »
// (instants figes de `DonneesClasseDemo`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../../support/harnais.dart';
import '../../teaching_core/e/faux/faux_classe.dart';

AccesSalle _acces() => AccesSalle(
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
  expireLe: DateTime.utc(2099),
);

/// La Classe, telle que le port la rend ; compte les lectures.
class GroupesMaApres implements PortGroupes {
  /// Cree le port sur ce qu'il rendra.
  GroupesMaApres(this.rendu);

  /// Ce que rend chaque lecture.
  final Future<GroupSummaryVM?> Function() rendu;

  /// Le nombre de lectures (« Reessayer » relit).
  int lectures = 0;

  @override
  Future<List<GroupSummaryVM>> mesGroupes() async => const <GroupSummaryVM>[];

  @override
  Future<GroupSummaryVM?> groupe(String groupeId) {
    lectures++;
    return rendu();
  }
}

/// Aucun tic : l'horloge de la Classe fait foi (instants figes).
class _HorlogeMuette implements PortHorlogeSeance {
  @override
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  }) async => null;

  @override
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  }) => const Stream<SessionClockVM>.empty();

  @override
  Future<DateTime> maintenantServeurUtc() async =>
      DonneesClasseDemo.instant(EtatDemoClasse.aVenir);
}

class _Travail implements PortTravailAVenir {
  const _Travail(this.actions);

  final List<SlotAction> actions;

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async => actions;
}

/// La Classe de demonstration, seance a venir (horloge figee).
Future<GroupSummaryVM?> classeAVenir() async =>
    DonneesClasseDemo.groupe(EtatDemoClasse.aVenir);

/// Pompe sans exiger la fin des animations (squelette).
Future<void> stabiliserMaApres(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Monte la vraie salle en Mode Accessibilite, puis « Quitter le cours » et
/// confirme. [cadre] : la cle du cadre de capture (au-dessus de l'app).
Future<void> quitterLaSalleMa(
  WidgetTester tester, {
  required PortGroupes groupes,
  Size taille = const Size(390, 844),
  double densite = 1,
  double echelle = 1,
  bool horsLigne = false,
  List<SlotAction> travail = DonneesClasseDemo.actions,
  ThemeMode themeMode = ThemeMode.light,
  Key? cadre,
}) async {
  tester.view.physicalSize = taille * densite;
  tester.view.devicePixelRatio = densite;
  addTearDown(tester.view.reset);
  final List<Override> surcharges = <Override>[
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(
        const SessionState(
          resolue: true,
          role: AppRole.student,
          profileId: 'p1',
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
          interfaceMode: InterfaceMode.enfant,
        ),
      ),
    ),
    servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
    serviceVideoProvider.overrideWithValue(FauxServiceVideo(acces0: _acces())),
    moteurSalleProvider.overrideWithValue(FauxMoteurSalle()),
    servicePresenceProvider.overrideWithValue(FauxServicePresence()),
    portAnnonceObservationEnfantProvider.overrideWithValue(
      FauxAnnonceObservationEnfant(observe: false),
    ),
    portAnnonceObservationProvider.overrideWithValue(
      FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
    ),
    portGroupesProvider.overrideWithValue(groupes),
    portHorlogeSeanceProvider.overrideWithValue(_HorlogeMuette()),
    portTravailAVenirProvider.overrideWithValue(_Travail(travail)),
    serviceReseauProvider.overrideWithValue(
      FauxServiceReseau(horsLigneRendu: horsLigne),
    ),
  ];
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.salle,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.salle,
        builder: (BuildContext _, GoRouterState _) => const SallePage(
          seanceId: 's1',
          groupeId: DonneesClasseDemo.groupeId,
        ),
      ),
      GoRoute(
        path: Routes.eleveSuivi,
        builder: (BuildContext _, GoRouterState _) => const Text('ma classe'),
      ),
      GoRoute(
        path: Routes.eleve,
        builder: (BuildContext _, GoRouterState _) =>
            const Text('accueil eleve'),
      ),
      GoRoute(
        path: Routes.compte,
        builder: (BuildContext _, GoRouterState _) => const Text('mon espace'),
      ),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadre,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.enfant, Brightness.dark),
              themeMode: themeMode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliserMaApres(tester);

  final Finder quitter = find.bySemanticsLabel(RegExp(t.salle.quitterLeCours));
  expect(quitter, findsWidgets);
  await tester.tap(quitter.first);
  await stabiliserMaApres(tester);
  await tester.tap(find.text(t.salle.quitterLeCours).last);
  await stabiliserMaApres(tester);
}
