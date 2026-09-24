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
import 'package:rewayah_academy/features/foyer/fiche/informations_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/inscription_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/interface_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';
import 'package:rewayah_academy/features/parcours_offres/parcours_offres_page.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';
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
    test('un eleve en mode enfant n a aucune destination (ADR-009)', () {
      final List<Destination> rien = destinationsPour(
        role: AppRole.student,
        mode: InterfaceMode.enfant,
      );
      expect(rien, isEmpty);
    });

    test('les chemins des destinations sont exactement ceux du role', () {
      final Map<AppRole, List<String>> attendus = <AppRole, List<String>>{
        // L'eleve et l'enseignant : inchanges (non-regression).
        AppRole.student: <String>[
          Routes.eleve,
          Routes.eleveCoran,
          Routes.eleveSuivi,
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
        // L'enseignant a TROIS destinations, pas quatre, et c'est un contrat
        // du protocole du role Enseignant : « Compte » et « Profil »
        // repondaient a la meme question (`TEACHER_PARALLEL_BASELINE.md`
        // §3.1, ADR-027).
        AppRole.teacher: <String>[
          Routes.enseignantJournee,
          Routes.enseignantCreneaux,
          Routes.enseignantProfil,
        ],
        // Le controleur et le comptable n ont pas de barre ; l'admin a sa
        // propre coquille (`admin_domaine_test.dart`).
        AppRole.controller: <String>[],
        AppRole.accountant: <String>[],
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
    // coquille, et la destination parente est active.
    final List<(String, Type, int)> table = <(String, Type, int)>[
      (Routes.tuteurAccueil, AccueilFamillePage, 0),
      (Routes.tuteurNotifications, NotificationsPage, 0),
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
      (Routes.ficheEleveSousPage('e1', 'appareils'), AppareilsElevePage, 1),
      (Routes.parcoursPour('e1'), ParcoursOffresPage, 1),
      (Routes.tuteurReglages, ReglagesEnfantPage, 1),
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

    for (final (String chemin, Type ecran, int destination) in table) {
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
      Routes.tuteurDisponibilites: Routes.tuteurFoyer,
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
        t.nav.eleve.coran,
        t.nav.eleve.suivi,
        t.nav.eleve.compte,
      ]) {
        expect(find.text(libelle), findsOneWidget, reason: libelle);
      }
      // Compte n'a pas de branche : la barre le rejoint par `go`, et non
      // par `goBranch` sur un index absent (C01 3.3-6).
      await tester.tap(find.text(t.nav.eleve.compte));
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
        // La page hors ligne n'appartient qu'a une session dont le profil n'a
        // pas pu etre lu.
        const SessionState(
          resolue: true,
          profileId: 'p1',
          role: AppRole.guardian,
          lectureProfil: LectureProfil.injoignable,
        ),
        for (final AppRole role in AppRole.values) _session(role),
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
        final bool atteint = sessions.any(
          (SessionState s) =>
              deciderRedirection(
                session: s,
                cheminDemande: chemin,
                maintenant: maintenant,
              ) ==
              null,
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
