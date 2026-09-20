import 'package:flutter/foundation.dart';

/// L'echec d'une lecture du corpus.
///
/// **Distinct de l'absence.** Un port rend `null` quand la donnee n'existe
/// pas, et leve quand il n'a pas pu savoir : confondre les deux ferait
/// afficher « ce verset n'existe pas » a chaque coupure reseau.
@immutable
class EchecCorpusCoran implements Exception {
  /// Cree un echec.
  const EchecCorpusCoran(this.motif);

  /// Ce qui a echoue, en clair, pour le journal de developpement.
  final String motif;

  @override
  String toString() => 'EchecCorpusCoran: $motif';
}

/// Une sourate, telle que le moteur de rendu la consomme.
@immutable
class SourateVM {
  /// Cree une sourate.
  const SourateVM({
    required this.numero,
    required this.nomArabe,
    required this.nomTranslittere,
    required this.mecquoise,
    required this.nombreVersets,
  });

  /// Son rang, de 1 a 114.
  final int numero;

  /// Son nom en arabe.
  final String nomArabe;

  /// Son nom translittere.
  final String nomTranslittere;

  /// Vrai pour une sourate revelee a La Mecque.
  final bool mecquoise;

  /// Le nombre de versets qu'elle compte.
  final int nombreVersets;
}

/// Un verset, tel que le corpus le livre.
///
/// [ligne] existe dans le schema (`verset.ligne`, migration `0007`) et **vaut
/// `null` sur les 6236 versets** : la migration `0013` ne la remplit pas, et
/// le dit. Le champ est porte ici pour que le jour ou elle sera peuplee, rien
/// n'ait a changer au-dessus ; il n'est jamais devine.
@immutable
class VersetCorpus {
  /// Cree un verset.
  const VersetCorpus({
    required this.sourate,
    required this.numero,
    required this.texte,
    required this.pageNumero,
    this.ligne,
  });

  /// La sourate a laquelle il appartient.
  final int sourate;

  /// Son rang dans la sourate.
  final int numero;

  /// Le texte, tel quel. Il ne se modifie jamais.
  final String texte;

  /// La page du mushaf ou il **commence**.
  ///
  /// Un verset a cheval sur deux pages est entierement attribue a la premiere :
  /// le corpus n'a aucune granularite sub-verset.
  final int pageNumero;

  /// La ligne de la page, quand elle est connue. `null` aujourd'hui, partout.
  final int? ligne;

  /// La reference courte, « 2:255 ».
  String get reference => '$sourate:$numero';
}

/// Une page du mushaf, telle que le corpus la livre.
@immutable
class PageCorpus {
  /// Cree une page.
  const PageCorpus({
    required this.numero,
    required this.versets,
    this.juzNumero,
  });

  /// Le numero de page, de 1 a 604.
  final int numero;

  /// Les versets de la page, dans l'ordre du texte.
  final List<VersetCorpus> versets;

  /// Le juz auquel la page appartient, quand il est connu.
  final int? juzNumero;

  /// Vrai quand la page n'a aucun verset : corpus non importe.
  bool get vide => versets.isEmpty;
}

/// Ce qu'une recherche rapide a trouve.
@immutable
class ResultatRechercheCoran {
  /// Cree un resultat.
  const ResultatRechercheCoran({
    required this.type,
    required this.page,
    required this.libelle,
    this.sourate,
    this.ayah,
    this.juz,
  });

  /// Ce qui a permis de trouver.
  final TypeResultatRecherche type;

  /// La page a ouvrir.
  final int page;

  /// Ce que la liste affiche.
  final String libelle;

  /// La sourate visee, quand le resultat en designe une.
  final int? sourate;

  /// Le verset vise, quand le resultat en designe un.
  final int? ayah;

  /// Le juz vise, quand le resultat en designe un.
  final int? juz;
}

/// Par quoi un resultat de recherche a ete trouve.
///
/// **La recherche plein texte n'existe pas.** Aucun index texte n'a ete pose
/// sur `verset` (ni `tsvector`, ni `pg_trgm`, ni colonne sans diacritiques), et
/// `ServiceCoran` est PROTECTED : l'ajouter est une demande, pas une
/// initiative. La valeur [texte] est donc declaree mais **jamais produite**
/// aujourd'hui, et l'ecran le dit a l'usager au lieu de rendre une liste vide
/// qui ressemblerait a « aucun resultat ».
enum TypeResultatRecherche {
  /// Une reference « sourate:verset », « 2:255 ».
  reference,

  /// Un nom ou un numero de sourate.
  sourate,

  /// Un numero de juz.
  juz,

  /// Un numero de page.
  page,

  /// Une occurrence dans le texte. Indisponible : voir la doc de l'enum.
  texte,
}

/// L'acces en LECTURE SEULE au corpus coranique.
///
/// Adaptateur au-dessus de `lib/core/coran/service_coran.dart`, qui est
/// **PROTECTED** : le moteur de rendu ne le connait pas, ne l'etend pas et ne
/// le duplique pas. Il n'existe **aucune** methode d'ecriture ici : le texte
/// canonique est immuable, et la position personnelle de lecture appartient a
/// `PortNavigationCoran`, pas au corpus.
///
/// Signature fixee par `TEACHING_CORE_CONTRACTS.md` section 17.
abstract class PortCorpusCoran {
  /// Les 114 sourates. Leve [EchecCorpusCoran] si la lecture echoue.
  Future<List<SourateVM>> sourates();

  /// Une page du mushaf, de 1 a 604. `null` si elle n'existe pas.
  Future<PageCorpus?> page(int numeroPage);

  /// La page ou commence un verset donne. `null` si le verset n'existe pas.
  Future<PageCorpus?> pageDeAyah({required int sourate, required int ayah});

  /// La page ou commence une sourate. `null` si la sourate n'existe pas.
  Future<int?> pageDeDebutDeSourate(int sourate);

  /// La page ou commence un juz. `null` si le juz n'existe pas.
  Future<int?> pageDeDebutDeJuz(int juz);

  /// Une recherche rapide. Voir [TypeResultatRecherche] pour ses limites.
  Future<List<ResultatRechercheCoran>> rechercher(String requete);
}
