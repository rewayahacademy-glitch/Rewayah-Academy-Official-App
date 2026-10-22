// Le port du candidat dans `/attente` : `PortMaCandidature`
// (`docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, section 3).
//
// **L'etat n'est pas une lecture de ce port.** Il vient de `etat_dossier()`
// etendu, lu par `ServiceDossier` (une seule source pour `/attente`). Ce port
// ne porte que ce qui n'est pas un etat : les conditions de remuneration, le
// questionnaire, le brouillon, l'envoi des reponses et le retrait.
//
// Les refus metier sont des exceptions typees ([ErreurCandidature]) : l'ecran
// dit chacun en mots, avec quoi faire (K-59), jamais un code. Un port dont le
// lot serveur manque leve `CapaciteIndisponible('CAND-BR-nn')` ; l'ecran le
// dit sans « Reessayer ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:uuid/uuid.dart';

import '../capacites/capacite_indisponible.dart';
import 'modeles_candidature.dart';

/// Les refus metier du port du candidat.
sealed class ErreurCandidature implements Exception {
  const ErreurCandidature();
}

/// Le questionnaire a change depuis l'ouverture de la page : [versionCourante]
/// est la version a relire.
final class QuestionnairePerime extends ErreurCandidature {
  /// Cree l'erreur.
  const QuestionnairePerime(this.versionCourante);

  /// La version courante du questionnaire.
  final String? versionCourante;
}

/// Des champs requis n'ont pas de reponse : [champs] les nomme.
final class ReponsesIncompletes extends ErreurCandidature {
  /// Cree l'erreur.
  const ReponsesIncompletes(this.champs);

  /// Les codes des champs sans reponse.
  final List<String> champs;
}

/// Des reponses ne sont pas dans la liste du champ : [champs] les nomme.
final class ReponsesInvalides extends ErreurCandidature {
  /// Cree l'erreur.
  const ReponsesInvalides(this.champs);

  /// Les codes des champs refuses.
  final List<String> champs;
}

/// La case de remuneration n'est pas cochee.
final class AccordRemunerationRequis extends ErreurCandidature {
  /// Cree l'erreur.
  const AccordRemunerationRequis();
}

/// Les conditions de remuneration ont change depuis leur lecture.
final class ConditionsPerimees extends ErreurCandidature {
  /// Cree l'erreur.
  const ConditionsPerimees(this.versionCourante);

  /// La version courante des conditions.
  final String? versionCourante;
}

/// Le cadre religieux et pedagogique n'est pas accepte a sa version requise.
final class EngagementNonAccepte extends ErreurCandidature {
  /// Cree l'erreur.
  const EngagementNonAccepte({this.versionRequise, this.publie = false});

  /// La version requise, nulle tant qu'elle n'est pas publiee.
  final String? versionRequise;

  /// Vrai quand une version est publiee (donc a accepter).
  final bool publie;
}

/// La candidature a change depuis l'ouverture de la page (version perimee).
final class ConflitCandidature extends ErreurCandidature {
  /// Cree l'erreur.
  const ConflitCandidature(this.versionCourante);

  /// La version courante de la candidature.
  final int? versionCourante;
}

/// Le brouillon a change ailleurs (autre appareil, autre onglet).
final class ConflitBrouillon extends ErreurCandidature {
  /// Cree l'erreur.
  const ConflitBrouillon(this.versionCourante);

  /// La version courante du brouillon.
  final int? versionCourante;
}

/// Le geste n'est pas permis depuis l'etat courant de la candidature.
final class TransitionInterdite extends ErreurCandidature {
  /// Cree l'erreur.
  const TransitionInterdite({this.enPause = false});

  /// Vrai quand c'est la pause qui interdit le geste.
  final bool enPause;
}

/// Aucune candidature pour ce compte.
final class CandidatureAbsente extends ErreurCandidature {
  /// Cree l'erreur.
  const CandidatureAbsente();
}

/// Aucune reponse : l'appareil est hors ligne, ou le serveur n'a pas repondu.
/// Ce qui a ete envoye est **non confirme** (D5).
final class HorsLigneCandidature extends ErreurCandidature {
  /// Cree l'erreur.
  const HorsLigneCandidature();
}

