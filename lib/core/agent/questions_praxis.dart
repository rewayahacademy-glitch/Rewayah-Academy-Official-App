// PX-SUIVI : les questions que Praxis pose a l'equipe quand il ne sait pas, et
// la reponse de la direction (`direction_praxis_questions`,
// `direction_praxis_repondre`). Praxis revient ensuite vers la personne : c'est
// lui qui ecrit, jamais cet ecran.
//
// Une lecture qui echoue ne rend jamais « aucune question » : l'appelant voit
// l'erreur. La question est celle que Praxis a RESUMEE lui-meme (300 signes au
// plus) ; le texte de la personne n'est jamais ici.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Une question de Praxis a l'equipe.
@immutable
class QuestionPraxis {
  /// Cree la question.
  const QuestionPraxis({
    required this.id,
    required this.filId,
    required this.question,
    required this.poseeLe,
    this.reponse,
    this.repondueLe,
    this.repondueParPrenom,
    this.utiliseeLe,
  });

  /// Lit une ligne rendue par le serveur, ou `null` quand elle est illisible.
  static QuestionPraxis? depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return null;
    final Object? id = brut['id'];
    final Object? fil = brut['filId'];
    final Object? question = brut['question'];
    final DateTime? posee = brut['poseeLe'] is String
        ? DateTime.tryParse(brut['poseeLe'] as String)?.toLocal()
        : null;
    if (id is! String ||
        fil is! String ||
        question is! String ||
        posee == null) {
      return null;
    }
    return QuestionPraxis(
      id: id,
      filId: fil,
      question: question,
      poseeLe: posee,
      reponse: brut['reponse'] is String ? brut['reponse'] as String : null,
      repondueLe: brut['repondueLe'] is String
          ? DateTime.tryParse(brut['repondueLe'] as String)?.toLocal()
          : null,
      repondueParPrenom: brut['repondueParPrenom'] is String
          ? brut['repondueParPrenom'] as String
          : null,
      utiliseeLe: brut['utiliseeLe'] is String
          ? DateTime.tryParse(brut['utiliseeLe'] as String)?.toLocal()
          : null,
    );
  }

  /// L'identifiant de la question.
  final String id;

  /// La conversation de la personne (le lien « Ouvrir la conversation »).
  final String filId;

  /// La question, resumee par Praxis (300 signes au plus).
  final String question;

  /// Quand Praxis l'a posee.
  final DateTime poseeLe;

  /// La reponse de la direction, ou `null`.
  final String? reponse;

  /// Quand la direction a repondu.
  final DateTime? repondueLe;

  /// Le prenom de la personne de la direction qui a repondu.
  final String? repondueParPrenom;

  /// Quand Praxis a transmis la reponse a la personne, ou `null`.
  final DateTime? utiliseeLe;

  /// La direction n'a pas encore repondu.
  bool get ouverte => repondueLe == null;

  /// Praxis est revenu vers la personne.
  bool get transmise => utiliseeLe != null;
}

/// Ce que `repondre` rend : fait, ou la cause du refus (`deja_repondue`,
/// `inconnue`).
@immutable
class ResultatQuestion {
  /// Cree le resultat.
  const ResultatQuestion({required this.fait, this.erreur});

  /// Vrai si la reponse est enregistree.
  final bool fait;

  /// La cause du refus, ou `null`.
  final String? erreur;
}

/// L'acces de la direction aux questions de Praxis.
abstract interface class ServiceQuestionsPraxis {
  /// Les questions, les ouvertes d'abord (les plus anciennes en tete).
  Future<List<QuestionPraxis>> lister();

  /// Repond a une question (double verification exigee par la base). Une seule
  /// reponse par question.
  Future<ResultatQuestion> repondre({
    required String id,
    required String texte,
  });
}

/// L'implementation Supabase.
class ServiceQuestionsPraxisSupabase implements ServiceQuestionsPraxis {
  /// Cree le service.
  ServiceQuestionsPraxisSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<QuestionPraxis>> lister() async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_questions',
      params: <String, dynamic>{'p_limite': 100},
    );
    if (rendu is! Map<String, dynamic> || rendu['questions'] is! List) {
      throw const FormatException('questions illisibles');
    }
    return <QuestionPraxis>[
      for (final Object? l in rendu['questions'] as List)
        ?QuestionPraxis.depuisJson(l),
    ];
  }

  @override
  Future<ResultatQuestion> repondre({
    required String id,
    required String texte,
  }) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_repondre',
      params: <String, dynamic>{'p_id': id, 'p_texte': texte},
    );
    if (rendu is! Map<String, dynamic>) {
      return const ResultatQuestion(fait: false, erreur: 'illisible');
    }
    final Object? erreur = rendu['erreur'];
    if (erreur is String) return ResultatQuestion(fait: false, erreur: erreur);
    return ResultatQuestion(fait: rendu['ok'] == true);
  }
}

/// Le service des questions.
final Provider<ServiceQuestionsPraxis> serviceQuestionsPraxisProvider =
    Provider<ServiceQuestionsPraxis>(
      (Ref ref) => ServiceQuestionsPraxisSupabase(Supabase.instance.client),
    );

/// Les questions. Une lecture qui echoue reste une ERREUR (jamais une liste
/// vide) ; pas de nouvel essai automatique.
final FutureProvider<List<QuestionPraxis>> questionsPraxisProvider =
    FutureProvider.autoDispose<List<QuestionPraxis>>(
      (Ref ref) => ref.watch(serviceQuestionsPraxisProvider).lister(),
      retry: (int retryCount, Object error) => null,
    );
