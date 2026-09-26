// Mes Classes (ENS-09) : page provisoire de la deuxieme destination de la
// coquille enseignant (E10, EN-1b). EN-3 la remplit (lignes groupees, tri du
// doc §12.2, pastille « Remplacement »). Aucun appel serveur (K-28).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';

/// La page Classes de l'enseignant, provisoire : un titre et un constat, sans
/// bouton qui promettrait ce que l'ecran ne tient pas encore.
class MesClassesPage extends StatelessWidget {
  /// Cree la page.
  const MesClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.enseignant.classes.titre,
      child: EmptyState(
        message: t.enseignant.classes.provisoire,
        invitation: t.enseignant.classes.detail,
        icone: AppIcons.classes,
        registre: RegistreVide.subi,
      ),
    );
  }
}
