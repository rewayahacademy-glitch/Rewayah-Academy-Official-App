// Port de la revue des dossiers d'identite (AD-4, contrats 17.1 a 17.4 et
// 17.6). Neutre : aucune dependance reseau. L'implementation par defaut dit
// « indisponible » (K-09) ; le vrai adaptateur ne se branchera que dans
// `lib/main.dart`, quand les besoins `AD-BR-nn` existeront (K-28).
//
// Toutes les dates sont en UTC cote port ; l'affichage local revient aux
// ecrans. Le genre n'apparait dans aucun modele : le client ne le lit jamais.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import 'capacite_indisponible.dart';

/// Statut de revue d'un dossier.
enum StatutRevue { aVerifier, valide, refuse }

/// La piece est-elle exigee pour ce dossier.
enum ExigencePiece { requise, dispensee }

/// Etat de la piece vu par CE relecteur.
enum EtatPieceRevue {
  disponible,

  /// Requise, non transmise.
  absente,

  /// Dispensee.
  nonRequise,

  /// Hors de portee de ce relecteur (politique de genre active).
  nonVisible,
}

/// Ce qu'une validation produirait (13.2). `indeterminee` : la validation est
/// indisponible pour le moment.
enum ConsequenceValidation {
  activationPossible,
  documentaireSeule,
  indeterminee,
}

/// Raisons pour lesquelles un geste est ferme. Libelles traduits par les
/// ecrans, jamais par le port.
enum BlocageRevue {
  pieceAbsente,
  pieceNonVisible,
  accordManquant,
  dejaDecide,
  decisionIndisponible,

  /// La piece existe dans un format que la visionneuse n'affiche pas : on
  /// n'atteste pas une piece qu'on n'a pas vue.
  pieceNonConsultable,
}

/// Le verdict.
enum DecisionDossier { valider, refuser }

/// Qui pose une verification.
enum OrigineVerification { humaine, serveur }

/// Etat d'une verification.
enum EtatVerification { aFaire, faite }

/// Etat d'un accord soumis.
enum EtatAccord { accepte, manquant }

/// Reponses metier typees. Aucun message SQL brut ne remonte.
enum CodeErreurRevue {
  nonAutorise,
  interdit,
  introuvable,

  /// `stale`, `stale_dossier`.
  perime,
  dejaDecide,
  verificationManquante,
  accordManquant,

  /// `document_unavailable`.
  pieceIndisponible,
  activationImpossible,
  expire,
  typeNonPrisEnCharge,
  motifRequis,

  /// Q30 : le motif depasse la longueur admise par le serveur.
  motifTropLong,

  /// Meme `command_id`, autre charge.
  commandeIncoherente,

  /// P-ADM-10 : la reponse s'est perdue, ce n'est JAMAIS un echec certain.
  reponsePerdue,

  /// 15.3, seulement quand la politique de genre est active.
  profilACompleter,
  indisponibleTemporairement,
}

/// Une reponse metier typee. Se distingue de [CapaciteIndisponible], qui ne
/// se reessaye pas.
class ErreurRevueDossier implements Exception {
  const ErreurRevueDossier(this.code);

  final CodeErreurRevue code;

  @override
  String toString() => 'ErreurRevueDossier(${code.name})';
}

/// Une ligne de la file (9.9) : une personne, aucune cle d'objet.
@immutable
class DossierEnFile {
  const DossierEnFile({
    required this.dossierId,
    required this.nomAffiche,
    required this.role,
    required this.soumisLeUtc,
    required this.statut,
    required this.revision,
    required this.aPieceIdentite,
    this.etatPiece,
  });

  final String dossierId;

  /// Prenom puis nom (`subject_display_name`).
  final String nomAffiche;
  final AppRole role;
  final DateTime soumisLeUtc;
  final StatutRevue statut;
  final int revision;
  final bool aPieceIdentite;

  /// Etat de la piece vu par CE relecteur, quand la source le dit (HL-A-1).
  /// Nul : inconnu, la ligne s'en tient a [aPieceIdentite].
  final EtatPieceRevue? etatPiece;
}

/// Une page de la file.
@immutable
class PageDossiers {
  const PageDossiers({required this.elements, this.curseurSuivant, this.total});

  final List<DossierEnFile> elements;
  final String? curseurSuivant;

  /// Nul quand le serveur ne peut pas le garantir.
  final int? total;

  bool get aSuite => curseurSuivant != null;
}

/// Une verification de la revue. Identifiants : `lisible`, `nom`,
/// `validite` (ceux de `dossiers_page.dart`).
@immutable
class VerificationRevue {
  const VerificationRevue({
    required this.id,
    required this.origine,
    required this.obligatoire,
    required this.etat,
    required this.modifiable,
  });

  final String id;
  final OrigineVerification origine;
  final bool obligatoire;
  final EtatVerification etat;
  final bool modifiable;
}

/// Un accord soumis avec le dossier.
@immutable
class AccordSoumis {
  const AccordSoumis({required this.sorte, required this.etat, this.version});

  final SorteContrat sorte;
  final String? version;
  final EtatAccord etat;
}

