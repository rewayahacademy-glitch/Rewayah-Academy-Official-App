// FORM-L2 : les formulaires d'administration font choisir l'eleve ou
// l'enseignant dans une liste cherchable au lieu de faire taper un
// identifiant (recensement FORM-AUTO-1, section 7 A1, A2, A8 ; K-57).
//
// Les cas partent des VRAIS ecrans (`GroupesPage`, `EvaluationsPage`) et de
// leurs vraies feuilles, ouvertes par leurs vrais boutons ; seuls les
// services sont des doubles (`support_form_l2.dart`). Horloge fixe : toutes
// les dates sont posees.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/personnes_proposables.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/core/widgets/selecteur_personne.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';

import '../support/harnais.dart';
import 'support_form_l2.dart';

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Monte un ecran a 1440 x 1600 : le rendu tabulaire porte le menu de ligne.
Future<void> _monter(
  WidgetTester tester,
  Widget ecran,
  List<Override> surcharges,
) async {
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hote(ecran, surcharges: surcharges));
  await tester.pumpAndSettle();
}

Future<void> _ouvrirCreation(WidgetTester tester, List<Override> s) async {
  await _monter(tester, const GroupesPage(), s);
  await _presser(tester, find.text(t.admin.groupes.creer).first);
}

Finder _carte(String id) => find.byKey(ValueKey<String>('personne-$id'));

/// CLASSE-FORM-1 : le genre de la classe est obligatoire et vient avant
/// l'enseignant.
Future<void> _choisirGenre(WidgetTester tester) =>
    _presser(tester, find.byKey(const ValueKey<String>('classe-genre-femmes')));

/// Le champ du nom, seul champ tape (CLASSE-FORM-1).
Finder get _champNom => find.descendant(
  of: find.byKey(const ValueKey<String>('classe-nom')),
  matching: find.byType(TextField),
);

