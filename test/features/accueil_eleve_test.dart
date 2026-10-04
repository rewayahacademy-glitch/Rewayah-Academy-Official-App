import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/libelle_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bento_tile.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';

import '../support/harnais.dart';

const String _enseignantId = 't1';

/// L'instant de reference de tous ces tests.
///
/// Un mardi a dix-sept heures. Fige, et non `DateTime.now()` : les six etats de
/// `ELV-02` se distinguent par des minutes, et un test cale sur l'horloge de la
/// machine changerait de resultat selon l'heure a laquelle la CI le lance. Le
/// dernier quart d'heure avant minuit suffirait a faire basculer « cours dans
/// 25 minutes » en « aucun cours aujourd'hui ».
final DateTime _maintenant = DateTime(2026, 9, 8, 17);

const ReglagesPriere _paris = ReglagesPriere(
  enseignantId: _enseignantId,
  latitude: 48.85341,
  longitude: 2.34880,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  lieu: 'Paris',
);

/// Une seance de l'eleve observe.
Seance _cours({
  required DateTime debut,
  required DateTime fin,
  String id = 's1',
  StatutSeance statut = StatutSeance.planifiee,
}) => Seance(
  id: id,
  debut: debut,
  fin: fin,
  statut: statut,
  eleveId: 'e1',
  elevePrenom: 'Khadija',
  eleveIdentifiant: 'STUD-KB-000003',
  enseignantId: _enseignantId,
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'TEACH-AD-000001',
);

List<Override> _surcharges({
  required FauxServicePlanning planning,
  FauxServicePriere? priere,
  bool horsLigne = false,
}) => <Override>[
  servicePlanningProvider.overrideWithValue(planning),
  servicePriereProvider.overrideWithValue(priere ?? FauxServicePriere()),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
];

/// L'ecran, a l'instant de reference.
Widget _ecran() => AccueilElevePage(horloge: () => _maintenant);

