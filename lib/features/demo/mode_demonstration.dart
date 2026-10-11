// Mode demonstration tuteur (P2-07) : socle.
//
// Donnees fictives, aucun appel serveur, jamais en production
// (03_DECISIONS_COORDINATEUR.md, decisions 1 et 6 ; 00_REPRISE.md 5.4).
//
// L'interrupteur se lit a l'execution (`?demo=tuteur` dans l'adresse) parce
// que le deploiement force `PLAYGROUND=false` et qu'on ne touche pas au
// workflow. La garde, elle, est compilee : `ENVIRONNEMENT=production` la
// ferme quelle que soit l'adresse, et une compilation de publication sans
// `ENVIRONNEMENT` declare aussi (DEMO-ENV-1).

import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/admin/port_bibliotheque_admin.dart';
import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/port_fusion_classes.dart';
import '../../core/admin/port_pilotage.dart';
import '../../core/admin/service_admin.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/alertes/port_alertes.dart';
import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/port_accents_profils.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_catalogue_classes.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/capacites/port_creation_classe.dart';
import '../../core/capacites/port_enseignants_classe.dart';
import '../../core/capacites/port_finance_direction.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/capacites/port_politique_revue_kyc.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/capacites/port_recharge_foyer.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/config/env.dart';
import '../../core/controle/port_tirage_controle.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/selecteur_fichier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/page_regroupements.dart'
    show portRegroupementsPagesProvider;
import '../../core/offres/port_regroupements_admin.dart';
import '../../core/offres/service_offres.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/recrutement/port_statuts_signature.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/session/source_session.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/tc_groupe/cartes_classe.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_observation/activation_observation.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import '../../core/tc_observation/port_politique_observation.dart';
import '../../core/tc_observation/port_visite_observation.dart';
import '../../core/theme/accent_profil.dart';
import '../admin_tableau/activite_recente.dart';
import 'admin_x_demo.dart';
import 'alertes_demo.dart';
import 'bibliotheque_admin_demo.dart';
import 'cartes_classe_demo.dart';
import 'catalogue_demo.dart';
import 'classe_form_demo.dart';
import 'classes_admin_demo.dart';
import 'dossiers_demo.dart';
import 'finance_demo.dart';
import 'fusion_demo.dart';
import 'observation_demo.dart';
import 'pilotage_demo.dart';
import 'presence_demo.dart';
import 'recrutement_demo.dart';
import 'regroupements_demo.dart';
import 'services_admin_demo.dart';
import 'suivi_demandes_demo.dart';
import 'tirage_demo.dart';

/// Parametre d'adresse qui demande la demonstration tuteur.
const String parametreDemo = 'demo';

/// Valeur du parametre qui ouvre la demonstration tuteur.
const String valeurDemoTuteur = 'tuteur';

/// Vrai si l'environnement compile autorise la demonstration.
///
/// Tout ce qui ressemble a `production` (casse, espaces) ferme la porte, et un
/// environnement vide aussi. DEMO-ENV-1 (AD-R m13) : une compilation de
/// publication qui ne declare pas `ENVIRONNEMENT` la ferme aussi, car
/// [Env.environnement] y vaudrait `developpement` par defaut et ouvrirait
/// toutes les demonstrations. [declare] et [publication] sont injectables
/// pour les tests ; en debogage et en test, l'environnement par defaut reste
/// ouvert.
bool environnementAutoriseDemo(
  String environnement, {
  bool declare = Env.environnementDeclare,
  // DEMO-ENV-1-M1 : ce branchement n'est garde que par la relecture. En
  // debogage et sous `flutter test`, kReleaseMode vaut toujours faux : un
  // test l'affirmant serait une tautologie. `declare` est, lui, teste.
  bool publication = kReleaseMode,
}) {
  if (publication && !declare) {
    return false;
  }
  final String normalise = environnement.trim().toLowerCase();
  return normalise.isNotEmpty && !normalise.contains('prod');
}

/// Valeur du parametre qui nomme la demonstration d'un dossier d'enseignant
/// (AD-NETTOYAGE-2, n1) : `?demo=enseignant&dossier=...`, alias de
/// `?demo=tuteur&dossier=...` qui reste accepte. Sans `dossier`, elle ne
/// montre rien d'enseignant et n'ouvre donc pas la demonstration.
const String valeurDemoEnseignant = 'enseignant';

