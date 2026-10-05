import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction, SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/libelle_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_metriques.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/audio_label.dart';
import 'package:rewayah_academy/core/widgets/bento_tile.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/raccourci_tactile.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';
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

    // DASH-ELV-ERR-b, m1 et i1 : une vraie panne leve une `Exception`
    // (`SocketException`, `PostgrestException`), que Riverpod relancait dix
    // fois en silence (pres de 40 s de squelette). L'erreur doit se dire tout
    // de suite, une seule lecture, et rester affichee pendant la relecture.
    testWidgets(
      'une panne reseau (Exception) se dit sans attente, et la relecture '
      'garde le message et le Coran',
      (WidgetTester tester) async {
        int lectures = 0;
        final Completer<List<Seance>> seconde = Completer<List<Seance>>();
        await tester.pumpWidget(
          hote(
            _ecran(),
            surcharges: <Override>[
              ..._surcharges(planning: FauxServicePlanning()),
              seancesProvider.overrideWith((_) {
                lectures++;
                if (lectures == 1) {
                  return Future<List<Seance>>.error(Exception('reseau'));
                }
                return seconde.future;
              }),
            ],
          ),
        );
        // Quelques images, jamais `pumpAndSettle` : il avancerait l'horloge
        // jusqu'au bout des retentatives et masquerait l'attente.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(lectures, 1);
        expect(find.byType(Skeleton), findsNothing);
        expect(find.text(t.eleve.accueil.erreurCours), findsOneWidget);
        expect(find.text(t.eleve.accueil.coran), findsOneWidget);
        expect(find.text(t.eleve.accueil.aucunCours), findsNothing);
        expect(
          tester
              .widget<EtatSysteme>(
                find.byKey(const ValueKey<String>('accueil-eleve-erreur')),
              )
              .nature,
          NatureEtat.echecServeur,
        );

        // Aucune retentative cachee derriere le bouton.
        await tester.pump(const Duration(seconds: 60));
        expect(lectures, 1);

        await tester.tap(
          find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Pendant la relecture : ni squelette, ni « aucun cours » ; le
        // message, le Coran et le bouton qui travaille restent.
        expect(lectures, 2);
        expect(find.byType(Skeleton), findsNothing);
        expect(find.text(t.eleve.accueil.erreurCours), findsOneWidget);
        expect(find.text(t.eleve.accueil.coran), findsOneWidget);
        expect(
          tester
              .widget<EtatSysteme>(
                find.byKey(const ValueKey<String>('accueil-eleve-erreur')),
              )
              .actionEnCours,
          isTrue,
        );

        seconde.complete(const <Seance>[]);
        await tester.pumpAndSettle();
        expect(find.text(t.eleve.accueil.erreurCours), findsNothing);
        expect(find.text(t.eleve.accueil.aucunCours), findsOneWidget);
      },
    );

    // DASH-ELV-ERR-b, m2 : hors ligne, la cause probable est l'absence de
    // reseau, et le bloc la porte par sa nature (K-59).
    testWidgets('hors ligne, l echec porte la nature hors ligne', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          _ecran(),
          surcharges: <Override>[
            ..._surcharges(planning: FauxServicePlanning(), horsLigne: true),
            seancesProvider.overrideWith(
              (_) => Future<List<Seance>>.error(Exception('reseau')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final EtatSysteme bloc = tester.widget<EtatSysteme>(
        find.byKey(const ValueKey<String>('accueil-eleve-erreur')),
      );
      expect(bloc.nature, NatureEtat.horsLigne);
      expect(find.text(t.eleve.accueil.erreurCours), findsOneWidget);
      // Au tutoiement, comme tout l'accueil eleve : jamais le titre commun
      // « Vous etes hors ligne ».
      expect(
        find.text(t.eleve.accueil.erreurCoursHorsLigneTitre),
        findsOneWidget,
      );
      expect(
        find.text(EtatSysteme.textesPar(NatureEtat.horsLigne).titre),
        findsNothing,
      );
      expect(find.text(t.eleve.accueil.coran), findsOneWidget);
    });

    // DASH-ELV-ERR-b, m3 : une erreur apres une valeur deja lue garde la
    // valeur. Le choix fige ici : l'eleve voit encore son etat precedent,
    // jamais un message qui le remplacerait.
    testWidgets('un echec apres une premiere lecture garde l etat deja lu', (
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
                return const <Seance>[];
              }
              throw Exception('reseau');
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.eleve.accueil.aucunCours), findsOneWidget);

      ProviderScope.containerOf(tester.element(find.byType(AccueilElevePage)))
          .invalidate(seancesProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(lectures, 2);
      expect(find.text(t.eleve.accueil.erreurCours), findsNothing);
      expect(find.text(t.eleve.accueil.aucunCours), findsOneWidget);
      expect(find.text(t.eleve.accueil.coran), findsOneWidget);
    });
  });
  // CORAN-CARTE-1 (demande du directeur du 04/10/2026) : la carte du Coran
  // separe ses elements. Le livre et le haut-parleur aux deux bouts d'un
  // en-tete sans texte ; titre, phrase et chevron dans une zone qui ouvre le
  // Coran. Deux cibles soeurs, jamais l'une dans l'autre.
  // CORAN-CARTE-2 : deux colonnes nettes (livre, titre et phrase au bord de
  // debut ; haut-parleur et chevron au bord de fin), air egal en haut et en
  // bas, et chaque arret du clavier porte un nom.
  // CORAN-CARTE-3 : le livre ouvre aussi le Coran (raccourci tactile du
  // lien), le haut-parleur se nomme « Ecouter : Le Coran », le contenu garde
  // une colonne bornee sur grand ecran, calee au bord de debut de la carte,
  // l'air est egal dans les deux modes.
  //
  // Ce groupe charge les vraies polices : il reste le DERNIER du fichier, pour
  // ne pas changer les mesures des groupes qui le precedent.
  group('ELV-02 : la carte du Coran separe chaque element', () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monter(
      WidgetTester tester, {
      double largeur = 390,
      double echelle = 1,
      TextDirection sens = TextDirection.ltr,
      InterfaceMode mode = InterfaceMode.standard,
      List<Override> surchargesEnPlus = const <Override>[],
    }) async {
      tester.view.physicalSize = Size(largeur, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.eleve,
          mode: mode,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.eleve,
              builder: (BuildContext contexte, GoRouterState _) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: Directionality(textDirection: sens, child: _ecran()),
              ),
            ),
            GoRoute(
              path: Routes.eleveCoran,
              builder: (BuildContext _, GoRouterState _) =>
                  const Text('ELV-04'),
            ),
          ],
          surcharges: <Override>[
            ..._surcharges(planning: FauxServicePlanning()),
            ...surchargesEnPlus,
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder carte() => find.ancestor(
      of: find.text(t.eleve.accueil.coranDetail),
      matching: find.byType(BentoTile),
    );
    Finder dans(Finder f) => find.descendant(of: carte(), matching: f);
    Finder livre() => dans(find.byIcon(AppIcons.coran.repos));
    Finder audio() => dans(
      find.descendant(
        of: find.byType(AudioLabel),
        matching: find.byType(Pressable),
      ),
    );
    Finder titre() => dans(find.text(t.eleve.accueil.coran));
    Finder phrase() => dans(find.text(t.eleve.accueil.coranDetail));
    Finder hautParleur() => dans(find.byIcon(AppIcons.libelleAudio.repos));
    Finder chevron() => dans(find.byIcon(AppIcons.chevron.repos));

    /// Le rectangle du contenu de la tuile : la tuile moins sa marge.
    Rect contenu(WidgetTester tester) {
      final Rect tuile = tester.getRect(carte());
      final double marge = AppMetriques.of(tester.element(carte())).marge;
      return tuile.deflate(marge);
    }

    /// Les cinq elements : aucun ne chevauche un autre, et chaque paire
    /// garde au moins un jeton d'ecart (8) sur l'un des deux axes.
    void verifierSepares(WidgetTester tester) {
      final Map<String, Rect> r = <String, Rect>{
        'livre': tester.getRect(livre()),
        'audio': tester.getRect(audio().first),
        'titre': tester.getRect(titre()),
        'phrase': tester.getRect(phrase()),
        'chevron': tester.getRect(chevron()),
      };
      final List<String> noms = r.keys.toList();
      for (int i = 0; i < noms.length; i++) {
        for (int j = i + 1; j < noms.length; j++) {
          final Rect a = r[noms[i]]!;
          final Rect b = r[noms[j]]!;
          final double ecartX = a.left >= b.right
              ? a.left - b.right
              : b.left - a.right;
          final double ecartY = a.top >= b.bottom
              ? a.top - b.bottom
              : b.top - a.bottom;
          expect(
            ecartX >= AppSpacing.sm || ecartY >= AppSpacing.sm,
            isTrue,
            reason: '${noms[i]} $a et ${noms[j]} $b sont colles',
          );
        }
      }
    }

    testWidgets('livre et haut-parleur sur un en-tete, aux deux bouts', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      verifierSepares(tester);
      final Rect tuile = tester.getRect(carte());
      final Rect l = tester.getRect(livre());
      final Rect a = tester.getRect(audio().first);
      // Le livre au debut, le haut-parleur a la fin : toute la largeur de la
      // carte les separe, ils ne se lisent pas comme une paire.
      expect(a.left - l.right, greaterThan(tuile.width / 2));
      // L'en-tete est au-dessus du titre et de la phrase.
      expect(tester.getRect(titre()).top, greaterThanOrEqualTo(a.bottom));
      expect(
        tester.getRect(phrase()).top,
        greaterThanOrEqualTo(tester.getRect(titre()).bottom + AppSpacing.sm),
      );
      // Le titre et la phrase partent du meme bord.
      expect(tester.getRect(titre()).left, tester.getRect(phrase()).left);
    });

    /// Deux colonnes : livre, titre et phrase partent du bord de debut du
    /// contenu ; le glyphe du haut-parleur et le chevron finissent au bord de
    /// fin. En RTL, les deux bords s'echangent.
    void verifierColonnes(WidgetTester tester, TextDirection sens) {
      final Rect c = contenu(tester);
      final bool ltr = sens == TextDirection.ltr;
      double debut(Rect r) => ltr ? r.left : r.right;
      double fin(Rect r) => ltr ? r.right : r.left;
      for (final (String, Finder) e in <(String, Finder)>[
        ('livre', livre()),
        ('titre', titre()),
        ('phrase', phrase()),
      ]) {
        expect(
          debut(tester.getRect(e.$2)),
          moreOrLessEquals(debut(c), epsilon: 1),
          reason: '${e.$1} hors du bord de debut',
        );
      }
      expect(
        fin(tester.getRect(hautParleur())),
        moreOrLessEquals(fin(c), epsilon: 1),
        reason: 'haut-parleur hors du bord de fin',
      );
      expect(
        fin(tester.getRect(chevron())),
        moreOrLessEquals(fin(tester.getRect(hautParleur())), epsilon: 1),
        reason: 'chevron et haut-parleur ne finissent pas au meme bord',
      );
      // Le chevron est sous le haut-parleur, pas sur la meme ligne.
      expect(
        tester.getRect(chevron()).top,
        greaterThanOrEqualTo(tester.getRect(hautParleur()).bottom),
      );
    }

    for (final (InterfaceMode, TextDirection) cas
        in <(InterfaceMode, TextDirection)>[
          (InterfaceMode.standard, TextDirection.ltr),
          (InterfaceMode.standard, TextDirection.rtl),
          (InterfaceMode.enfant, TextDirection.ltr),
          (InterfaceMode.enfant, TextDirection.rtl),
        ]) {
      testWidgets(
        '${cas.$1.name}, ${cas.$2.name} : deux colonnes alignees au bord',
        (WidgetTester tester) async {
          await monter(tester, mode: cas.$1, sens: cas.$2);
          verifierColonnes(tester, cas.$2);
        },
      );
    }

    for (final (InterfaceMode, double, double) cas
        in <(InterfaceMode, double, double)>[
          (InterfaceMode.standard, 390, 1),
          (InterfaceMode.enfant, 390, 1),
          (InterfaceMode.standard, 320, 2),
          (InterfaceMode.enfant, 320, 2),
        ]) {
      testWidgets(
        '${cas.$1.name}, ${cas.$2.toInt()} px, texte x${cas.$3.toInt()} : '
        'autant d air au-dessus des icones que sous la phrase',
        (WidgetTester tester) async {
          await monter(tester, mode: cas.$1, largeur: cas.$2, echelle: cas.$3);
          final Rect tuile = tester.getRect(carte());
          final double haut = tester.getRect(livre()).top - tuile.top;
          final double bas = tuile.bottom - tester.getRect(phrase()).bottom;
          expect(bas, moreOrLessEquals(haut, epsilon: 2));
        },
      );
    }

    testWidgets('aucune cible n est posee dans une autre', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      // Le livre (raccourci du lien), le haut-parleur, le lien.
      final Finder cibles = dans(find.byType(Pressable));
      expect(cibles, findsNWidgets(3));
      for (final Element e in cibles.evaluate()) {
        expect(
          find.ancestor(
            of: find.byElementPredicate((Element x) => x == e),
            matching: find.byType(Pressable),
          ),
          findsNothing,
          reason: 'Un bouton dans un bouton',
        );
      }
      // La tuile elle-meme ne se presse plus.
      expect(
        find.ancestor(of: carte(), matching: find.byType(Pressable)),
        findsNothing,
      );
    });

    testWidgets('toucher le titre ouvre le Coran', (WidgetTester tester) async {
      await monter(tester);
      await tester.tap(titre());
      await tester.pumpAndSettle();
      expect(find.text('ELV-04'), findsOneWidget);
    });

    for (final InterfaceMode mode in <InterfaceMode>[
      InterfaceMode.standard,
      InterfaceMode.enfant,
    ]) {
      testWidgets('${mode.name} : toucher le livre ouvre le Coran', (
        WidgetTester tester,
      ) async {
        await monter(tester, mode: mode);
        // Le livre n'est pas une zone morte : sa cible a la taille du mode.
        final Size cible = tester.getSize(
          dans(find.ancestor(of: livre(), matching: find.byType(Pressable))),
        );
        final double minimum = AppMetriques.of(tester.element(carte()))
            .cibleTactile;
        expect(cible.width, greaterThanOrEqualTo(minimum));
        expect(cible.height, greaterThanOrEqualTo(minimum));
        await tester.tap(livre());
        await tester.pumpAndSettle();
        expect(find.text('ELV-04'), findsOneWidget);
      });
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets(
        '1440, ${sens.name} : colonne bornee, calee au bord de debut',
        (WidgetTester tester) async {
          await monter(tester, largeur: 1440, sens: sens);
          final bool ltr = sens == TextDirection.ltr;
          final Rect c = contenu(tester);
          final Rect l = tester.getRect(livre());
          final Rect h = tester.getRect(hautParleur());
          final Rect ti = tester.getRect(titre());
          // Une colonne bornee : du livre au haut-parleur, du titre au
          // chevron, jamais plus que la colonne de l'etat vide.
          final Rect colonne = l.expandToInclude(h).expandToInclude(ti);
          expect(colonne.width, lessThanOrEqualTo(AppPage.largeurEtatVide));
          expect(
            ltr
                ? tester.getRect(chevron()).right
                : tester.getRect(chevron()).left,
            moreOrLessEquals(ltr ? h.right : h.left, epsilon: 1),
          );
          // Calee au bord de debut de la carte, comme les autres tuiles :
          // le livre et le titre touchent le bord de debut du contenu, tout
          // l'air restant est rendu du cote de la fin.
          for (final Rect r in <Rect>[l, ti]) {
            expect(
              ltr ? r.left : r.right,
              moreOrLessEquals(ltr ? c.left : c.right, epsilon: 1),
            );
          }
          final double airFin = ltr ? c.right - h.right : h.left - c.left;
          expect(
            airFin,
            moreOrLessEquals(c.width - AppPage.largeurEtatVide, epsilon: 1),
          );
          verifierSepares(tester);
        },
      );
    }

    testWidgets('toucher le haut-parleur ne quitte pas l accueil', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      await tester.tap(dans(find.byIcon(AppIcons.libelleAudio.repos)));
      await tester.pumpAndSettle();
      expect(find.text('ELV-04'), findsNothing);
      expect(phrase(), findsOneWidget);
    });

    testWidgets('cibles tactiles : 48 au moins, toute la largeur pour ouvrir', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      final Size a = tester.getSize(audio().first);
      expect(a.width, greaterThanOrEqualTo(48));
      expect(a.height, greaterThanOrEqualTo(48));
      final Finder ouvrir = dans(
        find.ancestor(of: titre(), matching: find.byType(Pressable)),
      );
      expect(tester.getSize(ouvrir).height, greaterThanOrEqualTo(48));
    });

    testWidgets('lecteur d ecran : un lien qui ouvre, un bouton qui parle', (
      WidgetTester tester,
    ) async {
      // CORAN-CARTE-3 : le haut-parleur dit son action (« Ecouter : Le
      // Coran ») ; un seul arret nomme « Le Coran », le lien. Le livre,
      // raccourci tactile, n'est pas annonce.
      final SemanticsHandle poignee = tester.ensureSemantics();
      await monter(tester);
      final String coran = t.eleve.accueil.coran;
      // Le lien : « Le Coran », puis la phrase ; le chevron n'est pas lu.
      final Finder lien = find.bySemanticsLabel(
        '$coran\n${t.eleve.accueil.coranDetail}',
      );
      expect(lien, findsOneWidget);
      final SemanticsNode noeudLien = tester.getSemantics(lien);
      expect(noeudLien.flagsCollection.isLink, isTrue);
      expect(noeudLien.flagsCollection.isButton, isFalse);
      // Le haut-parleur : un bouton nomme par son action, distinct du lien.
      final SemanticsNode noeudAudio = tester.getSemantics(audio().first);
      expect(noeudAudio.label, t.eleve.accueil.coranEcouter);
      expect(noeudAudio.flagsCollection.isButton, isTrue);
      expect(noeudAudio.flagsCollection.isLink, isFalse);
      // Un seul noeud dont le nom commence par « Le Coran » : le lien.
      final Set<int> noeuds = <int>{
        for (final Element e
            in find
                .bySemanticsLabel(RegExp('^${RegExp.escape(coran)}'))
                .evaluate())
          tester
              .getSemantics(find.byElementPredicate((Element x) => x == e))
              .id,
      };
      expect(noeuds, hasLength(1));
      final Set<int> liens = <int>{
        for (final Element e
            in find
                .bySemanticsLabel(RegExp('^${RegExp.escape(coran)}'))
                .evaluate())
          if (tester
              .getSemantics(find.byElementPredicate((Element x) => x == e))
              .flagsCollection
              .isLink)
            tester
                .getSemantics(find.byElementPredicate((Element x) => x == e))
                .id,
      };
      expect(liens, hasLength(1));
      poignee.dispose();
    });

    testWidgets('clavier : chaque arret de la carte a un nom et une action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await monter(tester);
      // Le livre est un raccourci tactile, hors du clavier : restent le
      // haut-parleur et le lien.
      final Set<Element> raccourcis = dans(
        find.descendant(
          of: find.byType(RaccourciTactile),
          matching: find.byType(Pressable),
        ),
      ).evaluate().toSet();
      final Set<Element> cibles = dans(find.byType(Pressable))
          .evaluate()
          .toSet()
          .difference(raccourcis);
      final Set<Element> atteintes = <Element>{};
      for (int i = 0; i < 30 && atteintes.length < cibles.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext? focus = FocusManager.instance.primaryFocus?.context;
        if (focus == null) continue;
        Element? cible;
        (focus as Element).visitAncestorElements((Element a) {
          if (cibles.contains(a)) {
            cible = a;
            return false;
          }
          return true;
        });
        if (cible == null) continue;
        atteintes.add(cible!);
        final SemanticsNode noeud = tester.getSemantics(
          find.byElementPredicate((Element e) => e == focus),
        );
        expect(noeud.label, isNotEmpty, reason: 'arret de focus sans nom');
        expect(
          noeud.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'arret de focus sans action',
        );
      }
      expect(atteintes, hasLength(2), reason: 'haut-parleur puis lien');
      poignee.dispose();
    });

    testWidgets('mode enfant : haut-parleur de 72, rien de masque', (
      WidgetTester tester,
    ) async {
      await monter(tester, mode: InterfaceMode.enfant);
      final Size a = tester.getSize(audio().first);
      expect(a.width, greaterThanOrEqualTo(72));
      expect(a.height, greaterThanOrEqualTo(72));
      expect(phrase(), findsOneWidget);
      verifierSepares(tester);
    });

    testWidgets('RTL : le livre passe a droite du haut-parleur', (
      WidgetTester tester,
    ) async {
      await monter(tester, sens: TextDirection.rtl);
      expect(
        tester.getRect(livre()).left,
        greaterThan(tester.getRect(audio().first).right),
      );
      // Le chevron passe a gauche, au bout de la ligne qui ouvre le Coran.
      expect(
        tester.getRect(chevron()).right,
        lessThan(tester.getRect(titre()).left),
      );
      verifierSepares(tester);
    });

    // L'Interface guidee (mode enfant) grossit le livre, le haut-parleur et
    // les cibles : elle passe le meme controle que le mode standard.
    for (final (InterfaceMode, double, double, TextDirection) cas
        in <(InterfaceMode, double, double, TextDirection)>[
          (InterfaceMode.standard, 320, 2, TextDirection.ltr),
          (InterfaceMode.standard, 320, 2, TextDirection.rtl),
          (InterfaceMode.standard, 1440, 1, TextDirection.ltr),
          (InterfaceMode.standard, 1440, 1, TextDirection.rtl),
          (InterfaceMode.enfant, 320, 2, TextDirection.ltr),
          (InterfaceMode.enfant, 320, 2, TextDirection.rtl),
          (InterfaceMode.enfant, 1440, 1, TextDirection.ltr),
          (InterfaceMode.enfant, 1440, 1, TextDirection.rtl),
        ]) {
      testWidgets(
        '${cas.$1.name}, ${cas.$2.toInt()} px, texte x${cas.$3.toInt()}, '
        '${cas.$4.name} : aucun debordement, aucun mot coupe sur la page',
        (WidgetTester tester) async {
          await monter(
            tester,
            mode: cas.$1,
            largeur: cas.$2,
            echelle: cas.$3,
            sens: cas.$4,
          );
          expect(tester.takeException(), isNull);
          // TOUTE la page, pas seulement la carte : l'etat vide « Pas de
          // cours aujourd'hui » coupait « aujourd'hu / i » (ELV-VIDE-COUPE-1).
          expect(find.text(t.eleve.accueil.aucunCours), findsOneWidget);
          verifierEcranSansMotCoupe(tester);
          verifierAucunMotCoupe(tester, carte());
          verifierSepares(tester);
        },
      );
    }

    // DASH-ELV-ERR-b, m2 : le libelle d'echec s'allonge de sa cause probable.
    // A 320 px et texte x2, dans les deux sens, aucun mot ne se coupe.
    for (final TextDirection sens in TextDirection.values) {
      testWidgets(
        'echec de lecture, 320 px, texte x2, ${sens.name} : aucun mot coupe',
        (WidgetTester tester) async {
          await monter(
            tester,
            largeur: 320,
            echelle: 2,
            sens: sens,
            surchargesEnPlus: <Override>[
              seancesProvider.overrideWith(
                (_) => Future<List<Seance>>.error(Exception('reseau')),
              ),
            ],
          );
          expect(tester.takeException(), isNull);
          expect(find.text(t.eleve.accueil.erreurCours), findsOneWidget);
          verifierEcranSansMotCoupe(tester);
        },
      );
    }

    testWidgets('le squelette a la hauteur de la carte', (
      WidgetTester tester,
    ) async {
      await monter(tester);
      // Mode standard, echelle 1, vraies polices : la hauteur que le squelette
      // du second bloc reserve (`Skeleton.tuileBento(hauteur: 156)`). Si ce
      // test change, changer le squelette avec lui.
      expect(tester.getSize(carte()).height, 156);
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
