// Historique du tuteur (lot E, sous-paquet 2) : Seances, Observations, detail
// de seance, detail des observations. Chaque parcours est TOUCHE depuis la
// barre de navigation, sur le vrai routeur (definition de « fait », registre
// section 5 bis), a 390 et a 1440 ; etats chargement, vide, erreur, hors
// ligne, indisponible, introuvable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/suivi_foyer/composants_historique.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_observations_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_seance_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/observations_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../../fixtures/tuteur/faux_observation.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import 'support_historique.dart';

Finder _ligne(String seanceId, {String eleve = 'foyer-a-eleve-1'}) =>
    find.byKey(ValueKey<String>('seance-$seanceId-$eleve'));

Finder _ligneObs(String seanceId, {String eleve = 'foyer-a-eleve-1'}) =>
    find.byKey(ValueKey<String>('observation-$seanceId-$eleve'));

Finder _dans(Finder parent, String texte) =>
    find.descendant(of: parent, matching: find.text(texte));

Finder _menu(String axe) =>
    find.byWidgetPredicate((Widget w) => w is MenuFiltre && w.libelle == axe);

Finder _segment(String libelle) => find.descendant(
  of: find.byWidgetPredicate((Widget w) => w is ControleSegmente),
  matching: find.text(libelle),
);

Finder _profil(String prenom) => find.descendant(
  of: find.byType(SelecteurProfils),
  matching: find.text(prenom),
);

Future<void> _filtrer(WidgetTester tester, String axe, String entree) async {
  await toucher(tester, _menu(axe));
  await tester.tap(find.text(entree).last);
  await stabiliser(tester);
}

int _indexActif(WidgetTester tester) =>
    tester.widget<NavShell>(find.byType(NavShell)).indexActif ?? -1;

String get _sayyidX => LibellesGroupe.enseignantNomme(classeA.enseignant);

