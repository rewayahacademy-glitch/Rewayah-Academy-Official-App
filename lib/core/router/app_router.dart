import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/_dev/galerie/compte_galerie.dart';
import '../../features/_dev/galerie/galerie_page.dart';
import '../../features/accueil_adulte/accueil_adulte_page.dart'
    show capaciteAccueilAdulteProvider;
import '../../features/accueil_adulte/routes_accueil_adulte.dart';
import '../../features/accueil_eleve/accueil_eleve_selon_presentation.dart';
import '../../features/accueil_famille/accueil_famille_page.dart';
import '../../features/admin_acces_agents/acces_agents_page.dart';
import '../../features/admin_attribution/attribution_page.dart';
import '../../features/admin_comptes/comptes_page.dart';
import '../../features/admin_configuration_conservation_donnees/conservation_donnees_page.dart';
import '../../features/admin_configuration_fonctionnalites/fonctionnalites_page.dart';
import '../../features/admin_configuration_politique_kyc/politique_revue_kyc_page.dart';
import '../../features/admin_configuration_regles/regles_page.dart';
import '../../features/admin_demandes/demandes_page.dart';
import '../../features/admin_dossiers/dossiers_page.dart';
import '../../features/admin_finance/finance_page.dart';
import '../../features/admin_groupes/groupes_page.dart';
import '../../features/admin_invitations/invitations_page.dart';
import '../../features/admin_journal/journal_page.dart';
import '../../features/admin_observations/observations_admin_page.dart';
import '../../features/admin_pedagogie_bibliotheque/catalogue/catalogue_page.dart';
import '../../features/admin_pedagogie_bibliotheque/fiche/fiche_page.dart';
import '../../features/admin_pedagogie_diagnostics/diagnostics_page.dart';
import '../../features/admin_pedagogie_evaluations/evaluations_page.dart';
import '../../features/admin_pedagogie_programmes/programmes_page.dart';
import '../../features/admin_pedagogie_progression/progression_page.dart';
import '../../features/admin_pedagogie_qualite/qualite_page.dart';
import '../../features/admin_pilotage/pilotage_page.dart';
import '../../features/admin_regroupements/regroupements_page.dart';
import '../../features/admin_reprises/reprises_page.dart';
import '../../features/admin_tableau/tableau_de_bord_page.dart';
import '../../features/admin_tirage/tirage_page.dart';
import '../../features/admin_traitement/traitement_page.dart';
import '../../features/agent_entree/agent_entree_page.dart';
import '../../features/alertes/alertes_page.dart';
import '../../features/alertes/bandeau_alerte_urgente.dart';
import '../../features/appareils/ajouter_enfant_page.dart';
import '../../features/appareils/appairage_page.dart';
import '../../features/appareils/appareils_eleve_page.dart';
import '../../features/appareils/appareils_page.dart';
import '../../features/bienvenue/bienvenue_page.dart';
import '../../features/bienvenue_enseignant/bienvenue_page.dart';
import '../../features/cahier/cahier_page.dart';
import '../../features/classe_tuteur/catalogue_classes_page.dart';
import '../../features/classe_tuteur/classe_tuteur_page.dart';
import '../../features/classe_tuteur/planning_classe_page.dart';
import '../../features/classe_tuteur/progression_classe_page.dart';
import '../../features/classe_tuteur/ressources_classe_page.dart';
import '../../features/classe_tuteur/travail_classe_page.dart';
import '../../features/com_annonces/administration_communications_page.dart';
import '../../features/com_annonces/publier_annonce_classe_page.dart';
import '../../features/com_communaute/communaute_page.dart';
import '../../features/com_messages/messages_admin.dart';
import '../../features/com_messages/messages_page.dart';
import '../../features/com_studio/studio_page.dart';
import '../../features/comptable/aujourdhui/aujourdhui_page.dart';
import '../../features/comptable/beneficiaires/beneficiaires_page.dart';
import '../../features/comptable/beneficiaires/profil_paiement_page.dart';
import '../../features/comptable/contractuels/contractuels_page.dart';
import '../../features/comptable/contractuels/nouvelle_obligation_page.dart';
import '../../features/comptable/contractuels/obligation_contractuel_page.dart';
import '../../features/comptable/encaissements/detail_encaissement_page.dart';
import '../../features/comptable/encaissements/encaissements_page.dart';
import '../../features/comptable/encaissements/rapprochement_page.dart';
import '../../features/comptable/paiements/detail_paiement_page.dart';
import '../../features/comptable/paiements/paiements_page.dart';
import '../../features/comptable/tresorerie/tresorerie_page.dart';
import '../../features/compte/acces_page.dart';
import '../../features/compte/aide_page.dart';
import '../../features/compte/apparence_page.dart';
import '../../features/compte/compte_page.dart';
import '../../features/compte/compte_tuteur_page.dart';
import '../../features/compte/espaces_compte.dart';
import '../../features/compte/informations_legales_page.dart';
import '../../features/compte/informations_page.dart';
import '../../features/compte/paiements_page.dart';
import '../../features/compte/preferences_page.dart';
import '../../features/compte/securite_page.dart';
import '../../features/connexion/connexion_page.dart';
import '../../features/connexion/recuperation_page.dart';
import '../../features/consentements/consentement_observation_page.dart';
import '../../features/controleur/compte_rendu_controle.dart'
    show choixObservationDepuis;
import '../../features/controleur/compte_rendu_controle_page.dart';
import '../../features/controleur/controle_page.dart';
import '../../features/controleur/echanges_controleur_page.dart';
import '../../features/controleur/garde_controle.dart';
import '../../features/controleur/historique_controleur_page.dart';
import '../../features/controleur/observation_controle_page.dart';
import '../../features/creneaux/creneaux_page.dart';
import '../../features/demo/communications/demo_communications_page.dart';
import '../../features/demo/demo_accessibilite_page.dart';
import '../../features/demo/demo_adulte_page.dart';
import '../../features/demo/demo_classe_page.dart';
import '../../features/demo/demo_comptable_page.dart';
import '../../features/demo/demo_controleur_page.dart';
import '../../features/demo/demo_enseignant_page.dart';
import '../../features/demo/demo_finance_page.dart';
import '../../features/demo/demo_salle_page.dart';
import '../../features/dossier/attente_page.dart';
import '../../features/dossier/depot_piece_page.dart';
import '../../features/dossier/signature_page.dart';
import '../../features/eleve_connexion/eleve_connexion_page.dart';
import '../../features/eleve_connexion/saisie_code_page.dart';
import '../../features/eleve_connexion/scanner_page.dart';
import '../../features/enseignant_classes/mes_classes_page.dart';
import '../../features/fiche_groupe/fiche_groupe_page.dart';
import '../../features/foyer/creer_mon_profil_indisponible.dart';
import '../../features/foyer/fiche/acces_page.dart';
import '../../features/foyer/fiche/camera_page.dart';
import '../../features/foyer/fiche/couleur_page.dart';
import '../../features/foyer/fiche/finances_page.dart';
import '../../features/foyer/fiche/informations_page.dart';
import '../../features/foyer/fiche/inscription_page.dart';
import '../../features/foyer/fiche/interface_page.dart';
import '../../features/foyer/fiche/mouvements_page.dart';
import '../../features/foyer/fiche_eleve_page.dart';
import '../../features/foyer/finances_foyer.dart' show financesFoyerProvider;
import '../../features/foyer/foyer_page.dart';
import '../../features/foyer/invitation_conjoint.dart';
import '../../features/inscription/etapes/genre_etape.dart';
import '../../features/inscription/etapes/identite_etape.dart';
import '../../features/inscription/etapes/recapitulatif_etape.dart';
import '../../features/inscription/etapes/usage_etape.dart';
import '../../features/inscription/inscription_page.dart';
import '../../features/journee/journee_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/paiements_recus/recevoir_paiements_page.dart';
import '../../features/parcours_offres/parcours_offres_page.dart';
import '../../features/presentation_tuteur/demandes_presentation_page.dart';
import '../../features/profil_enseignant/profil_enseignant_page.dart';
import '../../features/recrutement/invitation_candidat_page.dart';
import '../../features/remplacements/remplacements_page.dart';
import '../../features/revenus_enseignant/revenus_enseignant_page.dart';
import '../../features/revue_groupe/revue_groupe_page.dart';
import '../../features/salle/salle_page.dart';
import '../../features/suivi_demandes/changement_classe_page.dart';
import '../../features/suivi_eleve/suivi_eleve_page.dart';
import '../../features/suivi_famille/suivi_famille_page.dart';
import '../../features/suivi_foyer/detail_observations_page.dart';
import '../../features/suivi_foyer/detail_seance_page.dart';
import '../../features/suivi_foyer/observations_page.dart';
import '../../features/suivi_foyer/suivi_foyer_page.dart';
import '../../features/tc_catalogue/routes_tc_b.dart';
import '../../features/tc_classe_live/routes_tc_e.dart';
import '../../features/tc_mes_groupes/routes_tc_a.dart';
import '../../features/tc_mushaf/mushaf_page.dart';
import '../../features/tc_mushaf/routes_tc_c.dart';
import '../../features/tc_observation_ui/routes_tc_g.dart';
import '../admin/admin_domaine.dart';
import '../alertes/port_alertes.dart';
import '../config/env.dart';
import '../domain/enums.dart';
import '../dossier/resignature_contrat.dart';
import '../finance/montant.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/transitions.dart';
import '../preferences/presentation_vue.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../tc_groupe/group_home_vm.dart' show RoleEspaceGroupe;
import '../theme/app_gabarit.dart';
import '../widgets/admin_shell.dart';
import '../widgets/bascule_theme.dart';
import '../widgets/bouton_icone.dart';
import '../widgets/entete_page.dart';
import '../widgets/nav_shell.dart';
import '../widgets/page_shell.dart';
import 'billet_salle.dart';
import 'etats_routeur.dart';
import 'redirection.dart';
import 'routes.dart';

