import 'package:flutter/foundation.dart';

import '../tc_telechargement/port_etat_offline.dart';
import 'content_position.dart';
import 'library_resource.dart';

/// Un filtre simple du catalogue (spec section 6.1).
///
/// Chaque champ nul **relache** son axe. Un filtre entierement nul equivaut a
/// l'absence de filtre : c'est ce qui permet a l'appelant de composer sans
/// tester chaque cas.
@immutable
class FiltreCatalogue {
  /// Cree un filtre.
  const FiltreCatalogue({
    this.types,
    this.langue,
    this.categorie,
    this.niveau,
    this.etatOffline,
  });

  /// Les types retenus. `null` ou vide : tous les types.
  final Set<TypeRessource>? types;

  /// La langue retenue.
  final String? langue;

  /// La categorie retenue.
  final String? categorie;

  /// Le code de niveau retenu.
  final String? niveau;

  /// L'etat hors ligne retenu.
  final EtatOffline? etatOffline;

  /// Vrai quand aucun axe n'est pose.
  bool get vide =>
      (types == null || types!.isEmpty) &&
      langue == null &&
      categorie == null &&
      niveau == null &&
      etatOffline == null;

  /// Une copie avec un axe change. `remettre` relache l'axe vise.
  FiltreCatalogue avec({
    Set<TypeRessource>? types,
    String? langue,
    String? categorie,
    String? niveau,
    EtatOffline? etatOffline,
    Set<String> relacher = const <String>{},
  }) => FiltreCatalogue(
    types: relacher.contains('types') ? null : types ?? this.types,
    langue: relacher.contains('langue') ? null : langue ?? this.langue,
    categorie: relacher.contains('categorie')
        ? null
        : categorie ?? this.categorie,
    niveau: relacher.contains('niveau') ? null : niveau ?? this.niveau,
    etatOffline: relacher.contains('etatOffline')
        ? null
        : etatOffline ?? this.etatOffline,
  );
}

/// « Continuer » : la derniere ressource ouverte et la derniere position.
@immutable
class ReprisLecture {
  /// Cree une reprise.
  ///
  /// Non `const` : l'assertion d'UTC lit un getter d'instance, qui ne
  /// s'evalue pas a la compilation. L'invariant de temps l'emporte sur la
  /// canonicalisation.
  ReprisLecture({
    required this.ressource,
    required this.position,
    required this.vueLeUtc,
  }) : assert(vueLeUtc.isUtc, 'tout DateTime d un contrat est en UTC');

  /// La ressource a reprendre.
  final LibraryResource ressource;

  /// Ou la reprendre.
  final ContentPosition position;

  /// Quand elle a ete vue pour la derniere fois, en UTC.
  final DateTime vueLeUtc;
}

/// Le catalogue de la Bibliotheque (CONTRACTS section 4).
///
/// **Une seule Bibliotheque.** Ce port sert hors classe et en classe ; il
/// n'existe pas de variante « en classe » (decision D-20).
///
/// **Ce port ne decide aucun acces.** Il rend ce que le serveur laisse voir a
/// l'appelant. Une ressource refusee n'apparait pas dans [tous] et [parId]
/// rend `null` : l'interface l'explique, elle ne la filtre pas elle-meme.
abstract class PortCatalogue {
  /// Tous les supports visibles, filtres si [filtre] est fourni.
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre});

  /// Les ressources recemment ouvertes, les plus recentes en premier.
  Future<List<LibraryResource>> recents({int limite = 10});

  /// Les ressources epinglees ou assignees a un groupe.
  Future<List<LibraryResource>> pourGroupe(String groupeId);

  /// Une ressource precise, ou `null` quand l'appelant ne la voit pas.
  Future<LibraryResource?> parId(String resourceId);

  /// La recherche libre, filtree si [filtre] est fourni.
  Future<List<LibraryResource>> rechercher(
    String requete, {
    FiltreCatalogue? filtre,
  });

  /// « Continuer » : derniere ressource et derniere position.
  Future<ReprisLecture?> derniereLecture();
}

/// Une lecture de catalogue qui echoue.
///
/// **Ajout d'Agent B au contrat canonique**, dans l'esprit de CONTRACTS
/// section 0 (« un port rend un resultat type ou leve une exception de son
/// domaine `EchecXxx` »). Sa promotion est demandee dans
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_B.md`. Elle distingue un refus
/// serveur d'une absence : une absence ouvre un etat vide, un refus ouvre un
/// etat explique.
class EchecCatalogue implements Exception {
  /// Cree l'echec.
  const EchecCatalogue(this.raison);

  /// Ce qui a echoue, en une phrase technique.
  final String raison;

  @override
  String toString() => 'EchecCatalogue: $raison';
}
