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
///
/// L'essai dit ou il en est, « Essai : 1/2 » (02_DECOUPAGE C-4, revue
/// FI-3-R M2), des que la source rend ses deux compteurs.
class PastilleFinanciere extends StatelessWidget {
  /// Cree la pastille.
  const PastilleFinanciere({
    required this.etat,
    super.key,
    this.essaisUtilises,
    this.essaisMax,
  });

  /// L'etat rendu par la source.
  final EtatFinancier etat;

  /// Les seances d'essai utilisees, rendues par la source (`null` : inconnu).
  final int? essaisUtilises;

  /// Le nombre de seances d'essai de la politique (`null` : non lue, jamais
  /// suppose).
  final int? essaisMax;

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

  /// « Essai : n/max », la seule forme du compteur d'essai de l'application
  /// (pastille du Foyer, de la fiche et de l'acces).
  static String libelleEssai({required int utilises, required int max}) =>
      t.argent.etat.essaiCompte(n: utilises, max: max);

  /// La famille de l'etat.
  ///
  /// L'essai est **neutre** (revue FI-3-R M3) : le point d'accent
  /// (`surfacePrimary`, violet) tombe a 6 degres de teinte de l'accent de
  /// profil lavande, en clair comme en sombre ; le point neutre est
  /// desature et se distingue de tous les accents de profil
  /// (`test/core/widgets/composants_argent_test.dart`). Aucune couleur
  /// nouvelle (K-37). « En confirmation » garde l'accent : sa proximite avec
  /// lavande reste a trancher par TH-2.
  static TonEtat tonDe(EtatFinancier etat) => switch (etat) {
    EtatFinancier.finance => TonEtat.succes,
    EtatFinancier.essai => TonEtat.neutre,
    EtatFinancier.enConfirmation => TonEtat.accent,
    EtatFinancier.manque => TonEtat.avertissement,
    EtatFinancier.aRegulariser => TonEtat.avertissement,
    EtatFinancier.expire => TonEtat.alerte,
    EtatFinancier.pause => TonEtat.neutre,
  };

  @override
  Widget build(BuildContext context) {
    final int? n = essaisUtilises;
    final int? max = essaisMax;
    final String libelle =
        etat == EtatFinancier.essai && n != null && max != null
        ? libelleEssai(utilises: n, max: max)
        : libelleDe(etat);
    return StatusPill(libelle: libelle, ton: tonDe(etat));
  }
}
