// L'espace ou s'ouvrent les paiements a effectuer et leur detail : celui du
// Comptable (`/comptable/paiements`) ou la Finance de la direction
// (`/admin/finance/paie`, directeur, 31/10/2026 : la direction voit la paie
// avec son compte). Le meme ecran et la meme source servent les deux ; seuls
// changent les onglets, le titre et les adresses, pour qu'un lien ne quitte
// jamais l'espace de la personne connectee. Aucun role n'est lu ici : la
// route choisit l'espace, la base decide de ce qui est lu.

import '../../../core/admin/admin_domaine.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';

/// Les onglets, le titre et les adresses des paiements a effectuer.
class EspacePaiements {
  const EspacePaiements._({
    required this.onglets,
    required this.titre,
    required this.liste,
    required this.detail,
    this.beneficiaire,
    this._indexOnglet,
  });

  /// L'espace du Comptable : onglets Paiements, profils des beneficiaires.
  factory EspacePaiements.comptable() => EspacePaiements._(
    onglets: ongletsPaiementsComptable(),
    titre: t.comptable.paiements.titre,
    liste: Routes.comptablePaiements,
    detail: Routes.comptablePaiementObligationPour,
    beneficiaire: Routes.comptableBeneficiairePour,
  );

  /// La Finance de la direction : ses onglets ([onglets], `ongletsFinance()`
  /// par defaut, onglet actif [indexOnglet] quand les adresses sont celles
  /// de la demonstration), aucun lien vers les pages du Comptable.
  factory EspacePaiements.direction({
    List<({String libelle, String chemin})>? onglets,
    int? indexOnglet,
  }) => EspacePaiements._(
    onglets: onglets ?? ongletsFinance(),
    indexOnglet: indexOnglet,
    titre: t.admin.finance.paieEnseignants,
    liste: Routes.adminFinancePaie,
    detail: Routes.adminFinancePaieObligationPour,
  );

  /// Les onglets de l'en-tete.
  final List<({String libelle, String chemin})> onglets;

  /// Le titre de la liste.
  final String titre;

  /// L'adresse de la liste, onglet actif et retour du detail.
  final String liste;

  /// L'adresse du detail d'une obligation.
  final String Function(String obligationId) detail;

  /// L'adresse du profil de paiement d'un beneficiaire, ou `null` quand
  /// l'espace n'en a pas (la direction) : le lien n'est alors pas rendu.
  final String Function(String beneficiaireId)? beneficiaire;

  final int? _indexOnglet;

  /// L'onglet actif : celui donne, sinon celui de la liste, sinon le
  /// premier.
  int get indexOnglet {
    final int? donne = _indexOnglet;
    if (donne != null) return donne;
    final int i = onglets.indexWhere(
      (({String libelle, String chemin}) o) => o.chemin == liste,
    );
    return i < 0 ? 0 : i;
  }
}
