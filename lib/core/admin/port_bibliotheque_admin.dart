/// CAP29-0 : le port de la bibliotheque, cote administration.
///
/// L'administration depose une ressource, prouve ses droits, verifie le
/// rendu, publie une version immuable, l'attribue a des classes et peut la
/// retirer (spec CAP-29, §3 a §5). Ce port est le **contrat** que l'ecran fixe
/// et que le serveur (lot CAP29-BACK-1, 2, zone Codex) satisfait : l'ecran ne
/// presume ni schema, ni stockage, ni signature.
///
/// Garanties que le port porte et que Flutter ne decide jamais :
/// - **autorisation** : les capacites ([CapacitesBibliotheque],
///   [CapacitesSupport]) sont rendues par le serveur ; un widget les lit, il ne
///   lit jamais un role ;
/// - **catalogue** : filtres et pagination cote serveur, curseur, aucun total ;
/// - **versions** : une version publiee est immuable, une nouvelle version est
///   un nouveau brouillon ; la publication est atomique ;
/// - **fichier** : intention, depot, confirmation ; le client ne voit ni cle
///   de stockage, ni URL signee durable (R2, jamais Supabase Storage) ;
/// - **concurrence** : chaque ecriture porte la revision attendue.
///
/// Aucun branchement serveur : en production [portBibliothequeAdminProvider]
/// vaut `null` et l'ecran dit « disponible au branchement serveur ». La
/// demonstration le surcharge par un double.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modeles_bibliotheque_admin.dart';

/// La dependance serveur des ecrans (lots CAP29-BACK-1 et CAP29-BACK-2).
const String dependanceBibliothequeAdmin = 'CAP29-BACK-1';

/// Ce que la personne connectee peut faire dans la bibliotheque, rendu par le
/// serveur. Aucune capacite n'est deduite d'un role.
class CapacitesBibliotheque {
  /// Cree les capacites.
  const CapacitesBibliotheque({
    this.peutLire = false,
    this.peutImporter = false,
    this.peutPublier = false,
    this.peutAttribuer = false,
  });

  /// Aucune capacite (non autorise).
  static const CapacitesBibliotheque aucune = CapacitesBibliotheque();

  /// Voir le catalogue d'administration.
  final bool peutLire;

  /// Creer un brouillon et deposer un fichier.
  final bool peutImporter;

  /// Publier et retirer.
  final bool peutPublier;

  /// Attribuer aux classes.
  final bool peutAttribuer;
}

/// Pourquoi une operation de la bibliotheque echoue, hors resultats metier.
sealed class ErreurBibliotheque implements Exception {
  const ErreurBibliotheque();
}

/// La personne n'a pas la capacite.
final class BibliothequeNonAutorisee extends ErreurBibliotheque {
  /// Cree l'erreur.
  const BibliothequeNonAutorisee();
}

/// L'objet n'existe pas, ou n'est pas visible par cette personne : les deux
/// cas ne se distinguent jamais.
final class BibliothequeIntrouvable extends ErreurBibliotheque {
  /// Cree l'erreur.
  const BibliothequeIntrouvable();
}

/// La connexion a coupe : l'operation n'est pas confirmee.
final class BibliothequeHorsLigne extends ErreurBibliotheque {
  /// Cree l'erreur.
  const BibliothequeHorsLigne();
}

/// Le port de l'administration de la bibliotheque.
abstract interface class PortBibliothequeAdmin {
  /// Ce que la personne connectee peut faire.
  Future<CapacitesBibliotheque> capacites();

  /// Les valeurs de filtre (niveaux, langues) que le catalogue propose.
  Future<FacettesCatalogue> facettes();

  /// Une page du catalogue. Filtres et curseur bornes, jamais de total.
  Future<PageSupports> lister({
    FiltreCatalogue filtre = const FiltreCatalogue(),
    String? curseur,
    int limite = 25,
  });

  /// La fiche d'un support. [BibliothequeIntrouvable] si absent ou non
  /// visible.
  Future<FicheSupport> fiche(String supportId);

  /// Cree un brouillon (version 1, aucun fichier). Rend l'identifiant.
  Future<String> creerBrouillon(NouveauSupport saisie);

  /// Met a jour un brouillon, sous controle de revision.
  Future<ResultatEcriture> mettreAJour({
    required String supportId,
    required ModificationSupport modification,
    required int revisionAttendue,
  });

  /// Cree une nouvelle version brouillon d'un support publie. Rend l'id de la
  /// version.
  Future<String> nouvelleVersion(String supportId);

  /// Cree l'intention de depot d'un fichier pour un brouillon.
  Future<IntentionUpload> demanderUpload({
    required String supportId,
    required FichierADeposer fichier,
    FinaliteUpload finalite = FinaliteUpload.support,
  });

  /// Depose le fichier et diffuse la progression. Se termine a `pret`,
  /// `annule` ou `echec`. [octets] est le contenu ; sans lui (apercu), le
  /// double simule la progression.
  Stream<ProgressionUpload> deposer({
    required String uploadId,
    Uint8List? octets,
  });

  /// Annule un depot en cours.
  Future<void> annulerUpload(String uploadId);

  /// Revoit les droits d'une version brouillon (source, titulaire, preuve,
  /// usages, attribution, echeance). Changer de version reinitialise la revue.
  Future<ResultatEcriture> revoirDroits({
    required String supportId,
    required String versionId,
    required SaisieDroits saisie,
    required int revisionAttendue,
  });

  /// Le controle de publication d'une version : criteres et publiabilite
  /// rendus par le serveur.
  Future<ControleVersion> controler(String versionId);

  /// Publie une version : atomique, idempotente par [cle].
  Future<ResultatPublication> publier({
    required String supportId,
    required String versionId,
    required int revisionAttendue,
    required String cle,
  });

  /// Les classes auxquelles le support peut etre attribue, a curseur.
  Future<PageClasses> classes({
    required String supportId,
    String? curseur,
    int limite = 25,
  });

  /// Attribue un support publie a des classes (idempotent).
  Future<ResultatEcriture> attribuer({
    required String supportId,
    required Set<String> classeIds,
    required bool epingler,
    required int revisionAttendue,
  });

  /// Retire un support du catalogue : un motif, jamais une suppression
  /// physique.
  Future<ResultatEcriture> retirer({
    required String supportId,
    required String motif,
    required int revisionAttendue,
  });
}

/// Le port : absent avant le branchement serveur.
final Provider<PortBibliothequeAdmin?> portBibliothequeAdminProvider =
    Provider<PortBibliothequeAdmin?>((Ref _) => null);
