import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs dans ce depot : le type d'une famille de providers
// n'est pas exporte par l'entree principale de Riverpod 3, il vit dans
// `misc.dart` (meme convention que `service_planning.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:uuid/uuid.dart';

import '../enseignant/depot_cahiers.dart';
import '../enseignant/modeles_enseignant.dart';
import '../enseignant/service_enseignant.dart';
import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import '../tc_classe/port_roster_enseignant.dart';
import '../tc_classe/teacher_student_projection.dart';
import '../tc_outils/intention_pedagogique.dart';
import '../tc_outils/learning_assignment.dart';
import '../tc_outils/port_assignations.dart';
import 'port_travail_a_venir.dart';
import 'post_cours_vm.dart';
import 'source_contenu_seance.dart';

/// Pourquoi un post-cours n'a pas abouti.
enum MotifEchecPostCours {
  /// La seance n'existe pas, ou l'enseignant n'y a pas acces.
  seanceIntrouvable,

  /// Le constat prerempli n'a pas pu etre lu, et rien ne le remplace.
  ///
  /// Distinct de [seanceIntrouvable] : ici la seance existe, mais la lecture a
  /// echoue. Le premier ne se reessaye pas, le second oui.
  brouillonIndisponible,

  /// Le compte rendu est parti ou est en file, mais le travail propose n'a pas
  /// pu etre pose.
  ///
  /// **Deux faits dans un seul echec, et c'est voulu** : l'enseignant doit
  /// savoir que son cours est cloture et que le travail, lui, ne l'est pas.
  travailNonPose,
}

/// L'echec d'un post-cours.
class EchecPostCours implements Exception {
  /// Cree un echec.
  const EchecPostCours(this.motif);

  /// Ce qui a echoue.
  final MotifEchecPostCours motif;

  @override
  String toString() => 'EchecPostCours($motif)';
}

/// Le post-cours enseignant (`TEACHING_CORE_CONTRACTS.md` section 16).
///
/// **Contrat produit par Agent H**, consomme par H et Q.
abstract class PortPostCours {
  /// Le post-cours prerempli : presence, duree, contenu presente, position et
  /// plages. **Cible : moins de 45 secondes pour l'enseignant.**
  Future<PostCoursVM> preparer(String sessionId);

  /// Enregistre ce que l'enseignant a valide.
  Future<void> enregistrer(PostCoursVM saisie);
}

/// Le post-cours, compose au-dessus du cahier de transmission existant.
///
/// **Rien n'est reecrit ici de ce que le chantier enseignant a livre.** Le
/// constat prerempli vient de `brouillon_cahier()` par `ServiceEnseignant`, et
/// l'ecriture passe par `SoumissionCahier` -- donc par `FileRapports`, sa cle
/// d'idempotence generee une seule fois, son verrou de vidage et sa file drift.
/// **C'est de la que vient le hors ligne du lot H** : il n'a pas ete reecrit, il
/// a ete reutilise.
///
/// Ce que le lot H ajoute, et que le cahier ne savait pas faire : lire la
/// position de reprise et les plages travaillees, en deduire un travail a
/// proposer, et poser ce travail a la validation.
class PostCoursDepuisCahier implements PortPostCours {
  /// Cree le composeur.
  ///
  /// Le dernier argument, `enseignantId`, est le profil qui signera le travail
  /// pose : il vient du jeton, jamais d'un champ de formulaire.
  ///
  /// Positionnel comme `SoumissionCahier(this._file, this._depot, this._service)`
  /// et `ServiceSuiviSupabase(this._client)` : c'est le patron du depot pour des
  /// dependances injectees.
  PostCoursDepuisCahier(
    this._service,
    this._soumission,
    this._roster,
    this._contenu,
    this._assignations,
    this._enseignantId, {
    Uuid? generateur,
    DateTime Function()? maintenant,
  }) : _generateur = generateur ?? const Uuid(),
       _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final ServiceEnseignant _service;
  final SoumissionCahier _soumission;
  final PortRosterEnseignant _roster;
  final SourceContenuSeance _contenu;
  final PortAssignations _assignations;
  final String _enseignantId;
  final Uuid _generateur;
  final DateTime Function() _maintenant;

