import 'package:flutter/widgets.dart';

import 'formulaire_paiement.dart';

/// Hors web : aucun formulaire ne se monte (aucun achat integre hors web au
/// lancement, guide Finance V4 §1.6).
class FormulaireStripe extends StatelessWidget {
  /// Cree le formulaire.
  const FormulaireStripe({
    required this.formulaire,
    required this.onTermine,
    required this.onEchec,
    super.key,
  });

  /// La session a payer.
  final FormulairePaiement formulaire;

  /// Le paiement est passe dans le formulaire : la page relit l'etat.
  final VoidCallback onTermine;

  /// Le formulaire n'a pas pu se monter.
  final VoidCallback onEchec;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
