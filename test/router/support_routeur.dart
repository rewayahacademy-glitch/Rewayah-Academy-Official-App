// Outils partages des tests du routeur reel (navigation, etats transverses).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/service_video.dart';

import '../parcours/faux_service_offres.dart';
import '../support/harnais.dart';
import '../support/sens_et_echelle.dart';
import '../teaching_core/a/faux/faux_groupes.dart';

/// Une session active d'un role.
SessionState sessionActive(
  AppRole role, {
  InterfaceMode mode = InterfaceMode.standard,
}) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p-${role.valeurSql}',
  householdId: 'h1',
  accountStatus: AccountStatus.active,
  interfaceMode: mode,
  lectureProfil: LectureProfil.presente,
);

/// Une source de session pilotee par le test : un etat de depart, puis ceux
/// qu'on emet. [depart] nul : la session ne se resout jamais (demarrage).
class SourcePilotee implements SourceSession {
  /// Cree la source.
  SourcePilotee([this.depart]);

  /// L'etat rendu a l'abonnement, ou rien.
  final SessionState? depart;

  final StreamController<SessionState> _flux =
      StreamController<SessionState>.broadcast();

  /// Le nombre de relances demandees.
  int rafraichissements = 0;

  @override
  Stream<SessionState> etats() async* {
    final SessionState? premier = depart;
    if (premier != null) {
      yield premier;
    }
    yield* _flux.stream;
  }

  /// Emet un nouvel etat de session.
  void emettre(SessionState etat) => _flux.add(etat);

  @override
  Future<void> rafraichir() async {
    rafraichissements++;
  }

  /// Ferme le flux.
  Future<void> fermer() => _flux.close();
}

/// Les faux de tous les services qu'un ecran du tuteur (et de l'eleve) lit
/// au montage : aucun appel reseau, aucun Supabase.
List<Override> surchargesRouteur(
  SourceSession source, {
  ServiceAppairage? appairage,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(source),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
  serviceAppairageProvider.overrideWithValue(
    appairage ?? FauxServiceAppairage(),
  ),
  serviceAvatarProvider.overrideWithValue(FauxServiceAvatar()),
  serviceSuiviProvider.overrideWithValue(FauxServiceSuivi()),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
  servicePresenceProvider.overrideWithValue(FauxServicePresence()),
  serviceVideoProvider.overrideWithValue(FauxServiceVideo()),
  serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
  serviceOffresProvider.overrideWithValue(FauxServiceOffres()),
  portGroupesProvider.overrideWithValue(
    const FauxPortGroupes(groupes: <Never>[]),
  ),
  portHorlogeSeanceProvider.overrideWithValue(const PortHorlogeMuet()),
  stockagePreferencesProvider.overrideWithValue(StockagePreferencesMemoire()),
];

/// Laisse passer les animations d'entree sans exiger qu'elles s'arretent :
/// un squelette qui pulse ferait echouer `pumpAndSettle`.
Future<void> stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Monte l'application sur son **vrai** routeur, puis va a [depart] (s'il
/// est donne). La session vient de [source], ou d'une session active de
/// tuteur.
Future<GoRouter> monterRouteur(
  WidgetTester tester,
  String? depart, {
  SourceSession? source,
  Size taille = const Size(390, 844),
  List<Override> surcharges = const <Override>[],
  ThemeMode themeMode = ThemeMode.light,
  InterfaceMode interface = InterfaceMode.standard,
  TextDirection? direction,
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          source ?? FausseSourceSession(sessionActive(AppRole.guardian)),
        ),
        // Le port K6 est branche sur Supabase en production (revue C, M2) :
        // le routeur des tests transverses garde l'etat « pas encore relie ».
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(interface, Brightness.light),
              darkTheme: AppTheme.pour(interface, Brightness.dark),
              themeMode: themeMode,
              builder: sensEtEchelle(direction: direction, echelle: echelle),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (depart != null) {
    routeur.go(depart);
    await stabiliser(tester);
  }
  return routeur;
}

/// L'adresse courante du routeur, requete comprise.
String lieu(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.toString();