void main() {
  group('Seances : atteintes depuis la barre, composition V8 D2', () {
    testWidgets('la destination Historique ouvre les seances passees de '
        'l eleve retenu, statuts apres la seance', (WidgetTester tester) async {
      final GoRouter routeur = await monterHistorique(tester);
      await toucherDestination(tester, t.nav.tuteur.historique);

      expect(lieu(routeur), Routes.tuteurSuivi);
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      expect(_indexActif(tester), 2);
      expect(find.text(t.historique.titre), findsWidgets);
      // Selecteur K1, segment, filtres : l'ordre de la maquette.
      final double ySelecteur = tester
          .getTopLeft(find.byType(SelecteurProfils))
          .dy;
      final double ySegment = tester.getTopLeft(_segment('Séances')).dy;
      final double yFiltres = tester
          .getTopLeft(_menu(t.historique.filtres.periode))
          .dy;
      expect(ySelecteur, lessThan(ySegment));
      expect(ySegment, lessThan(yFiltres));
      // « Ajouter » n'est pas rendu : sa place est le Foyer.
      expect(find.text(t.commun.selecteurProfils.ajouter), findsNothing);

      // Le sort du cours passe avant l'eleve ; une coupure n'est pas une
      // absence ; le retard porte ses minutes.
      expect(
        _dans(_ligne('s-presente'), t.historique.etat.presence),
        findsOneWidget,
      );
      expect(
        _dans(_ligne('s-retard'), t.historique.etat.retard(minutes: 8)),
        findsOneWidget,
      );
      expect(_dans(_ligne('s-coupure'), libelleVerification), findsOneWidget);
      expect(
        _dans(_ligne('s-annulee'), t.historique.etat.annule),
        findsOneWidget,
      );
      await tester.ensureVisible(_ligne('s-non-tenue'));
      expect(
        _dans(_ligne('s-non-tenue'), t.historique.etat.nonTenu),
        findsOneWidget,
      );
      expect(find.text(t.presence.absente), findsNothing);
      expect(find.text(t.presence.deconnectee), findsNothing);
      // Classe et enseignant avec son titre, lus de la classe courante.
      expect(_dans(_ligne('s-presente'), classeA.libelle), findsOneWidget);
      expect(_dans(_ligne('s-presente'), _sayyidX), findsOneWidget);
      // Ni seance a venir, ni seance d'un autre eleve.
      expect(_ligne('s-futur'), findsNothing);
      expect(_ligne('s-a2', eleve: FoyersFictifs.a2.id), findsNothing);
      // Du plus recent au plus ancien.
      expect(
        tester.getTopLeft(_ligne('s-presente')).dy,
        lessThan(tester.getTopLeft(_ligne('s-retard')).dy),
      );
      // Fuseau explicite, aucun reseau non mesure.
      expect(find.text(t.historique.fuseauListe), findsOneWidget);
      expect(find.textContaining('Réseau'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toucher un autre profil change la liste (K1)', (
      WidgetTester tester,
    ) async {
      await monterHistorique(tester);
      await toucherDestination(tester, t.nav.tuteur.historique);
      await toucher(tester, _profil(FoyersFictifs.a2.prenom));

      expect(_ligne('s-a2', eleve: FoyersFictifs.a2.id), findsOneWidget);
      expect(_ligne('s-presente'), findsNothing);
      // Aucune classe connue pour cette seance : jamais devinee.
      expect(
        _dans(
          _ligne('s-a2', eleve: FoyersFictifs.a2.id),
          t.historique.classeInconnue,
        ),
        findsOneWidget,
      );
      expect(find.text(t.historique.selecteur.une), findsOneWidget);
    });

    testWidgets('toucher une ligne ouvre le detail de seance, le retour rend '
        'la liste filtree', (WidgetTester tester) async {
      final GoRouter routeur = await monterHistorique(tester);
      await toucherDestination(tester, t.nav.tuteur.historique);
      await _filtrer(
        tester,
        t.historique.filtres.statut,
        t.historique.etat.verification,
      );
      expect(_ligne('s-presente'), findsNothing);
      await toucher(tester, _ligne('s-coupure'));

      expect(find.byType(DetailSeancePage), findsOneWidget);
      expect(lieu(routeur), startsWith(Routes.seancePour('s-coupure')));
      expect(_indexActif(tester), 2);
      expect(find.text(classeA.libelle), findsWidgets);
      expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
      expect(find.text(libelleVerification), findsOneWidget);
      expect(find.text(t.historique.seance.verificationPhrase), findsOneWidget);
      expect(find.text('18:02'), findsOneWidget);
      expect(find.text('18:00 - 19:00'), findsOneWidget);
      expect(find.text(_sayyidX), findsOneWidget);
      expect(find.textContaining('UTC'), findsOneWidget);
      expect(find.byType(DisqueRetour), findsOneWidget);

      await toucher(tester, find.byType(DisqueRetour));
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      // Les filtres ont survecu au detail.
      expect(_ligne('s-coupure'), findsOneWidget);
      expect(_ligne('s-presente'), findsNothing);
    });

    testWidgets('seance annulee et non tenue : le detail le dit sans accuser', (
      WidgetTester tester,
    ) async {
      await monterHistorique(tester);
      await toucherDestination(tester, t.nav.tuteur.historique);
      await toucher(tester, _ligne('s-non-tenue'));
      expect(find.text(t.historique.seance.nonTenuPhrase), findsOneWidget);
      expect(find.text(t.historique.seance.arrivee), findsNothing);
      await toucher(tester, find.byType(DisqueRetour));
      await toucher(tester, _ligne('s-annulee'));
      expect(find.text(t.historique.seance.annulePhrase), findsOneWidget);
    });

    testWidgets('periode et filtre vide, puis reinitialisation', (
      WidgetTester tester,
    ) async {
      await monterHistorique(tester);
      await toucherDestination(tester, t.nav.tuteur.historique);
      await _filtrer(
        tester,
        t.historique.filtres.periode,
        t.historique.filtres.septJours,
      );
      expect(_ligne('s-presente'), findsOneWidget);
      expect(_ligne('s-non-tenue'), findsNothing);

      await _filtrer(
        tester,
        t.historique.filtres.statut,
        t.historique.etat.nonTenu,
      );
      expect(find.text(t.historique.seances.filtreVideTitre), findsOneWidget);
      await toucher(
        tester,
        find.text(t.commun.etats.actions.reinitialiserFiltres),
      );
      expect(_ligne('s-presente'), findsOneWidget);
      expect(_ligne('s-non-tenue'), findsOneWidget);
    });

    testWidgets('filtre Classe : seulement les classes nommables', (
      WidgetTester tester,
    ) async {
      await monterHistorique(tester);
      await toucherDestination(tester, t.nav.tuteur.historique);
      await _filtrer(tester, t.historique.filtres.classe, classeA.libelle);
      expect(_ligne('s-presente'), findsOneWidget);
      // Sans classe courante lisible, le menu n'est pas rendu.
    });

    testWidgets('sans classe lisible, pas de menu Classe', (
      WidgetTester tester,
    ) async {
      await monterHistorique(tester, avecClasses: false);
      await toucherDestination(tester, t.nav.tuteur.historique);
      expect(_menu(t.historique.filtres.classe), findsNothing);
      expect(
        _dans(_ligne('s-presente'), t.historique.classeInconnue),
        findsOneWidget,
      );
    });

    testWidgets('sur bureau : meme parcours touche, colonne bornee', (
      WidgetTester tester,
    ) async {
      await monterHistorique(tester, taille: const Size(1440, 900));
      await toucherDestination(tester, t.nav.tuteur.historique);
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      expect(_indexActif(tester), 2);
      expect(
        tester.getSize(_ligne('s-presente')).width,
        lessThanOrEqualTo(800),
      );
      await toucher(tester, _ligne('s-retard'));
      expect(find.byType(DetailSeancePage), findsOneWidget);
      expect(find.text(t.historique.etat.retard(minutes: 8)), findsOneWidget);
      await toucher(tester, find.byType(DisqueRetour));
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
    });

    testWidgets('l entree de la Classe pose l eleve et la classe', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: '${Routes.tuteurSuivi}?eleve=${FoyersFictifs.a2.id}',
      );
      expect(_ligne('s-a2', eleve: FoyersFictifs.a2.id), findsOneWidget);
      expect(_ligne('s-presente'), findsNothing);
    });
  });

  group('Observations : segment touche, detail touche', () {
    testWidgets('en production, le port dit indisponible (jamais une liste '
        'locale), et le segment Seances revient', (WidgetTester tester) async {
      final GoRouter routeur = await monterHistorique(tester);
      await toucherDestination(tester, t.nav.tuteur.historique);
      await toucher(tester, _segment(t.historique.segments.observations));

      expect(lieu(routeur), Routes.tuteurSuiviObservations);
      expect(find.byType(ObservationsPage), findsOneWidget);
      expect(_indexActif(tester), 2);
      expect(
        find.text(t.historique.observations.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);

      await toucher(tester, _segment(t.historique.segments.seances));
      expect(lieu(routeur), Routes.tuteurSuivi);
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
    });

    testWidgets('les visites groupees par seance, puis le detail et retour', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        observations: FauxHistoriqueObservations(lignes: visitesFoyerA()),
      );
      await toucherDestination(tester, t.nav.tuteur.historique);
      await toucher(tester, _segment(t.historique.segments.observations));

      final Finder ligne = _ligneObs('s-presente');
      expect(ligne, findsOneWidget);
      expect(
        _dans(
          ligne,
          '${t.historique.observations.visites(n: 2)} · '
          '${t.historique.observations.dureeNonConfirmee}',
        ),
        findsOneWidget,
      );
      expect(
        _dans(ligne, t.historique.observations.nonRefermee),
        findsOneWidget,
      );
      expect(_dans(ligne, classeA.libelle), findsOneWidget);
      // Aucun motif de fin deduit du client.
      expect(find.text('Limite atteinte'), findsNothing);
      expect(find.text('Départ volontaire'), findsNothing);

      await toucher(tester, ligne);
      expect(find.byType(DetailObservationsPage), findsOneWidget);
      expect(_indexActif(tester), 2);
      expect(find.text(t.historique.observation.visite(n: 1)), findsOneWidget);
      expect(find.text(t.historique.observation.visite(n: 2)), findsOneWidget);
      expect(find.text('18:12 - 18:14'), findsOneWidget);
      expect(find.text('2\u00A0min'), findsOneWidget);
      expect(find.text(t.historique.observations.terminee), findsOneWidget);
      expect(
        find.text(t.historique.observation.plageOuverte(debut: '18:35')),
        findsOneWidget,
      );
      expect(find.text(t.historique.observation.vous), findsOneWidget);
      expect(find.text(_sayyidX), findsOneWidget);
      expect(find.textContaining('UTC'), findsOneWidget);

      await toucher(tester, find.byType(DisqueRetour));
      expect(find.byType(ObservationsPage), findsOneWidget);

      await toucher(tester, _profil(FoyersFictifs.a2.prenom));
      final Finder ligneA2 = _ligneObs('s-a2', eleve: FoyersFictifs.a2.id);
      expect(ligneA2, findsOneWidget);
      expect(
        _dans(ligneA2, '${t.historique.observations.visiteUne} · 48\u00A0s'),
        findsOneWidget,
      );
      expect(_dans(ligneA2, t.historique.classeInconnue), findsOneWidget);
      expect(
        _dans(ligneA2, t.historique.observations.terminee),
        findsOneWidget,
      );
    });

    testWidgets('filtre Statut des observations', (WidgetTester tester) async {
      await monterHistorique(
        tester,
        observations: FauxHistoriqueObservations(lignes: visitesFoyerA()),
      );
      await toucherDestination(tester, t.nav.tuteur.historique);
      await toucher(tester, _segment(t.historique.segments.observations));
      await _filtrer(
        tester,
        t.historique.filtres.statut,
        t.historique.observations.nonRefermee,
      );
      expect(_ligneObs('s-presente'), findsOneWidget);
      // Les filtres survivent au changement de profil : la seule visite de A2
      // est terminee, la liste filtree est donc vide et le dit.
      await toucher(tester, _profil(FoyersFictifs.a2.prenom));
      expect(
        find.text(t.historique.observations.filtreVideTitre),
        findsOneWidget,
      );
      await toucher(
        tester,
        find.text(t.commun.etats.actions.reinitialiserFiltres),
      );
      expect(_ligneObs('s-a2', eleve: FoyersFictifs.a2.id), findsOneWidget);
    });

    testWidgets('sur bureau : detail des observations touche', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        taille: const Size(1440, 900),
        observations: FauxHistoriqueObservations(lignes: visitesFoyerA()),
      );
      await toucherDestination(tester, t.nav.tuteur.historique);
      await toucher(tester, _segment(t.historique.segments.observations));
      await toucher(tester, _ligneObs('s-presente'));
      expect(find.byType(DetailObservationsPage), findsOneWidget);
      await toucher(tester, find.byType(DisqueRetour));
      expect(find.byType(ObservationsPage), findsOneWidget);
    });

    testWidgets('aucune visite : vide honnete', (WidgetTester tester) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuiviObservations,
        observations: FauxHistoriqueObservations(),
      );
      expect(find.text(t.historique.observations.videTitre), findsOneWidget);
    });

    testWidgets('lien profond vers des visites inconnues : introuvable', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.observationsSeancePour('inconnue', eleveId: 'x'),
        observations: FauxHistoriqueObservations(lignes: visitesFoyerA()),
      );
      expect(
        find.text(t.historique.observation.introuvableTitre),
        findsOneWidget,
      );
      await toucher(tester, find.text(t.historique.retour));
      expect(find.byType(ObservationsPage), findsOneWidget);
    });
  });

  group('Etats', () {
    testWidgets('chargement : squelette, puis la liste', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        delai: const Duration(seconds: 2),
      );
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      await stabiliser(tester);
      expect(_ligne('s-presente'), findsOneWidget);
    });

    testWidgets('echec : Reessayer relit', (WidgetTester tester) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        erreur: Exception('lecture refusee'),
      );
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);
      final int avant = suiviDe(tester).lectures;
      suiviDe(tester).erreurAJeter = null;
      // Toucher tout de suite : pendant une relecture, le bouton montre sa
      // progression a la place de son libelle.
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await stabiliser(tester);
      expect(suiviDe(tester).lectures, greaterThan(avant));
      expect(_ligne('s-presente'), findsOneWidget);
    });

    testWidgets('aucune seance passee : vide honnete, sans bouton', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        seances: <Never>[],
      );
      expect(find.text(t.historique.seances.videTitre), findsOneWidget);
      expect(
        find.text(
          t.historique.seances.videPhrase(prenom: FoyersFictifs.a1.prenom),
        ),
        findsOneWidget,
      );
    });

    testWidgets('foyer sans profil eleve : vide du foyer, sans selecteur', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        eleves: FoyersFictifs.foyerVide,
      );
      expect(find.text(t.historique.seances.videPhraseFoyer), findsOneWidget);
      expect(find.byType(SelecteurProfils), findsNothing);
    });

    testWidgets('hors ligne : le bandeau le dit, la liste reste lisible', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        horsLigne: true,
      );
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(_ligne('s-presente'), findsOneWidget);
    });

    testWidgets('presence illisible : jamais une absence, la note le dit', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        presencesIllisibles: true,
      );
      expect(find.text(t.historique.presenceIllisible), findsOneWidget);
      expect(_dans(_ligne('s-presente'), libelleVerification), findsOneWidget);
      expect(find.text(t.presence.absente), findsNothing);
    });

    testWidgets('lien profond vers une seance inconnue : introuvable', (
      WidgetTester tester,
    ) async {
      await monterHistorique(tester, depart: Routes.seancePour('inconnue'));
      expect(find.text(t.historique.seance.introuvableTitre), findsOneWidget);
      expect(find.byType(DisqueRetour), findsOneWidget);
      await toucher(tester, find.text(t.historique.retour));
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
    });

    testWidgets('la colonne du bureau est la colonne de lecture', (
      WidgetTester tester,
    ) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        taille: const Size(1440, 900),
      );
      expect(
        tester.getSize(find.byType(CarteLignes)).width,
        lessThanOrEqualTo(800),
      );
    });
  });
}
