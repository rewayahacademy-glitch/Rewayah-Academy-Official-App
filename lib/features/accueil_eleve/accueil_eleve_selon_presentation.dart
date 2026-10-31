// DASH-MA-PROD : la route `/eleve` rend l'Accueil de la presentation de
// l'eleve. Meme arborescence, meme route (ADR-009, MA-NAV-1) : seul ce que
// l'ecran AFFICHE change. Le choix se lit dans la presentation du profil
// (`modeAccessibiliteActifProvider`), jamais dans un role.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/rejoindre_classe.dart';
import '../acces_finance/acces_finance.dart';
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
    // L'acces de l'eleve, borne a sa session (FI-9a, revue FI-VAGUE-R
    // R4-01) : la meme regle que l'Accueil standard et l'Espace groupe
    // (JONCTION-LIGNES-1 : cette route vient de DASH-MA-PROD, l'acces de
    // FI-DIR-1).
    final ({bool ferme, bool enLecture}) acces = rejoindreSelonAcces(
      ref.watch(accesAppelantProvider),
    );
    return AccueilAccessibilite.lu(
      accesFerme: acces.ferme,
      // Ma classe, deuxieme destination de l'eleve.
      onVoirClasse: () => aller(Routes.eleveSuivi),
      onTache: () => aller(Routes.eleveSuivi),
      onCoran: () => aller(Routes.eleveCoran),
      onAide: () => aller(Routes.eleveAide),
      onRejoindreEspace: acces.enLecture
          ? null
          : (GroupHomeVM espace) {
              final GoRouter routeur = GoRouter.of(context);
              // Sans seance en base (Classe nee pendant son creneau, defaut
              // du 30/10/2026), le concierge la cree ; un refus se dit sous
              // le bouton (K-59).
              unawaited(
                rejoindreClasse(
                  context,
                  groupeId: espace.identite.groupeId,
                  sessionId: espace.identite.horloge?.sessionId,
                  entrer: (String seance) => routeur.go(
                    Routes.salle,
                    // Le billet passe par `extra`, jamais par l'URL (ADR-005).
                    extra: BilletSalle(
                      sessionId: seance,
                      emisA: DateTime.now(),
                      groupeId: espace.identite.groupeId,
                    ),
                  ),
                ),
              );
            },
    );
  }
}