  /// Le dernier constat lu, garde pour l'enregistrement.
  ///
  /// **Necessaire au hors ligne, pas a la performance.** L'enregistrement a
  /// besoin des identifiants d'eleves pour composer les decisions du cahier ; or
  /// hors ligne, `brouillon_cahier()` ne repond plus. Sans ce souvenir, le
  /// chemin hors ligne -- celui pour lequel la file existe -- serait le seul a
  /// echouer. Un seul constat est garde : un enseignant cloture une seance a la
  /// fois, et une carte sans borne finirait par retenir sa journee entiere.
  BrouillonCahier? _dernierConstat;

  @override
  Future<PostCoursVM> preparer(String sessionId) async {
    final BrouillonCahier? constat = await _lireConstat(sessionId);
    if (constat == null) {
      throw const EchecPostCours(MotifEchecPostCours.seanceIntrouvable);
    }
    _dernierConstat = constat;

    final List<ContentRange> ranges = await _contenu.rangesTravailles(
      sessionId,
    );
    final ContentPosition? reprise = await _contenu.positionDeReprise(
      sessionId,
    );

    return PostCoursVM(
      sessionId: sessionId,
      // La duree de la base, telle quelle.
      dureeReelle: Duration(minutes: constat.dureeMinutes),
      participants: await _projeter(sessionId),
      positionDeRepriseProposee: reprise,
      rangesTravailles: ranges,
      travailPropose: _proposerTravail(
        groupeId: constat.groupeId,
        ranges: ranges,
      ),
    );
  }

  @override
  Future<void> enregistrer(PostCoursVM saisie) async {
    await deposer(saisie);
  }

  /// Enregistre, et dit **ce qu'il est advenu** du compte rendu.
  ///
  /// Le contrat rend `void` : une surface plus riche y aurait ete une
  /// divergence. Mais l'ecran, lui, doit pouvoir ecrire « il partira des le
  /// retour du reseau » plutot que « envoye », et c'est ce que cette methode
  /// permet. L'amendement du contrat est demande en section 5 de
  /// `docs/teaching-core/TC_CONTRACT_REQUEST_H.md`.
  Future<SortCahier> deposer(PostCoursVM saisie) async {
    final BrouillonCahier constat = await _constatPour(saisie.sessionId);

    SortCahier sort = SortCahier.envoye;
    if (!constat.dejaDepose) {
      // Un cahier deja depose se lit, il ne se redepose pas : la cle
      // d'idempotence protege du doublon technique, elle ne justifie pas de le
      // provoquer.
      sort = await _soumission.soumettre(
        CahierARendre(
          seanceId: saisie.sessionId,
          decisions: <DecisionEleve>[
            for (final ParticipantBrouillon p in constat.participants)
              // Chaque ligne vaut « Continuer » : c'est le defaut du cahier
              // `ENS-04`, et le post-cours ne pose pas un second vocabulaire de
              // decision.
              DecisionEleve(studentId: p.membre.studentId),
          ],
          noteGroupe: saisie.notesExceptions,
        ),
      );
    }

    // Le travail est pose APRES le compte rendu : hors ligne, le compte rendu
    // part en file et le travail echoue, et c'est le bon ordre -- l'inverse
    // ferait perdre le compte rendu pour sauver une proposition.
    if (saisie.travailPropose.isNotEmpty) {
      try {
        for (final LearningAssignment travail in saisie.travailPropose) {
          await _assignations.creerDepuisSelection(
            groupId: travail.groupId,
            studentId: travail.studentId,
            resourceId: travail.resourceId,
            resourceVersionId: travail.resourceVersionId,
            contentRange: travail.contentRange,
            purpose: travail.purpose,
            instructions: travail.instructions,
            dueAtUtc: travail.dueAtUtc,
          );
        }
      } on Exception {
        throw const EchecPostCours(MotifEchecPostCours.travailNonPose);
      }
    }

    return sort;
  }

