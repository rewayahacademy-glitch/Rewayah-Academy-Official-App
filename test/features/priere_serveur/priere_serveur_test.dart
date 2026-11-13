// PRIERE-1 : les ecrans de la priere lue sur le serveur. Donnees fictives.
//
// - l'enseignant ouvre « Mes heures de priere » depuis son Compte, sur son
//   vrai routeur : cinq etats (chargement, contenu, vide, erreur, hors ligne),
//   et l'ajustement de -30 a +30 minutes ;
// - la direction pose le lieu d'un enseignant (« Lieux de priere ») : cinq
//   etats, validation, retrait ;
// - le bloc « Prieres et creneau » de la fiche d'une classe, en lecture seule ;
// - les reglages de la priere dans Configuration > Regles ;
// - la journee de l'enseignant et l'accueil de l'eleve disent « Pause de
//   priere » (leurs tests sont dans journee_test.dart et accueil_eleve_test.dart).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart'
    show SeanceEnseignant;
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/libelle_priere.dart';
import 'package:rewayah_academy/core/priere/lieu_priere.dart';
import 'package:rewayah_academy/core/priere/pause_prevue.dart';
import 'package:rewayah_academy/core/priere/position_appareil.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choix_nombre.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_configuration_regles/regles_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/priere_serveur/bloc_priere_classe.dart';
import 'package:rewayah_academy/features/priere_serveur/lieux_priere_page.dart';
import 'package:rewayah_academy/features/priere_serveur/priere_enseignant_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/enseignant_demo.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

final DateTime _jour = DateTime.utc(2027, 1, 15);

LieuPriere _lieu({
  int maghrib = 0,
  bool vendredi = false,
  bool methodePropre = false,
}) => LieuPriere(
  enseignantId: 'ens-1',
  lieu: 'Conakry',
  latitude: 9.6412,
  longitude: -13.5784,
  fuseau: 'Africa/Conakry',
  methode: MethodeCalcul.ligueMondiale,
  ecoleAsr: Madhab.shafi,
  methodeSurchargee: methodePropre,
  ecoleSurchargee: false,
  ajustements: <Priere, int>{Priere.maghrib: maghrib},
  assisteVendredi: vendredi,
  vendrediDebut: '12:30',
  vendrediFin: '14:30',
);

VueEnseignantPriere _vue({
  String id = 'ens-1',
  String prenom = 'Aicha',
  bool aUnLieu = true,
  String source = 'enseignant',
  String origine = 'academie',
  bool vendredi = true,
}) => VueEnseignantPriere(
  enseignantId: id,
  prenom: prenom,
  aUnLieu: aUnLieu,
  lieu: aUnLieu ? 'Votre position, fuseau Africa/Conakry' : null,
  fuseau: aUnLieu ? 'Africa/Conakry' : null,
  source: aUnLieu ? source : null,
  methode: aUnLieu ? MethodeCalcul.ligueMondiale : null,
  origineMethode: aUnLieu ? origine : null,
  ecoleAsr: aUnLieu ? Madhab.shafi : null,
  assisteVendredi: aUnLieu && vendredi,
  horaires: aUnLieu ? _heures() : const <HeurePriere>[],
);

List<HeurePriere> _heures({bool approchee = false}) => <HeurePriere>[
  for (final (Priere p, int h, int m) in <(Priere, int, int)>[
    (Priere.fajr, 5, 35),
    (Priere.dhuhr, 12, 39),
    (Priere.asr, 15, 59),
    (Priere.maghrib, 18, 30),
    (Priere.isha, 19, 38),
  ])
    HeurePriere(
      priere: p,
      instant: DateTime(_jour.year, _jour.month, _jour.day, h, m),
      approximee: approchee && p == Priere.isha,
      fuseau: 'Africa/Conakry',
    ),
];

class _PriereEnPanne extends FauxServicePriere {
  @override
  Future<LieuPriere?> lieu({String? enseignantId}) async =>
      throw StateError('reseau');
}

class _PausePrevueEnPanne extends FauxServicePriere {
  @override
  Future<PausePrevue?> pausePrevue(String seanceId) async =>
      throw StateError('reseau');
}

class _PriereEnAttente extends FauxServicePriere {
  final Completer<void> attente = Completer<void>();

  @override
  Future<LieuPriere?> lieu({String? enseignantId}) async {
    await attente.future;
    return super.lieu(enseignantId: enseignantId);
  }
}

class _Config implements ServiceConfiguration {
  _Config(this.valeurs);

  final Map<String, Object?> valeurs;
  final List<(String, Object)> ecritures = <(String, Object)>[];

  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async => <ValeurConfig>[
    for (final String c in cles) ValeurConfig(cle: c, valeur: valeurs[c]),
  ];

