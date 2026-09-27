/// Les personnes simulees du Playground.
///
/// Une personne est un ensemble fixe de surcharges : la source de session
/// (porte d'acces), les sept services de l'application et les depots locaux, le
/// tout rempli de donnees relatives a aujourd'hui. Changer de personne monte la
/// vraie application sous un nouveau `ProviderScope` : les ecrans, le routeur et
/// le theme restent identiques, seules les donnees dessous changent.
///
/// **Aucune donnee de produit n'est invente ici.** Chaque champ suit la forme
/// du modele reel (voir les `depuisJson` qui font foi en production), et aucun
/// libelle n'apparait sous deux formes : une personne porte toujours la meme
/// famille, le meme enseignant et les memes eleves qu'une autre, pour que la
/// bench raconte une histoire coherente d'un role a l'autre.
///
/// Les libelles du menu sont des donnees de banc d'essai : ils peuvent etre
/// accents ou non, ce ne sont pas des libelles de produit.
library;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

import 'faux.dart';

/// Tout ce qu'une personne porte comme donnees, avant montage.
///
/// Les valeurs par defaut sont les etats neutres que le produit sait afficher :
/// un dossier sans profil, six compteurs a zero, aucune seance, aucun creneau.
class Graine {
  // ignore: prefer_const_constructors_in_immutables
  Graine({
    required this.session,
    this.etatDossier = const EtatDossier.sansProfil(),
  });

  /// L'etat de session, qui decide de la porte d'acces.
  final SessionState session;

  /// L'etat du dossier de KYC, lu par le portail d'attente.
  EtatDossier etatDossier;

  /// Les eleves du foyer.
  List<EleveDuFoyer> eleves = const <EleveDuFoyer>[];

  /// Les appareils appaires du foyer.
  List<AppareilAppaire> appareils = const <AppareilAppaire>[];

  /// Les seances de l'appelant.
  List<Seance> seances = const <Seance>[];

  /// Les affectations qui concernent l'appelant.
  List<Affectation> affectations = const <Affectation>[];

  /// Les creneaux poses, par profil.
  Map<String, List<Creneau>> creneaux = const <String, List<Creneau>>{};

  /// Le feed d'eleves sans enseignant.
  List<EleveEnAttente> feed = const <EleveEnAttente>[];

  /// La file des demandes de l'administration.
  List<Demande> demandes = const <Demande>[];

  /// La file des dossiers KYC a valider.
  List<DossierAValider> dossiers = const <DossierAValider>[];

  /// Les six compteurs de l'administration.
  IndicateursAdmin indicateurs = const IndicateursAdmin(
    dossiersEnAttente: 0,
    foyersSansEnseignant: 0,
    rapportsManquants: 0,
    incidents24h: 0,
    comptesEchus: 0,
    demandesEnAttente: 0,
  );

  /// Les regles d'un profil, par profil.
  Map<String, List<RegleProfil>> regles = const <String, List<RegleProfil>>{};

  /// Les surcharges closes d'un profil, par profil.
  Map<String, List<SurchargeClose>> historique =
      const <String, List<SurchargeClose>>{};

  /// Les reglages de priere, par enseignant.
  Map<String, ReglagesPriere> prieres = const <String, ReglagesPriere>{};

  /// Les profils locaux de l'appareil, pour la connexion eleve.
  List<ProfilLocal> profilsLocaux = const <ProfilLocal>[];

  /// Vrai pour monter l'application hors ligne.
  bool horsLigne = false;
}

/// Une personne simulee, prete a monter.
class Persona {
  /// Cree la personne.
  Persona({required this.id, required this.libelle, required this.surcharges});

  /// Identifiant stable, qui sert de cle au `ProviderScope`.
  final String id;

  /// Libelle du menu, donnee de banc d'essai.
  final String libelle;

  /// Les surcharges qui remplacent toute l'infrastructure reelle.
  final List<Override> surcharges;
}

