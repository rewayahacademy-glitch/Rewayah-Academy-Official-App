// ENS-02 Aujourd'hui (EN-2) : carte « Prochaine seance » (E11), « Ma
// journee », « A terminer » (K-45), « Alertes utiles », une ou deux colonnes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/libelle_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../support/harnais.dart';
import 'package:rewayah_academy/features/compte/apparence_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import '../capture/outil_capture.dart';

const String _monId = 't1';

/// Le « maintenant » des tests : lundi 28 septembre 2026, 16 h.
final DateTime _m = DateTime(2026, 9, 28, 16);

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

const ReglagesPriere _paris = ReglagesPriere(
  enseignantId: _monId,
  latitude: 48.85341,
  longitude: 2.34880,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  lieu: 'Paris',
);

PresenceParticipant _presence({
  required EtatPresence etat,
  String profilId = 'e1',
  String prenom = 'Maryam',
}) => PresenceParticipant(
  profilId: profilId,
  role: 'student',
  prenom: prenom,
  identifiantImmuable: 'STUD-XX-000003',
  etat: etat,
  consolide: false,
);

FauxServiceRegles _reglesAvecPause(int minutes) =>
    FauxServiceRegles()
      ..parProfil[_monId] = <RegleProfil>[
        RegleProfil(
          cle: CleRegle.pauseEntreCours,
          valeurEffective: minutes,
          valeurPlateforme: 30,
        ),
      ];

List<Override> _surcharges({
  FauxServiceEnseignant? enseignant,
  FauxServiceRegles? regles,
  FauxServicePriere? priere,
  FauxServicePresence? presence,
  FauxServiceReseau? reseau,
  DateTime? maintenant,
  DateTime Function()? horloge,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_sessionEnseignant),
  ),
  serviceEnseignantProvider.overrideWithValue(
    enseignant ?? FauxServiceEnseignant(),
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(regles ?? FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(priere ?? FauxServicePriere()),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  servicePresenceProvider.overrideWithValue(presence ?? FauxServicePresence()),
  serviceReseauProvider.overrideWithValue(reseau ?? FauxServiceReseau()),
  maintenantJourneeProvider.overrideWithValue(
    horloge ?? () => maintenant ?? _m,
  ),
];

/// La page dans le vrai theme clair ou sombre, a une echelle de texte donnee.
Widget _hoteCarte({
  required Brightness luminosite,
  required double echelleTexte,
  required List<Override> surcharges,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: luminosite == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(echelleTexte)),
        child: app!,
      ),
      home: const JourneePage(),
    ),
  ),
);

void _fenetre(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

SeanceEnseignant _anNour({StatutSeance statut = StatutSeance.planifiee}) =>
    seanceDeTest(
      id: 'an-nour',
      debut: DateTime(2026, 9, 28, 17, 30),
      statut: statut,
      nbParticipants: 4,
      groupeId: 'g-an-nour',
      groupeLibelle: 'An-Nour',
    );

CahierEnRetard _cahier(String id, String classe, int jour) => CahierEnRetard(
  seanceId: id,
  debut: DateTime(2026, 9, jour, 17),
  fin: DateTime(2026, 9, jour, 17, 45),
  nbParticipants: 3,
  heuresDeRetard: 30,
  groupeId: 'g-$id',
  groupeLibelle: classe,
);

List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: Routes.enseignantJournee,
    builder: (BuildContext _, GoRouterState _) => const JourneePage(),
  ),
  GoRoute(
    path: Routes.salle,
    builder: (BuildContext _, GoRouterState etat) {
      final BilletSalle? billet = etat.extra as BilletSalle?;
      return Text(
        'salle:${billet?.sessionId}:${billet?.preparation}:${billet?.groupeId}',
      );
    },
  ),
  GoRoute(
    path: '/enseignant/groupe/:groupeId',
    builder: (BuildContext _, GoRouterState etat) =>
        Text('groupe:${etat.pathParameters['groupeId']}'),
  ),
  GoRoute(
    path: '/enseignant/seance/:seanceId/cahier',
    builder: (BuildContext _, GoRouterState etat) =>
        Text('cahier:${etat.pathParameters['seanceId']}'),
  ),
];