/// L'ecran, avec les animations reduites.
///
/// La pulsation du bloc imminent tourne en boucle : `pumpAndSettle` attendrait
/// une stabilite qui n'arrive jamais. Le widget respecte deja la demande
/// systeme de reduction des animations, et le test s'en sert comme d'une
/// fenetre stable. C'est la meme idee que la fenetre haute de `ENS-02`, qui
/// mesurait la hauteur du viewport au lieu du contenu.
class _SansAnimation extends StatelessWidget {
  const _SansAnimation({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  );
}

/// La premiere interruption de priere qui suit l'instant de reference, et la
/// seance qui la contient.
///
/// Construire la seance **autour** d'une priere reelle plutot que d'esperer
/// qu'une priere tombe pendant une seance choisie au hasard : les cinq horaires
/// bougent chaque jour, et un test qui suppose « il y a forcement une priere
/// entre 17 h et 18 h » finit par etre faux un mois plus tard.
({Seance seance, InterruptionPriere interruption}) _seanceAvecPriere() {
  final List<InterruptionPriere> suivantes = interruptionsEntre(
    reglages: _paris,
    debut: _maintenant,
    fin: _maintenant.add(const Duration(days: 1)),
  );
  final InterruptionPriere premiere = suivantes.first;
  return (
    seance: _cours(
      debut: premiere.debut.subtract(const Duration(minutes: 10)),
      fin: premiere.fin.add(const Duration(minutes: 10)),
    ),
    interruption: premiere,
  );
}

/// L'heure locale d'un instant, comme l'ecran l'ecrit.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

void main() {
  testWidgets('la premiere lecture montre un squelette', (
    WidgetTester tester,
  ) async {
    final Completer<List<Seance>> reponse = Completer<List<Seance>>();
    final FauxServicePlanning planning = FauxServicePlanning();

    await tester.pumpWidget(
      hote(
        _ecran(),
        surcharges: <Override>[
          ..._surcharges(planning: planning),
          seancesProvider.overrideWith((_) => reponse.future),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(Skeleton), findsOneWidget);
    expect(find.text(t.commun.chargement), findsNothing);

    reponse.complete(const <Seance>[]);
    await tester.pumpAndSettle();
  });

  group('ELV-02 : les six etats du bloc principal', () {
    testWidgets('un cours plus tard annonce le temps qui reste, et le prenom', (
      WidgetTester tester,
    ) async {
      final DateTime debut = _maintenant.add(const Duration(minutes: 25));
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: debut, fin: debut.add(const Duration(minutes: 60))),
        ];

      await tester.pumpWidget(
        hote(_ecran(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.eleve.accueil.prochainCours), findsOneWidget);
      expect(
        find.text(t.eleve.accueil.dansMinutes(minutes: '25')),
        findsOneWidget,
      );
      // Le prenom de l'enseignante, jamais son nom de famille (ADR-008).
      expect(
        find.text(t.eleve.accueil.avec(prenom: 'Aminata')),
        findsOneWidget,
      );
    });

    testWidgets('a moins de cinq minutes, le bloc devient violet et pulse', (
      WidgetTester tester,
    ) async {
      final DateTime debut = _maintenant.add(const Duration(minutes: 4));
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: debut, fin: debut.add(const Duration(minutes: 60))),
        ];

      await tester.pumpWidget(
        hote(_ecran(), surcharges: _surcharges(planning: planning)),
      );
      // Pas de `pumpAndSettle` : la pulsation tourne en boucle. Deux frames
      // suffisent a la voir demarrer.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final BentoTile principal = tester.widget<BentoTile>(
        find.byType(BentoTile).first,
      );
      final AppPalette palette = AppPalette.claire();
      expect(principal.surface, palette.surfacePrimary);
      expect(principal.contourFort, isFalse);
      expect(find.byKey(clePulsationImminente), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);

      // Demonter l'ecran arrete la pulsation : sinon le ticker de la repetition
      // survivrait au test.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'sous mouvement reduit, une bordure fixe remplace la pulsation',
      (WidgetTester tester) async {
        // `04-systeme-mouvement.md` section 5 : une animation qui porte du sens
        // n'est pas supprimee, elle est remplacee. La pulsation d'imminence
        // devient une bordure `borderStrong` fixe, et l'information survit.
        final DateTime debut = _maintenant.add(const Duration(minutes: 4));
        final FauxServicePlanning planning = FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(debut: debut, fin: debut.add(const Duration(minutes: 60))),
          ];

        await tester.pumpWidget(
          hote(
            const _SansAnimation(child: _EcranFige()),
            surcharges: _surcharges(planning: planning),
          ),
        );
        await tester.pumpAndSettle();

        final BentoTile principal = tester.widget<BentoTile>(
          find.byType(BentoTile).first,
        );
        expect(principal.surface, AppPalette.claire().surfacePrimary);
        expect(principal.contourFort, isTrue);
        expect(find.byKey(clePulsationImminente), findsNothing);
      },
    );

    testWidgets('le meme cours une heure plus tot ne pulse pas', (
      WidgetTester tester,
    ) async {
      final DateTime debut = _maintenant.add(const Duration(minutes: 40));
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: debut, fin: debut.add(const Duration(minutes: 60))),
        ];

      await tester.pumpWidget(
        hote(_ecran(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      // La mesure vaut dans les deux sens, comme le plafond de `ENS-06` : la
      // meme seance, quarante minutes plus tot, redevient une carte normale,
      // sur la surface elevee par defaut et sans aplat plein.
      final BentoTile principal = tester.widget<BentoTile>(
        find.byType(BentoTile).first,
      );
      expect(principal.surface, isNull);
      expect(principal.contourFort, isFalse);
      expect(find.byKey(clePulsationImminente), findsNothing);
    });

    testWidgets('un cours commence porte Rejoindre et la pastille verte', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(
            debut: _maintenant.subtract(const Duration(minutes: 10)),
            fin: _maintenant.add(const Duration(minutes: 50)),
            statut: StatutSeance.enCours,
          ),
        ];

      await tester.pumpWidget(
        hote(_ecran(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.eleve.accueil.coursEnDirect), findsOneWidget);
      expect(
        find.text(t.eleve.accueil.avec(prenom: 'Aminata')),
        findsOneWidget,
      );
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byType(ActionPrincipale),
      );
      expect(bouton.libelle, t.eleve.accueil.rejoindre);
      expect(bouton.onPress, isNotNull);
    });

    testWidgets('sans cours aujourd hui, le prochain se dit en jours', (
      WidgetTester tester,
    ) async {
      final DateTime debut = _maintenant.add(const Duration(days: 3));
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: debut, fin: debut.add(const Duration(minutes: 60))),
        ];