/// Monte une personne a partir de sa graine.
///
/// Le motif reprend `test/support/harnais.dart`: les ecrans lisent des
/// providers derives qui, eux, lisent toujours le service de leur domaine. Il
/// suffit donc de remplacer les services pour rendre toute l'application
/// hors ligne, exactement comme un test de widget.
///
/// Les selecteurs de fichier et de photo pointent sur `null` : le Playground
/// simule un abandon de selection, comme un utilisateur qui fermerait la boite
/// de dialogue. Les ecrans doivent l'afficher comme un echec sans panne.
Persona personne({
  required String id,
  required String libelle,
  required Graine graine,
}) {
  final FausseSourceSession source = FausseSourceSession(graine.session);
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = graine.etatDossier;
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = graine.eleves
    ..appareilsRendus = graine.appareils;
  final FauxServicePlanning planning = FauxServicePlanning()
    ..seancesRendues = graine.seances
    ..affectationsRendues = graine.affectations
    ..creneaux.addAll(graine.creneaux);
  final FauxServiceMatching matching = FauxServiceMatching()
    ..feed = graine.feed;
  final FauxServiceAdmin admin = FauxServiceAdmin()
    ..indicateursRendus = graine.indicateurs
    ..file = graine.demandes;
  final FauxServiceValidation validation = FauxServiceValidation()
    ..file = graine.dossiers;
  final FauxServiceRegles regles = FauxServiceRegles()
    ..parProfil.addAll(graine.regles)
    ..historiqueParProfil.addAll(graine.historique);
  final FauxServicePriere priere = FauxServicePriere()
    ..parEnseignant.addAll(graine.prieres);
  final FauxProfilsLocaux profilsLocaux = FauxProfilsLocaux()
    ..profils = graine.profilsLocaux;

  return Persona(
    id: id,
    libelle: libelle,
    surcharges: <Override>[
      sourceSessionProvider.overrideWithValue(source),
      serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
      serviceDossierProvider.overrideWithValue(dossier),
      serviceAppairageProvider.overrideWithValue(appairage),
      serviceAvatarProvider.overrideWithValue(FauxServiceAvatar()),
      selecteurPhotoProvider.overrideWithValue(FauxSelecteurPhoto(null)),
      selecteurFichierProvider.overrideWithValue(FauxSelecteurFichier(null)),
      serviceValidationProvider.overrideWithValue(validation),
      servicePlanningProvider.overrideWithValue(planning),
      serviceMatchingProvider.overrideWithValue(matching),
      serviceAdminProvider.overrideWithValue(admin),
      serviceReglesProvider.overrideWithValue(regles),
      servicePriereProvider.overrideWithValue(priere),
      serviceReseauProvider.overrideWithValue(
        FauxServiceReseau(horsLigneRendu: graine.horsLigne),
      ),
      profilsLocauxProvider.overrideWithValue(profilsLocaux),
      stockageSecuriseProvider.overrideWithValue(FauxStockageSecurise()),
      serviceEnfantProvider.overrideWithValue(FauxServiceEnfant()),
    ],
  );
}

/// Monte une personne sans aucune donnee de domaine, uniquement sa session.
Persona _personneSimple({
  required String id,
  required String libelle,
  required SessionState session,
}) => personne(
  id: id,
  libelle: libelle,
  graine: Graine(session: session),
);

/// La famille commune a toutes les personnes.
///
/// Le tuteur est `p-g`, son foyer `f-1` ; les eleves sont `e-1` (Houriya) et
/// `e-2` (Sami) ; l'enseignant est `t-1` (Youssef). Les memes identifiants
/// relient les seances, les affectations et les regles d'une personne a
/// l'autre : c'est ce qui fait que la bench raconte une seule histoire.
const String foyer = 'f-1';
const String tuteur = 'p-g';
const String enseignant = 't-1';
const String enseignantPrenom = 'Youssef';
const String eleve1 = 'e-1';
const String prenom1 = 'Houriya';
const String eleve2 = 'e-2';
const String prenom2 = 'Sami';

