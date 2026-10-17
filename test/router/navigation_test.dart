import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/appareils/ajouter_enfant_page.dart';
import 'package:rewayah_academy/features/appareils/appairage_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_eleve_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/catalogue_classes_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/planning_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/progression_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/ressources_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/travail_classe_page.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/aide_page.dart';
import 'package:rewayah_academy/features/compte/apparence_page.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/compte/compte_tuteur_page.dart';
import 'package:rewayah_academy/features/compte/informations_legales_page.dart';
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/preferences_page.dart';
import 'package:rewayah_academy/features/compte/securite_page.dart';
import 'package:rewayah_academy/features/consentements/consentement_observation_page.dart';
import 'package:rewayah_academy/features/foyer/creer_mon_profil_indisponible.dart';
import 'package:rewayah_academy/features/foyer/fiche/acces_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/camera_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/informations_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/inscription_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/interface_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/mouvements_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_observations_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_seance_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/observations_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../support/harnais.dart';
import 'support_routeur.dart';

SessionState _session(AppRole role) => sessionActive(role);

List<Override> _surcharges(SessionState session) =>
    surchargesRouteur(FausseSourceSession(session));

Future<void> _stabiliser(WidgetTester tester) => stabiliser(tester);

/// Monte l'application sur son **vrai** routeur, a l'adresse demandee.
Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  SessionState? session,
  Size taille = const Size(390, 844),
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(session ?? sessionActive(AppRole.guardian)),
  taille: taille,
);

String _lieu(GoRouter routeur) => lieu(routeur);

