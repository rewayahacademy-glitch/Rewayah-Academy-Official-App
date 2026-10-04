import 'package:flutter/material.dart';

import '../finance/format_montant.dart';
import '../finance/montant.dart';
import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// La taille d'un montant, prise dans l'echelle typographique : jamais un
/// corps invente.
enum TailleMontant {
  /// Dans une ligne : le corps du texte.
  corps,

  /// En tete d'un bloc : au rang d'un titre de carte.
  titre,

  /// Le chiffre principal d'un resume (solde, total du mois).
  grand,
}

/// Un montant d'argent (`MoneyAmount`, guide Finance V4 §7 et §11.3 ; FI-3a).
///
/// - chiffres tabulaires : une colonne de montants reste calme ;
/// - la devise toujours dite, jamais collee au nombre (« 50 $ ») ;
/// - le signe explicite sur demande (« +5 $ », « −5 $ ») ;
/// - jamais la couleur seule : un montant attenue reste lisible par son
///   texte, et un debit se lit par son signe, pas par une teinte.
///
/// La mise en mots vient de [formaterMontant], seul formateur du depot ; ce
/// widget ne calcule rien (FI6).
class MontantArgent extends StatelessWidget {
  /// Cree le montant.
  const MontantArgent(
    this.montant, {
    super.key,
    this.signe = false,
    this.taille = TailleMontant.corps,
    this.attenue = false,
  });

  /// Le montant, entier en unites mineures et sa devise.
  final Montant montant;

  /// Vrai pour poser aussi le signe d'un montant positif (« +5 $ »).
  final bool signe;

  /// La taille.
  final TailleMontant taille;

  /// Vrai pour un montant secondaire (encre attenuee).
  final bool attenue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base =
        switch (taille) {
          TailleMontant.corps => textes.bodyLarge,
          TailleMontant.titre => textes.titleLarge,
          TailleMontant.grand => textes.displaySmall,
        } ??
        const TextStyle();
    return Text(
      formaterMontant(montant, signe: signe),
      style: (attenue ? palette.inkMuted : palette.inkStrong).applyTo(
        AppTypography.tabulaire(base),
      ),
    );
  }
}