/// Toutes les personnes de la bench, dans l'ordre des portes d'acces.
List<Persona> personasDuBench({required DateTime maintenant}) => <Persona>[
  _personneSimple(
    id: 'visiteur',
    libelle: 'Visiteur deconnecte',
    session: const SessionState.deconnecte(),
  ),
  _personneSimple(
    id: 'inscription',
    libelle: 'Compte sans profil',
    session: const SessionState(
      resolue: true,
      profileId: 'p-nouveau',
      lectureProfil: LectureProfil.absente,
    ),
  ),
  personne(
    id: 'famille-incomplet',
    libelle: 'Famille - dossier incomplet',
    graine: Graine(
      session: _sessionTuteur(AccountStatus.pendingKyc),
      etatDossier: const EtatDossier(
        profilExiste: true,
        role: AppRole.guardian,
        statutCompte: AccountStatus.pendingKyc,
      ),
    ),
  ),
  personne(
    // K-47 (HL-A-6) : le tuteur ne depose aucune piece ; accords signes, il
    // attend seulement l'ouverture de son acces (BR-1). Plus de persona
    // famille « en verification » ni « piece refusee ».
    id: 'famille-acces',
    libelle: 'Famille - acces en preparation',
    graine: Graine(
      session: _sessionTuteur(AccountStatus.pendingKyc),
      etatDossier: const EtatDossier(
        profilExiste: true,
        role: AppRole.guardian,
        statutCompte: AccountStatus.pendingKyc,
        contratSigne: true,
        accuseSigne: true,
      ),
    ),
  ),
  _personneSimple(
    id: 'suspendu',
    libelle: 'Famille - compte suspendu',
    session: _sessionTuteur(AccountStatus.disabled),
  ),
  personne(
    id: 'eleve-standard',
    libelle: 'Eleve (interface standard)',
    graine: _graineEleve(InterfaceMode.standard, maintenant),
  ),
  personne(
    id: 'eleve-enfant',
    libelle: 'Eleve (interface enfant)',
    graine: _graineEleve(InterfaceMode.enfant, maintenant),
  ),
  personne(
    id: 'enseignant',
    libelle: 'Enseignant',
    graine: _graineEnseignant(maintenant),
  ),
  personne(
    id: 'tuteur',
    libelle: 'Tuteur (famille active)',
    graine: _graineTuteur(maintenant),
  ),
  personne(
    id: 'admin',
    libelle: 'Administrateur',
    graine: _graineAdmin(maintenant),
  ),
  _personneSimple(
    id: 'comptable',
    libelle: 'Comptable',
    session: const SessionState(
      resolue: true,
      role: AppRole.accountant,
      householdId: foyer,
      profileId: 'p-c',
      accountStatus: AccountStatus.active,
      lectureProfil: LectureProfil.presente,
    ),
  ),
  _personneSimple(
    id: 'controleur',
    libelle: 'Controleur',
    session: const SessionState(
      resolue: true,
      role: AppRole.controller,
      householdId: foyer,
      profileId: 'p-co',
      accountStatus: AccountStatus.active,
      lectureProfil: LectureProfil.presente,
    ),
  ),
];

/// La session d'un tuteur du foyer commun, dans un statut de compte donne.
SessionState _sessionTuteur(AccountStatus statut) => SessionState(
  resolue: true,
  role: AppRole.guardian,
  householdId: foyer,
  profileId: tuteur,
  accountStatus: statut,
  lectureProfil: LectureProfil.presente,
);

/// La graine d'un eleve du foyer, dans un mode d'interface donne.
Graine _graineEleve(InterfaceMode mode, DateTime maintenant) =>
    Graine(
        session: SessionState(
          resolue: true,
          role: AppRole.student,
          householdId: foyer,
          profileId: eleve1,
          accountStatus: AccountStatus.active,
          interfaceMode: mode,
          lectureProfil: LectureProfil.presente,
        ),
      )
      ..seances = <Seance>[
        _seance(
          id: 's-1',
          debut: maintenant.subtract(const Duration(hours: 2)),
          statut: StatutSeance.terminee,
          minutesInterruption: 5,
        ),
        _seance(
          id: 's-2',
          debut: maintenant.add(const Duration(minutes: 30)),
          statut: StatutSeance.planifiee,
        ),
      ]
      ..affectations = <Affectation>[
        Affectation(
          id: 'a-1',
          enseignantId: enseignant,
          enseignantPrenom: enseignantPrenom,
          enseignantIdentifiant: 'imm-t-1',
          eleveId: eleve1,
          elevePrenom: prenom1,
          creneau: Creneau(
            jour: maintenant.weekday,
            heure: 16,
            fuseau: 'Europe/Paris',
          ),
          depuis: maintenant.subtract(const Duration(days: 30)),
        ),
      ]
      ..prieres = <String, ReglagesPriere>{enseignant: _reglagesPriere()};