/// Vrai si l'adresse demande la demonstration tuteur, ou celle d'un dossier
/// d'enseignant (`demo=enseignant` avec un `dossier`).
bool demoTuteurDemandee(Uri adresse) {
  final String? demo = adresse.queryParameters[parametreDemo]
      ?.trim()
      .toLowerCase();
  if (demo == valeurDemoTuteur) return true;
  return demo == valeurDemoEnseignant &&
      (adresse.queryParameters[parametreDossierDemo]?.trim().isNotEmpty ??
          false);
}

/// La garde complete, pure pour etre testee sans compilation dediee.
bool demoTuteurActive({required Uri adresse, required String environnement}) =>
    environnementAutoriseDemo(environnement) && demoTuteurDemandee(adresse);

/// La garde appliquee a la compilation courante et a l'adresse d'ouverture.
bool get demoTuteurActiveIci =>
    demoTuteurActive(adresse: Uri.base, environnement: Env.environnement);

/// Les surcharges de la demonstration tuteur.
///
/// Leve une [StateError] si l'environnement ne l'autorise pas : meme appelee
/// par erreur, elle ne produit rien en production. [eleves] remplace les
/// eleves du foyer (la demonstration adulte y met le foyer Diallo, EA-1b).
///
/// Avec [dossiers] et [titulaire] (AD-10), la personne est le titulaire d'un
/// dossier du jeu de revue : sa session et son portail d'attente lisent le
/// meme etat que la revue admin, et « Corriger » depose une piece fictive.
List<Override> surchargesDemoTuteur({
  String? environnement,
  List<EleveDuFoyer>? eleves,
  EtatRevueDemo? dossiers,
  String? titulaire,
  JeuFoyerFinance? finances,
}) {
  if (!environnementAutoriseDemo(environnement ?? Env.environnement)) {
    throw StateError('Demonstration interdite en production.');
  }
  final bool avecDossier = dossiers != null && titulaire != null;
  // FI-4 : avec un jeu Finance, le foyer est celui du jeu (memes
  // identifiants que ses finances), avec ses couleurs de profil.
  final JeuFoyerFinance? jeu = finances;
  final List<FinancesProfil> profilsFinance = jeu == null
      ? const <FinancesProfil>[]
      : DonneesFinanceDemo.profils(jeu);
  return <Override>[
    if (avecDossier) ...<Override>[
      sourceSessionProvider.overrideWithValue(
        SourceSessionDemoTitulaire(dossiers, titulaire),
      ),
      serviceDossierProvider.overrideWithValue(
        ServiceDossierDemo(dossiers, titulaire),
      ),
      selecteurFichierProvider.overrideWithValue(const SelecteurFichierDemo()),
    ] else
      sourceSessionProvider.overrideWithValue(const SourceSessionDemo()),
    // Avec un dossier, la titulaire est une enseignante (K-47) : elle n'a pas
    // de foyer, donc ni eleve ni classe ; le foyer vide est sa vraie valeur
    // (et evite tout appel serveur). Sans dossier, le foyer de demonstration.
    elevesDuFoyerProvider.overrideWith(
      (Ref ref) async => avecDossier
          ? const <EleveDuFoyer>[]
          : eleves ??
                (jeu == null
                    ? DonneesDemo.eleves
                    : <EleveDuFoyer>[
                        for (final FinancesProfil p in profilsFinance)
                          EleveDuFoyer(
                            id: p.profilId,
                            prenom: p.prenom,
                            identifiantImmuable: 'STUD-FI-${p.profilId}',
                            mode: InterfaceMode.standard,
                            camera: CameraPolicy.allowed,
                            // L'echeance d'acces du meme jeu (FI-1c-CORR) :
                            // jamais « sans echeance » pour un payant.
                            finAcces: _finAccesDemo(jeu, p.profilId),
                          ),
                      ]),
    ),
    if (jeu != null) ...<Override>[
      portPaiementsFoyerProvider.overrideWithValue(
        PaiementsFoyerFinanceDemo(jeu),
      ),
      portPolitiquesCommercialesProvider.overrideWithValue(
        const PolitiquesCommercialesDemo(),
      ),
      portRechargeFoyerProvider.overrideWithValue(
        RechargeFoyerFinanceDemo(jeu),
      ),
    ],
    portAccesFoyerProvider.overrideWithValue(const AccesFoyerDemo()),
    // La couleur de profil choisie par le tuteur (K-62) : gardee en memoire,
    // rien n'est envoye (FI-BR-19).
    portAccentsProfilsProvider.overrideWithValue(
      AccentsProfilsEnMemoire(<String, AccentProfil>{
        DonneesDemo.aichaId: AccentProfil.menthe,
        DonneesDemo.yusufId: AccentProfil.rose,
        // Les couleurs de la maquette 03 (choix du tuteur de la demo).
        if (jeu != null) ...<String, AccentProfil>{
          DonneesFinanceDemo.mariamId: AccentProfil.rose,
          DonneesFinanceDemo.ibrahimId: AccentProfil.ciel,
          DonneesFinanceDemo.aichaId: AccentProfil.lavande,
          // Le jeu a cinq profils : aucun profil sans couleur.
          DonneesFinanceDemo.youssefId: AccentProfil.peche,
          DonneesFinanceDemo.khadijaId: AccentProfil.sable,
        },
      }),
    ),
    portClassesFoyerProvider.overrideWithValue(const ClassesFoyerDemo()),
    portSeancesFamilleProvider.overrideWithValue(SeancesFamilleDemo()),
    portCatalogueClassesProvider.overrideWithValue(
      const CatalogueClassesDemo(),
    ),
    // Lectures des ecrans tuteur encore adossees a Supabase : rendues vides
    // ou fictives pour qu'aucune ne parte vers le serveur.
    appareilsDuFoyerProvider.overrideWith(
      (Ref ref) async => const <AppareilAppaire>[],
    ),
    parcoursFoyerProvider.overrideWith(
      (Ref ref) async => const <ParcoursApprenant>[],
    ),
    monFuseauProvider.overrideWith((Ref ref) async => 'Europe/Paris'),
    // OFFRES-FAM-1 : le suivi des demandes du foyer de demonstration, et les
    // notifications de ses transitions (foyer de demonstration seulement).
    if (!avecDossier && eleves == null) ...surchargesSuiviDemandesDemo(),
    seancesDuSuiviProvider.overrideWith((Ref ref) async => const <Seance>[]),
    mesGroupesProvider.overrideWith(
      (Ref ref) async => avecDossier
          ? const <GroupSummaryVM>[]
          : DonneesDemo.classes.values.toList(),
    ),
    // CARTES-PERSO-1b : la page Classe du tuteur lit les memes cartes de
    // demonstration que la demonstration enseignant, en lecture seule (la
    // capacite que le serveur rendrait au tuteur). Sans elle, elle disait
    // « pas encore ouvertes » (revue CARTES-PERSO-1, deuxieme passe).
    portCartesClasseProvider.overrideWith(
      (Ref _) => PortCartesClasseDemo(
        peutModifier: false,
        cartes: cartesClasseDemo(DateTime.now()),
      ),
    ),
    // Observation simulee : politique, budget, historique. La salle video
    // demande un jeton au serveur, donc l'observation reelle reste fermee.
    observationTuteurReelleProvider.overrideWithValue(false),
    portPolitiqueObservationProvider.overrideWithValue(
      const PolitiqueObservationDemo(),
    ),
    portVisiteObservationProvider.overrideWithValue(
      const VisiteObservationDemo(),
    ),
    portHistoriqueObservationsProvider.overrideWithValue(
      const HistoriqueObservationsDemo(),
    ),
    // Presence (Accueil, verification prealable) et pieces signees (Compte).
    servicePresenceProvider.overrideWithValue(const PresenceDemo()),
    acceptationsProvider.overrideWith((Ref ref) async => const <Acceptation>[]),
  ];
}

