import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../seance_famille/seance_famille.dart' show EnseignantSeance;
import 'capacite_indisponible.dart';

/// L'etat d'une classe ouverte, tel que le serveur le rendra.
enum EtatClasseOuverte {
  /// Des places restent.
  ouverte,

  /// Plus aucune place.
  complete,

  /// Complete, avec liste d'attente.
  listeAttente,
}

/// Une vraie classe proposee a un eleve (point P1 : enseignant, places
/// reelles), jamais une offre vitrine sans enseignant.
///
/// **Forme provisoire** : aucune source serveur ne la rend encore
/// (DB-CRS-07 ; aucune vue de classes ouvertes dans `supabase/migrations`).
/// Les seances hebdomadaires, le fuseau et le parcours sont **portes par le
/// contrat** (demande C-14, decision du directeur) mais restent vides tant
/// que la source ne les rend pas : l'ecran le dit, rien n'est devine.
@immutable
class ClasseOuverte {
  /// Cree une classe ouverte.
  const ClasseOuverte({
    required this.classeId,
    required this.libelle,
    required this.enseignant,
    required this.etat,
    this.placesRestantes,
    this.seances = const <CreneauHebdomadaire>[],
    this.fuseauIana,
    this.cours,
    this.niveau,
  });

  /// Identifiant de la classe.
  final String classeId;

  /// Nom de la classe, jamais un code technique.
  final String libelle;

  /// L'enseignant attitre.
  final EnseignantSeance enseignant;

  /// Places restantes **rendues par le serveur**. `null` : non dites.
  final int? placesRestantes;

  /// Ouverte, complete ou en liste d'attente.
  final EtatClasseOuverte etat;

  /// Les seances hebdomadaires, heures exprimees dans [fuseauIana]. Vide :
  /// non rendues par le serveur (jamais devinees).
  final List<CreneauHebdomadaire> seances;

  /// Le fuseau IANA dans lequel [seances] sont exprimees. `null` : non dit.
  final String? fuseauIana;

  /// Le cours suivi par la classe (parcours), en langage humain.
  final String? cours;

  /// Le niveau de la classe dans ce cours.
  final String? niveau;
}

/// Une seance hebdomadaire d'une classe ouverte : jour, heure de debut et
/// duree, lus dans le fuseau de la classe.
@immutable
class CreneauHebdomadaire {
  /// Cree un creneau.
  const CreneauHebdomadaire({
    required this.jourIso,
    required this.heure,
    required this.minute,
    required this.dureeMinutes,
  }) : assert(jourIso >= 1 && jourIso <= 7, 'jour ISO : 1 lundi a 7 dimanche');

  /// Le jour, norme ISO : 1 lundi, 7 dimanche.
  final int jourIso;

  /// L'heure de debut (0 a 23).
  final int heure;

  /// La minute de debut (0 a 59).
  final int minute;

  /// La duree de la seance, en minutes.
  final int dureeMinutes;
}

/// Ce qu'une demande d'inscription a produit (DB-CRS-08).
enum StatutInscription {
  /// Inscrit.
  inscrit,

  /// Demande recue, validation a venir.
  enAttenteValidation,

  /// Place en liste d'attente.
  listeAttente,

  /// Refuse (derniere place perdue, incompatibilite...).
  refuse,
}

/// Le resultat d'une inscription, rendu par le serveur.
@immutable
class ResultatInscription {
  /// Cree le resultat.
  const ResultatInscription(this.statut);

  /// Le statut.
  final StatutInscription statut;
}

/// Le catalogue des classes ouvertes (contrat K6).
abstract interface class PortCatalogueClasses {
  /// Les classes compatibles avec un eleve, heures lues dans [fuseauIana].
  Future<List<ClasseOuverte>> compatibles({
    required String eleveId,
    required String fuseauIana,
  });

  /// Inscrit un eleve, de facon atomique et idempotente cote serveur.
  Future<ResultatInscription> inscrire({
    required String classeId,
    required String eleveId,
    required String cleIdempotence,
  });
}

/// Le catalogue tant qu'aucune source n'existe : **aucune reservation
/// locale**, l'ecran dit que le choix de classe en ligne n'est pas encore
/// ouvert (point P1). Aucun adaptateur n'est prevu avant DB-CRS-07 et 08.
class CatalogueClassesIndisponible implements PortCatalogueClasses {
  /// Cree l'implementation.
  const CatalogueClassesIndisponible();

  @override
  Future<List<ClasseOuverte>> compatibles({
    required String eleveId,
    required String fuseauIana,
  }) => Future<List<ClasseOuverte>>.error(
    const CapaciteIndisponible('DB-CRS-07'),
  );

  @override
  Future<ResultatInscription> inscrire({
    required String classeId,
    required String eleveId,
    required String cleIdempotence,
  }) => Future<ResultatInscription>.error(
    const CapaciteIndisponible('DB-CRS-08'),
  );
}

/// Le catalogue employe par l'application.
final Provider<PortCatalogueClasses> portCatalogueClassesProvider =
    Provider<PortCatalogueClasses>(
      (Ref ref) => const CatalogueClassesIndisponible(),
    );
