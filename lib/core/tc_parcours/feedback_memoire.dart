import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'port_feedback.dart';
import 'rotation_feedback.dart';
import 'session_feedback.dart';

/// Ce que le serveur devra dire d'une seance pour decider d'un feedback.
///
/// Trois faits, et aucun n'est calculable cote client : a quel groupe la seance
/// appartient, quel est son **rang** pour la personne qui repond, et si elle a
/// deja repondu. La demande SQL correspondante est en section 3 de
/// `docs/teaching-core/TC_CONTRACT_REQUEST_H.md`.
@immutable
class ContexteSeanceFeedback {
  /// Cree un contexte de seance.
  const ContexteSeanceFeedback({
    required this.groupeId,
    required this.rangSeance,
  });

  /// Le groupe dont la seance est la reunion.
  final String groupeId;

  /// Le rang de la seance pour la personne, a partir de 1.
  final int rangSeance;
}

/// Le micro-feedback, en memoire.
///
/// **DOUBLE LOCAL ASSUME.** Aucune table `session_feedback` n'existe en base, et
/// aucun mecanisme d'echantillonnage n'existe cote serveur : la demande SQL est
/// ecrite dans `docs/teaching-core/TC_CONTRACT_REQUEST_H.md` section 3. Ce
/// double rend la regle testable aujourd'hui et servira de reference au jour ou
/// l'implementation Supabase sera ecrite.
///
/// **Il ne stocke aucune identite d'auteur**, exactement comme la table le
/// devra : ce n'est pas une simplification de double, c'est la regle elle-meme
/// (decision `D-17`).
class FeedbackMemoire implements PortFeedback {
  /// Cree un depot en memoire.
  ///
  /// [seances] tient lieu de la lecture serveur : le rang d'une seance et son
  /// groupe ne se devinent pas cote client.
  FeedbackMemoire({
    required Map<String, ContexteSeanceFeedback> seances,
    int? cadence,
    int? seuilTendance,
    List<QuestionFeedback>? catalogue,
    Uuid? generateur,
    DateTime Function()? maintenant,
  }) : _seances = Map<String, ContexteSeanceFeedback>.of(seances),
       _cadence = cadence ?? cadenceFeedbackParDefaut,
       _seuilTendance = seuilTendance ?? seuilTendanceParDefaut,
       _catalogue = catalogue ?? CatalogueFeedback.questions,
       _generateur = generateur ?? const Uuid(),
       _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final Map<String, ContexteSeanceFeedback> _seances;
  final int _cadence;
  final int _seuilTendance;
  final List<QuestionFeedback> _catalogue;
  final Uuid _generateur;
  final DateTime Function() _maintenant;

  /// Les reponses deposees, sans auteur.
  final List<SessionFeedback> _reponses = <SessionFeedback>[];

  /// L'historique des questions posees par groupe, du plus ancien au plus
  /// recent. C'est lui que la rotation lit.
  final Map<String, List<String>> _historique = <String, List<String>>{};

  @override
  Future<QuestionFeedback?> questionPour(String sessionId) async {
    final ContexteSeanceFeedback? contexte = _seances[sessionId];
    if (contexte == null) {
      // Seance inconnue : on ne demande rien. Une question posee sur une seance
      // qu'on ne sait pas situer ne serait rattachable a aucun groupe.
      return null;
    }
    if (_dejaRepondu(sessionId)) {
      return null;
    }
    if (!RotationFeedback.estEchantillonnee(
      rangSeance: contexte.rangSeance,
      cadence: _cadence,
    )) {
      return null;
    }
    return RotationFeedback.prochaineQuestion(
      catalogue: _catalogue,
      dejaPosees:
          _historique[contexte.groupeId] ?? const <String>[],
    );
  }

  @override
  Future<void> soumettre({
    required String sessionId,
    required String questionId,
    required ReponseFeedback reponse,
  }) async {
    final ContexteSeanceFeedback? contexte = _seances[sessionId];
    if (contexte == null) {
      throw const EchecFeedback(MotifEchecFeedback.ecriture);
    }
    if (_dejaRepondu(sessionId)) {
      // Un second depot est un double tap ou un rejeu, jamais une faute de
      // l'utilisateur : l'appelant le traite en silence.
      throw const EchecFeedback(MotifEchecFeedback.dejaDepose);
    }

    _reponses.add(
      SessionFeedback(
        id: _generateur.v4(),
        sessionId: sessionId,
        groupeId: contexte.groupeId,
        questionId: questionId,
        reponse: reponse,
        soumisLeUtc: _maintenant(),
      ),
    );
    // La rotation n'avance qu'a la reponse : une carte ignoree ne doit pas
    // consommer une question, sans quoi un eleve qui ne repond jamais ferait
    // defiler le catalogue pour tout son groupe.
    (_historique[contexte.groupeId] ??= <String>[]).add(questionId);
  }

  @override
  Future<TendanceFeedback> tendance({required String groupeId}) async =>
      TendanceFeedback.depuis(
        groupeId: groupeId,
        reponses: <ReponseFeedback>[
          for (final SessionFeedback f in _reponses)
            if (f.groupeId == groupeId) f.reponse,
        ],
        seuilMinimum: _seuilTendance,
      );

  bool _dejaRepondu(String sessionId) =>
      _reponses.any((SessionFeedback f) => f.sessionId == sessionId);
}