  @override
  Future<void> ecrire(String cle, Object valeur) async {
    ecritures.add((cle, valeur));
    valeurs[cle] = valeur;
  }
}

const Map<String, Object?> _clesRegles = <String, Object?>{
  'absence_threshold_minutes': 5,
  'session_duration_minutes': 60,
  'session_paid_minimum_minutes': 45,
  'break_minutes_between_sessions': 30,
  'max_students_per_teacher': 5,
  'matching_horizon_weeks': 4,
  'camera_auto_allow_min_age': 11,
  'child_ui_mode_max_age': 8,
  'max_devices_per_student': 2,
  'max_concurrent_sessions_per_profile': 1,
  'enseignant.classes_max': 3,
  'grace_after_end_minutes': 15,
};

Map<String, Object?> _clesPriere() => <String, Object?>{
  'priere.methode_defaut': 'muslim_world_league',
  'priere.ecole_asr_defaut': 'shafi',
  'priere.pause_minutes': 10,
  'priere.pause_ramadan_maghrib_minutes': 20,
  'priere.ramadan_en_cours': false,
  'priere.debut_marge_minutes': 5,
  'priere.fin_marge_minutes': 15,
  'priere.horizon_jours': 14,
  'priere.marge_avant_cours_minutes': 20,
  'priere.delai_fermeture_minutes': 10,
  'priere.methode_selon_pays': true,
};

List<Override> _surcharges(
  FauxServicePriere priere, {
  AppRole role = AppRole.teacher,
  FauxServiceEnseignant? enseignant,
  DateTime? maintenant,
}) => <Override>[
  if (maintenant != null)
    maintenantJourneeProvider.overrideWithValue(() => maintenant),
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: role,
        profileId: 'ens-1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  serviceEnseignantProvider.overrideWithValue(
    enseignant ?? FauxServiceEnseignant(),
  ),
  servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
  referentielLanguesProvider.overrideWith(
    (Ref _) async => const <LangueCours>[],
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(priere),
  profilEnseignantProvider.overrideWith(
    (Ref _) async => const ProfilEnseignant(
      prenom: 'Aicha',
      identifiant: 'RA-26-0007',
      langues: <String>[],
      statutCompte: AccountStatus.active,
    ),
  ),
  peutReglerPolitiqueKycProvider.overrideWithValue(false),
];

