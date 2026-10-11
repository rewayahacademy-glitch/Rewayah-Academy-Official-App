import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs dans ce depot : le type d'une famille de providers
// n'est pas exporte par l'entree principale de Riverpod 3, il vit dans
// `misc.dart` (meme convention que `service_planning.dart`).
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../tc_outils/fonction_indisponible.dart';
import 'session_feedback.dart';

/// Une question de micro-feedback, prete a etre posee.
///
/// Les trois libelles voyagent **avec** la question : une question sur le
/// rythme et une question sur la comprehension n'appellent pas les memes mots,
/// et poser « Difficile / Bien / Tres bien » sous chacune d'elles ferait de la
/// rotation un decor.
@immutable
class QuestionFeedback {
  /// Cree une question.
  const QuestionFeedback({
    required this.id,
    required this.intitule,
    required this.libelles,
  });

  /// L'identifiant stable de la question. C'est lui que la rotation suit.
  final String id;

  /// Ce qui est demande, en une phrase courte.
  final String intitule;

  /// Les trois reponses, dans les mots de cette question.
  final Map<ReponseFeedback, String> libelles;
}

/// Le micro-feedback occasionnel (`TEACHING_CORE_CONTRACTS.md` section 15).
///
/// **Contrat produit par Agent H**, consomme par H et Q.
///
/// Trois methodes, et la dissymetrie est voulue : on **depose** une reponse
/// nominative-en-rien, et on **lit** un agregat. Il n'existe aucune methode qui
/// rende les reponses une a une, parce qu'une telle methode finirait par etre
/// appelee (decision `D-17`).
abstract class PortFeedback {
  /// La question a poser apres cette seance, ou `null`.
  ///
  /// **`null` est le cas le plus frequent, et c'est voulu** : l'echantillonnage
  /// est configurable et le feedback ne s'affiche pas apres chaque seance. Un
  /// `null` n'est donc ni une erreur ni une indisponibilite : c'est « on ne
  /// demande rien cette fois », et l'UI n'affiche alors **rien du tout**, pas
  /// meme un emplacement vide.
  Future<QuestionFeedback?> questionPour(String sessionId);

  /// Depose la reponse. Un tap, termine, aucun commentaire.
  Future<void> soumettre({
    required String sessionId,
    required String questionId,
    required ReponseFeedback reponse,
  });

  /// Cote enseignant : **l'agregat seulement**, et seulement au-dessus du seuil.
  ///
  /// TC-Z-SUIVI : `t.tc.parcours.feedback.tendance.*` (titre, sousSeuil,
  /// anonyme) n'est encore consomme par aucun ecran -- ce port et son
  /// provider existent, mais rien ne les affiche cote enseignant.
  Future<TendanceFeedback> tendance({required String groupeId});
}

/// Pourquoi un feedback n'a pas pu etre depose.
enum MotifEchecFeedback {
  /// Reseau coupe, ecriture refusee, reponse illisible.
  ecriture,

  /// Une reponse existe deja pour cette seance et cette personne.
  ///
  /// Le micro-feedback se depose **une fois**. Un second depot n'est pas une
  /// erreur de l'utilisateur, c'est un double tap ou un rejeu : il se traite en
  /// silence cote UI, sans message d'echec.
  dejaDepose,
}

/// L'echec du depot d'un feedback.
class EchecFeedback implements Exception {
  /// Cree un echec.
  const EchecFeedback(this.motif);

  /// Ce qui a empeche le depot.
  final MotifEchecFeedback motif;

  @override
  String toString() => 'EchecFeedback($motif)';
}

/// Le micro-feedback quand aucun serveur n'est branche.
///
/// SALLE-ROBUSTE : aucune question n'est posee (`null`, le cas le plus
/// frequent du contrat : la carte n'affiche rien), la tendance est vide et
/// sous le seuil, et un depot echoue en [EchecFeedback], que l'ecran ignore
/// deja en silence. Rien n'est enregistre ni simule.
class FeedbackIndisponible implements PortFeedback, PortIndisponible {
  /// Cree le micro-feedback indisponible.
  const FeedbackIndisponible();

  @override
  Future<QuestionFeedback?> questionPour(String sessionId) async => null;

  @override
  Future<void> soumettre({
    required String sessionId,
    required String questionId,
    required ReponseFeedback reponse,
  }) => Future<void>.error(const EchecFeedback(MotifEchecFeedback.ecriture));

  @override
  Future<TendanceFeedback> tendance({required String groupeId}) async =>
      TendanceFeedback.depuis(
        groupeId: groupeId,
        reponses: const <ReponseFeedback>[],
        seuilMinimum: 1,
      );
}

/// Le micro-feedback employe par l'application.
///
/// Sans serveur, il rend [FeedbackIndisponible] : on ne demande rien, plutot
/// que de lever. Un double en memoire ferait croire a une collecte qui n'a pas
/// lieu ; Agent Z le surcharge a l'integration, les tests avec
/// `FeedbackMemoire`.
final Provider<PortFeedback> portFeedbackProvider = Provider<PortFeedback>(
  (Ref ref) => const FeedbackIndisponible(),
);

/// La question a poser apres une seance donnee, ou `null`.
///
/// `null` est le cas le plus frequent : l'echantillonnage n'est pas
/// systematique, et la carte ne s'affiche alors pas du tout.
final FutureProviderFamily<QuestionFeedback?, String> questionFeedbackProvider =
    FutureProvider.family<QuestionFeedback?, String>(
      (Ref ref, String sessionId) =>
          ref.watch(portFeedbackProvider).questionPour(sessionId),
    );

/// La tendance agregee d'un groupe, cote enseignant.
final FutureProviderFamily<TendanceFeedback, String> tendanceFeedbackProvider =
    FutureProvider.family<TendanceFeedback, String>(
      (Ref ref, String groupeId) =>
          ref.watch(portFeedbackProvider).tendance(groupeId: groupeId),
    );
