import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart'
    show TypePublicGroupe;
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
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/admin_demandes/demandes_page.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/appareils/ajouter_enfant_page.dart';
import 'package:rewayah_academy/features/appareils/appairage_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/bienvenue_page.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/disponibilites/disponibilites_page.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';
import 'package:rewayah_academy/features/eleve_connexion/eleve_connexion_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';
import 'package:rewayah_academy/features/revue_groupe/revue_groupe_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../support/harnais.dart';

/// Lot A1 : preuve, pour **chaque ecran reel construit du catalogue**
/// (`docs/archive/2026-09-pre-remise-a-plat/design/08-catalogue-ecrans.md`), que le rendu arabe (RTL, Bible V2
/// §14) et l'agrandissement a 200 % (§13.2) ne levent aucune exception.
///
/// `test/widgets/catalogue_galerie_test.dart` fait deja cette preuve, mais
/// seulement sur les **composants isoles** de la galerie, avec leurs etats
/// synthetiques. Ici, ce sont les **vingt-quatre ecrans reels**, montes avec
/// leurs propres services factices, qui sont rejoues. Un ecran qui deborderait
/// seulement a cause de sa propre mise en page (et pas d'un composant partage)
/// n'aurait ete vu par aucun autre test avant celui-ci.
///
/// **Le lot Enseignant en a ajoute quatre** (`ENS-01`, `ENS-04`, `ENS-07`,
/// `ENS-08`) et a donne au cinquieme, `ENS-02`, le service qui lui manquait
/// depuis le pivot du 19 septembre 2026. Le compte gele passe donc de vingt a
/// vingt-quatre : un ecran neuf absent de cette liste n'aurait AUCUNE preuve de
/// rendu arabe, et le compte gele est ce qui empeche de l'oublier en silence.
///
/// `ENS-03`, la salle, n'y figure toujours pas et ce n'est pas un oubli : elle
/// n'est pas une destination mais une surface immersive atteinte par un billet
/// (ADR-005), et ses quatre roles sont mesures par `test/features/salle_test.dart`
/// et `test/features/salle_enseignant_test.dart`, y compris a 390 sur 844 et a
/// 200 % d'echelle de texte.
///
/// Les ecrans encore marques « a construire » ou « hors MVP-0 » au catalogue
/// (`ADM-05`, `CTR-01`, `ELV-03`/`CTR-02`, `ELV-04`, `TUT-06`, `ADM-04`,
/// `CPT-01`) n'existent pas encore dans le code : rien a monter, rien a tester
/// avant qu'ils soient ecrits.

/// L'instant de reference des ecrans qui prennent une horloge
/// (`ELV-02`, `TUT-01`, `ADM-01`) : un mardi a dix-sept heures, comme leurs
/// tests fonctionnels respectifs.
final DateTime _horlogeFixe = DateTime(2026, 9, 8, 17);

const String _monId = 't1';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

/// Enveloppe un ecran sous une direction et une echelle de texte donnees.
///
/// Taille fixe et genereuse (390 de large, comme les deux autres axes de
/// verification de la galerie ; 8000 de haut, comme son groupe « 200 pour
/// cent », pour tolerer la croissance du contenu sans jamais la confondre
/// avec un vrai defaut de mise en page). `disableAnimations` evite qu'une
/// pulsation en boucle (`ELV-02`) ne laisse un minuteur arme a la fin du test.
Widget _enveloppe(
  Widget ecran, {
  required TextDirection direction,
  required double echelleTexte,
}) => MediaQuery(
  data: MediaQueryData(
    size: const Size(390, 8000),
    textScaler: TextScaler.linear(echelleTexte),
    disableAnimations: true,
  ),
  child: Directionality(textDirection: direction, child: ecran),
);

/// Une destination de retour pour les ecrans qui naviguent en fin de parcours.
GoRoute _portail() => GoRoute(
  path: Routes.attente,
  builder: (BuildContext _, GoRouterState _) =>
      const Scaffold(body: Text('portail')),
);

/// Un ecran a monter, avec son nom pour le message d'echec.
class _EcranAVerifier {
  const _EcranAVerifier(this.nom, this.construire);

  /// L'identifiant du catalogue, par exemple `TUT-00`.
  final String nom;

