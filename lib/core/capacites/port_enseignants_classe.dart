import 'package:flutter/foundation.dart';

import '../planning/service_planning.dart' show Creneau;
import 'capacite_indisponible.dart';

/// Le genre d'une classe (CLASSE-FORM-1, demande du directeur).
///
/// **Distinct de `Genre`** (`lib/core/domain/enums.dart`), dont le seul usage
/// ecrit est le cloisonnement des dossiers d'identite : ce genre-ci decrit le
/// public d'une classe, et il a une troisieme valeur.
enum GenreClasse {
  /// Une classe d'hommes (de garcons chez les enfants).
  hommes,

  /// Une classe de femmes (de filles chez les enfants).
  femmes,

  /// Genre de classe pas encore connu : tout enseignant compatible est proposé.
  indetermine,
}

/// Le genre public dérivé côté serveur de `profiles.gender` via le titre
/// sayid/sayyida; le genre brut ne part jamais vers le client.
enum GenreEnseignant {
  /// Un enseignant.
  homme,

  /// Une enseignante.
  femme,
}

/// Un enseignant proposable pour une classe a creer, avec ce qui fonde son
/// classement (genre, creneaux libres, charge).
///
/// **Forme provisoire** : aucune RPC ne rend encore ces champs ensemble
/// (`enseignants_pour_classe`, ligne Contrats de CLASSE-FORM-1). Ce que la
/// source ne dit pas reste nul, et l'ecran n'en tire aucune mention.
@immutable
class EnseignantPropose {
  /// Cree un enseignant propose.
  const EnseignantPropose({
    required this.id,
    required this.libelle,
    required this.identifiant,
    required this.classesActives,
    this.genre,
    this.creneauxLibres,
    this.creneauxPris = const <Creneau>[],
    this.fuseauIana,
  });

  /// L'identifiant technique du profil, celui que la RPC attend.
  final String id;

  /// Le nom affiche (repli sur l'identifiant quand l'identite est masquee).
  final String libelle;

  /// L'identifiant immuable, qui departage deux homonymes.
  final String identifiant;

  /// Le genre dérivé du titre public. Nul si le titre est absent ou inconnu.
  final GenreEnseignant? genre;

  /// Ses creneaux libres : disponibilites, moins ses affectations et les
  /// creneaux de ses classes actives. **Nul : non rendus par la source**
  /// (vide veut dire « aucun creneau libre »).
  final List<Creneau>? creneauxLibres;

  /// Les creneaux de ses classes actives : une nouvelle classe au meme
  /// creneau serait une collision.
  final List<Creneau> creneauxPris;

  /// Le nombre de ses classes actives.
  final int classesActives;

  /// Son fuseau IANA, dans lequel [creneauxLibres] se lisent. Nul : non dit.
  final String? fuseauIana;
}

/// Les enseignants proposables pour une classe (CLASSE-FORM-1).
abstract interface class PortEnseignantsClasse {
  /// Les enseignants actifs, avec ce que la source sait de chacun. Le
  /// classement se fait a cote (`classerEnseignants`), en fonction pure.
  Future<List<EnseignantPropose>> pourClasse({
    required String classeId,
  });
}

/// Implémentation de secours pour les environnements sans backend. Ne jamais
/// remplacer ce résultat par une liste non filtrée de comptes.
class EnseignantsClasseIndisponible implements PortEnseignantsClasse {
  /// Cree l'implementation.
  const EnseignantsClasseIndisponible();

  @override
  Future<List<EnseignantPropose>> pourClasse({
    required String classeId,
  }) => Future<List<EnseignantPropose>>.error(
    const CapaciteIndisponible('DB-CLASSE-FORM-1'),
  );
}
