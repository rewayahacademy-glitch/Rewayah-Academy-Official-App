import 'dart:async';

import 'package:rewayah_academy/features/classes/domaine/classe_vm.dart';
import 'package:rewayah_academy/features/classes/domaine/conformite.dart';
import 'package:rewayah_academy/features/classes/domaine/ports.dart';

/// Une Classe prete a l'emploi dans un test.
///
/// Le modele porte seize champs ; un test qui les ecrirait tous noierait ce
/// qu'il mesure. La capacite et l'effectif sont des parametres : ce sont eux
/// que les cartes affichent, jamais une constante.
ClasseVM classeDeTest({
  String id = 'classe-uuid-0001',
  String libelle = 'Perles du Coran',
  String? programme = 'Fondations de lecture',
  String? niveauHumain = 'Cycle 1',
  PublicClasse publicClasse = PublicClasse.enfants,
  int jourIso = 1,
  int heure = 17,
  String fuseau = 'Europe/Paris',
  Duration? duree = const Duration(minutes: 45),
  int capacite = 5,
  int inscrits = 4,
  int? seuilMinimal,
  EtatPublication etat = EtatPublication.publiee,
  EnseignantClasse? enseignant = const EnseignantClasse(
    id: 'ens-uuid-0001',
    nomAffichage: 'Amina',
  ),
  bool inscrit = false,
  EtatCandidature candidature = EtatCandidature.aucune,
  SeanceAVenir? prochaineSeance,
}) => ClasseVM(
  id: id,
  libelle: libelle,
  programme: programme,
  niveauHumain: niveauHumain,
  publicClasse: publicClasse,
  creneau: CreneauClasse(jourIso: jourIso, heure: heure, fuseauIana: fuseau),
  duree: duree,
  capacite: capacite,
  inscrits: inscrits,
  seuilMinimal: seuilMinimal,
  etat: etat,
  enseignant: enseignant,
  inscrit: inscrit,
  candidature: candidature,
  prochaineSeance: prochaineSeance,
);

/// Le port d'administration, en memoire.
///
/// Il **enregistre ce qu'on lui demande de publier** : c'est par la qu'un test
/// verifie qu'un lot de trois cases donne trois brouillons, et qu'aucun
/// identifiant saisi ne transite.
class FauxPortClassesAdmin implements PortClassesAdmin {
  /// Cree le faux.
  FauxPortClassesAdmin({
    this.classesRendues = const <ClasseVM>[],
    this.reglesRendues = const ReglesClasse(
      fuseauIana: 'Europe/Paris',
      dureeMinutes: 60,
    ),
    this.programmesRendus = const <ProgrammeChoix>[],
    this.eligiblesRendus = const <EnseignantEligible>[],
    this.membresRendus = const <String, List<MembreClasse>>{},
  });

  /// Ce que [classes] rend.
  List<ClasseVM> classesRendues;

  /// Ce que [regles] rend.
  ReglesClasse reglesRendues;

  /// Ce que [programmes] rend.
  List<ProgrammeChoix> programmesRendus;

  /// Ce que [enseignantsEligibles] rend.
  List<EnseignantEligible> eligiblesRendus;

  /// Ce que [membres] rend, par Classe.
  Map<String, List<MembreClasse>> membresRendus;

  /// Les lots publies, dans l'ordre.
  final List<List<BrouillonClasse>> publications = <List<BrouillonClasse>>[];

  /// Ce que la prochaine publication doit jeter.
  Object? erreurPublication;

  /// Ce que la lecture des Classes doit jeter.
  Object? erreurLecture;

  @override
  Future<List<ClasseVM>> classes() async {
    final Object? erreur = erreurLecture;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return classesRendues;
  }

  @override
  Future<ReglesClasse> regles() async => reglesRendues;

  @override
  Future<List<ProgrammeChoix>> programmes() async => programmesRendus;

  @override
  Future<List<EnseignantEligible>> enseignantsEligibles(
    BrouillonClasse brouillon,
  ) async => eligiblesRendus;

