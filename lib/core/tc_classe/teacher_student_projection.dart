import 'package:flutter/foundation.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_outils/learning_assignment.dart';

/// L'etat d'un eleve dans la seance, projete pour l'enseignant.
///
/// **Neuf valeurs, dont [inconnu], et [inconnu] n'est pas « absent ».** C'est
/// l'invariant J3 du depot, deja tenu par `service_presence.dart` : une lecture
/// qui echoue rend `inconnu`. « Absente » est un fait qui compte pour le suivi
/// et la facturation ; ne pas savoir n'en est pas un.
///
/// Cet enum est une **projection** des quatorze etats de `presence_state`, pas
/// un quinzieme vocabulaire : la conversion vit dans `roster_enseignant.dart` et
/// nulle part ailleurs. L'invariant J4 interdit d'ajouter un etat a la base ;
/// projeter n'en ajoute aucun.
enum EtatPresenceProjete {
  /// L'etat live n'est pas derivable. **Jamais « absent ».**
  ///
  /// Trois cas s'y rangent, et ils ont en commun de ne rien dire de la presence
  /// a cet instant : la lecture a echoue, la base a rendu une valeur que cette
  /// version ne connait pas, ou l'etat lu est un etat de **consolidation**
  /// posterieur a la seance (`confirmation_en_attente`, `corrigee_manuel`,
  /// `finalisee`). Le dernier cas est le plus subtil : ces trois etats
  /// qualifient une decision administrative, pas une place dans la salle.
  inconnu('inconnu'),

  /// Inscrit, la fenetre est ouverte, personne n'est encore entre.
  attendu('attendu'),

  /// Un jeton vient d'etre emis, la connexion est en cours.
  enConnexion('en_connexion'),

  /// Entre, et toujours la.
  present('present'),

  /// Entre apres l'heure, au-dela du seuil configure.
  enRetard('en_retard'),

  /// Le lien a lache sans geste volontaire.
  deconnecte('deconnecte'),

  /// Le lien a lache, la fenetre de retour court encore.
  enReconnexion('en_reconnexion'),

  /// Parti volontairement.
  sorti('sorti'),

  /// La seance est finie et cette personne n'est jamais entree.
  absent('absent');

  const EtatPresenceProjete(this.valeurSql);

  /// La valeur de projection. Elle n'est **pas** celle de `presence_state` :
  /// la correspondance est explicite dans `roster_enseignant.dart`.
  final String valeurSql;

  /// Vrai quand l'enseignant a quelque chose a faire de cet etat.
  ///
  /// C'est ce qui decide si la ligne de roster porte un ton d'alerte -- et la
  /// pastille porte **toujours** son mot (invariant J7).
  bool get demandeUneReaction => switch (this) {
    EtatPresenceProjete.inconnu ||
    EtatPresenceProjete.absent ||
    EtatPresenceProjete.enRetard ||
    EtatPresenceProjete.deconnecte ||
    EtatPresenceProjete.enReconnexion => true,
    EtatPresenceProjete.attendu ||
    EtatPresenceProjete.enConnexion ||
    EtatPresenceProjete.present ||
    EtatPresenceProjete.sorti => false,
  };

  /// Vrai quand la personne est effectivement dans la salle en ce moment.
  bool get enSalle =>
      this == EtatPresenceProjete.present || this == EtatPresenceProjete.enRetard;
}

/// Ce que la seance precedente a laisse.
@immutable
class ResumeSeance {
  /// Cree un resume de seance.
  ResumeSeance({required this.dateUtc, this.positionAtteinte, this.pointARevoir})
    : assert(dateUtc.isUtc, 'tout instant de contrat est en UTC');

  /// La date de la seance concernee, en UTC.
  final DateTime dateUtc;

  /// Ou la lecture s'est arretee.
  final ContentPosition? positionAtteinte;

  /// Le point a reprendre, redige court, par exemple « Confusion sad / sin ».
  final String? pointARevoir;
}

/// L'assiduite recente, telle qu'elle se lit : « 8 / 9 cours ».
///
/// **Le sort du cours prime sur l'etat de la personne** : un cours annule ou non
/// tenu n'entre pas dans [total], sans quoi l'eleve porterait l'absence de son
/// professeur. La regle est deja tranchee dans le depot par `SortDuCours`
/// (`lib/features/suivi_foyer/vue_suivi_foyer.dart`) : on la reprend, on ne la
/// rejoue pas.
@immutable
class AssiduiteRecente {
  /// Cree une assiduite.
  const AssiduiteRecente({required this.presences, required this.total})
    : assert(presences >= 0, 'un compte de presences n est jamais negatif'),
      assert(presences <= total, 'on ne peut pas etre present plus que prevu');

