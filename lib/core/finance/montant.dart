// Un montant d'argent, tel qu'une source le rend (FI-1c, guide Finance V4
// §7, §11.3 ; K-41.5).
//
// **Entier en unites mineures + code ISO 4217**, jamais un `double` (regle
// transverse du depot : « l'argent est un entier en unites mineures »).
// Flutter formate un montant ; il ne calcule ni prix, ni remise, ni taxe, ni
// paie (FI6). Le formatage selon la langue active arrive avec les composants
// d'argent (FI-3a).

import 'package:flutter/foundation.dart';

/// Un montant en unites mineures et sa devise.
@immutable
class Montant {
  /// Cree un montant de [mineur] unites mineures dans la devise [devise].
  const Montant(this.mineur, this.devise);

  /// Le montant en unites mineures (centimes pour l'USD). Signe compris :
  /// negatif pour une remise, un avoir ou un debit.
  final int mineur;

  /// Le code ISO 4217 (par exemple `USD`), toujours identifiable (FI14).
  final String devise;

  /// Vrai pour un montant nul.
  bool get estNul => mineur == 0;

  @override
  bool operator ==(Object other) =>
      other is Montant && other.mineur == mineur && other.devise == devise;

  @override
  int get hashCode => Object.hash(mineur, devise);

  @override
  String toString() => 'Montant($mineur $devise)';
}