/// Le detail d'un dossier pour la revue (17.2).
@immutable
class DossierPourRevue {
  const DossierPourRevue({
    required this.dossierId,
    required this.revision,
    required this.prenom,
    required this.nom,
    required this.role,
    required this.soumisLeUtc,
    required this.statut,
    required this.exigencePiece,
    required this.etatPiece,
    required this.verifications,
    required this.accords,
    required this.peutValider,
    required this.peutRefuser,
    required this.peutVoirPiece,
    required this.blocagesValidation,
    required this.blocagesRefus,
    required this.consequence,
    this.typePiece,
    this.documentId,
    this.revisionDocument,
    this.peutResoumettre,
    this.blocagesAcces = const <BlocageRevue>[],
    this.lectureRequise = false,
  });

  /// Vrai : les verifications et la validation restent fermees tant que la
  /// visionneuse n'a pas affiche la piece avec succes, et se referment sur un
  /// echec de lecture (P-ADM-06 point 5). Pose par l'adaptateur de production.
  final bool lectureRequise;

  final String dossierId;
  final int revision;
  final String prenom;
  final String nom;
  final AppRole role;
  final DateTime soumisLeUtc;
  final StatutRevue statut;
  final ExigencePiece exigencePiece;
  final EtatPieceRevue etatPiece;
  final TypePiece? typePiece;
  final String? documentId;
  final int? revisionDocument;
  final List<VerificationRevue> verifications;
  final List<AccordSoumis> accords;
  final bool peutValider;
  final bool peutRefuser;
  final bool peutVoirPiece;
  final List<BlocageRevue> blocagesValidation;
  final List<BlocageRevue> blocagesRefus;

  /// Pourquoi la piece n'est pas visible (vide quand [peutVoirPiece]).
  final List<BlocageRevue> blocagesAcces;

  /// `can_resubmit` (17.2) ; nul quand le serveur ne le fournit pas.
  final bool? peutResoumettre;
  final ConsequenceValidation consequence;
}

/// D'ou vient l'image de la piece.
sealed class SourcePiece {
  const SourcePiece();
}

/// Une URL de courte duree rendue par le serveur.
final class SourcePieceUrl extends SourcePiece {
  const SourcePieceUrl(this.url);

  final Uri url;
}

/// Demonstration : l'ecran dessine une piece neutre portant « Document
/// fictif », jamais une image realiste.
final class SourcePieceFictive extends SourcePiece {
  const SourcePieceFictive();
}

/// Une vue autorisee de la piece (17.3).
@immutable
class VuePiece {
  const VuePiece({
    required this.documentId,
    required this.source,
    required this.expireLeUtc,
    required this.typeMime,
  });

  final String documentId;
  final SourcePiece source;
  final DateTime expireLeUtc;
  final String typeMime;
}

/// Le resultat d'une decision (17.4).
@immutable
class ResultatDecision {
  const ResultatDecision({
    required this.dossierId,
    required this.statutFinal,
    required this.nouvelleRevision,
    required this.decideLeUtc,
    this.etatCompte,
  });

  final String dossierId;
  final StatutRevue statutFinal;

  /// L'acces reellement acquis, distinct de la decision.
  final AccountStatus? etatCompte;
  final int nouvelleRevision;
  final DateTime decideLeUtc;
}

/// L'etat d'une commande de decision (`get_decision_result`, 17.6).
sealed class EtatCommande {
  const EtatCommande();
}

final class EtatCommandeEnAttente extends EtatCommande {
  const EtatCommandeEnAttente();
}

final class EtatCommandeReussie extends EtatCommande {
  const EtatCommandeReussie(this.resultat);

  final ResultatDecision resultat;
}

final class EtatCommandeEchouee extends EtatCommande {
  const EtatCommandeEchouee(this.code);

  final CodeErreurRevue code;
}

final class EtatCommandeInconnue extends EtatCommande {
  const EtatCommandeInconnue();
}

/// La revue des dossiers.
abstract interface class PortRevueDossiers {
  /// 17.1. Tri : `soumisLeUtc` croissant puis `dossierId`. Autorisation et
  /// politique appliquees AVANT pagination et total.
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  });

  /// 17.2. Erreurs : introuvable, interdit, perime, indisponibleTemporairement.
  Future<DossierPourRevue> dossierPourRevue(String dossierId);

  /// 17.3. Le client ne choisit jamais un objet : le couple (dossier,
  /// document) est verifie. Erreurs : interdit, expire, introuvable,
  /// typeNonPrisEnCharge, indisponibleTemporairement.
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  });

  /// 17.4 et 17.6 : les verifications partent avec la decision atomique.
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  });

  /// 17.6 `get_decision_result`.
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  });
}

/// L'implementation par defaut : rien ne sert encore ces contrats.
class RevueDossiersIndisponible implements PortRevueDossiers {
  const RevueDossiersIndisponible();

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) => Future<PageDossiers>.error(const CapaciteIndisponible('AD-BR-01'));

  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) =>
      Future<DossierPourRevue>.error(const CapaciteIndisponible('AD-BR-02'));

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) => Future<VuePiece>.error(const CapaciteIndisponible('AD-BR-03'));

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) => Future<ResultatDecision>.error(const CapaciteIndisponible('AD-BR-06'));

  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) => Future<EtatCommande>.error(const CapaciteIndisponible('AD-BR-07'));
}

/// Le port employe par l'application. Indisponible par defaut (K-09).
final Provider<PortRevueDossiers> portRevueDossiersProvider =
    Provider<PortRevueDossiers>((Ref ref) => const RevueDossiersIndisponible());
