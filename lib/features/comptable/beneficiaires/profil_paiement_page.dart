// Etat du profil de paiement d'un beneficiaire (FIN-CPT-W07 ; spec §16, §19,
// §35). Posee « en preparation » par CPT-F avec son constructeur definitif ;
// **propriete de la voie CPT-BEN ensuite** (`20_comptable/02_DECOUPAGE.md`).
//
// Composee d'apres W03 (aucune planche) : identite, carte du profil (methode
// masquee, statut, pays, devise, derniere modification, verification,
// capacite de payout), historique ; actions Relancer (plein), Demander une
// mise a jour, Suspendre le paiement selon capacite. Aucun « Modifier
// coordonnees » (R-FIN-11).

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';

/// Le profil de paiement d'un beneficiaire, sous l'onglet « Beneficiaires ».
class ProfilPaiementPage extends StatelessWidget {
  /// Cree la page pour le beneficiaire [beneficiaireId] (segment d'adresse).
  const ProfilPaiementPage({required this.beneficiaireId, super.key});

  /// Le beneficiaire.
  final String beneficiaireId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.comptable.beneficiaires.profilTitre,
      onRetour: () => retourComptable(context, Routes.comptableBeneficiaires),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