/// Valeur du parametre qui ouvre la demonstration admin (AD-4).
const String valeurDemoAdmin = 'admin';

/// Vrai si l'adresse demande la demonstration admin.
bool demoAdminDemandee(Uri adresse) =>
    adresse.queryParameters[parametreDemo]?.trim().toLowerCase() ==
    valeurDemoAdmin;

/// La garde admin, meme porte compilee que celle du tuteur.
bool demoAdminActive({required Uri adresse, required String environnement}) =>
    environnementAutoriseDemo(environnement) && demoAdminDemandee(adresse);

/// La garde admin appliquee a la compilation et a l'adresse d'ouverture.
bool get demoAdminActiveIci =>
    demoAdminActive(adresse: Uri.base, environnement: Env.environnement);

/// Le delai avant l'arrivee d'une alerte urgente dans la demonstration admin
/// (ALERTE-1) : assez long pour regarder la page d'abord.
const Duration dureeArriveeAlerteDemo = Duration(seconds: 20);

/// Les surcharges de la demonstration admin.
///
/// Une seule [EtatRevueDemo] partagee par les doubles : une bascule de
/// politique se voit dans la file. Leve une [StateError] en production.
/// [avecAlertes] (ALERTE-1) : la visite montre des alertes fictives, une
/// urgente en tete ; [arriveeAlerte] : le delai avant qu'une seconde alerte
/// urgente arrive en cours de visite, sans recharger. Sans [avecAlertes]
/// (defaut, tests des autres ecrans), la source des alertes reste celle de
/// la production : indisponible, ni cloche ni bandeau.
List<Override> surchargesDemoAdmin({
  String? environnement,
  EtatRevueDemo? etat,
  bool avecAlertes = false,
  Duration? arriveeAlerte,
  PortBibliothequeAdmin? bibliotheque,
  bool bibliothequeAbsente = false,
}) {
  if (!environnementAutoriseDemo(environnement ?? Env.environnement)) {
    throw StateError('Demonstration interdite en production.');
  }
  final EtatRevueDemo e = etat ?? EtatRevueDemo.initial();
  // CLASSE-FORM-1 : une classe creee en demonstration se voit dans la liste
  // et compte dans la charge de son enseignant.
  final ClassesCreeesDemo creees = ClassesCreeesDemo();
  final RegroupementsDemo regroupementsPortDemo = RegroupementsDemo(
    depart: <RegroupementDemandes>[
      ...regroupementsDemo(),
      ...regroupementsVolumeDemo(),
    ],
  );
  // R9, R10 : fusions et transferts, calcules des classes avant mouvement.
  // Les deux se referencent : la fusion lit les classes, les classes lisent
  // ce que la fusion a change.
  late final FusionDemo fusionDemo;
  // La liste des classes suit les enseignants confirmes pendant la visite et
  // les fusions et transferts ; le tableau de pilotage se recalcule depuis
  // les deux.
  final ClassesAdminDemo classesAdminDemo = ClassesAdminDemo(
    creees: creees,
    classes: <ClasseListee>[
      ...familleDemo(),
      ...<GroupeAdmin>[...groupesDemo()].map(ClasseListee.depuisGroupe),
      ...volumeDemo(),
    ],
    enseignantAffecte: (String classeId) =>
        regroupementsPortDemo.enseignantDe[classeId],
    // ignore: unnecessary_lambdas, la fusion n'est affectee qu'apres.
    ajuster: (ClasseListee c) => fusionDemo.ajuster(c),
  );
  fusionDemo = FusionDemo(classes: classesAdminDemo.toutesBrutes);
  return <Override>[
    sourceSessionProvider.overrideWithValue(const SourceSessionDemoAdmin()),
    portRevueDossiersProvider.overrideWithValue(RevueDossiersDemo(e)),
    portPolitiqueRevueKycProvider.overrideWithValue(PolitiqueRevueKycDemo(e)),
    // L'ecran ADM-02 actuel et l'Accueil admin : aucun appel serveur.
    serviceValidationProvider.overrideWithValue(ServiceValidationDemo(e)),
    indicateursProvider.overrideWith(
      (Ref ref) async => IndicateursAdmin(
        dossiersEnAttente: e.nombreAVerifier,
        foyersSansEnseignant: 0,
        rapportsManquants: 0,
        incidents24h: 0,
        comptesEchus: 0,
        // AD-X : les deux demandes fictives de l'Espace de traitement.
        demandesEnAttente: 2,
      ),
    ),
    demandesProvider.overrideWith(
      (Ref ref) async => demandesDemo(e.maintenant.toLocal()),
    ),
    // AD-X : les classes fictives (collection et inspecteur, ADM-09). Seule
    // la creation ecrit (CLASSE-FORM-1, en memoire) ; ajouter, retirer et
    // cloturer restent « indisponibles ».
    groupesProvider.overrideWith((Ref ref) async => creees.toutes()),
    // R16, R17 : la liste paginee des classes, a grande echelle (30 classes
    // paralleles de meme cle, un grand volume simule, les classes creees).
    portClassesAdminProvider.overrideWithValue(classesAdminDemo),
    portFusionClassesProvider.overrideWithValue(fusionDemo),
    // ECHELLE-CTRL-DIRECT-1 : les regles et l'historique audite des tirages.
    portTirageControleProvider.overrideWithValue(TirageDemo()),
    // ECHELLE-ADM-PILOTAGE-1 : le tableau de pilotage par horaire.
    portPilotageProvider.overrideWithValue(
      PilotageDemo(
        classes: classesAdminDemo.toutes,
        regroupements: regroupementsPortDemo.regroupements,
      ),
    ),
    portEnseignantsClasseProvider.overrideWithValue(
      EnseignantsClasseDemo(creees),
    ),
    portCreationClasseProvider.overrideWithValue(CreationClasseDemo(creees)),
    // OFFRES-ADM-1 : les demandes semblables reunies, en memoire.
    // ECHELLE-ADM-LISTES-1 : 10 000 demandes simulees, paginees par le port.
    portRegroupementsAdminProvider.overrideWithValue(regroupementsPortDemo),
    portRegroupementsPagesProvider.overrideWithValue(regroupementsPortDemo),
    // RECRUT-ECRANS : les invitations d'enseignants (admin et verification du
    // code par le candidat) et les statuts de signature des dossiers.
    ...surchargesInvitationsDemo(),
    portStatutsSignatureProvider.overrideWithValue(
      const StatutsSignatureDemo(),
    ),
    membresGroupeProvider.overrideWith(
      (Ref ref, String groupeId) async => membresDemo(groupeId),
    ),
    // AD-X : la colonne « Activite recente » de l'Accueil, fictive.
    activiteRecenteProvider.overrideWith(
      (Ref ref) async => activiteRecenteDemo(e.maintenant.toLocal()),
    ),
    // CARTES-PERSO-1c (revue CARTES-PERSO-1b, reserve 2) : la direction lit
    // les memes cartes de demonstration que l'enseignant et le tuteur, en
    // lecture seule. Le retrait par la direction est une ecriture serveur
    // (CARTES-BR-02) : la capacite reste fausse, aucune ecriture simulee.
    portCartesClasseProvider.overrideWith(
      (Ref _) => PortCartesClasseDemo(
        peutModifier: false,
        cartes: cartesClasseDemo(DateTime.now()),
      ),
    ),
    // ALERTE-1 : alertes fictives, une urgente en tete ; une seconde urgente
    // arrive en cours de visite, sans recharger (temps reel simule).
    if (avecAlertes)
      portAlertesProvider.overrideWithValue(
        AlertesDemo(arrivee: arriveeAlerte),
      ),
    // La Vue globale de la Finance (FI-11a) : les chiffres de la
    // demonstration, jamais en production (K-09).
    portFinanceDirectionProvider.overrideWithValue(
      const FinanceDirectionDemo(),
    ),
    // Les Politiques commerciales (FI-11b) : la version de lancement et un
    // brouillon ; la publication reste indisponible, ici aussi.
    portPolitiquesCommercialesProvider.overrideWithValue(
      const PolitiquesCommercialesDemo(),
    ),
    // Tous les autres services admin adosses a Supabase : « indisponible ».
    ...surchargesServicesAdminIndisponibles(),
    // CAP29-0 : la bibliotheque d'administration, en demonstration.
    // [bibliotheque] pose un autre double (tests) ; [bibliothequeAbsente]
    // laisse le port nul, comme en production.
    if (!bibliothequeAbsente)
      portBibliothequeAdminProvider.overrideWithValue(
        bibliotheque ?? BibliothequeAdminDemo(),
      ),
  ];
}