  @override
  Future<List<String>> publier(List<BrouillonClasse> brouillons) async {
    final Object? erreur = erreurPublication;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    publications.add(List<BrouillonClasse>.unmodifiable(brouillons));
    return <String>[
      for (int i = 0; i < brouillons.length; i++) 'publiee-$i',
    ];
  }

  @override
  Future<List<MembreClasse>> membres(String classeId) async =>
      membresRendus[classeId] ?? const <MembreClasse>[];
}

/// La marketplace, en memoire.
class FauxPortMarketplace implements PortMarketplaceClasses {
  /// Cree le faux.
  FauxPortMarketplace({
    this.miennes = const <ClasseVM>[],
    this.disponiblesParMembre = const <String?, List<ClasseVM>>{},
  });

  /// Ce que [mesClasses] rend.
  List<ClasseVM> miennes;

  /// Ce que [classesDisponibles] rend, par membre (`null` pour l'appelant).
  Map<String?, List<ClasseVM>> disponiblesParMembre;

  /// Ce que la lecture des Classes disponibles doit jeter.
  Object? erreurDisponibles;

  /// Ce que la prochaine action doit jeter.
  Object? erreurAction;

  /// Les candidatures envoyees.
  final List<String> candidatures = <String>[];

  /// Les inscriptions faites.
  final List<({String classeId, String membreId})> inscriptions =
      <({String classeId, String membreId})>[];

  /// Les creneaux proposes.
  final List<({String membreId, CreneauClasse creneau})> propositions =
      <({String membreId, CreneauClasse creneau})>[];

  void _peutEchouer() {
    final Object? erreur = erreurAction;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
  }

  @override
  Future<List<ClasseVM>> mesClasses() async => miennes;

  @override
  Future<List<ClasseVM>> classesDisponibles({String? membreId}) async {
    final Object? erreur = erreurDisponibles;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return disponiblesParMembre[membreId] ?? const <ClasseVM>[];
  }

  @override
  Future<void> candidater(String classeId) async {
    _peutEchouer();
    candidatures.add(classeId);
  }

  @override
  Future<void> inscrire({
    required String classeId,
    required String membreId,
  }) async {
    _peutEchouer();
    inscriptions.add((classeId: classeId, membreId: membreId));
  }

  @override
  Future<void> proposerCreneau({
    required String membreId,
    required CreneauClasse creneau,
  }) async {
    _peutEchouer();
    propositions.add((membreId: membreId, creneau: creneau));
  }
}

/// La conformite, en memoire.
class FauxPortConformite implements PortConformite {
  /// Cree le faux.
  FauxPortConformite({
    this.mienne = const ConformiteCompte(
      exigence: ExigenceKyc.requise,
      etat: EtatKyc.verifie,
      contratAccepte: true,
    ),
    this.parCompte = const <String, ConformiteCompte>{},
  });

  /// Ce que [laMienne] rend.
  ConformiteCompte mienne;

  /// Ce que [pourComptes] rend.
  Map<String, ConformiteCompte> parCompte;

  /// Ce que la prochaine ecriture doit jeter.
  Object? erreurEcriture;

  /// Les ecritures, dans l'ordre.
  final List<({String profilId, bool requise, String motif})> ecritures =
      <({String profilId, bool requise, String motif})>[];

  @override
  Future<ConformiteCompte> laMienne() async => mienne;

  @override
  Future<Map<String, ConformiteCompte>> pourComptes() async => parCompte;

  @override
  Future<void> definirExigenceKyc({
    required String profilId,
    required bool requise,
    required String motif,
  }) async {
    final Object? erreur = erreurEcriture;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    ecritures.add((profilId: profilId, requise: requise, motif: motif));
  }
}

/// La precondition d'entree en Salle, en memoire.
class FauxPortPrecondition implements PortPreconditionSalle {
  /// Cree le faux.
  FauxPortPrecondition([this.rendue = const PreconditionSalle.inconnue()]);

  /// Ce que [pour] rend.
  PreconditionSalle rendue;

  @override
  Future<PreconditionSalle> pour({String? membreId}) async => rendue;
}
