import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 a sorti `Override` de l'export principal.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/accessibilite/accueil_accessibilite_supabase.dart';
import 'core/accessibilite/port_accueil_accessibilite.dart';
import 'core/accessibilite/port_reponse_presentation.dart';
import 'core/accessibilite/reponse_presentation_supabase.dart';
import 'core/admin/bibliotheque_admin_supabase.dart';
import 'core/admin/classes_admin_supabase.dart';
import 'core/admin/fusion_classes_supabase.dart';
import 'core/admin/incidents_seances_supabase.dart';
import 'core/admin/pilotage_supabase.dart';
import 'core/admin/planning_direction_supabase.dart';
import 'core/admin/port_bibliotheque_admin.dart';
import 'core/admin/port_classes_admin.dart';
import 'core/admin/port_fusion_classes.dart';
import 'core/admin/port_incidents_seances.dart';
import 'core/admin/port_pilotage.dart';
import 'core/admin/port_planning_direction.dart';
import 'core/agent/amorce_agent.dart';
import 'core/agent/session_agent.dart';
import 'core/capacites/classes_foyer_supabase.dart';
import 'core/capacites/enseignants_classe_supabase.dart';
import 'core/capacites/identite_titulaire_supabase.dart';
import 'core/capacites/mes_finances_supabase.dart';
import 'core/capacites/paiements_foyer_supabase.dart';
import 'core/capacites/paiements_saisis_supabase.dart';
import 'core/capacites/politiques_commerciales_supabase.dart';
import 'core/capacites/port_classes_foyer.dart';
import 'core/capacites/port_enseignants_classe.dart';
import 'core/capacites/port_identite_titulaire.dart';
import 'core/capacites/port_mes_finances.dart';
import 'core/capacites/port_paiements_foyer.dart';
import 'core/capacites/port_paiements_saisis.dart';
import 'core/capacites/port_politiques_commerciales.dart';
import 'core/capacites/port_profil_eleve_titulaire.dart';
import 'core/capacites/port_progression_famille.dart';
import 'core/capacites/port_recharge_foyer.dart';
import 'core/capacites/port_revenus_enseignant.dart';
import 'core/capacites/port_series_tresorerie.dart';
import 'core/capacites/port_support.dart';
import 'core/capacites/port_validations_finance.dart';
import 'core/capacites/profil_eleve_titulaire_supabase.dart';
import 'core/capacites/progression_famille_supabase.dart';
import 'core/capacites/recharge_foyer_supabase.dart';
import 'core/capacites/revenus_enseignant_supabase.dart';
import 'core/capacites/revue_dossiers_depuis_validation.dart';
import 'core/capacites/series_tresorerie_supabase.dart';
import 'core/capacites/support_supabase.dart';
import 'core/capacites/validations_finance_supabase.dart';
import 'core/communications/communications_supabase.dart';
import 'core/communications/libelles_communication_slang.dart';
import 'core/config/ecran_configuration_absente.dart';
import 'core/config/env.dart';
import 'core/controle/port_tirage_controle.dart';
import 'core/controle/port_tirage_controle_supabase.dart';
import 'core/dossier/port_acces_pieces_kyc.dart';
import 'core/dossier/port_acces_pieces_kyc_supabase.dart';
import 'core/enseignant/absence_remplacement.dart';
import 'core/enseignant/port_remplacements.dart';
import 'core/enseignant/remplacements_supabase.dart';
import 'core/finance/page_paiement.dart';
import 'core/foyer/port_reprises_admin.dart';
import 'core/foyer/reprises_admin_supabase.dart';
import 'core/i18n/langue_demarrage.dart';
import 'core/i18n/strings.g.dart';
import 'core/identite/matricule_supabase.dart';
import 'core/identite/port_matricule.dart';
import 'core/observabilite/supervision.dart';
import 'core/offres/demandes_suivi_supabase.dart';
import 'core/offres/frise_demandes_supabase.dart';
import 'core/offres/offres_admin_supabase.dart';
import 'core/offres/page_regroupements.dart';
import 'core/offres/port_frise_demande.dart';
import 'core/offres/port_offres_admin.dart';
import 'core/offres/port_regroupements_admin.dart';
import 'core/offres/port_suivi_demandes.dart';
import 'core/offres/regroupements_c11bis_supabase.dart';
import 'core/offres/regroupements_pages_supabase.dart';
import 'core/recrutement/invitations_comptable_supabase.dart';
import 'core/recrutement/invitations_enseignant_supabase.dart';
import 'core/recrutement/port_invitations_comptable.dart';
import 'core/recrutement/port_invitations_enseignant.dart';
import 'core/recrutement/port_signature_contrat.dart';
import 'core/recrutement/port_statuts_signature.dart';
import 'core/recrutement/port_statuts_signature_supabase.dart';
import 'core/router/routes.dart';
import 'core/session/port_capacite_eleve.dart';
import 'core/session/port_capacite_eleve_supabase.dart';
import 'core/session/session_controleur.dart';
import 'core/session/source_session_agent.dart';
import 'core/tc_bibliotheque/port_support_actif.dart';
import 'core/tc_bibliotheque/support_actif_supabase.dart';
import 'core/tc_etat_partage/etat_partage_supabase.dart';
import 'core/tc_etat_partage/providers_tc_etat_partage.dart';
import 'core/tc_observation/historique_observations_admin_supabase.dart';
import 'core/tc_observation/historique_observations_supabase.dart';
import 'core/tc_observation/port_historique_observations.dart';
import 'core/tc_outils/annotations_supabase.dart';
import 'core/tc_outils/assignations_supabase.dart';
import 'core/tc_outils/port_annotations.dart';
import 'core/tc_outils/port_assignations.dart';
import 'core/tc_parcours/contenu_seance_supabase.dart';
import 'core/tc_parcours/feedback_supabase.dart';
import 'core/tc_parcours/port_feedback.dart';
import 'core/tc_parcours/port_signalement.dart';
import 'core/tc_parcours/port_travail_a_venir.dart';
import 'core/tc_parcours/signalement_supabase.dart';
import 'features/_dev/playground/playground_racine.dart';
import 'features/bienvenue_enseignant/prerequis_enseignant_supabase.dart';
import 'features/com_annonces/annonces_supabase.dart';
import 'features/com_annonces/port_annonces.dart';
import 'features/com_messages/messages_metier_supabase.dart';
import 'features/com_messages/port_messages_metier.dart';
import 'features/controleur/echanges_controleur.dart';
import 'features/controleur/echanges_controleur_supabase.dart';
import 'features/controleur/historique_controleur.dart';
import 'features/controleur/historique_controleur_supabase.dart';
import 'features/demo/dossiers_demo.dart';
import 'features/demo/mode_demonstration.dart';
import 'features/demo/racine_demonstrable.dart';
import 'features/demo/repere_demonstration.dart';
import 'features/foyer/invitation_conjoint.dart';
import 'features/foyer/invitation_conjoint_supabase.dart';

