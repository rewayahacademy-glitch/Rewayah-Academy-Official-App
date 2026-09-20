import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/roster_enseignant.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/tc_horloge/port_horloge_seance.dart';
import '../../core/widgets/skeleton.dart';
import '../tc_classe_live/roster_classe.dart';

/// Le contenu du slot roster de l'Espace Groupe (§5.5 du plan d'integration
/// Teaching Core), branche sur `PortRosterEnseignant` (Agent E).
///
/// **Un seul des deux chemins du port est reellement branchable aujourd'hui.**
/// `rosterDeGroupe` (hors seance) leve systematiquement
/// `MotifEchecRoster.projectionAbsente` : `groupe_membres` ne porte que
/// `student_id`, et la RLS ferme la jointure vers `profiles` a l'enseignant
/// (la variante enseignant de `teacher_roster_v` est demandee, pas livree,
/// section 1 de `TC_CONTRACT_REQUEST_E.md`). Reconstituer la jointure ici
/// contournerait la RLS, ce que ce depot ne fait jamais.
///
/// Ce widget branche donc `rosterDeSeance` quand une seance est active, et
/// rend l'etat **indisponible** -- pas une liste vide -- hors seance : c'est
/// l'invariant J3, et c'est honnete plutot que d'inventer un roster de
/// groupe qui n'existe pas cote serveur.
///
/// **Lit `horlogeGroupeProvider(groupeId)` lui-meme**, exactement comme
/// `EspaceGroupePage` le fait pour son horloge -- c'est ce qui lui permet de
/// se cabler avec le seul `groupeId` connu au niveau de la route, sans que
/// `EspaceGroupePage.contenuRoster` (un `Widget?` statique) ait besoin de
/// connaitre la seance courante.
class RosterEnseignantSlot extends ConsumerWidget {
  /// Cree le contenu du slot.
  const RosterEnseignantSlot({required this.groupeId, super.key});

  /// Le groupe dont on montre le roster pedagogique.
  final String groupeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? sessionId = ref
        .watch(horlogeGroupeProvider(groupeId))
        .value
        ?.sessionId;
    if (sessionId == null) {
      return const PanneauRoster(roster: RosterClasseVM.indisponible);
    }

    final AsyncValue<List<TeacherStudentProjection>> lecture = ref.watch(
      rosterSeanceEnseignantProvider(sessionId),
    );
    if (!lecture.hasValue && !lecture.hasError) {
      return const Skeleton.liste(lignes: 2);
    }
    final RosterClasseVM roster = lecture.hasValue
        ? RosterClasseVM(eleves: lecture.requireValue, disponible: true)
        : RosterClasseVM.indisponible;
    return PanneauRoster(roster: roster);
  }
}
