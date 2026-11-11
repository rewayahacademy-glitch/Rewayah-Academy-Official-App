// ONBOARDING-TUTEUR (09/11/2026) : l'Accueil famille tel que le routeur le
// monte. Il lit la capacite « eleve autonome » (jamais le role) et, quand le
// serveur la sert, donne a la page l'entree vers l'espace d'eleve. La page
// elle-meme ne lit pas la session : ses tests la montent sans.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import 'accueil_famille_page.dart';

/// L'Accueil famille, avec le lien vers l'espace d'eleve sous le profil du
/// titulaire quand le compte le merite. Tant que la capacite est en lecture, elle est fausse : rien ne
/// s'affiche (jamais une entree qui apparait puis disparait sous les doigts).
class AccueilFamilleRelie extends ConsumerWidget {
  /// Cree l'Accueil relie a la session.
  const AccueilFamilleRelie({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool eleveAutonome = ref.watch(
      sessionProvider.select((SessionState s) => s.eleveAutonome),
    );
    final String? profil = ref.watch(
      sessionProvider.select((SessionState s) => s.profileId),
    );
    return AccueilFamillePage(
      onOuvrirEspaceEleve: eleveAutonome
          ? () => GoRouter.of(context).go(Routes.eleveAdulte)
          : null,
      // Le profil eleve du titulaire est SA propre ligne : son identifiant est
      // celui de son compte (student_profiles.titulaire_profile_id = lui).
      titulaireId: eleveAutonome ? profil : null,
    );
  }
}