/// Parametre d'adresse de la variante « profil a completer » (9.8).
const String parametreProfilDemo = 'profil';

/// Valeur qui simule un relecteur dont le genre n'est pas renseigne.
const String valeurProfilACompleter = 'a-completer';

/// L'etat de depart de la demonstration admin selon l'adresse :
/// `?demo=admin&profil=a-completer` rend la variante « Profil a completer ».
EtatRevueDemo etatRevueDemoPour(Uri adresse) => EtatRevueDemo.initial(
  genreRelecteurRenseigne:
      adresse.queryParameters[parametreProfilDemo]?.trim().toLowerCase() !=
      valeurProfilACompleter,
);

/// Session admin fictive, resolue tout de suite, sans Supabase. Aucune
/// valeur `super_admin` dans [AppRole] (Q40).
class SourceSessionDemoAdmin implements SourceSession {
  const SourceSessionDemoAdmin();

  static const SessionState etat = SessionState(
    resolue: true,
    role: AppRole.admin,
    profileId: 'demo-admin',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );

  @override
  Stream<SessionState> etats() => Stream<SessionState>.value(etat);

  @override
  Future<void> rafraichir() async {}
}

/// Parametre d'adresse du dossier de la personne en demonstration (AD-10).
const String parametreDossierDemo = 'dossier';

