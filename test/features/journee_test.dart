// ENS-02 Aujourd'hui (EN-2) : carte « Prochaine seance » (E11), « Ma
// journee », « A terminer » (K-45), « Alertes utiles », une ou deux colonnes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/cta_seance.dart';
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
import 'package:rewayah_academy/core/widgets/pastille_etat_seance.dart';
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../capture/outil_capture.dart'
    show
        capturer,
        chargerPolicesDuDepot,
        fixerVueCapture,
        hoteCapture,
        sautSansCapture;
import '../support/aucun_mot_coupe.dart';
import '../support/garde_interface.dart';
import '../support/harnais.dart';

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
  TextDirection? direction,
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
        child: direction == null
            ? app!
            : Directionality(textDirection: direction, child: app!),
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

void main() {
  group('ANNUL-VIS-1 : le cours annule du jour', () {
    testWidgets('pastille, horaire barre, pourquoi, surface enfoncee', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[
            _anNour(statut: StatutSeance.annulee),
          ],
      );
      final Finder carte = find.byKey(
        const ValueKey<String>('journee-cours-annule'),
      );
      expect(carte, findsOneWidget);
      expect(
        find.descendant(of: carte, matching: find.text(t.etat.seanceAnnulee)),
        findsOneWidget,
      );
      final TexteHeureSeance heure = tester.widget<TexteHeureSeance>(
        find.descendant(of: carte, matching: find.byType(TexteHeureSeance)),
      );
      expect(heure.annulee, isTrue);
      final Text texte = tester.widget<Text>(
        find.descendant(of: carte, matching: find.text(heure.heure)),
      );
      expect(texte.style!.decoration, TextDecoration.lineThrough);
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.etat.motifNonCommunique),
        ),
        findsOneWidget,
      );
      expect(tester.widget<AppCard>(carte).surface, isNotNull);
    });

    // SALLE-CORR-3 (releve VERIF-CORR-2) : la carte nomme sa Classe et y mene.
    testWidgets('nomme la Classe, « Voir la Classe » y mene', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[
                _anNour(statut: StatutSeance.annulee),
              ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder carte = find.byKey(
        const ValueKey<String>('journee-cours-annule'),
      );
      expect(
        find.descendant(of: carte, matching: find.text('An-Nour')),
        findsOneWidget,
      );
      final Finder lien = find.descendant(
        of: carte,
        matching: find.text(t.enseignant.journee.voirClasse),
      );
      expect(lien, findsOneWidget);
      await tester.ensureVisible(lien);
      await tester.tap(lien);
      await tester.pumpAndSettle();
      expect(find.text('groupe:g-an-nour'), findsOneWidget);
    });
  });

  group('SALLE-CORR-3 : captures du cours annule', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille, double texte, double densite)
        in <(String, Size, double, double)>[
          ('320_x2', const Size(320, 1400), 2, 2),
          ('390', const Size(390, 1400), 1, 3),
          ('1440', const Size(1440, 1100), 1, 1),
        ]) {
      for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        testWidgets('journee_annule_${l}_$m', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              const JourneePage(),
              surcharges: _surcharges(
                enseignant: FauxServiceEnseignant()
                  ..seancesRendues = <SeanceEnseignant>[
                    _anNour(statut: StatutSeance.annulee),
                  ],
              ),
              themeMode: mode,
              echelleTexte: texte,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.byKey(const ValueKey<String>('journee-cours-annule')),
          );
          await tester.pumpAndSettle();
          debugPrint(
            'PNG ${await capturer(tester, 'salle_corr3_journee_annule_${l}_$m')}',
          );
        });
      }
    }
  });

  group('ENS-02 : les etats de l ecran', () {
    testWidgets('chargement : un squelette, puis le contenu', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..delai = const Duration(milliseconds: 40);
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pump();
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
    });

    testWidgets('titre « Aujourd hui » et la date du jour', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      expect(find.text(t.enseignant.journee.titre), findsWidgets);
      expect(find.text('Lundi 28 septembre'), findsOneWidget);
    });

    testWidgets('vide : aucune seance, ni A terminer ni Alertes', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      expect(find.text(t.enseignant.journee.aucuneSeance), findsOneWidget);
      expect(find.text(t.enseignant.journee.rienAujourdhui), findsOneWidget);
      expect(find.text(t.enseignant.journee.aTerminer), findsNothing);
      expect(find.text(t.enseignant.journee.alertesUtiles), findsNothing);
    });

    testWidgets('erreur : une phrase, et de quoi relire', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..erreurLecture = StateError('vue absente');
      await _ouvrir(tester, enseignant: enseignant);
      expect(find.text(t.enseignant.journee.erreur), findsOneWidget);

      final int avant = enseignant.lecturesSeances;
      enseignant.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer).first);
      await tester.pumpAndSettle();
      expect(enseignant.lecturesSeances, greaterThan(avant));
    });

    testWidgets('retires : eleves en attente et cours individuel', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[
            seanceDeTest(debut: DateTime(2026, 9, 28, 17, 30)),
          ],
      );
      expect(find.text(t.enseignant.journee.enAttenteTitre), findsNothing);
      expect(find.text(t.enseignant.journee.coursIndividuel), findsNothing);
      // Une seance sans nom de Classe dit « Classe », rien d'autre.
      expect(find.text(t.enseignant.journee.classe), findsOneWidget);
    });
  });

  group('ENS-02 : la carte « Prochaine seance » (E11, E12)', () {
    testWidgets('peu de donnees : nom, heure, duree, eleves', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.enseignant.journee.prochaineSeance), findsOneWidget);
      expect(find.text('An-Nour'), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.plage(debut: '17:30', fin: '18:15')),
        findsWidgets,
      );
      expect(find.text(t.enseignant.journee.effectif(nombre: 4)), findsWidgets);
    });

    testWidgets('avant la fenetre : le contexte, puis Preparer la seance', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.enseignant.journee.preparerSeance), findsOneWidget);
      expect(find.text("Préparer l'entrée"), findsNothing);
    });

    testWidgets('fenetre ouverte : Rejoindre la salle (CTA-FIN-1)', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 17, 25),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.enseignant.journee.rejoindreSalle), findsOneWidget);
      expect(find.text("Préparer l'entrée"), findsNothing);
      expect(find.text(t.enseignant.journee.preparerSeance), findsNothing);
    });

    testWidgets('le bouton mene a la Classe', (WidgetTester tester) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[_anNour()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.enseignant.journee.preparerSeance));
      await tester.pumpAndSettle();
      expect(find.text('groupe:g-an-nour'), findsOneWidget);
    });

    testWidgets('hors ligne : la ligne d etat et Reessayer, sans bouton', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        reseau: FauxServiceReseau(horsLigneRendu: true),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.classe.entree.horsLigne), findsOneWidget);
      expect(find.text(t.enseignant.journee.preparerSeance), findsNothing);
    });
  });

  group('E11 : emplacementJournee, sans fork d EmplacementEntree', () {
    EmplacementEntree ligne(EtatEntree etat) => EmplacementEntree(
      role: RoleEntree.enseignant,
      etat: etat,
      forme: FormeEntree.ligne,
      libelle: 'contexte',
      annonce: 'annonce',
    );

    EmplacementEntree pour(
      EtatEntree etat,
      EtatCtaSeance cta, {
      EtatAbsence? absence,
    }) => emplacementJournee(
      ligne(etat),
      nomClasse: 'An-Nour',
      cta: cta,
      absence: absence,
    );

    test(
      'avant l heure : Preparer la seance, la ligne devient le contexte',
      () {
        final EmplacementEntree e = pour(
          EtatEntree.aVenir,
          EtatCtaSeance.preparer,
        );
        expect(e.estBouton, isTrue);
        expect(e.libelle, t.enseignant.journee.preparerSeance);
        expect(e.detail, 'contexte');
        expect(e.annonce, 'annonce');
      },
    );

    test(
      'pendant le creneau : Rejoindre la salle, jamais Preparer l entree',
      () {
        for (final EtatEntree etat in <EtatEntree>[
          EtatEntree.fenetreOuverte,
          EtatEntree.attente,
          EtatEntree.enDirect,
        ]) {
          final EmplacementEntree e = pour(etat, EtatCtaSeance.rejoindre);
          expect(e.estBouton, isTrue);
          expect(e.libelle, t.enseignant.journee.rejoindreSalle);
          expect(e.libelle, isNot("Préparer l'entrée"));
          expect(e.libelleLecteur, contains('An-Nour'));
        }
      },
    );

    test(
      'temps ecoule, cahier non depose : Remplir le cahier, obligatoire',
      () {
        final EmplacementEntree e = pour(
          EtatEntree.terminee,
          EtatCtaSeance.remplirCahier,
        );
        expect(e.estBouton, isTrue);
        expect(e.libelle, t.enseignant.journee.remplirCahier);
        expect(
          e.detail,
          t.enseignant.journee.cahierObligatoire(classe: "d'An-Nour"),
        );
        expect(e.libelleLecteur, contains('An-Nour'));
      },
    );

    test('cahier depose : une ligne seule, le lien est rendu par la carte', () {
      final EmplacementEntree e = pour(
        EtatEntree.terminee,
        EtatCtaSeance.voirCahier,
      );
      expect(e.estBouton, isFalse);
    });

    test('annulee : Voir la Classe', () {
      expect(
        pour(EtatEntree.annulee, EtatCtaSeance.voirClasse).libelle,
        t.enseignant.journee.voirClasse,
      );
    });

    test('absence declaree : Voir la Classe, sauf demande annulee', () {
      for (final EtatAbsence absence in EtatAbsence.values) {
        final EmplacementEntree e = pour(
          EtatEntree.aVenir,
          EtatCtaSeance.preparer,
          absence: absence,
        );
        expect(
          e.libelle,
          absence == EtatAbsence.demandeAnnulee
              ? t.enseignant.journee.preparerSeance
              : t.enseignant.journee.voirClasse,
        );
      }
    });

    test('jamais de bouton grise : chaque etat porte un libelle plein', () {
      for (final EtatCtaSeance cta in EtatCtaSeance.values) {
        final EmplacementEntree e = pour(EtatEntree.aVenir, cta);
        expect(e.libelle, isNotEmpty);
        expect(e.reessayer, isFalse);
      }
    });

    test('preparation et reessai restent tels quels (jamais grise)', () {
      final EmplacementEntree prep = ligne(EtatEntree.preparation);
      expect(
        emplacementJournee(
          prep,
          nomClasse: 'x',
          cta: EtatCtaSeance.remplirCahier,
        ),
        same(prep),
      );
      const EmplacementEntree reessai = EmplacementEntree(
        role: RoleEntree.enseignant,
        etat: EtatEntree.indisponible,
        forme: FormeEntree.ligne,
        libelle: 'hors ligne',
        annonce: 'hors ligne',
        reessayer: true,
      );
      expect(
        emplacementJournee(
          reessai,
          nomClasse: 'x',
          cta: EtatCtaSeance.remplirCahier,
        ),
        same(reessai),
      );
    });
  });

  group('CTA-FIN-1 : le bouton de la carte selon le moment', () {
    // La seance An-Nour : 17 h 30 a 18 h 15 ; la salle ouvre a 17 h 20.
    Future<void> carte(
      WidgetTester tester,
      DateTime maintenant, {
      StatutSeance statut = StatutSeance.planifiee,
      bool depose = false,
      Size taille = const Size(390, 2400),
      double texte = 1,
      Brightness theme = Brightness.light,
    }) async {
      _fenetre(tester, taille);
      await tester.pumpWidget(
        _hoteCarte(
          luminosite: theme,
          echelleTexte: texte,
          surcharges: _surcharges(
            maintenant: maintenant,
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[
                seanceDeTest(
                  id: 'an-nour',
                  debut: DateTime(2026, 9, 28, 17, 30),
                  statut: statut,
                  nbParticipants: 4,
                  cahierDepose: depose,
                  groupeId: 'g-an-nour',
                  groupeLibelle: 'An-Nour',
                ),
              ],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final Finder pastille = find.text(t.etat.enDirect);

    testWidgets('avant l heure : Preparer la seance, sans pastille', (
      WidgetTester tester,
    ) async {
      await carte(tester, DateTime(2026, 9, 28, 16));
      expect(find.text(t.enseignant.journee.preparerSeance), findsOneWidget);
      expect(find.text(t.enseignant.journee.rejoindreSalle), findsNothing);
      expect(pastille, findsNothing);
    });

    testWidgets('pendant le creneau : Rejoindre la salle et En direct', (
      WidgetTester tester,
    ) async {
      await carte(
        tester,
        DateTime(2026, 9, 28, 17, 40),
        statut: StatutSeance.enCours,
      );
      expect(find.text(t.enseignant.journee.rejoindreSalle), findsOneWidget);
      expect(find.text(t.enseignant.journee.preparerSeance), findsNothing);
      expect(find.text("Préparer l'entrée"), findsNothing);
      expect(pastille, findsOneWidget);
    });

    testWidgets('un cours qui deborde garde Rejoindre la salle', (
      WidgetTester tester,
    ) async {
      await carte(
        tester,
        DateTime(2026, 9, 28, 18, 50),
        statut: StatutSeance.enCours,
      );
      expect(find.text(t.enseignant.journee.rejoindreSalle), findsOneWidget);
      expect(find.text(t.enseignant.journee.remplirCahier), findsNothing);
      expect(pastille, findsOneWidget);
    });

    testWidgets('temps ecoule, cahier non depose : Remplir le cahier', (
      WidgetTester tester,
    ) async {
      await carte(
        tester,
        DateTime(2026, 9, 28, 18, 40),
        statut: StatutSeance.terminee,
      );
      expect(find.text(t.enseignant.journee.remplirCahier), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.cahierObligatoire(classe: "d'An-Nour")),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.journee.rejoindreSalle), findsNothing);
      expect(pastille, findsNothing);
    });

    testWidgets('Rejoindre la salle ouvre la salle par son pre-vol', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            maintenant: DateTime(2026, 9, 28, 17, 40),
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[
                _anNour(statut: StatutSeance.enCours),
              ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.enseignant.journee.rejoindreSalle));
      await tester.pumpAndSettle();
      expect(find.text('salle:an-nour:true:g-an-nour'), findsOneWidget);
    });

    testWidgets('Remplir le cahier ouvre le cahier de la seance', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            maintenant: DateTime(2026, 9, 28, 18, 40),
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[
                _anNour(statut: StatutSeance.terminee),
              ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.enseignant.journee.remplirCahier));
      await tester.pumpAndSettle();
      expect(find.text('cahier:an-nour'), findsOneWidget);
    });

    testWidgets('cahier depose : Voir le cahier en lien, sans bouton plein', (
      WidgetTester tester,
    ) async {
      await carte(
        tester,
        DateTime(2026, 9, 28, 18, 40),
        statut: StatutSeance.terminee,
        depose: true,
      );
      final Finder lien = find.byKey(
        const ValueKey<String>('journee-voir-cahier'),
      );
      expect(lien, findsOneWidget);
      expect(
        find.text(t.enseignant.journee.voirCahier(classe: "d'An-Nour")),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.journee.remplirCahier), findsNothing);
      expect(find.text(t.enseignant.journee.rejoindreSalle), findsNothing);
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('Voir le cahier ouvre le cahier de la seance', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            maintenant: DateTime(2026, 9, 28, 18, 40),
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[
                seanceDeTest(
                  id: 'an-nour',
                  debut: DateTime(2026, 9, 28, 17, 30),
                  statut: StatutSeance.terminee,
                  cahierDepose: true,
                  groupeId: 'g-an-nour',
                  groupeLibelle: 'An-Nour',
                ),
              ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('journee-voir-cahier')),
      );
      await tester.pumpAndSettle();
      expect(find.text('cahier:an-nour'), findsOneWidget);
    });

    testWidgets('l etat se rafraichit a la minute : la salle ouvre', (
      WidgetTester tester,
    ) async {
      DateTime maintenant = DateTime(2026, 9, 28, 17, 19);
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            horloge: () => maintenant,
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[_anNour()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.journee.preparerSeance), findsOneWidget);
      maintenant = DateTime(2026, 9, 28, 17, 21);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.journee.rejoindreSalle), findsOneWidget);
      expect(find.text(t.enseignant.journee.preparerSeance), findsNothing);
    });

    final List<(String, Size, double, Brightness)>
    vues = <(String, Size, double, Brightness)>[
      ('320 px, texte x1, clair', const Size(320, 2400), 1, Brightness.light),
      ('320 px, texte x2, clair', const Size(320, 2400), 2, Brightness.light),
      ('320 px, texte x2, sombre', const Size(320, 2400), 2, Brightness.dark),
      ('1440 px, texte x1, clair', const Size(1440, 1000), 1, Brightness.light),
      ('1440 px, texte x2, sombre', const Size(1440, 1000), 2, Brightness.dark),
    ];
    final List<(String, DateTime, StatutSeance, String)> moments =
        <(String, DateTime, StatutSeance, String)>[
          (
            'avant l heure',
            DateTime(2026, 9, 28, 16),
            StatutSeance.planifiee,
            t.enseignant.journee.preparerSeance,
          ),
          (
            'pendant le creneau',
            DateTime(2026, 9, 28, 17, 40),
            StatutSeance.enCours,
            t.enseignant.journee.rejoindreSalle,
          ),
          (
            'temps ecoule',
            DateTime(2026, 9, 28, 18, 40),
            StatutSeance.terminee,
            t.enseignant.journee.remplirCahier,
          ),
        ];
    for (final (String, Size, double, Brightness) vue in vues) {
      for (final (String, DateTime, StatutSeance, String) moment in moments) {
        testWidgets(
          'le bouton reste centre et dans l ecran, ${moment.$1} : ${vue.$1}',
          (WidgetTester tester) async {
            await carte(
              tester,
              moment.$2,
              statut: moment.$3,
              taille: vue.$2,
              texte: vue.$3,
              theme: vue.$4,
            );
            verifierBoutonCentre(
              tester,
              find.byType(ActionPrincipale).first,
              moment.$4,
            );
            final Object? exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason: exception is FlutterError
                  ? exception.toStringDeep()
                  : '$exception',
            );
          },
        );
      }
    }
  });

  group('ENS-02 : Ma journee', () {
    testWidgets('cours, pause et prieres dans la meme colonne', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: DateTime(2026, 9, 28, 9),
            duree: const Duration(hours: 1),
            groupeId: 'g1',
            groupeLibelle: 'An-Nour',
            nbParticipants: 4,
          ),
          seanceDeTest(
            id: 's2',
            debut: DateTime(2026, 9, 28, 10, 30),
            duree: const Duration(hours: 1),
            groupeId: 'g2',
            groupeLibelle: 'Al-Badr',
            nbParticipants: 3,
          ),
        ];
      final FauxServicePriere priere = FauxServicePriere()
        ..parEnseignant[_monId] = _paris;
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 8),
        enseignant: enseignant,
        priere: priere,
        regles: _reglesAvecPause(30),
      );

      expect(find.text(t.enseignant.journee.maJournee), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.classeNommee(classe: 'Al-Badr')),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.journee.lignePause), findsOneWidget);
      final List<InterruptionPriere> interruptions = interruptionsEntre(
        reglages: _paris,
        debut: DateTime(2026, 9, 28),
        fin: DateTime(2026, 9, 29),
      );
      expect(interruptions, isNotEmpty);
      for (final InterruptionPriere interruption in interruptions) {
        expect(find.text(libellePriere(interruption.priere)), findsWidgets);
      }
    });
  });

  group('ENS-02 : A terminer (K-45)', () {
    testWidgets('trois cahiers au plus, une phrase qui aide, le point', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..retardsRendus = <CahierEnRetard>[
            _cahier('a', 'Al-Badr', 26),
            _cahier('b', 'An-Nour', 24),
            _cahier('c', 'Al-Fatiha', 23),
            _cahier('d', 'Al-Ikhlas', 22),
          ],
      );
      expect(find.text(t.enseignant.journee.aTerminer), findsOneWidget);
      expect(find.text(t.enseignant.journee.aTerminerAide), findsOneWidget);
      expect(find.byType(PointRappel), findsOneWidget);
      // Le plus ancien d'abord (Q9) : Al-Badr, le plus recent, attend « Voir tout ».
      expect(
        find.text(
          t.enseignant.journee.cahierLigne(classe: deDevant('Al-Ikhlas')),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          t.enseignant.journee.cahierLigne(classe: deDevant('Al-Fatiha')),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          t.enseignant.journee.cahierLigne(classe: deDevant('Al-Badr')),
        ),
        findsNothing,
      );
    });

    testWidgets('la ligne mene au cahier de la seance', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          t.enseignant.journee.cahierLigne(classe: deDevant('Al-Badr')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('cahier:a'), findsOneWidget);
    });

    testWidgets('le point pulse quelques secondes, puis reste fixe', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey<String>('point-rappel-halo')), findsOne);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('point-rappel-halo')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('point-rappel')), findsOne);
    });

    testWidgets('mouvement reduit : le point est fixe d emblee', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const ValueKey<String>('point-rappel-halo')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('point-rappel')), findsOne);
    });
  });

  group('ENS-02 : Alertes utiles', () {
    testWidgets('une absence pendant le cours se dit avec un prenom', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 17, 40),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[
            _anNour(statut: StatutSeance.enCours),
          ],
        presence: FauxServicePresence(
          lignes: <PresenceParticipant>[
            _presence(etat: EtatPresence.presente, prenom: 'Yusuf'),
            _presence(
              etat: EtatPresence.absente,
              profilId: 'e2',
              prenom: 'Maryam',
            ),
          ],
        ),
      );
      expect(find.text(t.enseignant.journee.alertesUtiles), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Maryam')),
        findsOneWidget,
      );
    });

    testWidgets('une presence inconnue n est pas une alerte', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 17, 40),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[
            _anNour(statut: StatutSeance.enCours),
          ],
      );
      expect(find.text(t.enseignant.journee.alertesUtiles), findsNothing);
    });
  });

  group('ENS-02 : une ou deux colonnes', () {
    Future<void> journeeComplete(WidgetTester tester, Size taille) => _ouvrir(
      tester,
      taille: taille,
      enseignant: FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[_anNour()]
        ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
    );

    // BENTO-2 (DASH_STRATEGIE.md §3.5) : Ma journee a droite de la carte,
    // A terminer (rang 4) sous la carte, dans la meme colonne.
    testWidgets('bureau : Ma journee a droite, A terminer sous la carte', (
      WidgetTester tester,
    ) async {
      await journeeComplete(tester, const Size(1440, 1000));
      final Offset carte = tester.getTopLeft(find.text('An-Nour'));
      final double xJournee = tester
          .getTopLeft(find.text(t.enseignant.journee.maJournee))
          .dx;
      final Offset cahiers = tester.getTopLeft(
        find.text(t.enseignant.journee.aTerminer),
      );
      expect(xJournee, greaterThan(carte.dx + 300));
      expect(cahiers.dx, lessThan(carte.dx + 300));
      expect(cahiers.dy, greaterThan(carte.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile : une colonne, A terminer sous Ma journee', (
      WidgetTester tester,
    ) async {
      await journeeComplete(tester, const Size(390, 2400));
      final double yJournee = tester
          .getTopLeft(find.text(t.enseignant.journee.maJournee))
          .dy;
      final double yCahiers = tester
          .getTopLeft(find.text(t.enseignant.journee.aTerminer))
          .dy;
      expect(yCahiers, greaterThan(yJournee));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 200 % de texte sur mobile, rien ne deborde', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await journeeComplete(tester, const Size(390, 2400));
      expect(tester.takeException(), isNull);
    });
  });

  group('BENTO-2b/2c : « A terminer » ne coupe aucun mot', () {
    // Les mesures de texte n'ont de sens qu'avec les vraies polices.
    setUpAll(chargerPolicesDuDepot);

    // BENTO-2c (M1 de BENTO-2b-R) : avec 4 cahiers, « Voir tout » s'affiche
    // et ne laissait au titre que ~160 px a 320 x2 (« termi/ner »,
    // « Obligatoi/re »). On mesure tout le bloc (la `Column` de
    // « A terminer », qui existait deja avant le correctif), pas seulement
    // l'en-tete.
    final List<CahierEnRetard> quatre = <CahierEnRetard>[
      _cahier('a', 'Al-Badr', 26),
      _cahier('b', 'As-Salam', 25),
      _cahier('c', 'Al-Fatiha', 23),
      _cahier('d', 'Al-Ikhlas', 22),
    ];
    for (final int nombre in const <int>[2, 4]) {
      for (final (double, double) cas in const <(double, double)>[
        (320, 1),
        (320, 2),
        (390, 2),
        (768, 1),
        (768, 2),
      ]) {
        for (final TextDirection sens in TextDirection.values) {
          testWidgets('$nombre cahiers, ${cas.$1.toInt()} px, '
              'texte x${cas.$2.toInt()}, ${sens.name}', (
            WidgetTester tester,
          ) async {
            _fenetre(tester, Size(cas.$1, 3000));
            await tester.pumpWidget(
              _hoteCarte(
                luminosite: Brightness.light,
                echelleTexte: cas.$2,
                direction: sens,
                surcharges: _surcharges(
                  enseignant: FauxServiceEnseignant()
                    ..seancesRendues = <SeanceEnseignant>[_anNour()]
                    ..retardsRendus = quatre.take(nombre).toList(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final Finder titre = find.text(t.enseignant.journee.aTerminer);
            expect(titre, findsOneWidget);
            final Finder voirTout = find.byKey(
              const ValueKey<String>('journee-a-terminer-voir-tout'),
            );
            expect(voirTout, nombre > 3 ? findsOneWidget : findsNothing);
            final Finder bloc = find
                .ancestor(of: titre, matching: find.byType(Column))
                .first;
            expect(bloc, findsOneWidget);
            // Le bloc contient bien ce qu'on mesure : titre, pastille,
            // lignes de cahier et, avec 4 cahiers, « Voir tout ».
            expect(
              find.descendant(
                of: bloc,
                matching: find.text(t.enseignant.cahier.obligatoire),
              ),
              findsOneWidget,
            );
            if (nombre > 3) {
              expect(
                find.descendant(of: bloc, matching: voirTout),
                findsOneWidget,
              );
            }
            verifierAucunMotCoupe(tester, bloc);
            // « Voir tout » ne sort pas du bloc et reste une cible entiere.
            if (nombre > 3) {
              final Rect rBloc = tester.getRect(bloc);
              final Rect rLien = tester.getRect(voirTout);
              expect(rLien.left, greaterThanOrEqualTo(rBloc.left - 0.5));
              expect(rLien.right, lessThanOrEqualTo(rBloc.right + 0.5));
            }
          });
        }
      }
    }
  });
}
