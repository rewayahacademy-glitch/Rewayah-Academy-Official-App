import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/schedule_option.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/parcours_offres/bloc_parcours.dart';
import 'package:rewayah_academy/features/parcours_offres/libelles_parcours.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../support/harnais.dart';
import 'faux_service_offres.dart';

final DateTime _fait = DateTime(2026, 9, 20, 10);

List<Override> _avec(FauxServiceOffres faux) => <Override>[
  serviceOffresProvider.overrideWithValue(faux),
];

/// Un apprenant dont les six questions sont repondues.
ParcoursApprenant _personnalise({
  EtatIntention? intention,
  StatutDiagnostic diagnostic = StatutDiagnostic.aPlanifier,
  bool offreIndisponible = false,
  bool fuseauChange = false,
}) => apprenantDeTest(
  cohorte: 'enfant_8_10',
  langue: 'francais',
  onboardingFaitLe: _fait,
  fuseauFoyer: 'Europe/Paris',
  intention: intention,
  diagnostic: diagnostic,
  offreIndisponible: offreIndisponible,
  fuseauChange: fuseauChange,
);

void main() {
  group('etapeParcours, les sept etats et l ordre qui les separe', () {
    test('un profil vide est a personnaliser', () {
      expect(etapeParcours(apprenantDeTest()), EtapeParcours.aPersonnaliser);
    });

    test('un profil rempli sans intention attend un horaire', () {
      expect(etapeParcours(_personnalise()), EtapeParcours.horaireAChoisir);
    });

    test('une intention retiree ramene au choix d horaire', () {
      expect(
        etapeParcours(_personnalise(intention: EtatIntention.retiree)),
        EtapeParcours.horaireAChoisir,
      );
    });

    test('une offre retiree passe DEVANT en formation : ne jamais annoncer un '
        'groupe sur une offre qui n existe plus', () {
      expect(
        etapeParcours(
          _personnalise(
            intention: EtatIntention.enFormation,
            offreIndisponible: true,
          ),
        ),
        EtapeParcours.offreIndisponible,
      );
    });

    test('une intention enregistree renvoie au diagnostic', () {
      expect(
        etapeParcours(_personnalise(intention: EtatIntention.enregistree)),
        EtapeParcours.diagnosticRequis,
      );
    });

    test('un diagnostic planifie se dit en attente', () {
      expect(
        etapeParcours(
          _personnalise(
            intention: EtatIntention.enregistree,
            diagnostic: StatutDiagnostic.planifie,
          ),
        ),
        EtapeParcours.diagnosticEnAttente,
      );
    });

    test('en formation, puis confirme', () {
      expect(
        etapeParcours(_personnalise(intention: EtatIntention.enFormation)),
        EtapeParcours.groupeEnFormation,
      );
      expect(
        etapeParcours(_personnalise(intention: EtatIntention.affectee)),
        EtapeParcours.groupeConfirme,
      );
    });

    test('un onboarding sans date n est pas rempli', () {
      // La date est la preuve que les six questions sont parties ensemble. Sans
      // elle, deux colonnes ecrites suffiraient a faire croire au parcours
      // qu'il est fini.
      expect(
        etapeParcours(
          apprenantDeTest(cohorte: 'enfant_8_10', langue: 'francais'),
        ),
        EtapeParcours.aPersonnaliser,
      );
    });
  });

  group('classerOffres classe, et ne filtre jamais', () {
    final OffreHoraire matin = offreDeTest(
      id: 'matin',
      creneaux: const <CreneauVu>[CreneauVu(jourIso: 2, heure: 9)],
      heureSource: 9,
    );
    final OffreHoraire soir = offreDeTest(
      id: 'soir',
      creneaux: const <CreneauVu>[CreneauVu(jourIso: 2, heure: 19)],
      heureSource: 19,
    );

    test('aucun moment retenu conserve l ordre publie', () {
      expect(
        classerOffres(<OffreHoraire>[
          matin,
          soir,
        ], <MomentJournee>{}).map((OffreHoraire o) => o.id),
        <String>['matin', 'soir'],
      );
    });

    test('le moment retenu remonte l offre, sans retirer les autres', () {
      final List<OffreHoraire> rendues = classerOffres(
        <OffreHoraire>[matin, soir],
        <MomentJournee>{MomentJournee.soir},
      );
      expect(rendues.map((OffreHoraire o) => o.id), <String>['soir', 'matin']);
      // Tout le point de ce classement : l'offre du matin reste visible.
      expect(rendues.length, 2);
    });

    test('une offre a plusieurs creneaux remonte si UN seul convient', () {
      final OffreHoraire mixte = offreDeTest(
        id: 'mixte',
        creneaux: const <CreneauVu>[
          CreneauVu(jourIso: 1, heure: 9),
          CreneauVu(jourIso: 3, heure: 20),
        ],
      );
      expect(
        classerOffres(
          <OffreHoraire>[matin, mixte],
          <MomentJournee>{MomentJournee.soir},
        ).first.id,
        'mixte',
      );
    });
  });

  group('fuseauSuggere suggere, et ne decide pas', () {
    test('le fuseau deja connu du foyer gagne sur l horloge', () {
      expect(
        fuseauSuggere(
          fuseauConnu: 'Africa/Conakry',
          decalageAppareil: const Duration(hours: 2),
        )?.iana,
        'Africa/Conakry',
      );
    });

    test('sans fuseau connu, le plus proche de l horloge', () {
      expect(
        fuseauSuggere(decalageAppareil: const Duration(hours: 1))?.iana,
        'Europe/Paris',
      );
      expect(
        fuseauSuggere(decalageAppareil: const Duration(hours: -5))?.iana,
        'America/Toronto',
      );
    });

    test('au-dela de deux heures d ecart, aucune suggestion', () {
      // Mieux vaut aucune case cochee qu'une case fausse validee sans etre lue.
      expect(fuseauSuggere(decalageAppareil: const Duration(hours: 9)), isNull);
    });

    test('un fuseau connu hors de la liste retombe sur l horloge', () {
      expect(
        fuseauSuggere(
          fuseauConnu: 'Asia/Tokyo',
          decalageAppareil: const Duration(hours: 1),
        )?.iana,
        'Europe/Paris',
      );
    });
  });

  group('les libelles d une offre', () {
    test('les jours se lisent en toutes lettres', () {
      expect(
        libelleJours(const <CreneauVu>[
          CreneauVu(jourIso: 1, heure: 18),
          CreneauVu(jourIso: 6, heure: 18),
        ]),
        'lundi, samedi',
      );
    });

    test('une heure unique quand les creneaux coincident', () {
      expect(
        libelleHeures(const <CreneauVu>[
          CreneauVu(jourIso: 1, heure: 18),
          CreneauVu(jourIso: 3, heure: 18),
        ]),
        '18:00',
      );
    });

    test(
      'deux heures quand un changement d heure decale un jour et pas l autre',
      () {
        expect(
          libelleHeures(const <CreneauVu>[
            CreneauVu(jourIso: 1, heure: 19),
            CreneauVu(jourIso: 3, heure: 20),
          ]),
          '19:00 / 20:00',
        );
      },
    );

    test('une offre sans creneau ne leve pas', () {
      expect(libelleJours(const <CreneauVu>[]), '');
      expect(libelleHeures(const <CreneauVu>[]), '');
    });
  });

  group('la carte vitrine ne promet rien', () {
    testWidgets(
      'elle affiche les horaires, jamais un enseignant ni un compteur',
      (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[_personnalise()],
          offresRendues: <OffreHoraire>[offreDeTest()],
        );

        await tester.pumpWidget(
          hote(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: _avec(faux),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ScheduleOption), findsOneWidget);
        expect(find.text('lundi, mercredi, vendredi'), findsOneWidget);
        expect(find.text('18:00'), findsOneWidget);

        // L'interdiction absolue de la carte publique, verifiee sur les quatre
        // seules chaines que la carte peut rendre. Une recherche de texte sur
        // la page entiere serait trompeuse : la page dit justement, en toutes
        // lettres, qu'elle ne reserve PAS de place.
        final ScheduleOption carte = tester.widget<ScheduleOption>(
          find.byType(ScheduleOption),
        );
        final String rendu = <String?>[
          carte.day,
          carte.hours,
          carte.timeZone,
          carte.recurrence,
        ].whereType<String>().join(' ').toLowerCase();
        for (final String interdit in <String>[
          'professeur',
          'enseignant',
          'inscrit',
          'restante',
          'o1',
          'groupe',
        ]) {
          expect(
            rendu.contains(interdit),
            isFalse,
            reason: 'la carte vitrine ne doit jamais porter « $interdit »',
          );
        }
        // La capacite du groupe est connue du modele, et ne s'affiche pas.
        expect(rendu.contains('5'), isFalse);
      },
    );

    testWidgets(
      'le repli enregistre un signal, et dit d avance ce qu il ne fait pas',
      (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[_personnalise()],
          offresRendues: <OffreHoraire>[offreDeTest()],
        );

        await tester.pumpWidget(
          hote(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: _avec(faux),
          ),
        );
        await tester.pumpAndSettle();

        // La phrase qui borne la promesse est visible AVANT le clic.
        expect(find.text(t.parcours.refusEffet), findsOneWidget);

        await tester.ensureVisible(find.text(t.parcours.refusPrevenir));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.parcours.refusPrevenir));
        await tester.pumpAndSettle();

        expect(faux.signaux.length, 1);
        expect(faux.signaux.single.membreId, 'e1');
        expect(find.text(t.parcours.refusEnregistre), findsOneWidget);
        // Le signal ne cree aucune intention.
        expect(faux.choix, isEmpty);
      },
    );

    testWidgets('aucune offre compatible mene au repli, pas a un ecran vide', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[_personnalise()],
      );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.parcours.aucuneOffre), findsOneWidget);
      expect(find.text(t.parcours.refusPrevenir), findsOneWidget);
      expect(find.byType(ScheduleOption), findsNothing);
    });

    testWidgets('choisir un horaire enregistre une PREFERENCE', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[_personnalise()],
        offresRendues: <OffreHoraire>[offreDeTest()],
      );

      await tester.pumpWidget(
        hoteRoutant(
          depart: '/p',
          surcharges: _avec(faux),
          routes: <RouteBase>[
            GoRoute(
              path: '/p',
              builder: (BuildContext _, GoRouterState _) =>
                  const ParcoursOffresPage(eleveId: 'e1'),
            ),
            GoRoute(
              path: '/tuteur',
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('accueil')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ScheduleOption));
      await tester.pumpAndSettle();

      expect(faux.choix.length, 1);
      expect(faux.choix.single.offreId, 'o1');
      expect(faux.choix.single.fuseau, 'Europe/Paris');
      // Aucun renoncement : il n'y avait pas de preference vivante.
      expect(faux.renoncements, isEmpty);
      // La fin d'admission dit ce qui est enregistre, puis propose la suite.
      expect(find.text(t.parcours.finAjouterProfil), findsOneWidget);
      await tester.tap(find.text(t.parcours.retourAccueil));
      await tester.pumpAndSettle();
      expect(find.text('accueil'), findsOneWidget);
    });

    testWidgets('changer d horaire renonce d abord a la preference vivante', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[
          apprenantDeTest(
            cohorte: 'enfant_8_10',
            langue: 'francais',
            onboardingFaitLe: _fait,
            fuseauFoyer: 'Europe/Paris',
            intention: EtatIntention.enregistree,
            offreId: 'ancienne',
          ),
        ],
        offresRendues: <OffreHoraire>[offreDeTest()],
      );

      await tester.pumpWidget(
        hoteRoutant(
          depart: '/p',
          surcharges: _avec(faux),
          routes: <RouteBase>[
            GoRoute(
              path: '/p',
              builder: (BuildContext _, GoRouterState _) =>
                  const ParcoursOffresPage(eleveId: 'e1'),
            ),
            GoRoute(
              path: '/tuteur/foyer/ajouter',
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('ajouter')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ScheduleOption));
      await tester.pumpAndSettle();

      expect(faux.renoncements.single.membreId, 'e1');
      expect(faux.choix.single.offreId, 'o1');
      // Enchainement vers l'ajout d'un profil eleve, par la route seule.
      await tester.tap(find.text(t.parcours.finAjouterProfil));
      await tester.pumpAndSettle();
      expect(find.text('ajouter'), findsOneWidget);
    });

    testWidgets('backend du parcours absent : indisponible honnete', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres()
        ..erreurParcours = const PostgrestException(
          message: 'relation absente',
          code: 'PGRST205',
        );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.parcours.indisponibleTitre), findsOneWidget);
      expect(find.text(t.parcours.erreur), findsNothing);
    });
  });

  group('le bloc de l accueil dit la verite, ou se tait', () {
    Future<void> monter(
      WidgetTester tester,
      List<ParcoursApprenant> foyer,
    ) async {
      await tester.pumpWidget(
        hote(
          const Scaffold(body: SingleChildScrollView(child: BlocParcours())),
          surcharges: _avec(FauxServiceOffres(parcoursRendu: foyer)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sans 0043 il dit que le questionnaire n est pas ouvert (K5)', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres()
        ..erreurParcours = const PostgrestException(
          message: 'relation does not exist',
          code: '42P01',
        );
      await tester.pumpWidget(
        hote(
          const Scaffold(body: SingleChildScrollView(child: BlocParcours())),
          surcharges: _avec(faux),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bloc-parcours-indisponible')),
        findsOneWidget,
      );
      expect(find.text(t.parcours.indisponibleTitre), findsOneWidget);
      expect(find.text(t.parcours.indisponibleDetail), findsOneWidget);
    });

    testWidgets('une autre erreur reste silencieuse', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres()
        ..erreurParcours = const PostgrestException(message: 'x', code: '500');
      await tester.pumpWidget(
        hote(
          const Scaffold(body: SingleChildScrollView(child: BlocParcours())),
          surcharges: _avec(faux),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bloc-parcours-indisponible')), findsNothing);
      expect(find.text(t.parcours.indisponibleTitre), findsNothing);
    });

    testWidgets('il se tait quand tout le foyer a son groupe', (
      WidgetTester tester,
    ) async {
      await monter(tester, <ParcoursApprenant>[
        _personnalise(intention: EtatIntention.affectee),
      ]);
      expect(find.text(t.parcours.etatClasseConfirmee), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('en formation annonce le minimum, jamais une place reservee', (
      WidgetTester tester,
    ) async {
      await monter(tester, <ParcoursApprenant>[
        _personnalise(intention: EtatIntention.enFormation),
      ]);

      expect(find.text(t.parcours.etatClasseEnFormation), findsOneWidget);
      // Le minimum vient des regles serveur, pas d'une constante d'ecran.
      expect(
        find.text(t.parcours.etatClasseEnFormationDetail(minimum: 3)),
        findsOneWidget,
      );
      expect(find.textContaining('réserv'), findsNothing);
      // Aucune action : cet etat depend de l'academie, pas de la famille.
      expect(find.text(t.parcours.voirHoraires), findsNothing);
    });

    testWidgets('un fuseau change est dit, jamais taise', (
      WidgetTester tester,
    ) async {
      await monter(tester, <ParcoursApprenant>[
        _personnalise(intention: EtatIntention.enFormation, fuseauChange: true),
      ]);
      expect(find.text(t.parcours.fuseauChangeDetail), findsOneWidget);
    });

    testWidgets('une offre retiree propose de changer d horaire', (
      WidgetTester tester,
    ) async {
      await monter(tester, <ParcoursApprenant>[
        _personnalise(
          intention: EtatIntention.enFormation,
          offreIndisponible: true,
        ),
      ]);
      expect(find.text(t.parcours.etatOffreIndisponible), findsOneWidget);
      expect(find.text(t.parcours.changerHoraire), findsOneWidget);
    });

    testWidgets('une lecture en echec ne dit rien plutot que de mentir', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres()
        ..erreurParcours = Exception('reseau');
      await tester.pumpWidget(
        hote(const Scaffold(body: BlocParcours()), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();
      // Surtout pas « parcours a personnaliser » : une famille deja inscrite
      // croirait qu'il lui manque quelque chose.
      expect(find.text(t.parcours.etatAPersonnaliser), findsNothing);
    });
  });

  group('le parcours ne demande jamais d horaire sur mesure', () {
    testWidgets('aucun champ de saisie, aucune carte Autre', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
      );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.parcours.ageQuestion(prenom: 'Amina')),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text(t.choix.autre), findsNothing);
    });

    testWidgets('les six reponses partent ENSEMBLE, jamais a moitie', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
      );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      Future<void> repondre(String libelle) async {
        await tester.tap(find.text(libelle));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.commun.continuer));
        await tester.pumpAndSettle();
      }

      // La fiche n'a pas encore de tranche : l'age revient, en annees, et la
      // tranche envoyee en decoule.
      await tester.tap(find.byKey(ParcoursOffresPage.ageChoixKey(9)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.continuer));
      await tester.pumpAndSettle();
      expect(faux.profilsEnregistres, isEmpty);
      await repondre('Français');
      await repondre('France, Belgique, Espagne');
      await repondre(libelleNiveau(NiveauDeclare.debutLettres));
      // Aucune branche cote client : l'objectif est demande aussi au
      // debutant (REVUE LA-F, branches serveur seulement).
      expect(find.text(t.parcours.objectifQuestion), findsOneWidget);
      await repondre(libelleObjectif(ObjectifApprentissage.apprendreALire));
      // Rien n'est parti avant la derniere question.
      expect(faux.profilsEnregistres, isEmpty);

      await tester.tap(find.text(t.commun.continuer));
      await tester.pumpAndSettle();

      expect(faux.profilsEnregistres.length, 1);
      expect(faux.profilsEnregistres.single.cohorteCode, 'enfant_8_10');
      expect(faux.profilsEnregistres.single.langueCode, 'francais');
      expect(faux.profilsEnregistres.single.fuseau, 'Europe/Paris');
      expect(faux.profilsEnregistres.single.niveau, NiveauDeclare.debutLettres);
      expect(
        faux.profilsEnregistres.single.objectif,
        ObjectifApprentissage.apprendreALire,
      );
    });

    testWidgets('la langue du cours n est pas celle de l interface', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
      );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ParcoursOffresPage.ageChoixKey(9)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.continuer));
      await tester.pumpAndSettle();

      // Le poular est une langue d'ENSEIGNEMENT (ADR-029), meme si ADR-015 l'a
      // retire des locales de l'application. Son nom vient du serveur et n'est
      // jamais traduit.
      expect(find.text('Pulaar'), findsOneWidget);
      expect(find.textContaining(t.parcours.langueRaison), findsOneWidget);
      // Le prenom de l'eleve reste en contexte.
      expect(
        find.textContaining(t.parcours.pourPrenom(prenom: 'Amina')),
        findsOneWidget,
      );
    });

    testWidgets(
      'un foyer deja personnalise ne repond pas deux fois aux six questions',
      (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[_personnalise()],
          offresRendues: <OffreHoraire>[offreDeTest()],
        );

        await tester.pumpWidget(
          hote(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: _avec(faux),
          ),
        );
        await tester.pumpAndSettle();

        // On ouvre directement sur les horaires : ne jamais redemander ce que
        // l'on sait deja.
        expect(find.byType(ScheduleOption), findsOneWidget);
        expect(
          find.text(t.parcours.ageQuestion(prenom: 'Amina')),
          findsNothing,
        );
      },
    );
  });

  group(
    'le parcours s atteint par un geste depuis l accueil, pas par go()',
    () {
      testWidgets(
        'taper l action du bloc de l accueil ouvre le parcours de cet eleve',
        (WidgetTester tester) async {
          final FauxServiceOffres faux = FauxServiceOffres(
            parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
          );

          await tester.pumpWidget(
            hoteRoutant(
              depart: Routes.tuteurAccueil,
              surcharges: _avec(faux),
              routes: <RouteBase>[
                GoRoute(
                  path: Routes.tuteurAccueil,
                  builder: (BuildContext _, GoRouterState _) => const Scaffold(
                    body: SingleChildScrollView(child: BlocParcours()),
                  ),
                ),
                GoRoute(
                  path: '${Routes.tuteurParcours}/:eleveId',
                  builder: (BuildContext _, GoRouterState etat) =>
                      ParcoursOffresPage(
                        eleveId: etat.pathParameters['eleveId'] ?? '',
                      ),
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();

          // Le geste part du bloc de l'accueil, pas d'un `routeur.go()` ecrit
          // par le test : c'est le bouton que la famille voit et touche.
          expect(find.text(t.parcours.commencer), findsOneWidget);
          await tester.ensureVisible(find.text(t.parcours.commencer));
          await tester.tap(find.text(t.parcours.commencer));
          await tester.pumpAndSettle();

          expect(
            find.text(t.parcours.ageQuestion(prenom: 'Amina')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'un foyer avec horaire a choisir ouvre directement les horaires',
        (WidgetTester tester) async {
          final FauxServiceOffres faux = FauxServiceOffres(
            parcoursRendu: <ParcoursApprenant>[_personnalise()],
            offresRendues: <OffreHoraire>[offreDeTest()],
          );

          await tester.pumpWidget(
            hoteRoutant(
              depart: Routes.tuteurAccueil,
              surcharges: _avec(faux),
              routes: <RouteBase>[
                GoRoute(
                  path: Routes.tuteurAccueil,
                  builder: (BuildContext _, GoRouterState _) => const Scaffold(
                    body: SingleChildScrollView(child: BlocParcours()),
                  ),
                ),
                GoRoute(
                  path: '${Routes.tuteurParcours}/:eleveId',
                  builder: (BuildContext _, GoRouterState etat) =>
                      ParcoursOffresPage(
                        eleveId: etat.pathParameters['eleveId'] ?? '',
                      ),
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.text(t.parcours.voirHoraires));
          await tester.tap(find.text(t.parcours.voirHoraires));
          await tester.pumpAndSettle();

          expect(find.byType(ScheduleOption), findsOneWidget);
        },
      );
    },
  );

  group('les etats de lecture du parcours', () {
    testWidgets(
      'pendant le chargement, un squelette, jamais une question a moitie',
      (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
        )..attenteParcours = Completer<void>();

        await tester.pumpWidget(
          hote(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: _avec(faux),
          ),
        );
        // Un seul pump : la lecture n'a pas encore abouti.
        await tester.pump();

        expect(find.byType(Skeleton), findsWidgets);
        expect(
          find.text(t.parcours.ageQuestion(prenom: 'Amina')),
          findsNothing,
        );

        faux.attenteParcours!.complete();
        await tester.pumpAndSettle();

        expect(
          find.text(t.parcours.ageQuestion(prenom: 'Amina')),
          findsOneWidget,
        );
      },
    );

    testWidgets('hors ligne : etat hors ligne honnete, avec Reessayer', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres()
        ..erreurParcours = Exception(
          'SocketException: Failed host lookup: supabase.co',
        );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.parcours.horsLigneTitre), findsOneWidget);
      expect(find.text(t.parcours.reessayer), findsOneWidget);
      // Ce n'est PAS l'etat "backend absent" : ce sont deux pannes distinctes.
      expect(find.text(t.parcours.indisponibleTitre), findsNothing);

      faux.erreurParcours = null;
      await tester.tap(find.text(t.parcours.reessayer));
      await tester.pumpAndSettle();

      expect(find.text(t.parcours.introuvableTitre), findsOneWidget);
    });

    testWidgets('une erreur ordinaire propose aussi de reessayer', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres()
        ..erreurParcours = Exception('boom');

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.parcours.erreurChargement), findsOneWidget);
      expect(find.text(t.parcours.reessayer), findsOneWidget);
    });
  });

  group('les regles dures du parcours', () {
    testWidgets('aucun age n est preselectionne au depart', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
      );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      // Sans choix, Continuer n'avance pas : la question reste affichee.
      await tester.tap(find.text(t.commun.continuer));
      await tester.pumpAndSettle();
      expect(
        find.text(t.parcours.ageQuestion(prenom: 'Amina')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ParcoursOffresPage.ageChoixKey(9)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.continuer));
      await tester.pumpAndSettle();

      // Un choix fait, Continuer avance bien : la question n'etait donc
      // desactivee que par l'absence de reponse.
      expect(find.text(t.parcours.langueQuestion), findsOneWidget);
    });

    testWidgets(
      'choisir un horaire deux fois de suite n enregistre qu UN choix',
      (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[_personnalise()],
          offresRendues: <OffreHoraire>[offreDeTest()],
        )..attenteEcriture = Completer<void>();

        await tester.pumpWidget(
          hote(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: _avec(faux),
          ),
        );
        await tester.pumpAndSettle();

        // Le premier geste part, mais son ecriture reste en attente : la carte
        // doit se desactiver des ce moment (`enCours`/`enabled`), avant meme
        // que le serveur ne reponde.
        await tester.tap(find.byType(ScheduleOption));
        await tester.pump();

        final ScheduleOption carte = tester.widget<ScheduleOption>(
          find.byType(ScheduleOption),
        );
        expect(carte.enabled, isFalse);

        // Un second tap pendant cette fenetre n'a donc aucune prise.
        await tester.tap(find.byType(ScheduleOption), warnIfMissed: false);
        await tester.pump();

        faux.attenteEcriture!.complete();
        await tester.pumpAndSettle();

        expect(faux.choix.length, 1);
      },
    );

    testWidgets(
      'signaler un refus deux fois de suite n enregistre qu UN signal',
      (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[_personnalise()],
        )..attenteEcriture = Completer<void>();

        await tester.pumpWidget(
          hote(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: _avec(faux),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(t.parcours.refusPrevenir));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.parcours.refusPrevenir));
        await tester.pump();
        // L'ecriture n'a pas encore abouti : un second tap ne doit rien faire.
        await tester.tap(
          find.text(t.parcours.refusPrevenir),
          warnIfMissed: false,
        );
        await tester.pump();

        faux.attenteEcriture!.complete();
        await tester.pumpAndSettle();

        expect(faux.signaux.length, 1);
      },
    );
  });

  group('l age n est demande qu une fois, en annees', () {
    test('la tranche se deduit de l age, jamais par devinette', () {
      const List<CohorteAge> tranches = <CohorteAge>[
        CohorteAge(
          code: 'enfant_6_9',
          nom: '6 à 9 ans',
          typePublic: PublicOffre.enfants,
        ),
        CohorteAge(
          code: 'enfant_10_13',
          nom: '10 à 13 ans',
          typePublic: PublicOffre.enfants,
        ),
        CohorteAge(
          code: 'adulte_18_plus',
          nom: '18 ans et plus',
          typePublic: PublicOffre.adultes,
        ),
        CohorteAge(
          code: 'speciale',
          nom: 'Classe spéciale',
          typePublic: PublicOffre.enfants,
        ),
      ];
      expect(cohortePourAge(6, tranches), 'enfant_6_9');
      expect(cohortePourAge(9, tranches), 'enfant_6_9');
      expect(cohortePourAge(10, tranches), 'enfant_10_13');
      expect(cohortePourAge(18, tranches), 'adulte_18_plus');
      expect(cohortePourAge(40, tranches), 'adulte_18_plus');
      // 14 a 17 ans : aucune tranche rendue ne les couvre.
      expect(cohortePourAge(15, tranches), isNull);
    });

    testWidgets(
      'tranche connue du serveur : le parcours commence a la langue',
      (WidgetTester tester) async {
        final FauxServiceOffres faux = FauxServiceOffres(
          parcoursRendu: <ParcoursApprenant>[
            apprenantDeTest(cohorte: 'enfant_8_10'),
          ],
        );

        await tester.pumpWidget(
          hote(
            const ParcoursOffresPage(eleveId: 'e1'),
            surcharges: _avec(faux),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(t.parcours.langueQuestion), findsOneWidget);
        expect(
          find.text(t.parcours.ageQuestion(prenom: 'Amina')),
          findsNothing,
        );
        expect(find.byKey(ParcoursOffresPage.ageKey), findsNothing);
      },
    );

    testWidgets('au repli, l age se choisit en annees, comme au profil', (
      WidgetTester tester,
    ) async {
      final FauxServiceOffres faux = FauxServiceOffres(
        parcoursRendu: <ParcoursApprenant>[apprenantDeTest()],
      );

      await tester.pumpWidget(
        hote(const ParcoursOffresPage(eleveId: 'e1'), surcharges: _avec(faux)),
      );
      await tester.pumpAndSettle();

      // Meme titre qu'a l'ajout du profil, aucune tranche proposee.
      expect(find.text(t.foyer.ajout.identite.age), findsOneWidget);
      expect(find.text('8 à 10 ans'), findsNothing);
      expect(find.byKey(ParcoursOffresPage.ageChoixKey(6)), findsOneWidget);
      expect(find.byKey(ParcoursOffresPage.ageChoixKey(18)), findsOneWidget);

      // 6 ans : aucune tranche rendue ne le couvre. Le parcours le dit et
      // n'avance pas.
      await tester.tap(find.byKey(ParcoursOffresPage.ageChoixKey(6)));
      await tester.pumpAndSettle();
      expect(find.text(t.parcours.ageSansTranche), findsOneWidget);
      await tester.tap(find.text(t.commun.continuer));
      await tester.pumpAndSettle();
      expect(find.text(t.parcours.langueQuestion), findsNothing);

      await tester.tap(find.byKey(ParcoursOffresPage.ageChoixKey(18)));
      await tester.pumpAndSettle();
      expect(find.text(t.parcours.ageSansTranche), findsNothing);
      await tester.tap(find.text(t.commun.continuer));
      await tester.pumpAndSettle();
      expect(find.text(t.parcours.langueQuestion), findsOneWidget);
    });
  });
}
