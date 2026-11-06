// Retraits de comptes (SUPPRIMER et SUPPRIMER-bis, migrations 20261108600000
// et 20261108900000) : la direction retire des comptes choisis, voit les
// retraits, en restaure un pendant le delai ; le tuteur supprime le profil
// d'un enfant de son foyer.
//
// Le serveur decide de tout : qui peut, quel compte se retire, le delai avant
// l'anonymisation, ce qui se restaure. Flutter envoie la selection et affiche
// le resultat de chaque compte ; il ne calcule ni droit ni delai.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import 'capacite_indisponible.dart';

/// Pourquoi le serveur a refuse de retirer ou de restaurer un compte.
enum RaisonRefusRetrait {
  /// Le compte n'existe pas.
  introuvable,

  /// Le compte est deja retire.
  dejaRetire,

  /// On ne retire pas son propre compte.
  soiMeme,

  /// Un compte de la direction (administration, controle, comptabilite).
  compteDirection,

  /// Des seances a venir sont encore prevues avec cet enseignant.
  seancesAVenir,

  /// Aucun retrait en cours pour ce compte.
  aucunRetrait,

  /// Le compte est deja anonymise : rien a restaurer.
  dejaAnonymise,

  /// Retrait trop ancien : son etat d'avant n'est pas connu.
  etatAvantInconnu,

  /// Erreur du serveur sur ce compte ; les autres ont ete traites.
  erreur,
}

/// Le resultat d'un retrait, pour un compte.
@immutable
class ResultatRetrait {
  /// Cree le resultat.
  const ResultatRetrait({
    required this.id,
    required this.retire,
    this.raison,
    this.anonymiserLe,
    this.anonymise = false,
    this.seancesAVenir = 0,
  });

  /// Le profil vise.
  final String id;

  /// Vrai quand le compte est retire.
  final bool retire;

  /// La raison du refus, quand [retire] est faux.
  final RaisonRefusRetrait? raison;

  /// Le moment ou le compte sera anonymise, s'il est retire.
  final DateTime? anonymiserLe;

  /// Vrai quand le compte a ete anonymise tout de suite.
  final bool anonymise;

  /// Le nombre de seances a venir qui bloquent (refus `seances_a_venir`).
  final int seancesAVenir;
}

/// Le resultat d'une restauration, pour un compte.
@immutable
class ResultatRestauration {
  /// Cree le resultat.
  const ResultatRestauration({
    required this.id,
    required this.restaure,
    this.raison,
    this.classesQuittees = 0,
  });

  /// Le profil vise.
  final String id;

  /// Vrai quand le compte est restaure.
  final bool restaure;

  /// La raison du refus, quand [restaure] est faux.
  final RaisonRefusRetrait? raison;

  /// Les classes que l'eleve avait quittees au retrait : la restauration ne
  /// l'y remet pas, la direction le reaffecte.
  final int classesQuittees;
}

/// Quels retraits lire.
enum EtatRetraits {
  /// Ni anonymises ni restaures.
  enCours,

  /// Anonymises.
  anonymises,

  /// Restaures.
  restaures,

  /// Tous.
  tous,
}

/// Qui a retire le compte.
enum SourceRetrait {
  /// La direction.
  direction,

  /// Le tuteur du foyer.
  tuteur,
}

/// Un retrait, vu de la direction.
@immutable
class RetraitCompte {
  /// Cree le retrait.
  const RetraitCompte({
    required this.retraitId,
    required this.profilId,
    required this.matricule,
    required this.nom,
    required this.source,
    required this.retireLe,
    required this.anonymiserLe,
    required this.restaurable,
    this.role,
    this.motif,
    this.anonymiseLe,
    this.restaureLe,
  });

  /// L'identifiant du retrait.
  final String retraitId;

  /// Le profil retire.
  final String profilId;

  /// Son matricule.
  final String matricule;

  /// Son nom (vide une fois anonymise).
  final String nom;

  /// Son role au moment du retrait, ou `null` s'il est illisible.
  final AppRole? role;

  /// Qui l'a retire.
  final SourceRetrait source;

  /// Le motif ecrit par la direction.
  final String? motif;

  /// Le moment du retrait.
  final DateTime retireLe;

  /// Le moment prevu de l'anonymisation.
  final DateTime anonymiserLe;

  /// Le moment de l'anonymisation, si elle a eu lieu.
  final DateTime? anonymiseLe;

  /// Le moment de la restauration, si elle a eu lieu.
  final DateTime? restaureLe;

  /// Capacite rendue par le serveur : « Restaurer » est ouvert.
  final bool restaurable;
}

/// Ou reprendre la liste : le dernier retrait lu.
@immutable
class CurseurRetraits {
  /// Cree le curseur.
  const CurseurRetraits({required this.apresLe, required this.apresId});

  /// Le moment du dernier retrait lu.
  final DateTime apresLe;

  /// Son identifiant.
  final String apresId;
}

/// Une page de retraits.
@immutable
class PageRetraits {
  /// Cree la page.
  const PageRetraits({required this.lignes, this.suivant});

  /// Les retraits, du plus recent au plus ancien.
  final List<RetraitCompte> lignes;

  /// La page suivante, ou `null` s'il n'y en a plus.
  final CurseurRetraits? suivant;
}

/// Ce que le serveur repond au tuteur.
enum ResultatSuppressionEnfant {
  /// Le profil est retire ; il sera anonymise apres le delai.
  retire,

  /// Le profil n'est pas un enfant mineur de son foyer.
  horsFoyer,

  /// Le profil est deja retire ou n'existe plus.
  dejaRetire,
}

/// Les retraits de comptes (SUPPRIMER).
abstract interface class PortRetraitsComptes {
  /// Retire les comptes [ids] (200 au plus). Un resultat par compte.
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  });

  /// Une page de retraits. Lecture seule.
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  });

  /// Restaure les comptes [ids] (200 au plus). Un resultat par compte.
  Future<List<ResultatRestauration>> restaurer(List<String> ids);

  /// Le tuteur supprime le profil de l'enfant [eleveId].
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(String eleveId);
}

/// Tant qu'aucun adaptateur serveur n'est branche (demonstration, tests) :
/// l'ecran dit que la fonction est indisponible.
class RetraitsComptesIndisponibles implements PortRetraitsComptes {
  /// Cree l'implementation.
  const RetraitsComptesIndisponibles();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'SUPPRIMER',
  );

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) => Future<List<ResultatRetrait>>.error(_absente);

  @override
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  }) => Future<PageRetraits>.error(_absente);

  @override
  Future<List<ResultatRestauration>> restaurer(List<String> ids) =>
      Future<List<ResultatRestauration>>.error(_absente);

  @override
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(String eleveId) =>
      Future<ResultatSuppressionEnfant>.error(_absente);
}

/// Le port des retraits de comptes.
final Provider<PortRetraitsComptes> portRetraitsComptesProvider =
    Provider<PortRetraitsComptes>(
      (Ref ref) => const RetraitsComptesIndisponibles(),
    );
