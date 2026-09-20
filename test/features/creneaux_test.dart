import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';

import '../support/harnais.dart';

const String _monId = 't1';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

EleveEnAttente _eleve({
  String id = 'e1',
  String prenom = 'Khadija',
  int jours = 0,
  int jour = 2,
  int heure = 17,
}) => EleveEnAttente(
  eleveId: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-KB-000003',
  creneau: Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris'),
  depuis: DateTime.now().subtract(Duration(days: jours)),
  mode: InterfaceMode.enfant,
  niveau: 'debutant',
);

Affectation _affectation({
  required String eleveId,
  int jour = 4,
  int heure = 9,
  DateTime? closeLe,
}) => Affectation(
  id: 'a-$eleveId',
  enseignantId: _monId,
  enseignantPrenom: 'Omar',
  enseignantIdentifiant: 'TEACH-OS-000001',
  eleveId: eleveId,
  elevePrenom: 'Eleve $eleveId',
  creneau: Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris'),
  depuis: DateTime.now(),
  closeLe: closeLe,
);

/// Les surcharges communes.
///
/// **Le reseau en fait partie.** Sans lui, `horsLigneProvider` retombe sur
/// `connectivity_plus`, dont le canal de plateforme n'existe pas sous
/// `flutter_test` : l'etat « hors ligne » de l'ecran serait alors decide par un
/// echec de plugin plutot que par la fixture.
List<Override> _surcharges({
  required FauxServiceMatching matching,
  required FauxServicePlanning planning,
  required FauxServiceRegles regles,
  bool horsLigne = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_sessionEnseignant),
  ),
  serviceMatchingProvider.overrideWithValue(matching),
  servicePlanningProvider.overrideWithValue(planning),
  serviceReglesProvider.overrideWithValue(regles),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
];

FauxServiceRegles _reglesAvecPlafond(int plafond) =>
    FauxServiceRegles()
      ..parProfil[_monId] = <RegleProfil>[
        RegleProfil(
          cle: CleRegle.plafondEleves,
          valeurEffective: plafond,
          valeurPlateforme: 5,
        ),
      ];