  /// Le nombre de cours ou l'eleve etait la.
  final int presences;

  /// Le nombre de cours **reellement tenus** sur la periode.
  final int total;
}

/// La vue pedagogique restreinte d'un eleve, pour l'enseignant.
///
/// **Le contrat le plus important du chantier** : connaissance pedagogique
/// forte, connaissance privee minimale (spec section 10).
///
/// Ce type ne porte, a aucun niveau d'imbrication : ni telephone, ni email, ni
/// adresse, ni geolocalisation, ni identite des tuteurs, ni coordonnees de
/// famille, ni paiement, ni identifiant prive d'appareil, **ni nom de famille,
/// pas meme une initiale** (decision D-08, ADR-008).
///
/// **Et cette protection ne tient pas par ce fichier.** Elle tient parce que la
/// vue serveur ne delivre pas ces colonnes : `teacher_roster_v` a retire
/// `last_name` en 0005, et `profiles` n'accorde aucune policy `select` a
/// l'enseignant. Une projection Dart qui reconstituerait une donnee par jointure
/// serait un contournement, pas une commodite. Le present type en est la
/// **preuve lisible**, pas la barriere.
@immutable
class TeacherStudentProjection {
  /// Cree une projection.
  const TeacherStudentProjection({
    required this.firstName,
    required this.academyId,
    required this.liveStatus,
    required this.interfaceGuidee,
    this.level,
    this.curriculumPath,
    this.currentUnit,
    this.activeGoals = const <String>[],
    this.lastLesson,
    this.resumePoints,
    this.recentAttendance,
    this.currentAssignments = const <LearningAssignment>[],
    this.authorizedPedagogicalNotes = const <String>[],
  });

  /// Le prenom. **Seul, et jamais accompagne d'une initiale de nom.**
  final String firstName;

  /// L'identifiant d'academie, `profiles.immutable_id`, par exemple `RA-AB0012`.
  ///
  /// **C'est lui qui desambiguise deux homonymes**, et non un nom de famille :
  /// c'est exactement ce que fait deja `journee_page.dart`.
  final String academyId;

  /// Le niveau humain, jamais un code technique. `null` quand il est inconnu.
  final String? level;

  /// Le parcours dans le programme. `null` tant que le serveur ne le projette
  /// pas pour l'enseignant.
  final String? curriculumPath;

  /// L'unite en cours. Meme reserve que [curriculumPath].
  final String? currentUnit;

  /// Les objectifs actifs, courts. Vide quand il n'y en a pas de connu.
  final List<String> activeGoals;

  /// Ce que la derniere seance a laisse.
  final ResumeSeance? lastLesson;

  /// Ou reprendre la lecture.
  final ContentPosition? resumePoints;

  /// L'assiduite recente. `null` = indisponible, **jamais zero par defaut**.
  final AssiduiteRecente? recentAttendance;

  /// Le travail en cours, pose par le Teaching Dock.
  final List<LearningAssignment> currentAssignments;

  /// Les notes pedagogiques que cet enseignant a le droit de lire.
  ///
  /// **Autorisees**, donc filtrees en base : la liste est vide quand rien n'est
  /// ouvert a l'appelant, et cette vacuite n'est pas une erreur.
  final List<String> authorizedPedagogicalNotes;

  /// L'etat de presence projete. [EtatPresenceProjete.inconnu] si la lecture
  /// echoue.
  final EtatPresenceProjete liveStatus;

  /// Miroir de `student_profiles.interface_mode == 'child'`.
  ///
  /// **Le nom visible est « Interface guidee »** (decision D-07). Le champ est
  /// un booleen de contrat, pas une colonne nouvelle : la valeur SQL reste
  /// `'child'`, et aucune UI n'ecrit « mode enfant ».
  final bool interfaceGuidee;

  /// Vrai quand cette projection porte au moins un fait pedagogique a montrer.
  ///
  /// Sert a distinguer une fiche **vide parce que le serveur ne projette pas
  /// encore le domaine Pedagogie** d'une fiche pleine : le premier cas merite
  /// un etat explicite, pas un blanc.
  bool get aDuContenuPedagogique =>
      level != null ||
      curriculumPath != null ||
      currentUnit != null ||
      activeGoals.isNotEmpty ||
      lastLesson != null ||
      resumePoints != null ||
      recentAttendance != null ||
      currentAssignments.isNotEmpty ||
      authorizedPedagogicalNotes.isNotEmpty;
}
