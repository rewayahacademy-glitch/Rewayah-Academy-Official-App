// DASH-MA-PROD : la route `/eleve` rend l'Accueil de la presentation de
// l'eleve. Meme arborescence, meme route (ADR-009, MA-NAV-1) : seul ce que
// l'ecran AFFICHE change. Le choix se lit dans la presentation du profil
// (`modeAccessibiliteActifProvider`), jamais dans un role.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import 'accueil_accessibilite.dart';
import 'accueil_eleve_page.dart';

/// L'Accueil de l'eleve : celui du Mode Accessibilite quand il est actif,
/// `ELV-02` sinon.
class AccueilEleveSelonPresentation extends ConsumerWidget {
  /// Cree l'Accueil.
  const AccueilEleveSelonPresentation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(modeAccessibiliteActifProvider)) {
      return const AccueilElevePage();
    }
    void aller(String chemin) => GoRouter.of(context).go(chemin);
    return AccueilAccessibilite.lu(
      // Ma classe, deuxieme destination de l'eleve.
      onVoirClasse: () => aller(Routes.eleveSuivi),
      onTache: () => aller(Routes.eleveSuivi),
      onCoran: () => aller(Routes.eleveCoran),
      onAide: () => aller(Routes.eleveAide),
      onRejoindreEspace: (GroupHomeVM espace) {
        final String? seance = espace.identite.horloge?.sessionId;
        // Sans seance materialisee, l'entree se fait depuis Ma classe.
        if (seance == null) {
          aller(Routes.eleveSuivi);
          return;
        }
        GoRouter.of(context).go(
          Routes.salle,
          // Le billet passe par `extra`, jamais par l'URL (ADR-005).
          extra: BilletSalle(
            sessionId: seance,
            emisA: DateTime.now(),
            groupeId: espace.identite.groupeId,
          ),
        );
      },
    );
  }
}
