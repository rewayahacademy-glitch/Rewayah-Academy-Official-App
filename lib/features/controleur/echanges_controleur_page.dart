// Echanges (CTR-04) : page provisoire de la troisieme destination de la
// coquille controleur (C13, CT-1b). CT-6 la remplit (liste de fils par
// mission ou sujet, fil avec contexte epingle, C17). Aucun envoi (K-28).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';

/// La page Echanges du controleur, provisoire : un titre et un constat,
/// sans bouton qui promettrait ce que l'ecran ne tient pas encore.
class EchangesControleurPage extends StatelessWidget {
  /// Cree la page.
  const EchangesControleurPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.controleur.echanges.titre,
      child: EmptyState(
        message: t.controleur.echanges.provisoire,
        icone: AppIcons.info,
        registre: RegistreVide.subi,
      ),
    );
  }
}
