// « Paiements des familles » du Comptable (passation du 17/10/2026, point 3 :
// la direction OU le comptable enregistrent un paiement recu hors de
// l'application, attribue a un eleve ; FAC-B-01 et FAC-C-01).
//
// Le meme corps que l'onglet « Paiements » de la direction (`PaiementsBloc`)
// : factures du mois, puis eleves a regulariser et a jour, fiche de saisie.
// Le serveur ouvre ces gestes aux deux roles (`enregistrer_paiement`,
// `emettre_factures_mois`, `eleves_pour_paiement`). Page de niveau 2 de
// Tresorerie, ouverte depuis Encaissements ; elle ne touche pas la
// navigation gelee du Comptable (`navigation_comptable.dart`).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/page_shell.dart';
import '../../admin_finance/paiements/paiements_page.dart';

/// La page « Paiements des familles ».
class PaiementsFamillesPage extends StatelessWidget {
  /// Cree la page.
  const PaiementsFamillesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.comptable.paiementsFamilles.titre,
      onRetour: () => retourComptable(context, Routes.comptableEncaissements),
      child: const PaiementsBloc(),
    );
  }
}
