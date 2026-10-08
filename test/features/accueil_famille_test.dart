// Accueil du tuteur (lot C, sous-paquet 1) : parcours touches depuis la
// barre de navigation, sur le VRAI routeur, et etats de l'ecran.
//
// Donnees : fixtures isolees de `test/fixtures/tuteur/` (deux foyers fictifs,
// seances et classes fictives, horloge serveur figee). Aucun service reel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/classes_foyer_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_parcours/port_travail_a_venir.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/accueil_famille/bandeau_blocage.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';
import 'package:rewayah_academy/features/accueil_famille/carte_classe_seance.dart';
import 'package:rewayah_academy/features/accueil_famille/ligne_derniere_seance.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../fixtures/tuteur/faux_classes_foyer.dart';
import '../fixtures/tuteur/faux_seances_famille.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';

/// Le premier profil retenu : « Élève A1 » (tri par prenom, contrat K1).
const String _a1 = 'foyer-a-eleve-1';
const String _a2 = 'foyer-a-eleve-2';

/// Une seance a venir : salle ouverte (fenetre fictive de 20 min), dans
/// 10 min et 30 s (la demi-minute absorbe les millisecondes du test).
SeanceFamille _prochaine({
  StatutSeance? statut = StatutSeance.planifiee,
  Duration avant = const Duration(minutes: 10, seconds: 30),
  bool avecHorloge = true,
}) => seanceFictive(
  seanceId: 's1',
  eleveId: _a1,
  debutUtc: instantServeurFige.add(avant),
  statut: statut,
  avecHorloge: avecHorloge,
  heureFoyer: heureRendue('Europe/Paris', 'Paris', '18:10'),
);

/// La derniere seance, tenue il y a deux jours.
SeanceFamille _passee() => seanceFictive(
  seanceId: 's0',
  eleveId: _a1,
  debutUtc: instantServeurFige.subtract(const Duration(days: 2)),
  statut: StatutSeance.terminee,
  heureFoyer: heureRendue(
    'Europe/Paris',
    'Paris',
    '18:00',
    date: 'Samedi 19 septembre',
  ),
);

/// La classe fictive A avec son parcours lisible (ligne « cours · niveau »
/// des maquettes V1 et V2), en donnees fictives.
const ClasseFoyer _classeAvecParcours = ClasseFoyer(
  eleveId: _a1,
  classe: GroupSummaryVM(
    groupeId: 'classe-a',
    libelle: 'Classe fictive A',
    couleurJeton: JetonCouleurGroupe(index: 0, codeStable: 'g0'),
    enseignant: EnseignantVM(
      enseignantId: 'enseignant-x',
      titre: TitreEnseignant.sayyid,
      nomAffichage: 'Enseignant X',
    ),
    nombreMembres: 3,
    seuilMax: 6,
    typePublic: TypePublicGroupeVM.enfant,
    actif: true,
    nomCours: 'Cours fictif',
    niveauHumain: 'Niveau fictif',
  ),
);

/// Un appareil actif de l'eleve A1.
AppareilAppaire _appareilA1() => AppareilAppaire(
  id: 'app-1',
  profilId: _a1,
  prenom: 'Élève A1',
  plateforme: 'Android',
  appaireA: DateTime.utc(2026, 9, 1),
);

/// Le travail a venir, en memoire.
class _FauxTravail implements PortTravailAVenir {
  const _FauxTravail(this.actions);

  final List<SlotAction> actions;

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async => actions;
}