/// Mesure sur un telephone reel, jamais sur la surface par defaut.
///
/// `flutter_test` monte tout sur 800 x 600, c'est-a-dire au gabarit
/// **tablette**. Or `ENS-06` n'a d'onglets qu'au gabarit mobile : depuis le lot
/// R4, la tablette empile les deux panneaux et le desktop les met cote a cote
/// (`08-catalogue-ecrans.md` section 2). Ces tests mesurent le parcours
/// mobile -- prendre un eleve depuis l'onglet -- et cherchaient donc un onglet
/// qui n'existe plus a 800 de large. Ils le disent maintenant.
///
/// 390 x 844, et non une hauteur inventee : c'est le gabarit de reference du
/// produit. Une mesure faite sur une fenetre plus haute que les telephones
/// reels cache les depassements au lieu de les montrer.
void _telephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _monter(
  WidgetTester tester, {
  FauxServiceMatching? matching,
  FauxServicePlanning? planning,
  FauxServiceRegles? regles,
  bool horsLigne = false,
  List<Override> extra = const <Override>[],
}) async {
  _telephone(tester);
  await tester.pumpWidget(
    hote(
      const CreneauxPage(),
      surcharges: <Override>[
        ..._surcharges(
          matching: matching ?? FauxServiceMatching(),
          planning: planning ?? FauxServicePlanning(),
          regles: regles ?? _reglesAvecPlafond(5),
          horsLigne: horsLigne,
        ),
        ...extra,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _ouvrirOngletEleves(WidgetTester tester) async {
  await tester.tap(find.text(t.creneaux.ongletEleves));
  await tester.pumpAndSettle();
}

/// Tape une case de la grille par son libelle parle.
///
/// La grille n'expose aucune cle : la seule prise stable sur une case donnee
/// est le libelle semantique que `ENS-06` doit de toute facon porter (fiche
/// `ENS-06`, section Accessibilite). Le mesurer ici verifie les deux choses a
/// la fois.
Future<void> _taperCase(
  WidgetTester tester, {
  required String libelle,
}) async {
  final Finder cellule = find.bySemanticsLabel(libelle);
  expect(cellule, findsOneWidget, reason: 'case introuvable : $libelle');
  await tester.ensureVisible(cellule);
  await tester.pumpAndSettle();
  await tester.tap(cellule);
  await tester.pumpAndSettle();
}

void main() {
  group('ENS-06 : ce qui se prend est un eleve, pas un creneau', () {
    testWidgets('sous le plafond, le bouton prend l eleve sur son creneau', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()];

      await _monter(tester, matching: matching);
      await _ouvrirOngletEleves(tester);

      final Finder bouton = find.text(
        t.creneaux.prendre(jour: 'mardi', heure: '17'),
      );
      expect(bouton, findsOneWidget);

      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(matching.prises.length, 1);
      expect(matching.prises.single.eleveId, 'e1');
      expect(matching.prises.single.creneau.jour, 2);
      expect(matching.prises.single.creneau.heure, 17);
    });

    testWidgets('au plafond, le bouton n existe pas, une phrase le remplace', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..affectationsRendues = <Affectation>[
          for (int i = 0; i < 5; i++)
            _affectation(eleveId: 'x$i', heure: 9 + i),
        ];

      await _monter(
        tester,
        matching: FauxServiceMatching()..feed = <EleveEnAttente>[_eleve()],
        planning: planning,
      );
      await _ouvrirOngletEleves(tester);

      // Un bouton qui echoue apres le geste coute plus cher qu'un bouton
      // absent : la limite s'explique, elle ne se heurte pas.
      expect(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
        findsNothing,
      );
      expect(find.text(t.creneaux.plafondAtteint(nombre: '5')), findsOneWidget);
      expect(find.text(t.creneaux.plafondDemander), findsOneWidget);
      // L'eleve reste visible : l'enseignant doit pouvoir constater qui attend
      // avant de demander a en suivre plus.
      expect(find.text('Khadija'), findsOneWidget);
    });

    testWidgets('un plafond surcharge deverrouille le bouton', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..affectationsRendues = <Affectation>[
          for (int i = 0; i < 5; i++)
            _affectation(eleveId: 'x$i', heure: 9 + i),
        ];

      await _monter(
        tester,
        matching: FauxServiceMatching()..feed = <EleveEnAttente>[_eleve()],
        planning: planning,
        // La meme situation, avec la regle de CET enseignant portee a 6.
        regles: _reglesAvecPlafond(6),
      );
      await _ouvrirOngletEleves(tester);

      expect(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
        findsOneWidget,
      );
      expect(
        find.text(t.creneaux.mesEleves(nombre: '5', plafond: '6')),
        findsOneWidget,
      );
    });

    testWidgets('l attente est datee, et signalee au-dela de trois jours', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        matching: FauxServiceMatching()..feed = <EleveEnAttente>[
          _eleve(jours: 0),
          _eleve(id: 'e2', prenom: 'Ibrahim', jours: 1, jour: 3),
          _eleve(id: 'e3', prenom: 'Fatou', jours: 6, jour: 4),
        ],
      );
      await _ouvrirOngletEleves(tester);

      expect(find.text(t.creneaux.attendAujourdhui), findsOneWidget);
      expect(find.text(t.creneaux.attendUnJour), findsOneWidget);
      expect(find.text(t.creneaux.attendDepuis(jours: '6')), findsOneWidget);
    });

    test('parAnciennete rend la plus longue attente en premier', () {
      final List<EleveEnAttente> range = parAnciennete(<EleveEnAttente>[
        _eleve(jours: 0),
        _eleve(id: 'e3', prenom: 'Fatou', jours: 6),
        _eleve(id: 'e2', prenom: 'Ibrahim', jours: 1),
      ]);

      expect(range.map((EleveEnAttente e) => e.prenom).toList(), <String>[
        'Fatou',
        'Ibrahim',
        'Khadija',
      ]);
    });

    testWidgets('la famille qui attend le plus longtemps est en haut', (
      WidgetTester tester,
    ) async {
      // Le feed arrive volontairement dans le desordre. L'ordre appartient a
      // l'ecran : il vivait dans le seul `.order()` de la lecture, dont le sens
      // par defaut est DESCENDANT, ce qui enfoncait au bas de la liste la
      // famille qui attend depuis le plus longtemps, c'est-a-dire exactement
      // celle que ce tri existe pour faire remonter.
      await _monter(
        tester,
        matching: FauxServiceMatching()..feed = <EleveEnAttente>[
          _eleve(jours: 0),
          _eleve(id: 'e3', prenom: 'Fatou', jours: 6, jour: 4),
          _eleve(id: 'e2', prenom: 'Ibrahim', jours: 1, jour: 3),
        ],
      );
      await _ouvrirOngletEleves(tester);

      final double yFatou = tester.getTopLeft(find.text('Fatou')).dy;
      final double yIbrahim = tester.getTopLeft(find.text('Ibrahim')).dy;
      final double yKhadija = tester.getTopLeft(find.text('Khadija')).dy;

      expect(yFatou, lessThan(yIbrahim));
      expect(yIbrahim, lessThan(yKhadija));
    });

    testWidgets(
      'le feed rend une ligne par creneau compatible, pas par eleve',
      (WidgetTester tester) async {
        // Un seul eleve, trois heures croisees. Compter les cartes annoncerait
        // trois familles la ou une seule attend : l'invariant est que le
        // PRENOM se repete, et que ce sont les CRENEAUX qui changent.
        await _monter(
          tester,
          matching: FauxServiceMatching()..feed = <EleveEnAttente>[
            _eleve(jour: 2, heure: 17),
            _eleve(jour: 3, heure: 18),
            _eleve(jour: 4, heure: 9),
          ],
        );
        await _ouvrirOngletEleves(tester);

        expect(find.text('Khadija'), findsNWidgets(3));
        expect(
          find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
          findsOneWidget,
        );
        expect(
          find.text(t.creneaux.prendre(jour: 'mercredi', heure: '18')),
          findsOneWidget,
        );
        expect(
          find.text(t.creneaux.prendre(jour: 'jeudi', heure: '9')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'des la tablette, chaque panneau porte le nom de son onglet',
      (WidgetTester tester) async {
        // Le lot R4 a supprime les onglets au-dela de 600 et laisse leurs deux
        // libelles dans le seul `TabBar` mobile : le feed s'est retrouve sans
        // titre sur tablette comme sur desktop. Les tests ci-dessus ne
        // pouvaient pas le voir, ils mesurent le gabarit mobile.
        for (final double largeur in <double>[768, 1440]) {
          tester.view.physicalSize = Size(largeur, 2000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            hote(
              const CreneauxPage(),
              surcharges: _surcharges(
                matching: FauxServiceMatching()..feed = <EleveEnAttente>[
                  _eleve(),
                ],
                planning: FauxServicePlanning(),
                regles: _reglesAvecPlafond(5),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(t.creneaux.ongletHeures),
            findsOneWidget,
            reason: 'panneau des heures sans titre a $largeur',
          );
          expect(
            find.text(t.creneaux.ongletEleves),
            findsOneWidget,
            reason: 'panneau des eleves sans titre a $largeur',
          );
        }
      },
    );
  });

  group('ENS-06 : la base tranche la concurrence, l ecran la raconte', () {
    testWidgets(
      'pris par un autre pendant l affichage : la ligne disparait, et c est dit',
      (WidgetTester tester) async {
        final FauxServiceMatching matching = FauxServiceMatching()
          ..feed = <EleveEnAttente>[_eleve()];

        await _monter(tester, matching: matching);
        await _ouvrirOngletEleves(tester);
        expect(find.text('Khadija'), findsOneWidget);

        // Un autre enseignant gagne la course PENDANT que cet ecran affiche la
        // carte : la base refuse, et la file ne contient plus cette ligne.
        matching
          ..erreurPrise = StateError(
            'cet eleve vient d etre pris par un autre enseignant',
          )
          ..feed = const <EleveEnAttente>[];

        await tester.tap(
          find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
        );
        await tester.pumpAndSettle();

        // 1. Le conflit est NOMME, pas recopie depuis une chaine SQL.
        expect(
          find.text(t.enseignant.creneaux.refusDejaPris),
          findsOneWidget,
          reason: 'le perdant d une prise simultanee doit lire une phrase',
        );
        // 2. L'element DISPARAIT : le protocole l'exige, et sans cela un second
        //    tap redonnerait la meme erreur.
        expect(find.text('Khadija'), findsNothing);
        expect(
          find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
          findsNothing,
        );
        // 3. Aucune incoherence locale : rien n'a ete enregistre cote client, et
        //    la file vide s'affiche comme une file vide.
        expect(matching.prises, isEmpty);
        expect(find.text(t.creneaux.aucunEleve), findsOneWidget);
      },
    );

    testWidgets('tout echec d une prise relit le feed', (
      WidgetTester tester,
    ) async {
      // Invariant de non-regression : les invalidations ne vivaient que dans le
      // chemin de SUCCES. Ici la base refuse pour une autre raison et la file
      // rend desormais un AUTRE eleve : si le feed n'etait pas relu, l'ecran
      // resterait sur Khadija.
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()];

      await _monter(tester, matching: matching);
      await _ouvrirOngletEleves(tester);

      matching
        ..erreurPrise = StateError('ce creneau n est pas propose par ce foyer')
        ..feed = <EleveEnAttente>[_eleve(id: 'e9', prenom: 'Fatou', jour: 3)];

      await tester.tap(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.creneaux.refusCreneauRetire),
        findsOneWidget,
      );
      expect(find.text('Khadija'), findsNothing);
      expect(find.text('Fatou'), findsOneWidget);
    });

    testWidgets('un refus imprevu se recopie plutot que de s avaler', (
      WidgetTester tester,
    ) async {
      // Le repli existe pour que le jour ou la base ajoute un controle, le
      // refus reste lisible au lieu de devenir une phrase generique fausse.
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()]
        ..erreurPrise = StateError('un motif que l ecran ne connait pas');

      await _monter(tester, matching: matching);
      await _ouvrirOngletEleves(tester);

      await tester.tap(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('un motif que l ecran ne connait pas'),
        findsOneWidget,
      );
    });

    testWidgets('le plafond refuse en base se nomme aussi', (
      WidgetTester tester,
    ) async {
      // Le plafond est un trigger separe : il peut refuser alors que l'ecran se
      // croyait sous la limite (regle changee entre la lecture et le geste).
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()]
        ..erreurPrise = StateError(
          'plafond d eleves atteint pour cet enseignant (5)',
        );

      await _monter(tester, matching: matching);
      await _ouvrirOngletEleves(tester);

      await tester.tap(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.creneaux.refusPlafond), findsOneWidget);
    });
  });

  group('ENS-06 : les etats du feed des creneaux disponibles', () {
    testWidgets('loading : un squelette, jamais un feed vide', (
      WidgetTester tester,
    ) async {
      // Le feed ne rendait quelque chose que si `hasValue` : pendant le premier
      // chargement, la vue affichait le compteur de plafond puis RIEN.
      final Completer<List<EleveEnAttente>> jamais =
          Completer<List<EleveEnAttente>>();

      await _monter(
        tester,
        extra: <Override>[
          elevesEnAttenteProvider.overrideWith((_) => jamais.future),
        ],
      );
      await _ouvrirOngletEleves(tester);

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.creneaux.aucunEleve), findsNothing);
      expect(find.text(t.enseignant.creneaux.feedErreur), findsNothing);
    });

    testWidgets('error : un message et une relecture, pas un ecran muet', (
      WidgetTester tester,
    ) async {
      // `hasError` n'etait jamais lu : une lecture en echec etait
      // indiscernable d'une file vide, et n'affichait meme pas l'EmptyState.
      await _monter(
        tester,
        extra: <Override>[
          elevesEnAttenteProvider.overrideWith(
            (_) async => throw StateError('fixture'),
          ),
        ],
      );
      await _ouvrirOngletEleves(tester);

      expect(find.text(t.enseignant.creneaux.feedErreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.text(t.creneaux.aucunEleve), findsNothing);
    });

    testWidgets('empty : le constat, et aucun bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _ouvrirOngletEleves(tester);

      expect(find.text(t.creneaux.aucunEleve), findsOneWidget);
      expect(find.text(t.creneaux.aucunEleveDetail), findsOneWidget);
    });

    testWidgets('offline : la file reste lisible, la prise n est pas rendue', (
      WidgetTester tester,
    ) async {
      // Hors ligne, le CTA restait pressable et echouait APRES le geste.
      await _monter(
        tester,
        matching: FauxServiceMatching()..feed = <EleveEnAttente>[_eleve()],
        horsLigne: true,
      );
      await _ouvrirOngletEleves(tester);

      expect(find.text(t.enseignant.creneaux.horsLignePrise), findsOneWidget);
      expect(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
        findsNothing,
      );
      // Consultable : la carte reste, seul le geste disparait.
      expect(find.text('Khadija'), findsOneWidget);
    });

    testWidgets('aucune coordonnee de famille n atteint l ecran', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        matching: FauxServiceMatching()..feed = <EleveEnAttente>[_eleve()],
      );
      await _ouvrirOngletEleves(tester);

      // Ce que la carte montre, et rien de plus (ADR-008).
      expect(find.text('Khadija'), findsOneWidget);
      expect(find.text('STUD-KB-000003'), findsOneWidget);
      expect(find.text(t.creneaux.niveau(niveau: 'debutant')), findsOneWidget);

      // L'identifiant immuable est ECARTE du balayage, et c'est le point : il
      // porte six chiffres d'affilee (`STUD-KB-000003`) et il est la seule
      // longue suite de chiffres qu'ADR-008 autorise a atteindre cet ecran --
      // c'est meme ce que la ligne 578 vient d'exiger. Sans cette exclusion, le
      // garde-fou se declencherait sur la donnee qu'il est cense proteger, et
      // aucun numero de telephone ne le ferait echouer davantage : un test qui
      // echoue toujours ne mesure rien.
      final List<String> rendus = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text texte) => texte.data ?? '')
          .where((String s) => s != 'STUD-KB-000003')
          .toList();
      expect(
        rendus.any((String s) => s.contains('@')),
        isFalse,
        reason: 'aucune adresse de courriel ne doit atteindre cet ecran',
      );
      expect(
        rendus.any((String s) => RegExp(r'\d{6,}').hasMatch(s)),
        isFalse,
        reason: 'aucun numero de telephone ne doit atteindre cet ecran',
      );
    });

    testWidgets('aucun depassement a 390 x 844 avec une file chargee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        matching: FauxServiceMatching()..feed = <EleveEnAttente>[
          for (int i = 0; i < 8; i++)
            _eleve(id: 'e$i', prenom: 'Famille $i', jours: i, jour: 1 + i % 7),
        ],
      );
      await _ouvrirOngletEleves(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('ENS-06 : les etats de la grille', () {
    testWidgets('loading : aucune heure avant que le fuseau ait repondu', (
      WidgetTester tester,
    ) async {
      // La grille se repliait sur 'Europe/Paris' code en dur : un enseignant de
      // Conakry lisait ses heures en heure de Paris, puis les voyait changer.
      final Completer<String> jamais = Completer<String>();

      await _monter(
        tester,
        extra: <Override>[monFuseauProvider.overrideWith((_) => jamais.future)],
      );

      expect(find.byType(Skeleton), findsWidgets);
      expect(
        find.text(t.disponibilites.fuseau(fuseau: 'Europe/Paris')),
        findsNothing,
        reason: 'un fuseau de repli affiche est un fuseau faux',
      );
    });

    testWidgets('error : la grille dit son echec et propose la relecture', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        extra: <Override>[
          monFuseauProvider.overrideWith((_) async => throw StateError('fix')),
        ],
      );

      expect(find.text(t.enseignant.creneaux.grilleErreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('empty : aucune heure posee se dit, et dit sa consequence', (
      WidgetTester tester,
    ) async {
      // Une grille vide pendant le chargement etait identique a une grille sans
      // aucune heure posee : les deux ne disaient rien.
      await _monter(tester);

      expect(find.text(t.enseignant.creneaux.aucuneHeure), findsOneWidget);
    });

    testWidgets('sauvegarde : la case enregistree est NOMMEE', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning();

      await _monter(tester, planning: planning);
      await _taperCase(
        tester,
        libelle: t.disponibilites.celluleLibre(jour: 'mardi', heure: '17'),
      );

      expect(planning.poses.length, 1);
      expect(planning.poses.single.creneau.jour, 2);
      expect(planning.poses.single.creneau.heure, 17);
      // `enCours` figeait la grille sans jamais dire qu'une case etait passee.
      expect(
        find.text(
          t.enseignant.creneaux.heureEnregistree(heure: 'mardi 17 h'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('conflit : une heure qui porte un eleve se VOIT', (
      WidgetTester tester,
    ) async {
      // Sans ce calcul, la case d'une heure engagee est indiscernable d'une
      // case libre. Le conflit se voit, il ne se bloque pas : retirer une
      // disponibilite n'annule aucun cours, et refuser le geste serait une
      // regle metier qu'aucun document du depot ne pose.
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 4, heure: 9, fuseau: 'Europe/Paris'),
        ]
        ..affectationsRendues = <Affectation>[_affectation(eleveId: 'x1')];

      await _monter(tester, planning: planning);

      // 1. Le conflit est visible AVANT le geste.
      expect(
        find.text(t.enseignant.creneaux.heureEngagee(heures: 'jeudi 9 h')),
        findsOneWidget,
      );

      await _taperCase(
        tester,
        libelle: t.disponibilites.cellulePosee(jour: 'jeudi', heure: '9'),
      );

      // 2. Le geste passe, et la confirmation dit ce qu'il ne fait PAS.
      expect(planning.retires.length, 1);
      expect(planning.retires.single.creneau.heure, 9);
      expect(
        find.text(t.enseignant.creneaux.retraitEngage(heure: 'jeudi 9 h')),
        findsOneWidget,
      );
    });

    testWidgets('une heure libre retiree ne parle d aucune reaffectation', (
      WidgetTester tester,
    ) async {
      // Le pendant du test ci-dessus : sans eleve sur l'heure, la confirmation
      // reste courte. Une phrase de reaffectation partout serait du bruit.
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning);
      await _taperCase(
        tester,
        libelle: t.disponibilites.cellulePosee(jour: 'mardi', heure: '17'),
      );

      expect(planning.retires.length, 1);
      expect(
        find.text(t.enseignant.creneaux.heureRetiree(heure: 'mardi 17 h')),
        findsOneWidget,
      );
    });

    testWidgets('offline : la grille reste lisible mais n accepte rien', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning, horsLigne: true);

      // Consultable : le compteur d'heures posees est la.
      expect(find.text(t.disponibilites.poseeUne), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.horsLigneGrille), findsOneWidget);
      // Et inerte : la case n'expose plus de libelle pressable.
      expect(
        find.bySemanticsLabel(
          t.disponibilites.cellulePosee(jour: 'mardi', heure: '17'),
        ),
        findsNothing,
      );
      expect(planning.poses, isEmpty);
      expect(planning.retires, isEmpty);
    });
  });
}