/// K-47 (HL-A-6) : DEMONSTRATION ENSEIGNANT. La titulaire est une enseignante
/// (la piece ne concerne jamais le tuteur) ; l'adresse garde `demo=tuteur`
/// pour ne pas casser les liens existants, mais ne montre AUCUN parcours
/// tuteur. Le parcours tuteur voulu est `?demo=tuteur` sans `dossier` :
/// arrivee directe sur /tuteur (capture HL-A-5 n° 15).
/// ?demo=tuteur&dossier=refuse|refuse-fige|verification : la personne est
/// Amina Benali, titulaire d'un dossier refuse (motif fictif), refuse sans
/// correction permise (AD-BR-28), ou en cours de verification.
/// Nul sans ce parametre : la demonstration tuteur habituelle.
({EtatRevueDemo dossiers, String titulaire})? dossierTitulaireDemoPour(
  Uri adresse, {
  DateTime? maintenant,
}) {
  final String? v = adresse.queryParameters[parametreDossierDemo]
      ?.trim()
      .toLowerCase();
  if (v != 'refuse' && v != 'refuse-fige' && v != 'verification') {
    return null;
  }
  final EtatRevueDemo e = EtatRevueDemo.initial(maintenant: maintenant);
  const String id = DonneesDossiersDemo.enseignantDocumentaire;
  if (v != 'verification') {
    e.dossiers[id]!
      ..statut = StatutRevue.refuse
      ..motifRefus = 'Motif fictif : la photo de la pièce est floue.'
      ..correctionAutorisee = v == 'refuse-fige' ? false : null;
  }
  return (dossiers: e, titulaire: id);
}

