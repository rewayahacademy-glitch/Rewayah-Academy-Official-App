// Historique (CTR-05) : page provisoire de la deuxieme destination de la
// coquille controleur (C13, CT-1b). CT-7 la remplit (filtres Periode, Classe,
// Etat ; lignes groupees ; C18). Aucun appel serveur (K-28).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';

/// La page Historique du controleur, provisoire : un titre et un constat,
/// sans bouton qui promettrait ce que l'ecran ne tient pas encore.
class HistoriqueControleurPage extends StatelessWidget {
  /// Cree la page.
  const HistoriqueControleurPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.controleur.historique.titre,
      child: EmptyState(
        message: t.controleur.historique.provisoire,
        icone: AppIcons.historique,
        registre: RegistreVide.subi,
      ),
    );
  }
}