/// Monte l'application sur son vrai routeur, avec un tuteur actif et le
/// foyer fictif A, puis va a [depart].
Future<GoRouter> _monter(
  WidgetTester tester, {
  String depart = Routes.tuteurFoyer,
  List<EleveDuFoyer> foyer = FoyersFictifs.foyerA,
  List<SeanceFamille>? seances,
  List<ClasseFoyer>? classes,
  PortClassesFoyer? portClasses,
  List<AppareilAppaire>? appareils,
  PortTravailAVenir? travail,
  DateTime? maintenant,
  bool horlogeAbsente = false,
  Size taille = const Size(390, 844),
  List<Override> autres = const <Override>[],
  double echelle = 1,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = foyer
    ..appareilsRendus = appareils ?? <AppareilAppaire>[_appareilA1()];
  final FauxSeancesFamille faux = FauxSeancesFamille(
    seances: seances ?? <SeanceFamille>[_prochaine(), _passee()],
    maintenant: maintenant,
  );
  if (horlogeAbsente) {
    faux.maintenant = null;
  }
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        portSeancesFamilleProvider.overrideWithValue(faux),
        portClassesFoyerProvider.overrideWithValue(
          portClasses ??
              FauxClassesFoyer(
                classes:
                    classes ??
                    <ClasseFoyer>[
                      ClasseFoyer(eleveId: _a1, classe: classeFictive()),
                    ],
              ),
        ),
        portTravailAVenirProvider.overrideWithValue(travail),
        ...autres,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              // Sans echelle ni sens demandes, l'application reste telle quelle.
              builder: echelle == 1 && direction == null
                  ? null
                  : (BuildContext c, Widget? app) => MediaQuery(
                      data: MediaQuery.of(c)
                          .copyWith(textScaler: TextScaler.linear(echelle)),
                      child: Directionality(
                        textDirection: direction ?? TextDirection.ltr,
                        child: app!,
                      ),
                    ),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Touche l'onglet Accueil de la barre basse.
Future<void> _ouvrirAccueilParLaBarre(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.text(t.nav.tuteur.accueil),
    ),
  );
  await stabiliser(tester);
  expect(find.byType(AccueilFamillePage), findsOneWidget);
}

/// Touche un texte apres l'avoir amene a l'ecran.
Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