Future<void> _ouvrir(
  WidgetTester tester, {
  FauxServiceEnseignant? enseignant,
  FauxServiceRegles? regles,
  FauxServicePriere? priere,
  FauxServicePresence? presence,
  FauxServiceReseau? reseau,
  DateTime? maintenant,
  Size taille = const Size(390, 2400),
}) async {
  _fenetre(tester, taille);
  await tester.pumpWidget(
    hote(
      const JourneePage(),
      surcharges: _surcharges(
        enseignant: enseignant,
        regles: regles,
        priere: priere,
        presence: presence,
        reseau: reseau,
        maintenant: maintenant,
      ),
    ),
  );
  await tester.pumpAndSettle();
}


// ---------------------------------------------------------------------------
// Captures avant / apres du lot 1 : CTA-FIN-1 (Journee), AVATAR-1, ETATS-BTN-1,
// NAV-FLECHES-1 (salle), THEME-SW-1 (Apparence). Les memes ecrans reels, sur la
// base et sur la branche. Saute sans CAPTURE_DIR (voir LISEZ-MOI.md).
// ---------------------------------------------------------------------------

void _rien() {}
void _outil(OutilEnseignement _) {}
void _aller(String _) {}
void _eleve(EleveSeance _) {}

const ActionsSeance _actions = ActionsSeance(
  onRetour: _rien,
  onQuitter: _rien,
  onMicro: _rien,
  onCamera: _rien,
  onAgrandir: _rien,
  onReseau: _rien,
  onEleves: _rien,
  onSupports: _rien,
  onOutil: _outil,
  onPagePrecedente: _rien,
  onPageSuivante: _rien,
  onZoomMoins: _rien,
  onZoomPlus: _rien,
  onNotifications: _rien,
  onReglages: _rien,
  onCompte: _rien,
  onNaviguer: _aller,
  onRappeler: _eleve,
  onChoisirPourReciter: _eleve,
  onNoter: _eleve,
  onSignaler: _eleve,
);

void main() {
  group('Capture : lot 1 (CTA, avatar, salle, theme)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final Size vue in const <Size>[Size(320, 1500), Size(1440, 1100)]) {
      final String l = '${vue.width.toInt()}';

      for (final (String, DateTime, StatutSeance) cas
          in <(String, DateTime, StatutSeance)>[
            ('loin', DateTime(2026, 9, 28, 16), StatutSeance.planifiee),
            ('imminent', DateTime(2026, 9, 28, 17, 25), StatutSeance.planifiee),
            ('en_cours', DateTime(2026, 9, 28, 17, 40), StatutSeance.enCours),
          ]) {
        testWidgets('journee, bouton de la seance ${cas.$1}, $l px', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, vue, 1);
          await tester.pumpWidget(
            hoteCapture(
              const JourneePage(),
              surcharges: _surcharges(
                enseignant: FauxServiceEnseignant()
                  ..seancesRendues = <SeanceEnseignant>[
                    _anNour(statut: cas.$3),
                  ],
                maintenant: cas.$2,
              ),
            ),
          );
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, 'cta_journee_${cas.$1}_$l')}');
        });
      }

      for (final (String, EtatDemoSalle, PanneauOuvert?) cas
          in <(String, EtatDemoSalle, PanneauOuvert?)>[
            ('salle_repos', EtatDemoSalle.repos, null),
            ('salle_eleves', EtatDemoSalle.eleves, PanneauOuvert.eleves),
          ]) {
        testWidgets('${cas.$1}, $l px', (WidgetTester tester) async {
          fixerVueCapture(tester, vue.width > 400 ? const Size(1440, 900) : const Size(320, 640), 1);
          VueSeance v = DonneesSeanceDemo.vue(RoleSeance.enseignant, cas.$2);
          if (cas.$3 != null) {
            v = v.copyWith(panneau: cas.$3);
          }
          await tester.pumpWidget(
            hoteCapture(SalleSeance(vue: v, actions: _actions)),
          );
          await tester.pump();
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, '${cas.$1}_$l')}');
        });
      }

      testWidgets('apparence, choix du theme, $l px', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, vue, 1);
        await tester.pumpWidget(
          hoteCapture(
            const ApparenceComptePage(),
            surcharges: <Override>[
              sourceSessionProvider.overrideWithValue(FausseSourceSession()),
            ],
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'apparence_theme_$l')}');
      });
    }
  });
}