/// Monte l'application sur son vrai routeur, a l'adresse demandee.
Future<GoRouter> _monter(
  WidgetTester tester,
  String depart,
  FauxServicePriere priere, {
  Size taille = const Size(390, 2400),
  FauxServiceEnseignant? enseignant,
  DateTime? maintenant,
}) async {
  fixerVueCapture(tester, taille, 1);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(
        priere,
        enseignant: enseignant,
        maintenant: maintenant,
      ),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            routeur.go(depart);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

/// Une page montee seule, avec le service [priere].
Future<void> _monterPage(
  WidgetTester tester,
  Widget page,
  FauxServicePriere priere, {
  Size taille = const Size(390, 2400),
  List<Override> autres = const <Override>[],
  bool attendre = true,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hote(page, surcharges: <Override>[..._surcharges(priere), ...autres]),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  group('L enseignant : Mes heures de priere (sur le vrai routeur)', () {
    testWidgets('le Compte ouvre la page, le retour ramene au Compte', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..lieuRendu = _lieu()
        ..heures = _heures();
      final GoRouter routeur = await _monter(
        tester,
        Routes.enseignantProfil,
        priere,
      );
      expect(find.byType(ProfilEnseignantPage), findsOneWidget);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('compte-priere')),
      );
      expect(routeur.state.matchedLocation, Routes.enseignantProfilPriere);
      expect(find.byType(PriereEnseignantPage), findsOneWidget);
      await _toucher(tester, find.byType(DisqueRetour));
      expect(routeur.state.matchedLocation, Routes.enseignantProfil);
    });

    // Revue du 13/11/2026 (P2) : le titulaire d'une seance remplacee la voit dans sa
    // liste ; le serveur ne lui rend plus d'erreur mais zero ligne, donc sa journee ne
    // signale aucun echec. Le meme chemin avec une vraie panne le signale.
    for (final (String nom, FauxServicePriere service, bool echec)
        in <(String, FauxServicePriere, bool)>[
          ('zero ligne rendue par le serveur', FauxServicePriere(), false),
          ('lecture en panne', _PausePrevueEnPanne(), true),
        ]) {
      testWidgets(
        'journee du titulaire d une seance remplacee, vrai routeur : $nom',
        (WidgetTester tester) async {
          await _monter(
            tester,
            Routes.enseignantJournee,
            service,
            enseignant: FauxServiceEnseignant()
              ..groupesRendus = DonneesEnseignantDemo.groupes()
              ..seancesRendues = <SeanceEnseignant>[
                seanceDeTest(
                  debut: DateTime(2026, 9, 28, 9),
                  duree: const Duration(hours: 1),
                  groupeId: 'g1',
                  groupeLibelle: 'An-Nour',
                  nbParticipants: 4,
                ),
              ],
            maintenant: DateTime(2026, 9, 28, 8),
          );
          expect(find.byType(JourneePage), findsOneWidget);
          expect(
            find.text(t.enseignant.journee.erreurPartielle),
            echec ? findsOneWidget : findsNothing,
          );
        },
      );
    }

    testWidgets('contenu : cinq lignes, le lieu, les heures du serveur', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..lieuRendu = _lieu(maghrib: 3)
        ..heures = _heures(approchee: true);
      await _monterPage(tester, const PriereEnseignantPage(), priere);
      expect(find.text(t.priere.lieu(lieu: 'Conakry')), findsOneWidget);
      for (final Priere p in Priere.values) {
        expect(find.byKey(PriereEnseignantPage.cleLigne(p)), findsOneWidget);
      }
      expect(find.textContaining('18:30'), findsOneWidget);
      expect(
        find.textContaining(
          LibellesGroupe.insecable(t.priere.enseignant.plus(minutes: '3')),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(t.priere.approchee), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vide : aucun lieu connu, un seul bouton plein, aucun champ', (
      WidgetTester tester,
    ) async {
      await _monterPage(
        tester,
        const PriereEnseignantPage(),
        FauxServicePriere(),
      );
      expect(find.text(t.priere.enseignant.vide), findsOneWidget);
      expect(
        find.byKey(PriereEnseignantPage.cleLigne(Priere.fajr)),
        findsNothing,
      );
      expect(find.text(t.priere.enseignant.utiliserPosition), findsOneWidget);
      // Jamais un formulaire de coordonnees pour l'enseignant.
      expect(find.byType(TextField), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('« Utiliser ma position » : la position part au serveur', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere();
      await _monterPage(
        tester,
        const PriereEnseignantPage(),
        priere,
        autres: <Override>[
          lecturePositionAppareilProvider.overrideWithValue(
            () async => const PositionAppareil(
              latitude: 9.64123,
              longitude: -13.57841,
              fuseau: 'Africa/Conakry',
            ),
          ),
        ],
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('priere-utiliser-position')),
      );
      expect(priere.partagees.length, 1);
      expect(priere.partagees.single.fuseau, 'Africa/Conakry');
      expect(
        find.byKey(const ValueKey<String>('priere-position-message')),
        findsNothing,
      );
    });

    testWidgets('position refusee : l\'etat le dit, on peut reessayer', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere();
      await _monterPage(
        tester,
        const PriereEnseignantPage(),
        priere,
        autres: <Override>[
          lecturePositionAppareilProvider.overrideWithValue(
            () => Future<PositionAppareil>.error(const PositionNonPartagee()),
          ),
        ],
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('priere-utiliser-position')),
      );
      expect(find.text(t.priere.enseignant.positionRefusee), findsOneWidget);
      expect(priere.partagees, isEmpty);
      expect(find.byType(TextField), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('priere-utiliser-position')),
        findsOneWidget,
      );
    });

    testWidgets('le serveur n\'a pas recu : « il est possible que... »', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..echecEcriture = true;
      await _monterPage(
        tester,
        const PriereEnseignantPage(),
        priere,
        autres: <Override>[
          lecturePositionAppareilProvider.overrideWithValue(
            () async => const PositionAppareil(
              latitude: 9.6,
              longitude: -13.5,
              fuseau: 'Africa/Conakry',
            ),
          ),
        ],
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('priere-utiliser-position')),
      );
      expect(find.text(t.priere.enseignant.positionErreur), findsOneWidget);
    });

    testWidgets('un lieu pose par la direction : la phrase le dit', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..partageRefuse = true;
      await _monterPage(
        tester,
        const PriereEnseignantPage(),
        priere,
        autres: <Override>[
          lecturePositionAppareilProvider.overrideWithValue(
            () async => const PositionAppareil(
              latitude: 9.6,
              longitude: -13.5,
              fuseau: 'Africa/Conakry',
            ),
          ),
        ],
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('priere-utiliser-position')),
      );
      // Le faux leve une erreur generique : « il est possible que... ».
      expect(find.text(t.priere.enseignant.positionErreur), findsOneWidget);
    });

    testWidgets('erreur : la cause probable et un bouton pour relire', (
      WidgetTester tester,
    ) async {
      await _monterPage(tester, const PriereEnseignantPage(), _PriereEnPanne());
      expect(find.text(t.priere.enseignant.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('chargement : un squelette, aucune ligne', (
      WidgetTester tester,
    ) async {
      final _PriereEnAttente priere = _PriereEnAttente();
      await _monterPage(
        tester,
        const PriereEnseignantPage(),
        priere,
        attendre: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(EmptyState), findsNothing);
      priere.attente.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('ajuster : de -30 a +30, enregistre, un seul bouton plein', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..lieuRendu = _lieu()
        ..heures = _heures();
      await _monterPage(tester, const PriereEnseignantPage(), priere);
      await _toucher(
        tester,
        find.byKey(PriereEnseignantPage.cleLigne(Priere.maghrib)),
      );
      verifierUnSeulBoutonPlein(tester);
      await _toucher(tester, find.byKey(ChoixNombre.clePlus));
      await _toucher(tester, find.text(t.priere.enseignant.enregistrer));
      expect(priere.ajustes, <(Priere, int)>[(Priere.maghrib, 1)]);
    });

    testWidgets('ajuster : un echec se dit, rien n est enregistre', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..lieuRendu = _lieu()
        ..heures = _heures()
        ..echecEcriture = true;
      await _monterPage(tester, const PriereEnseignantPage(), priere);
      await _toucher(
        tester,
        find.byKey(PriereEnseignantPage.cleLigne(Priere.fajr)),
      );
      await _toucher(tester, find.byKey(ChoixNombre.cleMoins));
      await _toucher(tester, find.text(t.priere.enseignant.enregistrer));
      expect(
        find.text(t.priere.enseignant.erreurEnregistrement),
        findsOneWidget,
      );
      expect(priere.ajustes, isEmpty);
    });
  });

  group('En arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    testWidgets('les textes et les noms des prieres sont ceux de la decision', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..lieuRendu = _lieu()
        ..heures = _heures();
      await _monterPage(tester, const PriereEnseignantPage(), priere);
      expect(find.text(t.priere.enseignant.titre), findsWidgets);
      expect(t.priere.pauseDePriere, 'استراحة الصلاة');
      expect(find.text(t.priere.maghrib), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('La direction : Lieux de priere (une liste a lire)', () {
    final List<VueEnseignantPriere> vues = <VueEnseignantPriere>[
      _vue(),
      _vue(id: 'ens-2', prenom: 'Omar', aUnLieu: false),
    ];

    testWidgets(
      'contenu : la zone, les cinq heures, la methode, « en attente »',
      (WidgetTester tester) async {
        final FauxServicePriere priere = FauxServicePriere()
          ..vueRendue = vues
          ..incoherencesRendues = const <IncoherencePriere>[
            IncoherencePriere(
              enseignantId: 'ens-1',
              prenom: 'Aicha',
              motif: 'fuseau_compte_different',
              detail: 'Europe/Paris / Africa/Conakry',
            ),
          ];
        await _monterPage(tester, const LieuxPrierePage(), priere);
        expect(find.byKey(LieuxPrierePage.cleLigne('ens-1')), findsOneWidget);
        expect(find.byKey(LieuxPrierePage.cleLigne('ens-2')), findsOneWidget);
        // Omar n'a pas partage sa position : « en attente ».
        expect(find.textContaining(t.priere.direction.attente), findsOneWidget);
        // Aicha : sa zone, d'ou vient le lieu, ses cinq heures, sa methode.
        expect(
          find.textContaining(t.priere.direction.sourceEnseignant),
          findsOneWidget,
        );
        expect(find.textContaining('18:30'), findsOneWidget);
        expect(
          find.textContaining(
            t.priere.direction.methodeLigne(
              methode: libelleMethode(MethodeCalcul.ligueMondiale),
              origine: t.priere.direction.origineAcademie,
            ),
          ),
          findsOneWidget,
        );
        // Une seule action secondaire par ligne, aucun champ visible.
        expect(find.text(t.priere.direction.corriger), findsNWidgets(2));
        expect(find.byType(TextField), findsNothing);
        expect(find.text(t.priere.direction.incoherenceTitre), findsOneWidget);
      },
    );

    testWidgets('vide : aucun enseignant actif', (WidgetTester tester) async {
      await _monterPage(tester, const LieuxPrierePage(), FauxServicePriere());
      expect(find.text(t.priere.direction.vide), findsOneWidget);
    });

    testWidgets('erreur : relire', (WidgetTester tester) async {
      await _monterPage(
        tester,
        const LieuxPrierePage(),
        FauxServicePriere(),
        autres: <Override>[
          vueEnseignantsPriereProvider.overrideWith(
            (Ref _) async => throw StateError('reseau'),
          ),
        ],
      );
      expect(find.text(t.priere.direction.erreur), findsOneWidget);
    });

    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      final Completer<List<VueEnseignantPriere>> attente =
          Completer<List<VueEnseignantPriere>>();
      await _monterPage(
        tester,
        const LieuxPrierePage(),
        FauxServicePriere(),
        attendre: false,
        autres: <Override>[
          vueEnseignantsPriereProvider.overrideWith((Ref _) => attente.future),
        ],
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Skeleton), findsWidgets);
      attente.complete(vues);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'corriger : le vendredi, les heures seulement s\'il est active, un seul bouton plein',
      (WidgetTester tester) async {
        final FauxServicePriere priere = FauxServicePriere()
          ..vueRendue = vues
          ..lieuRendu = _lieu(vendredi: true);
        await _monterPage(tester, const LieuxPrierePage(), priere);
        await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-1')));
        verifierUnSeulBoutonPlein(tester);
        // Active : les deux heures du vendredi sont la ; le reglage avance est replie.
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.text(t.priere.direction.feuille.methodeAuto), findsNothing);
        // Eteint : plus aucune heure.
        await _toucher(
          tester,
          find.descendant(
            of: find.byKey(const ValueKey<String>('priere-vendredi')),
            matching: find.byType(Switch),
          ),
        );
        expect(find.byType(TextField), findsNothing);
        await _toucher(
          tester,
          find.text(t.priere.direction.feuille.enregistrer),
        );
        expect(priere.corrections.length, 1);
        final c = priere.corrections.single;
        expect(c.enseignantId, 'ens-1');
        expect(c.assisteVendredi, isFalse);
        expect(c.methode, isNull, reason: 'automatique');
        expect(c.ecoleAsr, isNull);
        expect(priere.poses, isEmpty, reason: 'la position n\'est pas touchee');
      },
    );

    testWidgets('reglage avance : la methode se choisit dans un menu replie', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..vueRendue = vues
        ..lieuRendu = _lieu();
      await _monterPage(tester, const LieuxPrierePage(), priere);
      await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-1')));
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('priere-avance')),
      );
      await _toucher(tester, find.text(t.priere.direction.feuille.methodeAuto));
      await _toucher(tester, find.text(libelleMethode(MethodeCalcul.egypte)));
      await _toucher(tester, find.text(t.priere.direction.feuille.enregistrer));
      expect(priere.corrections.single.methode, MethodeCalcul.egypte);
    });

    testWidgets('sans lieu : en attente, la pose a la main reste repliee', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()..vueRendue = vues;
      await _monterPage(tester, const LieuxPrierePage(), priere);
      await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-2')));
      expect(
        find.text(t.priere.direction.feuille.sansLieuAide),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text(t.priere.direction.feuille.enregistrer), findsNothing);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('priere-avance')),
      );
      final Finder champs = find.byType(TextField);
      await tester.enterText(champs.at(0), 'Dakar');
      await tester.enterText(champs.at(1), '14,6937');
      await tester.enterText(champs.at(2), '-17.4441');
      await tester.enterText(champs.at(3), 'Africa/Dakar');
      await tester.pumpAndSettle();
      await _toucher(tester, find.text(t.priere.direction.feuille.poserLieu));
      expect(priere.poses.length, 1);
      final DefinitionLieu d = priere.poses.single;
      expect(d.enseignantId, 'ens-2');
      expect(d.lieu, 'Dakar');
      expect(d.latitude, 14.6937);
      expect(d.longitude, -17.4441);
      expect(d.fuseau, 'Africa/Dakar');
    });

    testWidgets('sans lieu, des champs vides : refus en mots simples', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()..vueRendue = vues;
      await _monterPage(tester, const LieuxPrierePage(), priere);
      await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-2')));
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('priere-avance')),
      );
      await _toucher(tester, find.text(t.priere.direction.feuille.poserLieu));
      expect(find.text(t.priere.direction.feuille.invalide), findsOneWidget);
      expect(priere.poses, isEmpty);
    });

    testWidgets('retirer le lieu', (WidgetTester tester) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..vueRendue = vues
        ..lieuRendu = _lieu();
      await _monterPage(tester, const LieuxPrierePage(), priere);
      await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-1')));
      await _toucher(tester, find.text(t.priere.direction.feuille.retirer));
      expect(priere.retires, <String>['ens-1']);
    });

    testWidgets('un echec d enregistrement se dit', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere()
        ..vueRendue = vues
        ..lieuRendu = _lieu()
        ..echecEcriture = true;
      await _monterPage(tester, const LieuxPrierePage(), priere);
      await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-1')));
      await _toucher(tester, find.text(t.priere.direction.feuille.enregistrer));
      expect(
        find.text(t.priere.direction.feuille.erreurEnregistrement),
        findsOneWidget,
      );
    });
  });

  group('La fiche d une classe : Prieres et creneau', () {
    LectureCreneauPriere lecture({
      bool sansLieu = false,
      List<CroisementPriere> croisements = const <CroisementPriere>[],
      int vendredi = 0,
      List<int>? libres = const <int>[9, 10],
    }) => LectureCreneauPriere(
      jour: 4,
      heure: 19,
      fuseau: 'Europe/Paris',
      dureeMinutes: 60,
      sansLieu: sansLieu,
      indefini: false,
      seances: 52,
      croisements: croisements,
      vendrediAssiste: vendredi > 0,
      vendrediSeances: vendredi,
      vendrediDebut: '12:30',
      vendrediFin: '14:30',
      heuresSansPriere: libres,
    );

    testWidgets(
      'contenu : periodes, pause placee, apres le cours, heures libres',
      (WidgetTester tester) async {
        final FauxServicePriere priere = FauxServicePriere();
        priere.lectures['g1'] = <LectureCreneauPriere>[
          lecture(
            croisements: <CroisementPriere>[
              CroisementPriere(
                priere: Priere.maghrib,
                du: DateTime(2026, 11, 19),
                au: DateTime(2027, 3, 25),
                nbSeances: 19,
                nbPause: 15,
                nbApresCours: 4,
              ),
            ],
            vendredi: 12,
          ),
        ];
        await _monterPage(
          tester,
          const SingleChildScrollView(child: BlocPriereClasse(classeId: 'g1')),
          priere,
        );
        expect(find.text(t.priere.classe.titre), findsOneWidget);
        expect(find.textContaining('19 séances, dont 15'), findsOneWidget);
        expect(find.textContaining('12 séances de l\'année'), findsOneWidget);
        expect(
          find.textContaining(
            t.priere.classe.libres(
              heures:
                  '${t.priere.classe.heureCourte(h: '9')}, ${t.priere.classe.heureCourte(h: '10')}',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byType(TextButton), findsNothing, reason: 'lecture seule');
      },
    );

    testWidgets('vide : l enseignant n a pas de lieu', (
      WidgetTester tester,
    ) async {
      final FauxServicePriere priere = FauxServicePriere();
      priere.lectures['g1'] = <LectureCreneauPriere>[lecture(sansLieu: true)];
      await _monterPage(
        tester,
        const SingleChildScrollView(child: BlocPriereClasse(classeId: 'g1')),
        priere,
      );
      expect(find.text(t.priere.classe.sansLieu), findsOneWidget);
    });

    testWidgets('erreur : relire', (WidgetTester tester) async {
      await _monterPage(
        tester,
        const SingleChildScrollView(child: BlocPriereClasse(classeId: 'g1')),
        FauxServicePriere(),
        autres: <Override>[
          lectureClassePriereProvider.overrideWith(
            (Ref _, String _) async => throw StateError('reseau'),
          ),
        ],
      );
      expect(find.text(t.priere.classe.erreur), findsOneWidget);
    });
  });

  group('Configuration > Regles : la priere de l ecole', () {
    Future<_Config> monter(WidgetTester tester, Map<String, Object?> v) async {
      final _Config config = _Config(v);
      fixerVueCapture(tester, const Size(390, 4000), 1);
      await tester.pumpWidget(
        hote(
          const ReglesPage(),
          surcharges: <Override>[
            serviceConfigurationProvider.overrideWithValue(config),
            peutReglerPolitiqueKycProvider.overrideWithValue(false),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return config;
    }

    testWidgets('la section est la, avec la mention a valider', (
      WidgetTester tester,
    ) async {
      await monter(tester, <String, Object?>{..._clesRegles, ..._clesPriere()});
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('regles-priere')),
      );
      expect(find.text(t.priere.regles.section), findsOneWidget);
      // Les valeurs chiffrees sont repliees : la pause ne se voit pas d'abord.
      expect(find.text(t.priere.regles.pause), findsNothing);
      expect(find.text(t.priere.regles.valeurs), findsOneWidget);
      expect(find.textContaining(t.priere.aValider), findsWidgets);
    });

    testWidgets('« methode selon le pays » : un interrupteur, il s ecrit', (
      WidgetTester tester,
    ) async {
      final _Config config = await monter(tester, <String, Object?>{
        ..._clesRegles,
        ..._clesPriere(),
      });
      final Finder ligne = find.byKey(
        const ValueKey<String>('regles-priere-selon-pays'),
      );
      await tester.ensureVisible(ligne);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: ligne, matching: find.byType(Switch)),
      );
      await tester.pumpAndSettle();
      expect(config.ecritures, <(String, Object)>[
        ('priere.methode_selon_pays', false),
      ]);
    });

    testWidgets('un serveur d avant le lot : la section n est pas montree', (
      WidgetTester tester,
    ) async {
      await monter(tester, <String, Object?>{..._clesRegles});
      expect(find.text(t.priere.regles.section), findsNothing);
    });

    testWidgets('le Ramadan se pose a la main, il s ecrit', (
      WidgetTester tester,
    ) async {
      final _Config config = await monter(tester, <String, Object?>{
        ..._clesRegles,
        ..._clesPriere(),
      });
      final Finder ligne = find.byKey(
        const ValueKey<String>('regles-priere-ramadan'),
      );
      await tester.ensureVisible(ligne);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: ligne, matching: find.byType(Switch)),
      );
      await tester.pumpAndSettle();
      expect(config.ecritures, <(String, Object)>[
        ('priere.ramadan_en_cours', true),
      ]);
    });

    testWidgets('la methode se choisit parmi les douze, elle s ecrit', (
      WidgetTester tester,
    ) async {
      final _Config config = await monter(tester, <String, Object?>{
        ..._clesRegles,
        ..._clesPriere(),
      });
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('regles-priere.methode_defaut')),
      );
      await _toucher(tester, find.text(t.priere.methodes.egyptian));
      expect(config.ecritures, <(String, Object)>[
        ('priere.methode_defaut', 'egyptian'),
      ]);
    });

    testWidgets('la duree de la pause : 5 a 20 minutes, elle s ecrit', (
      WidgetTester tester,
    ) async {
      final _Config config = await monter(tester, <String, Object?>{
        ..._clesRegles,
        ..._clesPriere(),
      });
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('regles-priere-valeurs')),
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('regles-priere.pause_minutes')),
      );
      await _toucher(tester, find.text(t.admin.regles.envoyer));
      expect(config.ecritures.single.$1, 'priere.pause_minutes');
    });
  });

  // Captures PRIERE-1 et PRIERE-2 : donnees fictives, jamais sans CAPTURE_DIR.
  // Les ecrans de la priere sans formulaire (« zero saisie ») : 390 et 1440,
  // clair et sombre, francais et arabe.
  group('Captures PRIERE', skip: sautSansCapture, () {
    setUp(masquerRubanDebug);
    tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

    Future<void> monter(
      WidgetTester tester,
      Widget page,
      FauxServicePriere priere, {
      required Size taille,
      required ThemeMode theme,
      required AppLocale langue,
      List<Override> autres = const <Override>[],
    }) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      fixerVueCapture(tester, taille, 1);
      await tester.pumpWidget(
        hoteCapture(
          page,
          surcharges: <Override>[..._surcharges(priere), ...autres],
          themeMode: theme,
        ),
      );
      await tester.pumpAndSettle();
    }

    const List<(String, ThemeMode, AppLocale)> variantes =
        <(String, ThemeMode, AppLocale)>[
          ('clair', ThemeMode.light, AppLocale.fr),
          ('sombre', ThemeMode.dark, AppLocale.fr),
          ('arabe', ThemeMode.light, AppLocale.ar),
        ];

    for (final (String nom, ThemeMode theme, AppLocale langue) in variantes) {
      testWidgets('enseignant, aucun lieu : le bouton, $nom', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          const PriereEnseignantPage(),
          FauxServicePriere(),
          taille: const Size(390, 700),
          theme: theme,
          langue: langue,
        );
        debugPrint(
          'PNG ${await capturerVue(tester, 'priere_enseignant_vide_390_$nom')}',
        );
      });

      testWidgets('enseignant, position refusee : l etat, $nom', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          const PriereEnseignantPage(),
          FauxServicePriere(),
          taille: const Size(390, 700),
          theme: theme,
          langue: langue,
          autres: <Override>[
            lecturePositionAppareilProvider.overrideWithValue(
              () => Future<PositionAppareil>.error(const PositionNonPartagee()),
            ),
          ],
        );
        await _toucher(
          tester,
          find.byKey(const ValueKey<String>('priere-utiliser-position')),
        );
        debugPrint(
          'PNG ${await capturerVue(tester, 'priere_enseignant_refus_390_$nom')}',
        );
      });

      testWidgets('enseignant, heures : le contenu, $nom', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          const PriereEnseignantPage(),
          FauxServicePriere()
            ..lieuRendu = _lieu(maghrib: 3)
            ..heures = _heures(approchee: true),
          taille: const Size(390, 900),
          theme: theme,
          langue: langue,
        );
        debugPrint(
          'PNG ${await capturerVue(tester, 'priere_enseignant_contenu_390_$nom')}',
        );
      });

      for (final Size taille in <Size>[
        const Size(390, 1500),
        const Size(1440, 900),
      ]) {
        testWidgets('direction, la liste a lire ${taille.width.toInt()}, $nom', (
          WidgetTester tester,
        ) async {
          await monter(
            tester,
            const LieuxPrierePage(),
            FauxServicePriere()
              ..vueRendue = <VueEnseignantPriere>[
                _vue(),
                _vue(
                  id: 'ens-3',
                  prenom: 'Bilal',
                  source: 'direction',
                  origine: 'pays',
                ),
                _vue(id: 'ens-2', prenom: 'Omar', aUnLieu: false),
              ]
              ..incoherencesRendues = const <IncoherencePriere>[
                IncoherencePriere(
                  enseignantId: 'ens-1',
                  prenom: 'Aicha',
                  motif: 'fuseau_compte_different',
                  detail: 'Europe/Paris / Africa/Conakry',
                ),
              ],
            taille: taille,
            theme: theme,
            langue: langue,
          );
          debugPrint(
            'PNG ${await capturerVue(tester, 'priere_lieux_direction_${taille.width.toInt()}_$nom')}',
          );
        });
      }

      testWidgets('direction, la feuille Corriger, $nom', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          const LieuxPrierePage(),
          FauxServicePriere()
            ..vueRendue = <VueEnseignantPriere>[_vue()]
            ..lieuRendu = _lieu(vendredi: true),
          taille: const Size(390, 1500),
          theme: theme,
          langue: langue,
        );
        await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-1')));
        debugPrint(
          'PNG ${await capturerVue(tester, 'priere_feuille_corriger_390_$nom')}',
        );
      });

      testWidgets('direction, la feuille Corriger, avance ouvert, $nom', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          const LieuxPrierePage(),
          FauxServicePriere()
            ..vueRendue = <VueEnseignantPriere>[_vue()]
            ..lieuRendu = _lieu(),
          taille: const Size(390, 2200),
          theme: theme,
          langue: langue,
        );
        await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-1')));
        await _toucher(
          tester,
          find.byKey(const ValueKey<String>('priere-avance')),
        );
        debugPrint(
          'PNG ${await capturerVue(tester, 'priere_feuille_avance_390_$nom')}',
        );
      });

      testWidgets('direction, la feuille d un enseignant en attente, $nom', (
        WidgetTester tester,
      ) async {
        await monter(
          tester,
          const LieuxPrierePage(),
          FauxServicePriere()
            ..vueRendue = <VueEnseignantPriere>[
              _vue(id: 'ens-2', prenom: 'Omar', aUnLieu: false),
            ],
          taille: const Size(390, 1100),
          theme: theme,
          langue: langue,
        );
        await _toucher(tester, find.byKey(LieuxPrierePage.cleLigne('ens-2')));
        debugPrint(
          'PNG ${await capturerVue(tester, 'priere_feuille_attente_390_$nom')}',
        );
      });

      testWidgets('regles, la section La priere, $nom', (
        WidgetTester tester,
      ) async {
        final _Config config = _Config(<String, Object?>{
          ..._clesRegles,
          ..._clesPriere(),
        });
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        fixerVueCapture(tester, const Size(390, 5200), 1);
        await tester.pumpWidget(
          hoteCapture(
            const ReglesPage(),
            surcharges: <Override>[
              serviceConfigurationProvider.overrideWithValue(config),
              peutReglerPolitiqueKycProvider.overrideWithValue(false),
            ],
            themeMode: theme,
          ),
        );
        await tester.pumpAndSettle();
        debugPrint(
          'PNG ${await capturerVue(tester, 'priere_regles_academie_390_$nom')}',
        );
      });
    }

    testWidgets('heures de l enseignant, erreur', (WidgetTester tester) async {
      await monter(
        tester,
        const PriereEnseignantPage(),
        _PriereEnPanne(),
        taille: const Size(390, 700),
        theme: ThemeMode.light,
        langue: AppLocale.fr,
      );
      debugPrint(
        'PNG ${await capturerVue(tester, 'priere_enseignant_erreur_390')}',
      );
    });

    testWidgets('bloc de la classe', (WidgetTester tester) async {
      final FauxServicePriere priere = FauxServicePriere();
      priere.lectures['g1'] = <LectureCreneauPriere>[
        LectureCreneauPriere(
          jour: 4,
          heure: 19,
          fuseau: 'Europe/Paris',
          dureeMinutes: 60,
          sansLieu: false,
          indefini: false,
          seances: 52,
          croisements: <CroisementPriere>[
            CroisementPriere(
              priere: Priere.maghrib,
              du: DateTime(2026, 11, 19),
              au: DateTime(2027, 3, 25),
              nbSeances: 19,
              nbPause: 15,
              nbApresCours: 4,
            ),
          ],
          vendrediAssiste: true,
          vendrediSeances: 12,
          vendrediDebut: '12:30',
          vendrediFin: '14:30',
          heuresSansPriere: const <int>[9, 10, 11],
        ),
      ];
      await monter(
        tester,
        const SingleChildScrollView(child: BlocPriereClasse(classeId: 'g1')),
        priere,
        taille: const Size(390, 900),
        theme: ThemeMode.light,
        langue: AppLocale.fr,
      );
      debugPrint('PNG ${await capturerVue(tester, 'priere_bloc_classe_390')}');
    });
  });
}