/// La session du titulaire d'un dossier de demonstration (AD-10) : son statut
/// de compte suit l'etat partage, relu a chaque [rafraichir], comme le
/// rafraichissement de jeton relit le profil en production.
class SourceSessionDemoTitulaire implements SourceSession {
  SourceSessionDemoTitulaire(this.dossiers, this.titulaire);

  final EtatRevueDemo dossiers;
  final String titulaire;
  final StreamController<SessionState> _flux =
      StreamController<SessionState>.broadcast();

  SessionState get _etat {
    final DossierDemo d = dossiers.dossiers[titulaire]!;
    return SessionState(
      resolue: true,
      role: d.role,
      householdId: d.role == AppRole.guardian ? DonneesDemo.foyerId : null,
      profileId: d.id,
      accountStatus: d.etatCompte,
      lectureProfil: LectureProfil.presente,
    );
  }

  @override
  Stream<SessionState> etats() async* {
    yield _etat;
    yield* _flux.stream;
  }

  @override
  Future<void> rafraichir() async => _flux.add(_etat);
}

/// Donnees fictives partagees par les doubles.
abstract final class DonneesDemo {
  static const String foyerId = 'demo-foyer';
  static const String tuteurId = 'demo-tuteur';
  static const String aichaId = 'demo-eleve-aicha';
  static const String yusufId = 'demo-eleve-yusuf';
  static const String groupeAicha = 'demo-groupe-coran-1';
  static const String groupeYusuf = 'demo-groupe-arabe-1';

