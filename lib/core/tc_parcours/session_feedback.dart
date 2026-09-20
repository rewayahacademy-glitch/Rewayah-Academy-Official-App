import 'package:flutter/foundation.dart';

/// Ce qu'une personne repond au micro-feedback.
///
/// **Trois choix, un tap, termine** (spec section 12.1). Il n'y a pas de
/// quatrieme valeur, pas de note sur cinq, pas d'etoiles : une echelle plus fine
/// inviterait a comparer des enseignants entre eux, ce que la decision `D-17`
/// interdit explicitement.
enum ReponseFeedback {
  /// « Difficile ».
  difficile('difficile'),

  /// « Bien ».
  bien('bien'),

  /// « Tres bien ».
  tresBien('tres_bien');

  const ReponseFeedback(this.valeurSql);

  /// La valeur telle qu'elle est attendue en base.
  final String valeurSql;

  /// Lit une reponse depuis sa valeur SQL.
  ///
  /// Rend `null` sur valeur inconnue : **jamais de repli silencieux** sur
  /// « Bien », qui gonflerait une tendance avec des reponses illisibles.
  static ReponseFeedback? depuisSql(String? valeur) {
    for (final ReponseFeedback reponse in ReponseFeedback.values) {
      if (reponse.valeurSql == valeur) {
        return reponse;
      }
    }
    return null;
  }
}

/// Un micro-feedback depose sur une seance.
///
/// **Contrat produit par Agent H** (`TEACHING_CORE_CONTRACTS.md` section 15).
///
/// **Ce type ne porte aucune identite d'auteur, et c'est le point.** Ce n'est
/// pas un oubli qu'un futur lot comblerait : la spec interdit que l'enseignant
/// lise « tel eleve m'a mis telle note », et la seule facon de tenir cette
/// promesse est que la donnee qui remonte ne porte pas le nom. Un champ
/// `auteurId` ici, meme masque a l'ecran, serait une fuite a un `select` pres.
///
/// [questionId] est conserve parce que la rotation en depend : sans lui, on ne
/// peut ni savoir quelles questions ont deja ete posees, ni agreger deux
/// reponses qui ne parlent pas du meme sujet.
@immutable
class SessionFeedback {
  /// Cree un feedback.
  SessionFeedback({
    required this.id,
    required this.sessionId,
    required this.groupeId,
    required this.questionId,
    required this.reponse,
    required this.soumisLeUtc,
  }) : assert(soumisLeUtc.isUtc, 'tout instant de contrat est en UTC');

  /// L'identifiant du feedback.
  final String id;

  /// La seance notee.
  final String sessionId;

  /// Le groupe auquel la seance appartient.
  final String groupeId;

  /// La question posee, pour la rotation et pour l'agregat.
  final String questionId;

  /// La reponse, en un tap.
  final ReponseFeedback reponse;

  /// Quand le feedback a ete depose, en UTC.
  final DateTime soumisLeUtc;
}

/// La tendance agregee d'un groupe, telle que l'enseignant peut la lire.
///
/// **La seule lecture ouverte a l'enseignant.** Il n'existe volontairement
/// aucune methode qui rende la liste des feedbacks : la protection ne tient pas
/// par un ecran qui s'abstiendrait d'afficher, elle tient parce que la surface
/// n'expose rien d'autre que cet agregat.
///
/// Sous le seuil, [repartition] vaut `null` et **rien n'est montre**. Un
/// pourcentage calcule sur deux reponses n'est pas une tendance, c'est une
/// anecdote a laquelle une carriere ne doit pas se suspendre.
@immutable
class TendanceFeedback {
  /// Cree une tendance.
  const TendanceFeedback({
    required this.groupeId,
    required this.nombreEchantillons,
    required this.seuilMinimum,
    required this.visibleParEnseignant,
    this.repartition,
  }) : assert(
         visibleParEnseignant || repartition == null,
         'sous le seuil, aucune repartition ne sort',
       );

  /// Calcule la tendance d'un groupe a partir des reponses collectees.
  ///
  /// Fonction pure : aucun reseau, aucune horloge. Elle se teste sans base, et
  /// c'est ce qui permet de prouver que le seuil tient.
  factory TendanceFeedback.depuis({
    required String groupeId,
    required List<ReponseFeedback> reponses,
    required int seuilMinimum,
  }) {
    final int total = reponses.length;
    final bool visible = total >= seuilMinimum && total > 0;
    if (!visible) {
      return TendanceFeedback(
        groupeId: groupeId,
        nombreEchantillons: total,
        seuilMinimum: seuilMinimum,
        visibleParEnseignant: false,
      );
    }

    final Map<ReponseFeedback, int> comptes = <ReponseFeedback, int>{
      for (final ReponseFeedback valeur in ReponseFeedback.values) valeur: 0,
    };
    for (final ReponseFeedback reponse in reponses) {
      comptes[reponse] = comptes[reponse]! + 1;
    }

    return TendanceFeedback(
      groupeId: groupeId,
      nombreEchantillons: total,
      seuilMinimum: seuilMinimum,
      visibleParEnseignant: true,
      repartition: <ReponseFeedback, double>{
        for (final MapEntry<ReponseFeedback, int> ligne in comptes.entries)
          ligne.key: ligne.value / total,
      },
    );
  }

  /// Le groupe concerne.
  final String groupeId;

  /// Le nombre de reponses collectees.
  final int nombreEchantillons;

  /// En dessous, rien n'est montre a l'enseignant.
  final int seuilMinimum;

  /// Vrai quand le seuil est atteint.
  final bool visibleParEnseignant;

  /// La repartition, en parts de 1. `null` tant que le seuil n'est pas atteint.
  final Map<ReponseFeedback, double>? repartition;
}

/// Le seuil d'echantillons par defaut sous lequel aucune tendance ne sort.
///
/// **Cinq, et c'est une valeur de repli, pas une regle gravee.** Le seuil
/// appartient a `app_config`, le magasin cle/valeur deja employe pour les trois
/// seuils de presence : il doit se regler sans redeploiement. La demande est
/// ecrite dans `docs/teaching-core/TC_CONTRACT_REQUEST_H.md` section 3.
const int seuilTendanceParDefaut = 5;