      await tester.pumpWidget(
        hote(_ecran(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.eleve.accueil.aucunCours), findsOneWidget);
      expect(
        find.text(t.eleve.accueil.prochainDansJours(jours: '3')),
        findsOneWidget,
      );
      // En jours, jamais en date : ni le jour de la semaine, ni l'heure.
      expect(find.text(_hhmm(debut)), findsNothing);
      expect(
        find.text(t.disponibilites.joursLongs[debut.weekday - 1]),
        findsNothing,
      );
    });

    testWidgets('une seance annulee ne dit ni statut ni motif', (
      WidgetTester tester,
    ) async {
      final DateTime debut = _maintenant.subtract(const Duration(minutes: 10));
      final DateTime demain = _maintenant.add(const Duration(days: 1));
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(
            debut: debut,
            fin: debut.add(const Duration(minutes: 60)),
            statut: StatutSeance.annulee,
          ),
          _cours(
            id: 's2',
            debut: demain,
            fin: demain.add(const Duration(minutes: 60)),
          ),
        ];

      await tester.pumpWidget(
        hote(_ecran(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.eleve.accueil.annulee), findsOneWidget);
      expect(find.text(t.eleve.accueil.prochainDemain), findsOneWidget);
      // Aucune explication technique : le statut de la base ne remonte pas a
      // l'ecran, sous aucune forme.
      expect(find.textContaining(StatutSeance.annulee.valeurSql), findsNothing);
      // Et le cours annule ne se propose pas a rejoindre.
      expect(find.byType(ActionPrincipale), findsNothing);
    });

    testWidgets('hors ligne, le bloc Rejoindre reste present mais inerte', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(
            debut: _maintenant.subtract(const Duration(minutes: 10)),
            fin: _maintenant.add(const Duration(minutes: 50)),
            statut: StatutSeance.enCours,
          ),
        ];

      await tester.pumpWidget(
        hote(
          _ecran(),
          surcharges: _surcharges(planning: planning, horsLigne: true),
        ),
      );
      await tester.pumpAndSettle();

      // L'ecran reste identique : le cours est toujours annonce.
      expect(find.text(t.eleve.accueil.coursEnDirect), findsOneWidget);
      // Seul le bloc Rejoindre change, et il ne disparait pas : une panne de
      // reseau n'est pas une limite de droit, et un bouton absent ferait croire
      // que le cours n'existe plus.
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byType(ActionPrincipale),
      );
      expect(bouton.onPress, isNull);
      expect(find.text(t.eleve.accueil.horsLigne), findsOneWidget);
      expect(find.text(t.eleve.accueil.horsLigneDetail), findsOneWidget);
    });
  });

  group('ELV-02 : deux blocs, rien d autre', () {
    testWidgets('quel que soit l etat, l ecran ne rend que deux blocs', (
      WidgetTester tester,
    ) async {
      for (final FauxServicePlanning planning in <FauxServicePlanning>[
        FauxServicePlanning(),
        FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(
              debut: _maintenant.subtract(const Duration(minutes: 10)),
              fin: _maintenant.add(const Duration(minutes: 50)),
              statut: StatutSeance.enCours,
            ),
          ],
        FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(
              debut: _maintenant.add(const Duration(days: 2)),
              fin: _maintenant.add(const Duration(days: 2, minutes: 60)),
            ),
          ],
      ]) {
        await tester.pumpWidget(
          hote(_ecran(), surcharges: _surcharges(planning: planning)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BentoTile), findsNWidgets(2));
      }
    });

    testWidgets('le second bloc mene au Coran', (WidgetTester tester) async {
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.eleve,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.eleve,
              builder: (BuildContext _, GoRouterState _) => _ecran(),
            ),
            GoRoute(
              path: Routes.eleveCoran,
              builder: (BuildContext _, GoRouterState _) =>
                  const Text('ELV-04'),
            ),
          ],
          surcharges: _surcharges(planning: FauxServicePlanning()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.eleve.accueil.coran), findsOneWidget);
      await tester.tap(find.text(t.eleve.accueil.coranDetail));
      await tester.pumpAndSettle();

      expect(find.text('ELV-04'), findsOneWidget);
    });
  });

  group(
    'ELV-02 : les interruptions de priere sont annoncees avant le cours',
    () {
      testWidgets('en mode standard, chaque interruption se lit en clair', (
        WidgetTester tester,
      ) async {
        final ({Seance seance, InterruptionPriere interruption}) cas =
            _seanceAvecPriere();
        final FauxServicePlanning planning = FauxServicePlanning()
          ..seancesRendues = <Seance>[cas.seance];
        final FauxServicePriere priere = FauxServicePriere()
          ..parEnseignant[_enseignantId] = _paris;

        await tester.pumpWidget(
          hote(
            _ecran(),
            surcharges: _surcharges(planning: planning, priere: priere),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(t.eleve.accueil.pausePriere), findsOneWidget);
        expect(
          find.text(
            t.eleve.accueil.pausePriereDetail(
              priere: libellePriere(cas.interruption.priere),
              heure: _hhmm(cas.interruption.debut),
            ),
          ),
          findsOneWidget,
        );
      });

      testWidgets('en mode enfant, le libelle parle remplace le detail', (
        WidgetTester tester,
      ) async {
        final ({Seance seance, InterruptionPriere interruption}) cas =
            _seanceAvecPriere();
        final FauxServicePlanning planning = FauxServicePlanning()
          ..seancesRendues = <Seance>[cas.seance];
        final FauxServicePriere priere = FauxServicePriere()
          ..parEnseignant[_enseignantId] = _paris;

        await tester.pumpWidget(
          hote(
            _ecran(),
            surcharges: _surcharges(planning: planning, priere: priere),
            mode: InterfaceMode.enfant,
          ),
        );
        await tester.pumpAndSettle();

        // Le pictogramme et le libelle parle restent, l'heure et le nom de la
        // priere disparaissent : a six ans, on ne lit ni l'un ni l'autre.
        expect(find.text(t.eleve.accueil.pausePriere), findsOneWidget);
        expect(
          find.text(
            t.eleve.accueil.pausePriereDetail(
              priere: libellePriere(cas.interruption.priere),
              heure: _hhmm(cas.interruption.debut),
            ),
          ),
          findsNothing,
        );
      });

      testWidgets(
        'sans reglages lisibles, aucune interruption n est annoncee',
        (WidgetTester tester) async {
          final ({Seance seance, InterruptionPriere interruption}) cas =
              _seanceAvecPriere();
          final FauxServicePlanning planning = FauxServicePlanning()
            ..seancesRendues = <Seance>[cas.seance];

          await tester.pumpWidget(
            // Le meme cours, sans les reglages de l'enseignant : mieux vaut
            // n'annoncer aucune interruption qu'une fausse.
            hote(_ecran(), surcharges: _surcharges(planning: planning)),
          );
          await tester.pumpAndSettle();

          expect(find.text(t.eleve.accueil.pausePriere), findsNothing);
        },
      );
    },
  );

  group('ELV-02 : l etat se decide sans monter d ecran', () {
    final Seance enCours = _cours(
      debut: _maintenant.subtract(const Duration(minutes: 10)),
      fin: _maintenant.add(const Duration(minutes: 50)),
      statut: StatutSeance.enCours,
    );

    test('le hors ligne ne change que le cours en direct', () {
      expect(
        etatAccueilEleve(
          prochain: enCours,
          annulee: null,
          maintenant: _maintenant,
          horsLigne: false,
        ),
        EtatAccueilEleve.coursEnDirect,
      );
      expect(
        etatAccueilEleve(
          prochain: enCours,
          annulee: null,
          maintenant: _maintenant,
          horsLigne: true,
        ),
        EtatAccueilEleve.horsLigne,
      );
    });

    test('le seuil d imminence est de cinq minutes, bornes comprises', () {
      Seance dans(Duration attente) {
        final DateTime debut = _maintenant.add(attente);
        return _cours(debut: debut, fin: debut.add(const Duration(hours: 1)));
      }

      expect(
        etatAccueilEleve(
          prochain: dans(seuilImminence),
          annulee: null,
          maintenant: _maintenant,
          horsLigne: false,
        ),
        EtatAccueilEleve.coursImminent,
      );
      expect(
        etatAccueilEleve(
          prochain: dans(seuilImminence + const Duration(minutes: 1)),
          annulee: null,
          maintenant: _maintenant,
          horsLigne: false,
        ),
        EtatAccueilEleve.coursPlusTard,
      );
    });

    test('une annulation ne passe devant que si elle vient avant', () {
      final Seance annuleeTot = _cours(
        id: 's0',
        debut: _maintenant.subtract(const Duration(minutes: 5)),
        fin: _maintenant.add(const Duration(minutes: 55)),
        statut: StatutSeance.annulee,
      );
      final Seance plusTard = _cours(
        id: 's2',
        debut: _maintenant.add(const Duration(hours: 3)),
        fin: _maintenant.add(const Duration(hours: 4)),
      );

      expect(
        etatAccueilEleve(
          prochain: plusTard,
          annulee: annuleeTot,
          maintenant: _maintenant,
          horsLigne: false,
        ),
        EtatAccueilEleve.seanceAnnulee,
      );
      // L'inverse : un cours qui vient avant l'annulation garde le bloc.
      expect(
        etatAccueilEleve(
          prochain: _cours(
            id: 's3',
            debut: _maintenant.add(const Duration(minutes: 30)),
            fin: _maintenant.add(const Duration(minutes: 90)),
          ),
          annulee: _cours(
            id: 's4',
            debut: _maintenant.add(const Duration(hours: 5)),
            fin: _maintenant.add(const Duration(hours: 6)),
            statut: StatutSeance.annulee,
          ),
          maintenant: _maintenant,
          horsLigne: false,
        ),
        EtatAccueilEleve.coursPlusTard,
      );
    });

    test('le compte de jours ne depend pas du fuseau de la machine', () {
      // Les deux nuits de changement d'heure europeen de 2026. Un `inDays` pose
      // sur deux minuits **locaux** rendrait zero pour la nuit de mars, qui ne
      // dure que vingt-trois heures, et « demain » designerait apres-demain.
      //
      // Ce test ne le demontrerait pas a lui seul : ce poste est a UTC+3 sans
      // heure d'ete, et la CI tourne en UTC, donc les deux nuits y durent
      // vingt-quatre heures. C'est justement pourquoi la fonction repose ses
      // dates en UTC : le resultat cesse de dependre de la machine qui mesure,
      // et ce test vaut alors partout au lieu de valoir ici.
      expect(
        joursCivilsEntre(DateTime(2026, 3, 28, 23), DateTime(2026, 3, 29, 1)),
        1,
      );
      expect(
        joursCivilsEntre(DateTime(2026, 10, 24, 23), DateTime(2026, 10, 25, 1)),
        1,
      );
      expect(
        joursCivilsEntre(_maintenant, _maintenant.add(const Duration(days: 3))),
        3,
      );
      // Le meme jour, a n'importe quelle heure, ne compte aucun jour.
      expect(
        joursCivilsEntre(DateTime(2026, 9, 8, 1), DateTime(2026, 9, 8, 23)),
        0,
      );
    });
  });

  group('DASH-ELV-ERR : une lecture en echec n est pas « aucun cours »', () {
    testWidgets('l echec le dit, propose de relire, et garde le Coran', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await tester.pumpWidget(
        hote(
          _ecran(),
          surcharges: <Override>[
            ..._surcharges(planning: FauxServicePlanning()),
            seancesProvider.overrideWith((_) async {
              lectures++;
              if (lectures == 1) {
                throw StateError('reseau');
              }
              return const <Seance>[];
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // D10 : jamais « Pas de cours aujourd'hui » sur une lecture ratee.
      expect(find.text(t.eleve.accueil.aucunCours), findsNothing);
      expect(find.text(t.eleve.accueil.erreurCours), findsOneWidget);
      expect(find.text(t.eleve.accueil.coran), findsOneWidget);

      // Relire : la seconde lecture aboutit, le vrai etat revient.
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pumpAndSettle();

      expect(lectures, 2);
      expect(find.text(t.eleve.accueil.erreurCours), findsNothing);
      expect(find.text(t.eleve.accueil.aucunCours), findsOneWidget);
    });
  });
}

/// L'ecran a l'instant de reference, en version constante.
///
/// `_SansAnimation` est `const`, et son enfant doit l'etre aussi : la fermeture
/// `() => _maintenant` ne l'est pas.
class _EcranFige extends StatelessWidget {
  const _EcranFige();

  @override
  Widget build(BuildContext context) =>
      AccueilElevePage(horloge: () => _maintenant);
}