/// La graine de l'enseignant : creneaux, feed, regles bornees en base.
Graine _graineEnseignant(DateTime maintenant) =>
    Graine(
        session: const SessionState(
          resolue: true,
          role: AppRole.teacher,
          householdId: foyer,
          profileId: enseignant,
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
        ),
      )
      ..seances = <Seance>[
        _seance(
          id: 's-1',
          debut: maintenant.subtract(const Duration(hours: 2)),
          statut: StatutSeance.terminee,
          minutesInterruption: 5,
        ),
        _seance(id: 's-2', debut: maintenant, statut: StatutSeance.planifiee),
      ]
      ..affectations = <Affectation>[
        Affectation(
          id: 'a-1',
          enseignantId: enseignant,
          enseignantPrenom: enseignantPrenom,
          enseignantIdentifiant: 'imm-t-1',
          eleveId: eleve1,
          elevePrenom: prenom1,
          creneau: Creneau(
            jour: maintenant.weekday,
            heure: 16,
            fuseau: 'Europe/Paris',
          ),
          depuis: maintenant.subtract(const Duration(days: 30)),
        ),
        Affectation(
          id: 'a-2',
          enseignantId: enseignant,
          enseignantPrenom: enseignantPrenom,
          enseignantIdentifiant: 'imm-t-1',
          eleveId: eleve2,
          elevePrenom: prenom2,
          creneau: Creneau(
            jour: maintenant.weekday,
            heure: 18,
            fuseau: 'Europe/Paris',
          ),
          depuis: maintenant.subtract(const Duration(days: 10)),
        ),
      ]
      ..creneaux = <String, List<Creneau>>{
        enseignant: <Creneau>[
          Creneau(
            jour: maintenant.weekday,
            heure: 16,
            fuseau: 'Europe/Paris',
            poseLe: maintenant.subtract(const Duration(days: 30)),
          ),
          Creneau(
            jour: maintenant.weekday,
            heure: 18,
            fuseau: 'Europe/Paris',
            poseLe: maintenant.subtract(const Duration(days: 20)),
          ),
        ],
      }
      ..feed = <EleveEnAttente>[
        EleveEnAttente(
          eleveId: 'e-3',
          prenom: 'Amina',
          identifiantImmuable: 'imm-e-3',
          creneau: Creneau(
            jour: maintenant.weekday,
            heure: 16,
            fuseau: 'Europe/Paris',
          ),
          depuis: maintenant.subtract(const Duration(days: 5)),
          mode: InterfaceMode.standard,
        ),
      ]
      ..regles = <String, List<RegleProfil>>{
        enseignant: <RegleProfil>[
          _regle(
            cle: CleRegle.plafondEleves,
            effective: 4,
            plateforme: 6,
            surchargeId: 'r-1',
            motif: 'Foyer deja accompagne hors plateforme',
            poseeLe: maintenant.subtract(const Duration(days: 20)),
          ),
          _regle(
            cle: CleRegle.pauseEntreCours,
            effective: 10,
            plateforme: 15,
            surchargeId: 'r-2',
            motif: 'Ajuste au planning du foyer',
            poseeLe: maintenant.subtract(const Duration(days: 15)),
          ),
        ],
      }
      ..prieres = <String, ReglagesPriere>{enseignant: _reglagesPriere()};