/// Le routeur de l'application.
///
/// **Un seul routeur, pour toutes les plateformes**, puisque le Web est ouvert
/// a tous les roles (ADR-008). Aucune branche de navigation par plateforme,
/// aucune arborescence dupliquee entre le mode enfant et le mode standard
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 3).
///
/// `tool/verifier_jetons.dart` echoue si un second fichier du depot construit
/// un `GoRouter`.
final Provider<GoRouter> routeurProvider = Provider<GoRouter>((Ref ref) {
  final _RafraichisseurRoutage rafraichisseur = _RafraichisseurRoutage();

  ref.listen<SessionState>(sessionProvider, (SessionState? _, SessionState _) {
    rafraichisseur.declencher();
  });
  ref.onDispose(rafraichisseur.dispose);

  // --- DASH-EA-PROD : capacite « accueil adulte » ---------------------------
  // La redirection de `/eleve` vers l'Accueil adulte depend d'une capacite
  // lue apres la session : le routeur se reveille quand elle change.
  ref.listen<bool>(capaciteAccueilAdulteProvider, (bool? _, bool _) {
    rafraichisseur.declencher();
  });
  // --- fin du bloc DASH-EA-PROD ---------------------------------------------

  // Q-2 = a : la nouvelle signature du contrat enseignant se lit apres la
  // session (acceptations) ; le routeur se reveille quand elle change.
  ref.listen<bool>(resignatureContratEnseignantProvider, (bool? _, bool _) {
    rafraichisseur.declencher();
  });

  // PUB-1 : la racine d'un visiteur sans session depend de la presentation
  // deja vue sur cet appareil, lue apres le demarrage.
  ref.listen<EtatPresentation>(presentationProvider, (
    EtatPresentation? _,
    EtatPresentation _,
  ) {
    rafraichisseur.declencher();
  });

  // Lu une fois, a la construction du routeur : un role ne change pas sans
  // reconnexion, qui recree ce provider. `routesTcA` n'en a besoin que pour
  // distinguer l'affichage eleve/tuteur au sein de l'Espace Groupe -- la
  // redirection, elle, s'appuie sur le role frais lu a chaque decision.
  final RoleEspaceGroupe sessionRole = _roleEspaceGroupePour(
    ref.read(sessionProvider).role,
  );

  return GoRouter(
    initialLocation: Routes.racine,
    refreshListenable: rafraichisseur,
    redirect: (BuildContext _, GoRouterState etat) {
      final SessionState session = ref.read(sessionProvider);
      // La preference n'est lue que pour la racine d'un visiteur sans
      // session : un compte connecte ne touche jamais ce stockage.
      if (session.porte == PorteAcces.deconnecte &&
          etat.matchedLocation == Routes.racine) {
        ref.read(presentationProvider.notifier).charger();
      }
      return deciderRedirection(
        session: session,
        presentation: ref.read(presentationProvider),
        cheminDemande: etat.matchedLocation,
        billet: etat.extra is BilletSalle ? etat.extra! as BilletSalle : null,
        maintenant: DateTime.now(),
        // Aucune route ne correspond : la page introuvable, pas un renvoi
        // silencieux (mandat Tuteur V1 section 8).
        routeConnue: etat.error == null,
        cheminComplet: etat.uri.toString(),
        retour: etat.uri.queryParameters['retour'],
        resignatureContrat: ref.read(resignatureContratEnseignantProvider),
      );
    },
    // Un chemin qu'aucune route ne sert : une page d'etat dans la charte, qui
    // ramene a l'accueil ou a la connexion selon la session. Jamais l'ecran
    // anglais de go_router ni l'exception brute.
    errorBuilder: (BuildContext _, GoRouterState _) => const PageIntrouvable(),
    routes: <RouteBase>[
      // L'ecran neutre du demarrage, le temps de resoudre la session.
      GoRoute(
        path: Routes.racine,
        builder: (BuildContext _, GoRouterState _) => const EcranDemarrage(),
      ),
      // Les etats transverses qui sont des pages : l'acces refuse (ouvert a
      // tout compte actif) et le hors ligne du demarrage (la seule page d'une
      // session dont le profil n'a pas pu etre lu).
      GoRoute(
        path: Routes.accesRefuse,
        builder: (BuildContext _, GoRouterState _) => const PageAccesRefuse(),
      ),
      GoRoute(
        path: Routes.horsLigne,
        builder: (BuildContext _, GoRouterState _) => const PageHorsLigne(),
      ),
      GoRoute(
        path: Routes.connexion,
        builder: (BuildContext _, GoRouterState _) => const ConnexionPage(),
      ),
      GoRoute(
        path: Routes.connexionEleve,
        builder: (BuildContext _, GoRouterState _) =>
            const EleveConnexionPage(),
      ),
      // Le sous-arbre public de la connexion (contrainte R3) : l'appareil de
      // l'eleve (scanner, saisie du code) et la recuperation d'acces n'ont,
      // par construction, aucune session. Aucun code ni jeton dans l'URL (R7).
      GoRoute(
        path: Routes.connexionEleveScanner,
        builder: (BuildContext _, GoRouterState _) => const ScannerPage(),
      ),
      GoRoute(
        path: Routes.connexionEleveCode,
        builder: (BuildContext _, GoRouterState _) => const SaisieCodePage(),
      ),
      GoRoute(
        path: Routes.connexionRecuperation,
        builder: (BuildContext _, GoRouterState etat) => RecuperationPage(
          courrielInitial: etat.extra is String ? etat.extra! as String : null,
        ),
      ),
      // L'accueil public : la racine d'un visiteur deconnecte y mene
      // (`deciderRedirection`, demande A-1) ; une route protegee demandee
      // sans session va toujours a la connexion, avec son retour.
      GoRoute(
        path: Routes.bienvenue,
        builder: (BuildContext _, GoRouterState _) => const BienvenuePage(),
      ),
      GoRoute(
        path: Routes.inscription,
        builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
      ),
      // Les quatre etapes de l'inscription, sous la porte `inscription` (R4).
      // `/inscription` garde son ecran existant tant que le lot A n'a pas
      // livre les etapes.
      GoRoute(
        path: Routes.inscriptionUsage,
        builder: (BuildContext _, GoRouterState _) => const UsageEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionInvitation,
        builder: (BuildContext _, GoRouterState etat) => InvitationCandidatPage(
          codeInitial: etat.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: Routes.inscriptionIdentite,
        builder: (BuildContext _, GoRouterState _) => const IdentiteEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionGenre,
        builder: (BuildContext _, GoRouterState _) => const GenreEtape(),
      ),
      GoRoute(
        path: Routes.inscriptionRecapitulatif,
        builder: (BuildContext _, GoRouterState _) =>
            const RecapitulatifEtape(),
      ),
      // `AGT-00` : l'entree d'un agent IA (ADR-025). Publique, puisqu'un
      // porteur de jeton n'a par definition aucune session ; elle n'ouvre rien
      // par elle-meme, l'observation se decide dans `main()`.
      GoRoute(
        path: Routes.agentEntree,
        builder: (BuildContext _, GoRouterState _) => const AgentEntreePage(),
      ),
      // Le portail d'attente et ses trois pages. Le sous-arbre entier est
      // ouvert a un compte en attente, la racine seule ne suffirait pas.
      GoRoute(
        path: Routes.attente,
        builder: (BuildContext _, GoRouterState _) => const AttentePage(),
      ),
      GoRoute(
        path: Routes.attenteAccuse,
        builder: (BuildContext _, GoRouterState _) => const AccusePage(),
      ),
      GoRoute(
        path: Routes.attenteContrat,
        builder: (BuildContext _, GoRouterState _) => const ContratPage(),
      ),
      GoRoute(
        path: Routes.attentePiece,
        builder: (BuildContext _, GoRouterState _) => const DepotPiecePage(),
      ),

      // Compte. Cet espace est partage par les roles actifs, mais ses
      // capacites restent celles projetees par la session et le serveur.
      //
      // Le chrome du role l'entoure, **role lu dans la session** : c'est ici
      // que vit « Se deconnecter », donc l'ecran que tout role finit par
      // ouvrir, et il se rendait sans aucune navigation. On y entrait par le
      // pied du tiroir et on n'en ressortait qu'avec le bouton precedent du
      // navigateur.
      GoRoute(
        path: Routes.compte,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ComptePage()),
      ),
      GoRoute(
        path: Routes.compteProfil,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ProfilPersonnelPage()),
      ),
      GoRoute(
        path: Routes.compteReglages,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ReglagesComptePage()),
      ),
      GoRoute(
        path: Routes.compteProfils,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: ProfilsComptePage()),
      ),
      GoRoute(
        path: '${Routes.compteProfilEnfant}/:profilId',
        builder: (BuildContext _, GoRouterState etat) => _CoquilleSecondaire(
          child: ProfilEnfantPage(
            profilId: etat.pathParameters['profilId'] ?? '',
          ),
        ),
      ),
      // « Recevoir mes paiements » (Comptable V1, CPT-F ; spec Finance
      // operationnelle §17, §38) : la surface personnelle de tout
      // beneficiaire avec compte, dans la coquille de son role. Le
      // beneficiaire seul y modifie ses coordonnees (R-FIN-13).
      GoRoute(
        path: Routes.comptePaiementsRecus,
        builder: (BuildContext _, GoRouterState _) =>
            const _CoquilleSecondaire(child: RecevoirPaiementsPage()),
      ),

      // Eleve. Meme arborescence en mode enfant et en mode standard : c'est ce
      // que chaque ecran AFFICHE qui change, jamais la structure (ADR-009).
      // MA-2 : quatre destinations dans les deux presentations (Accueil, Ma
      // classe, Coran, Mon espace) ; les branches suivent l'ordre de
      // `destinationsPour` (Accueil, Ma classe = `/eleve/suivi`, Coran), Mon
      // espace (`/compte`) n'a pas de branche. Aucun chemin ne change.
      StatefulShellRoute.indexedStack(
        builder:
            (BuildContext _, GoRouterState etat, StatefulNavigationShell n) =>
                _CoquilleNavigation(
                  role: AppRole.student,
                  navigationShell: n,
                  chemin: etat.uri.path,
                ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.eleve,
                // DASH-EA-PROD : l'Accueil adulte quand la capacite est
                // servie, jamais d'apres le role.
                redirect: (BuildContext _, GoRouterState _) =>
                    redirectionAccueilEleve(
                      capaciteAccueilAdulte: ref.read(
                        capaciteAccueilAdulteProvider,
                      ),
                    ),
                // DASH-MA-PROD : sinon, l'Accueil du Mode Accessibilite quand
                // la presentation de l'eleve l'est, `ELV-02` sinon.
                builder: (BuildContext _, GoRouterState _) =>
                    const AccueilEleveSelonPresentation(),
              ),
              // --- DASH-EA-PROD : Accueil adulte et historique -------------
              // Dans la branche Accueil : la destination reste allumee.
              ...routesAccueilAdulte(),
              // --- fin du bloc DASH-EA-PROD --------------------------------
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.eleveSuivi,
                builder: (BuildContext _, GoRouterState _) =>
                    const SuiviElevePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.eleveCoran,
                // Pointe sur le nouveau moteur Mushaf (Teaching Core, lot C) :
                // arbitrage entérine au plan d'integration section 3.1 point
                // 1, « la destination /eleve/coran existante pointe sur le
                // nouveau moteur ». `sessionId` reste nul : hors classe.
                builder: (BuildContext _, GoRouterState _) =>
                    const MushafPage(),
              ),
            ],
          ),
        ],
      ),

      // --- DASH-MA-PROD : l'aide de l'eleve ---------------------------------
      // Bloc separe (une autre etape ajoute aussi une route ici). La page
      // d'aide existante (contrat K6, port neutre tant qu'aucun canal n'est
      // publie), dans la coquille de l'eleve pour en ressortir ; le retour
      // ramene a l'Accueil.
      GoRoute(
        path: Routes.eleveAide,
        builder: (BuildContext contexte, GoRouterState _) =>
            _CoquilleSecondaire(
              child: AideComptePage(
                onRetour: () => GoRouter.of(contexte).go(Routes.eleve),
              ),
            ),
      ),

      // Les alias du tuteur (arbre du mandat, mapping des routes sections 3
      // et 4) : des redirections, jamais une seconde page. Declares AVANT la
      // coquille, ils passent en premier ; la garde de role s'applique avant
      // eux, un autre role n'y entre donc pas.
      GoRoute(
        path: Routes.tuteurAccueilAlias,
        redirect: (BuildContext _, GoRouterState _) => Routes.tuteurAccueil,
      ),
      GoRoute(
        path: Routes.tuteurHistoriqueAlias,
        redirect: (BuildContext _, GoRouterState _) => Routes.tuteurSuivi,
      ),
      GoRoute(
        path: '${Routes.tuteurHistoriqueAlias}/observations',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.tuteurSuiviObservations,
      ),
      GoRoute(
        path: Routes.tuteurAjouterEnfantAncien,
        redirect: (BuildContext _, GoRouterState etat) => Uri(
          path: Routes.tuteurAjouterEnfant,
          queryParameters: etat.uri.queryParameters.isEmpty
              ? null
              : etat.uri.queryParameters,
        ).toString(),
      ),
      // Le matching par disponibilites est remplace (`docs/current/00`) : la
      // page reste dans le code, sa route mene au Foyer.
      GoRoute(
        path: Routes.tuteurDisponibilites,
        redirect: (BuildContext _, GoRouterState _) => Routes.tuteurFoyer,
      ),
      // Les reglages par eleve vivent dans la fiche (photo, camera, interface ;
      // lot B, LB-3) : l'ancienne page ferait un second endroit pour la meme
      // fonction (mapping C6, demande B-4). Son adresse mene au Foyer.
      GoRoute(
        path: Routes.tuteurReglages,
        redirect: (BuildContext _, GoRouterState _) => Routes.tuteurFoyer,
      ),
      GoRoute(
        path: '${Routes.tuteurFoyer}/:eleveId/appareils/connexion',
        redirect: (BuildContext _, GoRouterState etat) =>
            Routes.appairerPour(_parametre(etat, 'eleveId')),
      ),
      // Alias de route, propriete du lot C-obs (integration, m8) :
      //
      // L'observation se rejoint par la seance, pas par la classe
      // (`/tc/observation/:seanceId`) : tant que la classe ne sait pas
      // resoudre la seance en cours (lots C et C-obs), cette adresse ramene a
      // la classe. **La classe deleguee (`EspaceGroupePage`) ne porte encore
      // aucun bloc d'observation** : le lot C-obs l'y pose et fait de cet
      // alias une vraie entree (ligne 31 de l'arbre ; revue phase 0, routes
      // D8).
      GoRoute(
        path: '${Routes.tuteurClasses}/:classeId/observer',
        redirect: (BuildContext _, GoRouterState etat) => Routes.classePour(
          _parametre(etat, 'classeId'),
          eleveId: etat.uri.queryParameters['eleve'],
        ),
      ),

      // Tuteur. Quatre branches, quatre destinations : Accueil, Foyer,
      // Historique, Compte (mandat Tuteur V1 section 4 ; structure du mapping
      // des routes, section 5). Une sous-page vit dans la branche de sa
      // destination : la barre reste visible, la destination parente reste
      // active, et le retour systeme revient en arriere au lieu de fermer
      // l'application (contrainte R6). Un segment statique est toujours
      // declare avant son frere dynamique (R5). Aucun secret dans un chemin
      // ni un parametre (R7) : des identifiants, que la RLS borne.
      StatefulShellRoute.indexedStack(
        builder:
            (BuildContext _, GoRouterState etat, StatefulNavigationShell n) =>
                _CoquilleNavigation(
                  role: AppRole.guardian,
                  navigationShell: n,
                  chemin: etat.uri.path,
                ),
        branches: <StatefulShellBranch>[
          // Accueil : notifications, choix d'une classe, classe et ses pages.
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurAccueil,
                pageBuilder: glissee(
                  (GoRouterState _) => const AccueilFamillePage(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: glissee(
                      (GoRouterState _) => const NotificationsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'presentation',
                    pageBuilder: glissee(
                      (GoRouterState _) => const DemandesPresentationPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'demandes',
                    pageBuilder: glissee(
                      (GoRouterState _) => const SuiviDemandesEntree(),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: ':demandeId',
                        pageBuilder: glissee(
                          (GoRouterState etat) => FriseDemandePage(
                            demandeId: _parametre(etat, 'demandeId'),
                          ),
                        ),
                      ),
                      // ECHELLE-FAM-ETATS-1 : le resultat d'une fusion ou
                      // d'un transfert, adresse que le rechargement garde.
                      GoRoute(
                        path: ':demandeId/changement',
                        pageBuilder: glissee(
                          (GoRouterState etat) => ChangementClassePage(
                            demandeId: _parametre(etat, 'demandeId'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'classes/catalogue',
                    pageBuilder: glissee(
                      (GoRouterState etat) =>
                          CatalogueClassesPage(eleveId: _eleve(etat)),
                    ),
                  ),
                  GoRoute(
                    path: 'classes/:classeId',
                    pageBuilder: glissee(
                      (GoRouterState etat) => ClasseTuteurPage(
                        classeId: _parametre(etat, 'classeId'),
                        eleveId: _eleve(etat),
                      ),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'planning',
                        pageBuilder: glissee(
                          (GoRouterState etat) => PlanningClassePage(
                            classeId: _parametre(etat, 'classeId'),
                            eleveId: _eleve(etat),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'travail',
                        pageBuilder: glissee(
                          (GoRouterState etat) => TravailClassePage(
                            classeId: _parametre(etat, 'classeId'),
                            eleveId: _eleve(etat),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'ressources',
                        pageBuilder: glissee(
                          (GoRouterState etat) => RessourcesClassePage(
                            classeId: _parametre(etat, 'classeId'),
                            eleveId: _eleve(etat),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'progression',
                        pageBuilder: glissee(
                          (GoRouterState etat) => ProgressionClassePage(
                            classeId: _parametre(etat, 'classeId'),
                            eleveId: _eleve(etat),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // COM-F : les Messages metier, une pose de l'Accueil (aucune
              // cinquieme destination) ; la voie COM-MSG remplit l'ecran.
              GoRoute(
                path: Routes.tuteurMessages,
                pageBuilder: glissee(
                  (GoRouterState _) =>
                      const MessagesPage(cheminRetour: Routes.tuteurAccueil),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':filId',
                    pageBuilder: glissee(
                      (GoRouterState etat) => MessagesPage(
                        filId: _parametre(etat, 'filId'),
                        cheminRetour: Routes.tuteurMessages,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Foyer : ajout de profil, appareils, emetteur QR, fiche et ses
          // pages ; puis le parcours (C7). Les reglages par eleve ont rejoint
          // la fiche : `/tuteur/reglages` est un alias du Foyer (C6).
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurFoyer,
                pageBuilder: glissee((GoRouterState _) => const FoyerPage()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'ajouter',
                    // `?pour=moi` : le profil eleve du titulaire lui-meme,
                    // indisponible tant que DB-FOY-01 manque (mapping 7.1).
                    pageBuilder: glissee(
                      (GoRouterState etat) =>
                          etat.uri.queryParameters['pour'] == 'moi'
                          ? const CreerMonProfilIndisponible()
                          : const AjouterEnfantPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'appareils',
                    pageBuilder: glissee(
                      (GoRouterState _) => const AppareilsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'recharge',
                    pageBuilder: glissee(
                      (GoRouterState etat) => Builder(
                        builder: (BuildContext context) => RechargeFoyerPage(
                          // Une autre selection (« Reessayer » apres un
                          // echec, FI-8, `&reprise=`) ouvre une recharge
                          // neuve. Sous le resultat, l'adresse garde les
                          // memes parametres (plus `commande`, ignore ici) :
                          // la page et sa commande restent, et le retour du
                          // navigateur montre « Suivre le paiement », jamais
                          // un second « Payer » (revue FI-8).
                          key: ValueKey<String>(
                            Routes.identiteRecharge(etat.uri.queryParameters),
                          ),
                          preselection: <String>{
                            for (final String id
                                in (etat.uri.queryParameters['profils'] ?? '')
                                    .split(','))
                              if (id.isNotEmpty) id,
                          },
                          montantsInitiaux: Routes.montantsDe(
                            etat.uri.queryParameters['montants'],
                          ),
                          // L'abandon ramene d'ou la recharge est partie :
                          // Compte > Paiements (`?depuis=compte`) ou le Foyer.
                          onAbandon: () => GoRouter.of(context).go(
                            etat.uri.queryParameters['depuis'] ==
                                    Routes.origineCompte
                                ? Routes.compteTuteurSousPage('paiements')
                                : Routes.tuteurFoyer,
                          ),
                          // Apres le paiement, le Foyer relit ses finances
                          // (soldes, etats) au lieu de montrer les anciennes.
                          onTerminee: () {
                            ProviderScope.containerOf(
                              context,
                              listen: false,
                            ).invalidate(financesFoyerProvider);
                            GoRouter.of(context).go(Routes.tuteurFoyer);
                          },
                          // Le paiement rend une commande : son resultat
                          // (FI-8), qui relit l'etat, jamais un succes local.
                          onPaye: (String commande) => GoRouter.of(context).go(
                            Routes.resultatRechargePour(
                              commande,
                              recharge: etat.uri.queryParameters,
                            ),
                          ),
                        ),
                      ),
                    ),
                    routes: <RouteBase>[
                      // Le resultat et ses huit etats (FI-8, guide §5.4).
                      GoRoute(
                        path: 'result',
                        pageBuilder: glissee(
                          (GoRouterState etat) => Builder(
                            builder: (BuildContext context) =>
                                ResultatRechargePage(
                                  commandeId:
                                      etat.uri.queryParameters['commande'] ??
                                      '',
                                  // Retour au Foyer : ses finances sont
                                  // relues, jamais les soldes d'avant.
                                  onRevenir: () {
                                    ProviderScope.containerOf(
                                      context,
                                      listen: false,
                                    ).invalidate(financesFoyerProvider);
                                    GoRouter.of(context).go(Routes.tuteurFoyer);
                                  },
                                  onReprendre: (Map<String, Montant> m) =>
                                      GoRouter.of(context).go(
                                        Routes.rechargeReprise(
                                          m,
                                          commande: etat
                                              .uri
                                              .queryParameters['commande'],
                                        ),
                                      ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'appairer/:eleveId',
                    pageBuilder: glissee(
                      (GoRouterState etat) =>
                          AppairagePage(eleveId: _parametre(etat, 'eleveId')),
                    ),
                  ),
                  GoRoute(
                    path: ':eleveId',
                    pageBuilder: glissee(
                      (GoRouterState etat) =>
                          FicheElevePage(eleveId: _parametre(etat, 'eleveId')),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'informations',
                        pageBuilder: glissee(
                          (GoRouterState etat) => InformationsElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'inscription',
                        pageBuilder: glissee(
                          (GoRouterState etat) => InscriptionElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'interface',
                        pageBuilder: glissee(
                          (GoRouterState etat) => InterfaceElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'couleur',
                        pageBuilder: glissee(
                          (GoRouterState etat) => CouleurElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'camera',
                        pageBuilder: glissee(
                          (GoRouterState etat) => CameraElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'acces',
                        pageBuilder: glissee(
                          (GoRouterState etat) => AccesElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'finances',
                        pageBuilder: glissee(
                          (GoRouterState etat) => FinancesElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'mouvements',
                        pageBuilder: glissee(
                          (GoRouterState etat) => MouvementsElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'appareils',
                        pageBuilder: glissee(
                          (GoRouterState etat) => AppareilsElevePage(
                            eleveId: _parametre(etat, 'eleveId'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Le parcours de personnalisation et de choix d'horaire : une
              // tache focalisee de la branche Foyer.
              GoRoute(
                path: '${Routes.tuteurParcours}/:eleveId',
                pageBuilder: glissee(
                  (GoRouterState etat) =>
                      ParcoursOffresPage(eleveId: _parametre(etat, 'eleveId')),
                ),
              ),
            ],
          ),
          // Historique : seances et observations, puis le detail d'une seance
          // (deuxieme racine de la branche).
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurSuivi,
                pageBuilder: glissee(
                  (GoRouterState _) => const SuiviFoyerPage(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'observations',
                    pageBuilder: glissee(
                      (GoRouterState _) => const ObservationsPage(),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '${Routes.tuteurSeances}/:seanceId',
                pageBuilder: glissee(
                  (GoRouterState etat) =>
                      DetailSeancePage(seanceId: _parametre(etat, 'seanceId')),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'observations',
                    pageBuilder: glissee(
                      (GoRouterState etat) => DetailObservationsPage(
                        seanceId: _parametre(etat, 'seanceId'),
                        eleveId: _eleve(etat),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Compte.
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.tuteurCompte,
                pageBuilder: glissee(
                  (GoRouterState _) => const CompteTuteurPage(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'informations',
                    pageBuilder: glissee(
                      (GoRouterState _) => const InformationsComptePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'securite',
                    pageBuilder: glissee(
                      (GoRouterState _) => const SecuriteComptePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'acces',
                    pageBuilder: glissee(
                      (GoRouterState _) => const AccesComptePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'paiements',
                    // « Recharger » ouvre LA recharge du Foyer (FI-7,
                    // guide V4 §4) : jamais un second centre de paiement.
                    pageBuilder: glissee(
                      (GoRouterState _) => Builder(
                        builder: (BuildContext context) => PaiementsComptePage(
                          // `?depuis=compte` : l'abandon revient ici.
                          onRecharger: () =>
                              GoRouter.of(context)
                                  .go(Routes.rechargeDepuisCompte),
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'preferences',
                    pageBuilder: glissee(
                      (GoRouterState _) => const PreferencesComptePage(),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'apparence',
                        pageBuilder: glissee(
                          (GoRouterState _) => const ApparenceComptePage(),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'aide',
                    pageBuilder: glissee(
                      (GoRouterState _) => const AideComptePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'informations-legales',
                    pageBuilder: glissee(
                      (GoRouterState _) =>
                          const InformationsLegalesComptePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'consentements',
                    pageBuilder: glissee(
                      (GoRouterState _) => const ConsentementObservationPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Enseignant.
      StatefulShellRoute.indexedStack(
        builder:
            (BuildContext _, GoRouterState etat, StatefulNavigationShell n) =>
                _CoquilleNavigation(
                  role: AppRole.teacher,
                  navigationShell: n,
                  chemin: etat.uri.path,
                ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.enseignantJournee,
                builder: (BuildContext _, GoRouterState _) =>
                    const JourneePage(),
                routes: <RouteBase>[
                  // DASH-ENS-ROUTE : « Voir tout » de « A terminer ».
                  GoRoute(
                    path: 'a-terminer',
                    builder: (BuildContext _, GoRouterState _) =>
                        const ListeATerminerPage(),
                  ),
                  // REMPL-1 : l'ecran commun des remplacements, ou mene
                  // « Voir tout » des remplacements de la Journee.
                  GoRoute(
                    path: 'remplacements',
                    builder: (BuildContext _, GoRouterState _) =>
                        const RemplacementsPage(),
                  ),
                  // DASH-ENS-LISTES : toutes les « Alertes utiles ».
                  GoRoute(
                    path: 'alertes',
                    builder: (BuildContext _, GoRouterState _) =>
                        const ListeAlertesPage(),
                  ),
                ],
              ),
              // COM-F : poses de la branche Aujourd'hui (aucune destination
              // ajoutee, E10) : les notifications de la cloche, la
              // `NotificationsPage` existante, et la Communaute enseignants,
              // raccourci d'Aujourd'hui (Q2).
              GoRoute(
                path: Routes.enseignantNotifications,
                builder: (BuildContext contexte, GoRouterState _) =>
                    NotificationsPage(
                      onRetour: () =>
                          GoRouter.of(contexte).go(Routes.enseignantJournee),
                    ),
              ),
              GoRoute(
                path: Routes.enseignantCommunaute,
                builder: (BuildContext _, GoRouterState _) =>
                    const CommunautePage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':publicationId',
                    builder: (BuildContext _, GoRouterState etat) =>
                        CommunautePage(
                          publicationId: _parametre(etat, 'publicationId'),
                        ),
                  ),
                ],
              ),
            ],
          ),
          // Classes, deuxieme branche (E10) : l'ordre des branches est celui
          // de `destinationsPour(AppRole.teacher)`.
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.enseignantClasses,
                builder: (BuildContext _, GoRouterState _) =>
                    const MesClassesPage(),
              ),
              // COM-F : les Messages metier de l'enseignant, une pose de la
              // branche Classes (aucune destination ajoutee, E10).
              GoRoute(
                path: Routes.enseignantMessages,
                builder: (BuildContext _, GoRouterState _) =>
                    const MessagesPage(cheminRetour: Routes.enseignantClasses),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':filId',
                    builder: (BuildContext _, GoRouterState etat) =>
                        MessagesPage(
                          filId: _parametre(etat, 'filId'),
                          cheminRetour: Routes.enseignantMessages,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.enseignantCreneaux,
                builder: (BuildContext _, GoRouterState _) =>
                    const CreneauxPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.enseignantProfil,
                builder: (BuildContext _, GoRouterState _) =>
                    const ProfilEnseignantPage(),
              ),
              // Mes revenus (FI-10) : une pose de la branche Profil, ou elle
              // s'ouvre ; la barre garde Profil actif.
              GoRoute(
                path: Routes.enseignantRevenus,
                builder: (BuildContext _, GoRouterState _) =>
                    const RevenusEnseignantPage(),
              ),
            ],
          ),
        ],
      ),

      // Les quatre poses de l'enseignant, HORS de la coquille et c'est le
      // point : la barre de l'enseignant en tient quatre destinations (E10,
      // decision du 26/09/2026 qui remplace ADR-027), et le cahier est
      // l'ecran de sortie de seance, sans barre qui offrirait de partir
      // ailleurs. Une pose s'atteint depuis un ecran puis se quitte.
      //
      // La forme des chemins est ecrite ici avec ses parametres, et calculee
      // ailleurs par `Routes.cahierPour`, `groupePour` et `revuePour` : les deux
      // doivent rester d'accord, et `test/router/redirection_test.dart` mesure
      // les deux cotes -- que chaque constructeur produise bien un chemin sous
      // `/enseignant`, et qu'un tuteur qui le demande reparte chez lui.
      GoRoute(
        path: Routes.enseignantBienvenue,
        builder: (BuildContext _, GoRouterState _) =>
            const BienvenueEnseignantPage(),
      ),
      // Q-2 = a : la page du contrat, ouverte seulement quand l'enseignant
      // doit signer la nouvelle version (`deciderRedirection`).
      GoRoute(
        path: Routes.enseignantContrat,
        builder: (BuildContext _, GoRouterState _) => const ContratPage(),
      ),
      GoRoute(
        path: '${Routes.enseignantSeance}/:seanceId/cahier',
        builder: (BuildContext _, GoRouterState etat) =>
            CahierPage(seanceId: etat.pathParameters['seanceId'] ?? ''),
      ),
      GoRoute(
        path: '${Routes.enseignantGroupe}/:groupeId',
        builder: (BuildContext _, GoRouterState etat) => FicheGroupePage(
          groupeId: etat.pathParameters['groupeId'] ?? '',
          // EN-4 : toute la ligne d'un eleve ouvre sa fiche (ENS-11).
          onOuvrirEleve: FicheGroupePage.ficheEleve,
        ),
      ),
      GoRoute(
        path: '${Routes.enseignantGroupe}/:groupeId/revue',
        builder: (BuildContext _, GoRouterState etat) =>
            RevueGroupePage(groupeId: etat.pathParameters['groupeId'] ?? ''),
      ),
      // COM-F : publier une annonce de Classe, tache focalisee hors de la
      // coquille comme l'Espace Classe d'ou elle part (voie COM-ANN).
      GoRoute(
        path: '${Routes.enseignantGroupe}/:groupeId/annonce',
        builder: (BuildContext _, GoRouterState etat) =>
            PublierAnnonceClassePage(groupeId: _parametre(etat, 'groupeId')),
      ),

      // Controleur : quatre destinations, Controle, Historique, Echanges,
      // Compte (C13, document 08 du 27/09/2026, qui remplace « une seule
      // destination, sans barre »). Les trois premieres sont les branches,
      // dans l'ordre de `destinationsPour(AppRole.controller)` ; Compte est
      // `/compte`, partage, rejoint par `go`. `CTR-02`, la salle, vit hors de
      // l'arbre et sans barre (ADR-005).
      StatefulShellRoute.indexedStack(
        builder:
            (BuildContext _, GoRouterState etat, StatefulNavigationShell n) =>
                _CoquilleNavigation(
                  role: AppRole.controller,
                  navigationShell: n,
                  chemin: etat.uri.path,
                ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.controleur,
                builder: (BuildContext _, GoRouterState _) =>
                    const ControleControleurPage(),
              ),
              // COM-F : les notifications de la cloche du controleur, la
              // `NotificationsPage` existante, pose de la branche Controle.
              GoRoute(
                path: Routes.controleurNotifications,
                builder: (BuildContext contexte, GoRouterState _) =>
                    NotificationsPage(
                      onRetour: () =>
                          GoRouter.of(contexte).go(Routes.controleur),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.controleurHistorique,
                builder: (BuildContext _, GoRouterState _) =>
                    const HistoriqueControleurPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.controleurEchanges,
                builder: (BuildContext _, GoRouterState etat) =>
                    EchangesControleurPage(
                      missionOuverte: etat.uri.queryParameters['mission'],
                    ),
              ),
            ],
          ),
        ],
      ),

      // Admin. Huit domaines (gel d'architecture,
      // `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`), routes NESTED par domaine.
      // Chaque route porte son domaine explicitement, comme
      // `_CoquilleSecondaire` portait deja son role -- ni l'un ni l'autre ne
      // devine depuis le chemin courant. Direction n'a **aucune route ici** :
      // l'audit interdit une page construite pour un domaine sans fonction
      // reelle (`AdminDomaine.chemin` y est nul, `AdminShell` le rend inerte).
      // Finance a ses routes depuis FI-1b (guide Finance V4 du directeur,
      // 02/10/2026) : sans port branche, chaque onglet dit honnetement
      // « Pas encore disponible ».
      GoRoute(
        path: Routes.admin,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.accueil,
          child: TableauDeBordPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminAlertes,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.accueil,
          sousPage: true,
          child: AlertesPage(),
        ),
      ),
      // La racine du domaine Operations n'est pas une page : elle renvoie a
      // sa fonction primaire, jamais une seconde implementation. Groupes en
      // est la fonction primaire depuis le pivot du 19 septembre 2026
      // (migration `0017`) : c'est le noyau du produit, l'Attribution et les
      // Demandes restent des fonctions secondaires atteignables depuis
      // l'Accueil.
      // AD-X : la racine mene a l'Espace de traitement (`ADM-18`), comme
      // l'image ADMIN-SHELL-02 du directeur (« Operations » actif sur la file
      // reunie). Les Classes (`ADM-09`) restent a leur adresse, reliees par
      // la sous-navigation Operations (`ongletsOperations()`).
      GoRoute(
        path: Routes.adminOperations,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminOperationsTraitement,
      ),
      GoRoute(
        path: Routes.adminOperationsTraitement,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: TraitementPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminOperationsGroupes,
        builder: (BuildContext _, GoRouterState etat) => _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          // ECHELLE-ADM-PILOTAGE-1 : `?etat=attente` ouvre la liste sur les
          // classes en attente d'enseignant.
          child: GroupesPage(
            attenteInitiale: etat.uri.queryParameters['etat'] == 'attente',
          ),
        ),
      ),
      // ECHELLE-ADM-PILOTAGE-1 : le tableau de pilotage par horaire, atteint
      // depuis l'Accueil (raccourci « Pilotage des horaires »).
      GoRoute(
        path: Routes.adminOperationsPilotage,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: PilotagePage(),
        ),
      ),
      GoRoute(
        path: Routes.adminOperationsAttributions,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: AttributionPage(),
        ),
      ),
      // La reaffectation (demandes) reste atteinte depuis l'Accueil, jamais
      // depuis un second niveau de la sidebar
      // (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md).
      GoRoute(
        path: Routes.adminOperationsDemandes,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: DemandesPage(),
        ),
      ),
      // COM-F : l'Administration des communications, sous Operations
      // (QUESTIONS Q4), jamais un neuvieme domaine. Trois onglets pairs
      // (`ongletsCommunications`) ; la racine renvoie au premier.
      GoRoute(
        path: Routes.adminOperationsCommunications,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminCommunicationsAnnonces,
      ),
      GoRoute(
        path: Routes.adminCommunicationsAnnonces,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: AdministrationCommunicationsPage(
            onglet: OngletCommunications.annonces,
          ),
        ),
      ),
      GoRoute(
        path: Routes.adminCommunicationsModeration,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: AdministrationCommunicationsPage(
            onglet: OngletCommunications.moderation,
          ),
        ),
      ),
      // COM-FUS : l'onglet Messages monte la page de la voie COM-MSG-2
      // (`MessagesAdminPage`), meme sous-navigation des trois onglets.
      GoRoute(
        path: Routes.adminCommunicationsMessages,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: MessagesAdminPage(),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: ':filId',
            builder: (BuildContext _, GoRouterState etat) => _CoquilleAdmin(
              domaine: AdminDomaine.operations,
              child: MessagesAdminPage(filId: _parametre(etat, 'filId')),
            ),
          ),
        ],
      ),
      // COM-F : la cloche de l'en-tete admin ouvre la `NotificationsPage`
      // existante, transverse aux domaines (aucun domaine actif).
      GoRoute(
        path: Routes.adminNotifications,
        builder: (BuildContext contexte, GoRouterState _) => _CoquilleAdmin(
          domaine: null,
          notificationsOuvertes: true,
          child: NotificationsPage(
            onRetour: () => GoRouter.of(contexte).go(Routes.admin),
          ),
        ),
      ),
      // COM-F : Le Studio (QUESTIONS Q1), hors de l'`AdminShell` : sa propre
      // navigation viendra de la voie COM-STU, la sortie ramene a `/admin`.
      // `/admin/studio/canaux` n'a pas de page : elle renvoie a la vue des
      // canaux du Studio (`/admin/studio` est Aujourd'hui, COM-STU-2).
      // COM-RC (revue COM-R, R-05) : comme toute coquille admin, Le Studio
      // porte la cloche, la bascule clair / sombre et l'acces au compte
      // (`_ActionsStudio`), et son identite « Administrateur » dans sa
      // colonne (`CoquilleStudio.onCompte`).
      GoRoute(
        path: Routes.adminStudio,
        builder: (BuildContext _, GoRouterState _) =>
            const _ActionsStudio(child: StudioPage()),
      ),
      GoRoute(
        path: Routes.adminStudioCanaux,
        redirect: (BuildContext _, GoRouterState _) =>
            adresseVueStudio(VueStudio.canaux),
      ),
      GoRoute(
        path: '${Routes.adminStudioCanaux}/:canalId',
        builder: (BuildContext _, GoRouterState etat) => _ActionsStudio(
          child: StudioPage(canalId: _parametre(etat, 'canalId')),
        ),
      ),
      // OFFRES-ADM-1 : atteinte depuis l'Accueil (raccourci « Classes a
      // ouvrir »), comme les Demandes.
      GoRoute(
        path: Routes.adminOperationsRegroupements,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.operations,
          child: RegroupementsPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPersonnesReprises,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.personnes,
          child: ReprisesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPersonnesInvitations,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.personnes,
          child: InvitationsPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPersonnes,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPersonnesDossiers,
      ),
      GoRoute(
        path: Routes.adminPersonnesDossiers,
        // Le dossier vise depuis l'Accueil passe par `extra`, jamais par
        // l'URL : un identifiant de personne n'a rien a faire dans un
        // historique de navigateur (spec l.1933).
        builder: (BuildContext _, GoRouterState etat) => _CoquilleAdmin(
          domaine: AdminDomaine.personnes,
          child: DossiersPage(
            profilId: switch (etat.extra) {
              final String id => id,
              _ => null,
            },
          ),
        ),
      ),
      // `ADM-08` : les comptes, atteints depuis l'Accueil
      // (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md).
      // Sans cet ecran, l'administration n'avait aucun moyen de voir une
      // personne inscrite qui n'a pas encore depose sa piece : c'est le
      // defaut mesure le 18 septembre 2026.
      GoRoute(
        path: Routes.adminPersonnesComptes,
        builder: (BuildContext _, GoRouterState etat) => _CoquilleAdmin(
          domaine: AdminDomaine.personnes,
          // DASH-ADM-ECHUS : `?filtre=echus` ouvre la page sur les acces echus.
          child: ComptesPage(
            echusSeulement: etat.uri.queryParameters['filtre'] == 'echus',
          ),
        ),
      ),
      // Domaine Pedagogie : cinq fonctions pairs, jamais une secondaire
      // atteinte seulement depuis l'Accueil comme Operations/Personnes --
      // voir `SousNavigationDomaine`. Diagnostics est la fonction primaire,
      // meme pattern que Groupes pour Operations : la file la plus
      // actionnable du domaine.
      GoRoute(
        path: Routes.adminPedagogie,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPedagogieDiagnostics,
      ),
      GoRoute(
        path: Routes.adminPedagogieDiagnostics,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: DiagnosticsPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieProgression,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: ProgressionPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieEvaluations,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: EvaluationsPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieBibliotheque,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: CataloguePage(),
        ),
      ),
      GoRoute(
        path: '${Routes.adminPedagogieBibliotheque}/:supportId',
        builder: (BuildContext _, GoRouterState etat) => _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: FichePage(supportId: _parametre(etat, 'supportId')),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieProgrammes,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: ProgrammesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminPedagogieQualite,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.pedagogie,
          child: QualitePage(),
        ),
      ),
      // Domaine Finance (FI-1b) : la racine EST la Vue globale (route
      // canonique « Vue d'ensemble » du contrat metier), jamais une
      // redirection ; Politiques commerciales est son onglet pair
      // (`ongletsFinance()`).
      GoRoute(
        path: Routes.adminFinance,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.finance,
          child: FinancePage(onglet: OngletFinance.vueGlobale),
        ),
      ),
      GoRoute(
        path: Routes.adminFinancePolitiques,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.finance,
          child: FinancePage(onglet: OngletFinance.politiques),
        ),
      ),
      // Reserve et delegation (Comptable V1, CPT-F ; spec Finance
      // operationnelle §37) : le troisieme onglet du meme domaine, jamais un
      // second systeme Finance. La voie CPT-DIR remplit sa page.
      GoRoute(
        path: Routes.adminFinanceReserveDelegation,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.finance,
          child: FinancePage(onglet: OngletFinance.reserveDelegation),
        ),
      ),
      // A valider (CPT-VAL-1, decision Q-8 = (a) du 05/10) : le quatrieme
      // onglet du meme domaine.
      GoRoute(
        path: Routes.adminFinanceAValider,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.finance,
          child: FinancePage(onglet: OngletFinance.aValider),
        ),
      ),
      // Domaine Configuration : la racine redirige vers Regles, sa fonction
      // primaire -- meme mecanique que Pedagogie plus haut. Academie, Classe
      // en ligne, Notifications et Localisation n'ont pas de route : aucune
      // fonction reelle derriere elles, voir `ongletsConfiguration()`.
      GoRoute(
        path: Routes.adminConfiguration,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminConfigurationRegles,
      ),
      GoRoute(
        path: Routes.adminConfigurationRegles,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.configuration,
          child: ReglesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminConfigurationFonctionnalites,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.configuration,
          child: FonctionnalitesPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminConfigurationConservationDonnees,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.configuration,
          child: ConservationDonneesPage(),
        ),
      ),
      // AD-9 : pas de redirect, la capacite arrive de facon asynchrone ; la
      // garde est dans la page (accesRefuse / indisponible).
      GoRoute(
        path: Routes.adminConfigurationPolitiqueRevueKyc,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.configuration,
          child: PolitiqueRevueKycPage(),
        ),
      ),
      GoRoute(
        path: Routes.adminSecuriteAudit,
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminSecuriteAuditJournal,
      ),
      GoRoute(
        path: Routes.adminSecuriteAuditJournal,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.securite,
          child: JournalPage(),
        ),
      ),
      // `ADM-07` : l'acces des agents IA (ADR-025), atteint depuis l'Accueil.
      GoRoute(
        path: Routes.adminSecuriteAuditAccesAgents,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.securite,
          child: AccesAgentsPage(),
        ),
      ),
      // L'historique des observations (complement observation du mandat
      // Tuteur V1, section 8), onglet pair du Journal (`ongletsSecurite()`).
      GoRoute(
        path: Routes.adminSecuriteAuditObservations,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.securite,
          child: ObservationsAdminPage(),
        ),
      ),
      // ECHELLE-CTRL-DIRECT-1 : le tirage des controles, onglet pair du
      // Journal et des observations (`ongletsSecurite()`).
      GoRoute(
        path: Routes.adminSecuriteAuditTirages,
        builder: (BuildContext _, GoRouterState _) => const _CoquilleAdmin(
          domaine: AdminDomaine.securite,
          child: TiragePage(),
        ),
      ),

      // Anciennes routes plates : des redirections, jamais une seconde page
      // (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md, table de compatibilite).
      GoRoute(
        path: '/admin/tableau-de-bord',
        redirect: (BuildContext _, GoRouterState _) => Routes.admin,
      ),
      GoRoute(
        path: '/admin/dossiers',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPersonnesDossiers,
      ),
      GoRoute(
        path: '/admin/comptes',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminPersonnesComptes,
      ),
      GoRoute(
        path: '/admin/attribution',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminOperationsAttributions,
      ),
      GoRoute(
        path: '/admin/demandes',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminOperationsDemandes,
      ),
      GoRoute(
        path: '/admin/journal',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminSecuriteAuditJournal,
      ),
      GoRoute(
        path: '/admin/acces-agents',
        redirect: (BuildContext _, GoRouterState _) =>
            Routes.adminSecuriteAuditAccesAgents,
      ),

      // Comptable (Comptable V1, CPT-F) : quatre destinations, Aujourd'hui,
      // Paiements, Tresorerie, Compte (spec Finance operationnelle §45 ;
      // `20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md` §3). Les trois
      // premieres sont les branches, dans l'ordre de
      // `destinationsPour(AppRole.accountant)` ; Compte est `/compte`,
      // partage, rejoint par `go`. Le second niveau (A effectuer,
      // Contractuels, Beneficiaires ; Coffres, Encaissements, Rapprochement)
      // est en onglets DANS la page, et chaque page de detail est une route
      // imbriquee de sa branche. Les constructeurs ne recoivent que des
      // chaines (identifiant, filtre brut) : la page lit son port. Les pages
      // « en preparation » sont remplacees par les voies (CPT-FUS) sans que
      // ces routes changent. ADR-003 est remplace par la spec du 04/10/2026.
      StatefulShellRoute.indexedStack(
        builder:
            (BuildContext _, GoRouterState etat, StatefulNavigationShell n) =>
                _CoquilleNavigation(
                  role: AppRole.accountant,
                  navigationShell: n,
                  chemin: etat.uri.path,
                ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.comptable,
                builder: (BuildContext _, GoRouterState etat) =>
                    AujourdhuiComptablePage(
                      vue: etat
                          .uri
                          .queryParameters[Routes.parametreVueComptable],
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.comptablePaiements,
                builder: (BuildContext _, GoRouterState etat) =>
                    PaiementsAEffectuerPage(
                      filtre: etat
                          .uri
                          .queryParameters[Routes.parametreFiltreComptable],
                      type: etat
                          .uri
                          .queryParameters[Routes.parametreTypeComptable],
                      classe: etat
                          .uri
                          .queryParameters[Routes.parametreClasseComptable],
                    ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'obligation/:obligationId',
                    builder: (BuildContext _, GoRouterState etat) =>
                        DetailPaiementPage(
                          obligationId: _parametre(etat, 'obligationId'),
                        ),
                  ),
                  GoRoute(
                    path: 'contractuels',
                    builder: (BuildContext _, GoRouterState etat) =>
                        ContractuelsPage(
                          onglet: etat.uri.queryParameters['onglet'],
                        ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'nouvelle',
                        builder: (BuildContext _, GoRouterState _) =>
                            const NouvelleObligationPage(),
                      ),
                      GoRoute(
                        path: 'obligation/:obligationId',
                        builder: (BuildContext _, GoRouterState etat) =>
                            ObligationContractuelPage(
                              obligationId: _parametre(etat, 'obligationId'),
                            ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'beneficiaires',
                    builder: (BuildContext _, GoRouterState etat) =>
                        BeneficiairesPage(
                          filtre: etat
                              .uri
                              .queryParameters[Routes.parametreFiltreComptable],
                        ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: ':beneficiaireId',
                        builder: (BuildContext _, GoRouterState etat) =>
                            ProfilPaiementPage(
                              beneficiaireId: _parametre(
                                etat,
                                'beneficiaireId',
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <GoRoute>[
              GoRoute(
                path: Routes.comptableTresorerie,
                builder: (BuildContext _, GoRouterState etat) => TresoreriePage(
                  action:
                      etat.uri.queryParameters[Routes.parametreActionComptable],
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'encaissements',
                    builder: (BuildContext _, GoRouterState etat) =>
                        EncaissementsPage(
                          filtre: etat
                              .uri
                              .queryParameters[Routes.parametreFiltreComptable],
                        ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: ':encaissementId',
                        builder: (BuildContext _, GoRouterState etat) =>
                            DetailEncaissementPage(
                              encaissementId: _parametre(
                                etat,
                                'encaissementId',
                              ),
                            ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'rapprochement',
                    builder: (BuildContext _, GoRouterState _) =>
                        const RapprochementPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Teaching Core (plan d'integration, etape 7). Cinq lots, cinq
      // fonctions qui RETOURNENT des routes sans jamais construire de
      // `GoRouter` (decision D-04) : `routesTcA`, `routesTcB`, `routesTcC`,
      // `routesTcE`, `routesTcG`. Chaque chemin porte son autorisation de
      // role dans `redirection.dart` (`_teachingCoreAutorise`), sans quoi
      // `/tc/` serait inatteignable pour tous les roles.
      ...routesTcA(role: sessionRole),
      ...routesTcB(),
      ...routesTcC(),
      ...routesTcE(),
      ...routesTcG(),

      // Salle. Le billet passe par `extra`, jamais par l'URL (ADR-005).
      //
      // `deciderRedirection` a deja refuse l'entree sans billet presentable :
      // arriver ici avec `extra` vide est donc impossible par le routeur. Le
      // repli sur une seance vide existe quand meme, et il est sur -- le
      // backend refusera le jeton, et l'ecran affichera son impasse d'acces
      // plutot que de lever.
      GoRoute(
        path: Routes.salle,
        builder: (BuildContext _, GoRouterState etat) => SallePage(
          seanceId: etat.extra is BilletSalle
              ? (etat.extra! as BilletSalle).sessionId
              : '',
          preparation:
              etat.extra is BilletSalle &&
              (etat.extra! as BilletSalle).preparation,
          groupeId: etat.extra is BilletSalle
              ? (etat.extra! as BilletSalle).groupeId
              : null,
        ),
      ),

      // CTR-03, la sortie de la salle d'observation : tache focalisee, sans
      // coquille (UX_REVIEW_08 n° 1 c). CT-4.
      GoRoute(
        path: Routes.controleurCompteRendu,
        builder: (BuildContext _, GoRouterState etat) => GardeControle(
          // La visite par l'adresse (`?seance=`, revue CT-R B1).
          child: CompteRenduControlePage(
            seanceId: etat.uri.queryParameters['seance'],
          ),
        ),
      ),
      // CTR-03A, l'observation structuree (CT-5) : « Ajouter une
      // observation » ou « Signaler un point important », porte par
      // l'adresse (`?choix=`), pour survivre a un rechargement.
      GoRoute(
        path: Routes.controleurObservation,
        builder: (BuildContext _, GoRouterState etat) => GardeControle(
          child: ObservationControlePage(
            seanceId: etat.uri.queryParameters['seance'],
            choix: choixObservationDepuis(etat.uri.queryParameters, etat.extra),
          ),
        ),
      ),

      // Galerie de developpement, absente des versions de production.
      if (Env.galerieActive)
        GoRoute(
          path: Routes.galerie,
          builder: (BuildContext _, GoRouterState _) => const GaleriePage(),
        ),
      if (Env.galerieActive)
        GoRoute(
          path: Routes.galerieCompte,
          builder: (BuildContext _, GoRouterState _) =>
              const CompteGaleriePage(),
        ),

      // La salle de seance en demonstration : aucune route en production.
      ...routesDemoSalle(Env.environnement),
      ...routesDemoClasse(Env.environnement),
      ...routesDemoEnseignant(Env.environnement),
      ...routesDemoControleur(Env.environnement),
      ...routesDemoAccessibilite(Env.environnement),
      ...routesDemoAdulte(Env.environnement),
      ...routesDemoFinance(Env.environnement),
      ...routesDemoCommunications(Env.environnement),
      ...routesDemoComptable(Env.environnement),
    ],
  );
});

/// Un parametre de chemin, ou la chaine vide (jamais une exception : un
/// identifiant absent donne un ecran « introuvable », pas un plantage).
String _parametre(GoRouterState etat, String nom) =>
    etat.pathParameters[nom] ?? '';

/// L'eleve concerne (`?eleve=`), s'il est donne. **Jamais une
/// autorisation** : la selection se replie sur un profil du foyer (contrat
/// K1), la RLS decide.
String? _eleve(GoRouterState etat) {
  final String? brut = etat.uri.queryParameters['eleve'];
  return brut == null || brut.isEmpty ? null : brut;
}

/// Reveille go_router quand la session change.
///
/// go_router attend un [Listenable] ; Riverpod fournit un flux d'etats. Ce pont
/// existe uniquement pour relier les deux, il ne porte aucune logique.
class _RafraichisseurRoutage extends ChangeNotifier {
  void declencher() => notifyListeners();
}

/// Racine de l'application, branchee sur le routeur.
class AppRouterDelegateHote extends ConsumerWidget {
  /// Cree l'hote du routeur.
  const AppRouterDelegateHote({required this.constructeur, super.key});

  /// Construit l'application a partir de la configuration de routage.
  final Widget Function(BuildContext context, GoRouter routeur) constructeur;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      constructeur(context, ref.watch(routeurProvider));
}

/// Les routes atteignables, exposees pour les tests d'arborescence.
@visibleForTesting
List<String> cheminsDeclares(GoRouter routeur) {
  final List<String> chemins = <String>[];
  void parcourir(List<RouteBase> routes, String prefixe) {
    for (final RouteBase route in routes) {
      if (route is GoRoute) {
        final String complet = route.path.startsWith('/')
            ? route.path
            : '$prefixe/${route.path}';
        chemins.add(complet);
        parcourir(route.routes, complet);
      } else if (route is ShellRouteBase) {
        // Les branches d'une coquille : leurs routes sont des routes de
        // premier niveau comme les autres.
        parcourir(route.routes, prefixe);
      }
    }
  }

  parcourir(routeur.configuration.routes, '');
  return chemins;
}

/// Redirige vers la racine du role, sans passer par une route intermediaire.
@visibleForTesting
String racineDe(AppRole? role) =>
    role == null ? Routes.connexion : Routes.racinePour(role);

/// Traduit le role de session en role d'Espace Groupe (Teaching Core, lot A).
///
/// **Un role different, pas un doublon** : `AppRole` vient du JWT et porte
/// six valeurs, `RoleEspaceGroupe` n'en porte que quatre et decide
/// uniquement de ce que l'Espace Groupe affiche. Le controleur et le
/// comptable n'atteignent jamais `/tc/groupes` (`_teachingCoreAutorise` dans
/// `redirection.dart` le refuse), le repli `eleve` ici ne sert donc qu'a
/// satisfaire le type : aucun de ces deux roles ne le lit jamais.
@visibleForTesting
RoleEspaceGroupe roleEspaceGroupePour(AppRole? role) =>
    _roleEspaceGroupePour(role);

RoleEspaceGroupe _roleEspaceGroupePour(AppRole? role) => switch (role) {
  AppRole.guardian => RoleEspaceGroupe.tuteur,
  AppRole.teacher => RoleEspaceGroupe.enseignant,
  AppRole.admin => RoleEspaceGroupe.admin,
  AppRole.student ||
  AppRole.controller ||
  AppRole.accountant ||
  null => RoleEspaceGroupe.eleve,
};

/// La coquille de navigation d'un role, autour des branches qui sont ses
/// destinations.
///
/// Le role est connu par construction de la route : chaque coquille est câblée
/// a un seul role. Depuis MA-2, l'eleve garde ses quatre destinations dans
/// les deux presentations, sur les memes branches (ADR-009).
/// Le chrome d'un role autour d'un ecran **hors** de sa barre.
///
/// `ADM-06`, `ADM-07` et `ADM-08` ne sont pas des destinations de premier
/// niveau, la barre etant plafonnee a quatre entrees (et gelee a trois pour
/// l'enseignant, `TEACHER_PARALLEL_BASELINE.md` §3.1), mais ils ont besoin de
/// son chrome pour qu'on puisse en **sortir**. Sans lui, on y entre et on n'en
/// revient qu'avec le bouton precedent du navigateur : c'est precisement le
/// reproche fait a l'interface le 18 septembre 2026, et `ADM-08` venait de le
/// reproduire le jour meme de sa creation.
///
/// **L'espace « Mon compte » est le meme cas, et il avait ete oublie** : c'est
/// l'ecran ou vit « Se deconnecter », donc celui que tout role finit par
/// ouvrir, et il se rendait sans le moindre chrome. On y arrivait par le pied
/// du tiroir et on n'en ressortait plus. Il est partage par tous les roles, le
/// role s'y lit donc toujours dans la session, jamais câble par la route.
///
/// Aucune destination n'est active ici : `indexActif` est nul, et le chrome
/// rend alors ses entrees sans en surligner aucune.
class _CoquilleSecondaire extends ConsumerWidget {
  const _CoquilleSecondaire({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void aller(String chemin) => GoRouter.of(context).go(chemin);

    final SessionState session = ref.watch(sessionProvider);
    final AppRole? effectif = session.role;

    // Sans role connu, il n'y a pas de chrome a rendre : l'ecran se suffit.
    if (effectif == null) {
      return child;
    }

    // L'admin n'a plus de coquille `NavShell` depuis le lot IA-01 : « Mon
    // compte » reste transverse aux huit domaines
    // (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`), donc aucun domaine n'y est actif.
    // Sans ce branchement, un admin qui ouvrait `/compte` retombait sur
    // `destinationsPour(role: AppRole.admin)`, videe par ce meme lot, et
    // perdait tout chrome -- exactement le defaut mesure le 18 septembre
    // 2026 sur ce meme ecran.
    if (effectif == AppRole.admin) {
      return AdminShell(
        domaines: domainesAdmin(voitDirection: session.peutVoirDirection),
        domaineActif: null,
        onAller: aller,
        onCompte: () => aller(Routes.compte),
        // Retour vers l'Accueil admin partout (spec section 26 ter, Q14).
        onRetour: () => aller(Routes.admin),
        // COM-F : la cloche et Le Studio, comme sur toute page admin.
        onNotifications: () => aller(Routes.adminNotifications),
        onStudio: () => aller(Routes.adminStudio),
        child: child,
      );
    }

    final List<Destination> destinations = destinationsPour(
      role: effectif,
      // Seul l'eleve a deux formes de destinations (ADR-009) ; pour les
      // autres roles le mode ne change rien.
      mode: session.interfaceMode,
    );
    // Toutes les pages de cette coquille sont des pages `/compte*` : quand le
    // role porte le compte parmi ses destinations (l'eleve), c'est elle qui
    // est active, et la barre basse reste la pour en sortir.
    final int compte = destinations.indexWhere(
      (Destination d) => d.chemin == Routes.compte,
    );

    return NavShell(
      destinations: destinations,
      indexActif: compte == -1 ? null : compte,
      onAller: aller,
      secondaires: secondairesPour(role: effectif),
      onAllerSecondaire: aller,
      // Rail a libelles hors tuteur, comme avant le chantier Tuteur V1.
      libellesDansLeRail: effectif != AppRole.guardian,
      child: child,
    );
  }
}

class _CoquilleNavigation extends ConsumerWidget {
  /// Cree la coquille d'un role.
  const _CoquilleNavigation({
    required this.role,
    required this.navigationShell,
    required this.chemin,
  });

  /// Le role dont cette coquille tient les destinations.
  final AppRole role;

  /// Les branches de la coquille, pilotées par `go_router`.
  final StatefulNavigationShell navigationShell;

  /// Le chemin courant : il dit si l'ecran est une tache focalisee.
  final String chemin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InterfaceMode mode = ref.watch(
      sessionProvider.select((SessionState s) => s.interfaceMode),
    );
    // MA-NAV-1 : la barre du Mode Accessibilite montre moins de destinations,
    // mais l'arborescence est la meme. Les branches du routeur se lisent donc
    // sur la liste COMPLETE ; la barre ne recoit que les destinations
    // essentielles, et son index actif est recalcule dessus.
    final List<Destination> destinations = destinationsPour(
      role: role,
      mode: InterfaceMode.standard,
    );
    final List<Destination> visibles = destinationsPour(role: role, mode: mode);
    // COM-F-Q5 : sur la page des notifications, la cloche est la seule
    // entree active. La page vit sous une branche (la Journee, l'Accueil),
    // mais la barre ne surligne pas cet onglet : deux selections a la fois
    // diraient deux endroits.
    final String? cheminCloche = Routes.notificationsPour(role);
    final bool surNotifications = chemin == cheminCloche;

    final Widget coquille = NavShell(
      destinations: visibles,
      indexActif: surNotifications
          ? null
          : indexDansBarre(
              visibles: visibles,
              completes: destinations,
              indexComplet: navigationShell.currentIndex < destinations.length
                  ? navigationShell.currentIndex
                  : null,
            ),
      masquerBarreBasse:
          Routes.estTacheFocalisee(chemin) ||
          Routes.estTacheFocaliseeComptable(chemin),
      // Le rail replie a icones seules est la maquette du tuteur ; l'eleve et
      // l'enseignant gardent leurs libelles visibles sur tablette, comme avant
      // le chantier (revue phase 0, jetons D2, routes D3).
      libellesDansLeRail: role != AppRole.guardian,
      onAller: (String destination) {
        final int index = destinations.indexWhere(
          (Destination d) => d.chemin == destination,
        );
        if (index == -1) {
          return;
        }
        // Une destination sans branche (le Compte de l'eleve, `/compte`) se
        // rejoint par `go` : `goBranch` sur un index absent violait
        // l'assertion de go_router puis lisait hors de la liste (C01, 3.3-6).
        if (index >= navigationShell.route.branches.length) {
          GoRouter.of(context).go(destination);
          return;
        }
        navigationShell.goBranch(
          index,
          // Retaper la destination courante la reprend a sa racine.
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      secondaires: secondairesPour(role: role),
      // Les entrees secondaires sont des routes de premier niveau **hors** de
      // la coquille : elles se rejoignent par `go`, jamais par `goBranch`, qui
      // ne connait que les branches.
      onAllerSecondaire: (String destination) =>
          GoRouter.of(context).go(destination),
      // Fondu court entre les onglets du tuteur (P2-16) ; l'eleve et
      // l'enseignant gardent la bascule seche.
      child: role == AppRole.guardian
          ? FonduOnglet(
              index: navigationShell.currentIndex,
              child: navigationShell,
            )
          : navigationShell,
    );

    if (role != AppRole.guardian) {
      // COM-F : la cloche des notifications, posee par la coquille du role
      // quand ce role en a une (`Routes.notificationsPour` : enseignant et
      // controleur ; jamais l'eleve mineur, reponse Q5 du directeur du
      // 04/10). Sans point tant que le port est indisponible, comme le
      // tuteur. Elle s'ajoute, en dernier, aux actions deja posees au-dessus
      // (le raccourci Espaces de CT-9), et se montre active sur sa page.
      final Widget avecCloche = cheminCloche == null
          ? coquille
          : Builder(
              builder: (BuildContext contexte) => ActionsEnteteCoquille(
                actions: <Widget>[
                  ...ActionsEnteteCoquille.de(contexte),
                  ClocheNotifications(
                    actif: surNotifications,
                    onPress: () => GoRouter.of(contexte).go(cheminCloche),
                  ),
                ],
                onRetour: ActionsEnteteCoquille.retourDe(contexte),
                child: coquille,
              ),
            );
      // CT-9 : le raccourci d'en-tete vers `Compte > Espaces`, seulement
      // quand le compte a plus d'un espace (jamais le tuteur, C6) ; l'espace
      // Controle est garde, refus generique si la capacite manque (C7).
      final Widget avecEspaces = EnteteEspaces(child: avecCloche);
      return role == AppRole.controller
          ? GardeControle(child: avecEspaces)
          : avecEspaces;
    }
    // Le tuteur porte, sur chaque page de sa coquille, la cloche des
    // notifications et, a partir de la tablette, la bascule clair / sombre
    // (manifeste visuel Tuteur V1 section 4.2). La cloche n'a pas de point
    // tant qu'aucune source de notifications n'existe (DB-CPT-04).
    final bool large = AppGabarit.de(context).estLarge;
    return ActionsEnteteCoquille(
      actions: <Widget>[
        if (large) const BasculeTheme(),
        ClocheNotifications(
          actif: surNotifications,
          onPress: () => GoRouter.of(context).go(Routes.tuteurNotifications),
        ),
      ],
      child: coquille,
    );
  }
}

/// Les actions d'en-tete du Studio (revue COM-R, R-05), posees par la route
/// comme celles de l'`AdminShell` : a partir de 600, la bascule clair /
/// sombre ; partout, « Mon compte » (la deconnexion y est) puis la cloche des
/// notifications de l'admin, en dernier. Sous le prefixe `/admin`, que la
/// garde reserve a l'admin : rien ici ne lit un role.
class _ActionsStudio extends StatelessWidget {
  const _ActionsStudio({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    void aller(String chemin) => GoRouter.of(context).go(chemin);
    final bool large = AppGabarit.de(context).estLarge;
    return ActionsEnteteCoquille(
      actions: <Widget>[
        if (large) const BasculeTheme(),
        BoutonIcone(
          key: cleCompteStudio,
          icone: AppIcons.profil,
          libelle: t.nav.compte,
          infobulle: t.nav.compte,
          onPress: () => aller(Routes.compte),
        ),
        ClocheNotifications(onPress: () => aller(Routes.adminNotifications)),
      ],
      child: child,
    );
  }
}

/// La cle de « Mon compte » dans l'en-tete du Studio, pour les tests.
const Key cleCompteStudio = ValueKey<String>('studio-compte');

/// Le chrome du panneau admin, huit domaines (lot IA-01, 19 septembre 2026).
///
/// Remplace `_CoquilleNavigation`/`_CoquilleSecondaire` pour le role admin :
/// `AdminShell` ne partage pas la limite de quatre destinations de
/// `NavShell`, l'operateur a tranche que le panneau grandira avec un RBAC a
/// plusieurs roles (`docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`). Chaque route porte explicitement
/// son domaine, exactement comme `_CoquilleSecondaire` porte deja son role :
/// ni l'un ni l'autre ne devine depuis le chemin courant.
///
/// **Perd l'IndexedStack** que les quatre premiers ecrans avaient hier : huit
/// domaines ne se rangent plus dans quatre branches d'onglets, la plupart des
/// ecrans admin redemarrent donc leur etat a chaque navigation, comme le
/// faisaient deja `ADM-06`, `ADM-07` et `ADM-08` avant ce lot. C'est le prix
/// assume de la restructuration, pas un oubli.
class _CoquilleAdmin extends ConsumerWidget {
  const _CoquilleAdmin({
    required this.domaine,
    required this.child,
    this.sousPage = false,
    this.notificationsOuvertes = false,
  });

  /// Le domaine que revendique cette route ; nul pour une page transverse
  /// (les notifications), qui n'allume aucun domaine.
  final AdminDomaine? domaine;

  /// Vrai pour une page rangee sous l'Accueil (les alertes) : elle garde le
  /// retour vers l'Accueil.
  final bool sousPage;

  final Widget child;

  /// La page ouverte est celle des notifications : la cloche s'y montre
  /// active.
  final bool notificationsOuvertes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void aller(String chemin) => GoRouter.of(context).go(chemin);

    final bool voitDirection = ref.watch(
      sessionProvider.select((SessionState s) => s.peutVoirDirection),
    );

    // ALERTE-1 : la cloche n'existe que si la capacite « alertes » rend
    // quelque chose (jamais en production avant DASH-BR-03, Q5) ; son point
    // dit qu'une alerte urgente est ouverte. Jamais deduite du role.
    final int? urgentes = ref.watch(alertesUrgentesProvider);

    return AdminShell(
      domaines: domainesAdmin(voitDirection: voitDirection),
      domaineActif: domaine,
      onAller: aller,
      onCompte: () => aller(Routes.compte),
      // Retour vers l'Accueil sur toute page admin sauf l'Accueil lui-meme
      // (spec section 26 ter, Q14).
      onRetour: domaine == AdminDomaine.accueil && !sousPage
          ? null
          : () => aller(Routes.admin),
      cloche: urgentes == null
          ? null
          : ClocheNotifications(
              onPress: () => aller(Routes.adminAlertes),
              nonLues: urgentes,
              libelleSemantique: switch (urgentes) {
                0 => t.alertes.cloche,
                1 => t.alertes.clocheUneUrgente,
                _ => t.alertes.clocheUrgentes(nombre: urgentes),
              },
            ),
      // Le bandeau d'alerte urgente, en tete de toute page ouverte, sauf
      // sous l'Accueil : le Centre de commande et la page des alertes
      // montrent deja l'alerte en tete (D7, une information une fois).
      // Pose seulement quand une alerte urgente est ouverte ; fige en haut
      // par la coquille, hors de la zone qui defile (ALERTE-1b).
      bandeau: domaine == AdminDomaine.accueil || (urgentes ?? 0) == 0
          ? null
          : BandeauAlerteUrgente(onOuvrir: () => aller(Routes.adminAlertes)),
      // COM-F : la cloche mene a la `NotificationsPage` existante, l'action
      // « Le Studio » au Studio (Q1). Posees par la route, sous le prefixe
      // `/admin` que la garde reserve a l'admin : la coquille ne lit aucun
      // role.
      onNotifications: () => aller(Routes.adminNotifications),
      notificationsActives: notificationsOuvertes,
      onStudio: () => aller(Routes.adminStudio),
      child: child,
    );
  }
}
