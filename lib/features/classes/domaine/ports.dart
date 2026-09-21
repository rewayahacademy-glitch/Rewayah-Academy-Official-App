import 'classe_vm.dart';
import 'conformite.dart';

/// Ce que l'administration lit et ecrit sur les Classes.
///
/// **Un port, pas un service Supabase.** Les adaptateurs vivent dans
/// `adaptateurs_existants.dart` et s'appuient sur les services deja presents
/// dans `lib/core/`. Ce qui n'existe pas encore cote serveur leve
/// `EchecDomaine(MotifEchec.capaciteAbsente)` : l'ecran le dit, il ne fait pas
/// semblant.
abstract interface class PortClassesAdmin {
  /// Toutes les Classes, actives d'abord.
  Future<List<ClasseVM>> classes();

  /// Les regles de l'academie qui preremplissent une Classe.
  Future<ReglesClasse> regles();

  /// Les niveaux du programme publie, en langage humain.
  Future<List<ProgrammeChoix>> programmes();

  /// Les enseignants reellement eligibles a un brouillon.
  ///
  /// **Filtree par le serveur**, jamais par un champ d'identifiant.
  Future<List<EnseignantEligible>> enseignantsEligibles(
    BrouillonClasse brouillon,
  );

  /// Publie un ou plusieurs brouillons et rend les identifiants crees.
  ///
  /// Un lot se publie **en une fois** : l'aperçu a deja montre ce qui sera
  /// cree. Une publication partielle se signale par
  /// `EchecPublicationPartielle`.
  Future<List<String>> publier(List<BrouillonClasse> brouillons);

  /// Les eleves inscrits a une Classe.
  Future<List<MembreClasse>> membres(String classeId);
}

/// La marketplace : ce qu'un enseignant, un tuteur ou un eleve voit et fait.
///
/// **Le filtrage par role, par clearance et par compatibilite est serveur.**
/// Le client ne recoit jamais le catalogue entier pour le filtrer.
abstract interface class PortMarketplaceClasses {
  /// Les Classes de l'appelant : assignees pour un enseignant, du foyer pour
  /// un tuteur, la sienne pour un eleve.
  Future<List<ClasseVM>> mesClasses();

  /// Les Classes compatibles, pour l'appelant ou pour un membre du foyer.
  Future<List<ClasseVM>> classesDisponibles({String? membreId});

  /// Un enseignant se porte candidat. L'academie decide.
  Future<void> candidater(String classeId);

  /// Un tuteur inscrit un membre du foyer, un eleve adulte s'inscrit.
  Future<void> inscrire({required String classeId, required String membreId});

  /// Quand aucune Classe ne convient : proposer un creneau que l'academie
  /// agregera.
  Future<void> proposerCreneau({
    required String membreId,
    required CreneauClasse creneau,
  });
}

/// La conformite : ce qui est exige, ou l'on en est, et la dispense.
abstract interface class PortConformite {
  /// La conformite de l'appelant.
  Future<ConformiteCompte> laMienne();

  /// La conformite de tous les comptes, par identifiant de profil.
  /// Administration seulement.
  Future<Map<String, ConformiteCompte>> pourComptes();

  /// Active ou desactive l'exigence KYC d'un compte.
  ///
  /// Explicite, reversible, motivee, journalisee, jamais accessible au
  /// demandeur lui-meme : ces garanties sont **serveur**. Ce port ne fait que
  /// les demander.
  Future<void> definirExigenceKyc({
    required String profilId,
    required bool requise,
    required String motif,
  });
}

/// Ce qu'il faut avant d'entrer en Salle.
abstract interface class PortPreconditionSalle {
  /// La precondition de l'appelant (`membreId` nul) ou d'un membre du foyer.
  Future<PreconditionSalle> pour({String? membreId});
}
