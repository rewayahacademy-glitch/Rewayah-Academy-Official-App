import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_journal/journal_page.dart';

import '../support/harnais.dart';
import '../support/rangee_plus.dart';
import '../support/selecteur_section.dart';

/// Une fenetre haute, et large ou etroite selon ce qu'on mesure.
///
/// **Haute** parce que la fenetre par defaut de `flutter_test` fait 800 x 600,
/// gabarit tablette plus court que tout telephone : ce qui depasse n'est
/// simplement pas construit, et neuf tests du depot s'y sont deja trompes.
/// **La largeur est le sujet** de `ADM-04` : au dela de 1024 il rend un tableau
/// dense, en dessous une carte par entree.
void _fenetre(WidgetTester tester, {double largeur = 1400}) {
  tester.view.physicalSize = Size(largeur, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Le 12 septembre 2026, fige.
///
/// Aucune heure relative ici : `journee_test.dart` a deja appris au depot ce
/// que coute une assertion qui depend de l'heure a laquelle la suite tourne.
DateTime _quand(int minutes) =>
    DateTime(2026, 9, 12, 10).subtract(Duration(minutes: minutes));

EntreeJournal _entree({
  required int id,
  String type = 'kyc_read',
  String? acteur = 'u1',
  String? nom = 'Khadija Ndiaye',
  String? role = 'admin',
  String table = 'kyc_documents',
  Map<String, dynamic> details = const <String, dynamic>{},
}) => EntreeJournal(
  id: id,
  survenuLe: _quand(id),
  acteur: acteur,
  roleActeur: role,
  nomActeur: nom,
  typeEvenement: type,
  tableVisee: table,
  details: details,
);

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceJournal service,
}) async {
  await tester.pumpWidget(
    hote(
      const JournalPage(),
      surcharges: <Override>[serviceJournalProvider.overrideWithValue(service)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ADM-04 : un journal se lit, et rien d\'autre', () {
    testWidgets('aucun bouton n\'ecrit, et le tableau dense sort au desktop', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = <EntreeJournal>[_entree(id: 3), _entree(id: 2)]
        ..chaine = const EtatChaine(verifiees: 2, rompues: 0);

      await _monter(tester, service: service);

      expect(find.byType(DataCollection<EntreeJournal>), findsOneWidget);
      // L'en-tete de colonnes n'existe qu'en rendu tableau.
      expect(find.text(t.admin.journal.colonneQuand), findsOneWidget);
      expect(find.text(t.admin.journal.colonneQuoi), findsOneWidget);

      // Le seul ecran du produit sans action principale : la seule chose qu'on
      // puisse faire d'un journal immuable, c'est le lire.
      for (final ActionPrincipale bouton in tester.widgetList<ActionPrincipale>(
        find.byType(ActionPrincipale),
      )) {
        expect(
          bouton.niveau,
          isNot(NiveauAction.principale),
          reason: 'ADM-04 ne porte aucune action principale',
        );
      }
    });

    testWidgets('sous 1024, une carte par entree et aucun en-tete de colonne', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, largeur: 390);
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = <EntreeJournal>[_entree(id: 3)]
        ..chaine = const EtatChaine(verifiees: 1, rompues: 0);

      await _monter(tester, service: service);

      // Un tableau retreci est precisement ce que 05-regles-responsive.md
      // section 4 interdit.
      expect(find.text(t.admin.journal.colonneQuand), findsNothing);
      expect(find.text(t.admin.journal.colonneQuoi), findsNothing);
      // La colonne identifiante est devenue le titre de la carte.
      expect(find.text(t.admin.journal.evtKycLu), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(t.admin.journal.evtKycLu),
          matching: find.byType(AppCard),
        ),
        findsOneWidget,
      );
    });

    testWidgets('les deux onglets de Securite et audit sont en tete', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await _monter(tester, service: FauxServiceJournal());
      expect(sectionVisible(t.admin.journal.titre), findsOneWidget);
      expect(sectionVisible(t.admin.observations.titre), findsOneWidget);
    });

    testWidgets('la chaine intacte se dit en tete, avant les entrees', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = <EntreeJournal>[_entree(id: 1)]
        ..chaine = const EtatChaine(verifiees: 42, rompues: 0);

      await _monter(tester, service: service);

      expect(find.text(t.admin.journal.chaineIntacte), findsOneWidget);
      expect(
        find.text(t.admin.journal.chaineIntacteDetail(nombre: 42)),
        findsOneWidget,
      );
      expect(find.text(t.admin.journal.chaineRompue), findsNothing);
    });

    testWidgets('une chaine rompue le dit, et nomme l\'entree en cause', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = <EntreeJournal>[_entree(id: 1)]
        ..chaine = const EtatChaine(
          verifiees: 42,
          rompues: 2,
          premiereRompue: 17,
        );

      await _monter(tester, service: service);

      expect(find.text(t.admin.journal.chaineRompue), findsOneWidget);
      expect(
        find.text(t.admin.journal.chaineRompueDetail(nombre: 2, entree: 17)),
        findsOneWidget,
      );
      // Et les entrees restent lisibles : un journal douteux se lit quand meme,
      // c'est meme le moment ou on en a le plus besoin.
      expect(find.byType(DataCollection<EntreeJournal>), findsOneWidget);
    });

    testWidgets(
      'une verification qui echoue ne fait pas passer le journal pour intact',
      (WidgetTester tester) async {
        _fenetre(tester);
        final FauxServiceJournal service = FauxServiceJournal()
          ..entreesEnBase = <EntreeJournal>[_entree(id: 1)]
          ..erreurChaine = Exception('hors ligne');

        await _monter(tester, service: service);

        expect(find.text(t.admin.journal.chaineInconnue), findsOneWidget);
        expect(find.text(t.admin.journal.chaineIntacte), findsNothing);
      },
    );

    testWidgets('changer de filtre relit depuis le debut, sans curseur', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = <EntreeJournal>[
          _entree(id: 3),
          _entree(id: 2, type: 'profil_cree', table: 'profiles'),
        ]
        ..chaine = const EtatChaine(verifiees: 2, rompues: 0)
        ..filtres0 = const FiltresJournal(
          total: 2,
          actions: <ValeurFiltre>[
            ValeurFiltre(valeur: 'kyc_read', libelle: 'kyc_read', nombre: 1),
            ValeurFiltre(
              valeur: 'profil_cree',
              libelle: 'profil_cree',
              nombre: 1,
            ),
          ],
          acteurs: <ValeurFiltre>[],
        );

      await _monter(tester, service: service);
      service.lectures.clear();

      // Le filtre d'evenement est un menu depuis la correction d'ergonomie du
      // 18 septembre 2026 : le vocabulaire vit en base et grandit a chaque
      // migration, donc une vingtaine de pastilles repoussaient le journal
      // sous le pli. On ouvre le menu, puis on choisit son entree.
      // L4-07 : le menu est la quatrieme puce, rangee sous « Plus ».
      await ouvrirMenuFiltre(tester, find.byType(MenuFiltre<String>));
      await tester.tap(find.text(t.admin.journal.evtProfilCree).last);
      await tester.pumpAndSettle();
      await fermerPlus(tester);

      // Une seule lecture, sans curseur : garder les entrees deja lues
      // melangerait deux filtres dans une meme liste.
      expect(service.lectures, hasLength(1));
      expect(service.lectures.single.type, 'profil_cree');
      expect(service.lectures.single.curseur, isNull);

      // L'assertion se borne a la collection, et pas a l'ecran : la pilule de
      // filtre porte elle aussi le libelle du type, et un `findsNothing` global
      // mesurerait la barre de filtres au lieu de la liste.
      final Finder collection = find.byType(DataCollection<EntreeJournal>);
      expect(
        find.descendant(
          of: collection,
          matching: find.text(t.admin.journal.evtProfilCree),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: collection,
          matching: find.text(t.admin.journal.evtKycLu),
        ),
        findsNothing,
      );
    });

    testWidgets('la suite se demande avec le curseur de la derniere entree', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      // Une page pleine, donc une suite possible. `parPage` vaut 50 : sans une
      // premiere page pleine, l'ecran conclurait a la fin du journal.
      final List<EntreeJournal> journal = <EntreeJournal>[
        for (int i = 60; i > 0; i--) _entree(id: i),
      ];
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = journal
        ..chaine = const EtatChaine(verifiees: 60, rompues: 0);

      await _monter(tester, service: service);

      final Finder suite = find.widgetWithText(
        ActionPrincipale,
        t.admin.journal.chargerSuite,
      );
      // Deux zones defilantes depuis les onglets de Securite et audit (la
      // barre d'onglets defile aussi) : on nomme celle du journal.
      await tester.scrollUntilVisible(
        suite,
        400,
        scrollable: find
            .descendant(
              of: find.byType(DataCollection<EntreeJournal>),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      // `scrollUntilVisible` s'arrete des que le finder **trouve** le widget,
      // c'est-a-dire des qu'il est construit — or une `ListView` construit
      // au-dela de son viewport. Le pied de page peut donc etre bati quelques
      // pixels sous le bord, et le tap manquerait sa cible.
      await tester.ensureVisible(suite);
      await tester.pumpAndSettle();
      await tester.tap(suite);
      await tester.pumpAndSettle();

      expect(service.lectures, hasLength(2));
      final CurseurJournal? curseur = service.lectures.last.curseur;
      expect(curseur, isNotNull);
      // La 50e entree lue est celle d'identifiant 11 : le journal descend de 60
      // a 1, et la premiere page en a pris cinquante.
      expect(curseur!.avantId, 11);
      // Et le filtre de la premiere lecture voyage avec la seconde.
      expect(service.lectures.last.type, service.lectures.first.type);
    });

    testWidgets('une page incomplete dit que le journal est remonte', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = <EntreeJournal>[_entree(id: 2), _entree(id: 1)]
        ..chaine = const EtatChaine(verifiees: 2, rompues: 0);

      await _monter(tester, service: service);

      expect(find.text(t.admin.journal.fin), findsOneWidget);
      expect(
        find.widgetWithText(ActionPrincipale, t.admin.journal.chargerSuite),
        findsNothing,
      );
    });

    testWidgets('un journal vide sans filtre est une bonne nouvelle', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..chaine = const EtatChaine(verifiees: 0, rompues: 0);

      await _monter(tester, service: service);

      // Le troisieme registre de `EmptyState` : rien a traiter n'est pas une
      // panne (`02-regles-ux.md` section 6). Aucun bouton, donc.
      expect(find.text(t.admin.journal.vide), findsOneWidget);
      expect(find.text(t.admin.journal.effacerFiltres), findsNothing);
    });

    testWidgets('un journal vide SOUS FILTRE propose de relacher le filtre', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..chaine = const EtatChaine(verifiees: 0, rompues: 0)
        ..filtres0 = const FiltresJournal(
          total: 0,
          actions: <ValeurFiltre>[
            ValeurFiltre(valeur: 'kyc_read', libelle: 'kyc_read', nombre: 0),
          ],
          acteurs: <ValeurFiltre>[],
        );

      await _monter(tester, service: service);

      // L'ecran s'ouvre sans filtre : c'est en en posant un qu'on entre dans
      // l'impasse, et c'est la qu'elle doit avoir une sortie.
      await tester.tap(
        find.widgetWithText(FilterPill, t.admin.journal.periodeSemaine),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.admin.journal.videFiltre), findsOneWidget);
      expect(find.text(t.admin.journal.effacerFiltres), findsOneWidget);

      await tester.tap(find.text(t.admin.journal.effacerFiltres));
      await tester.pumpAndSettle();

      // Effacer les filtres remonte a la periode la plus large, sans quoi le
      // bouton promettrait plus que ce qu'il fait.
      expect(service.lectures.last.depuis, isNull);
      expect(service.lectures.last.type, isNull);
      expect(service.lectures.last.acteur, isNull);
    });

    testWidgets('le chargement montre la forme de la liste, pas un mot', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      await tester.pumpWidget(
        hote(
          const JournalPage(),
          surcharges: <Override>[
            serviceJournalProvider.overrideWithValue(
              FauxServiceJournal()..delai = const Duration(milliseconds: 200),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text(t.commun.chargement), findsNothing);

      // `pumpAndSettle` ne vide pas un `Future.delayed` : sans cette avance de
      // temps, le test se termine sur un minuteur en attente.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    });

    testWidgets('un journal illisible propose de reessayer', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..erreurEntrees = Exception('hors ligne');

      await _monter(tester, service: service);

      expect(find.text(t.admin.journal.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets(
      'une ecriture sans acteur humain est nommee, pas laissee vide',
      (WidgetTester tester) async {
        _fenetre(tester);
        final FauxServiceJournal service = FauxServiceJournal()
          ..entreesEnBase = <EntreeJournal>[
            _entree(id: 2, acteur: null, nom: null, role: null),
            _entree(id: 1, nom: null),
          ]
          ..chaine = const EtatChaine(verifiees: 2, rompues: 0);

        await _monter(tester, service: service);

        // Une case vide dans un journal est une ligne qu'on ne peut opposer a
        // personne : les deux cas ont chacun leur mot.
        expect(find.text(t.admin.journal.acteurSysteme), findsOneWidget);
        expect(find.text(t.admin.journal.acteurInconnu), findsOneWidget);
        expect(find.text(t.admin.journal.roleAucun), findsOneWidget);
      },
    );

    testWidgets('un type d\'evenement inconnu s\'affiche tel quel', (
      WidgetTester tester,
    ) async {
      _fenetre(tester);
      final FauxServiceJournal service = FauxServiceJournal()
        ..entreesEnBase = <EntreeJournal>[
          _entree(id: 1, type: 'seance_forcee_par_le_futur'),
        ]
        ..chaine = const EtatChaine(verifiees: 1, rompues: 0);

      await _monter(tester, service: service);

      // Le vocabulaire vit en base et grandira : un ecran qui n'affiche que ce
      // qu'il sait nommer cacherait les evenements les plus recents.
      expect(find.text('seance_forcee_par_le_futur'), findsOneWidget);
    });
  });

  group('ADM-04 : ce que les colonnes promettent', () {
    test('la colonne identifiante est le type d\'evenement', () {
      final List<ColonneDonnees<EntreeJournal>> colonnes = colonnesJournal();
      final Iterable<ColonneDonnees<EntreeJournal>> identifiantes = colonnes
          .where(
            (ColonneDonnees<EntreeJournal> c) =>
                c.role == RoleColonne.identifiante,
          );

      // Une seule, sinon la carte aurait deux titres.
      expect(identifiantes, hasLength(1));
      expect(identifiantes.first.titre, t.admin.journal.colonneQuoi);
    });

    test('le detail se borne a trois couples', () {
      final String resume = resumeDetails(<String, dynamic>{
        'a': 1,
        'b': 2,
        'c': 3,
        'd': 4,
      });

      // Une ligne de tableau dense qui double de hauteur selon son contenu
      // n'est plus un tableau.
      expect(resume, 'a 1 · b 2 · c 3');
      expect(resumeDetails(const <String, dynamic>{}), isEmpty);
    });

    test(
      'la periode se traduit en borne basse, et « tout » n\'en pose pas',
      () {
        final DateTime maintenant = DateTime(2026, 9, 12, 10);

        expect(
          PeriodeJournal.semaine.depuis(maintenant),
          DateTime(2026, 9, 5, 10),
        );
        expect(
          PeriodeJournal.mois.depuis(maintenant),
          DateTime(2026, 8, 13, 10),
        );
        expect(PeriodeJournal.tout.depuis(maintenant), isNull);
      },
    );
  });
}