/// Les surcharges de l'application reelle (jamais le mode demonstration) :
/// le port des classes du foyer bascule sur l'adaptateur Supabase des que le
/// client est initialise (constat C-INT-1, `demandes/c.md`). Un provider
/// partage ne doit pas dependre implicitement d'un service reseau pour son
/// comportement par defaut ; ce branchement se fait ici et nulle part
/// ailleurs.
List<Override> _surchargesAppReelle() => <Override>[
  portClassesFoyerProvider.overrideWithValue(
    ClassesFoyerSupabase(Supabase.instance.client),
  ),
  surchargeRevueDossiersProduction,
  // Direction : chaque port d'administration lit et ecrit par les RPC de
  // STAGING, avec le jeton de la session (le serveur reste la barriere).
  portIncidentsSeancesProvider.overrideWithValue(
    IncidentsSeancesSupabase(Supabase.instance.client),
  ),
  portPlanningDirectionProvider.overrideWithValue(
    PlanningDirectionSupabase(Supabase.instance.client),
  ),
  portReprisesAdminProvider.overrideWithValue(
    ReprisesAdminSupabase(Supabase.instance.client),
  ),
  portRegroupementsAdminProvider.overrideWithValue(
    RegroupementsC11bisSupabase(Supabase.instance.client),
  ),
  // L2-05 : les offres vitrine (creer, publier, retirer) par les RPC de 0043.
  portOffresAdminProvider.overrideWithValue(
    OffresAdminSupabase(Supabase.instance.client),
  ),
  // Liste paginee des regroupements (fonction Edge `regroupements-pages`).
  portRegroupementsPagesProvider.overrideWithValue(
    RegroupementsPagesSupabase(Supabase.instance.client),
  ),
  // Bibliotheque d'administration (CAP-29) : lectures, revue des droits,
  // depot R2 et ecritures (brouillon, mise a jour de la fiche, controle,
  // publication, attribution, retrait).
  portBibliothequeAdminProvider.overrideWithValue(
    BibliothequeAdminSupabase(Supabase.instance.client),
  ),
  // Classes de la direction (CONTRATS-MANQUANTS) : liste paginee et
  // numerotee (R16, R17), fusion et transfert (R9, R10), pilotage par
  // horaire (R19), enseignants proposables a la creation (CLASSE-FORM-1).
  portClassesAdminProvider.overrideWithValue(
    ClassesAdminSupabase(Supabase.instance.client),
  ),
  portFusionClassesProvider.overrideWithValue(
    FusionClassesSupabase(Supabase.instance.client),
  ),
  portPilotageProvider.overrideWithValue(
    PilotageSupabase(Supabase.instance.client),
  ),
  portEnseignantsClasseProvider.overrideWithValue(
    EnseignantsClasseSupabase(Supabase.instance.client),
  ),
  // Recrutement : invitation d'un enseignant par la direction et
  // verification du code par le candidat (C-13, C-14).
  portInvitationsEnseignantProvider.overrideWithValue(
    InvitationsEnseignantSupabase(Supabase.instance.client),
  ),
  portVerificationInvitationProvider.overrideWithValue(
    VerificationInvitationSupabase(Supabase.instance.client),
  ),
  // Invitation d'un comptable par la direction (BF1-03, 20261017160200) :
  // ports branches, ecrans d'emission et d'inscription a venir.
  portInvitationsComptableProvider.overrideWithValue(
    InvitationsComptableSupabase(Supabase.instance.client),
  ),
  portVerificationInvitationComptableProvider.overrideWithValue(
    VerificationInvitationComptableSupabase(Supabase.instance.client),
  ),
  portInscriptionComptableProvider.overrideWithValue(
    InscriptionComptableSupabase(Supabase.instance.client),
  ),
  portTirageControleProvider.overrideWithValue(
    PortTirageControleSupabase(Supabase.instance.client),
  ),
  // Famille : la frise des demandes et la reponse aux demandes de
  // presentation, bornees au foyer de la session par le serveur.
  portFriseDemandesProvider.overrideWithValue(
    FriseDemandesSupabase(Supabase.instance.client),
  ),
  portReponsePresentationProvider.overrideWithValue(
    ReponsePresentationSupabase(Supabase.instance.client),
  ),
  portSuiviDemandesProvider.overrideWithValue(
    DemandesSuiviSupabase(Supabase.instance.client),
  ),
  // Travail a preparer d'une Classe (learning_assignment, RLS 0061) : ecriture
  // enseignante du dock et lecture de la famille.
  portAssignationsProvider.overrideWithValue(
    AssignationsSupabase(Supabase.instance.client),
  ),
  assignationsFamilleProvider.overrideWithValue(
    AssignationsSupabase(Supabase.instance.client),
  ),
  // Dossiers et recrutement : verdict d'acces aux pieces KYC, statuts des
  // signatures et signature du contrat enseignant versionne (F70).
  portAccesPiecesKycProvider.overrideWithValue(
    PortAccesPiecesKycSupabase(Supabase.instance.client),
  ),
  portStatutsSignatureProvider.overrideWithValue(
    StatutsSignatureSupabase(Supabase.instance.client),
  ),
  portSignatureContratProvider.overrideWithValue(
    SignatureContratSupabase(Supabase.instance.client),
  ),
  // Ports a defaut « indisponible » (ou en memoire) dont l'adaptateur
  // serveur existe : compte, tresorerie, observations, controleur, support
  // et etat partage de la classe.
  portIdentiteTitulaireProvider.overrideWithValue(
    IdentiteTitulaireSupabase(
      Supabase.instance.client,
      motDePassePossible: Env.authParMotDePasseActive,
    ),
  ),
  portMatriculeProvider.overrideWithValue(
    MatriculeSupabase(Supabase.instance.client),
  ),
  portSeriesTresorerieProvider.overrideWithValue(
    SeriesTresorerieSupabase(Supabase.instance.client),
  ),
  // Finance hors administration (BF1, migrations 20261017160000 et
  // 20261017160100) : revenus de l'enseignant connecte, finances de l'eleve
  // adulte sur son profil, finance et paiements du foyer pour le titulaire.
  // La recharge reste indisponible : aucun prestataire de paiement reel.
  portRevenusEnseignantProvider.overrideWithValue(
    RevenusEnseignantSupabase(Supabase.instance.client),
  ),
  portMesFinancesProvider.overrideWithValue(
    MesFinancesSupabase(Supabase.instance.client),
  ),
  portPaiementsFoyerProvider.overrideWithValue(
    PaiementsFoyerSupabase(Supabase.instance.client),
  ),
  // Politique commerciale versionnee (FAC-A-01, migration 20261017170000) :
  // lecture par la direction et la comptabilite, publication par la
  // direction en double verification.
  portPolitiquesCommercialesProvider.overrideWithValue(
    PolitiquesCommercialesSupabase(Supabase.instance.client),
  ),
  // Saisie des paiements recus (FAC-C-01, migration 20261017172000) : la
  // direction et la comptabilite, attribues a un eleve.
  // Recharge des familles payee chez Stripe (FI-BR-06, migration
  // 20261018100000, fonctions `recharge-payer` et `stripe-webhook`) : le
  // chemin par defaut ; la saisie a la main reste un recours.
  portRechargeFoyerProvider.overrideWithValue(
    RechargeFoyerSupabase(
      Supabase.instance.client,
      adresseRetour: () => adresseApplication(
        Routes.resultatRechargePour(RechargeFoyerSupabase.marqueCommande),
      ),
      ouvrirPage: ouvrirPagePaiement,
    ),
  ),
  portPaiementsSaisisProvider.overrideWithValue(
    PaiementsSaisisSupabase(Supabase.instance.client),
  ),
  // Validations de la direction (FAC-D-01, migration 20261018090000) : un
  // paiement saisi par la comptabilite est credite apres validation.
  portValidationsFinanceProvider.overrideWithValue(
    ValidationsFinanceSupabase(Supabase.instance.client),
  ),
  portHistoriqueObservationsProvider.overrideWithValue(
    HistoriqueObservationsSupabase(() => Supabase.instance.client),
  ),
  portHistoriqueObservationsAdminProvider.overrideWithValue(
    HistoriqueObservationsAdminSupabase(() => Supabase.instance.client),
  ),
  portEchangesProvider.overrideWithValue(
    EchangesControleurSupabase(Supabase.instance.client),
  ),
  portHistoriqueProvider.overrideWithValue(
    HistoriqueControleurSupabase(Supabase.instance.client),
  ),
  portSupportProvider.overrideWithValue(
    SupportSupabase(Supabase.instance.client),
  ),
  portEtatPartagePersistantProvider.overrideWithValue(
    EtatPartageSupabase(Supabase.instance.client),
  ),
  // Enseignant : absence sur une seance et prise d'un remplacement (B-09).
  declarationAbsenceProvider.overrideWithValue(
    DeclarationAbsenceSupabase(Supabase.instance.client),
  ),
  reponseRemplacementProvider.overrideWithValue(
    ReponseRemplacementSupabase(Supabase.instance.client),
  ),
  // Tableau commun des remplacements (REMPL-1), filtre par le serveur.
  portRemplacementsProvider.overrideWithValue(
    RemplacementsSupabase(Supabase.instance.client),
  ),
  // Prerequis de l'enseignant (ENS-01), calcules par le serveur.
  surchargePrerequisEnseignant(),
  // Famille et titulaire : progression d'un eleve, profil eleve du
  // titulaire, invitation du second adulte, capacite « eleve autonome ».
  portProgressionFamilleProvider.overrideWithValue(
    ProgressionFamilleSupabase(Supabase.instance.client),
  ),
  portProfilEleveTitulaireProvider.overrideWithValue(
    ProfilEleveTitulaireSupabase(Supabase.instance.client),
  ),
  portInvitationConjointProvider.overrideWithValue(
    InvitationConjointSupabase(Supabase.instance.client),
  ),
  portCapaciteEleveProvider.overrideWithValue(
    PortCapaciteEleveSupabase(Supabase.instance.client),
  ),
  // Salle et parcours : annotations persistantes, retour de comprehension et
  // signalements, sous RLS et RPC bornees au groupe.
  portAnnotationsProvider.overrideWithValue(
    AnnotationsSupabase(Supabase.instance.client),
  ),
  portFeedbackProvider.overrideWithValue(
    FeedbackSupabase(Supabase.instance.client),
  ),
  portSignalementProvider.overrideWithValue(
    SignalementSupabase(Supabase.instance.client),
  ),
  // Support actif de la seance (CAP29-G) et travail a venir de la classe
  // (« Avant le prochain cours ») : assignations ouvertes et reprise.
  portSupportActifProvider.overrideWithValue(
    SupportActifSupabase(Supabase.instance.client),
  ),
  portTravailAVenirProvider.overrideWithValue(
    travailAVenirSupabase(Supabase.instance.client),
  ),
  // Accueil de l'eleve en Mode Accessibilite (RACCORDEMENT-1016) : prenom,
  // Classe et prochaine seance reelle (`prochaine_seance_groupe`, puis
  // `horloge_seance`), travail a venir de la Classe.
  portAccueilAccessibiliteProvider.overrideWithValue(
    AccueilAccessibiliteSupabase(
      Supabase.instance.client,
      travail: travailAVenirSupabase(Supabase.instance.client),
    ),
  ),
  // Communications (COM-BACK-1) : Messages metier et annonces de Classe sur
  // les RPC `com_*`, nommes dans la langue courante.
  portMessagesMetierProvider.overrideWithValue(
    MessagesMetierSupabase(
      appelRpcSupabase(Supabase.instance.client),
      libelles: const LibellesCommunicationSlang(),
    ),
  ),
  portAnnoncesProvider.overrideWithValue(
    AnnoncesSupabase(
      appelRpcSupabase(Supabase.instance.client),
      libelles: const LibellesCommunicationSlang(),
    ),
  ),
];

