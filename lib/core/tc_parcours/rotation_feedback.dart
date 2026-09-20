import 'libelles_tc_parcours.dart';
import 'port_feedback.dart';
import 'session_feedback.dart';

/// Une seance sur quatre, par defaut.
///
/// **Valeur de repli, pas regle gravee.** L'echantillonnage est « configurable,
/// pas systematique » (spec section 12.1) : la cadence appartient a
/// `app_config`, comme les trois seuils de presence, pour se regler sans
/// redeploiement. La demande est ecrite dans
/// `docs/teaching-core/TC_CONTRACT_REQUEST_H.md` section 3.
const int cadenceFeedbackParDefaut = 4;

/// Les questions du micro-feedback, dans l'ordre de la rotation.
///
/// **Cinq volets, et c'est l'exigence la plus souvent oubliee de la spec** :
/// « il doit aussi etre dynamique et variable : afficher differentes questions
/// pour avoir differents volets. La meme question peut revenir apres mais apres
/// avoir affiche les autres d'abord. » Une question unique repetee apres chaque
/// seance echantillonnee ne mesurerait qu'une seule chose, et l'eleve cesserait
/// de la lire des la troisieme fois.
///
/// Chaque question porte **ses propres** trois libelles : « Trop rapide » n'est
/// pas « Difficile », meme si les deux se rangent du meme cote de l'echelle.
/// C'est ce qui distingue une rotation d'un decor.
abstract final class CatalogueFeedback {
  /// Les cinq questions, dans l'ordre ou elles sont posees.
  static const List<QuestionFeedback> questions = <QuestionFeedback>[
    QuestionFeedback(
      id: 'cours',
      intitule: LibellesParcours.feedbackCoursIntitule,
      libelles: <ReponseFeedback, String>{
        ReponseFeedback.difficile: LibellesParcours.feedbackCoursDifficile,
        ReponseFeedback.bien: LibellesParcours.feedbackCoursBien,
        ReponseFeedback.tresBien: LibellesParcours.feedbackCoursTresBien,
      },
    ),
    QuestionFeedback(
      id: 'comprehension',
      intitule: LibellesParcours.feedbackComprehensionIntitule,
      libelles: <ReponseFeedback, String>{
        ReponseFeedback.difficile:
            LibellesParcours.feedbackComprehensionDifficile,
        ReponseFeedback.bien: LibellesParcours.feedbackComprehensionBien,
        ReponseFeedback.tresBien:
            LibellesParcours.feedbackComprehensionTresBien,
      },
    ),
    QuestionFeedback(
      id: 'rythme',
      intitule: LibellesParcours.feedbackRythmeIntitule,
      libelles: <ReponseFeedback, String>{
        ReponseFeedback.difficile: LibellesParcours.feedbackRythmeDifficile,
        ReponseFeedback.bien: LibellesParcours.feedbackRythmeBien,
        ReponseFeedback.tresBien: LibellesParcours.feedbackRythmeTresBien,
      },
    ),
    QuestionFeedback(
      id: 'technique',
      intitule: LibellesParcours.feedbackTechniqueIntitule,
      libelles: <ReponseFeedback, String>{
        ReponseFeedback.difficile: LibellesParcours.feedbackTechniqueDifficile,
        ReponseFeedback.bien: LibellesParcours.feedbackTechniqueBien,
        ReponseFeedback.tresBien: LibellesParcours.feedbackTechniqueTresBien,
      },
    ),
    QuestionFeedback(
      id: 'confiance',
      intitule: LibellesParcours.feedbackConfianceIntitule,
      libelles: <ReponseFeedback, String>{
        ReponseFeedback.difficile: LibellesParcours.feedbackConfianceDifficile,
        ReponseFeedback.bien: LibellesParcours.feedbackConfianceBien,
        ReponseFeedback.tresBien: LibellesParcours.feedbackConfianceTresBien,
      },
    ),
  ];
}

/// La rotation des questions et la decision d'echantillonner.
///
/// **Deux fonctions pures, sans horloge ni hasard.** Le hasard aurait ete plus
/// simple a ecrire et impossible a prouver : il aurait pu poser deux fois la
/// meme question de suite, ce que la spec interdit, et aucun test n'aurait pu
/// le constater de facon stable.
abstract final class RotationFeedback {
  /// La prochaine question a poser, ou `null` si le catalogue est vide.
  ///
  /// [dejaPosees] est l'historique des identifiants deja poses, du plus ancien
  /// au plus recent, pour la personne et le groupe concernes.
  ///
  /// **Invariant tenu : une question ne revient qu'apres que toutes les autres
  /// ont ete posees.** Le cycle courant se deduit du nombre de questions deja
  /// posees ; la premiere question du catalogue qui n'y figure pas est la
  /// prochaine. Un identifiant devenu inconnu -- question retiree du catalogue
  /// entre deux versions -- est ignore : sans cela, une question supprimee
  /// gelerait la rotation sur place.
  static QuestionFeedback? prochaineQuestion({
    required List<QuestionFeedback> catalogue,
    required List<String> dejaPosees,
  }) {
    if (catalogue.isEmpty) {
      return null;
    }
    final Set<String> connues = <String>{
      for (final QuestionFeedback question in catalogue) question.id,
    };
    final List<String> historique = dejaPosees
        .where(connues.contains)
        .toList(growable: false);

    final int debutDuCycle =
        (historique.length ~/ catalogue.length) * catalogue.length;
    final Set<String> posesDansLeCycle = historique
        .sublist(debutDuCycle)
        .toSet();

    for (final QuestionFeedback question in catalogue) {
      if (!posesDansLeCycle.contains(question.id)) {
        return question;
      }
    }
    // Le cycle est complet : le suivant recommence au debut du catalogue.
    return catalogue.first;
  }

  /// Vrai quand cette seance est echantillonnee.
  ///
  /// [rangSeance] est le rang de la seance pour la personne concernee, a partir
  /// de 1. Une cadence nulle ou negative **desactive** le feedback : c'est la
  /// facon de l'eteindre sans supprimer le code, et une cadence de 1 le rendrait
  /// systematique, ce que la spec refuse.
  static bool estEchantillonnee({
    required int rangSeance,
    int cadence = cadenceFeedbackParDefaut,
  }) {
    if (cadence <= 0 || rangSeance <= 0) {
      return false;
    }
    return rangSeance % cadence == 0;
  }
}
