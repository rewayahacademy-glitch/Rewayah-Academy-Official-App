// PLAN-DE-CLASSE A (lot 5, 13/11/2026), les ecrans de la direction, par le
// vrai routeur : l'etape d'une classe deja ouverte, le jour de debut d'un
// eleve, qui n'a pas d'etape et pourquoi (Diagnostics), l'impasse du brouillon
// (Programmes). Les regles sont prouvees cote serveur
// (supabase/tests/scenarios_plan_de_classe_a.sql) ; ici, le geste envoye et la
// phrase montree.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_diagnostics.dart';
import 'package:rewayah_academy/core/admin/service_plan_classe.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';

import '../../support/monter_admin_demo.dart';
import 'fauxs.dart';

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester, fois: 3);
  await tester.tap(cible);
  await stabiliser(tester);
}

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

/// Les services que ce test fournit lui-meme : la demonstration ne les ferme pas.
final List<Object> _fournis = <Object>[
  servicePlanClasseProvider,
  serviceProgrammeProvider,
  serviceDiagnosticsProvider,
];

List<Override> _surcharges(
  FauxPlanClasse plan, {
  FauxProgrammePublie? programme,
  FauxDiagnostics? diagnostics,
}) => <Override>[
  servicePlanClasseProvider.overrideWithValue(plan),
  serviceProgrammeProvider.overrideWithValue(
    programme ?? FauxProgrammePublie(),
  ),
  if (diagnostics != null)
    serviceDiagnosticsProvider.overrideWithValue(diagnostics),
];

Future<void> _fiche(
  WidgetTester tester,
  FauxPlanClasse plan, {
  Size taille = const Size(1440, 1600),
  double echelle = 1,
  TextDirection? direction,
}) => monterAdminDemo(
  tester,
  route: Routes.adminOperationsGroupePour('demo-classe-1'),
  plus: _surcharges(plan),
  servicesFournis: _fournis,
  taille: taille,
  echelle: echelle,
  direction: direction,
);

