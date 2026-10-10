/// CAP29-A (coque) puis CAP29-C : ajouter un support. La coque donne sa route
/// a l'action « Ajouter un support » du catalogue ; CAP29-C y met le parcours.
library;

import 'package:flutter/material.dart';

import '../../../core/admin/admin_domaine.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../catalogue/catalogue_page.dart' show rangBibliotheque;
import '../porte_bibliotheque.dart';

/// L'ecran « Ajouter un support ».
class ImportPage extends StatelessWidget {
  /// Cree l'ecran.
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.bibliotheque.ajouter,
      entete: SousNavigationDomaine(
        onglets: ongletsPedagogie(),
        indexActif: rangBibliotheque,
      ),
      child: PorteBibliotheque(
        construire: (BuildContext context, port, capacites) =>
            Text(t.admin.bibliotheque.intro),
      ),
    );
  }
}
