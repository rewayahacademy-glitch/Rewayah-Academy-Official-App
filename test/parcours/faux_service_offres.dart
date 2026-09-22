import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';

/// Les offres, le profil d'apprentissage et l'intention, en memoire.
///
/// Il vit dans son propre fichier et non dans `test/support/harnais.dart` :
/// ce lot est construit en parallele d'un autre agent, et un faux ajoute au
/// harnais commun serait un point de collision pour un gain nul.
class FauxServiceOffres implements ServiceOffres {
  /// Cree le faux.
  FauxServiceOffres({
    this.reglesRendues = const ReglesAcademie(
      capaciteEnfant: 5,
      capaciteAdulte: 6,
      minimumLancement: 3,
      seancesParSemaine: 3,
      dureeMinutesEnfant: 60,
      dureeMinutesAdulte: 90,
      pauseMinutesEnfant: 6,
      pauseMinutesAdulte: 0,
    ),
    this.languesRendues = const <LangueCours>[
      LangueCours(code: 'francais', nom: 'Français'),
      LangueCours(code: 'poular', nom: 'Pulaar'),
    ],
    this.cohortesRendues = const <CohorteAge>[
      CohorteAge(
        code: 'enfant_8_10',
        nom: '8 à 10 ans',
        typePublic: PublicOffre.enfants,
      ),
      CohorteAge(
        code: 'adulte_18_plus',
        nom: '18 ans et plus',
        typePublic: PublicOffre.adultes,
      ),
    ],
    this.parcoursRendu = const <ParcoursApprenant>[],
    this.offresRendues = const <OffreHoraire>[],
  });

  /// Les regles rendues.
  ReglesAcademie reglesRendues;

  /// Les langues rendues.
  List<LangueCours> languesRendues;

  /// Les cohortes rendues.
  List<CohorteAge> cohortesRendues;

  /// L'etat du foyer.
  List<ParcoursApprenant> parcoursRendu;

  /// Les offres compatibles rendues.
  List<OffreHoraire> offresRendues;

  /// Les profils enregistres, dans l'ordre.
  final List<
    ({
      String membreId,
      String langueCode,
      String cohorteCode,
      NiveauDeclare niveau,
      ObjectifApprentissage objectif,
      String fuseau,
    })
  >
  profilsEnregistres =
      <
        ({
          String membreId,
          String langueCode,
          String cohorteCode,
          NiveauDeclare niveau,
          ObjectifApprentissage objectif,
          String fuseau,
        })
      >[];

  /// Les choix d'offre, dans l'ordre.
  final List<({String membreId, String offreId, String fuseau})> choix =
      <({String membreId, String offreId, String fuseau})>[];

  /// Les signaux de demande non satisfaite, dans l'ordre.
  final List<({String membreId, String fuseau})> signaux =
      <({String membreId, String fuseau})>[];

  /// Les renoncements, dans l'ordre.
  final List<({String membreId, String motif})> renoncements =
      <({String membreId, String motif})>[];

  /// Ce que la prochaine ecriture doit jeter.
  Object? erreurAJeter;

  /// Ce que la lecture du parcours doit jeter.
  Object? erreurParcours;

  void _peutEchouer() {
    final Object? erreur = erreurAJeter;
    if (erreur != null) {
      // Volontairement un Object : le vrai client jette aussi bien une
      // PostgrestException qu'une erreur de plateforme, et l'ecran doit se
      // comporter pareil dans les deux cas.
      // ignore: only_throw_errors
      throw erreur;
    }
  }

  @override
  Future<ReglesAcademie> regles() async => reglesRendues;

  @override
  Future<List<LangueCours>> langues() async => languesRendues;

  @override
  Future<List<CohorteAge>> cohortes() async => cohortesRendues;

  @override
  Future<List<ParcoursApprenant>> parcours() async {
    final Object? erreur = erreurParcours;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return parcoursRendu;
  }

  @override
  Future<void> enregistrerProfil({
    required String membreId,
    required String langueCode,
    required String cohorteCode,
    required NiveauDeclare niveau,
    required ObjectifApprentissage objectif,
    required String fuseau,
  }) async {
    _peutEchouer();
    profilsEnregistres.add((
      membreId: membreId,
      langueCode: langueCode,
      cohorteCode: cohorteCode,
      niveau: niveau,
      objectif: objectif,
      fuseau: fuseau,
    ));
  }

  @override
  Future<List<OffreHoraire>> offresCompatibles(CleOffres cle) async =>
      offresRendues;

  @override
  Future<String> choisirOffre(CleOffres cle, String offreId) async {
    _peutEchouer();
    choix.add((membreId: cle.membreId, offreId: offreId, fuseau: cle.fuseau));
    return 'intention-${choix.length}';
  }

  @override
  Future<void> renoncer({
    required String membreId,
    required String motif,
  }) async {
    _peutEchouer();
    renoncements.add((membreId: membreId, motif: motif));
  }

  @override
  Future<void> signalerHoraireInsatisfait({
    required String membreId,
    required String fuseau,
    String? langueCode,
    String? cohorteCode,
  }) async {
    _peutEchouer();
    signaux.add((membreId: membreId, fuseau: fuseau));
  }
}

/// Un apprenant pret a l'emploi dans un test.
ParcoursApprenant apprenantDeTest({
  String eleveId = 'e1',
  String prenom = 'Amina',
  String? cohorte,
  String? langue,
  DateTime? onboardingFaitLe,
  EtatIntention? intention,
  StatutDiagnostic diagnostic = StatutDiagnostic.aPlanifier,
  bool offreIndisponible = false,
  bool fuseauChange = false,
  String? fuseauFoyer,
}) => ParcoursApprenant(
  eleveId: eleveId,
  prenom: prenom,
  diagnostic: diagnostic,
  cohorteCode: cohorte,
  langueCode: langue,
  onboardingFaitLe: onboardingFaitLe,
  intentionEtat: intention,
  offreIndisponible: offreIndisponible,
  fuseauChange: fuseauChange,
  fuseauFoyer: fuseauFoyer,
);

/// Une offre prete a l'emploi dans un test.
OffreHoraire offreDeTest({
  String id = 'o1',
  PublicOffre public = PublicOffre.enfants,
  List<CreneauVu> creneaux = const <CreneauVu>[
    CreneauVu(jourIso: 1, heure: 18),
    CreneauVu(jourIso: 3, heure: 18),
    CreneauVu(jourIso: 5, heure: 18),
  ],
  int heureSource = 18,
  bool dejaChoisie = false,
}) => OffreHoraire(
  id: id,
  public: public,
  langueCode: 'francais',
  langueNom: 'Français',
  creneaux: creneaux,
  heureSource: heureSource,
  fuseauSource: 'Europe/Paris',
  dureeMinutes: 60,
  pauseMinutes: 6,
  capacite: 5,
  dejaChoisie: dejaChoisie,
);