Future<void> _ouvrirMenuClasse(WidgetTester tester) async {
  // Le menu de la classe est le dernier de la fiche (les eleves le precedent).
  await _presser(tester, find.byType(MenuActions).last);
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final p = t.admin.planClasse;

  group('fiche de la classe : l\'etape', () {
    testWidgets('une classe sans etape le dit, avec ses eleves sans etape', (
      tester,
    ) async {
      await _fiche(tester, FauxPlanClasse());
      expect(find.text(p.etapeCle), findsOneWidget);
      expect(find.text(p.aucuneEtape), findsOneWidget);
      expect(find.text(p.sansEtapeMembres(n: 2)), findsOneWidget);
    });

    testWidgets('le libelle suit le serveur : « Changer » quand la classe a '
        'deja une etape', (tester) async {
      await _fiche(
        tester,
        FauxPlanClasse(
          etape: const EtapeClasse(
            niveauId: 'n2',
            etapeNom: 'Mots',
            programmePublie: true,
            membres: 3,
            membresSansEtape: 0,
          ),
        ),
      );
      expect(find.text('Mots'), findsOneWidget);
      await _ouvrirMenuClasse(tester);
      expect(find.text(p.changerEtape), findsOneWidget);
      expect(find.text(p.donnerEtape), findsNothing);
    });

    testWidgets('donner une etape : etape, motif, puis le geste serveur', (
      tester,
    ) async {
      final FauxPlanClasse plan = FauxPlanClasse();
      await _fiche(tester, plan);
      await _ouvrirMenuClasse(tester);
      await _presser(tester, find.text(p.donnerEtape).last);
      // Les quatre etapes de la version publiee, par leur nom humain.
      expect(find.text('Lettres'), findsOneWidget);
      expect(find.text('Sourates'), findsOneWidget);
      // Bouton jamais grise : sans etape choisie, la phrase dit quoi faire.
      await _presser(tester, find.text(p.donnerEnvoyer));
      expect(find.text(p.donnerManque), findsOneWidget);
      expect(plan.niveauxDonnes, isEmpty);
      await _presser(tester, find.text('Lettres'));
      // Sans motif : rien n'est envoye, le motif manquant se dit.
      await _presser(tester, find.text(p.donnerEnvoyer));
      expect(find.text(t.formulaire.motif.manque), findsWidgets);
      expect(plan.niveauxDonnes, isEmpty);
      await _presser(tester, find.text(p.motifs.classe));
      await _presser(tester, find.text(p.donnerEnvoyer));
      expect(plan.niveauxDonnes.length, 1);
      expect(plan.niveauxDonnes.single.$1, 'demo-classe-1');
      expect(plan.niveauxDonnes.single.$2, 'n1');
      expect(plan.niveauxDonnes.single.$3, p.motifs.classe);
      // La feuille est fermee, la fiche relue : l'etape se lit.
      expect(find.text(p.donnerEnvoyer), findsNothing);
      expect(find.text('Lettres'), findsOneWidget);
      expect(find.text(p.aucuneEtape), findsNothing);
    });

    testWidgets('un refus du serveur est dit en mots simples, la feuille '
        'reste ouverte', (tester) async {
      final FauxPlanClasse plan = FauxPlanClasse()
        ..echec = Exception('message: niveau_non_publie, code: P0001');
      await _fiche(tester, plan);
      await _ouvrirMenuClasse(tester);
      await _presser(tester, find.text(p.donnerEtape).last);
      await _presser(tester, find.text('Mots'));
      await _presser(tester, find.text(p.motifs.reprise));
      await _presser(tester, find.text(p.donnerEnvoyer));
      expect(find.text(p.refus.niveauNonPublie), findsOneWidget);
      expect(find.text(p.donnerEnvoyer), findsOneWidget);
      expect(plan.niveauxDonnes, isEmpty);
    });

    testWidgets('sans version publiee, la feuille le dit et ne propose rien', (
      tester,
    ) async {
      await monterAdminDemo(
        tester,
        route: Routes.adminOperationsGroupePour('demo-classe-1'),
        servicesFournis: _fournis,
        plus: _surcharges(
          FauxPlanClasse(),
          programme: FauxProgrammePublie(
            versionsListe: <VersionProgramme>[
              FauxProgrammePublie.version(
                'v1',
                StatutVersionProgramme.brouillon,
                1,
                niveaux: 0,
              ),
            ],
          ),
        ),
        taille: const Size(1440, 1600),
      );
      await _ouvrirMenuClasse(tester);
      await _presser(tester, find.text(p.donnerEtape).last);
      expect(find.text(p.aucunProgramme), findsOneWidget);
      expect(find.text(p.donnerEnvoyer), findsNothing);
    });
  });

  group('un eleve deja en cours : le jour de debut', () {
    Future<void> ouvrir(WidgetTester tester, FauxPlanClasse plan) async {
      await _fiche(tester, plan);
      final Finder ligne = find.descendant(
        of: find.widgetWithText(ListTile, 'Mariam Exemple'),
        matching: find.byType(MenuActions),
      );
      await _presser(tester, ligne);
      await _presser(tester, find.text(p.dateAction).last);
    }

    testWidgets('sans jour choisi, la phrase dit quoi faire', (tester) async {
      final FauxPlanClasse plan = FauxPlanClasse();
      await ouvrir(tester, plan);
      await _presser(tester, find.text(p.dateEnvoyer));
      expect(find.text(p.dateManque), findsOneWidget);
      expect(plan.datations, isEmpty);
    });

    testWidgets('un jour, un motif, puis le geste serveur', (tester) async {
      final FauxPlanClasse plan = FauxPlanClasse();
      await ouvrir(tester, plan);
      await _presser(tester, _cle('champ-date'));
      await _presser(tester, find.text('OK'));
      await _presser(tester, find.text(p.dateMotifs.avant));
      await _presser(tester, find.text(p.dateEnvoyer));
      expect(plan.datations.length, 1);
      expect(plan.datations.single.$1, 'demo-classe-1-Mariam');
      expect(plan.datations.single.$3, p.dateMotifs.avant);
      expect(find.text(p.dateEnvoyer), findsNothing);
    });

    testWidgets(
      'un jour sous le plancher : le refus dit le plus ancien jour accepte',
      (tester) async {
        final FauxPlanClasse plan = FauxPlanClasse()
          ..echec = Exception(
            'message: date_sous_plancher: 2016-11-13, code: P0001',
          );
        await ouvrir(tester, plan);
        await _presser(tester, _cle('champ-date'));
        await _presser(tester, find.text('OK'));
        await _presser(tester, find.text(p.dateMotifs.correction));
        await _presser(tester, find.text(p.dateEnvoyer));
        expect(
          find.text(p.refus.dateSousPlancher(date: '13/11/2016')),
          findsOneWidget,
        );
      },
    );
  });

  group('Diagnostics : qui n\'a pas d\'etape', () {
    Future<void> monter(
      WidgetTester tester,
      FauxPlanClasse plan,
      FauxDiagnostics diag, {
      Size taille = const Size(1440, 2200),
    }) => monterAdminDemo(
      tester,
      route: Routes.adminPedagogieDiagnostics,
      servicesFournis: _fournis,
      plus: _surcharges(plan, diagnostics: diag),
      taille: taille,
    );

    testWidgets('les eleves, leur classe et pourquoi, d\'un seul regard', (
      tester,
    ) async {
      await monter(tester, FauxPlanClasse(), FauxDiagnostics());
      expect(find.text(p.sansEtape.titre), findsWidgets);
      expect(find.text('Classe An-Nour'), findsWidgets);
      expect(find.textContaining('Nour Exemple'), findsOneWidget);
      expect(find.textContaining(p.sansEtape.raisonDebutant), findsOneWidget);
      expect(find.textContaining(p.sansEtape.raisonAttente), findsOneWidget);
    });

    testWidgets('le rattachement : confirmer, puis la liste est a jour', (
      tester,
    ) async {
      final FauxPlanClasse plan = FauxPlanClasse();
      await monter(tester, plan, FauxDiagnostics());
      await _presser(tester, _cle('placements-rattacher'));
      expect(find.text(p.sansEtape.rattacherDetail), findsOneWidget);
      await _presser(tester, find.text(p.sansEtape.rattacherEnvoyer));
      expect(plan.rattachements, 1);
      expect(find.text(p.sansEtape.rattacherFait), findsOneWidget);
      // Le debutant a quitte la liste ; l'eleve qui attend l'entretien reste.
      expect(find.textContaining('Nour Exemple'), findsNothing);
      expect(find.textContaining(p.sansEtape.raisonAttente), findsOneWidget);
    });

    testWidgets('un refus du rattachement est dit, rien n\'est annonce', (
      tester,
    ) async {
      final FauxPlanClasse plan = FauxPlanClasse()
        ..echec = Exception('message: aucun_programme_publie, code: P0001');
      await monter(tester, plan, FauxDiagnostics());
      await _presser(tester, _cle('placements-rattacher'));
      await _presser(tester, find.text(p.sansEtape.rattacherEnvoyer));
      expect(find.text(p.refus.aucunProgrammePublie), findsOneWidget);
      expect(find.text(p.sansEtape.rattacherFait), findsNothing);
    });

    testWidgets('le placement envoie le jour de debut quand on en donne un', (
      tester,
    ) async {
      final FauxDiagnostics diag = FauxDiagnostics();
      await monter(tester, FauxPlanClasse(), diag);
      await _presser(tester, find.text('Lettres'));
      await _presser(tester, _cle('champ-date'));
      await _presser(tester, find.text('OK'));
      expect(find.text(p.debutRetirer), findsOneWidget);
      await _presser(tester, find.text(t.motifs.placement.debutant));
      await _presser(tester, find.text(t.admin.diagnostics.decider));
      expect(diag.decisions.length, 1);
      expect(diag.decisions.single.$4, isNotNull);
    });

    testWidgets('sans jour donne, le placement part sans date', (tester) async {
      final FauxDiagnostics diag = FauxDiagnostics();
      await monter(tester, FauxPlanClasse(), diag);
      await _presser(tester, find.text('Lettres'));
      await _presser(tester, find.text(t.motifs.placement.debutant));
      await _presser(tester, find.text(t.admin.diagnostics.decider));
      expect(diag.decisions.single.$4, isNull);
    });
  });

  group('Programmes : l\'impasse du brouillon', () {
    FauxProgrammePublie brouillon() => FauxProgrammePublie(
      versionsListe: <VersionProgramme>[
        FauxProgrammePublie.version(
          'v1',
          StatutVersionProgramme.brouillon,
          1,
          niveaux: 1,
        ),
      ],
    );

    Future<void> monter(
      WidgetTester tester,
      FauxPlanClasse plan,
      FauxProgrammePublie prog,
    ) => monterAdminDemo(
      tester,
      route: Routes.adminPedagogieProgrammes,
      servicesFournis: _fournis,
      plus: _surcharges(plan, programme: prog),
      taille: const Size(1440, 1600),
    );

    testWidgets('un brouillon incomplet dit pourquoi et offre la sortie', (
      tester,
    ) async {
      final FauxPlanClasse plan = FauxPlanClasse(
        etat: const EtatPublication(
          raison: RaisonBrouillon.incomplet,
          detail: 'Lecture',
        ),
      );
      final FauxProgrammePublie prog = brouillon();
      await monter(tester, plan, prog);
      expect(
        find.text(p.brouillon.incomplet(etape: 'Lecture')),
        findsOneWidget,
      );
      // La creation d'une version vide reste offerte malgre le brouillon.
      expect(find.text(t.admin.programmes.creerVersion), findsOneWidget);
      await _presser(tester, _cle('programmes-repartir'));
      expect(find.text(p.brouillon.repartirDetail), findsOneWidget);
      await _presser(tester, find.text(p.brouillon.repartirEnvoyer));
      expect(plan.repartirs, 1);
    });

    testWidgets('un brouillon publiable ne montre aucun avertissement', (
      tester,
    ) async {
      await monter(tester, FauxPlanClasse(), brouillon());
      expect(_cle('programmes-brouillon-bloque'), findsNothing);
      expect(_cle('programmes-repartir'), findsNothing);
    });

    testWidgets(
      'sommes incoherentes et bases absentes : la phrase du serveur',
      (tester) async {
        await monter(
          tester,
          FauxPlanClasse(
            etat: const EtatPublication(
              raison: RaisonBrouillon.incoherent,
              detail: 'Les bases, Adulte',
            ),
          ),
          brouillon(),
        );
        expect(
          find.text(p.brouillon.incoherent(niveau: 'Les bases, Adulte')),
          findsOneWidget,
        );
      },
    );

    testWidgets('un echec de creation est dit, sans nouvelle version', (
      tester,
    ) async {
      final FauxPlanClasse plan = FauxPlanClasse(
        etat: const EtatPublication(raison: RaisonBrouillon.sansBases),
      );
      await monter(tester, plan, brouillon());
      plan.echec = Exception('message: reserve a la direction, code: 42501');
      await _presser(tester, _cle('programmes-repartir'));
      await _presser(tester, find.text(p.brouillon.repartirEnvoyer));
      expect(
        find.text(
          p.brouillon.repartirErreur(message: 'reserve a la direction'),
        ),
        findsOneWidget,
      );
      expect(plan.repartirs, 0);
    });
  });
}
