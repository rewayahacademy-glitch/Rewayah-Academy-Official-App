import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';

/// Le Studio (COM-W00, COM-M04, et le canal COM-W03) : **ecran provisoire
/// pose par le socle (COM-F)**, propriete de la voie COM-STU.
///
/// `/admin/studio` et `/admin/studio/canaux/:canalId`, ouverts par l'action
/// « Le Studio » de l'en-tete de l'`AdminShell` (QUESTIONS Q1). Hors de la
/// coquille admin : Le Studio aura sa propre navigation (Aujourd'hui,
/// Canaux), et le mode focus masquera tout chrome. La sortie ramene a
/// l'Accueil admin.
class StudioPage extends StatelessWidget {
  /// Cree la page.
  const StudioPage({super.key, this.canalId});

  /// Le canal demande par l'adresse, s'il y en a un.
  final String? canalId;

  @override
  Widget build(BuildContext context) {
    final n = t.com.socle.navigation.provisoire;
    return PageShell(
      titre: n.studioTitre,
      onRetour: () => GoRouter.of(context).go(Routes.admin),
      child: EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.com.socle.composants.etats.indisponibleTitre,
        phrase: n.studioDetail,
        dependance: 'COM-STU-1',
      ),
    );
  }
}
