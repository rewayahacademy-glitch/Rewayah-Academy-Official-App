/// CAP29-0 (coque) puis CAP29-A : le catalogue de la bibliotheque, Pedagogie >
/// Bibliotheque.
///
/// Cette coque pose la page, la sous-navigation et les etats de la porte
/// (indisponible, non autorise, erreur, chargement) ; CAP29-A y met le
/// catalogue.
library;

import 'package:flutter/material.dart';

import '../../../core/admin/admin_domaine.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../porte_bibliotheque.dart';

/// Le rang de « Bibliotheque » dans la sous-navigation Pedagogie.
const int rangBibliotheque = 4;

/// L'ecran du catalogue.
class CataloguePage extends StatelessWidget {
  /// Cree l'ecran.
  const CataloguePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.bibliotheque.titre,
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