void main() {
  group('destinationsPour : une barre par role, jamais plus de quatre', () {
    // MA-2 (27/09/2026) remplaçait « aucune destination en mode enfant » par
    // les memes quatre ; MA-NAV-1 (02/10/2026, demande du directeur) garde
    // les essentielles en Mode Accessibilite, sur les memes routes. Pour
    // l'eleve, les quatre le sont (Coran compris : MA-CMD-1, decision
    // deleguee du 02/10).
    test('un eleve garde ses quatre destinations en Mode Accessibilite', () {
      List<String> chemins(InterfaceMode mode) => destinationsPour(
        role: AppRole.student,
        mode: mode,
      ).map((Destination d) => d.chemin).toList();
      expect(chemins(InterfaceMode.enfant), hasLength(4));
      expect(chemins(InterfaceMode.standard), hasLength(4));
      expect(chemins(InterfaceMode.enfant), chemins(InterfaceMode.standard));
      expect(chemins(InterfaceMode.enfant), contains(Routes.eleveCoran));
    });

    test('les chemins des destinations sont exactement ceux du role', () {
      final Map<AppRole, List<String>> attendus = <AppRole, List<String>>{
        // L'eleve (MA-2) : Accueil, Ma classe, Coran, Mon espace, sur les
        // routes existantes.
        AppRole.student: <String>[
          Routes.eleve,
          Routes.eleveSuivi,
          Routes.eleveCoran,
          Routes.compte,
        ],
        // Le tuteur : Accueil, Foyer, Historique, Compte, dans cet ordre, sur
        // tous les formats (mandat Tuteur V1 section 4).
        AppRole.guardian: <String>[
          Routes.tuteurAccueil,
          Routes.tuteurFoyer,
          Routes.tuteurSuivi,
          Routes.tuteurCompte,
        ],
        // L'enseignant a QUATRE destinations, dans l'ordre E10 : Aujourd'hui,
        // Classes, Disponibilites, Profil (decision du directeur du
        // 26/09/2026, qui remplace ADR-027). « Compte » ne revient pas.
        AppRole.teacher: <String>[
          Routes.enseignantJournee,
          Routes.enseignantClasses,
          Routes.enseignantCreneaux,
          Routes.enseignantProfil,
        ],
        // Le controleur a QUATRE destinations, dans l'ordre C13 : Controle,
        // Historique, Echanges, Compte (document 08 du 27/09/2026, qui
        // remplace « une seule destination, sans barre »).
        AppRole.controller: <String>[
          Routes.controleur,
          Routes.controleurHistorique,
          Routes.controleurEchanges,
          Routes.compte,
        ],
        // Le comptable a QUATRE destinations (Comptable V1, CPT-F) :
        // Aujourd'hui, Paiements, Tresorerie, Compte (spec §45,
        // `UX_REVIEW_FINANCE_COMPTABLE_L0.md` §3). L'admin a sa propre
        // coquille (`admin_domaine_test.dart`).
        AppRole.accountant: <String>[
          Routes.comptable,
          Routes.comptablePaiements,
          Routes.comptableTresorerie,
          Routes.compte,
        ],
        AppRole.admin: <String>[],
      };

      for (final MapEntry<AppRole, List<String>> attente in attendus.entries) {
        final List<Destination> destinations = destinationsPour(
          role: attente.key,
          mode: InterfaceMode.standard,
        );
        expect(
          destinations.map((Destination d) => d.chemin).toList(),
          attente.value,
          reason: 'les destinations de ${attente.key.valeurSql}',
        );
        // La racine du role est toujours la premiere destination.
        if (attente.value.isNotEmpty) {
          expect(
            destinations.first.chemin,
            Routes.racinePour(attente.key),
            reason: 'la racine de ${attente.key.valeurSql} est en premiere',
          );
        }
      }
    });

    test('libelles et icones du tuteur, Compte epingle, aucune secondaire', () {
      final List<Destination> tuteur = destinationsPour(
        role: AppRole.guardian,
        mode: InterfaceMode.standard,
      );
      expect(tuteur.map((Destination d) => d.libelle), <String>[
        t.nav.tuteur.accueil,
        t.nav.tuteur.foyer,
        t.nav.tuteur.historique,
        t.nav.tuteur.compte,
      ]);
      expect(tuteur.map((Destination d) => d.icone), <AppIcon>[
        AppIcons.accueil,
        AppIcons.foyer,
        AppIcons.historique,
        AppIcons.profil,
      ]);
      expect(tuteur.where((Destination d) => d.enPied), hasLength(1));
      expect(tuteur.last.enPied, isTrue);
      for (final AppRole role in AppRole.values) {
        expect(secondairesPour(role: role), isEmpty, reason: role.valeurSql);
      }
    });

    test('aucun role ne demande plus de quatre destinations', () {
      for (final AppRole role in AppRole.values) {
        for (final InterfaceMode mode in InterfaceMode.values) {
          expect(
            destinationsPour(role: role, mode: mode).length,
            lessThanOrEqualTo(NavShell.maxDestinations),
            reason: '${role.valeurSql} en mode ${mode.name}',
          );
        }
      }
    });

    test('chaque destination porte un libelle et son icone', () {
      for (final AppRole role in AppRole.values) {
        for (final Destination destination in destinationsPour(
          role: role,
          mode: InterfaceMode.standard,
        )) {
          expect(destination.libelle, isNotEmpty);
          expect(destination.chemin, isNotEmpty);
        }
      }
    });
  });

  group('Coquille tuteur sur le vrai routeur', () {
    testWidgets('chaque destination de la barre mene a sa branche', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, Routes.tuteurAccueil);
      expect(find.byType(AccueilFamillePage), findsOneWidget);

      final Map<String, (String, Type)> attendus = <String, (String, Type)>{
        t.nav.tuteur.foyer: (Routes.tuteurFoyer, FoyerPage),
        t.nav.tuteur.historique: (Routes.tuteurSuivi, SuiviFoyerPage),
        t.nav.tuteur.compte: (Routes.tuteurCompte, CompteTuteurPage),
        t.nav.tuteur.accueil: (Routes.tuteurAccueil, AccueilFamillePage),
      };
      for (final MapEntry<String, (String, Type)> e in attendus.entries) {
        await tester.tap(
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(e.key),
          ),
        );
        await _stabiliser(tester);
        expect(_lieu(routeur), e.value.$1, reason: e.key);
        expect(find.byType(e.value.$2), findsOneWidget, reason: e.key);
      }
      expect(tester.takeException(), isNull);
    });

    // Toute la table des routes du tuteur (mapping sections 3 et 4) : la
    // route existe, la garde la laisse passer, l'ecran se construit dans la
    // coquille, et la destination parente est active. La page des
    // notifications n'en allume aucune : la cloche y est la seule entree
    // active (COM-F-Q5).
    final List<(String, Type, int?)> table = <(String, Type, int?)>[
      (Routes.tuteurAccueil, AccueilFamillePage, 0),
      (Routes.tuteurNotifications, NotificationsPage, null),
      ('${Routes.tuteurClassesCatalogue}?eleve=e1', CatalogueClassesPage, 0),
      (Routes.classePour('g1', eleveId: 'e1'), ClasseTuteurPage, 0),
      (Routes.classeSousPage('g1', 'planning'), PlanningClassePage, 0),
      (Routes.classeSousPage('g1', 'travail'), TravailClassePage, 0),
      (Routes.classeSousPage('g1', 'ressources'), RessourcesClassePage, 0),
      (Routes.classeSousPage('g1', 'progression'), ProgressionClassePage, 0),
      (Routes.tuteurFoyer, FoyerPage, 1),
      (Routes.tuteurAjouterEnfant, AjouterEnfantPage, 1),
      (Routes.tuteurAjouterPourMoi, CreerMonProfilIndisponible, 1),
      (Routes.tuteurFoyerAppareils, AppareilsPage, 1),
      (Routes.appairerPour('e1'), AppairagePage, 1),
      (Routes.ficheElevePour('e1'), FicheElevePage, 1),
      (
        Routes.ficheEleveSousPage('e1', 'informations'),
        InformationsElevePage,
        1,
      ),
      (Routes.ficheEleveSousPage('e1', 'inscription'), InscriptionElevePage, 1),
      (Routes.ficheEleveSousPage('e1', 'interface'), InterfaceElevePage, 1),
      (Routes.ficheEleveSousPage('e1', 'camera'), CameraElevePage, 1),
      (Routes.ficheEleveSousPage('e1', 'acces'), AccesElevePage, 1),
      (Routes.ficheEleveSousPage('e1', 'finances'), FinancesElevePage, 1),
      (Routes.ficheEleveSousPage('e1', 'mouvements'), MouvementsElevePage, 1),
      (Routes.ficheEleveSousPage('e1', 'appareils'), AppareilsElevePage, 1),
      (Routes.parcoursPour('e1'), ParcoursOffresPage, 1),
      (Routes.tuteurSuivi, SuiviFoyerPage, 2),
      (Routes.tuteurSuiviObservations, ObservationsPage, 2),
      (Routes.seancePour('s1'), DetailSeancePage, 2),
      (
        Routes.observationsSeancePour('s1', eleveId: 'e1'),
        DetailObservationsPage,
        2,
      ),
      (Routes.tuteurCompte, CompteTuteurPage, 3),
      (Routes.compteTuteurSousPage('informations'), InformationsComptePage, 3),
      (Routes.compteTuteurSousPage('securite'), SecuriteComptePage, 3),
      (Routes.compteTuteurSousPage('acces'), AccesComptePage, 3),
      (Routes.compteTuteurSousPage('paiements'), PaiementsComptePage, 3),
      (Routes.tuteurComptePreferences, PreferencesComptePage, 3),
      (Routes.tuteurCompteApparence, ApparenceComptePage, 3),
      (Routes.compteTuteurSousPage('aide'), AideComptePage, 3),
      (
        Routes.compteTuteurSousPage('informations-legales'),
        InformationsLegalesComptePage,
        3,
      ),
      (Routes.tuteurCompteConsentements, ConsentementObservationPage, 3),
    ];

    // Ou le BOUTON de chaque ligne est touche (revue P2-09, majeur 2) : cette
    // table ne monte que l'adresse ; le clic reel est prouve, ecran par
    // ecran, dans le fichier nomme ici. Le test suivant verifie que chaque
    // ecran de la table a son fichier, et que ce fichier touche un bouton
    // (`tap`) et attend cet ecran.
    const String compte = 'test/features/compte/compte_tuteur_test.dart';
    const String classe = 'test/features/classe_tuteur/classe_tuteur_test.dart';
    const String fiche = 'test/features/foyer/fiche_eleve_test.dart';
    const String partage = 'test/features/appareils/appareil_partage_test.dart';
    const String historique = 'test/features/historique/historique_test.dart';
    final Map<Type, String> boutonTesteDans = <Type, String>{
      AccueilFamillePage: 'test/features/accueil_famille_test.dart',
      NotificationsPage: 'test/features/notifications/notifications_test.dart',
      CatalogueClassesPage:
          'test/features/classe_tuteur/catalogue_classes_test.dart',
      ClasseTuteurPage: 'test/features/accueil_famille_test.dart',
      PlanningClassePage: classe,
      TravailClassePage: classe,
      RessourcesClassePage: classe,
      ProgressionClassePage: classe,
      FoyerPage: partage,
      AjouterEnfantPage:
          'test/features/foyer/formulaire_profil_eleve_test.dart',
      CreerMonProfilIndisponible: compte,
      AppareilsPage: 'test/features/foyer/foyer_page_test.dart',
      AppairagePage: 'test/features/appareils/emetteur_qr_test.dart',
      FicheElevePage: partage,
      InformationsElevePage: fiche,
      InscriptionElevePage: fiche,
      InterfaceElevePage: fiche,
      CameraElevePage: fiche,
      AccesElevePage: fiche,
      FinancesElevePage: 'test/features/foyer/fiche_eleve_finances_test.dart',
      MouvementsElevePage:
          'test/features/foyer/fiche_eleve_mouvements_test.dart',
      AppareilsElevePage: partage,
      ParcoursOffresPage: fiche,
      SuiviFoyerPage: classe,
      ObservationsPage: historique,
      DetailSeancePage: historique,
      DetailObservationsPage: historique,
      CompteTuteurPage: compte,
      InformationsComptePage: compte,
      SecuriteComptePage: compte,
      AccesComptePage: compte,
      PaiementsComptePage: compte,
      PreferencesComptePage: compte,
      ApparenceComptePage: compte,
      AideComptePage: compte,
      InformationsLegalesComptePage: compte,
      ConsentementObservationPage: compte,
    };

    test('chaque route de la table a son test de bouton (P2-09)', () {
      for (final (String chemin, Type ecran, int? _) in table) {
        final String? fichier = boutonTesteDans[ecran];
        expect(fichier, isNotNull, reason: '$chemin : aucun test de bouton');
        final String source = File(fichier!).readAsStringSync();
        expect(source, contains('tap'), reason: fichier);
        expect(source, contains('$ecran'), reason: '$fichier : $ecran');
      }
    });

    for (final (String chemin, Type ecran, int? destination) in table) {
      testWidgets('$chemin rend $ecran, destination $destination active', (
        WidgetTester tester,
      ) async {
        // Sur tablette : la colonne reste visible meme sur une tache
        // focalisee, la destination active se lit donc partout.
        final GoRouter routeur = await _monter(
          tester,
          chemin,
          taille: const Size(900, 1000),
        );
        expect(_lieu(routeur), chemin, reason: 'la garde a devie $chemin');
        expect(find.byType(ecran), findsOneWidget);
        expect(
          tester.widget<NavShell>(find.byType(NavShell)).indexActif,
          destination,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('une tache focalisee efface la barre basse sur telephone', (
      WidgetTester tester,
    ) async {
      for (final String chemin in <String>[
        Routes.tuteurAjouterEnfant,
        Routes.appairerPour('e1'),
        Routes.parcoursPour('e1'),
        Routes.tuteurComptePreferences,
        Routes.tuteurCompteApparence,
        Routes.tuteurCompteConsentements,
      ]) {
        await _monter(tester, chemin);
        expect(
          find.byKey(NavShell.barreBasseKey),
          findsNothing,
          reason: chemin,
        );
      }
      for (final String chemin in <String>[
        Routes.tuteurFoyer,
        Routes.ficheElevePour('e1'),
        Routes.classePour('g1'),
        Routes.tuteurCompte,
      ]) {
        await _monter(tester, chemin);
        expect(
          find.byKey(NavShell.barreBasseKey),
          findsOneWidget,
          reason: chemin,
        );
      }
    });

    testWidgets(
      'les preferences, tache focalisee, sortent par le disque retour',
      (WidgetTester tester) async {
        // Revue phase 0 (routes D4) : la barre basse s'efface sur les
        // preferences ; sans disque retour, la cloche etait la seule sortie.
        final GoRouter routeur = await _monter(
          tester,
          Routes.tuteurComptePreferences,
        );
        expect(find.byKey(NavShell.barreBasseKey), findsNothing);
        expect(find.byType(DisqueRetour), findsOneWidget);

        await tester.tap(find.byType(DisqueRetour));
        await _stabiliser(tester);
        expect(_lieu(routeur), Routes.tuteurCompte);
        expect(find.byKey(NavShell.barreBasseKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('la ligne des profils du Compte allume le Foyer', (
      WidgetTester tester,
    ) async {
      // Revue phase 0 (routes D7) : un `push` de `/compte/profils` empilait
      // le Foyer dans la branche Compte, Compte reste actif.
      final GoRouter routeur = await _monter(tester, Routes.tuteurCompte);
      final Finder ligne = find.text(t.compte.profils);
      await tester.ensureVisible(ligne);
      await _stabiliser(tester);
      await tester.tap(ligne);
      await _stabiliser(tester);

      expect(_lieu(routeur), Routes.tuteurFoyer);
      expect(find.byType(FoyerPage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 1);
    });

    testWidgets('la cloche mene aux notifications ; bascule des la tablette', (
      WidgetTester tester,
    ) async {
      GoRouter routeur = await _monter(tester, Routes.tuteurSuivi);
      expect(
        find.bySemanticsLabel(t.commun.entete.notifications),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(t.commun.theme.clair), findsNothing);
      await tester.tap(
        find.bySemanticsLabel(t.commun.entete.notifications).first,
      );
      await _stabiliser(tester);
      expect(_lieu(routeur), Routes.tuteurNotifications);

      routeur = await _monter(
        tester,
        Routes.tuteurSuivi,
        taille: const Size(1440, 900),
      );
      expect(find.bySemanticsLabel(t.commun.theme.clair), findsOneWidget);
      expect(find.bySemanticsLabel(t.commun.theme.sombre), findsOneWidget);
    });

    // Les alias et redirections du tuteur (mapping sections 2 a 4).
    final Map<String, String> alias = <String, String>{
      Routes.tuteurAccueilAlias: Routes.tuteurAccueil,
      Routes.tuteurHistoriqueAlias: Routes.tuteurSuivi,
      '${Routes.tuteurHistoriqueAlias}/observations':
          Routes.tuteurSuiviObservations,
      Routes.tuteurAjouterEnfantAncien: Routes.tuteurAjouterEnfant,
      '${Routes.tuteurAjouterEnfantAncien}?pour=moi':
          Routes.tuteurAjouterPourMoi,
      // Mapping C6, demande B-4 : les reglages par eleve sont dans la fiche.
      Routes.tuteurReglages: Routes.tuteurFoyer,
      '${Routes.ficheElevePour('e1')}/appareils/connexion': Routes.appairerPour(
        'e1',
      ),
      '${Routes.classeSousPage('g1', 'observer')}?eleve=e1': Routes.classePour(
        'g1',
        eleveId: 'e1',
      ),
      Routes.compte: Routes.tuteurCompte,
      Routes.compteProfil: Routes.compteTuteurSousPage('informations'),
      Routes.compteReglages: Routes.tuteurComptePreferences,
      Routes.compteProfils: Routes.tuteurFoyer,
      Routes.compteProfilEnfantPour('e1'): Routes.ficheElevePour('e1'),
      Routes.tcGroupes: Routes.tuteurAccueil,
      Routes.tcEspaceGroupe('g1'): Routes.classePour('g1'),
    };
    for (final MapEntry<String, String> a in alias.entries) {
      testWidgets('${a.key} mene le tuteur a ${a.value}', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monter(tester, a.key);
        expect(_lieu(routeur), a.value);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Les autres roles gardent leur navigation', () {
    testWidgets('l eleve : quatre destinations, Compte sans branche', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.eleve,
        session: _session(AppRole.student),
      );
      expect(find.byType(AccueilElevePage), findsOneWidget);
      for (final String libelle in <String>[
        t.nav.eleve.accueil,
        t.nav.eleve.maClasse,
        t.nav.eleve.coran,
        t.nav.eleve.monEspace,
      ]) {
        expect(find.text(libelle), findsOneWidget, reason: libelle);
      }
      // Mon espace n'a pas de branche : la barre le rejoint par `go`, et non
      // par `goBranch` sur un index absent (C01 3.3-6).
      await tester.tap(find.text(t.nav.eleve.monEspace));
      await _stabiliser(tester);
      expect(_lieu(routeur), Routes.compte);
      expect(find.byType(ComptePage), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Sur le compte, la barre reste la, Compte actif.
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);
    });

    testWidgets('l enseignant et l admin gardent /compte', (
      WidgetTester tester,
    ) async {
      for (final AppRole role in <AppRole>[AppRole.teacher, AppRole.admin]) {
        final GoRouter routeur = await _monter(
          tester,
          Routes.compteReglages,
          session: _session(role),
        );
        expect(_lieu(routeur), Routes.compteReglages, reason: role.valeurSql);
        expect(find.byType(ReglagesComptePage), findsOneWidget);
      }
    });

    testWidgets('l eleve garde son Espace Groupe sous /tc/groupes', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        Routes.tcEspaceGroupe('g1'),
        session: _session(AppRole.student),
      );
      expect(_lieu(routeur), Routes.tcEspaceGroupe('g1'));
    });
  });

  group('Aucune route orpheline', () {
    test('chaque route declaree est atteignable par au moins une session', () {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: _surcharges(_session(AppRole.guardian)),
      );
      addTearDown(conteneur.dispose);
      final GoRouter routeur = conteneur.read(routeurProvider);
      final DateTime maintenant = DateTime.utc(2026, 9, 24, 10);
      final List<SessionState> sessions = <SessionState>[
        const SessionState.deconnecte(),
        const SessionState(
          resolue: true,
          profileId: 'p1',
          lectureProfil: LectureProfil.absente,
        ),
        _session(AppRole.guardian)
            .copyWith(accountStatus: AccountStatus.pendingKyc),
        // K-47 (HL-A-6) : le depot de piece n'est ouvert qu'a l'enseignant.
        _session(AppRole.teacher)
            .copyWith(accountStatus: AccountStatus.pendingKyc),
        // La page hors ligne n'appartient qu'a une session dont le profil n'a
        // pas pu etre lu.
        const SessionState(
          resolue: true,
          profileId: 'p1',
          role: AppRole.guardian,
          lectureProfil: LectureProfil.injoignable,
        ),
        for (final AppRole role in AppRole.values) _session(role),
        // L1-10 : la seconde etape du controleur ne s'ouvre qu'a lui, tant que
        // la capacite `mfaRequise` est vraie.
        _session(AppRole.controller).copyWith(mfaRequise: true),
      ];
      final List<String> declares = cheminsDeclares(routeur);
      expect(declares, isNotEmpty);
      for (final String modele in declares) {
        // `/salle` ne s'ouvre qu'avec un billet ephemere (ADR-005), mesure par
        // `redirection_test.dart`.
        if (modele == Routes.salle) {
          continue;
        }
        // / ne se montre que pendant la resolution de session : toute porte
        // resolue en repart (ecran de demarrage, etats_transverses_test).
        if (modele == Routes.racine) {
          continue;
        }
        if (!Env.galerieActive && modele.startsWith(Routes.galerie)) {
          continue;
        }
        final String chemin = modele.replaceAllMapped(
          RegExp(r':(\w+)'),
          (Match m) => 'id-${m[1]}',
        );
        // Q-2 = a : `/enseignant/contrat` ne s'ouvre qu'a l'enseignant qui
        // doit signer de nouveau ; cet etat compte comme une session de plus.
        final bool atteint = sessions.any(
          (SessionState s) => <bool>[false, true].any(
            (bool resignature) =>
                deciderRedirection(
                  session: s,
                  cheminDemande: chemin,
                  maintenant: maintenant,
                  resignatureContrat: resignature,
                ) ==
                null,
          ),
        );
        expect(atteint, isTrue, reason: '$modele : aucune session n y entre');
      }
    });

    test('toutes les routes du tuteur sont sous /tuteur (R1)', () {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: _surcharges(_session(AppRole.guardian)),
      );
      addTearDown(conteneur.dispose);
      final GoRouter routeur = conteneur.read(routeurProvider);
      for (final String modele in cheminsDeclares(routeur)) {
        if (modele.startsWith('/appareil')) {
          fail('$modele : aucune route /appareils a la racine (R1)');
        }
      }
      expect(
        cheminsDeclares(routeur),
        containsAll(<String>[
          Routes.connexionEleveScanner,
          Routes.connexionEleveCode,
          Routes.connexionRecuperation,
          Routes.bienvenue,
          Routes.adminSecuriteAuditObservations,
        ]),
      );
    });
  });
}
