// La part d'un paiement qui va a un profil (FI-3a, guide Finance V4 §5.3,
// §5.4 et §7 : `PaymentAllocationRow`), habit de `LigneCleValeur`.

import 'package:flutter/widgets.dart';

import '../finance/format_montant.dart';
import '../finance/montant.dart';
import 'ligne_cle_valeur.dart';

/// La part d'un paiement qui va a un profil (`PaymentAllocationRow`, guide
/// §5.3 et §5.4) : on voit toujours **a qui** va chaque montant, son avatar
/// et son prenom en tete, jamais un « solde commun ».
class LigneAllocation extends StatelessWidget {
  /// Cree la ligne.
  const LigneAllocation({
    required this.prenom,
    required this.montant,
    required this.avatar,
    super.key,
    this.detail,
  });

  /// Le prenom du profil.
  final String prenom;

  /// Ce qui lui est attribue.
  final Montant montant;

  /// Son avatar, avec son bandeau de couleur s'il en a un (`BandeauProfil`).
  final Widget avatar;

  /// Une precision : la periode financee, le nouveau solde.
  final String? detail;

  @override
  Widget build(BuildContext context) => LigneCleValeur(
    meneur: avatar,
    cle: prenom,
    detailCle: detail,
    valeur: formaterMontant(montant),
    chiffres: true,
    valeurEnFin: true,
  );
}