/// Le port du candidat.
abstract interface class PortMaCandidature {
  /// Les conditions de remuneration, lues dans la politique de paie en base.
  /// `CapaciteIndisponible('CAND-BR-12')` quand le serveur n'en publie pas.
  Future<ConditionsRemuneration> conditionsRemuneration();

  /// Le questionnaire courant, avec le dernier document du candidat.
  /// `CapaciteIndisponible('CAND-BR-10')` quand le serveur n'en publie pas.
  Future<Questionnaire> questionnaire();

  /// Les moyens de versement que Rewayah a confirmes pour [paysVersement]
  /// (code ISO) : le virement bancaire, et les operateurs de monnaie mobile.
  /// [MoyensConfirmes.aucun] dit : aucun moyen confirme dans ce pays.
  Future<MoyensConfirmes> moyensConfirmes(String paysVersement);

  /// Enregistre un brouillon : des reponses partielles, jamais une valeur hors
  /// liste. [versionBrouillon] est la version du brouillon ouvert (0 sans
  /// brouillon). Une cle neuve a chaque enregistrement.
  Future<ResultatBrouillon> enregistrerBrouillon({
    required String versionQuestionnaire,
    required Map<String, Object?> reponses,
    required int versionBrouillon,
    required String cleIdempotence,
  });

  /// Envoie la candidature (transition 6). Rend le bloc `candidature` relu au
  /// serveur : le succes ne se dit qu'apres cette reponse.
  Future<CandidatureDossier> envoyerReponses({
    required String versionQuestionnaire,
    required Map<String, Object?> reponses,
    required bool accordRemuneration,
    required String versionConditions,
    required int versionAttendue,
    required String cleIdempotence,
  });

  /// Retire la candidature (transition 17, CAND-03). Rend le bloc `candidature`
  /// relu au serveur.
  Future<CandidatureDossier> retirer({
    required int versionAttendue,
    required String cleIdempotence,
  });
}

/// L'identifiant de la dependance serveur du questionnaire et de l'envoi
/// (`CAND-BR-10`), pour la trace et les tests : jamais affiche.
const String dependanceCandidature = 'CAND-BR-10';

/// L'identifiant de la dependance serveur des conditions de remuneration
/// (`CAND-BR-12`), pour la trace et les tests : jamais affiche.
const String dependanceConditionsRemuneration = 'CAND-BR-12';

/// Le port du candidat : absent avant le branchement serveur.
final Provider<PortMaCandidature?> portMaCandidatureProvider =
    Provider<PortMaCandidature?>((Ref _) => null);

/// Le questionnaire. Sans port : [CapaciteIndisponible].
final FutureProvider<Questionnaire> questionnaireCandidatProvider =
    FutureProvider<Questionnaire>((Ref ref) {
      final PortMaCandidature? port = ref.watch(portMaCandidatureProvider);
      if (port == null) {
        return Future<Questionnaire>.error(
          const CapaciteIndisponible(dependanceCandidature),
        );
      }
      return port.questionnaire();
    }, retry: (int _, Object _) => null);

/// Les conditions de remuneration. Sans port : [CapaciteIndisponible].
final FutureProvider<ConditionsRemuneration>
conditionsRemunerationCandidatProvider = FutureProvider<ConditionsRemuneration>(
  (Ref ref) {
    final PortMaCandidature? port = ref.watch(portMaCandidatureProvider);
    if (port == null) {
      return Future<ConditionsRemuneration>.error(
        const CapaciteIndisponible(dependanceConditionsRemuneration),
      );
    }
    return port.conditionsRemuneration();
  },
  retry: (int _, Object _) => null,
);

/// Les moyens de versement confirmes d'un pays de versement.
final FutureProviderFamily<MoyensConfirmes, String> moyensConfirmesProvider =
    FutureProvider.family<MoyensConfirmes, String>((Ref ref, String pays) {
      final PortMaCandidature? port = ref.watch(portMaCandidatureProvider);
      if (port == null) {
        return Future<MoyensConfirmes>.error(
          const CapaciteIndisponible(dependanceCandidature),
        );
      }
      return port.moyensConfirmes(pays);
    }, retry: (int _, Object _) => null);

/// Une cle d'idempotence neuve : une par geste (8 a 200 signes cote serveur).
/// La meme cle rejoue le meme geste sans l'ecrire deux fois.
String nouvelleCleIdempotence() => 'cand-${const Uuid().v4()}';