  static final DateTime finAcces = DateTime.utc(2099, 12, 31);

  static final List<EleveDuFoyer> eleves = <EleveDuFoyer>[
    EleveDuFoyer(
      id: aichaId,
      prenom: 'Aïcha',
      identifiantImmuable: 'DEMO-A1',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
      finAcces: finAcces,
    ),
    EleveDuFoyer(
      id: yusufId,
      prenom: 'Yusuf',
      identifiantImmuable: 'DEMO-Y1',
      mode: InterfaceMode.standard,
      camera: CameraPolicy.allowed,
      finAcces: finAcces,
    ),
  ];

  static const EnseignantVM enseignante = EnseignantVM(
    enseignantId: 'demo-enseignante',
    titre: TitreEnseignant.sayyida,
    nomAffichage: 'Maryam',
    pays: 'Maroc',
  );

  static const EnseignantVM enseignant = EnseignantVM(
    enseignantId: 'demo-enseignant',
    titre: TitreEnseignant.sayyid,
    nomAffichage: 'Ibrahim',
    pays: 'France',
  );

  static const Map<String, GroupSummaryVM> classes = <String, GroupSummaryVM>{
    aichaId: GroupSummaryVM(
      groupeId: groupeAicha,
      libelle: 'Coran, niveau 1',
      couleurJeton: JetonCouleurGroupe(index: 0, codeStable: 'demo-0'),
      enseignant: enseignante,
      nombreMembres: 5,
      seuilMax: 8,
      typePublic: TypePublicGroupeVM.enfant,
      actif: true,
      nomCours: 'Coran',
    ),
    yusufId: GroupSummaryVM(
      groupeId: groupeYusuf,
      libelle: 'Arabe, niveau 2',
      couleurJeton: JetonCouleurGroupe(index: 1, codeStable: 'demo-1'),
      enseignant: enseignant,
      nombreMembres: 6,
      seuilMax: 8,
      typePublic: TypePublicGroupeVM.enfant,
      actif: true,
      nomCours: 'Arabe',
    ),
  };
}

/// Session tuteur fictive, resolue tout de suite, sans Supabase.
class SourceSessionDemo implements SourceSession {
  const SourceSessionDemo();

  static const SessionState etat = SessionState(
    resolue: true,
    role: AppRole.guardian,
    householdId: DonneesDemo.foyerId,
    profileId: DonneesDemo.tuteurId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );

  @override
  Stream<SessionState> etats() => Stream<SessionState>.value(etat);

  @override
  Future<void> rafraichir() async {}
}

/// Acces fictifs : les deux eleves sont actifs.
class AccesFoyerDemo implements PortAccesFoyer {
  const AccesFoyerDemo();

  @override
  Future<List<AccesBeneficiaire>> acces() async => <AccesBeneficiaire>[
    for (final EleveDuFoyer e in DonneesDemo.eleves)
      AccesBeneficiaire(
        eleveId: e.id,
        prenom: e.prenom,
        finAcces: e.finAcces,
        etatAffiche: EtatAccesAffiche.actif,
      ),
  ];
}

/// Une classe fictive par eleve.
class ClassesFoyerDemo implements PortClassesFoyer {
  const ClassesFoyerDemo();

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async {
    final GroupSummaryVM? c = DonneesDemo.classes[eleveId];
    return c == null
        ? const <ClasseFoyer>[]
        : <ClasseFoyer>[ClasseFoyer(eleveId: eleveId, classe: c)];
  }

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async {
    final GroupSummaryVM? c = DonneesDemo.classes[eleveId];
    return c != null && c.groupeId == groupeId
        ? ClasseFoyer(eleveId: eleveId, classe: c)
        : null;
  }
}

/// Seances fictives : chaque eleve a trois seances passees (historique) et
/// une a venir, calculees a partir de l'instant d'ouverture.
class SeancesFamilleDemo implements PortSeancesFamille {
  SeancesFamilleDemo({DateTime? maintenant})
    : _seances = _fabriquer((maintenant ?? DateTime.now()).toUtc());

