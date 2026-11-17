// Le service des questions de Praxis (PX-SUIVI) pour les tests : une liste
// fictive, une lecture qui peut echouer, une reponse qui peut etre refusee.
// `QuestionsPraxisVides` sert aux tests qui montent la section Praxis sans s'en
// occuper : aucune question, lecture qui reussit (sans lui, le bloc montrerait
// son etat d'erreur, la vraie source lit Supabase, absent sous test).

import 'package:rewayah_academy/core/agent/questions_praxis.dart';

/// Une question fictive. Aucune personne reelle.
QuestionPraxis questionPraxisFictive({
  String id = 'q1',
  String filId = 'f1',
  String question =
      'Le tuteur demande si le cours du lundi peut passer au mardi.',
  DateTime? poseeLe,
  String? reponse,
  DateTime? repondueLe,
  DateTime? utiliseeLe,
}) => QuestionPraxis(
  id: id,
  filId: filId,
  question: question,
  poseeLe: poseeLe ?? DateTime(2026, 11, 17, 9, 14),
  reponse: reponse,
  repondueLe:
      repondueLe ?? (reponse == null ? null : DateTime(2026, 11, 17, 10)),
  repondueParPrenom: reponse == null ? null : 'Direction',
  utiliseeLe: utiliseeLe,
);

/// Le double.
class FauxServiceQuestionsPraxis implements ServiceQuestionsPraxis {
  /// Cree le double.
  FauxServiceQuestionsPraxis({
    List<QuestionPraxis>? questions,
    this.erreurLecture,
    this.resultat = const ResultatQuestion(fait: true),
    this.erreurReponse,
  }) : _questions = questions ?? <QuestionPraxis>[];

  final List<QuestionPraxis> _questions;

  /// Si non nul, la lecture leve cette erreur.
  Exception? erreurLecture;

  /// Ce que `repondre` rend.
  ResultatQuestion resultat;

  /// Si non nul, `repondre` leve cette erreur (par exemple le refus de droit).
  Exception? erreurReponse;

  /// Les appels recus.
  final List<String> appels = <String>[];

  /// Les textes envoyes.
  final List<String> textes = <String>[];

  @override
  Future<List<QuestionPraxis>> lister() async {
    appels.add('lister');
    if (erreurLecture != null) throw erreurLecture!;
    return List<QuestionPraxis>.of(_questions);
  }

  @override
  Future<ResultatQuestion> repondre({
    required String id,
    required String texte,
  }) async {
    appels.add('repondre:$id');
    textes.add(texte);
    if (erreurReponse != null) throw erreurReponse!;
    if (resultat.fait) {
      final int i = _questions.indexWhere((QuestionPraxis q) => q.id == id);
      if (i >= 0) {
        _questions[i] = questionPraxisFictive(
          id: id,
          filId: _questions[i].filId,
          question: _questions[i].question,
          poseeLe: _questions[i].poseeLe,
          reponse: texte,
        );
      }
    }
    return resultat;
  }
}

/// Aucune question.
class QuestionsPraxisVides implements ServiceQuestionsPraxis {
  /// Cree le double.
  const QuestionsPraxisVides();

  @override
  Future<List<QuestionPraxis>> lister() async => const <QuestionPraxis>[];

  @override
  Future<ResultatQuestion> repondre({
    required String id,
    required String texte,
  }) async => const ResultatQuestion(fait: false, erreur: 'inconnue');
}