  /// Construit l'application montee, direction et echelle appliquees a
  /// l'ecran lui-meme (jamais au chrome de test).
  final Widget Function(TextDirection direction, double echelleTexte)
  construire;
}

/// Les vingt-quatre ecrans reels du catalogue, dans l'ordre de
/// `08-catalogue-ecrans.md`.
///
/// Les quatre ecrans du lot Enseignant sont groupes derriere `ENS-02` plutot que
/// disperses a leur rang de catalogue : ils partagent le meme
/// `FauxServiceEnseignant` et la meme session, et les lire ensemble dit ce qui
/// les relie.
List<_EcranAVerifier> _ecrans() => <_EcranAVerifier>[
  _EcranAVerifier(
    'TUT-00',
    (TextDirection d, double e) => hote(
      _enveloppe(const ConnexionPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ELV-01',
    (TextDirection d, double e) => hote(
      _enveloppe(const EleveConnexionPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        profilsLocauxProvider.overrideWithValue(FauxProfilsLocaux()),
        stockageSecuriseProvider.overrideWithValue(FauxStockageSecurise()),
        serviceEnfantProvider.overrideWithValue(FauxServiceEnfant()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-00c (inscription)',
    (TextDirection d, double e) => hote(
      _enveloppe(const InscriptionPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-00b (portail d attente)',
    (TextDirection d, double e) => hote(
      _enveloppe(const AttentePage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-00c/a (accuse)',
    (TextDirection d, double e) => hoteRoutant(
      depart: Routes.attenteAccuse,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attenteAccuse,
          builder: (BuildContext _, GoRouterState _) =>
              _enveloppe(const AccusePage(), direction: d, echelleTexte: e),
        ),
        _portail(),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-00c/b (contrat)',
    (TextDirection d, double e) => hoteRoutant(
      depart: Routes.attenteContrat,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attenteContrat,
          builder: (BuildContext _, GoRouterState _) =>
              _enveloppe(const ContratPage(), direction: d, echelleTexte: e),
        ),
        _portail(),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(
          FauxServiceDossier()
            ..etatRendu = const EtatDossier(
              profilExiste: true,
              role: AppRole.guardian,
              statutCompte: AccountStatus.pendingKyc,
              accuseSigne: true,
            ),
        ),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-00c/c (depot piece)',
    (TextDirection d, double e) => hoteRoutant(
      depart: Routes.attentePiece,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attentePiece,
          builder: (BuildContext _, GoRouterState _) => _enveloppe(
            const DepotPiecePage(),
            direction: d,
            echelleTexte: e,
          ),
        ),
        _portail(),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
        selecteurFichierProvider.overrideWithValue(FauxSelecteurFichier(null)),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-01',
    (TextDirection d, double e) => hoteRoutant(
      depart: Routes.tuteurAccueil,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.tuteurAccueil,
          builder: (BuildContext _, GoRouterState _) => _enveloppe(
            AccueilFamillePage(horloge: () => _horlogeFixe),
            direction: d,
            echelleTexte: e,
          ),
        ),
        GoRoute(
          path: Routes.tuteurFoyer,
          builder: (BuildContext _, GoRouterState _) => const Text('TUT-02'),
        ),
        GoRoute(
          path: Routes.tuteurAjouterEnfant,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('TUT-02/a'),
        ),
        GoRoute(
          path: Routes.tuteurReglages,
          builder: (BuildContext _, GoRouterState _) => const Text('TUT-05'),
        ),
      ],
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
        servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-02',
    (TextDirection d, double e) => hote(
      _enveloppe(const AppareilsPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-02/a',
    (TextDirection d, double e) => hote(
      _enveloppe(const AjouterEnfantPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-02/b',
    (TextDirection d, double e) => hote(
      _enveloppe(
        const AppairagePage(eleveId: 'e1'),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-04',
    (TextDirection d, double e) => hote(
      _enveloppe(const DisponibilitesPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
        servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-05',
    (TextDirection d, double e) => hote(
      _enveloppe(const ReglagesEnfantPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
        servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
        serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
        serviceAvatarProvider.overrideWithValue(FauxServiceAvatar()),
        selecteurPhotoProvider.overrideWithValue(FauxSelecteurPhoto(null)),
        serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
      ],
    ),
  ),
  _EcranAVerifier(
    'TUT-06',
    // Une liste pleine, jamais l'etat vide : c'est la ligne la plus longue qui
    // deborde -- une date, un prenom, un enseignant et sa pastille d'etat sur
    // 390 points, a 200 pour cent de taille de texte.
    (TextDirection d, double e) => hote(
      _enveloppe(
        SuiviFoyerPage(horloge: () => _horlogeFixe),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        serviceSuiviProvider.overrideWithValue(
          FauxServiceSuivi(
            seancesRendues: <Seance>[
              Seance(
                id: 's1',
                debut: _horlogeFixe.subtract(const Duration(days: 3)),
                fin: _horlogeFixe.subtract(
                  const Duration(days: 3, minutes: -60),
                ),
                statut: StatutSeance.terminee,
                eleveId: 'enf-1',
                elevePrenom: 'Sofia',
                eleveIdentifiant: 'STUD-000001',
                enseignantId: 'ens-1',
                enseignantPrenom: 'Rachid',
                enseignantIdentifiant: 'TEACH-000001',
              ),
            ],
            presencesRendues: <PresenceParticipant>[
              const PresenceParticipant(
                seanceId: 's1',
                profilId: 'enf-1',
                role: 'student',
                prenom: 'Sofia',
                identifiantImmuable: 'STUD-000001',
                etat: EtatPresence.confirmationEnAttente,
                consolide: false,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
  _EcranAVerifier(
    'ENS-06',
    (TextDirection d, double e) => hote(
      _enveloppe(const CreneauxPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_sessionEnseignant),
        ),
        serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
        servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
        serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ELV-02',
    (TextDirection d, double e) => hote(
      _enveloppe(
        AccueilElevePage(horloge: () => _horlogeFixe),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
        servicePriereProvider.overrideWithValue(FauxServicePriere()),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ENS-02',
    (TextDirection d, double e) => hote(
      _enveloppe(const JourneePage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_sessionEnseignant),
        ),
        servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
        serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
        serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
        servicePriereProvider.overrideWithValue(FauxServicePriere()),
        // Depuis le pivot du 19 septembre 2026, la Journee lit le service
        // enseignant et non le planning seul : sans ce faux, l'ecran ne rendrait
        // que son etat d'erreur, et la garantie RTL ne porterait que sur une
        // phrase d'echec.
        serviceEnseignantProvider.overrideWithValue(
          FauxServiceEnseignant()..retardsRendus = <CahierEnRetard>[],
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ENS-01 (bienvenue)',
    (TextDirection d, double e) => hote(
      _enveloppe(
        const BienvenueEnseignantPage(),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_sessionEnseignant),
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ENS-04 (cahier)',
    (TextDirection d, double e) => hote(
      _enveloppe(
        const CahierPage(seanceId: 'seance-1'),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_sessionEnseignant),
        ),
        serviceEnseignantProvider.overrideWithValue(
          FauxServiceEnseignant()
            ..brouillonRendu = BrouillonCahier(
              seanceId: 'seance-1',
              debut: _horlogeFixe,
              fin: _horlogeFixe.add(const Duration(minutes: 45)),
              statut: StatutSeance.terminee,
              dureeMinutes: 45,
              minutesInterruption: 0,
              dejaDepose: false,
              participants: const <ParticipantBrouillon>[],
              evenements: const <EvenementSeance>[],
            ),
        ),
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ENS-07 (fiche groupe)',
    (TextDirection d, double e) => hote(
      _enveloppe(
        const FicheGroupePage(groupeId: 'groupe-1'),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_sessionEnseignant),
        ),
        serviceEnseignantProvider.overrideWithValue(
          FauxServiceEnseignant()
            ..groupesRendus = <GroupeEnseignant>[
              GroupeEnseignant(
                id: 'groupe-1',
                libelle: 'Classe du mardi',
                type: TypePublicGroupe.enfant,
                seuilMax: 5,
                creneau: const Creneau(
                  jour: 2,
                  heure: 17,
                  fuseau: 'Europe/Paris',
                ),
                nbMembres: 2,
                creeLe: _horlogeFixe,
              ),
            ]
            ..membresRendus = const <String, List<MembreSeance>>{
              'groupe-1': <MembreSeance>[
                MembreSeance(
                  studentId: 'e1',
                  identifiantImmuable: 'STUD-KB-000003',
                  prenom: 'Khadija',
                  niveau: 'debutant',
                ),
                MembreSeance(
                  studentId: 'e2',
                  identifiantImmuable: 'STUD-YD-000004',
                  prenom: 'Yacine',
                ),
              ],
            },
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ENS-08 (revue de groupe)',
    (TextDirection d, double e) => hote(
      _enveloppe(
        const RevueGroupePage(groupeId: 'groupe-1'),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(_sessionEnseignant),
        ),
        // `anomaliesGroupeProvider` rend deja une liste vide : aucune RPC
        // d'anomalies bornee a l'enseignant n'existe en base
        // (`CONTRACT_REQUEST_C.md` §1). L'ecran est donc verifie dans son etat
        // vide, qui est son etat reel aujourd'hui.
        serviceEnseignantProvider.overrideWithValue(
          FauxServiceEnseignant()
            ..membresRendus = const <String, List<MembreSeance>>{
              'groupe-1': <MembreSeance>[
                MembreSeance(
                  studentId: 'e1',
                  identifiantImmuable: 'STUD-KB-000003',
                  prenom: 'Khadija',
                ),
              ],
            },
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ADM-01',
    (TextDirection d, double e) => hote(
      _enveloppe(
        TableauDeBordPage(horloge: () => _horlogeFixe),
        direction: d,
        echelleTexte: e,
      ),
      surcharges: <Override>[
        serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
        serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ADM-02',
    (TextDirection d, double e) => hote(
      _enveloppe(const DossiersPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
      ],
    ),
  ),
  _EcranAVerifier(
    'ADM-06',
    (TextDirection d, double e) => hote(
      _enveloppe(const DemandesPage(), direction: d, echelleTexte: e),
      surcharges: <Override>[
        serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
        serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
      ],
    ),
  ),
];

/// Monte un ecran sous une condition, et verifie qu'aucune exception n'est
/// levee -- ni du rendu lui-meme, ni d'un `RenderFlex` en debordement.
///
/// Pas de `pumpAndSettle` : `ELV-02` porte une pulsation en boucle
/// (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-4-journal.md`), et `disableAnimations` ne
/// supprime pas forcement le minuteur qui l'entretient. Deux `pump` bornes
/// suffisent a faire apparaitre un debordement de mise en page.
Future<void> _verifier(
  WidgetTester tester,
  _EcranAVerifier ecran, {
  required TextDirection direction,
  required double echelleTexte,
  required String condition,
}) async {
  tester.view.physicalSize = const Size(390, 8000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ecran.construire(direction, echelleTexte));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  expect(
    tester.takeException(),
    isNull,
    reason: '${ecran.nom} $condition a leve',
  );

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  final List<_EcranAVerifier> ecrans = _ecrans();

  test(
    'vingt-quatre ecrans reels sont couverts, un par identifiant du catalogue',
    () {
      // Garde-fou : un ecran ajoute au catalogue sans entree ici passerait
      // inapercu, comme `catalogue_galerie_test.dart` le fait deja pour les
      // composants. Le compte est passe de vingt a vingt-quatre avec le lot
      // Enseignant (`ENS-01`, `ENS-04`, `ENS-07`, `ENS-08`).
      expect(ecrans.length, 24);
      expect(ecrans.map((_EcranAVerifier e) => e.nom).toSet().length, 24);
    },
  );

  group('Chaque ecran reel se rend en arabe (RTL) sans lever', () {
    for (final _EcranAVerifier ecran in _ecrans()) {
      testWidgets(ecran.nom, (WidgetTester tester) async {
        await _verifier(
          tester,
          ecran,
          direction: TextDirection.rtl,
          echelleTexte: 1,
          condition: 'en RTL',
        );
      });
    }
  });

  group('Chaque ecran reel tient a 200 pour cent de taille de texte', () {
    for (final _EcranAVerifier ecran in _ecrans()) {
      testWidgets(ecran.nom, (WidgetTester tester) async {
        await _verifier(
          tester,
          ecran,
          direction: TextDirection.ltr,
          echelleTexte: 2,
          condition: 'a 200 pour cent',
        );
      });
    }
  });
}
