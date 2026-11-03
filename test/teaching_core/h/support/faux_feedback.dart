// M1-SUPPR (03/11/2026) : un faux `PortFeedback` pour les tests de la carte de
// micro-feedback (`carte_feedback_seance.dart`, gardee par le directeur le
// 03/11/2026). Il remplace `FeedbackMemoire` et `RotationFeedback`, supprimes :
// l'echantillonnage et la rotation sont decides par le serveur
// (`question_feedback_pour`, migration 0065), jamais par l'application.
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';

/// La question « cours », telle que le serveur la rendrait.
QuestionFeedback questionCours() => QuestionFeedback(
  id: 'cours',
  intitule: t.tc.parcours.feedback.cours.intitule,
  libelles: <ReponseFeedback, String>{
    ReponseFeedback.difficile: t.tc.parcours.feedback.cours.difficile,
    ReponseFeedback.bien: t.tc.parcours.feedback.cours.bien,
    ReponseFeedback.tresBien: t.tc.parcours.feedback.cours.tresBien,
  },
);

/// Un port qui pose [question] (nulle : seance hors echantillon) une seule
/// fois par seance, et garde les reponses recues.
class FauxFeedback implements PortFeedback {
  /// Cree le faux port.
  FauxFeedback({this.question, this.groupeId = 'g1'});

  /// La question rendue tant que la seance n'a pas de reponse.
  final QuestionFeedback? question;

  /// Le groupe auquel les reponses sont rattachees.
  final String groupeId;

  /// Les reponses recues, par seance.
  final Map<String, ReponseFeedback> reponses = <String, ReponseFeedback>{};

  @override
  Future<QuestionFeedback?> questionPour(String sessionId) async =>
      reponses.containsKey(sessionId) ? null : question;

  @override
  Future<void> soumettre({
    required String sessionId,
    required String questionId,
    required ReponseFeedback reponse,
  }) async {
    if (reponses.containsKey(sessionId)) {
      throw const EchecFeedback(MotifEchecFeedback.dejaDepose);
    }
    reponses[sessionId] = reponse;
  }

  @override
  Future<TendanceFeedback> tendance({required String groupeId}) async =>
      TendanceFeedback.depuis(
        groupeId: groupeId,
        reponses: groupeId == this.groupeId
            ? reponses.values.toList()
            : const <ReponseFeedback>[],
        seuilMinimum: 1,
      );
}
