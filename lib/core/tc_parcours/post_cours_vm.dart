import 'package:flutter/foundation.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import 'ports_externes/learning_assignment.dart';
import 'ports_externes/teacher_student_projection.dart';

/// Le post-cours de l'enseignant (`TEACHING_CORE_CONTRACTS.md` section 16).
///
/// **Contrat produit par Agent H**, consomme par H et Q.
///
/// **Tout y est prerempli, et rien n'y est redemande.** La duree vient de la
/// base, la presence vient de la base, les plages travaillees viennent de
/// l'etat partage de la seance, la position de reprise vient de la meme source,
/// et le travail propose se deduit des plages. Le seul champ que l'enseignant
/// peut remplir est [notesExceptions], et il est **facultatif** : la cible des
/// 45 secondes n'est atteignable que si le chemin nominal ne demande aucune
/// frappe.
///
/// **Ce VM ne remplace pas le cahier de transmission `ENS-04`**, qui existe,
/// qui est teste et qui porte deja la presence, la duree et les exceptions par
/// eleve. Il le **complete** avec ce que le cahier ne sait pas encore faire :
/// proposer une position de reprise et un travail a venir. Agent Z branche les
/// deux surfaces l'une sous l'autre.
@immutable
class PostCoursVM {
  /// Cree un post-cours.
  const PostCoursVM({
    required this.sessionId,
    required this.dureeReelle,
    required this.participants,
    required this.rangesTravailles,
    required this.travailPropose,
    this.positionDeRepriseProposee,
    this.notesExceptions,
  });

  /// La seance concernee.
  final String sessionId;

  /// La duree **calculee par la base**, jamais recalculee ici.
  ///
  /// Le depot sait deja deduire quatre durees differentes pour une meme seance
  /// (`fin - debut`, `entre_le -> derniere_trace_le`, `minutesInterruption`,
  /// `started_at -> ended_at`). En calculer une cinquieme donnerait deux
  /// chiffres pour le meme cours, et personne ne saurait lequel croire.
  final Duration dureeReelle;

  /// Les eleves de la seance, projetes sans aucune donnee privee famille.
  ///
  /// Vide quand le serveur ne projette pas encore le roster pour l'enseignant :
  /// une liste vide dit « je ne sais pas montrer », elle n'affirme pas que la
  /// seance etait deserte.
  final List<TeacherStudentProjection> participants;

  /// La position ou reprendre, **proposee**. `null` quand elle est inconnue.
  ///
  /// Proposee, pas decidee : c'est une suggestion que l'enseignant garde ou
  /// remplace, jamais une position ecrite d'autorite.
  final ContentPosition? positionDeRepriseProposee;

  /// Les plages reellement travaillees pendant la seance.
  final List<ContentRange> rangesTravailles;

  /// Le travail propose pour la suite, **pas encore pose**.
  ///
  /// Il ne devient reel qu'a l'enregistrement : tant que l'enseignant n'a pas
  /// valide, aucun eleve ne voit ces lignes dans son Espace Groupe.
  final List<LearningAssignment> travailPropose;

  /// Ce que l'enseignant ajoute, **pour les exceptions seulement**.
  ///
  /// `null` est le cas nominal. Aucun rapport narratif n'est demande : un
  /// enseignant a qui l'on reclame un texte apres chaque cours cesse d'ecrire
  /// des textes utiles au troisieme cours.
  final String? notesExceptions;

  /// Les seuls eleves qui demandent un regard.
  ///
  /// La regle vit dans `EtatPresenceProjete.demandeUneReaction`, chez Agent E :
  /// le lot H la lit, il n'en pose pas une seconde. Une presence **inconnue**
  /// en fait partie -- ne pas savoir demande un regard, exactement comme une
  /// absence (invariant J3).
  List<TeacherStudentProjection> get exceptions => participants
      .where((TeacherStudentProjection p) => p.liveStatus.demandeUneReaction)
      .toList(growable: false);

  /// Les eleves dans l'ordre de l'ecran : les exceptions d'abord.
  List<TeacherStudentProjection> get participantsOrdonnes =>
      <TeacherStudentProjection>[
        ...exceptions,
        ...participants.where(
          (TeacherStudentProjection p) => !p.liveStatus.demandeUneReaction,
        ),
      ];

  /// Vrai quand rien ne demande l'attention de l'enseignant.
  ///
  /// C'est le chemin d'un seul geste. Faux quand la liste est vide : on ne
  /// declare pas « tout va bien » sur une seance dont on ne sait rien.
  bool get toutEstNominal => participants.isNotEmpty && exceptions.isEmpty;

  /// Le meme post-cours, avec la note d'exception de l'enseignant.
  PostCoursVM avecNotes(String? notes) {
    final String? propre = notes?.trim();
    return PostCoursVM(
      sessionId: sessionId,
      dureeReelle: dureeReelle,
      participants: participants,
      positionDeRepriseProposee: positionDeRepriseProposee,
      rangesTravailles: rangesTravailles,
      travailPropose: travailPropose,
      notesExceptions: propre == null || propre.isEmpty ? null : propre,
    );
  }

  /// Le meme post-cours, avec un autre travail propose.
  ///
  /// C'est ainsi que l'enseignant retire une proposition qui ne lui convient
  /// pas : il ne la modifie pas, il compose la liste qu'il valide.
  PostCoursVM avecTravail(List<LearningAssignment> travail) => PostCoursVM(
    sessionId: sessionId,
    dureeReelle: dureeReelle,
    participants: participants,
    positionDeRepriseProposee: positionDeRepriseProposee,
    rangesTravailles: rangesTravailles,
    travailPropose: travail,
    notesExceptions: notesExceptions,
  );
}