/// La graine du tuteur d'un foyer actif avec deux enfants.
Graine _graineTuteur(DateTime maintenant) =>
    Graine(
        session: const SessionState(
          resolue: true,
          role: AppRole.guardian,
          householdId: foyer,
          profileId: tuteur,
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
        ),
      )
      ..eleves = <EleveDuFoyer>[
        const EleveDuFoyer(
          id: eleve1,
          prenom: prenom1,
          identifiantImmuable: 'imm-e-1',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.allowed,
        ),
        const EleveDuFoyer(
          id: eleve2,
          prenom: prenom2,
          identifiantImmuable: 'imm-e-2',
          mode: InterfaceMode.enfant,
          camera: CameraPolicy.forbidden,
        ),
      ]
      ..appareils = <AppareilAppaire>[
        AppareilAppaire(
          id: 'app-1',
          profilId: eleve1,
          prenom: prenom1,
          plateforme: 'Windows',
          appaireA: maintenant.subtract(const Duration(days: 20)),
          derniereUtilisation: maintenant.subtract(const Duration(days: 1)),
        ),
        AppareilAppaire(
          id: 'app-2',
          profilId: eleve1,
          prenom: prenom1,
          plateforme: 'Android',
          appaireA: maintenant.subtract(const Duration(days: 2)),
        ),
      ]
      ..seances = <Seance>[
        _seance(
          id: 's-1',
          debut: maintenant.subtract(const Duration(hours: 2)),
          statut: StatutSeance.terminee,
          minutesInterruption: 5,
        ),
        _seance(
          id: 's-2',
          debut: maintenant.add(const Duration(minutes: 30)),
          statut: StatutSeance.planifiee,
        ),
        _seance(
          id: 's-3',
          debut: maintenant.add(const Duration(days: 1)),
          statut: StatutSeance.planifiee,
        ),
      ]
      ..affectations = <Affectation>[
        Affectation(
          id: 'a-1',
          enseignantId: enseignant,
          enseignantPrenom: enseignantPrenom,
          enseignantIdentifiant: 'imm-t-1',
          eleveId: eleve1,
          elevePrenom: prenom1,
          creneau: Creneau(
            jour: maintenant.weekday,
            heure: 16,
            fuseau: 'Europe/Paris',
          ),
          depuis: maintenant.subtract(const Duration(days: 30)),
        ),
      ]
      ..creneaux = <String, List<Creneau>>{
        eleve1: <Creneau>[
          Creneau(
            jour: maintenant.weekday,
            heure: 16,
            fuseau: 'Europe/Paris',
            poseLe: maintenant.subtract(const Duration(days: 3)),
          ),
        ],
        eleve2: <Creneau>[
          Creneau(
            jour: maintenant.weekday,
            heure: 18,
            fuseau: 'Europe/Paris',
            poseLe: aujourdhui(maintenant, 1),
          ),
        ],
      }
      ..regles = <String, List<RegleProfil>>{
        eleve1: <RegleProfil>[
          _regle(cle: CleRegle.dureeSeance, effective: 30, plateforme: 30),
          _regle(
            cle: CleRegle.minimumPayable,
            effective: 25,
            plateforme: 30,
            surchargeId: 'r-3',
            motif: 'Accord valide avec le tuteur',
            poseeLe: aujourdhui(maintenant, -7),
          ),
        ],
        eleve2: <RegleProfil>[
          _regle(cle: CleRegle.dureeSeance, effective: 30, plateforme: 30),
          _regle(cle: CleRegle.minimumPayable, effective: 25, plateforme: 30),
        ],
      };

