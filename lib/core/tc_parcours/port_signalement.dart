import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../tc_outils/fonction_indisponible.dart';
import 'student_concern.dart';

/// Le signalement structure (`TEACHING_CORE_CONTRACTS.md` section 16).
///
/// **Contrat produit par Agent H**, consomme par H, E (action de fiche), Q et
/// l'administration a l'integration.
///
/// **Le contexte est prerempli par l'implementation, pas saisi par
/// l'enseignant.** Les trois identifiants que porte [signaler] viennent de
/// l'ecran ou il se trouve deja -- la seance ouverte, le groupe ouvert, la fiche
/// ouverte -- et l'identite de l'enseignant vient du jeton, jamais d'un champ.
/// Le professeur choisit une categorie et ecrit ce qu'il a a dire ; il ne retape
/// aucun identifiant.
abstract class PortSignalement {
  /// Depose un signalement.
  ///
  /// [familySummary] est facultatif, et l'absence est le **cas normal** : un
  /// signalement interne n'a pas toujours de message pour la famille, et en
  /// fabriquer un automatiquement serait exactement la fuite que la spec
  /// interdit.
  Future<StudentConcern> signaler({
    required CategorieSignalement categorie,
    required String groupeId,
    String? sessionId,
    required String academyId,
    required String internalDetails,
    String? familySummary,
  });

  /// Les signalements deposes par l'enseignant connecte.
  Future<List<StudentConcern>> mesSignalements({String? groupeId});

  /// Preparation de l'action Admin future. **Non branchee en phase parallele.**
  ///
  /// La transmission est une decision de l'administration, en un clic, vers le
  /// tuteur d'un mineur ou vers l'eleve adulte. Elle **echoue** quand aucun
  /// message famille n'existe : il n'y a alors rien a transmettre, et surtout
  /// pas la note interne.
  Future<void> transmettre({
    required String concernId,
    required CibleTransmission cible,
  });
}

/// Les signalements, en memoire.
///
/// **DOUBLE LOCAL ASSUME.** Aucune table `student_concern` n'existe en base :
/// la demande SQL est en section 2 de
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_H.md`. La forme a reprendre est celle
/// de `matching_requests` (demande -> decision admin -> audit), **pas la table
/// elle-meme** : `0022_progression_suivi.sql` interdit explicitement de
/// l'etendre avec des clefs pedagogiques.
class SignalementMemoire implements PortSignalement {
  /// Cree un depot en memoire pour l'enseignant donne.
  ///
  /// [enseignantId] est ce que l'implementation serveur lira dans le jeton :
  /// il est **prerempli**, jamais saisi.
  SignalementMemoire(
    this._enseignantId, {
    Uuid? generateur,
    DateTime Function()? maintenant,
  }) : _generateur = generateur ?? const Uuid(),
       _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final String _enseignantId;
  final Uuid _generateur;
  final DateTime Function() _maintenant;
  final List<StudentConcern> _signalements = <StudentConcern>[];

  @override
  Future<StudentConcern> signaler({
    required CategorieSignalement categorie,
    required String groupeId,
    String? sessionId,
    required String academyId,
    required String internalDetails,
    String? familySummary,
  }) async {
    final String interne = internalDetails.trim();
    if (interne.isEmpty) {
      throw const EchecSignalement(MotifEchecSignalement.interneVide);
    }
    final String? famille = familySummary?.trim();

    final StudentConcern signalement = StudentConcern(
      id: _generateur.v4(),
      categorie: categorie,
      groupeId: groupeId,
      sessionId: sessionId,
      academyId: academyId,
      enseignantId: _enseignantId,
      internalDetails: interne,
      // Une chaine vide n'est pas un message : elle vaut `null`, sans quoi
      // l'action « Transmettre » s'ouvrirait sur un message vide.
      familySummary: famille == null || famille.isEmpty ? null : famille,
      statut: StatutSignalement.ouvert,
      creeLeUtc: _maintenant(),
    );
    _signalements.add(signalement);
    return signalement;
  }

  @override
  Future<List<StudentConcern>> mesSignalements({String? groupeId}) async =>
      List<StudentConcern>.unmodifiable(
        _signalements.where(
          (StudentConcern s) => groupeId == null || s.groupeId == groupeId,
        ),
      );

  @override
  Future<void> transmettre({
    required String concernId,
    required CibleTransmission cible,
  }) async {
    final int rang = _signalements.indexWhere(
      (StudentConcern s) => s.id == concernId,
    );
    if (rang == -1) {
      throw const EchecSignalement(MotifEchecSignalement.inconnu);
    }
    // `transmis` refuse elle-meme un signalement sans message famille : la
    // regle vit dans le contrat, pas dans ce double.
    _signalements[rang] = _signalements[rang].transmis(
      cible: cible,
      maintenantUtc: _maintenant(),
    );
  }
}

/// Le signalement quand aucun serveur n'est branche.
///
/// SALLE-ROBUSTE : aucun signalement n'est connu, et signaler ou transmettre
/// leve [FonctionIndisponible]. Il n'avale jamais un signalement : un
/// enseignant ne doit pas croire que l'administration a ete prevenue.
class SignalementIndisponible implements PortSignalement, PortIndisponible {
  /// Cree le signalement indisponible.
  const SignalementIndisponible();

  static const FonctionIndisponible _echec = FonctionIndisponible(
    'signalement',
  );

  @override
  Future<StudentConcern> signaler({
    required CategorieSignalement categorie,
    required String groupeId,
    String? sessionId,
    required String academyId,
    required String internalDetails,
    String? familySummary,
  }) => Future<StudentConcern>.error(_echec);

  @override
  Future<List<StudentConcern>> mesSignalements({String? groupeId}) async =>
      const <StudentConcern>[];

  @override
  Future<void> transmettre({
    required String concernId,
    required CibleTransmission cible,
  }) => Future<void>.error(_echec);
}

/// Le signalement employe par l'application.
///
/// Sans serveur, il rend [SignalementIndisponible] : l'ecran dit que la
/// fonction n'est pas encore disponible au lieu de lever. Agent Z le surcharge
/// a l'integration (`SignalementMemoire` pour les tests et la demonstration).
final Provider<PortSignalement> portSignalementProvider =
    Provider<PortSignalement>(
      (Ref ref) => const SignalementIndisponible(),
    );