  /// Le constat de la seance, depuis le souvenir ou depuis le serveur.
  Future<BrouillonCahier> _constatPour(String sessionId) async {
    final BrouillonCahier? garde = _dernierConstat;
    if (garde != null && garde.seanceId == sessionId) {
      return garde;
    }
    final BrouillonCahier? relu = await _lireConstat(sessionId);
    if (relu == null) {
      throw const EchecPostCours(MotifEchecPostCours.brouillonIndisponible);
    }
    _dernierConstat = relu;
    return relu;
  }

  Future<BrouillonCahier?> _lireConstat(String sessionId) async {
    try {
      return await _service.brouillon(sessionId);
    } on Exception {
      return null;
    }
  }

  /// Le roster projete, ou une liste vide quand le serveur ne le projette pas.
  ///
  /// Agent E a nomme ce cas : `MotifEchecRoster.projectionAbsente`. Il est
  /// **l'etat courant du depot**, pas une panne, et il ne doit pas empecher un
  /// enseignant de cloturer son cours.
  Future<List<TeacherStudentProjection>> _projeter(String sessionId) async {
    try {
      return await _roster.rosterDeSeance(sessionId);
    } on EchecRoster {
      return const <TeacherStudentProjection>[];
    }
  }

  /// Le travail propose a partir de ce qui a ete travaille.
  ///
  /// **Une regle simple, et assumee comme telle** : ce qui vient d'etre vu se
  /// revoit. Chaque plage travaillee devient une proposition « A revoir »,
  /// bornee au plafond de trois actions du bloc « Avant le prochain cours » --
  /// inutile de proposer ce qui ne pourra pas s'afficher. L'enseignant change
  /// l'intention ou retire la ligne d'un geste ; le systeme propose, il ne
  /// decide pas.
  ///
  /// Sans groupe -- un cours individuel anterieur au pivot -- aucune proposition
  /// n'est faite : `LearningAssignment` est un objet de **groupe**.
  List<LearningAssignment> _proposerTravail({
    required String? groupeId,
    required List<ContentRange> ranges,
  }) {
    if (groupeId == null || ranges.isEmpty) {
      return const <LearningAssignment>[];
    }
    final DateTime debut = _maintenant();
    return <LearningAssignment>[
      for (final ContentRange plage
          in ranges.take(plafondActionsAvantCours))
        LearningAssignment(
          id: _generateur.v4(),
          groupId: groupeId,
          resourceId: plage.resourceId,
          resourceVersionId: plage.resourceVersionId,
          contentRange: plage,
          purpose: IntentionPedagogique.aRevoir,
          startsAtUtc: debut,
          createdBy: _enseignantId,
          status: StatutAssignation.aFaire,
        ),
    ];
  }
}

/// Le post-cours employe par l'application.
///
/// Il se compose de cinq morceaux, dont trois n'ont pas encore de source
/// serveur (roster projete, etat partage persiste, table d'assignations). Le
/// provider echoue plutot que d'en rendre une version partielle qui laisserait
/// croire a un cours cloture.
final Provider<PortPostCours> portPostCoursProvider = Provider<PortPostCours>(
  (Ref ref) => throw UnimplementedError(
    'PortPostCours : composer PostCoursDepuisCahier avec ServiceEnseignant, '
    "SoumissionCahier, le roster d'Agent E, une SourceContenuSeance et le "
    "PortAssignations d'Agent D.",
  ),
);

/// Le post-cours prerempli d'une seance.
final FutureProviderFamily<PostCoursVM, String> postCoursProvider =
    FutureProvider.family<PostCoursVM, String>(
      (Ref ref, String sessionId) =>
          ref.watch(portPostCoursProvider).preparer(sessionId),
    );
