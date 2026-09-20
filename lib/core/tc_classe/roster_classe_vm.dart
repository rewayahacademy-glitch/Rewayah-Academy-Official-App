import 'package:flutter/foundation.dart';

import 'teacher_student_projection.dart';

/// La file de recitation : qui recite, et qui vient apres.
///
/// **Changer d'eleve ne change ni la page, ni le focus, ni le stylet, ni le
/// support** (spec section 10.3). Cette classe ne porte donc **que** des
/// identifiants d'academie : elle ne peut pas, structurellement, deplacer le
/// support -- il n'y a rien dedans qui le designe.
///
/// Le professeur corrige en parlant a son micro. Rien ici n'ouvre un micro,
/// rien ici ne declenche une action a distance.
@immutable
class FileRecitation {
  /// Cree une file.
  const FileRecitation({this.actif, this.suivants = const <String>[]});

  /// La file vide : personne ne recite.
  static const FileRecitation vide = FileRecitation();

  /// L'eleve qui recite en ce moment, par son `academyId`. `null` = personne.
  final String? actif;

  /// Les suivants, dans l'ordre, par leur `academyId`.
  final List<String> suivants;

  /// Combien de suivants sont montres a l'ecran.
  ///
  /// **Une liste courte**, dit la spec : trois noms se lisent d'un coup d'oeil
  /// pendant qu'on ecoute reciter, six demandent de chercher.
  static const int suivantsMontres = 3;

  /// Les suivants effectivement affiches.
  List<String> get suivantsVisibles => suivants.length <= suivantsMontres
      ? suivants
      : suivants.sublist(0, suivantsMontres);

  /// Vrai quand quelqu'un recite.
  bool get enCours => actif != null;

  /// Passe la parole a [academyId], en le retirant de la file d'attente.
  ///
  /// L'eleve qui reciait n'est **pas** remis en fin de file : la file est une
  /// intention du professeur, pas un tourniquet automatique. Il la recompose
  /// quand il veut avec [avecFile].
  FileRecitation donnerLaParoleA(String academyId) => FileRecitation(
    actif: academyId,
    suivants: suivants.where((String id) => id != academyId).toList(),
  );

  /// Rend la file au repos : plus personne ne recite.
  FileRecitation get sansActif => FileRecitation(suivants: suivants);

  /// Remplace la file d'attente, sans toucher a qui recite.
  FileRecitation avecFile(List<String> nouveaux) => FileRecitation(
    actif: actif,
    suivants: nouveaux.where((String id) => id != actif).toList(),
  );

  @override
  bool operator ==(Object other) =>
      other is FileRecitation &&
      other.actif == actif &&
      listEquals(other.suivants, suivants);

  @override
  int get hashCode => Object.hash(actif, Object.hashAll(suivants));
}

/// Le roster de la classe, tel que l'enseignant le lit.
///
/// **Il ne porte que des [TeacherStudentProjection]** : c'est l'invariant de
/// confidentialite du lot, et il se verifie d'un coup d'oeil sur ce fichier --
/// aucun autre type d'eleve n'y entre.
///
/// **Il ne se construit jamais sur la seule liste LiveKit** (doublon 9.4 de la
/// cartographie) : qui n'est jamais arrive n'a aucune piste, et c'est justement
/// de lui que l'enseignant doit savoir quelque chose. La source est
/// `presence_seance_v`, croisee avec `teacher_roster_v`.
@immutable
class RosterClasseVM {
  /// Cree un roster.
  const RosterClasseVM({
    required this.eleves,
    required this.disponible,
    this.seuilMax,
    this.file = FileRecitation.vide,
  });

  /// Le roster **indisponible** : la lecture n'a rien rendu.
  ///
  /// Distinct d'un roster vide, et c'est l'invariant J3 : une liste vide dit
  /// « personne n'est inscrit », l'indisponibilite dit « je ne sais pas ».
  static const RosterClasseVM indisponible = RosterClasseVM(
    eleves: <TeacherStudentProjection>[],
    disponible: false,
  );

  /// Les eleves, dans l'ordre de lecture rendu par la source.
  final List<TeacherStudentProjection> eleves;

  /// Faux quand la lecture a echoue.
  final bool disponible;

  /// Le plafond du groupe, **lu du serveur**. `null` quand il n'est pas connu.
  ///
  /// **Jamais la valeur 5 en dur** : elle vient de `groupes.seuil_max`, qui
  /// vaut 5 pour les enfants et 6 pour les adultes, et qu'un administrateur
  /// peut changer. Un plafond ecrit dans Flutter serait un second plafond, et
  /// deux plafonds finissent par ne plus dire la meme chose.
  final int? seuilMax;

  /// La file de recitation courante.
  final FileRecitation file;

  /// Combien d'eleves sont effectivement en salle.
  int get presents =>
      eleves.where((TeacherStudentProjection e) => e.liveStatus.enSalle).length;

  /// Combien d'eleves sont attendus, c'est-a-dire inscrits a la seance.
  int get attendus => eleves.length;

  /// Le compteur compact du bouton de roster sur telephone, « 4/5 ».
  ///
  /// Le denominateur est le nombre d'**inscrits**, pas le plafond du groupe :
  /// un groupe de cinq places ou quatre eleves sont inscrits affiche « 4/4 »
  /// quand tout le monde est la, et non « 4/5 », qui se lirait comme une
  /// absence. Le plafond, lui, vit dans [seuilMax] et sert a l'administration.
  String get compteurCompact => '$presents/$attendus';

  /// Les eleves dont l'etat demande une reaction, en tete de lecture.
  List<TeacherStudentProjection> get aRegarder => eleves
      .where((TeacherStudentProjection e) => e.liveStatus.demandeUneReaction)
      .toList();

  /// La projection portant cet identifiant d'academie, ou `null`.
  TeacherStudentProjection? parAcademyId(String academyId) {
    for (final TeacherStudentProjection e in eleves) {
      if (e.academyId == academyId) {
        return e;
      }
    }
    return null;
  }

  /// L'eleve qui recite en ce moment, s'il est encore au roster.
  TeacherStudentProjection? get eleveActif {
    final String? id = file.actif;
    return id == null ? null : parAcademyId(id);
  }

  /// Le meme roster, avec une autre file de recitation.
  RosterClasseVM avecFile(FileRecitation nouvelle) => RosterClasseVM(
    eleves: eleves,
    disponible: disponible,
    seuilMax: seuilMax,
    file: nouvelle,
  );

  /// Le meme roster, avec le plafond du groupe **lu du serveur**.
  ///
  /// Il entre par ici et par nulle part ailleurs : aucun fichier de ce lot
  /// n'ecrit un plafond, ce qui rend l'invariant verifiable d'un `grep`.
  RosterClasseVM avecSeuil(int? plafond) => RosterClasseVM(
    eleves: eleves,
    disponible: disponible,
    seuilMax: plafond,
    file: file,
  );
}
