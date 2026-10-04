// Detail d'un encaissement (FIN-CPT-W05 ; spec §24.2, §33). Posee « en
// preparation » par CPT-F avec son constructeur definitif ; **propriete de la
// voie CPT-ENC ensuite** (`20_comptable/02_DECOUPAGE.md`).
//
// Page sous 1200 ; a 1440 la liste l'ouvre en panneau. « Voir le recu »
// seulement si la source rend un recu.

import 'package:flutter/material.dart';

import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_shell.dart';

/// Le detail d'un encaissement, sous l'onglet « Encaissements ».
class DetailEncaissementPage extends StatelessWidget {
  /// Cree la page pour l'encaissement [encaissementId] (segment d'adresse).
  const DetailEncaissementPage({required this.encaissementId, super.key});

  /// L'encaissement.
  final String encaissementId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.comptable.encaissements.detailTitre,
      onRetour: () => retourComptable(context, Routes.comptableEncaissements),
      actionsEntete: const <Widget>[BasculeMontants()],
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
