// Compte rendu (CTR-03) : page provisoire, sortie de la salle d'observation
// (P-CTR-03 point 12, CT-3). CT-4 la construit (question « Avez-vous quelque
// chose a signaler ? », trois cartes, transmission automatique au depart).
// Aucun appel serveur (K-28).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';

/// Le compte rendu du controleur, provisoire : un titre, un constat, et le
/// retour au controle.
class CompteRenduControlePage extends StatelessWidget {
  /// Cree la page.
  const CompteRenduControlePage({super.key, this.onRevenir});

  /// Le retour au controle ; par defaut, la destination Controle.
  final VoidCallback? onRevenir;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.controleur.compteRendu.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          EmptyState(
            message: t.controleur.compteRendu.provisoire,
            registre: RegistreVide.subi,
          ),
          Ecart.vXl,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              libelle: t.controleur.compteRendu.revenir,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress:
                  onRevenir ??
                  () => GoRouter.of(context).go(Routes.controleur),
            ),
          ),
        ],
      ),
    );
  }
}