void main() {
  group('Le filtre des personnes proposables', () {
    test(
      'garde le role demande, comptes actifs ou provisoires, tries par nom',
      () {
        final List<PersonneProposee> eleves = personnesProposablesDepuis(
          comptesFormL2,
          AppRole.student,
        );
        expect(eleves.map((PersonneProposee p) => p.id), <String>[
          'e-elias',
          'e-ines',
          'e-mariam',
        ]);
        expect(eleves.first.nom, 'Élias Haddad');
        expect(eleves.first.identifiant, 'ELV-EH-011');

        final List<PersonneProposee> enseignants = personnesProposablesDepuis(
          comptesFormL2,
          AppRole.teacher,
        );
        expect(enseignants.map((PersonneProposee p) => p.id), <String>[
          't-amina',
          't-yacine',
        ]);
      },
    );
  });

  group('Creer une classe : l\'enseignant se choisit dans la liste', () {
    testWidgets('plus aucun champ d\'identifiant ; la liste ne montre que les '
        'enseignants actifs', (WidgetTester tester) async {
      await _ouvrirCreation(
        tester,
        surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
      );

      expect(find.byType(SelecteurPersonne), findsOneWidget);
      expect(
        find.text(t.commun.selecteurPersonne.contexteEnseignant),
        findsOneWidget,
      );
      expect(_carte('t-amina'), findsOneWidget);
      expect(_carte('t-yacine'), findsOneWidget);
      expect(_carte('t-attente'), findsNothing);
      expect(_carte('e-mariam'), findsNothing);
      // Le nom et l'identifiant immuable, jamais l'identifiant technique.
      expect(find.text('Amina Diallo'), findsWidgets);
      expect(find.text('ENS\u2011AD\u2011001'), findsOneWidget);
      expect(find.text('t-amina'), findsNothing);
    });

    testWidgets(
      'choisir dans la liste porte l\'identifiant jusqu\'au service',
      (WidgetTester tester) async {
        final FauxGroupesFormL2 groupes = FauxGroupesFormL2();
        await _ouvrirCreation(
          tester,
          surchargesFormL2(
            comptes: FauxComptesFormL2(comptesFormL2),
            groupes: groupes,
          ),
        );

        await _choisirGenre(tester);
        await _presser(tester, _carte('t-yacine'));
        await _presser(
          tester,
          find.byKey(const ValueKey<String>('classe-jour-2')),
        );
        await _presser(
          tester,
          find.byKey(const ValueKey<String>('classe-heure')),
        );
        await _presser(tester, find.text('17\u00a0h').last);
        await tester.enterText(_champNom, 'Al-Fajr');
        await _presser(tester, find.text(t.admin.groupes.creerEnvoyer));

        expect(groupes.creesPour, <String>['t-yacine']);
        expect(groupes.creations.single.libelle, 'Al-Fajr');
      },
    );

    testWidgets('presser sans choix dit ce qui manque, sans rien envoyer', (
      WidgetTester tester,
    ) async {
      final FauxGroupesFormL2 groupes = FauxGroupesFormL2();
      await _ouvrirCreation(
        tester,
        surchargesFormL2(
          comptes: FauxComptesFormL2(comptesFormL2),
          groupes: groupes,
        ),
      );
      await _choisirGenre(tester);
      await _presser(tester, find.text(t.admin.groupes.creerEnvoyer));

      expect(find.text(t.admin.groupes.manqueEnseignant), findsOneWidget);
      expect(groupes.creesPour, isEmpty);
    });

    testWidgets('la recherche filtre par nom, sans accent ni casse, puis par '
        'identifiant ; sans resultat, l\'ecran le dit et propose d\'effacer', (
      WidgetTester tester,
    ) async {
      await _ouvrirCreation(
        tester,
        surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
      );
      final Finder recherche = find.widgetWithText(
        TextField,
        t.commun.selecteurPersonne.rechercheEnseignant,
      );

      await tester.enterText(recherche, 'BENALI');
      await tester.pumpAndSettle();
      expect(_carte('t-yacine'), findsOneWidget);
      expect(_carte('t-amina'), findsNothing);

      await tester.enterText(recherche, 'ens-ad');
      await tester.pumpAndSettle();
      expect(_carte('t-amina'), findsOneWidget);
      expect(_carte('t-yacine'), findsNothing);

      await tester.enterText(recherche, 'zzz');
      await tester.pumpAndSettle();
      expect(
        find.text(t.commun.selecteurPersonne.aucunResultat(recherche: 'zzz')),
        findsOneWidget,
      );
      await _presser(
        tester,
        find.text(t.commun.selecteurPersonne.effacerRecherche),
      );
      expect(_carte('t-amina'), findsOneWidget);
      expect(_carte('t-yacine'), findsOneWidget);
    });

    testWidgets(
      'liste vide : l\'ecran dit qu\'aucun enseignant n\'est actif et '
      'quoi faire',
      (WidgetTester tester) async {
        await _ouvrirCreation(
          tester,
          surchargesFormL2(
            comptes: FauxComptesFormL2(
              comptesFormL2
                  .where((CompteAdmin c) => c.role != AppRole.teacher)
                  .toList(),
            ),
          ),
        );

        expect(
          find.text(t.commun.selecteurPersonne.videEnseignant),
          findsOneWidget,
        );
        expect(
          find.text(t.commun.selecteurPersonne.videEnseignantDetail),
          findsOneWidget,
        );
      },
    );

    testWidgets('erreur de lecture : ce qui manque, la cause, et Reessayer '
        'relit la liste', (WidgetTester tester) async {
      // Echec durable : Riverpod 3 relance seul un provider en echec, un
      // echec unique serait absorbe avant d'etre vu.
      final FauxComptesFormL2 comptes = FauxComptesFormL2(
        comptesFormL2,
        echecs: 1 << 20,
      );
      await _ouvrirCreation(tester, surchargesFormL2(comptes: comptes));

      expect(
        find.text(t.commun.selecteurPersonne.erreurEnseignantTitre),
        findsOneWidget,
      );
      expect(
        find.text(t.commun.selecteurPersonne.erreurDetail),
        findsOneWidget,
      );
      expect(_carte('t-amina'), findsNothing);

      comptes.echecs = 0;
      final int avant = comptes.lectures;
      await _presser(tester, find.text(t.commun.etats.actions.reessayer).last);

      expect(comptes.lectures, greaterThan(avant));
      expect(_carte('t-amina'), findsOneWidget);
    });
  });

  group(
    'Ajouter un eleve a une classe : l\'eleve se choisit dans la liste',
    () {
      testWidgets('choisir l\'eleve et ecrire le motif l\'ajoute', (
        WidgetTester tester,
      ) async {
        final FauxGroupesFormL2 groupes = FauxGroupesFormL2();
        await _monter(
          tester,
          const GroupesPage(),
          surchargesFormL2(
            comptes: FauxComptesFormL2(comptesFormL2),
            groupes: groupes,
          ),
        );
        await _presser(tester, find.byType(MenuActions).first);
        await _presser(tester, find.text(t.admin.groupes.actionAjouter).last);

        expect(_carte('e-mariam'), findsOneWidget);
        expect(_carte('e-elias'), findsOneWidget);
        expect(_carte('e-coupe'), findsNothing);
        expect(_carte('t-amina'), findsNothing);
        expect(_carte('g-fatou'), findsNothing);

        // Sans eleve : la raison, pas un bouton grise.
        await _presser(tester, find.text(t.admin.groupes.ajouterEnvoyer));
        expect(find.text(t.admin.groupes.manqueEleve), findsOneWidget);

        await _presser(tester, _carte('e-ines'));
        // Eleve choisi, sans motif : le manque se dit sous les puces (le
        // selecteur recoit `erreur`), rien ne part.
        await _presser(tester, find.text(t.admin.groupes.ajouterEnvoyer));
        expect(find.text(t.admin.groupes.manqueEleve), findsNothing);
        expect(
          find.descendant(
            of: find.byType(SelecteurMotif),
            matching: find.text(t.formulaire.motif.manque),
          ),
          findsOneWidget,
        );
        expect(groupes.ajouts, isEmpty);
        // FORM-L1 : le motif libre s'ecrit apres « Autre ».
        await _presser(tester, find.byKey(SelecteurMotif.cleAutre));
        await tester.enterText(
          find.widgetWithText(TextField, t.admin.groupes.champMotif),
          'Inscription confirmee',
        );
        await _presser(tester, find.text(t.admin.groupes.ajouterEnvoyer));

        expect(groupes.ajouts, <(String, String)>[
          ('e-ines', 'Inscription confirmee'),
        ]);
      });
    },
  );

  group('Planifier une evaluation : l\'eleve se choisit dans la liste', () {
    testWidgets('choisir l\'eleve, le niveau et la date planifie pour lui', (
      WidgetTester tester,
    ) async {
      final FauxEvaluationsFormL2 evaluations = FauxEvaluationsFormL2();
      await _monter(
        tester,
        const EvaluationsPage(),
        surchargesFormL2(
          comptes: FauxComptesFormL2(comptesFormL2),
          evaluations: evaluations,
        ),
      );
      await _presser(tester, find.text(t.admin.evaluations.planifier).first);

      expect(find.byType(SelecteurPersonne), findsOneWidget);
      await _presser(tester, find.text(t.admin.evaluations.planifierEnvoyer));
      expect(find.text(t.admin.evaluations.manqueEleve), findsOneWidget);

      await _presser(tester, _carte('e-mariam'));
      await _presser(tester, find.text(niveauFormL2.nomHumain));
      // FORM-L4 : la date se choisit dans le calendrier, elle ne se tape plus.
      await _presser(tester, find.byKey(const ValueKey<String>('champ-date')));
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await _presser(tester, find.text(t.admin.evaluations.planifierEnvoyer));

      expect(evaluations.planifiees, hasLength(1));
      expect(evaluations.planifiees.single.$1, 'e-mariam');
      expect(evaluations.planifiees.single.$2, 'n1');
      expect(evaluations.planifiees.single.$3, DateTime(2026, 10, 15));
    });
  });

  group('Le composant borne la liste', () {
    testWidgets('au-dela du maximum, il dit combien restent ; la personne '
        'choisie reste visible malgre la recherche', (
      WidgetTester tester,
    ) async {
      final List<PersonneProposee> dix = <PersonneProposee>[
        for (int i = 0; i < 10; i++)
          PersonneProposee(id: 'p$i', nom: 'Eleve $i', identifiant: 'ELV-$i'),
      ];
      String? choisie;
      await tester.pumpWidget(
        hote(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => Scaffold(
              body: SingleChildScrollView(
                child: SelecteurPersonne(
                  sorte: SortePersonne.eleve,
                  personnes: AsyncValue<List<PersonneProposee>>.data(dix),
                  choisie: choisie,
                  onChoix: (PersonneProposee p) =>
                      setState(() => choisie = p.id),
                  onReessayer: () {},
                  maximumAffiche: 4,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_carte('p3'), findsOneWidget);
      expect(_carte('p4'), findsNothing);
      expect(
        find.text(t.commun.selecteurPersonne.autresPlusieurs(n: 6)),
        findsOneWidget,
      );

      await _presser(tester, _carte('p2'));
      expect(choisie, 'p2');

      await tester.enterText(
        find.widgetWithText(
          TextField,
          t.commun.selecteurPersonne.rechercheEleve,
        ),
        'Eleve 9',
      );
      await tester.pumpAndSettle();
      expect(_carte('p9'), findsOneWidget);
      expect(_carte('p2'), findsOneWidget);
      expect(_carte('p0'), findsNothing);
    });
  });
}