/// Point d'entree unique de l'application.
///
/// Une seule cible, toutes les plateformes : Windows, Android, iOS et Web. Le
/// Web est ouvert a tous les roles (ADR-008), il n'y a donc aucune branche de
/// demarrage par plateforme.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La supervision avant tout le reste : une erreur du demarrage lui-meme doit
  // remonter comme les autres, y compris l'ecran de configuration absente.
  // Sans DSN, cet appel ne fait rien. Il ne passe pas par `appRunner` : sur
  // Flutter 3.47, `PlatformDispatcher.onError` existe, donc Sentry n'ouvre
  // aucune zone gardee et `appRunner` ne capterait pas une erreur de plus.
  await Supervision.demarrer();

  // Jamais `LocaleSettings.useDeviceLocale()` : une langue systeme mal formee
  // (« en-US@posix ») y levait et arretait l'application (CLAVIER-ENTREE-1).
  await appliquerLangueDeLAppareil();

  // La configuration est injectee a la compilation, jamais versionnee.
  // Sans elle, on echoue tot, en clair, et EN RELEASE AUSSI : un `assert` seul
  // ne tient pas cette promesse, il disparait de la version compilee et laisse
  // l'application demarrer pour mourir plus loin sur un ecran gris.
  if (!Env.configuree) {
    runApp(const EcranConfigurationAbsente());
    return;
  }

  // L'observation par un agent IA (ADR-025) se decide ICI et nulle part
  // ailleurs : l'identite sous laquelle le client parle a la base est une
  // decision d'amorcage. Un ecran ne peut pas la prendre apres coup, puisque le
  // client est deja construit quand le premier ecran s'affiche.
  final String? jetonAgent = jetonAgentDeLUrl();
  if (jetonAgent != null) {
    await _demarrerObservation(jetonAgent);
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  // Demonstration tuteur (P2-07) : `?demo=tuteur`, jamais en production.
  if (demoTuteurActiveIci) {
    final ({EtatRevueDemo dossiers, String titulaire})? titulaireDemo =
        dossierTitulaireDemoPour(Uri.base);
    runApp(
      ProviderScope(
        overrides: surchargesDemoTuteur(
          dossiers: titulaireDemo?.dossiers,
          titulaire: titulaireDemo?.titulaire,
        ),
        child: TranslationProvider(
          child: RewayahApp(
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    );
    return;
  }

  // Demonstration admin (AD-4) : `?demo=admin`, meme garde et meme repere.
  // Aucun adaptateur serveur des ports de revue n'est branche (K-28).
  if (demoAdminActiveIci) {
    runApp(
      ProviderScope(
        overrides: surchargesDemoAdmin(
          etat: etatRevueDemoPour(Uri.base),
          avecAlertes: true,
          arriveeAlerte: dureeArriveeAlerteDemo,
        ),
        child: TranslationProvider(
          child: RewayahApp(
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    );
    return;
  }

  if (Env.playgroundActif) {
    runApp(
      ProviderScope(
        child: TranslationProvider(child: const PlaygroundRacine()),
      ),
    );
    return;
  }

  // Hors production, la racine porte l'entree « Essayer la demonstration »
  // (P2-07) ; en production elle n'a aucun lanceur et se comporte comme
  // l'application seule.
  runApp(RacineDemonstrable(surchargesReelles: _surchargesAppReelle()));
}

/// Demarre l'application en session d'observation.
///
/// L'echange du jeton se fait AVANT `Supabase.initialize`, pour deux raisons.
/// La premiere : le client s'initialise avec le passe-vole `accessToken`, donc
/// il faut deja savoir que l'observation est possible. La seconde, plus
/// importante : un jeton refuse doit le rester **avant** que le moindre ecran
/// metier existe. Ouvrir l'application puis echouer a la premiere requete
/// afficherait une coquille vide au lieu d'un refus.
///
/// Quand la remise echoue, on demarre l'application **normalement**, sur
/// `AGT-00`, qui dit ce qui s'est passe. Pas d'ecran d'erreur separe : un agent
/// qui a un jeton valide sous la main doit pouvoir s'en servir tout de suite.
Future<void> _demarrerObservation(String jeton) async {
  final PorteurSessionAgent porteur = PorteurSessionAgent(
    jeton: jeton,
    url: Env.supabaseUrl,
    cleAnon: Env.supabaseAnonKey,
  );

  EchecAgent? echec;
  try {
    await porteur.ouvrir();
  } on ErreurAgent catch (e) {
    echec = e.cause;
  } on Object {
    echec = EchecAgent.serviceIndisponible;
  }

  if (echec != null) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    runApp(
      ProviderScope(
        overrides: <Override>[
          echecAgentProvider.overrideWithValue(echec),
          ..._surchargesAppReelle(),
        ],
        child: TranslationProvider(child: const RewayahApp()),
      ),
    );
    return;
  }

  // `accessToken` remplace l'authentification gotrue : `client.auth` devient
  // inutilisable, et c'est exactement ce qu'on veut. Une session d'observation
  // ne se connecte pas, ne se deconnecte pas, et ne porte aucun jeton de
  // rafraichissement -- le porteur repasse par la base a chaque renouvellement.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    accessToken: porteur.jetonFrais,
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(
          SourceSessionAgent(porteur, Supabase.instance.client),
        ),
        ..._surchargesAppReelle(),
      ],
      child: TranslationProvider(child: const RewayahApp()),
    ),
  );
}
