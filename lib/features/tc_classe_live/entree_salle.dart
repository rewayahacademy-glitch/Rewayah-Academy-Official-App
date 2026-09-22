import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../salle/vue_salle.dart';
import 'classe_live_page.dart';

/// La porte `/salle` : un billet entre, la Classe Live sort.
///
/// **Une seule coque pour les quatre roles.** Le billet (ADR-005) porte la
/// seance et, quand l'ecran d'entree les connaissait, le groupe et le prenom
/// de l'enseignant ; il n'autorise rien. Le role et les capacites viennent du
/// jeton signe, lus par `VueSalle` dans la coque.
///
/// **La sortie est decidee ici, pas dans la coque** (decision D-04 : la coque
/// ne navigue pas). L'enseignant qui a reellement tenu le cours va au cahier
/// (`ENS-04`), les autres a la racine de leur role -- le meme parcours que la
/// salle du lot N3.
class EntreeSalle extends ConsumerWidget {
  /// Cree la porte.
  const EntreeSalle({required this.billet, super.key});

  /// Le billet presente.
  final BilletSalle billet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? prenom = billet.enseignantPrenom;
    return ClasseLivePage(
      contexte: ContexteClasseLive(
        sessionId: billet.sessionId,
        groupeId: billet.groupeId,
        libelleGroupe: billet.libelleGroupe ?? t.tc.classe.entete.sansGroupe,
        // Le billet porte un prenom, jamais une photo : on ne signale pas
        // comme manquante une photo qu'on n'a pas cherchee.
        enseignant: prenom == null
            ? null
            : EnseignantDeClasse(nomAffichage: prenom, photoInconnue: true),
        seuilMax: billet.seuilMax,
        onSortie: (SortieClasse sortie) => _sortir(context, ref, sortie),
      ),
    );
  }

  void _sortir(BuildContext context, WidgetRef ref, SortieClasse sortie) {
    if (sortie.role == RoleSalle.enseignant && sortie.aEteEnSalle) {
      // `go` et non `push` : la salle ne doit rester sous aucune pile,
      // l'ADR-005 lui interdit d'etre revenue en arriere.
      GoRouter.of(context).go(Routes.cahierPour(billet.sessionId));
      return;
    }
    AppRole? role;
    try {
      role = ref.read(sessionProvider).role;
    } on Object {
      role = null;
    }
    GoRouter.of(context)
        .go(role == null ? Routes.racine : Routes.racinePour(role));
  }
}
