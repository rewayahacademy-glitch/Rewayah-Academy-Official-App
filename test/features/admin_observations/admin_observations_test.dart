// Consultation admin des observations (lot E, sous-paquet 3), sur le VRAI
// routeur et une session d'administration : l'ecran s'atteint en TOUCHANT
// l'onglet « Observations » du Journal (Securite et audit), et la barre
// laterale y ramene. Donnees : doubles isoles, aucun Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/historique_observations_admin_supabase.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_journal/journal_page.dart';
import 'package:rewayah_academy/features/admin_observations/annuaire_observations.dart';
import 'package:rewayah_academy/features/admin_observations/observations_admin_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/composants_historique.dart';

import '../../fixtures/tuteur/faux_observation.dart';
import '../../router/support_routeur.dart';
import 'support_admin_observations.dart';

Finder get _champ => find.descendant(
  of: find.byType(RechercheObservations),
  matching: find.byType(TextField),
);

Finder _visite(String id) => find.byKey(ValueKey<String>('visite-$id'));

Future<void> _choisir(WidgetTester tester, String axe, String entree) async {
  await tester.tap(find.text(axe).first);
  await stabiliser(tester);
  await tester.tap(find.text(entree).last);
  await stabiliser(tester);
}

void main() {
  group('Consultation admin des observations : acces', () {
    for (final Size taille in <Size>[
      const Size(1440, 900),
      const Size(390, 844),
    ]) {
      testWidgets('l onglet Observations du Journal est TOUCHE ; production : '
          'indisponible, rien d autre lu (${taille.width.toInt()})', (
        WidgetTester tester,
      ) async {
        final FauxAnnuaire annuaire = FauxAnnuaire();
        final GoRouter routeur = await monterAdmin(
          tester,
          Routes.adminSecuriteAuditJournal,
          taille: taille,
          annuaire: annuaire,
        );
        expect(find.byType(JournalPage), findsOneWidget);
        expect(find.widgetWithText(Tab, t.admin.journal.titre), findsOneWidget);

        await toucherOnglet(tester, t.admin.observations.titre);

        expect(lieu(routeur), Routes.adminSecuriteAuditObservations);
        expect(find.byType(ObservationsAdminPage), findsOneWidget);
        expect(find.text(t.admin.observations.titrePage), findsOneWidget);
        final EtatSysteme etat = tester.widget<EtatSysteme>(
          find.byType(EtatSysteme),
        );
        expect(etat.nature, NatureEtat.indisponible);
        expect(
          find.text(t.admin.observations.indisponibleTitre),
          findsOneWidget,
        );
        expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
        // Ni recherche, ni filtres, ni annuaire tant que rien n'est lisible.
        expect(find.text(t.admin.observations.recherche), findsNothing);
        expect(annuaire.recherches, isEmpty);

        // Retour au Journal par l'onglet pair.
        await toucherOnglet(tester, t.admin.journal.titre);
        expect(lieu(routeur), Routes.adminSecuriteAuditJournal);
        expect(find.byType(JournalPage), findsOneWidget);
      });
    }

    testWidgets('la barre laterale ramene de l historique au Journal', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterAdmin(
        tester,
        Routes.adminSecuriteAuditJournal,
        port: FauxHistoriqueObservationsAdmin(),
      );
      await toucherOnglet(tester, t.admin.observations.titre);
      expect(find.byType(ObservationsAdminPage), findsOneWidget);
      await tester.tap(find.text(t.nav.admin.securite).first);
      await stabiliser(tester);
      expect(lieu(routeur), Routes.adminSecuriteAuditJournal);
    });
  });

  group('Consultation admin des observations : contenu (simulation)', () {
    testWidgets('1440 : tableau de D3, « Fin » devenue « Statut », aucun motif '
        'de fin, aucune action', (WidgetTester tester) async {
      await monterAdmin(
        tester,
        Routes.adminSecuriteAuditJournal,
        port: FauxHistoriqueObservationsAdmin(),
      );
      await toucherOnglet(tester, t.admin.observations.titre);

      expect(find.byType(DataCollection<VisiteAdmin>), findsOneWidget);
      for (final String colonne in <String>[
        t.admin.observations.colonneDate,
        t.admin.observations.colonneTuteur,
        t.admin.observations.colonneEleve,
        t.admin.observations.colonneClasse,
        t.admin.observations.colonneEntree,
        t.admin.observations.colonneSortie,
        t.admin.observations.colonneDuree,
      ]) {
        expect(find.text(colonne), findsWidgets, reason: colonne);
      }
      expect(find.text('Fin'), findsNothing);
      expect(find.text('Limite atteinte'), findsNothing);
      expect(find.text('Départ volontaire'), findsNothing);
      // Ordre : 23/09 visite 1, visite 2, puis 21/09.
      expect(
        tester.getTopLeft(_visite('v1')).dy,
        lessThan(tester.getTopLeft(_visite('v2')).dy),
      );
      expect(
        tester.getTopLeft(_visite('v2')).dy,
        lessThan(tester.getTopLeft(_visite('v3')).dy),
      );
      expect(find.text('Fatoumata Diallo'), findsNWidgets(3));
      expect(find.text('An-Nour'), findsNWidgets(3));
      expect(find.text('23/09/2026'), findsNWidgets(2));
      expect(find.text('18:12:00'), findsOneWidget);
      expect(find.text('18:14:00'), findsOneWidget);
      expect(find.text('1 min 42 s'), findsOneWidget);
      // Visite sans sortie : ni sortie ni duree inventees.
      expect(find.text(t.admin.observations.sortieAbsente), findsOneWidget);
      expect(find.text(t.admin.observations.dureeNonConfirmee), findsOneWidget);
      expect(find.text(t.admin.observations.ouverte), findsWidgets);
      expect(find.textContaining('UTC'), findsOneWidget);
      expect(find.text(t.admin.observations.fin), findsOneWidget);
      // Lecture seule : aucune action principale.
      for (final ActionPrincipale b in tester.widgetList<ActionPrincipale>(
        find.byType(ActionPrincipale),
      )) {
        expect(b.niveau, isNot(NiveauAction.principale));
      }
    });

    testWidgets('390 : UNE carte a filets, pas de tableau', (
      WidgetTester tester,
    ) async {
      await monterAdmin(
        tester,
        Routes.adminSecuriteAuditJournal,
        taille: const Size(390, 844),
        port: FauxHistoriqueObservationsAdmin(),
      );
      await toucherOnglet(tester, t.admin.observations.titre);
      expect(find.byType(DataCollection<VisiteAdmin>), findsNothing);
      expect(find.byType(CarteLignes), findsOneWidget);
      expect(_visite('v1'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(CarteLignes), matching: _visite('v3')),
        findsOneWidget,
      );
      expect(find.text(t.admin.observations.colonneEntree), findsNothing);
    });

    testWidgets('filtres TOUCHES : statut, periode, classe relisent depuis le '
        'debut', (WidgetTester tester) async {
      final FauxHistoriqueObservationsAdmin port =
          FauxHistoriqueObservationsAdmin();
      await monterAdmin(tester, Routes.adminSecuriteAuditJournal, port: port);
      await toucherOnglet(tester, t.admin.observations.titre);

      await _choisir(
        tester,
        t.admin.observations.statut,
        t.admin.observations.ouverte,
      );
      expect(port.recherches.last.$1.seulementOuvertes, isTrue);
      expect(port.recherches.last.$2, isNull);

      await _choisir(
        tester,
        t.admin.observations.periode,
        t.historique.filtres.septJours,
      );
      expect(port.recherches.last.$1.periode, isNotNull);
      expect(port.recherches.last.$1.seulementOuvertes, isTrue);

      await _choisir(tester, t.admin.observations.classe, 'Al-Huda');
      expect(port.recherches.last.$1.groupeId, 'classe-al-huda');
    });

    testWidgets('recherche TOUCHEE : choisir un tuteur pose le filtre ; la '
        'pastille le retire', (WidgetTester tester) async {
      final FauxHistoriqueObservationsAdmin port =
          FauxHistoriqueObservationsAdmin();
      final FauxAnnuaire annuaire = FauxAnnuaire();
      await monterAdmin(
        tester,
        Routes.adminSecuriteAuditJournal,
        port: port,
        annuaire: annuaire,
      );
      await toucherOnglet(tester, t.admin.observations.titre);

      await tester.enterText(_champ, 'F');
      await stabiliser(tester);
      expect(annuaire.recherches, isEmpty, reason: 'deux lettres au moins');

      await tester.enterText(_champ, 'Fatou');
      await stabiliser(tester);
      expect(annuaire.recherches, contains('Fatou'));
      await tester.tap(
        find.byKey(const ValueKey<String>('personne-tuteur-fatoumata')),
      );
      await stabiliser(tester);

      expect(port.recherches.last.$1.tuteurId, 'tuteur-fatoumata');
      final Finder pastille = find.text(
        t.admin.observations.filtreTuteur(nom: 'Fatoumata Diallo'),
      );
      expect(pastille, findsOneWidget);

      await tester.tap(pastille);
      await stabiliser(tester);
      expect(port.recherches.last.$1.tuteurId, isNull);
      expect(pastille, findsNothing);
    });

    testWidgets('pagination TOUCHEE : la suite porte le curseur', (
      WidgetTester tester,
    ) async {
      final FauxHistoriqueObservationsAdmin port =
          FauxHistoriqueObservationsAdmin(
            pages: <List<Map<String, dynamic>>>[
              visitesD3(),
              <Map<String, dynamic>>[
                visiteAdmin(id: 'v9', entree: DateTime(2026, 9, 14, 18, 5)),
              ],
            ],
          );
      await monterAdmin(tester, Routes.adminSecuriteAuditJournal, port: port);
      await toucherOnglet(tester, t.admin.observations.titre);
      final Finder suite = find.text(t.admin.observations.chargerSuite);
      await tester.ensureVisible(suite);
      await stabiliser(tester);
      await tester.tap(suite);
      await stabiliser(tester);
      expect(port.recherches.last.$2, '1');
      expect(_visite('v9'), findsOneWidget);
      expect(find.text(t.admin.observations.fin), findsOneWidget);
    });

    testWidgets('vide sans filtre, vide sous filtre avec sortie', (
      WidgetTester tester,
    ) async {
      final FauxHistoriqueObservationsAdmin port =
          FauxHistoriqueObservationsAdmin(
            pages: <List<Map<String, dynamic>>>[visitesD3()],
          );
      await monterAdmin(tester, Routes.adminSecuriteAuditJournal, port: port);
      await toucherOnglet(tester, t.admin.observations.titre);
      port.pages = <List<Map<String, dynamic>>>[<Map<String, dynamic>>[]];
      await _choisir(
        tester,
        t.admin.observations.statut,
        t.admin.observations.ouverte,
      );
      expect(find.text(t.admin.observations.videFiltreTitre), findsOneWidget);
      await tester.tap(find.text(t.admin.observations.effacerFiltres));
      await stabiliser(tester);
      expect(port.recherches.last.$1.seulementOuvertes, isFalse);
      expect(find.text(t.admin.observations.videTitre), findsOneWidget);
    });

    testWidgets('echec : Reessayer relit', (WidgetTester tester) async {
      final FauxHistoriqueObservationsAdmin port =
          FauxHistoriqueObservationsAdmin(erreur: Exception('refus'));
      await monterAdmin(tester, Routes.adminSecuriteAuditJournal, port: port);
      await toucherOnglet(tester, t.admin.observations.titre);
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);
      port.erreur = null;
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await stabiliser(tester);
      expect(_visite('v1'), findsOneWidget);
    });

    testWidgets('chargement : la forme de la liste', (
      WidgetTester tester,
    ) async {
      await monterAdmin(
        tester,
        Routes.adminSecuriteAuditJournal,
        port: FauxHistoriqueObservationsAdmin(
          delai: const Duration(seconds: 2),
        ),
      );
      await toucherOnglet(tester, t.admin.observations.titre);
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      await stabiliser(tester);
      expect(_visite('v1'), findsOneWidget);
    });

    testWidgets('annuaire illisible : « Nom non disponible », les visites '
        'restent', (WidgetTester tester) async {
      await monterAdmin(
        tester,
        Routes.adminSecuriteAuditJournal,
        port: FauxHistoriqueObservationsAdmin(),
        annuaire: FauxAnnuaire(enPanne: true),
      );
      await toucherOnglet(tester, t.admin.observations.titre);
      expect(_visite('v1'), findsOneWidget);
      expect(find.text(t.admin.observations.nomInconnu), findsWidgets);
      expect(find.text(t.admin.observations.classeInconnue), findsWidgets);
    });

    testWidgets('hors ligne : le bandeau le dit', (WidgetTester tester) async {
      await monterAdmin(
        tester,
        Routes.adminSecuriteAuditJournal,
        port: FauxHistoriqueObservationsAdmin(),
        horsLigne: true,
      );
      await toucherOnglet(tester, t.admin.observations.titre);
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
    });
  });

  group('Consultation admin : fonctions pures', () {
    test('deux responsables du meme eleve a la meme seance : deux groupes', () {
      final List<ObservationsSeance> g = grouperParObservateur(
        <Map<String, dynamic>>[
          visiteAdmin(id: 'a', entree: DateTime(2026, 9, 23, 18)),
          visiteAdmin(
            id: 'b',
            observateur: 'tuteur-2',
            entree: DateTime(2026, 9, 23, 18, 5),
          ),
        ],
      );
      expect(g, hasLength(2));
      expect(g.first.visites.single.id, 'b');
    });

    test('le curseur se relit et refuse ce qui n est pas un uuid', () {
      final CurseurVisites? c = CurseurVisites.apres(
        visiteAdmin(
          id: '0b6f7c1e-1111-4222-8333-944455556666',
          entree: DateTime.utc(2026, 9, 23, 16, 12),
        ),
      );
      expect(c, isNotNull);
      final CurseurVisites? relu = CurseurVisites.lire(c!.ecrire());
      expect(relu!.id, c.id);
      expect(relu.entree, c.entree);
      expect(relu.filtre, contains('entered_at.lt."2026-09-23T16:12:00.000Z"'));
      expect(CurseurVisites.lire('2026-09-23T16:12:00Z|x),or(id.gt.0'), isNull);
      expect(CurseurVisites.lire(null), isNull);
    });

    test('la recherche ne laisse passer aucun caractere de filtre', () {
      expect(motifRecherche('Fatou,(ma).*"'), 'Fatouma');
      expect(motifRecherche("N'Diaye-Ba"), "N'Diaye-Ba");
    });

    test('le Journal nomme les evenements d observation', () {
      expect(
        libelleEvenement('observation_entree'),
        t.admin.journal.evenements.observationEntree,
      );
      expect(
        libelleEvenement('observation_sortie'),
        t.admin.journal.evenements.observationSortie,
      );
      expect(
        libelleEvenement('observation_politique_groupe_modifiee'),
        t.admin.journal.evenements.observationPolitiqueGroupeModifiee,
      );
    });

    test('le port de production est indisponible', () {
      expect(
        const HistoriqueObservationsAdminIndisponible().rechercher(
          const FiltreObservationsAdmin(),
        ),
        throwsA(anything),
      );
    });

    test('le double de test groupe comme l adaptateur', () {
      expect(
        grouperParObservateur(<Map<String, dynamic>>[ligneVisite()]),
        hasLength(1),
      );
    });
  });
}
