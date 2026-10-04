import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';

/// La Communaute enseignants (COM-M02, COM-W02) : **ecran provisoire pose
/// par le socle (COM-F)**, propriete de la voie COM-COMU.
///
/// `/enseignant/communaute`, un raccourci depuis Aujourd'hui (QUESTIONS Q2),
/// jamais une destination de la barre. Tant qu'aucun port n'est branche, la
/// page dit que l'espace arrive ; le bandeau hors ligne vient de
/// [PageShell].
class CommunautePage extends StatelessWidget {
  /// Cree la page.
  const CommunautePage({super.key, this.publicationId});

  /// La publication demandee par l'adresse, s'il y en a une.
  final String? publicationId;

  @override
  Widget build(BuildContext context) {
    final n = t.com.socle.navigation.provisoire;
    return PageShell(
      titre: n.communauteTitre,
      // Le retour ramene a Aujourd'hui, d'ou part le raccourci (Q2).
      onRetour: () => GoRouter.of(context).go(Routes.enseignantJournee),
      child: EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.com.socle.composants.etats.indisponibleTitre,
        phrase: n.communauteDetail,
        dependance: 'COM-COMU-1',
      ),
    );
  }
}
