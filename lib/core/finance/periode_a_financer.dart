// La periode a financer d'un profil (guide Finance V4 §1.7) : partagee par la
// carte du Foyer et la fiche Finances, pour que les deux ecrans disent la
// meme chose du meme enfant (revue FI-VAGUE-R, R1-05).

import '../i18n/strings.g.dart';
import 'finances_profil.dart';

/// Le mois que le debit attendu doit financer, en toutes lettres (guide
/// §1.7 : « Il manque 8 USD pour financer janvier »), `null` sans debit.
String? moisAFinancer(FinancesProfil f) => switch (f.prochainDebit) {
  final ProchainDebit d => t.commun.dates.mois[d.date.month - 1],
  null => null,
};

/// Vrai quand le debit attendu est celui d'une periode **non financee** (la
/// periode en cours, guide §1.7) : il ne se dit pas « prochain débit », sa
/// date pouvant etre deja passee.
bool periodeNonFinancee(FinancesProfil f) =>
    f.periode == null &&
    f.prochainDebit != null &&
    switch (f.etat) {
      EtatFinancier.aRegulariser ||
      EtatFinancier.manque ||
      EtatFinancier.expire => true,
      _ => false,
    };