/// La graine de l'administration : compteurs, dossiers et demandes.
Graine _graineAdmin(DateTime maintenant) =>
    Graine(
        session: const SessionState(
          resolue: true,
          role: AppRole.admin,
          householdId: foyer,
          profileId: 'a-1',
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
        ),
      )
      ..indicateurs = const IndicateursAdmin(
        dossiersEnAttente: 2,
        foyersSansEnseignant: 1,
        rapportsManquants: 3,
        incidents24h: 1,
        comptesEchus: 4,
        demandesEnAttente: 3,
      )
      ..dossiers = <DossierAValider>[
        DossierAValider(
          documentId: 'doc-1',
          profilId: 'p-d1',
          type: TypePiece.carteIdentite,
          cleObjet: 'kyc/doc-1.png',
          deposeLe: aujourdhui(maintenant, -1),
          prenom: 'Amina',
          nom: 'Benali',
          identifiantImmuable: 'imm-d1',
          role: AppRole.guardian,
        ),
        DossierAValider(
          documentId: 'doc-2',
          profilId: 'p-d2',
          type: TypePiece.passeport,
          cleObjet: 'kyc/doc-2.png',
          deposeLe: aujourdhui(maintenant, -2),
          prenom: 'Omar',
          nom: 'Haddad',
          identifiantImmuable: 'imm-d2',
          role: AppRole.teacher,
        ),
      ]
      ..demandes = <Demande>[
        Demande(
          id: 'dem-1',
          sorte: SorteDemande.reaffectation,
          sujetId: eleve1,
          sujetPrenom: prenom1,
          sujetIdentifiant: 'imm-e-1',
          motif: 'Changement d\'enseignant demande par le tuteur',
          roleDemandeur: AppRole.guardian,
          creeeLe: aujourdhui(maintenant, 0),
        ),
        Demande(
          id: 'dem-2',
          sorte: SorteDemande.plafond,
          sujetId: enseignant,
          sujetPrenom: enseignantPrenom,
          sujetIdentifiant: 'imm-t-1',
          motif: 'Foyer deja accompagne hors plateforme',
          roleDemandeur: AppRole.teacher,
          cleRegle: CleRegle.plafondEleves,
          valeurDemandee: 8,
          creeeLe: aujourdhui(maintenant, -2),
        ),
        Demande(
          id: 'dem-3',
          sorte: SorteDemande.regle,
          sujetId: eleve2,
          sujetPrenom: prenom2,
          sujetIdentifiant: 'imm-e-2',
          motif: 'Besoin d\'une seance plus longue pour progresser',
          roleDemandeur: AppRole.guardian,
          cleRegle: CleRegle.dureeSeance,
          valeurDemandee: 45,
          creeeLe: aujourdhui(maintenant, -1),
        ),
      ]
      ..regles = <String, List<RegleProfil>>{
        enseignant: <RegleProfil>[
          _regle(
            cle: CleRegle.plafondEleves,
            effective: 4,
            plateforme: 6,
            surchargeId: 'r-1',
            motif: 'Foyer deja accompagne hors plateforme',
            poseeLe: aujourdhui(maintenant, -20),
          ),
          _regle(
            cle: CleRegle.pauseEntreCours,
            effective: 10,
            plateforme: 15,
            poseeLe: aujourdhui(maintenant, -30),
          ),
        ],
        eleve2: <RegleProfil>[
          _regle(cle: CleRegle.dureeSeance, effective: 30, plateforme: 30),
          _regle(cle: CleRegle.minimumPayable, effective: 25, plateforme: 30),
        ],
      }
      ..historique = <String, List<SurchargeClose>>{
        enseignant: <SurchargeClose>[
          SurchargeClose(
            id: 'r-x',
            cle: CleRegle.plafondEleves,
            valeur: 5,
            motif: 'Foyer accompagne un temps',
            poseeLe: aujourdhui(maintenant, -60),
            closeLe: aujourdhui(maintenant, -20),
            motifCloture: 'Fin d\'accompagnement',
          ),
        ],
      };

/// Une seance a la forme de `mes_seances_v`, cote eleve et enseignant.
Seance _seance({
  required String id,
  required DateTime debut,
  required StatutSeance statut,
  int minutesInterruption = 0,
}) => Seance(
  id: id,
  debut: debut,
  fin: debut.add(const Duration(minutes: 30)),
  statut: statut,
  eleveId: eleve1,
  elevePrenom: prenom1,
  eleveIdentifiant: 'imm-e-1',
  enseignantId: enseignant,
  enseignantPrenom: enseignantPrenom,
  enseignantIdentifiant: 'imm-t-1',
  minutesInterruption: minutesInterruption,
);

/// Une regle a la forme de `regles_profil_v`.
RegleProfil _regle({
  required CleRegle cle,
  required int effective,
  required int plateforme,
  String? surchargeId,
  String? motif,
  DateTime? poseeLe,
}) => RegleProfil(
  cle: cle,
  valeurEffective: effective,
  valeurPlateforme: plateforme,
  surchargeId: surchargeId,
  motif: motif,
  poseeLe: poseeLe,
);

/// Des reglages de priere calculables, dans le fuseau de l'enseignant.
ReglagesPriere _reglagesPriere() => const ReglagesPriere(
  enseignantId: enseignant,
  latitude: 48.8566,
  longitude: 2.3522,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  fuseau: 'Europe/Paris',
  minutesPause: 10,
  minutesPreavis: 5,
  lieu: 'Paris',
);

/// Le jour a une heure fixe, jours relatifs a aujourd'hui.
///
/// C'est ce qui rend les seances et les fichiers « il y a deux jours » sans
/// jamais dater une seed en absolu : la bench doit raconter la meme histoire
/// aujourd'hui, demain et dans un mois.
DateTime aujourdhui(DateTime maintenant, int deltaJours) =>
    DateTime(maintenant.year, maintenant.month, maintenant.day + deltaJours);