String _lieu(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('Accueil : parcours touches depuis la barre de navigation', () {
    testWidgets('la carte classe dit la classe, l enseignant, la seance, '
        'et « Voir la classe » ouvre la classe de CET eleve', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        classes: const <ClasseFoyer>[_classeAvecParcours],
      );
      await _ouvrirAccueilParLaBarre(tester);

      expect(find.text(t.tuteur.accueil.titre), findsWidgets);
      expect(find.text('Classe fictive A'), findsOneWidget);
      expect(
        find.text('${t.tc.groupe.enseignant.sayyid} Enseignant X'),
        findsOneWidget,
      );
      // Le parcours lisible sous l'enseignant (V1, V2), quand il est rendu.
      expect(
        find.text(
          LibellesGroupe.coursEtNiveau(
            cours: 'Cours fictif',
            niveau: 'Niveau fictif',
          ),
        ),
        findsOneWidget,
      );
      // Meme source pour le selecteur et la carte : « Salle ouverte » dans les
      // deux, jamais « En seance » au-dessus d'un compte a rebours.
      expect(find.text(LibellesGroupe.salleOuverteCourt), findsNWidgets(2));
      expect(find.text(LibellesGroupe.dansMinutes(10)), findsOneWidget);
      expect(
        find.text(LibellesGroupe.heureEtVille(heure: '18:10', ville: 'Paris')),
        findsOneWidget,
      );

      await _toucher(tester, find.text(t.tuteur.accueil.voirLaClasse));
      expect(_lieu(routeur), Routes.classePour('classe-a', eleveId: _a1));
      expect(find.byType(ClasseTuteurPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('changer de profil met a jour la carte ; sans classe, '
        '« Choisir une classe » ouvre le catalogue de cet eleve', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirAccueilParLaBarre(tester);

      await _toucher(
        tester,
        find.descendant(
          of: find.byType(SelecteurProfils),
          matching: find.text('Élève A2'),
        ),
      );
      expect(
        find.text(t.tuteur.accueil.sansClasseTitre(prenom: 'Élève A2')),
        findsOneWidget,
      );
      // Aucune valeur de l'eleve precedent ne subsiste.
      expect(find.text('Classe fictive A'), findsNothing);

      await _toucher(tester, find.text(t.classe.catalogue));
      expect(_lieu(routeur), '${Routes.tuteurClassesCatalogue}?eleve=$_a2');
    });

    testWidgets('« Ajouter » du selecteur ouvre le meme flux que le Foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirAccueilParLaBarre(tester);

      await _toucher(
        tester,
        find.descendant(
          of: find.byType(SelecteurProfils),
          matching: find.text(t.commun.selecteurProfils.ajouter),
        ),
      );
      expect(_lieu(routeur), Routes.tuteurAjouterEnfant);
    });

    testWidgets('un seul blocage, confirme par les donnees : aucun appareil ; '
        '« Connecter un appareil » ouvre l emetteur de CET eleve', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        appareils: <AppareilAppaire>[],
      );
      await _ouvrirAccueilParLaBarre(tester);

      expect(find.byType(BandeauBlocage), findsOneWidget);
      expect(
        find.text(t.tuteur.accueil.blocageAppareilTitre(prenom: 'Élève A1')),
        findsOneWidget,
      );
      await _toucher(tester, find.text(t.tuteur.accueil.connecterAppareil));
      expect(_lieu(routeur), Routes.appairerPour(_a1));
    });

    testWidgets('bandeau telephone : « Connecter un appareil » a droite du '
        'texte a 390 (V1 #17), sous le texte a 200 pour cent', (
      WidgetTester tester,
    ) async {
      final Finder titre = find.text(
        t.tuteur.accueil.blocageAppareilTitre(prenom: 'Élève A1'),
      );
      final Finder action = find.text(t.tuteur.accueil.connecterAppareil);

      await _monter(tester, appareils: <AppareilAppaire>[]);
      await _ouvrirAccueilParLaBarre(tester);
      await tester.ensureVisible(action);
      await stabiliser(tester);
      expect(
        tester.getTopLeft(action).dx,
        greaterThan(tester.getTopRight(titre).dx),
      );
      expect(
        tester.getTopLeft(action).dy,
        lessThan(tester.getBottomLeft(find.byType(BandeauBlocage)).dy),
      );
      expect(tester.takeException(), isNull);

      // Texte x2 : le bandeau seul, texte agrandi par son MediaQuery (la
      // barre basse a texte x2 est couverte par test/accessibilite).
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BandeauBlocage(
                  prenom: 'Élève A1',
                  compact: true,
                  onConnecter: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(action).dy,
        greaterThan(tester.getBottomLeft(titre).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('un appareil actif : aucun blocage', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _ouvrirAccueilParLaBarre(tester);
      expect(find.byType(BandeauBlocage), findsNothing);
    });

    testWidgets('« Voir l historique » et « Details de la seance » menent a '
        'l Historique de cet eleve et au detail de la derniere seance', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirAccueilParLaBarre(tester);

      expect(find.text(t.tuteur.accueil.derniereSeance), findsOneWidget);
      await _toucher(tester, find.text(t.tuteur.accueil.voirHistorique));
      expect(_lieu(routeur), '${Routes.tuteurSuivi}?eleve=$_a1');

      await _ouvrirAccueilParLaBarre(tester);
      await _toucher(tester, find.text(t.tuteur.accueil.detailsSeance));
      expect(_lieu(routeur), Routes.seancePour('s0'));
    });

    testWidgets('travail branche : trois actions au plus, « Voir tout » ouvre '
        'le travail de la classe', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        travail: const _FauxTravail(<SlotAction>[
          SlotAction(id: 'a', libelle: 'Action fictive 1'),
          SlotAction(id: 'b', libelle: 'Action fictive 2'),
          SlotAction(id: 'c', libelle: 'Action fictive 3'),
          SlotAction(id: 'd', libelle: 'Action fictive 4'),
        ]),
      );
      await _ouvrirAccueilParLaBarre(tester);

      expect(find.text('Action fictive 3'), findsOneWidget);
      expect(find.text('Action fictive 4'), findsNothing);
      await _toucher(tester, find.text(t.tuteur.accueil.voirTout));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage('classe-a', 'travail')}?eleve=$_a1',
      );
    });
  });

  group('Accueil : etats', () {
    testWidgets('travail non branche : une phrase honnete, jamais « Rien a '
        'preparer »', (WidgetTester tester) async {
      await _monter(tester, depart: Routes.tuteurAccueil);
      expect(find.text(t.tuteur.accueil.travailIndisponible), findsOneWidget);
      expect(find.text(t.tuteur.accueil.rienAPreparer), findsNothing);
    });

    testWidgets('sans horloge serveur : aucune salle ouverte ni compte a '
        'rebours, l heure est dite « de cet appareil »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.tuteurAccueil,
        horlogeAbsente: true,
        seances: <SeanceFamille>[_prochaine(avecHorloge: false)],
      );
      expect(find.text(LibellesGroupe.salleOuverteCourt), findsNothing);
      expect(find.text(t.tuteur.accueil.horaireIncertain), findsOneWidget);
      expect(find.text(t.tuteur.accueil.heureAppareil), findsOneWidget);
      expect(find.text(t.tuteur.accueil.etatCourt.prevue), findsOneWidget);
    });

    testWidgets(
      'seance prolongee : « Seance toujours en direct », sans nombre',
      (WidgetTester tester) async {
        await _monter(
          tester,
          depart: Routes.tuteurAccueil,
          seances: <SeanceFamille>[
            _prochaine(
              statut: StatutSeance.enCours,
              avant: const Duration(minutes: -50),
            ),
          ],
        );
        expect(find.text(LibellesGroupe.prolongee), findsOneWidget);
        // Le selecteur et la pastille de la carte disent la meme chose.
        expect(
          find.text(t.tuteur.accueil.etatCourt.enDirect),
          findsNWidgets(2),
        );
        expect(find.textContaining('-'), findsNothing);
      },
    );

    testWidgets('seance annulee : pastille « Annulee », jamais de compte a '
        'rebours', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.tuteurAccueil,
        seances: <SeanceFamille>[_prochaine(statut: StatutSeance.annulee)],
      );
      final StatusPill pastille = tester.widget<StatusPill>(
        find.widgetWithText(StatusPill, t.tuteur.accueil.pastilleAnnulee),
      );
      expect(pastille.ton, TonEtat.alerte);
      expect(find.text(LibellesGroupe.dansMinutes(10)), findsNothing);
    });

    testWidgets('classes indisponibles (production) : la seance reste, sans '
        'CTA qui ne pourrait mener nulle part', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.tuteurAccueil,
        portClasses: const ClassesFoyerIndisponible(),
      );
      expect(find.text(t.tuteur.accueil.classeIndisponible), findsOneWidget);
      expect(find.text(t.tuteur.accueil.voirLaClasse), findsNothing);
      expect(find.text(LibellesGroupe.dansMinutes(10)), findsOneWidget);
    });

    testWidgets('foyer vide : invitation a ajouter un profil eleve', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        foyer: FoyersFictifs.foyerVide,
      );
      await _ouvrirAccueilParLaBarre(tester);
      expect(find.text(t.tuteur.accueil.foyerVideTitre), findsOneWidget);
      await _toucher(tester, find.text(t.tuteur.accueil.ajouterProfil));
      expect(_lieu(routeur), Routes.tuteurAjouterEnfant);
    });

    testWidgets('bureau 1440 : deux colonnes, carte classe a gauche et carte '
        'groupee a droite', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.tuteurAccueil,
        taille: const Size(1440, 900),
      );
      final Offset classe = tester.getTopLeft(find.text('Classe fictive A'));
      final Offset avant = tester.getTopLeft(
        find.text(t.tuteur.accueil.avantProchainCours),
      );
      expect(avant.dx, greaterThan(classe.dx + 400));
      expect((avant.dy - classe.dy).abs(), lessThan(200));
      expect(find.text(t.tuteur.accueil.prochaineSeance), findsOneWidget);
      expect(find.byType(NavShell), findsOneWidget);
    });
  });

  group('BENTO-2b/2c : la carte classe ne coupe aucun mot', () {
    // Les mesures de texte n'ont de sens qu'avec les vraies polices.
    setUpAll(chargerPolicesDuDepot);

    for (final (double, double) cas in const <(double, double)>[
      (320, 1),
      (320, 2),
      (390, 2),
      // BENTO-2c (m1 de BENTO-2b-R) : carte pleine largeur, colonne de la
      // duree trop etroite a texte double (« Duré/e », « 45 / min »).
      (600, 2),
      (620, 2),
      (768, 1),
      (768, 2),
      // BENTO-2c (m3) : la bande 864-1023 (moitie de 360 a 439 px), 1024,
      // 1200 (moitie 432) et 1280.
      (864, 1),
      (900, 1),
      (1024, 1),
      (1200, 1),
      (1280, 1),
      (1440, 1),
      (1440, 2),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
            '${sens.name}', (WidgetTester tester) async {
          await _monter(
            tester,
            depart: Routes.tuteurAccueil,
            taille: Size(cas.$1, 3000),
            echelle: cas.$2,
            direction: sens,
          );
          expect(tester.takeException(), isNull);
          // BENTO-2c (m4) : la mesure porte sur quelque chose. La grille est
          // la, et la ligne « Duree » qu'elle doit proteger aussi.
          final Finder grille = find.byType(GrilleBento);
          expect(grille, findsOneWidget);
          expect(
            find.descendant(
              of: grille,
              matching: find.text(LibellesGroupe.dureeLibelle),
            ),
            findsOneWidget,
          );
          // La carte, « Avant le prochain cours » et « Derniere seance » ;
          // le selecteur de profils (qui defile) et la coquille sont hors
          // de cette mesure.
          verifierAucunMotCoupe(tester, grille);
        });
      }
    }

    /// Vrai si la carte classe partage sa bande (moins de la moitie de la
    /// grille).
    bool coteACote(WidgetTester tester) =>
        tester.getSize(find.byType(CarteClasseSeance)).width <
        tester.getSize(find.byType(GrilleBento)).width / 2;

    // BENTO-2c (m2, m3) : la carte partage sa bande des que chaque moitie de
    // la grille offre 360 px x echelle. Avec le rail (80) et les gouttieres
    // (2 x 24), la grille fait 736 px a 864 px d'ecran : bascule entre 863
    // et 864 ; a 1024 px la carte est deja cote a cote ; a texte double, il
    // faut une grille de 1472 px, donc 1440 reste en pleine largeur.
    for (final (double, double, bool) cas in const <(double, double, bool)>[
      (768, 1, false),
      (863, 1, false),
      (864, 1, true),
      (1024, 1, true),
      (1440, 1, true),
      (1440, 2, false),
    ]) {
      testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()} : '
          '${cas.$3 ? 'cote a cote' : 'pleine largeur'}', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          depart: Routes.tuteurAccueil,
          taille: Size(cas.$1, 3000),
          echelle: cas.$2,
        );
        expect(find.byType(CarteClasseSeance), findsOneWidget);
        expect(coteACote(tester), cas.$3);
        if (!cas.$3) {
          expect(
            tester.getSize(find.byType(CarteClasseSeance)).width,
            moreOrLessEquals(tester.getSize(find.byType(GrilleBento)).width),
          );
        }
      });
    }

    // BENTO-2c (m8, m9) : la duree reste a droite du filet tant que
    // (mesure, plus de seuil fixe de 96 px)
    // « Duree » et sa valeur y tiennent entieres, sinon elle passe sous
    // l'heure (dans la moitie de debut de la carte).
    for (final (double, double, bool) cas in const <(double, double, bool)>[
      (320, 1, true),
      (320, 2, false),
      (390, 1, true),
      (390, 2, true),
      (600, 2, false),
      (1440, 1, true),
    ]) {
      testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()} : duree '
          '${cas.$3 ? 'a droite' : "sous l'heure"}', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          depart: Routes.tuteurAccueil,
          taille: Size(cas.$1, 3000),
          echelle: cas.$2,
        );
        final Finder duree = find.descendant(
          of: find.byType(BlocSeance),
          matching: find.text(LibellesGroupe.dureeLibelle),
        );
        expect(duree, findsOneWidget);
        final Rect bloc = tester.getRect(find.byType(BlocSeance));
        expect(tester.getTopLeft(duree).dx > bloc.center.dx, cas.$3);
      });
    }
  });

  group('Accueil : lectures en echec ou en cours', () {
    testWidgets('profils illisibles : etat d echec avec Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.tuteurAccueil,
        autres: <Override>[
          elevesDuFoyerProvider.overrideWith(
            (Ref _) => Future<List<EleveDuFoyer>>.error(StateError('reseau')),
          ),
        ],
      );
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etat.nature, NatureEtat.echecServeur);
      expect(find.text(t.commun.etats.actions.reessayer), findsOneWidget);
    });

    testWidgets('premiere lecture : squelette', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const AccueilFamillePage(),
          surcharges: <Override>[
            elevesDuFoyerProvider.overrideWith(
              (Ref _) => Future<List<EleveDuFoyer>>.delayed(
                const Duration(seconds: 1),
                () => const <EleveDuFoyer>[],
              ),
            ),
            portSeancesFamilleProvider.overrideWithValue(FauxSeancesFamille()),
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Accueil : fonctions pures', () {
    test('un meme calcul pour le selecteur et la carte', () {
      final AffichageSeance salle = AffichageSeance.depuis(
        _prochaine(),
        maintenantServeurUtc: instantServeurFige,
      );
      expect(salle.etat, EtatSeanceFamille.salleOuverte);
      expect(salle.etatCourt, t.tuteur.accueil.etatCourt.salleOuverte);
      expect(salle.point, PointStatut.succes);
      expect(salle.ligneEtat, LibellesGroupe.dansMinutes(10));
      expect(salle.fuseau, t.tuteur.accueil.heureDe(ville: 'Paris'));

      final AffichageSeance loin = AffichageSeance.depuis(
        _prochaine(avant: const Duration(hours: 3, minutes: 28, seconds: 30)),
        maintenantServeurUtc: instantServeurFige,
      );
      expect(loin.etat, EtatSeanceFamille.aVenir);
      expect(loin.ligneEtat, LibellesGroupe.dansHeures(heures: 3, minutes: 28));
      expect(
        loin.etatCourt,
        t.tuteur.accueil.etatCourt.dansHeures(heures: 3, minutes: '28'),
      );
      expect(loin.point, PointStatut.attention);
    });

    test(
      'aucun appareil pret : seulement sans appareil actif de CET eleve',
      () {
        expect(aucunAppareilPret(const <AppareilAppaire>[], _a1), isTrue);
        expect(
          aucunAppareilPret(<AppareilAppaire>[_appareilA1()], _a1),
          isFalse,
        );
        expect(
          aucunAppareilPret(<AppareilAppaire>[_appareilA1()], _a2),
          isTrue,
        );
        final AppareilAppaire revoque = AppareilAppaire(
          id: 'app-2',
          profilId: _a1,
          prenom: 'Élève A1',
          plateforme: 'Web',
          appaireA: DateTime.utc(2026, 9, 1),
          revoqueA: DateTime.utc(2026, 9, 2),
        );
        expect(aucunAppareilPret(<AppareilAppaire>[revoque], _a1), isTrue);
      },
    );

    test('classes du foyer : seules les appartenances ouvertes de l eleve', () {
      Map<String, dynamic> ligne(String id, String libelle) =>
          <String, dynamic>{
            'groupe_id': id,
            'libelle': libelle,
            'seuil_max': 6,
            'nb_membres': 3,
            'teacher_id': 't1',
            'teacher_prenom': 'Enseignant X',
            'teacher_titre': 'sayyida',
            'type_public': 'enfant',
          };
      final List<ClasseFoyer> classes = classesDepuisLignes(
        eleveId: _a1,
        appartenances: <Map<String, dynamic>>[
          <String, dynamic>{'groupe_id': 'g2'},
        ],
        groupes: <Map<String, dynamic>>[
          ligne('g1', 'Classe fictive 1'),
          ligne('g2', 'Classe fictive 2'),
        ],
      );
      expect(classes, hasLength(1));
      expect(classes.single.eleveId, _a1);
      expect(classes.single.classe.libelle, 'Classe fictive 2');
    });
  });

  group('Derniere seance : presence par la table unique', () {
    testWidgets('presence lue : la pastille de LignePresence', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          LigneDerniereSeance(
            derniere: AsyncValue<SeanceFamille?>.data(_passee()),
            presence: const AsyncValue<PresenceParticipant?>.data(
              PresenceParticipant(
                profilId: _a1,
                role: 'student',
                prenom: 'Élève A1',
                identifiantImmuable: 'STUD-FA-000001',
                etat: EtatPresence.finalisee,
                consolide: true,
              ),
            ),
            maintenantServeurUtc: instantServeurFige,
            onVoirHistorique: () {},
            onDetails: (String _) {},
            onReessayer: () {},
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(LignePresence.libelle(EtatPresence.finalisee)),
        findsOneWidget,
      );
    });

    testWidgets('presence illisible : jamais « Absence »', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          LigneDerniereSeance(
            derniere: AsyncValue<SeanceFamille?>.data(_passee()),
            presence: const AsyncValue<PresenceParticipant?>.data(null),
            maintenantServeurUtc: instantServeurFige,
            onVoirHistorique: () {},
            onDetails: (String _) {},
            onReessayer: () {},
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(LignePresence.libelle(EtatPresence.absente)),
        findsNothing,
      );
      expect(
        find.text(LignePresence.libelle(EtatPresence.inconnu)),
        findsOneWidget,
      );
    });
  });
}
