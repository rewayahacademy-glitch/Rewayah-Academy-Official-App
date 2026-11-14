// Les doubles du lot PLAN-DE-CLASSE A : un service de gestes en memoire et un
// programme publie. Ils redisent ce que dit le serveur (prouve en SQL par
// supabase/tests/scenarios_plan_de_classe_a.sql) ; les tests d'ecran verifient
// le geste envoye et la phrase montree, jamais une regle recopiee.
import 'package:rewayah_academy/core/admin/service_diagnostics.dart';
import 'package:rewayah_academy/core/admin/service_plan_classe.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';

class FauxPlanClasse implements ServicePlanClasse {
  FauxPlanClasse({
    this.etape = const EtapeClasse(
      niveauId: null,
      etapeNom: null,
      programmePublie: true,
      membres: 3,
      membresSansEtape: 2,
    ),
    this.placements = const PlacementsAFaire(
      programmePublie: true,
      classes: <ClasseSansEtape>[
        ClasseSansEtape(
          groupeId: 'demo-classe-1',
          nom: 'Classe An-Nour',
          membres: 3,
        ),
      ],
      eleves: <EleveSansEtape>[
        EleveSansEtape(
          studentId: 'e1',
          identifiant: 'ELV-1',
          prenom: 'Nour',
          nom: 'Exemple',
          classe: 'Classe An-Nour',
          raison: RaisonSansEtape.debutantARattacher,
          inscritLe: null,
        ),
        EleveSansEtape(
          studentId: 'e3',
          identifiant: 'ELV-3',
          prenom: 'Adam',
          nom: 'Fictif',
          classe: 'Classe Al-Furqan',
          raison: RaisonSansEtape.attenteEntretien,
          inscritLe: null,
        ),
      ],
    ),
    this.etat = const EtatPublication(raison: RaisonBrouillon.publiable),
    this.apercu,
  });

  /// Le jour de reference rendu par le « serveur » : fixe, pour que les tests
  /// ne dependent ni de l'horloge ni du jour de l'appareil.
  static final DateTime jour = DateTime(2026, 11, 13);

  /// L'apercu rendu (par defaut : une date limite dix semaines apres le jour
  /// choisi, pas encore passee).
  ApercuDateLimite? apercu;
  final List<CleApercu> apercusDemandes = <CleApercu>[];

  EtapeClasse etape;
  PlacementsAFaire placements;
  EtatPublication etat;
  Exception? echec;

  final List<(String, String, String)> niveauxDonnes =
      <(String, String, String)>[];
  final List<(String, DateTime, String)> datations =
      <(String, DateTime, String)>[];
  int rattachements = 0;
  int repartirs = 0;

  void _echouer() {
    if (echec case final Exception e) throw e;
  }

  @override
  Future<EtapeClasse?> etapeClasse(String groupeId) async => etape;

  @override
  Future<ResultatNiveauClasse> donnerNiveauClasse({
    required String groupeId,
    required String niveauId,
    required String motif,
  }) async {
    _echouer();
    niveauxDonnes.add((groupeId, niveauId, motif));
    etape = EtapeClasse(
      niveauId: niveauId,
      etapeNom: 'Lettres',
      programmePublie: true,
      membres: etape.membres,
      membresSansEtape: 0,
    );
    return const ResultatNiveauClasse(elevesPlaces: 2, elevesEnAttente: 0);
  }

  @override
  Future<void> daterEntreeEtape({
    required String studentId,
    required DateTime jour,
    required String motif,
  }) async {
    _echouer();
    datations.add((studentId, jour, motif));
  }

  @override
  Future<PlacementsAFaire> placementsAFaire() async => placements;

  @override
  Future<ResultatRattachement> rattacher() async {
    _echouer();
    rattachements++;
    placements = PlacementsAFaire(
      programmePublie: true,
      classes: const <ClasseSansEtape>[],
      eleves: placements.eleves
          .where(
            (EleveSansEtape e) =>
                e.raison != RaisonSansEtape.debutantARattacher,
          )
          .toList(),
    );
    return const ResultatRattachement(classes: 1, eleves: 1);
  }

  @override
  Future<EtatPublication> etatPublication(String versionId) async => etat;

  @override
  Future<ApercuDateLimite> apercuDateLimite({
    required String studentId,
    required DateTime jour,
    String? niveauId,
  }) async {
    apercusDemandes.add((studentId: studentId, jour: jour, niveauId: niveauId));
    return apercu ??
        ApercuDateLimite(
          dateLimite: jour.add(const Duration(days: 70)),
          dejaPassee: false,
        );
  }

  @override
  Future<DateTime> jourAcademie() async => jour;

  @override
  Future<String> repartirDesBases() async {
    _echouer();
    repartirs++;
    return 'v-neuve';
  }
}

class FauxProgrammePublie implements ServiceProgramme {
  FauxProgrammePublie({this.versionsListe});

  List<VersionProgramme>? versionsListe;
  final List<String?> creations = <String?>[];

  static VersionProgramme version(
    String id,
    StatutVersionProgramme statut,
    int numero, {
    int niveaux = 4,
  }) => VersionProgramme(
    id: id,
    statut: statut,
    numeroVersion: numero,
    creeParIdentifiant: 'x',
    creeParPrenom: null,
    creeParNom: null,
    publieeAt: statut == StatutVersionProgramme.publiee
        ? DateTime.utc(2026, 11, 13)
        : null,
    nombreNiveaux: niveaux,
    createdAt: DateTime.utc(2026, 11, 1),
  );

  static NiveauProgramme etapeNommee(String id, String nom, int ordre) =>
      NiveauProgramme(
        id: id,
        codeTechnique: 'BASES-$ordre',
        nomHumain: nom,
        cycle: 'Les bases',
        ordre: ordre,
        description: null,
      );

  @override
  Future<List<VersionProgramme>> versions() async =>
      versionsListe ??
      <VersionProgramme>[version('v1', StatutVersionProgramme.publiee, 1)];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      <NiveauProgramme>[
        etapeNommee('n1', 'Lettres', 1),
        etapeNommee('n2', 'Mots', 2),
        etapeNommee('n3', 'Sourates', 3),
        etapeNommee('n4', 'Lecture', 4),
      ];

  @override
  Future<String> creerVersion({String? versionSourceId}) async {
    creations.add(versionSourceId);
    return 'v-vide';
  }

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async => 'n';

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {}

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) async {}

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) async {}
}

class FauxDiagnostics implements ServiceDiagnostics {
  final List<(String, String, String, DateTime?)> decisions =
      <(String, String, String, DateTime?)>[];
  Exception? echec;

  @override
  Future<List<EleveADiagnostiquer>> aTraiter() async => <EleveADiagnostiquer>[
    EleveADiagnostiquer(
      studentId: 'e9',
      identifiant: 'ELV-9',
      prenom: 'Yasmine',
      nom: 'Exemple',
      inscritDepuis: DateTime.now().subtract(const Duration(days: 40)),
    ),
  ];

  @override
  Future<void> deciderPlacement({
    required String studentId,
    required String niveauId,
    required String motif,
    DateTime? depuis,
  }) async {
    if (echec case final Exception e) throw e;
    decisions.add((studentId, niveauId, motif, depuis));
  }
}
