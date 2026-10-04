import 'package:flutter/widgets.dart';

import '../finance/finances_profil.dart';
import '../i18n/strings.g.dart';
import 'status_pill.dart';

/// L'etat financier d'un profil en pastille (`FinancialStatusChip`, guide
/// Finance V4 §5.1 « Etats visuels », §11.4 ; FI-3b).
///
/// Un habit de [StatusPill], jamais une recopie : un point **et** un mot,
/// chaque etat se lit sans la couleur. Le ton dit la famille (financé = succes,
/// a regulariser = avertissement), jamais l'accent du profil (guide §11.4 :
/// l'accent profil ne se confond jamais avec un statut).
class PastilleFinanciere extends StatelessWidget {
  /// Cree la pastille.
  const PastilleFinanciere({required this.etat, super.key});

  /// L'etat rendu par la source.
  final EtatFinancier etat;

  /// Le mot de l'etat.
  static String libelleDe(EtatFinancier etat) => switch (etat) {
    EtatFinancier.finance => t.argent.etat.finance,
    EtatFinancier.essai => t.argent.etat.essai,
    EtatFinancier.manque => t.argent.etat.manque,
    EtatFinancier.enConfirmation => t.argent.etat.enConfirmation,
    EtatFinancier.expire => t.argent.etat.expire,
    EtatFinancier.pause => t.argent.etat.pause,
    EtatFinancier.aRegulariser => t.argent.etat.aRegulariser,
  };

  /// La famille de l'etat.
  static TonEtat tonDe(EtatFinancier etat) => switch (etat) {
    EtatFinancier.finance => TonEtat.succes,
    EtatFinancier.essai => TonEtat.accent,
    EtatFinancier.enConfirmation => TonEtat.accent,
    EtatFinancier.manque => TonEtat.avertissement,
    EtatFinancier.aRegulariser => TonEtat.avertissement,
    EtatFinancier.expire => TonEtat.alerte,
    EtatFinancier.pause => TonEtat.neutre,
  };

  @override
  Widget build(BuildContext context) =>
      StatusPill(libelle: libelleDe(etat), ton: tonDe(etat));
}
