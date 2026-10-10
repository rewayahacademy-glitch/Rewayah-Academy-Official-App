/// CAP29-B (coque) puis CAP29-E : attribuer aux classes et retirer.
library;

import 'package:flutter/material.dart';

import '../../../core/admin/admin_domaine.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../catalogue/catalogue_page.dart' show rangBibliotheque;
import '../porte_bibliotheque.dart';

/// L'ecran du support [supportId].
class AttributionSupportPage extends StatelessWidget {
  /// Cree l'ecran.
  const AttributionSupportPage({required this.supportId, super.key});

  /// Le support.
  final String supportId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.bibliotheque.ficheTitre,
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