  final List<SeanceFamille> _seances;

  static List<SeanceFamille> _fabriquer(DateTime maintenant) {
    final DateTime base = DateTime.utc(
      maintenant.year,
      maintenant.month,
      maintenant.day,
      16,
    );
    return <SeanceFamille>[
      for (final EleveDuFoyer e in DonneesDemo.eleves)
        for (final int jours in <int>[-14, -7, -2, 2])
          SeanceFamille(
            seanceId: 'demo-seance-${e.id}-$jours',
            eleveId: e.id,
            groupeId: DonneesDemo.classes[e.id]!.groupeId,
            debutUtc: base.add(Duration(days: jours)),
            finPrevueUtc: base.add(Duration(days: jours, minutes: 45)),
            enseignant: EnseignantSeance(
              prenom: DonneesDemo.classes[e.id]!.enseignant.nomAffichage,
              titre: DonneesDemo.classes[e.id]!.enseignant.titre,
              pays: DonneesDemo.classes[e.id]!.enseignant.pays,
            ),
          ),
    ];
  }

  DateTime get _maintenant => DateTime.now().toUtc();

  Iterable<SeanceFamille> _de(String? eleveId) => _seances.where(
    (SeanceFamille s) => eleveId == null || s.eleveId == eleveId,
  );

  @override
  Future<SeanceFamille?> prochaine(String eleveId) async {
    final List<SeanceFamille> a = _de(eleveId)
        .where((SeanceFamille s) => s.debutUtc.isAfter(_maintenant))
        .toList();
    return a.isEmpty ? null : a.first;
  }

  @override
  Future<SeanceFamille?> derniere(String eleveId) async {
    final List<SeanceFamille> p = _de(eleveId)
        .where((SeanceFamille s) => !s.debutUtc.isAfter(_maintenant))
        .toList();
    return p.isEmpty ? null : p.last;
  }

  @override
  Future<List<SeanceFamille>> historique({
    String? eleveId,
    DateTimeRange? periode,
  }) async => _de(eleveId)
      .where(
        (SeanceFamille s) =>
            !s.debutUtc.isAfter(_maintenant) &&
            (periode == null ||
                (!s.debutUtc.isBefore(periode.start.toUtc()) &&
                    s.debutUtc.isBefore(periode.end.toUtc()))),
      )
      .toList()
      .reversed
      .toList();

  @override
  Future<SeanceFamille?> seance(String seanceId, {String? eleveId}) async {
    for (final SeanceFamille s in _de(eleveId)) {
      if (s.seanceId == seanceId) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<List<SeanceFamille>> planning({
    required String groupeId,
    required String eleveId,
    required DateTimeRange periode,
  }) async => _de(eleveId)
      .where(
        (SeanceFamille s) =>
            s.groupeId == groupeId &&
            !s.debutUtc.isBefore(periode.start.toUtc()) &&
            s.debutUtc.isBefore(periode.end.toUtc()),
      )
      .toList();

  @override
  Future<DateTime> maintenantServeurUtc() async => _maintenant;

  @override
  Stream<SeanceFamille> suivre(String seanceId, {String? eleveId}) async* {
    final SeanceFamille? s = await seance(seanceId, eleveId: eleveId);
    if (s == null) {
      throw SeanceIntrouvable(seanceId);
    }
    yield s;
  }
}

/// L'echeance d'acces de [profilId] dans le jeu Finance [jeu].
DateTime? _finAccesDemo(JeuFoyerFinance jeu, String profilId) {
  for (final AccesBeneficiaire a in DonneesFinanceDemo.acces(jeu)) {
    if (a.eleveId == profilId) return a.finAcces;
  }
  return null;
}

/// Les deux ports d'invitation, portes par un meme objet en memoire : ce que
/// l'administration cree, le candidat peut le verifier.
List<Override> surchargesInvitationsDemo() {
  final InvitationsDemo invitations = InvitationsDemo();
  return <Override>[
    portInvitationsEnseignantProvider.overrideWithValue(invitations),
    portVerificationInvitationProvider.overrideWithValue(invitations),
  ];
}
