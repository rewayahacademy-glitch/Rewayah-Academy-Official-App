/// IMM-ACCUEIL-FRONT : le port de l'ecran « Importer les inscriptions ».
///
/// Decision du directeur du 12/10/2026 (`DECISION-IMMATRICULATION-2026-10-12.md`,
/// section 5) : la direction depose les deux CSV du classeur des formulaires
/// Google, voit un **essai a blanc** (rien n'est ecrit), puis confirme. Le
/// serveur lit la disposition des formulaires, regroupe par adresse e-mail,
/// ignore les lignes d'essai et ne cree jamais deux fois la meme personne.
///
/// Trois appels, tous reserves a la direction : la capacite
/// (`capacites_import_inscriptions`, direction active en double verification),
/// l'essai a blanc (`previsualiser_import_inscriptions`) et la confirmation
/// (`confirmer_import_inscriptions`, idempotente par personne). Aucune valeur
/// de reference ici : les bornes d'age sont celles du serveur.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'analyse_inscriptions.dart';

/// La dependance serveur de l'ecran (ligne Backend IMM-ACCUEIL).
const String dependanceImportInscriptions = 'IMM-ACCUEIL';

/// Ce que la personne connectee peut faire ici, dit par le serveur.
@immutable
class CapacitesImport {
  /// Cree les capacites.
  const CapacitesImport({
    required this.peutImporter,
    this.doubleVerificationRequise = false,
    this.bornes = BornesAge.aucune,
  });

  /// Aucune capacite.
  static const CapacitesImport aucune = CapacitesImport(peutImporter: false);

  /// Elle peut deposer et confirmer un import.
  final bool peutImporter;

  /// Elle est de la direction mais sans double verification : le serveur le dit
  /// pour que l'ecran explique quoi faire.
  final bool doubleVerificationRequise;

  /// Les bornes d'age des tranches du serveur.
  final BornesAge bornes;
}

/// Une ligne que le serveur a refusee a l'essai a blanc.
@immutable
class MotifRejetServeur {
  /// Cree le motif.
  const MotifRejetServeur({
    required this.source,
    required this.ligne,
    required this.motif,
  });

  /// Le fichier.
  final SourceImport source;

  /// Le numero de ligne (l'en-tete est la ligne 1).
  final int ligne;

  /// Le motif du serveur (`invalid_email`...), tel quel.
  final String motif;

  /// Le probleme correspondant, ou `null` si le motif est inconnu.
  CodeProbleme? get code => motifsServeur[motif];
}

/// Le compte rendu de l'essai a blanc du serveur.
@immutable
class ApercuServeur {
  /// Cree le compte rendu.
  const ApercuServeur({
    required this.foyers,
    required this.personnes,
    required this.doublons,
    required this.lignesRejetees,
    required this.motifs,
  });

  /// Les foyers qui seraient crees.
  final int foyers;

  /// Les personnes qui seraient importees.
  final int personnes;

  /// Les lignes dont l'adresse revient.
  final int doublons;

  /// Les lignes refusees.
  final int lignesRejetees;

  /// Le motif de chaque ligne refusee.
  final List<MotifRejetServeur> motifs;
}

/// Un reglage de foyer a la confirmation : le mot et la case « a patiente ».
@immutable
class OptionFoyer {
  /// Cree l'option.
  const OptionFoyer({
    required this.email,
    this.aPatiente = false,
    this.motAccueil,
    this.motPatience,
  });

  /// L'adresse du foyer (en minuscules).
  final String email;

  /// La famille a attendu l'application : elle recoit le mot de patience.
  final bool aPatiente;

  /// Le mot d'accueil retouche, ou `null` pour celui du serveur (rempli avec
  /// les prenoms connus).
  final String? motAccueil;

  /// Le mot de patience retouche, ou `null` pour celui du serveur.
  final String? motPatience;

  /// Vrai quand l'option ne change rien a ce que le serveur ferait seul.
  bool get neutre =>
      !aPatiente &&
      (motAccueil == null || motAccueil!.trim().isEmpty) &&
      (motPatience == null || motPatience!.trim().isEmpty);
}

/// Ce que la confirmation a ecrit.
@immutable
class ResultatImport {
  /// Cree le resultat.
  const ResultatImport({
    required this.foyersTraites,
    required this.foyersCrees,
    required this.personnesCreees,
    required this.personnesDejaImportees,
  });

  /// Les foyers vus.
  final int foyersTraites;

  /// Les foyers nouveaux.
  final int foyersCrees;

  /// Les personnes nouvelles.
  final int personnesCreees;

  /// Les personnes deja presentes (import rejoue : rien de plus n'est cree).
  final int personnesDejaImportees;
}

/// Pourquoi un import n'a pas abouti.
sealed class ErreurImport implements Exception {
  const ErreurImport();
}

/// La connexion a coupe : rien n'est confirme, la meme demande se rejoue sans
/// doublon.
final class ImportHorsLigne extends ErreurImport {
  /// Cree l'erreur.
  const ImportHorsLigne();
}

/// Le serveur refuse l'appelant (direction active en double verification).
final class ImportRefuse extends ErreurImport {
  /// Cree l'erreur.
  const ImportRefuse();
}

/// Le serveur refuse le contenu (fichier mal forme, option pour un foyer
/// absent). [message] est celui du serveur : il ne s'affiche pas tel quel.
final class ImportInvalide extends ErreurImport {
  /// Cree l'erreur.
  const ImportInvalide(this.message);

  /// Le message du serveur.
  final String message;
}

/// Le port.
abstract interface class PortImportInscriptions {
  /// Ce que la personne connectee peut faire ici.
  Future<CapacitesImport> capacites();

  /// L'essai a blanc : rien n'est ecrit.
  Future<ApercuServeur> apercu({
    required String elevesCsv,
    required String enseignantsCsv,
  });

  /// La confirmation. Rejouable : une personne deja importee n'est pas
  /// recreee.
  Future<ResultatImport> confirmer({
    required String elevesCsv,
    required String enseignantsCsv,
    required List<OptionFoyer> options,
  });
}

/// Le port : absent avant le branchement serveur.
final Provider<PortImportInscriptions?> portImportInscriptionsProvider =
    Provider<PortImportInscriptions?>((Ref _) => null);

/// Les capacites. Sans port : [CapaciteIndisponible].
final FutureProvider<CapacitesImport> capacitesImportProvider =
    FutureProvider<CapacitesImport>((Ref ref) {
      final PortImportInscriptions? port = ref.watch(
        portImportInscriptionsProvider,
      );
      if (port == null) {
        return Future<CapacitesImport>.error(
          const CapaciteIndisponible(dependanceImportInscriptions),
        );
      }
      return port.capacites();
    }, retry: (int _, Object _) => null);

/// La date du jour, pour l'age ; surchargeable dans un test.
final Provider<DateTime Function()> horlogeImportProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);
